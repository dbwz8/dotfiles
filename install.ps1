$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot
$env:DOTFILES = $RepoRoot

$githubAuthValid = $false
$env:GITHUB_TOKEN = $null
$env:GH_TOKEN = $null

function Ensure-RequiredSubmodules {
    $missing = @()

    if (-not (Test-Path (Join-Path $RepoRoot "submodules\dotbot\bin\dotbot"))) {
        $missing += "submodules/dotbot"
    }

    if (-not (Test-Path (Join-Path $RepoRoot "submodules\kickstart.nvim\init.lua"))) {
        $missing += "submodules/kickstart.nvim"
    }

    if ($missing.Count -eq 0) {
        return
    }

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) {
        throw "git.exe is unavailable; cannot initialize required submodules: $($missing -join ', ')"
    }

    Write-Host "Initializing required submodules: $($missing -join ', ')"
    & $git.Source submodule sync -- @missing
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sync required submodules."
    }

    & $git.Source submodule update --init --recursive -- @missing
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to initialize required submodules."
    }
}

Ensure-RequiredSubmodules

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

function Resolve-NeovimPath {
    $dotbinsNeovim = Join-Path $HOME ".dotbins\windows\amd64\neovim\bin\nvim.exe"
    if (Test-Path $dotbinsNeovim) {
        return $dotbinsNeovim
    }

    $nvim = Get-Command nvim.exe -ErrorAction SilentlyContinue
    if ($nvim) {
        return $nvim.Source
    }

    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Neovim\bin\nvim.exe"),
        (Join-Path ${env:ProgramFiles} "Neovim\bin\nvim.exe"),
        (Join-Path ${env:ProgramW6432} "Neovim\bin\nvim.exe")
    ) | Where-Object { $_ }

    foreach ($candidate in $candidatePaths) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Install-NeovimZip {
    $neovimRoot = Join-Path $HOME ".dotbins\windows\amd64\neovim"
    $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) "nvim-win64.zip"
    $extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-neovim"

    $release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/neovim/neovim/releases/latest" `
        -Headers @{ "User-Agent" = "dotfiles-install" }
    $asset = $release.assets | Where-Object { $_.name -eq "nvim-win64.zip" } | Select-Object -First 1
    if (-not $asset) {
        throw "Could not find nvim-win64.zip in the latest Neovim release."
    }

    if (Test-Path $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force

    $expandedRoot = Join-Path $extractRoot "nvim-win64"
    if (-not (Test-Path (Join-Path $expandedRoot "bin\nvim.exe"))) {
        throw "Downloaded Neovim archive did not contain nvim-win64\bin\nvim.exe."
    }

    if (Test-Path $neovimRoot) {
        Remove-Item -LiteralPath $neovimRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $neovimRoot) | Out-Null
    Move-Item -LiteralPath $expandedRoot -Destination $neovimRoot
}

function Ensure-Neovim {
    $dotbinsNvim = Join-Path $HOME ".dotbins\windows\amd64\bin\nvim.exe"
    if (Test-Path $dotbinsNvim) {
        Write-Host "Removing incomplete dotbins Neovim binary..."
        Remove-Item -LiteralPath $dotbinsNvim -Force
    }

    $nvimPath = Resolve-NeovimPath
    if (-not $nvimPath) {
        Write-Host "Installing Neovim from the official Windows ZIP..."
        Install-NeovimZip

        $nvimPath = Resolve-NeovimPath
        if (-not $nvimPath) {
            throw "Neovim installation completed, but nvim.exe could not be located afterwards."
        }
    }

    $nvimBinDir = Split-Path -Parent $nvimPath
    if ($nvimBinDir -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $nvimBinDir)) {
        $env:PATH = "$nvimBinDir$([System.IO.Path]::PathSeparator)$env:PATH"
    }

    return $nvimPath
}

Ensure-Neovim | Out-Null

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

function Install-ManagedFileLink {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $targetDir = Split-Path -Parent $TargetPath
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    if (Test-Path -LiteralPath $TargetPath) {
        $targetItem = Get-Item -LiteralPath $TargetPath -Force
        if ($targetItem.PSIsContainer) {
            throw "Cannot replace directory with managed file link: $TargetPath"
        }
        Remove-Item -LiteralPath $TargetPath -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -Force | Out-Null
    } catch {
        New-Item -ItemType HardLink -Path $TargetPath -Target $SourcePath -Force | Out-Null
    }
}

