@echo off
REM Full Auto Setup - Double click to run
REM This will run the PowerShell full-auto-setup script

echo ========================================
echo   Full Auto Setup - End-to-End
echo ========================================
echo.
echo This script will create a USB bootable
echo for automatic server installation.
echo.
echo Requirements:
echo - USB drive (16GB+)
echo - Ubuntu/CentOS ISO file
echo - Administrator privileges
echo.
pause

REM Check for Administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

REM Get USB drive letter
echo.
echo Available drives:
wmic logicaldisk get deviceid,volumename,description
echo.
set /p USBDRIVE="Enter USB drive letter (e.g., E): "

REM Get ISO path
set /p ISOPATH="Enter path to ISO file: "

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0full-auto-setup.ps1" -USBDrive "%USBDRIVE%:" -ISOPath "%ISOPATH%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Full auto setup failed with error code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Full auto setup completed successfully!
echo.
echo Next steps:
echo 1. Plug USB into server
echo 2. Boot from USB in BIOS/UEFI
echo 3. Wait for automatic installation (30-60 minutes)
echo.
pause
