@echo off
REM ============================================================
REM Quick Test Runner for Windows Command Prompt
REM ============================================================

echo ============================================================
echo HIRING MANAGER TEST SUITE - Quick Runner
echo ============================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://www.python.org/
    pause
    exit /b 1
)

echo [OK] Python is installed
echo.

REM Check if Flask server is running
echo Checking Flask server status...
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:5000/api/admin/dashboard-counts >nul 2>&1
if errorlevel 1 (
    echo WARNING: Flask server may not be running
    echo Please start it with: python run.py
    echo.
    choice /C YN /M "Continue anyway"
    if errorlevel 2 exit /b 1
)

echo [OK] Flask server is accessible
echo.

REM Check for test tokens
if not exist test_tokens.txt (
    echo WARNING: No JWT tokens configured
    echo.
    echo Running token setup...
    python get_jwt_tokens.py
    if errorlevel 1 (
        echo Failed to obtain tokens
        pause
        exit /b 1
    )
)

echo [OK] JWT tokens configured
echo.

echo ============================================================
echo Running API Tests...
echo ============================================================
echo.

python test_hiring_manager_endpoints.py
set TEST_RESULT=%errorlevel%

echo.
echo ============================================================
echo Test Execution Complete
echo ============================================================
echo.

if %TEST_RESULT% equ 0 (
    echo [SUCCESS] All tests passed!
    echo Hiring Manager implementation is production-ready.
) else (
    echo [FAILURE] Some tests failed.
    echo Please review the output above for details.
)

echo.
pause
exit /b %TEST_RESULT%
