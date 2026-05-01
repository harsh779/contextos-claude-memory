param(
    [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$captureScript = Join-Path $PSScriptRoot "contextos-capture.ps1"
$processScript = Join-Path $PSScriptRoot "process-session.py"
$compressScript = Join-Path $PSScriptRoot "compress-project-memory.py"

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (!$Condition) {
        throw "Assertion failed: $Message"
    }
}

function New-TestTranscript {
    param(
        [string]$Path,
        [string]$CaseName
    )

    $lines = @(
        (@{
            message = @{
                role = "user"
                content = "Decision: validate raw transcript privacy behavior for $CaseName."
            }
        } | ConvertTo-Json -Compress -Depth 10),
        (@{
            message = @{
                role = "assistant"
                content = "Next action: confirm memory files still update from transcript_path for $CaseName."
            }
        } | ConvertTo-Json -Compress -Depth 10)
    )

    $lines | Set-Content -Encoding UTF8 $Path
}

function Get-RawTranscriptCount {
    param([string]$ProjectDir)

    $rawDir = Join-Path $ProjectDir "raw"

    if (!(Test-Path $rawDir)) {
        return 0
    }

    return @(Get-ChildItem $rawDir -Recurse -File -Filter "*.jsonl").Count
}

function Invoke-CaptureCase {
    param(
        [string]$Name,
        [string]$CopyRawValue,
        [bool]$ExpectRawCopy,
        [bool]$SetCopyRawEnv
    )

    $vault = Join-Path $env:TEMP "contextos-privacy-$Name-$([guid]::NewGuid().ToString('N'))"
    $scriptsDir = Join-Path $vault "scripts"
    New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
    Copy-Item $processScript $scriptsDir -Force
    Copy-Item $compressScript $scriptsDir -Force

    $transcript = Join-Path $vault "source-transcript.jsonl"
    New-TestTranscript -Path $transcript -CaseName $Name

    $projectCwd = Join-Path $vault "fake-project-$Name"
    $eventJson = @{
        cwd = $projectCwd
        hook_event_name = "SessionEnd"
        session_id = "$Name-test"
        transcript_path = $transcript
    } | ConvertTo-Json -Compress

    $oldVault = $env:CONTEXTOS_VAULT_PATH
    $oldCopyRaw = $env:CONTEXTOS_COPY_RAW_TRANSCRIPTS
    $hadCopyRaw = Test-Path Env:\CONTEXTOS_COPY_RAW_TRANSCRIPTS

    try {
        $env:CONTEXTOS_VAULT_PATH = $vault

        if ($SetCopyRawEnv) {
            $env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = $CopyRawValue
        } else {
            Remove-Item Env:\CONTEXTOS_COPY_RAW_TRANSCRIPTS -ErrorAction SilentlyContinue
        }

        $output = $eventJson | powershell -NoProfile -ExecutionPolicy Bypass -File $captureScript
        $output | ForEach-Object { Write-Host "[$Name] $_" }

        $projectDir = Join-Path $vault "projects\fake-project-$Name"
        $requiredFiles = @(
            "PROJECT_CONTEXT.md",
            "SESSION_LOG.md",
            "DECISIONS.md",
            "NEXT_ACTIONS.md",
            "TOKEN_SAVINGS.md",
            "graph.mmd"
        )

        foreach ($file in $requiredFiles) {
            Assert-Condition (Test-Path (Join-Path $projectDir $file)) "$Name should create $file"
        }

        $rawCount = Get-RawTranscriptCount -ProjectDir $projectDir

        if ($ExpectRawCopy) {
            Assert-Condition ($rawCount -eq 1) "$Name should copy exactly one raw transcript"
        } else {
            Assert-Condition ($rawCount -eq 0) "$Name should not copy raw transcripts"
        }

        $metadata = Get-ChildItem (Join-Path $projectDir "sessions") -File -Filter "*-event.json" |
            Select-Object -First 1
        Assert-Condition ($null -ne $metadata) "$Name should write event metadata"

        $eventData = Get-Content $metadata.FullName -Raw | ConvertFrom-Json
        Assert-Condition ($eventData.copy_raw_transcripts -eq $ExpectRawCopy) "$Name metadata should record copy_raw_transcripts=$ExpectRawCopy"

        if ($ExpectRawCopy) {
            Assert-Condition (![string]::IsNullOrWhiteSpace($eventData.raw_copy_path)) "$Name metadata should include raw_copy_path"
            Assert-Condition (Test-Path $eventData.raw_copy_path) "$Name raw_copy_path should exist"
        } else {
            Assert-Condition ($null -eq $eventData.raw_copy_path) "$Name metadata should keep raw_copy_path null"
        }

        Write-Host "PASS $Name"
    } finally {
        $env:CONTEXTOS_VAULT_PATH = $oldVault

        if ($hadCopyRaw) {
            $env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = $oldCopyRaw
        } else {
            Remove-Item Env:\CONTEXTOS_COPY_RAW_TRANSCRIPTS -ErrorAction SilentlyContinue
        }

        if (!$KeepTemp -and (Test-Path $vault) -and $vault.StartsWith($env:TEMP, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $vault -Recurse -Force
        }
    }
}

Assert-Condition (Test-Path $captureScript) "contextos-capture.ps1 should exist"
Assert-Condition (Test-Path $processScript) "process-session.py should exist"
Assert-Condition (Test-Path $compressScript) "compress-project-memory.py should exist"

Invoke-CaptureCase -Name "disabled-unset" -SetCopyRawEnv:$false -CopyRawValue "" -ExpectRawCopy:$false
Invoke-CaptureCase -Name "disabled-nonexact" -SetCopyRawEnv:$true -CopyRawValue "True" -ExpectRawCopy:$false
Invoke-CaptureCase -Name "enabled-exact" -SetCopyRawEnv:$true -CopyRawValue "true" -ExpectRawCopy:$true

Write-Host "Raw transcript privacy regression checks passed."
