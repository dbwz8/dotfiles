if ((Get-Variable -Name DotfilesPowerShellProfileLoaded -Scope Global -ErrorAction SilentlyContinue) -and $global:DotfilesPowerShellProfileLoaded) {
    return
}
$global:DotfilesPowerShellProfileLoaded = $true

$profileItem = if ($PSCommandPath) { Get-Item -LiteralPath $PSCommandPath -Force } else { $null }
if (-not $env:HOME) {
    $env:HOME = $HOME
}
if (-not $env:SHELL) {
    $env:SHELL = "pwsh.exe"
}

if (-not $env:DOTFILES) {
    $dotfilesCandidates = @()
    if ($profileItem) {
        $profileSourcePath = if ($profileItem.Target) { $profileItem.Target } else { $profileItem.FullName }
        $dotfilesCandidates += Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $profileSourcePath))
    }
    $dotfilesCandidates += @(
        (Join-Path $HOME "git\dotfiles"),
        (Join-Path $HOME "dotfiles")
    )

    foreach ($candidate in $dotfilesCandidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate "configs")) -and (Test-Path (Join-Path $candidate "scripts\start-zellij.ps1"))) {
            $env:DOTFILES = $candidate
            break
        }
    }
}

if ($env:DOTFILES) {
    $zellijConfigDir = Join-Path $env:DOTFILES "configs\zellij"
    if (Test-Path $zellijConfigDir) {
        $env:ZELLIJ_CONFIG_DIR = $zellijConfigDir
    }
}

$repoBin = $null
if ($env:DOTFILES) {
    $repoBin = Join-Path $env:DOTFILES "bin"
    if ((Test-Path $repoBin) -and -not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $repoBin)) {
        $env:PATH = "$repoBin$([System.IO.Path]::PathSeparator)$env:PATH"
    }
}

$arch = "386"
try {
    $processor = Get-CimInstance -Class Win32_Processor -ErrorAction Stop | Select-Object -First 1
    if ($processor -and $processor.AddressWidth -eq 64) {
        $arch = "amd64"
    }
} catch {
    if ([Environment]::Is64BitOperatingSystem) {
        $arch = "amd64"
    }
}

$dotbinsBin = Join-Path $HOME ".dotbins\windows\$arch\bin"
if (Test-Path $dotbinsBin) {
    $env:PATH = "$dotbinsBin$([System.IO.Path]::PathSeparator)$env:PATH"
}
$dotbinsNeovimBin = Join-Path $HOME ".dotbins\windows\$arch\neovim\bin"
if (Test-Path $dotbinsNeovimBin) {
    $env:PATH = "$dotbinsNeovimBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

$localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME "AppData\Local" }
$codexBin = if ($env:CODEX_INSTALL_DIR) { $env:CODEX_INSTALL_DIR } else { Join-Path $localAppData "Programs\OpenAI\Codex\bin" }
if (Test-Path $codexBin) {
    $env:PATH = "$codexBin$([System.IO.Path]::PathSeparator)$env:PATH"
}
$localBin = Join-Path $HOME ".local\bin"
if (Test-Path $localBin) {
    $env:PATH = "$localBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

$managedGoRoot = if ($env:DOTFILES_GO_INSTALL_ROOT) { $env:DOTFILES_GO_INSTALL_ROOT } else { Join-Path $HOME ".local\go" }
$goRoot = if (Test-Path (Join-Path $managedGoRoot "bin")) { $managedGoRoot } elseif ($env:GOROOT) { $env:GOROOT } else { $managedGoRoot }
$env:GOROOT = $goRoot
$goBin = Join-Path $goRoot "bin"
$goPath = if ($env:GOPATH) { $env:GOPATH } else { Join-Path $HOME "go" }
if (-not $env:GOPATH) {
    $env:GOPATH = $goPath
}
$goBinInstall = if ($env:GOBIN) { $env:GOBIN } else { Join-Path $goPath "bin" }
if (-not $env:GOBIN) {
    $env:GOBIN = $goBinInstall
}
if (-not $env:GOMODCACHE) {
    $env:GOMODCACHE = Join-Path $goPath "pkg\mod"
}
if (-not $env:GOCACHE) {
    $env:GOCACHE = Join-Path $HOME ".cache\go-build"
}
if (-not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $goBinInstall)) {
    $env:PATH = "$goBinInstall$([System.IO.Path]::PathSeparator)$env:PATH"
}
if (-not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $goBin)) {
    $env:PATH = "$goBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

$cargoBin = Join-Path $HOME ".cargo\bin"
if (-not (($env:PATH -split [System.IO.Path]::PathSeparator) -contains $cargoBin)) {
    $env:PATH = "$cargoBin$([System.IO.Path]::PathSeparator)$env:PATH"
}

if (Test-Path (Join-Path $HOME ".lmstudio\bin\lms.exe")) {
    $env:PATH += ";$HOME\.lmstudio\bin"
}

$dotfilesLocale = if ($env:DOTFILES_LOCALE) { $env:DOTFILES_LOCALE } else { "en_US.UTF-8" }
$env:DOTFILES_LOCALE = $dotfilesLocale
$env:LANG = $dotfilesLocale
$env:LC_ALL = $dotfilesLocale
$env:LC_CTYPE = $dotfilesLocale

$gitFind = Get-Command find.exe -All -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -like "*\Git\usr\bin\find.exe" } |
    Select-Object -First 1
