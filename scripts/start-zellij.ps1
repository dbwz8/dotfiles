param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ZellijArgs
)

$ErrorActionPreference = "Stop"

if (-not $env:DOTFILES) {
    $env:DOTFILES = Split-Path -Parent $PSScriptRoot
}

$zellijConfigDir = Join-Path $env:DOTFILES "configs\zellij"
$zellijConfigFile = Join-Path $zellijConfigDir "config.kdl"
$windowsLayoutFile = Join-Path $zellijConfigDir "layouts\windows-starter.kdl"
if (Test-Path $zellijConfigDir) {
    $env:ZELLIJ_CONFIG_DIR = $zellijConfigDir
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
if (Test-Path $zellijConfigFile) {
    $zellijConfigArgs += @("--config", $zellijConfigFile)
}

if ($ZellijArgs.Count -gt 0) {
    & $zellij.Source @zellijConfigArgs @ZellijArgs
    exit $LASTEXITCODE
}

$sessionName = "standard"
$existingSessions = & $zellij.Source @zellijConfigArgs list-sessions 2>$null
if ($LASTEXITCODE -eq 0 -and ($existingSessions -split "`r?`n" | ForEach-Object { ($_ -split '\s+', 2)[0] } | Where-Object { $_ -eq $sessionName })) {
    & $zellij.Source @zellijConfigArgs attach $sessionName
    exit $LASTEXITCODE
}

if (Test-Path $windowsLayoutFile) {
    & $zellij.Source @zellijConfigArgs -s $sessionName -l $windowsLayoutFile
} else {
    & $zellij.Source @zellijConfigArgs -s $sessionName -l windows-starter
}
exit $LASTEXITCODE

