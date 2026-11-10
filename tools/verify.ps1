# Verify script: headless import, test runner, smoke run.
# Works in Windows PowerShell 5.1. Exit 0 = VERIFY PASS, exit 1 = VERIFY FAIL.
# Full output goes to tools/verify.log (git-ignored).
# Godot path: $env:GODOT, else the default install path from conventions.md.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$gameDir = Join-Path $root 'game'
$logPath = Join-Path $PSScriptRoot 'verify.log'

$godot = $env:GODOT
if (-not $godot) {
    $godot = 'D:\Godot\Godot_v4.5.1-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $godot)) {
    Write-Output 'VERIFY FAIL'
    Write-Output "Godot not found: $godot"
    exit 1
}

# Only one verify run at a time: parallel agents share the Godot import cache.
# The mutex is released when this process exits.
$verifyMutex = New-Object System.Threading.Mutex($false, 'Global\idle_space_company_verify')
try { [void]$verifyMutex.WaitOne(300000) } catch [System.Threading.AbandonedMutexException] { }

$logLines = New-Object System.Collections.Generic.List[string]
$errorLines = New-Object System.Collections.Generic.List[string]
$failedSteps = New-Object System.Collections.Generic.List[string]
$testSummary = ''
$testFailCount = -1

function Invoke-GodotStep {
    param([string]$Name, [string]$ArgLine)

    $logLines.Add("=== STEP: $Name ===")
    $logLines.Add("godot $ArgLine")
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $godot -ArgumentList $ArgLine -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        $lines = @()
        $lines += @(Get-Content -LiteralPath $outFile -ErrorAction SilentlyContinue)
        $lines += @(Get-Content -LiteralPath $errFile -ErrorAction SilentlyContinue)
        $exitCode = [int]$proc.ExitCode
    }
    finally {
        Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
    }

    foreach ($line in $lines) {
        $logLines.Add([string]$line)
        if ($line -match 'SCRIPT ERROR|Parse Error|ERROR:') {
            $errorLines.Add([string]$line)
        }
        if ($Name -eq 'tests' -and $line -match 'PASS\s+(\d+)\s*/\s*FAIL\s+(\d+)') {
            $script:testSummary = [string]$line.Trim()
            $script:testFailCount = [int]$matches[2]
        }
    }
    $logLines.Add("=== EXIT: $Name = $exitCode ===")

    if ($exitCode -ne 0) {
        $failedSteps.Add("$Name (exit code $exitCode)")
    }
}

Invoke-GodotStep -Name 'import' -ArgLine "--headless --path `"$gameDir`" --import"
Invoke-GodotStep -Name 'tests' -ArgLine "--headless --path `"$gameDir`" -s res://tests/run_tests.gd"
Invoke-GodotStep -Name 'smoke' -ArgLine "--headless --path `"$gameDir`" --quit-after 180"

if ($testSummary -eq '') {
    $failedSteps.Add('tests (summary line not found)')
}
elseif ($testFailCount -gt 0) {
    $failedSteps.Add("tests ($testSummary)")
}

try {
    Out-File -FilePath $logPath -InputObject $logLines -Encoding utf8
}
catch {
    Write-Output "Could not write log: $logPath"
}

if ($failedSteps.Count -eq 0 -and $errorLines.Count -eq 0) {
    if ($testSummary -ne '') {
        Write-Output $testSummary
    }
    Write-Output 'VERIFY PASS'
    exit 0
}

foreach ($step in $failedSteps) {
    Write-Output "FAILED STEP: $step"
}
$shown = 0
foreach ($errLine in $errorLines) {
    if ($shown -ge 30) { break }
    Write-Output $errLine
    $shown++
}
Write-Output 'VERIFY FAIL'
exit 1
