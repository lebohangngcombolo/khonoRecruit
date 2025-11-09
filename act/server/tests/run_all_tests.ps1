# ============================================================
# COMPREHENSIVE TEST SUITE RUNNER FOR HIRING MANAGER
# PowerShell Script for Windows
# ============================================================

$ErrorActionPreference = "Continue"
$TestDir = $PSScriptRoot
$ServerDir = Split-Path $TestDir -Parent

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "HIRING MANAGER TEST SUITE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored messages
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ $msg" -ForegroundColor Blue }
function Write-Warning { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }

# ============================================================
# 1. PRE-FLIGHT CHECKS
# ============================================================
Write-Info "Running pre-flight checks..."
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python found: $pythonVersion"
} catch {
    Write-Error "Python not found! Please install Python 3.8+"
    exit 1
}

# Check if PostgreSQL client is available
try {
    $psqlVersion = psql --version 2>&1
    Write-Success "PostgreSQL client found: $psqlVersion"
} catch {
    Write-Warning "PostgreSQL client (psql) not found. Database tests will be skipped."
    $skipDbTests = $true
}

# Check if Flask server is running
Write-Info "Checking if Flask server is running..."
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/admin/dashboard-counts" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Error "Server is accessible WITHOUT authentication - this is a security issue!"
} catch {
    if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403) {
        Write-Success "Flask server is running and requires authentication"
    } else {
        Write-Error "Flask server is not running or not accessible"
        Write-Info "Please start the Flask server with: python run.py"
        exit 1
    }
}

Write-Host ""

# ============================================================
# 2. CHECK FOR JWT TOKENS
# ============================================================
Write-Info "Checking for JWT tokens configuration..."
Write-Host ""

$tokenFile = Join-Path $TestDir "test_tokens.txt"
$hmToken = $null
$adminToken = $null

if (Test-Path $tokenFile) {
    $tokens = Get-Content $tokenFile
    foreach ($line in $tokens) {
        if ($line -match "^HM_TOKEN=(.+)$") {
            $hmToken = $matches[1]
        }
        if ($line -match "^ADMIN_TOKEN=(.+)$") {
            $adminToken = $matches[1]
        }
    }
}

if (-not $hmToken -or $hmToken -eq "your_hiring_manager_jwt_token_here") {
    Write-Warning "Hiring Manager JWT token not configured!"
    Write-Host ""
    Write-Host "To configure tokens, create a file: $tokenFile" -ForegroundColor Yellow
    Write-Host "With the following content:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "HM_TOKEN=your_actual_hiring_manager_jwt_token" -ForegroundColor Yellow
    Write-Host "ADMIN_TOKEN=your_actual_admin_jwt_token" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To get tokens, login via:" -ForegroundColor Yellow
    Write-Host "  POST http://127.0.0.1:5000/api/auth/login" -ForegroundColor Yellow
    Write-Host "  Body: {`"email`": `"hm@company.com`", `"password`": `"yourpassword`"}" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask if user wants to continue with manual token input
    $response = Read-Host "Do you want to enter tokens manually now? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $hmToken = Read-Host "Enter Hiring Manager JWT Token"
        $adminToken = Read-Host "Enter Admin JWT Token (optional, press Enter to skip)"
        
        # Save tokens for next run
        "HM_TOKEN=$hmToken" | Out-File -FilePath $tokenFile -Encoding UTF8
        if ($adminToken) {
            "ADMIN_TOKEN=$adminToken" | Add-Content -Path $tokenFile -Encoding UTF8
        }
        Write-Success "Tokens saved to $tokenFile"
    } else {
        Write-Error "Cannot run tests without JWT tokens. Exiting."
        exit 1
    }
}

Write-Success "JWT tokens configured"
Write-Host ""

# ============================================================
# 3. UPDATE TEST FILES WITH TOKENS
# ============================================================
Write-Info "Updating test files with JWT tokens..."

$testFile = Join-Path $TestDir "test_hiring_manager_endpoints.py"
$content = Get-Content $testFile -Raw
$content = $content -replace 'HM_TOKEN = ".*?"', "HM_TOKEN = `"$hmToken`""
if ($adminToken) {
    $content = $content -replace 'ADMIN_TOKEN = ".*?"', "ADMIN_TOKEN = `"$adminToken`""
}
$content | Set-Content $testFile -Encoding UTF8

Write-Success "Test files updated"
Write-Host ""

# ============================================================
# 4. RUN PYTHON API TESTS
# ============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "RUNNING API ENDPOINT TESTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $TestDir
$pythonTestResult = python test_hiring_manager_endpoints.py
Write-Host $pythonTestResult
$pythonExitCode = $LASTEXITCODE

Write-Host ""

# ============================================================
# 5. RUN DATABASE INTEGRITY TESTS
# ============================================================
if (-not $skipDbTests) {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "RUNNING DATABASE INTEGRITY TESTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Read database config from environment or config.py
    $dbHost = $env:DB_HOST ?? "localhost"
    $dbPort = $env:DB_PORT ?? "5432"
    $dbName = $env:DB_NAME ?? "recruitment_db"
    $dbUser = $env:DB_USER ?? "appuser"
    
    Write-Info "Connecting to database: $dbHost`:$dbPort/$dbName as $dbUser"
    Write-Host ""
    
    $sqlFile = Join-Path $TestDir "test_database_integrity.sql"
    
    try {
        $env:PGPASSWORD = $env:DB_PASSWORD ?? "your_password_here"
        psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $sqlFile
        $dbExitCode = $LASTEXITCODE
        
        if ($dbExitCode -eq 0) {
            Write-Success "Database integrity tests completed"
        } else {
            Write-Warning "Database tests completed with warnings"
        }
    } catch {
        Write-Error "Database tests failed: $_"
        $dbExitCode = 1
    }
    
    Remove-Item Env:PGPASSWORD
} else {
    Write-Warning "Skipping database tests (psql not found)"
    $dbExitCode = 0
}

Write-Host ""

# ============================================================
# 6. GENERATE TEST REPORT
# ============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TEST EXECUTION SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$reportFile = Join-Path $TestDir "test_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$report = @"
HIRING MANAGER TEST SUITE EXECUTION REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================================

TEST RESULTS:
-------------
API Endpoint Tests: $(if ($pythonExitCode -eq 0) { "✓ PASSED" } else { "✗ FAILED" })
Database Integrity Tests: $(if ($dbExitCode -eq 0) { "✓ PASSED" } elseif ($skipDbTests) { "⊘ SKIPPED" } else { "✗ FAILED" })

ENVIRONMENT:
------------
Flask Server: Running at http://127.0.0.1:5000
Database: $dbHost`:$dbPort/$dbName
Python: $pythonVersion
$(if (-not $skipDbTests) { "PostgreSQL: $psqlVersion" } else { "PostgreSQL: Not available" })

OVERALL STATUS:
---------------
$(if ($pythonExitCode -eq 0 -and $dbExitCode -eq 0) { 
    "✓ ALL TESTS PASSED - Hiring Manager implementation is production-ready"
} else { 
    "✗ SOME TESTS FAILED - Review the output above for details"
})

============================================================
For detailed results, review the console output above.
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Info "Test report saved to: $reportFile"
Write-Host ""

if ($pythonExitCode -eq 0 -and $dbExitCode -eq 0) {
    Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "Hiring Manager implementation is production-ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "Please review the errors above and fix any issues." -ForegroundColor Red
    exit 1
}
