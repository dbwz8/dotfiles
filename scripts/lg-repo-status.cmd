@echo off
where pwsh.exe >nul 2>&1
if errorlevel 1 goto powershell

pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lg-repo-status.ps1"
exit /b %ERRORLEVEL%

:powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lg-repo-status.ps1"
exit /b %ERRORLEVEL%
