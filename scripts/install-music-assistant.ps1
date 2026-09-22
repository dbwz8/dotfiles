$ErrorActionPreference = "Stop"

$packageName = "Music Assistant"
$releaseApi = "https://api.github.com/repos/music-assistant/desktop-app/releases/latest"

function Get-InstalledMusicAssistantVersion {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $package = Get-ItemProperty -Path $uninstallPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq $packageName } |
        Select-Object -First 1

    if ($package -and $package.DisplayVersion) {
        return [Version]$package.DisplayVersion
    }
}

if (-not [Environment]::Is64BitOperatingSystem) {
    throw "Music Assistant Companion is supported only on 64-bit Windows."
}

$architecture = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
$release = Invoke-RestMethod -Uri $releaseApi -Headers @{ "User-Agent" = "dotfiles-installer" }
$latestVersion = [Version]($release.tag_name.TrimStart("v"))
$installedVersion = Get-InstalledMusicAssistantVersion

if ($installedVersion -and $installedVersion -ge $latestVersion) {
    Write-Host "$packageName is already up to date ($installedVersion)."
    return
}

$installer = $release.assets |
    Where-Object { $_.name -match "^Music\.Assistant_.+_${architecture}_en-US\.msi$" } |
    Select-Object -First 1
if (-not $installer -or -not $installer.digest.StartsWith("sha256:")) {
    throw "The latest Music Assistant release does not contain a verified $architecture Windows MSI."
}

$action = if ($installedVersion) { "Updating" } else { "Installing" }
Write-Host "$action $packageName to $latestVersion..."
$installerPath = Join-Path $env:TEMP $installer.name

try {
    Invoke-WebRequest -Uri $installer.browser_download_url -OutFile $installerPath
    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedHash = $installer.digest.Substring("sha256:".Length).ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "The downloaded Music Assistant installer hash did not match the GitHub release metadata."
    }

    Get-Process -Name "music-assistant-companion" -ErrorAction SilentlyContinue |
        Stop-Process -Force
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList @("/i", $installerPath, "/qn", "/norestart") -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "The Music Assistant installer exited with code $($process.ExitCode)."
    }
} finally {
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
}

$installedVersion = Get-InstalledMusicAssistantVersion
if (-not $installedVersion -or $installedVersion -lt $latestVersion) {
    throw "Music Assistant installation completed, but version $latestVersion was not detected."
}

Write-Host "$packageName is installed at version $installedVersion."