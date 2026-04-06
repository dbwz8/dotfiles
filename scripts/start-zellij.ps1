param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ZellijArgs
)

$ErrorActionPreference = "Stop"

if (-not $env:DOTFILES) {
    $env:DOTFILES = Split-Path -Parent $PSScriptRoot
}

$repoBin = Join-Path $env:DOTFILES "bin"
if ((Test-Path $repoBin) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $repoBin)) {
    $env:PATH = "$repoBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

$zellij = Get-Command zellij.exe -ErrorAction Stop

if ($ZellijArgs.Count -gt 0) {
    & $zellij.Source @ZellijArgs
    exit $LASTEXITCODE
}

$sessionName = "standard"
$existingSessions = & $zellij.Source list-sessions 2>$null
if ($LASTEXITCODE -eq 0 -and ($existingSessions -split "`r?`n" | ForEach-Object { ($_ -split '\s+', 2)[0] } | Where-Object { $_ -eq $sessionName })) {
    & $zellij.Source attach $sessionName
    exit $LASTEXITCODE
}

& $zellij.Source -s $sessionName -l windows-starter
exit $LASTEXITCODE

