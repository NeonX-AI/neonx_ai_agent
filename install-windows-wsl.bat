@echo off
setlocal
cd /d "%~dp0"
title NeonX AI Agent - WSL Docker Installer

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows-wsl.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo NeonX installation completed.
) else if "%EXIT_CODE%"=="3010" (
  echo Windows must restart. Run this file again after restarting.
) else (
  echo Installation failed with exit code %EXIT_CODE%.
)
echo.
pause
exit /b %EXIT_CODE%
