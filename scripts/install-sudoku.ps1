param(
    [string]$SourcePath = $null
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

function Resolve-SudokuSource {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        return $RequestedPath
    }

    if ($env:SUDOKU_SOURCE) {
        return $env:SUDOKU_SOURCE
    }

    $candidates = @(
        (Join-Path $HOME "git\languages\rust\Sudoku")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "Cargo.toml")) {
            return $candidate
        }
    }

    return $candidates[0]
}

function Get-CargoPackageName {
    param([Parameter(Mandatory = $true)][string]$CargoToml)

    $inPackage = $false
    foreach ($line in Get-Content -LiteralPath $CargoToml) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^\[(?<Section>[^\]]+)\]$") {
            $inPackage = $Matches.Section -eq "package"
            continue
        }

        if ($inPackage -and $trimmed -match '^name\s*=\s*"(?<Name>[^"]+)"') {
            return $Matches.Name
        }
    }

    return "sudoku"
}

$SourcePath = Resolve-SudokuSource -RequestedPath $SourcePath
if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Warning "Skipping Sudoku install because the source checkout was not found at '$SourcePath'. Set SUDOKU_SOURCE to override."
    return
}

$cargoToml = Join-Path $SourcePath "Cargo.toml"
if (-not (Test-Path -LiteralPath $cargoToml)) {
    throw "Sudoku source path exists but does not contain Cargo.toml: $SourcePath"
}

$cargo = Resolve-CargoPath
if (-not $cargo) {
    Write-Warning "Skipping Sudoku install because cargo.exe was not found. Install Rust and rerun install.ps1."
    return
}

$packageName = Get-CargoPackageName -CargoToml $cargoToml

Write-Host "Installing Sudoku from $SourcePath..."
& $cargo install --path $SourcePath --locked --force
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Skipping Sudoku update because cargo install failed with exit code $LASTEXITCODE. If $packageName.exe is running, close it and rerun scripts\install-sudoku.ps1."
    return
}

$cargoInstallRoot = $env:CARGO_INSTALL_ROOT
if (-not $cargoInstallRoot) {
    $cargoInstallRoot = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $HOME ".cargo" }
}

$sudokuExe = Join-Path $cargoInstallRoot "bin\$packageName.exe"
if (Test-Path $sudokuExe) {
    Write-Host "Sudoku installed at $sudokuExe"
} else {
    Write-Warning "Sudoku install completed, but $packageName.exe was not found at the expected path: $sudokuExe"
}
