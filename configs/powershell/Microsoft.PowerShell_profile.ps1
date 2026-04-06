$profileItem = Get-Item -LiteralPath $PSCommandPath -Force
if ($profileItem.Target) {
    $profilePath = $profileItem.Target
} else {
    $profilePath = (Resolve-Path -LiteralPath $PSCommandPath).Path
}
$dotfilesFromProfile = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $profilePath))
if (Test-Path (Join-Path $dotfilesFromProfile "configs")) {
    $env:DOTFILES = $dotfilesFromProfile
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

if (Test-Path (Join-Path $HOME ".cargo\bin")) {
    $env:PATH += ";$HOME\.cargo\bin"
}

if (Test-Path (Join-Path $HOME ".lmstudio\bin\lms.exe")) {
    $env:PATH += ";$HOME\.lmstudio\bin"
}

$env:COLORTERM = "truecolor"
$env:EDITOR = "code --wait"
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
        Invoke-Expression (& { (atuin init powershell | Out-String) })
    }
}
if (Get-Command duf -ErrorAction SilentlyContinue) { Set-Alias du duf.exe }
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat.exe --paging=never $args }
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function l { eza.exe --long --all --git --icons=auto --color=always $args }
    function ll { eza.exe --long --all --git --icons=auto --color=always $args }
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

