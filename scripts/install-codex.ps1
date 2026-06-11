$ErrorActionPreference = "Stop"

if ($env:DOTFILES_INSTALL_CODEX -match "^(0|false|FALSE|no|NO)$") {
    Write-Host "Skipping Codex CLI install because DOTFILES_INSTALL_CODEX=$env:DOTFILES_INSTALL_CODEX."
    exit 0
}

function Add-PathPrefix {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ((Test-Path $Path) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $Path)) {
        $env:PATH = "$Path$([System.IO.Path]::PathSeparator)$env:PATH"
    }
}

$localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME "AppData\Local" }
$installDir = if ($env:CODEX_INSTALL_DIR) { $env:CODEX_INSTALL_DIR } else { Join-Path $localAppData "Programs\OpenAI\Codex\bin" }
$codexCandidates = @("codex.exe", "codex.cmd", "codex.ps1") | ForEach-Object { Join-Path $installDir $_ }
$installedCodex = $codexCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($installedCodex) {
    Add-PathPrefix $installDir
    Write-Host "Codex CLI already installed at $installedCodex."
    exit 0
}

Write-Host "Installing Codex CLI with the OpenAI standalone installer..."
$previousNonInteractive = $env:CODEX_NON_INTERACTIVE
$env:CODEX_NON_INTERACTIVE = "1"

try {
    Invoke-Expression (Invoke-RestMethod -Uri "https://chatgpt.com/codex/install.ps1")
} finally {
    if ($null -eq $previousNonInteractive) {
        Remove-Item Env:\CODEX_NON_INTERACTIVE -ErrorAction SilentlyContinue
    } else {
        $env:CODEX_NON_INTERACTIVE = $previousNonInteractive
    }
}

$installedCodex = $codexCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($installedCodex) {
    Add-PathPrefix $installDir
    Write-Host "Codex CLI installed at $installedCodex."
    exit 0
}

$codexCommand = Get-Command codex -ErrorAction SilentlyContinue
if ($codexCommand) {
    Add-PathPrefix (Split-Path -Parent $codexCommand.Source)
    Write-Host "Codex CLI is available at $($codexCommand.Source)."
    exit 0
}

throw "Codex CLI installation finished, but no codex command was found."
