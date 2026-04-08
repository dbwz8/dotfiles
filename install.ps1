$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot
$env:DOTFILES = $RepoRoot

$githubAuthValid = $false
$env:GITHUB_TOKEN = $null
$env:GH_TOKEN = $null

$gh = Get-Command gh.exe -ErrorAction SilentlyContinue
if ($gh) {
    try {
        $token = & $gh.Source auth token 2>$null
        if ($LASTEXITCODE -eq 0 -and $token) {
            $resolvedToken = ($token | Select-Object -First 1).Trim()
            if ($resolvedToken) {
                $oldGhToken = $env:GH_TOKEN
                $oldGithubToken = $env:GITHUB_TOKEN
                $env:GITHUB_TOKEN = $resolvedToken
                $env:GH_TOKEN = $resolvedToken
                & $gh.Source api user 1>$null 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $githubAuthValid = $true
                } else {
                    $env:GITHUB_TOKEN = $oldGithubToken
                    $env:GH_TOKEN = $oldGhToken
                }
            }
        }
    } catch {
    }
}

function Get-UvPath {
    $uv = Get-Command uv.exe -ErrorAction SilentlyContinue
    if ($uv) {
        return $uv.Source
    }

    $candidate = Join-Path $HOME ".dotbins\windows\amd64\bin\uv.exe"
    if (Test-Path $candidate) {
        return $candidate
    }

    throw "uv is unavailable. Install uv or sync dotbins first."
}

function Invoke-Dotbot {
    $dotbot = Join-Path $RepoRoot "submodules\dotbot\bin\dotbot"
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    $python = Get-Command python.exe -ErrorAction SilentlyContinue

    if ((Test-Path $dotbot) -and $py) {
        & $py.Source -3 $dotbot -d $RepoRoot -c "install.windows.conf.yaml"
        return
    }

    if ((Test-Path $dotbot) -and $python) {
        & $python.Source $dotbot -d $RepoRoot -c "install.windows.conf.yaml"
        return
    }

    $uv = Get-UvPath
    & $uv tool run dotbot -d $RepoRoot -c "install.windows.conf.yaml"
}

function Resolve-PwshPath {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwsh) {
        return $pwsh.Source
    }

    $candidatePaths = @(
        (Join-Path ${env:ProgramFiles} "PowerShell\7\pwsh.exe"),
        (Join-Path ${env:ProgramW6432} "PowerShell\7\pwsh.exe"),
        (Join-Path $HOME "AppData\Local\Microsoft\WindowsApps\pwsh.exe")
    ) | Where-Object { $_ }

    foreach ($candidate in $candidatePaths) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $winGetPackagesDir = Join-Path $HOME "AppData\Local\Microsoft\WinGet\Packages"
    if (Test-Path $winGetPackagesDir) {
        $discoveredPwsh = Get-ChildItem -Path $winGetPackagesDir -Recurse -Filter pwsh.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($discoveredPwsh) {
            return $discoveredPwsh
        }
    }

    return $null
}

function Ensure-Pwsh {
    $pwshPath = Resolve-PwshPath
    if (-not $pwshPath) {
        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw "pwsh.exe is required for the Windows shell setup, but it is not installed and winget.exe is unavailable."
        }

        Write-Host "Installing PowerShell 7 with winget..."
        & $winget.Source install --exact --id Microsoft.PowerShell --scope user --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install PowerShell 7 with winget."
        }

        $pwshPath = Resolve-PwshPath
        if (-not $pwshPath) {
            throw "PowerShell 7 installation completed, but pwsh.exe could not be located afterwards."
        }
    }

    $pwshBinDir = Split-Path -Parent $pwshPath
    if ($pwshBinDir -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $pwshBinDir)) {
        $env:PATH = "$pwshBinDir$([System.IO.Path]::PathSeparator)$env:PATH"
    }

    return $pwshPath
}

Ensure-Pwsh | Out-Null

Invoke-Dotbot

$zellijSourceDir = Join-Path $RepoRoot "configs\zellij"
if (Test-Path $zellijSourceDir) {
    foreach ($zellijTargetDir in @(
        (Join-Path $HOME ".config\zellij"),
        (Join-Path $env:APPDATA "Zellij\config")
    )) {
        New-Item -ItemType Directory -Force -Path $zellijTargetDir | Out-Null
        Copy-Item (Join-Path $zellijSourceDir "*") $zellijTargetDir -Recurse -Force
    }
}

$dotbinsDir = Join-Path $HOME ".dotbins"
New-Item -ItemType Directory -Force -Path $dotbinsDir | Out-Null
Copy-Item (Join-Path $RepoRoot "configs\dotbins\dotbins.yaml") (Join-Path $dotbinsDir "dotbins.yaml") -Force

$profileSource = Join-Path $RepoRoot "configs\powershell\Microsoft.PowerShell_profile.ps1"
foreach ($profileDir in @(
    (Join-Path $HOME "Documents\PowerShell"),
    (Join-Path $HOME "Documents\WindowsPowerShell")
)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    Copy-Item $profileSource (Join-Path $profileDir "Microsoft.PowerShell_profile.ps1") -Force
}

& (Join-Path $RepoRoot "scripts\sync-uv-tools.ps1")

$dotbins = $null
$dotbinsCommand = Get-Command dotbins.exe -ErrorAction SilentlyContinue
if ($dotbinsCommand) {
    $dotbins = $dotbinsCommand.Source
} else {
    $candidate = Join-Path $HOME ".local\bin\dotbins.exe"
    if (Test-Path $candidate) {
        $dotbins = $candidate
    }
}

if ($dotbins) {
    $tools = @(
        "delta",
        "duf",
        "dust",
        "fd",
        "gh",
        "git-lfs",
        "hyperfine",
        "rg",
        "yazi",
        "bat",
        "direnv",
        "eza",
        "fzf",
        "lazygit",
        "micromamba",
        "starship",
        "zoxide",
        "atuin",
        "keychain",
        "uv",
        "codex"
    )
    if ($githubAuthValid) {
        & $dotbins sync --current @tools
    } else {
        Write-Warning "Skipping dotbins sync because GitHub CLI authentication is missing or invalid."
        Write-Warning "Run 'gh auth login -h github.com' and then rerun .\install.ps1 to install/update CLI tools."
    }
} else {
    Write-Warning "dotbins is not installed; skipping CLI tool sync."
}
