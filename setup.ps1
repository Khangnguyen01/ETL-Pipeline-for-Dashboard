#!/usr/bin/env pwsh
# ===================================
# DBT Project Setup Script
# Quick setup for Windows/PowerShell
# ===================================

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 DBT ETL Pipeline Setup Wizard      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Function to check if command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Function to print step
function Write-Step {
    param($Step, $Message)
    Write-Host "[$Step] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Message" -ForegroundColor White
}

# Function to print success
function Write-Success {
    param($Message)
    Write-Host "  ✓ " -ForegroundColor Green -NoNewline
    Write-Host "$Message" -ForegroundColor Gray
}

# Function to print error
function Write-Error-Custom {
    param($Message)
    Write-Host "  ✗ " -ForegroundColor Red -NoNewline
    Write-Host "$Message" -ForegroundColor Gray
}

# Step 1: Check Prerequisites
Write-Step "1/7" "Checking prerequisites..."
Start-Sleep -Milliseconds 500

$allPrerequisitesMet = $true

if (Test-Command "python") {
    $pythonVersion = python --version
    Write-Success "Python installed: $pythonVersion"
} else {
    Write-Error-Custom "Python not found. Please install Python 3.10+"
    $allPrerequisitesMet = $false
}

if (Test-Command "git") {
    Write-Success "Git installed"
} else {
    Write-Error-Custom "Git not found. Please install Git"
    $allPrerequisitesMet = $false
}

if (Test-Command "gcloud") {
    Write-Success "Google Cloud SDK installed"
} else {
    Write-Error-Custom "gcloud not found (optional for OAuth)"
}

Write-Host ""

if (-not $allPrerequisitesMet) {
    Write-Host "⚠️  Please install missing prerequisites and run again." -ForegroundColor Red
    exit 1
}

# Step 2: Create Virtual Environment
Write-Step "2/7" "Setting up Python virtual environment..."
Start-Sleep -Milliseconds 500

if (-not (Test-Path ".venv")) {
    python -m venv .venv
    Write-Success "Virtual environment created"
} else {
    Write-Success "Virtual environment already exists"
}

# Activate virtual environment
& .\.venv\Scripts\Activate.ps1
Write-Success "Virtual environment activated"
Write-Host ""

# Step 3: Install Python Dependencies
Write-Step "3/7" "Installing Python dependencies..."
Start-Sleep -Milliseconds 500

pip install -q --upgrade pip
pip install -q -r requirements.txt
Write-Success "Dependencies installed"
Write-Host ""

# Step 4: Install dbt Packages
Write-Step "4/7" "Installing dbt packages..."
Start-Sleep -Milliseconds 500

dbt deps 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "dbt packages installed (dbt-utils, audit_helper, elementary)"
} else {
    Write-Error-Custom "Failed to install dbt packages (will retry later)"
}
Write-Host ""

# Step 5: Check Configuration Files
Write-Step "5/7" "Checking configuration files..."
Start-Sleep -Milliseconds 500

# Check for profiles.yml
$profilesPath = "$env:USERPROFILE\.dbt\profiles.yml"
if (Test-Path $profilesPath) {
    Write-Success "profiles.yml found at $profilesPath"
} else {
    Write-Error-Custom "profiles.yml NOT found"
    Write-Host "    → Please copy profiles.yml.example to $profilesPath" -ForegroundColor Yellow
    Write-Host "    → Update with your GCP project details" -ForegroundColor Yellow
}

# Check for credentials
if (Test-Path "application_default_credentials.json") {
    Write-Success "GCP credentials file found"
} else {
    Write-Error-Custom "application_default_credentials.json NOT found"
    Write-Host "    → Option 1: Run 'gcloud auth application-default login'" -ForegroundColor Yellow
    Write-Host "    → Option 2: Download service account key from GCP" -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Test dbt Connection
Write-Step "6/7" "Testing dbt connection..."
Start-Sleep -Milliseconds 500

$testResult = dbt debug --profiles-dir $env:USERPROFILE\.dbt 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "dbt connection successful!"
} else {
    Write-Error-Custom "dbt connection failed"
    Write-Host "    → Run 'dbt debug' for more details" -ForegroundColor Yellow
    Write-Host "    → Check CONFIGURATION_GUIDE.md for setup instructions" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Summary
Write-Step "7/7" "Setup Summary"
Start-Sleep -Milliseconds 500

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   🎉 Setup Complete!                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📚 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Configure authentication:" -ForegroundColor White
Write-Host "     gcloud auth application-default login" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Set up profiles.yml:" -ForegroundColor White
Write-Host "     Copy profiles.yml.example to $profilesPath" -ForegroundColor Gray
Write-Host "     Update with your GCP project ID" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Test connection:" -ForegroundColor White
Write-Host "     dbt debug" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Compile models:" -ForegroundColor White
Write-Host "     dbt compile" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Run staging models:" -ForegroundColor White
Write-Host "     dbt run --select staging.*" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Documentation:" -ForegroundColor Cyan
Write-Host "  • README.md - Full project documentation" -ForegroundColor Gray
Write-Host "  • CONFIGURATION_GUIDE.md - Detailed setup guide" -ForegroundColor Gray
Write-Host "  • profiles.yml.example - Configuration template" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Useful Commands:" -ForegroundColor Cyan
Write-Host "  dbt compile          # Check SQL syntax" -ForegroundColor Gray
Write-Host "  dbt run              # Run all models" -ForegroundColor Gray
Write-Host "  dbt test             # Run data quality tests" -ForegroundColor Gray
Write-Host "  dbt docs generate    # Generate documentation" -ForegroundColor Gray
Write-Host "  dbt docs serve       # View documentation" -ForegroundColor Gray
Write-Host ""
Write-Host "Happy data transforming! 🎉" -ForegroundColor Green
Write-Host ""

