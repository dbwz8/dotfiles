$ErrorActionPreference = "Stop"

$officialPackageId = "Zellij.Zellij"
$legacyPackageId = "arndawg.zellij-windows"
$noApplicableUpgradeExitCode = -1978335189 # 0x8A15002B
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warning "Skipping Zellij install because winget.exe was not found. Install App Installer and rerun install.ps1."
    return
}

& $winget.Source list --exact --id $officialPackageId --source winget --accept-source-agreements | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Updating official Zellij..."
    & $winget.Source upgrade --exact --id $officialPackageId --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -eq $noApplicableUpgradeExitCode) {
        Write-Host "Official Zellij is already up to date."
        $global:LASTEXITCODE = 0
    } elseif ($LASTEXITCODE -ne 0) {
        Write-Warning "Official Zellij update failed with exit code $LASTEXITCODE. The legacy Zellij package was not removed."
        return
    }
} else {
    Write-Host "Installing official Zellij..."
    & $winget.Source install --exact --id $officialPackageId --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Official Zellij install failed with exit code $LASTEXITCODE. The legacy Zellij package was not removed."
        return
    }
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
$global:LASTEXITCODE = 0