if ($gitFind) {
    $global:DotfilesFindExe = $gitFind.Source
    function global:find { & $global:DotfilesFindExe @args }
    function global:find.exe { & $global:DotfilesFindExe @args }
}

$env:COLORTERM = "truecolor"
$env:EDITOR = "nvim"
$env:VISUAL = "nvim"
$env:GIT_EDITOR = "nvim"
$env:DIRENV_LOG_FORMAT = ""
if (-not $env:GH_TOKEN -and $env:GITHUB_TOKEN) {
    $env:GH_TOKEN = $env:GITHUB_TOKEN
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
if ($PSVersionTable.PSVersion.Major -ge 7) {
    if (Get-Command direnv -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { (direnv hook pwsh | Out-String) })
    }
    if (Get-Command atuin -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { (atuin init powershell --disable-up-arrow | Out-String) })
    }
}
if (Get-Command duf -ErrorAction SilentlyContinue) { Set-Alias du duf.exe }
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat.exe --paging=never $args }
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function l { eza.exe --long --all --git --icons=auto --color=always $args }
    function ll { eza.exe --long --all --git --icons=auto --color=always $args }
    function lt { eza.exe -l --sort=modified -r $args | head }
}
if (Get-Command lazygit -ErrorAction SilentlyContinue) { Set-Alias lg lazygit.exe }
if (Get-Command micromamba -ErrorAction SilentlyContinue) {
    $env:MAMBA_EXE = (Get-Command micromamba).Source
    if (-not $env:MAMBA_ROOT_PREFIX) {
        $env:MAMBA_ROOT_PREFIX = Join-Path $HOME "micromamba"
    }
    $mambaModule = Join-Path $env:MAMBA_ROOT_PREFIX "condabin\Mamba.psm1"
    if (Test-Path $mambaModule) {
        Set-Alias mm micromamba.exe
        Invoke-Expression (& { (micromamba shell hook -s powershell | Out-String) })
    }
}

if (Get-Command code -ErrorAction SilentlyContinue) { Set-Alias c code }
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name v -Value nvim.exe -Force
    Set-Alias -Name vi -Value nvim.exe -Force
    Set-Alias -Name vim -Value nvim.exe -Force
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs { git status @args }
    function glo { git log --oneline --decorate -20 @args }
}
if ($env:DOTFILES) {
    $zellijStart = Join-Path $env:DOTFILES "scripts\start-zellij.ps1"
    if (Test-Path $zellijStart) {
        function zellij { & $zellijStart @args }
        function zj { & $zellijStart @args }
    }
}
if (Get-Command python -ErrorAction SilentlyContinue) { Set-Alias py python }
if (Get-Command claude -ErrorAction SilentlyContinue) { Set-Alias cl claude }
if ($env:DOTFILES) {
    $codexScript = Join-Path $env:DOTFILES "scripts\install-codex.ps1"
    if (Test-Path $codexScript) {
        function codex {
            if ($args.Count -eq 1 -and $args[0] -eq "update") {
                $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
                if (-not $pwsh) {
                    throw "pwsh.exe is required for Codex updates. Run install.ps1 to install PowerShell 7."
                }
                & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $codexScript -Update
                return
            }

            $codexCommand = $null
            foreach ($name in @("codex.exe", "codex.cmd", "codex.ps1")) {
                $candidate = Join-Path $codexBin $name
                if (Test-Path $candidate) {
                    $codexCommand = $candidate
                    break
                }
            }
            if (-not $codexCommand) {
                throw "Codex CLI is not installed in $codexBin."
            }
            & $codexCommand @args
        }
    }
    $aiderScript = Join-Path $env:DOTFILES "scripts\aider.ps1"
    if (Test-Path $aiderScript) {
        function aider { & $aiderScript @args }
    }
}
