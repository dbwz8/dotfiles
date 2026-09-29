$ErrorActionPreference = "Stop"

$packageIds = @(
    "Zellij.Zellij",
    "arndawg.zellij-windows"
)
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Host "Skipping removal of previous Zellij packages because winget.exe was not found."
    return
}

foreach ($packageId in $packageIds) {
    & $winget.Source list --exact --id $packageId --source winget --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) {
        continue
    }

    Write-Host "Removing $packageId in favor of Dotbins-managed zellij-no-web..."
    & $winget.Source uninstall --exact --id $packageId --source winget --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Removing $packageId failed with exit code $LASTEXITCODE."
        return
    }
}

Write-Host "zellij-no-web will be installed and updated by Dotbins."
$global:LASTEXITCODE = 0
