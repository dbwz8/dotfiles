$ErrorActionPreference = "Stop"

if ($env:DOTFILES_INSTALL_CLAUDE -match "^(0|false|FALSE|no|NO)$") {
    Write-Host "Skipping Claude Code install because DOTFILES_INSTALL_CLAUDE=$env:DOTFILES_INSTALL_CLAUDE."
    exit 0
}

function Add-PathPrefix {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ((Test-Path $Path) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $Path)) {
        $env:PATH = "$Path$([System.IO.Path]::PathSeparator)$env:PATH"
    }
}

$localBin = Join-Path $HOME ".local\bin"
$claudeCommand = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCommand) {
    Add-PathPrefix (Split-Path -Parent $claudeCommand.Source)
    Write-Host "Claude Code already installed at $($claudeCommand.Source)."
    exit 0
}

$claudeCandidates = @("claude.exe", "claude.cmd", "claude.ps1", "claude") | ForEach-Object { Join-Path $localBin $_ }
$installedClaude = $claudeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($installedClaude) {
    Add-PathPrefix $localBin
    Write-Host "Claude Code already installed at $installedClaude."
    exit 0
}

$installVersionOrChannel = if ($env:CLAUDE_INSTALL_VERSION_OR_CHANNEL) { $env:CLAUDE_INSTALL_VERSION_OR_CHANNEL } else { "stable" }
Write-Host "Installing Claude Code with the Anthropic native installer ($installVersionOrChannel)..."

$installer = Invoke-RestMethod -Uri "https://claude.ai/install.ps1"
& ([scriptblock]::Create($installer)) $installVersionOrChannel

$claudeCommand = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCommand) {
    Add-PathPrefix (Split-Path -Parent $claudeCommand.Source)
    Write-Host "Claude Code installed at $($claudeCommand.Source)."
    exit 0
}

$installedClaude = $claudeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($installedClaude) {
    Add-PathPrefix $localBin
    Write-Host "Claude Code installed at $installedClaude."
    exit 0
}

throw "Claude Code installation finished, but no claude command was found."
