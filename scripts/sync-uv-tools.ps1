$ErrorActionPreference = "Stop"

function Get-UvPath {
    $uv = Get-Command uv.exe -ErrorAction SilentlyContinue
    if ($uv) {
        return $uv.Source
    }

    $candidate = Join-Path $HOME ".dotbins\windows\amd64\bin\uv.exe"
    if (Test-Path $candidate) {
        return $candidate
    }

    throw "uv is not installed. Run dotbins sync first."
}

$uv = Get-UvPath
$tools = @(
    "agent-cli",
    "asciinema",
    "black",
    "bump-my-version",
    "clip-files",
    "conda-lock",
    "dotbins",
    "dotbot",
    "fileup",
    "llm --with llm-gemini --with llm-anthropic --with llm-ollama",
    "markdown-code-runner",
    "mypy",
    "pre-commit --with pre-commit-uv",
    "pygount",
    "rsync-time-machine",
    "ruff",
    "smassh",
    "tuitorial",
    "unidep[all]"
)

foreach ($tool in $tools) {
    & $uv tool install $tool.Split(" ")
}

& $uv tool upgrade --all
