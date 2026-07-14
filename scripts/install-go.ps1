$ErrorActionPreference = "Stop"

function Test-IsDisabled {
    param([string]$Value)

    return $Value -in @("0", "false", "FALSE", "no", "NO")
}

if (Test-IsDisabled -Value $env:DOTFILES_INSTALL_GO) {
    return
}

$GoVersionUrl = if ($env:DOTFILES_GO_VERSION_URL) { $env:DOTFILES_GO_VERSION_URL } else { "https://go.dev/VERSION?m=text" }
$GoDownloadBase = if ($env:DOTFILES_GO_DOWNLOAD_BASE) { $env:DOTFILES_GO_DOWNLOAD_BASE } else { "https://go.dev/dl" }
$GoInstallRoot = if ($env:DOTFILES_GO_INSTALL_ROOT) { $env:DOTFILES_GO_INSTALL_ROOT } else { Join-Path $HOME ".local\go" }
$DefaultGoTools = @("golang.org/x/tools/gopls@latest", "golang.org/x/tools/cmd/goimports@latest")
$GoTools = if ($env:DOTFILES_GO_TOOLS) { $env:DOTFILES_GO_TOOLS -split "\s+" | Where-Object { $_ } } else { $DefaultGoTools }

function Normalize-GoVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    if ($Version.StartsWith("go")) {
        return $Version
    }

    return "go$Version"
}

function Get-LatestGoVersion {
    if ($env:DOTFILES_GO_VERSION) {
        return Normalize-GoVersion -Version $env:DOTFILES_GO_VERSION
    }

    $response = Invoke-RestMethod -Uri $GoVersionUrl
    $line = (($response -split "`n") | Select-Object -First 1).Trim()
    $version = ($line -split "\s+") | Select-Object -First 1
    if (-not $version -or -not $version.StartsWith("go")) {
        throw "Could not resolve the latest Go version from $GoVersionUrl."
    }

    return $version
}

function Get-GoArch {
    $arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    switch ($arch.ToUpperInvariant()) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { throw "Unsupported Go architecture: $arch" }
    }
}

function ConvertTo-GoVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    $numeric = (($Version -replace "^go", "") -split "[-+]")[0]
    return [version]$numeric
}

function Get-InstalledGoVersion {
    param([Parameter(Mandatory = $true)][string]$GoExe)

    if (-not (Test-Path $GoExe)) {
        return $null
    }

    $versionLine = & $GoExe version 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    if ($versionLine -match "go version (?<Version>go[^\s]+)") {
        return $Matches.Version
    }

    return $null
}

