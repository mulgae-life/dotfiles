@echo off
rem dotfiles Windows installer entry point - CMD, PowerShell, or double-click from Explorer.
rem Runs install.ps1 with the execution policy bypassed for this process only.
rem Keep this file ASCII-only: cmd.exe reads batch files in the OEM code page, so UTF-8 text can break parsing.
setlocal
set "PS1=%~dp0install.ps1"
if not exist "%PS1%" goto :missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"
rem Launched with /c (double-click or from PowerShell): keep the window open so the log stays readable.
rem Delayed expansion keeps characters such as & or ) in the path from breaking this check.
setlocal EnableDelayedExpansion
if /i not "!CMDCMDLINE:/c =!"=="!CMDCMDLINE!" pause
endlocal
exit /b %RC%

:missing
echo [ERROR] install.ps1 not found next to install.cmd: "%PS1%"
exit /b 1
