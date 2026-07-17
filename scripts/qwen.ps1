$ErrorActionPreference = "Stop"

$serverMode = if ($env:QWEN_SERVER_MODE) { $env:QWEN_SERVER_MODE } else { "ssh" }
$remoteHost = if ($env:QWEN_REMOTE_HOST) { $env:QWEN_REMOTE_HOST } else { "weckerAA" }
$localBind = if ($env:QWEN_REMOTE_LOCAL_BIND) { $env:QWEN_REMOTE_LOCAL_BIND } else { "127.0.0.1" }
$localPort = if ($env:QWEN_REMOTE_LOCAL_PORT) { [int]$env:QWEN_REMOTE_LOCAL_PORT } else { 18023 }
$remoteBind = if ($env:QWEN_REMOTE_BIND_HOST) { $env:QWEN_REMOTE_BIND_HOST } else { "127.0.0.1" }
$remotePort = if ($env:QWEN_REMOTE_PORT) { [int]$env:QWEN_REMOTE_PORT } else { 8023 }
$localDirectPort = if ($env:QWEN_LOCAL_PORT) { [int]$env:QWEN_LOCAL_PORT } else { $remotePort }
$model = if ($env:QWEN_REMOTE_MODEL) { $env:QWEN_REMOTE_MODEL } else { "qwen3-coder-next" }
$apiKey = if ($env:QWEN_REMOTE_API_KEY) { $env:QWEN_REMOTE_API_KEY } else { "local-vllm" }
$waitSeconds = if ($env:QWEN_REMOTE_TUNNEL_WAIT_SECONDS) { [int]$env:QWEN_REMOTE_TUNNEL_WAIT_SECONDS } else { 30 }
$maxOutputTokens = if ($env:QWEN_CODE_MAX_OUTPUT_TOKENS) { $env:QWEN_CODE_MAX_OUTPUT_TOKENS } else { "8192" }
$safeMode = if ($env:QWEN_CODE_SAFE_MODE) { $env:QWEN_CODE_SAFE_MODE } else { "0" }
$thinkingMode = $false
$hasSystemPromptOverride = $false
$thinkingAppendSystemPrompt = if ($env:QWEN_THINKING_APPEND_SYSTEM_PROMPT) {
    $env:QWEN_THINKING_APPEND_SYSTEM_PROMPT
} else {
    "When asked to implement, fix, refactor, add, or write code, modify the working tree with Qwen Code edit/write_file tools before answering. Do not put code blocks, patches, or replacement file contents in the final answer unless the user explicitly asks for snippets. If you cannot edit files, say so explicitly instead of showing code."
}

function Test-SamePath {
    param(
        [string]$Left,
        [string]$Right
    )

    if (-not $Left -or -not $Right) {
        return $false
    }

    try {
        return (Resolve-Path -LiteralPath $Left).Path -eq (Resolve-Path -LiteralPath $Right).Path
    } catch {
        return $false
    }
}

function Resolve-QwenBinary {
    if ($env:QWEN_CODE_BIN -and (Test-Path $env:QWEN_CODE_BIN)) {
        return (Resolve-Path -LiteralPath $env:QWEN_CODE_BIN).Path
    }

    $localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME "AppData\Local" }
    $candidates = @(
        (Join-Path $localAppData "qwen-code\bin\qwen.cmd"),
        (Join-Path $localAppData "qwen-code\bin\qwen.exe"),
        (Join-Path $HOME ".local\lib\qwen-code\bin\qwen.cmd"),
        (Join-Path $HOME ".local\lib\qwen-code\bin\qwen.exe"),
        (Join-Path $HOME ".local\lib\qwen-code\bin\qwen")
    )

    foreach ($candidate in $candidates) {
        if ((Test-Path $candidate) -and -not (Test-SamePath $candidate $PSCommandPath)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $commands = Get-Command qwen -CommandType Application -ErrorAction SilentlyContinue
    foreach ($command in $commands) {
        if ($command.Source -and -not (Test-SamePath $command.Source $PSCommandPath)) {
            return $command.Source
        }
    }

    return $null
}

function Test-ShouldAddSafeMode {
    param([string[]]$Arguments)

    if ($safeMode -match "^(0|false|FALSE|no|NO)$") {
        return $false
    }

    $first = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "" }
    if ($first -in @(
            "auth",
            "channel",
            "extensions",
            "hooks",
            "mcp",
            "review",
            "serve",
            "sessions",
            "-v",
            "--version",
            "-h",
            "--help"
        )) {
        return $false
    }

    return -not ($Arguments -contains "--safe-mode")
}

