#!/usr/bin/env bash
# ==============================================================================
# Script: vault_setup.sh
# Purpose: Configure HashiCorp Vault KV Secret Engine and AppRole for SAST CI
# ==============================================================================

set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

echo "=================================================="
echo "Configuring HashiCorp Vault for CI/CD SAST Scans"
echo "Vault Address: ${VAULT_ADDR}"
echo "=================================================="

export VAULT_ADDR VAULT_TOKEN

# 1. Enable KV v2 secret engine if not enabled
if ! vault secrets list | grep -q "^secret/"; then
    echo "[+] Enabling KV version 2 secret engine at secret/..."
    vault secrets enable -path=secret kv-v2
else
    echo "[*] KV secret engine already enabled at secret/"
fi

# 2. Write SAST credentials into Vault
echo "[+] Writing SAST credentials and Semgrep tokens to secret/ci/sast..."
vault kv put secret/ci/sast \
    SEMGREP_APP_TOKEN="smp_mock_token_for_ci_pipeline_validation_12345" \
    SAST_WEBHOOK_URL="https://hooks.slack.com/services/ORG/DEVOPS/ALERT" \
    SCAN_ENVIRONMENT="ci-pipeline"

# 3. Create Policy from vault_sast_policy.hcl
echo "[+] Applying Vault policy 'sast-ci-reader'..."
vault policy write sast-ci-reader tasks/sast_pipeline_validation/vault_sast_policy.hcl

# 4. Configure AppRole for GitHub Actions Runner
if ! vault auth list | grep -q "^approle/"; then
    echo "[+] Enabling AppRole authentication..."
    vault auth enable approle
fi

echo "[+] Creating AppRole 'github-actions-sast'..."
vault write auth/approle/role/github-actions-sast \
    token_policies="sast-ci-reader" \
    token_ttl=1h \
    token_max_ttl=4h

echo "[+] Fetching Role ID and Secret ID for GitHub Actions secrets..."
ROLE_ID=$(vault read -format=json auth/approle/role/github-actions-sast/role-id | grep -o '"role_id": "[^"]*' | cut -d'"' -f4)
SECRET_ID=$(vault write -f -format=json auth/approle/role/github-actions-sast/secret-id | grep -o '"secret_id": "[^"]*' | cut -d'"' -f4)

echo ""
echo "=== Vault Credentials for CI/CD Pipeline Configuration ==="
echo "Add these to GitHub Repository Secrets:"
echo "VAULT_ROLE_ID   : ${ROLE_ID}"
echo "VAULT_SECRET_ID : ${SECRET_ID}"
echo "VAULT_ADDR      : ${VAULT_ADDR}"
echo "=========================================================="
