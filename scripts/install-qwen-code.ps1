$ErrorActionPreference = "Stop"

if ($env:DOTFILES_INSTALL_QWEN_CODE -match "^(0|false|FALSE|no|NO)$") {
    Write-Host "Skipping Qwen Code install because DOTFILES_INSTALL_QWEN_CODE=$env:DOTFILES_INSTALL_QWEN_CODE."
    exit 0
}

function Add-PathPrefix {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ((Test-Path $Path) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $Path)) {
        $env:PATH = "$Path$([System.IO.Path]::PathSeparator)$env:PATH"
    }
}

$qwenCommand = Get-Command qwen -ErrorAction SilentlyContinue
if ($qwenCommand) {
    Add-PathPrefix (Split-Path -Parent $qwenCommand.Source)
    Write-Host "Qwen Code already installed at $($qwenCommand.Source)."
    exit 0
}

$localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME "AppData\Local" }
if ($env:QWEN_INSTALL_BIN_DIR) {
    $installBinDir = $env:QWEN_INSTALL_BIN_DIR
} else {
    $installBinDir = Join-Path $localAppData "qwen-code\bin"
}
$qwenCandidates = @("qwen.exe", "qwen.cmd", "qwen.ps1", "qwen") | ForEach-Object { Join-Path $installBinDir $_ }
$installedQwen = $qwenCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($installedQwen) {
    Add-PathPrefix $installBinDir
    Write-Host "Qwen Code already installed at $installedQwen."
    exit 0
}

Write-Host "Installing Qwen Code with the official standalone installer..."
$previousNoModifyPath = $env:QWEN_NO_MODIFY_PATH
$env:QWEN_NO_MODIFY_PATH = "1"

try {
    $installerUrl = "https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.ps1"
    $installer = Invoke-RestMethod -Uri $installerUrl
    & ([scriptblock]::Create($installer)) --no-modify-path
} finally {
    if ($null -eq $previousNoModifyPath) {
        Remove-Item Env:\QWEN_NO_MODIFY_PATH -ErrorAction SilentlyContinue
    } else {
        $env:QWEN_NO_MODIFY_PATH = $previousNoModifyPath
    }
}

$qwenCommand = Get-Command qwen -ErrorAction SilentlyContinue
if ($qwenCommand) {
    Add-PathPrefix (Split-Path -Parent $qwenCommand.Source)
    Write-Host "Qwen Code installed at $($qwenCommand.Source)."
    exit 0
}

$installedQwen = $qwenCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($installedQwen) {
    Add-PathPrefix $installBinDir
    Write-Host "Qwen Code installed at $installedQwen."
    exit 0
}

throw "Qwen Code installation finished, but no qwen command was found."
