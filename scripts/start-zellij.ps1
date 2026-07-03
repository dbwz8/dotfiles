param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ZellijArgs
)

$ErrorActionPreference = "Stop"

if (-not $env:DOTFILES) {
    $env:DOTFILES = Split-Path -Parent $PSScriptRoot
}

$zellijConfigDir = Join-Path $env:DOTFILES "configs\zellij"
if (Test-Path $zellijConfigDir) {
    $env:ZELLIJ_CONFIG_DIR = $zellijConfigDir
}

if (-not $env:SHELL) {
    $env:SHELL = "pwsh.exe"
}

$repoBin = Join-Path $env:DOTFILES "bin"
if ((Test-Path $repoBin) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $repoBin)) {
    $env:PATH = "$repoBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

$zellij = Get-Command zellij.exe -ErrorAction Stop
$zellijConfigArgs = @()
if (Test-Path $zellijConfigDir) {
    $zellijConfigArgs += @("--config-dir", $zellijConfigDir)
}

& $zellij.Source @zellijConfigArgs @ZellijArgs
exit $LASTEXITCODE
