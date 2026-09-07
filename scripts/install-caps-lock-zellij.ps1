$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "configs\windows\caps-lock-zellij.ahk"
$startupDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)
$shortcutPath = Join-Path $startupDir "Caps Lock Zellij Leader.lnk"
$packageId = "AutoHotkey.AutoHotkey"

if (-not (Test-Path $scriptPath)) {
    throw "Caps Lock leader script is missing: $scriptPath"
}

$autoHotkey = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
if (-not $autoHotkey) {
    $autoHotkey = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
}

if (-not $autoHotkey) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "Skipping Caps Lock Zellij leader setup because winget.exe was not found. Install AutoHotkey v2 and rerun install.ps1."
        return
    }

    Write-Host "Installing AutoHotkey for the Caps Lock Zellij leader..."
    & $winget.Source install --exact --id $packageId --source winget --scope user --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install AutoHotkey for the Caps Lock Zellij leader."
    }

    $autoHotkey = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
    if (-not $autoHotkey) {
        $autoHotkey = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
    }
}

if (-not $autoHotkey) {
    throw "AutoHotkey was installed, but its executable could not be located."
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $autoHotkey.Source
$shortcut.Arguments = '"' + $scriptPath + '"'
$shortcut.WorkingDirectory = $repoRoot
$shortcut.Save()

Write-Host "Configured Caps Lock as Zellij's Ctrl-F1 leader in Windows Terminal. Sign out and back in, or run the shortcut once, to activate it."
