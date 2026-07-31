$ErrorActionPreference = "Stop"

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warning "Skipping OpenWhispr install because winget.exe was not found. Install App Installer and rerun install.ps1."
    return
}

Write-Host "Installing or updating OpenWhispr..."
& $winget.Source install --exact --id OpenWhispr.OpenWhispr --scope user --accept-package-agreements --accept-source-agreements --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    Write-Warning "OpenWhispr install or update failed with exit code $LASTEXITCODE. Rerun scripts\\install-openwhispr.ps1 after resolving the winget issue."
    return
}

Write-Host "OpenWhispr is installed."
