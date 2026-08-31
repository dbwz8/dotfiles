$ErrorActionPreference = "Stop"

$packageId = "OpenWhispr.OpenWhispr"
$noApplicableUpgradeExitCode = -1978335189 # 0x8A15002B
$downloadNotFoundExitCode = -2145844844 # 0x80190194
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warning "Skipping OpenWhispr install because winget.exe was not found. Install App Installer and rerun install.ps1."
    return
}

function Install-LatestOpenWhisprRelease {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/OpenWhispr/openwhispr/releases/latest" -Headers @{ "User-Agent" = "dotfiles-installer" }
    $installer = $release.assets | Where-Object { $_.name -match "^OpenWhispr-Setup-.+\\.exe$" } | Select-Object -First 1
    if (-not $installer -or -not $installer.digest.StartsWith("sha256:")) {
        throw "The latest OpenWhispr release does not contain a verified Windows installer."
    }

    $installerPath = Join-Path $env:TEMP $installer.name
    try {
        Invoke-WebRequest -Uri $installer.browser_download_url -OutFile $installerPath
        $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = $installer.digest.Substring("sha256:".Length).ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "The downloaded OpenWhispr installer hash did not match the GitHub release metadata."
        }

        $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "The OpenWhispr installer exited with code $($process.ExitCode)."
        }
    } finally {
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
    }
}

& $winget.Source list --exact --id $packageId --source winget --accept-source-agreements | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Updating OpenWhispr..."
    & $winget.Source upgrade --exact --id $packageId --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
} else {
    Write-Host "Installing OpenWhispr..."
    & $winget.Source install --exact --id $packageId --source winget --scope user --accept-package-agreements --accept-source-agreements --disable-interactivity
}

if ($LASTEXITCODE -eq $noApplicableUpgradeExitCode) {
    Write-Host "OpenWhispr is already up to date."
    $global:LASTEXITCODE = 0
    return
}

if ($LASTEXITCODE -ne 0) {
    if ($LASTEXITCODE -ne $downloadNotFoundExitCode) {
        Write-Warning "OpenWhispr install or update failed with exit code $LASTEXITCODE."
        return
    }
    Write-Warning "Winget could not install or update OpenWhispr (exit code $LASTEXITCODE). Downloading the latest verified release from GitHub instead."
    try {
        Install-LatestOpenWhisprRelease
    } catch {
        Write-Warning "OpenWhispr install or update failed: $($_.Exception.Message)"
        return
    }
    $global:LASTEXITCODE = 0
}

Write-Host "OpenWhispr is installed."
