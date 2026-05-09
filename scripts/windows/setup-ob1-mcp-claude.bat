@echo off
REM LF2B OB1 MCP Setup for Windows — Launcher for PowerShell script
REM This batch file simply launches the PowerShell setup script with proper execution policy

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║ LF2B OB1 MCP Setup — Windows Claude Configuration             ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Check if PowerShell script exists
if not exist "%SCRIPT_DIR%setup-ob1-mcp-claude.ps1" (
  echo ERROR: setup-ob1-mcp-claude.ps1 not found in %SCRIPT_DIR%
  pause
  exit /b 1
)

REM Run the PowerShell script with appropriate execution policy
REM -NoExit keeps the window open if there's an error
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-ob1-mcp-claude.ps1" %*

if errorlevel 1 (
  echo.
  echo Setup encountered an error. Press any key to exit.
  pause
  exit /b 1
)

echo.
echo Setup completed. You can close this window.
echo.
pause