function Install-ManagedDirectoryLink {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $targetParent = Split-Path -Parent $TargetPath
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null

    if (Test-Path -LiteralPath $TargetPath) {
        $targetItem = Get-Item -LiteralPath $TargetPath -Force
        if ($targetItem.LinkType -or ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            Remove-Item -LiteralPath $TargetPath -Force
        } else {
            Write-Warning "Skipping managed directory link because a regular directory already exists: $TargetPath"
            return
        }
    }

    New-Item -ItemType Junction -Path $TargetPath -Target $SourcePath | Out-Null
}

function Install-CodexConfigLinks {
    $codexSource = Join-Path $RepoRoot "configs\codex\codex"
    $codexHome = Join-Path $HOME ".codex"

    Install-ManagedFileLink `
        -SourcePath (Join-Path $codexSource "config.toml") `
        -TargetPath (Join-Path $codexHome "config.toml")
    Install-ManagedFileLink `
        -SourcePath (Join-Path $codexSource "AGENTS.md") `
        -TargetPath (Join-Path $codexHome "AGENTS.md")
    Install-ManagedDirectoryLink `
        -SourcePath (Join-Path $codexSource "skills\weekly-update") `
        -TargetPath (Join-Path $codexHome "skills\weekly-update")
}

function Install-VSCodeConfigLinks {
    $vscodeSource = Join-Path $RepoRoot "configs\vscode\Code\User"
    $vscodeTarget = Join-Path $HOME "AppData\Roaming\Code\User"

    Install-ManagedFileLink `
        -SourcePath (Join-Path $vscodeSource "keybindings.json") `
        -TargetPath (Join-Path $vscodeTarget "keybindings.json")
    Install-ManagedFileLink `
        -SourcePath (Join-Path $vscodeSource "settings.json") `
        -TargetPath (Join-Path $vscodeTarget "settings.json")
}

Install-CodexConfigLinks
Install-VSCodeConfigLinks

function Install-PowerShellProfileBootstrap {
    param([Parameter(Mandatory = $true)][string]$TargetPath)

    $profileSource = Join-Path $RepoRoot "configs\powershell\Microsoft.PowerShell_profile.ps1"
    $escapedRepoRoot = $RepoRoot.Replace("'", "''")
    $escapedProfileSource = $profileSource.Replace("'", "''")
    $bootstrap = @(
        "`$env:DOTFILES = '$escapedRepoRoot'",
        ". '$escapedProfileSource'"
    )

    $targetDir = Split-Path -Parent $TargetPath
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    if (Test-Path -LiteralPath $TargetPath) {
        $targetItem = Get-Item -LiteralPath $TargetPath -Force
        if ($targetItem.LinkType -or ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            Remove-Item -LiteralPath $TargetPath -Force
        }
    }

    Set-Content -LiteralPath $TargetPath -Value $bootstrap -Encoding UTF8
}

$profileTargets = @(
    (Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
) | Select-Object -Unique

foreach ($profileTarget in $profileTargets) {
    Install-PowerShellProfileBootstrap -TargetPath $profileTarget
}

& (Join-Path $RepoRoot "scripts\install-wlm.ps1")

& (Join-Path $RepoRoot "scripts\install-codex.ps1")

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
        "tree-sitter",
        "zoxide",
        "atuin",
        "keychain",
        "uv"
    )
    if ($githubAuthValid) {
        $previousPythonIoEncoding = $env:PYTHONIOENCODING
        $previousPythonUtf8 = $env:PYTHONUTF8
        $env:PYTHONIOENCODING = "utf-8"
        $env:PYTHONUTF8 = "1"
        try {
            & $dotbins sync --current @tools
        } finally {
            if ($null -eq $previousPythonIoEncoding) {
                Remove-Item Env:\PYTHONIOENCODING -ErrorAction SilentlyContinue
            } else {
                $env:PYTHONIOENCODING = $previousPythonIoEncoding
            }
            if ($null -eq $previousPythonUtf8) {
                Remove-Item Env:\PYTHONUTF8 -ErrorAction SilentlyContinue
            } else {
                $env:PYTHONUTF8 = $previousPythonUtf8
            }
        }
    } else {
        Write-Warning "Skipping dotbins sync because GitHub CLI authentication is missing or invalid."
        Write-Warning "Run 'gh auth login -h github.com' and then rerun .\install.ps1 to install/update CLI tools."
    }
} else {
    Write-Warning "dotbins is not installed; skipping CLI tool sync."
}
