@echo off
REM 🚀 QuikApp Project Name Update Script (Batch Wrapper)
REM Automatically updates APP_NAME in all Codemagic workflows

echo 🚀 QuikApp Project Name Update Script
echo =====================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell is not available on this system.
    echo Please install PowerShell or use the bash script instead.
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo [ERROR] pubspec.yaml not found.
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

if not exist "codemagic.yaml" (
    echo [ERROR] codemagic.yaml not found.
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [INFO] Starting QuikApp Project Name Update...
echo [INFO] This script will update APP_NAME in all Codemagic workflows
echo [INFO] to use the project name from pubspec.yaml with lowercase and no spaces.
echo.

REM Parse command line arguments
set "args="
if "%1"=="--help" set "args=-Help"
if "%1"=="-h" set "args=-Help"
if "%1"=="--dry-run" set "args=-DryRun"
if "%1"=="-d" set "args=-DryRun"
if "%1"=="--no-backup" set "args=-NoBackup"
if "%1"=="-n" set "args=-NoBackup"
if "%1"=="--verbose" set "args=-Verbose"
if "%1"=="-v" set "args=-Verbose"

REM Run the PowerShell script
echo [INFO] Executing PowerShell script...
powershell -ExecutionPolicy Bypass -File "%~dp0update_project_name.ps1" %args%

REM Check if the script ran successfully
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Script completed successfully!
) else (
    echo.
    echo [ERROR] Script failed with error code %errorlevel%
)

echo.
echo Press any key to exit...
pause >nul