$qwenArgs = New-Object System.Collections.Generic.List[string]
foreach ($arg in $args) {
    if ($arg -eq "--system-prompt" -or
        $arg -eq "--append-system-prompt" -or
        $arg -like "--system-prompt=*" -or
        $arg -like "--append-system-prompt=*") {
        $hasSystemPromptOverride = $true
        [void]$qwenArgs.Add($arg)
        continue
    }

    switch ($arg) {
        "--coding" {
            $model = if ($env:QWEN_CODER_MODEL) { $env:QWEN_CODER_MODEL } else { "qwen3-coder-next" }
        }
        "--thinking" {
            $thinkingMode = $true
            $model = if ($env:QWEN_THINKING_MODEL) {
                $env:QWEN_THINKING_MODEL
            } elseif ($env:QWEN_DEBUG_MODEL) {
                $env:QWEN_DEBUG_MODEL
            } else {
                "qwq-32b"
            }
        }
        "--local" {
            $serverMode = "local"
        }
        "--remote" {
            $serverMode = "ssh"
            $remoteHost = if ($env:QWEN_REMOTE_HOST_REMOTE) { $env:QWEN_REMOTE_HOST_REMOTE } else { "weckerAA-remote" }
        }
        default {
            [void]$qwenArgs.Add($arg)
        }
    }
}

$realQwen = Resolve-QwenBinary
if (-not $realQwen) {
    throw "Qwen Code is not installed. Run scripts\install-qwen-code.ps1 or rerun install.ps1."
}

$firstArg = if ($qwenArgs.Count -gt 0) { $qwenArgs[0] } else { "" }
if ($firstArg -in @("auth", "channel", "extensions", "hooks", "mcp", "review", "serve", "sessions", "-v", "--version", "-h", "--help")) {
    & $realQwen @qwenArgs
    exit $LASTEXITCODE
}

switch ($serverMode) {
    "local" {
        $baseUrl = "http://127.0.0.1:${localDirectPort}/v1"
    }
    "ssh" {
        $baseUrl = "http://${localBind}:${localPort}/v1"
    }
    default {
        throw "Unknown Qwen server mode: $serverMode"
    }
}

function Test-QwenEndpoint {
    try {
        Invoke-RestMethod -Uri "$baseUrl/models" -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

if ($serverMode -eq "ssh") {
    $ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if (-not $ssh) {
        $ssh = Get-Command ssh -ErrorAction SilentlyContinue
    }
    if (-not $ssh) {
        throw "ssh is required to open the Qwen Code tunnel to $remoteHost."
    }
}

if ($serverMode -eq "ssh" -and -not (Test-QwenEndpoint)) {
    Write-Host "Opening SSH tunnel to $remoteHost for Qwen Code..."
    $sshArgs = @(
        "-N",
        "-o", "ExitOnForwardFailure=yes",
        "-L", "${localBind}:${localPort}:${remoteBind}:${remotePort}",
        $remoteHost
    )
    Start-Process -FilePath $ssh.Source -ArgumentList $sshArgs | Out-Null

    for ($i = 0; $i -lt $waitSeconds; $i++) {
        if (Test-QwenEndpoint) {
            break
        }
        Start-Sleep -Seconds 1
    }
}

if (-not (Test-QwenEndpoint)) {
    if ($serverMode -eq "ssh") {
        throw "Qwen Code model endpoint did not become ready at $baseUrl. Check SSH access to $remoteHost and the remote service on ${remoteBind}:${remotePort}."
    }

    throw "Qwen Code model endpoint did not become ready at $baseUrl. Check the local service on 127.0.0.1:${localDirectPort}."
}

$env:OPENAI_API_KEY = $apiKey
$env:OPENAI_BASE_URL = $baseUrl
$env:OPENAI_MODEL = $model
$env:QWEN_MODEL = $model
$env:QWEN_CODE_MAX_OUTPUT_TOKENS = $maxOutputTokens

$finalArgs = [string[]]$qwenArgs.ToArray()
if ($thinkingMode -and -not $hasSystemPromptOverride) {
    $finalArgs = @("--append-system-prompt", $thinkingAppendSystemPrompt) + $finalArgs
}
if (Test-ShouldAddSafeMode -Arguments $finalArgs) {
    $finalArgs = @("--safe-mode") + $finalArgs
}

& $realQwen --model $model @finalArgs
exit $LASTEXITCODE
