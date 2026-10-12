# Shared, opt-in install timing. Only labels and elapsed times are recorded.
function Start-DotfilesTimingReport {
    if ($env:DOTFILES_TIME_INSTALL -ne "1") { return }
    $reportDir = Join-Path $HOME ".local\state\dotfiles\install-timings"
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
    $env:DOTFILES_TIMING_REPORT = Join-Path $reportDir ("windows-{0}-{1}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $PID)
    '"step","seconds","result","exit_code"' | Set-Content -LiteralPath $env:DOTFILES_TIMING_REPORT -Encoding UTF8
    Write-Host "Install timing report: $env:DOTFILES_TIMING_REPORT"
}

function Write-DotfilesTiming {
    param([string]$Step, [System.Diagnostics.Stopwatch]$Timer, [string]$Result, $ExitCode)
    if ($env:DOTFILES_TIME_INSTALL -ne "1" -or -not $env:DOTFILES_TIMING_REPORT) { return }
    [PSCustomObject]@{
        step = $Step
        seconds = $Timer.Elapsed.TotalSeconds.ToString("F3", [Globalization.CultureInfo]::InvariantCulture)
        result = $Result
        exit_code = $ExitCode
    } | Export-Csv -LiteralPath $env:DOTFILES_TIMING_REPORT -Append -NoTypeInformation -Encoding UTF8
}

function Invoke-DotfilesTimedStep {
    param([string]$Step, [scriptblock]$Action)
    if ($env:DOTFILES_TIME_INSTALL -ne "1") { & $Action; return }
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $result = "completed"
    $global:LASTEXITCODE = 0
    try {
        & $Action
        if ($global:LASTEXITCODE -ne 0) { $result = "nonzero-exit" }
    } catch {
        $result = "failed"
        throw
    } finally {
        $stepExitCode = $global:LASTEXITCODE
        Write-DotfilesTiming $Step $timer $result $stepExitCode
        $global:LASTEXITCODE = $stepExitCode
    }
}