function Add-UserPathEntry {
    param([Parameter(Mandatory = $true)][string]$PathEntry)

    New-Item -ItemType Directory -Force -Path $PathEntry | Out-Null

    $pathSeparator = [System.IO.Path]::PathSeparator
    if (-not (($env:PATH -split $pathSeparator) -contains $PathEntry)) {
        $env:PATH = "$PathEntry$pathSeparator$env:PATH"
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userPathEntries = @()
    if ($userPath) {
        $userPathEntries = $userPath -split $pathSeparator | Where-Object { $_ }
    }

    if (-not ($userPathEntries -contains $PathEntry)) {
        $userPathEntries += $PathEntry
        [Environment]::SetEnvironmentVariable("Path", ($userPathEntries -join $pathSeparator), "User")
    }
}

function Get-GoArchiveSha256 {
    param([Parameter(Mandatory = $true)][string]$ArchiveName)

    $releases = Invoke-RestMethod -Uri "$GoDownloadBase/?mode=json&include=all"
    $file = $releases.files | Where-Object { $_.filename -eq $ArchiveName } | Select-Object -First 1
    if (-not $file -or -not $file.sha256) {
        throw "Could not find a SHA-256 checksum for $ArchiveName."
    }

    return $file.sha256
}

function Install-GoArchive {
    param(
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$InstallRoot
    )

    $extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-go"
    if (Test-Path $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null

    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extractRoot -Force
    $expandedRoot = Join-Path $extractRoot "go"
    if (-not (Test-Path (Join-Path $expandedRoot "bin\go.exe"))) {
        throw "Downloaded Go archive did not contain go\bin\go.exe."
    }

    if (Test-Path $InstallRoot) {
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallRoot) | Out-Null
    Move-Item -LiteralPath $expandedRoot -Destination $InstallRoot
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
}

function Install-GoTools {
    param([Parameter(Mandatory = $true)][string]$GoExe)

    if (Test-IsDisabled -Value $env:DOTFILES_INSTALL_GO_TOOLS) {
        return
    }

    if (-not $GoTools -or $GoTools.Count -eq 0) {
        return
    }

    $userGoPath = [Environment]::GetEnvironmentVariable("GOPATH", "User")
    $goPath = if ($env:GOPATH) { $env:GOPATH } elseif ($userGoPath) { $userGoPath } else { Join-Path $HOME "go" }
    $goBinInstall = if ($env:GOBIN) { $env:GOBIN } else { Join-Path $goPath "bin" }
    $goRootBin = Split-Path -Parent $GoExe

    $env:GOROOT = $GoInstallRoot
    $env:GOPATH = $goPath
    $env:GOBIN = $goBinInstall
    $env:GOMODCACHE = if ($env:GOMODCACHE) { $env:GOMODCACHE } else { Join-Path $goPath "pkg\mod" }
    $env:GOCACHE = if ($env:GOCACHE) { $env:GOCACHE } else { Join-Path $HOME ".cache\go-build" }
    $env:PATH = "$goRootBin$([System.IO.Path]::PathSeparator)$goBinInstall$([System.IO.Path]::PathSeparator)$env:PATH"

    Add-UserPathEntry -PathEntry $goRootBin
    Add-UserPathEntry -PathEntry $goBinInstall
    [Environment]::SetEnvironmentVariable("GOROOT", $GoInstallRoot, "User")
    [Environment]::SetEnvironmentVariable("GOBIN", $goBinInstall, "User")
    [Environment]::SetEnvironmentVariable("GOMODCACHE", $env:GOMODCACHE, "User")
    [Environment]::SetEnvironmentVariable("GOCACHE", $env:GOCACHE, "User")
    if (-not $userGoPath) {
        [Environment]::SetEnvironmentVariable("GOPATH", $goPath, "User")
    }

    foreach ($tool in $GoTools) {
        Write-Host "Installing Go tool $tool..."
        & $GoExe install $tool
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Go tool $tool."
        }
    }
}

$latestVersion = Get-LatestGoVersion
$goArch = Get-GoArch
$goExe = Join-Path $GoInstallRoot "bin\go.exe"
$installedVersion = Get-InstalledGoVersion -GoExe $goExe

if ($installedVersion) {
    $installedComparable = ConvertTo-GoVersion -Version $installedVersion
    $latestComparable = ConvertTo-GoVersion -Version $latestVersion
    if ($installedComparable -ge $latestComparable) {
        Write-Host "Go $installedVersion is already installed at $GoInstallRoot."
        Install-GoTools -GoExe $goExe
        return
    }
}

$archiveName = "$latestVersion.windows-$goArch.zip"
$archivePath = Join-Path ([System.IO.Path]::GetTempPath()) $archiveName
$archiveUri = "$GoDownloadBase/$archiveName"

Write-Host "Installing Go $latestVersion for windows/$goArch..."
Invoke-WebRequest -Uri $archiveUri -OutFile $archivePath

$expectedHash = Get-GoArchiveSha256 -ArchiveName $archiveName
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash.ToLowerInvariant()) {
    throw "SHA-256 verification failed for $archiveName."
}

Install-GoArchive -ArchivePath $archivePath -InstallRoot $GoInstallRoot
& $goExe version
Install-GoTools -GoExe $goExe
