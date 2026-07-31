$ErrorActionPreference = "Stop"

$officialPackageId = "Zellij.Zellij"
$legacyPackageId = "arndawg.zellij-windows"
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warning "Skipping Zellij install because winget.exe was not found. Install App Installer and rerun install.ps1."
    return
}

Write-Host "Installing or updating official Zellij..."
& $winget.Source install --exact --id $officialPackageId --accept-package-agreements --accept-source-agreements --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Official Zellij install or update failed with exit code $LASTEXITCODE. The legacy Zellij package was not removed."
    return
}

& $winget.Source list --exact --id $legacyPackageId --source winget --accept-source-agreements | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Removing obsolete Zellij Windows fork..."
    & $winget.Source uninstall --exact --id $legacyPackageId --source winget --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Official Zellij was installed, but removing the legacy fork failed with exit code $LASTEXITCODE."
        return
    }
}

Write-Host "Official Zellij is installed."
