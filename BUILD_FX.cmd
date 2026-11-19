@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install_duality.ps1" -Mode Demo -BuildAssets -PreserveLaunchMode %*
if errorlevel 1 pause
