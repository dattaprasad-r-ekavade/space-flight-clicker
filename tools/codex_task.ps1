# Runs one task card with Codex CLI, non-interactive.
# Usage:  powershell -ExecutionPolicy Bypass -File tools/codex_task.ps1 T040
# Report: reports/<id>.md
param(
    [Parameter(Mandatory = $true)][string]$TaskId,
    [string]$Model = ""
)

$repo = Split-Path -Parent $PSScriptRoot
$card = Join-Path $repo "tasks\$TaskId.md"
if (-not (Test-Path $card)) { Write-Error "No card: $card"; exit 2 }

$reports = Join-Path $repo "reports"
New-Item -ItemType Directory -Force $reports | Out-Null
$report = Join-Path $reports "$TaskId.md"

# Godot writes user:// data and caches under %APPDATA%\Godot, outside the workspace.
$godotData = Join-Path $env:APPDATA "Godot"
New-Item -ItemType Directory -Force $godotData | Out-Null

$prompt = "Do task $TaskId. Follow AGENTS.md. Your card is tasks/$TaskId.md."

$codexArgs = @("exec", "-s", "workspace-write", "-C", $repo, "--add-dir", $godotData, "-o", $report)
if ($Model -ne "") { $codexArgs += @("-m", $Model) }
$codexArgs += $prompt

& codex @codexArgs | Out-Null
$code = $LASTEXITCODE
if (Test-Path $report) { Get-Content $report -Tail 15 }
exit $code
