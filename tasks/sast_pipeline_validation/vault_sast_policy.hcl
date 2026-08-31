# HashiCorp Vault Policy for CI/CD SAST Pipeline
# Path: tasks/sast_pipeline_validation/vault_sast_policy.hcl

# Allow CI/CD runners read-only access to SAST credentials and API tokens
path "secret/data/ci/sast" {
  capabilities = ["read"]
}

# Allow reading SAST license and webhook alerting tokens
path "secret/data/ci/sast/*" {
  capabilities = ["read", "list"]
}

# Allow CI runner to query its own token capabilities
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
