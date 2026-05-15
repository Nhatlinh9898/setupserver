@echo off
REM Quick Build Script - Double click to run
REM This will run the PowerShell build script

echo ========================================
echo   Linux Server Setup - Quick Build
echo ========================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found
    echo Please install PowerShell or run build.ps1 manually
    pause
    exit /b 1
)

REM Run the PowerShell build script
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*

REM Pause to see output
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Build completed successfully
pause
