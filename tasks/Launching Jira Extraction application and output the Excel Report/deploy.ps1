<# 
.SYNOPSIS
    Jira Extraction Application – Windows Deployment Script

.DESCRIPTION
    Sets up the Python virtual environment, installs dependencies, validates
    credentials, and runs the Jira Extraction Application.

.EXAMPLE
    .\deploy.ps1                               # Default extraction
    .\deploy.ps1 -Template open_bugs           # Use a saved template
    .\deploy.ps1 -JQL "project = DEV"          # Custom JQL
    .\deploy.ps1 -Limit 50                     # Limit results
    .\deploy.ps1 -DockerMode                   # Build & run via Docker
#>

param(
    [string]$JQL,
    [string]$Template,
    [int]$Limit,
    [string]$Output,
    [switch]$DockerMode,
    [switch]$SkipSetup
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Jira Extraction Application – Deployment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── Docker Mode ──────────────────────────────────────────────
if ($DockerMode) {
    Write-Host "[1/3] Building Docker image..." -ForegroundColor Yellow
    docker build -t jira-extraction:latest $ScriptDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Docker build failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "[2/3] Running container..." -ForegroundColor Yellow
    $dockerArgs = @()
    if ($JQL)      { $dockerArgs += "--jql"; $dockerArgs += "`"$JQL`"" }
    if ($Template) { $dockerArgs += "--template"; $dockerArgs += $Template }
    if ($Limit)    { $dockerArgs += "--limit"; $dockerArgs += $Limit }

    docker compose -f "$ScriptDir\docker-compose.yml" run --rm jira-extract @dockerArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Docker run failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "[3/3] Done! Check output/ for the generated report." -ForegroundColor Green
    exit 0
}

# ── Local Python Mode ───────────────────────────────────────
if (-not $SkipSetup) {
    # Step 1: Virtual environment
    Write-Host "[1/4] Setting up virtual environment..." -ForegroundColor Yellow
    $VenvPath = Join-Path $ScriptDir "venv"
    if (-not (Test-Path "$VenvPath\Scripts\python.exe")) {
        Write-Host "  Creating virtual environment..." 
        py -m venv $VenvPath
    } else {
        Write-Host "  Virtual environment already exists."
    }

    # Step 2: Install dependencies
    Write-Host "[2/4] Installing dependencies..." -ForegroundColor Yellow
    & "$VenvPath\Scripts\pip.exe" install -r "$ScriptDir\requirements.txt" --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Dependency installation failed." -ForegroundColor Red
        exit 1
    }
}

$VenvPath = Join-Path $ScriptDir "venv"

# Step 3: Validate credentials
Write-Host "[3/4] Validating credentials..." -ForegroundColor Yellow
$envFile = Join-Path $ScriptDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "[ERROR] .env file not found. Copy .env.example to .env and fill in credentials." -ForegroundColor Red
    exit 1
}

$envContent = Get-Content $envFile -Raw
if ($envContent -match "PASTE_YOUR_API_TOKEN_HERE" -or $envContent -match "your-real-api-token") {
    Write-Host "[WARNING] .env contains placeholder API token. Update JIRA_API_TOKEN with a real token." -ForegroundColor Red
    Write-Host "  Generate one at: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Yellow
    exit 1
}

$requiredVars = @("JIRA_URL", "JIRA_EMAIL", "JIRA_API_TOKEN")
foreach ($var in $requiredVars) {
    if ($envContent -notmatch "$var=.+") {
        Write-Host "[ERROR] Missing required variable: $var in .env" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  Credentials validated." -ForegroundColor Green

# Step 4: Run extraction
Write-Host "[4/4] Running Jira Extraction..." -ForegroundColor Yellow
$pythonExe = "$VenvPath\Scripts\python.exe"
$scriptPath = Join-Path $ScriptDir "jira_extraction.py"

$pyArgs = @($scriptPath)
if ($JQL)      { $pyArgs += "--jql"; $pyArgs += $JQL }
if ($Template) { $pyArgs += "--template"; $pyArgs += $Template }
if ($Limit)    { $pyArgs += "--limit"; $pyArgs += $Limit }
if ($Output)   { $pyArgs += "--output"; $pyArgs += $Output }

& $pythonExe @pyArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Extraction failed. Check logs above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
