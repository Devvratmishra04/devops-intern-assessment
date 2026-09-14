#!/usr/bin/env bash
# ── Jira Extraction Application – Linux/macOS Deployment Script ──
#
# Usage:
#   ./deploy.sh                                # Default extraction
#   ./deploy.sh --template open_bugs           # Use a saved template
#   ./deploy.sh --jql "project = DEV"          # Custom JQL
#   ./deploy.sh --limit 50                     # Limit results
#   ./deploy.sh --docker                       # Build & run via Docker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"
DOCKER_MODE=false
EXTRA_ARGS=()

# ── Parse arguments ──────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --docker)
            DOCKER_MODE=true
            shift
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

echo ""
echo "============================================================"
echo "  Jira Extraction Application – Deployment"
echo "============================================================"
echo ""

# ── Docker Mode ──────────────────────────────────────────────
if [ "$DOCKER_MODE" = true ]; then
    echo "[1/3] Building Docker image..."
    docker build -t jira-extraction:latest "$SCRIPT_DIR"

    echo "[2/3] Running container..."
    docker compose -f "${SCRIPT_DIR}/docker-compose.yml" run --rm jira-extract "${EXTRA_ARGS[@]}"

    echo "[3/3] Done! Check output/ for the generated report."
    exit 0
fi

# ── Local Python Mode ───────────────────────────────────────

# Step 1: Virtual environment
echo "[1/4] Setting up virtual environment..."
if [ ! -f "${VENV_DIR}/bin/python" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "  Virtual environment already exists."
fi

# Step 2: Install dependencies
echo "[2/4] Installing dependencies..."
"${VENV_DIR}/bin/pip" install -r "${SCRIPT_DIR}/requirements.txt" --quiet

# Step 3: Validate credentials
echo "[3/4] Validating credentials..."
ENV_FILE="${SCRIPT_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "[ERROR] .env file not found. Copy .env.example to .env and fill in credentials."
    exit 1
fi

for var in JIRA_URL JIRA_EMAIL JIRA_API_TOKEN; do
    if ! grep -qE "^${var}=.+" "$ENV_FILE"; then
        echo "[ERROR] Missing required variable: ${var} in .env"
        exit 1
    fi
done

if grep -q "PASTE_YOUR_API_TOKEN_HERE\|your-real-api-token" "$ENV_FILE"; then
    echo "[ERROR] .env contains placeholder API token. Update JIRA_API_TOKEN."
    echo "  Generate one at: https://id.atlassian.com/manage-profile/security/api-tokens"
    exit 1
fi
echo "  Credentials validated."

# Step 4: Run extraction
echo "[4/4] Running Jira Extraction..."
"${VENV_DIR}/bin/python" "${SCRIPT_DIR}/jira_extraction.py" "${EXTRA_ARGS[@]}"

echo ""
echo "============================================================"
echo "  Deployment Complete!"
echo "============================================================"
echo ""
