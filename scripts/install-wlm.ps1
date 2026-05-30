param(
    [string]$SourcePath = $(if ($env:WLM_SOURCE) { $env:WLM_SOURCE } else { Join-Path $HOME "git\languages\rust\WLM" })
)

$ErrorActionPreference = "Stop"

function Resolve-CargoPath {
    $cargo = Get-Command cargo.exe -ErrorAction SilentlyContinue
    if ($cargo) {
        return $cargo.Source
    }

    $candidate = Join-Path $HOME ".cargo\bin\cargo.exe"
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Warning "Skipping WLM install because the source checkout was not found at '$SourcePath'. Set WLM_SOURCE to override."
    return
}

$cargoToml = Join-Path $SourcePath "Cargo.toml"
if (-not (Test-Path -LiteralPath $cargoToml)) {
    throw "WLM source path exists but does not contain Cargo.toml: $SourcePath"
}

$cargo = Resolve-CargoPath
if (-not $cargo) {
    Write-Warning "Skipping WLM install because cargo.exe was not found. Install Rust and rerun install.ps1."
    return
}

Write-Host "Installing WLM from $SourcePath..."
& $cargo install --path $SourcePath --locked --force
if ($LASTEXITCODE -ne 0) {
    throw "cargo install failed for WLM."
}

$cargoInstallRoot = $env:CARGO_INSTALL_ROOT
if (-not $cargoInstallRoot) {
    $cargoInstallRoot = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $HOME ".cargo" }
}

$wlmExe = Join-Path $cargoInstallRoot "bin\WLM.exe"
if (Test-Path $wlmExe) {
    Write-Host "WLM installed at $wlmExe"
} else {
    Write-Warning "WLM install completed, but WLM.exe was not found at the expected path: $wlmExe"
}
