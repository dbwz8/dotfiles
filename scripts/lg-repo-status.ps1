$ErrorActionPreference = "Stop"

function Find-StateFile {
    $candidates = New-Object System.Collections.Generic.List[string]

    if ($env:LAZYGIT_STATE_FILE) {
        [void]$candidates.Add($env:LAZYGIT_STATE_FILE)
    }

    if ($env:LOCALAPPDATA) {
        [void]$candidates.Add((Join-Path $env:LOCALAPPDATA "lazygit\state.yml"))
    }

    $lazygit = Get-Command lazygit.exe -ErrorAction SilentlyContinue
    if ($lazygit) {
        $configDir = & $lazygit.Source --print-config-dir 2>$null
        if ($LASTEXITCODE -eq 0 -and $configDir) {
            [void]$candidates.Add((Join-Path $configDir.Trim() "state.yml"))
        }
    }

    [void]$candidates.Add((Join-Path $HOME "AppData\Local\lazygit\state.yml"))
    [void]$candidates.Add((Join-Path $HOME ".config\lazygit\state.yml"))

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function ConvertFrom-LazygitYamlScalar {
    param([Parameter(Mandatory = $true)][string]$Value)

    $value = $Value.Trim()
    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        return ConvertFrom-Json -InputObject $value
    }
    if ($value.StartsWith("'") -and $value.EndsWith("'")) {
        return $value.Substring(1, $value.Length - 2).Replace("''", "'")
    }

    return $value
}

function Get-RecentRepositories {
    param([Parameter(Mandatory = $true)][string]$StateFile)

    $inRecentRepos = $false
    foreach ($line in Get-Content -LiteralPath $StateFile) {
        if ($line -match '^\s*recentrepos:\s*$') {
            $inRecentRepos = $true
            continue
        }
        if ($inRecentRepos -and $line -match '^\S') {
            break
        }
        if ($inRecentRepos -and $line -match '^\s*-\s*(?<path>.*)$') {
            ConvertFrom-LazygitYamlScalar -Value $Matches.path
        }
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) {
        return $null
    }

    $output = & $git.Source -c core.untrackedCache=false -C $Repository @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return @($output)
}

function Write-RepositoryStatus {
    param([Parameter(Mandatory = $true)][string]$Repository)

    $name = Split-Path -Leaf $Repository
    if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
        "{0,-24} {1,-18} {2,-24} {3}" -f $name, '-', 'missing', $Repository
        return
    }
    if (-not (Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--show-toplevel'))) {
        "{0,-24} {1,-18} {2,-24} {3}" -f $name, '-', 'not a Git repository', $Repository
        return
    }

    $branch = (Invoke-Git -Repository $Repository -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD') | Select-Object -First 1)
    if (-not $branch) {
        $commit = (Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--short', 'HEAD') | Select-Object -First 1)
        if (-not $commit) {
            $commit = '?'
        }
        $branch = "detached@$commit"
    }

    $statusLines = @(Invoke-Git -Repository $Repository -Arguments @('status', '--porcelain=v1', '--untracked-files=normal'))
    $modifiedCount = @($statusLines | Where-Object { $_ -and -not $_.StartsWith('??') }).Count
    $untrackedCount = @($statusLines | Where-Object { $_ -and $_.StartsWith('??') }).Count
    $worktree = if ($modifiedCount -eq 0 -and $untrackedCount -eq 0) {
        'clean M:0 U:0'
    } else {
        "dirty M:$modifiedCount U:$untrackedCount"
    }

    $upstream = (Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}') | Select-Object -First 1)
    if (-not $upstream) {
        $syncStatus = 'no upstream'
    } else {
        $counts = (Invoke-Git -Repository $Repository -Arguments @('rev-list', '--left-right', '--count', "$upstream...HEAD") | Select-Object -First 1) -split '\s+'
        if ($counts.Count -eq 2) {
            $syncStatus = "$upstream ahead:$($counts[1]) behind:$($counts[0])"
        } else {
            $syncStatus = "$upstream unavailable"
        }
    }

    "{0,-24} {1,-18} {2,-24} {3}  {4}" -f $name, $branch, $worktree, $syncStatus, $Repository
}

$stateFile = Find-StateFile
if (-not $stateFile) {
    Write-Error "Could not find Lazygit state.yml; open a repository in Lazygit first."
    exit 1
}

"Lazygit recent repositories: $stateFile"
"{0,-24} {1,-18} {2,-24} {3}" -f 'REPOSITORY', 'BRANCH', 'WORKTREE', 'UPSTREAM / PATH'
'---------------------------------------------------------------------------------------------------------------'

Get-RecentRepositories -StateFile $stateFile | ForEach-Object {
    if ($_) {
        Write-RepositoryStatus -Repository $_
    }
}
