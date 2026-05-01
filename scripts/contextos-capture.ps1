$ErrorActionPreference = "Stop"

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

$vault = Get-ContextOSVaultPath
$debugDir = Join-Path $vault "debug"
New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

$pipelineInput = ($input | ForEach-Object { $_ }) -join "`n"

if ([string]::IsNullOrWhiteSpace($pipelineInput)) {
    $inputJson = [Console]::In.ReadToEnd()
} else {
    $inputJson = $pipelineInput
}

$inputJson = $inputJson.Trim()

$rawDebugPath = Join-Path $debugDir "last-capture-raw-input.json"
$inputJson | Out-File -Encoding UTF8 $rawDebugPath

if ([string]::IsNullOrWhiteSpace($inputJson)) {
    "ContextOS capture skipped: no JSON input received."
    exit 0
}

try {
    $hookData = $inputJson | ConvertFrom-Json
} catch {
    "ContextOS capture failed: invalid JSON input."
    "Raw input saved here: $rawDebugPath"
    exit 1
}

$parsedDebugPath = Join-Path $debugDir "last-capture-parsed.json"
$hookData | ConvertTo-Json -Depth 50 | Out-File -Encoding UTF8 $parsedDebugPath

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$cwd = $hookData.cwd
$hookEventName = $hookData.hook_event_name
$sessionId = $hookData.session_id
$transcriptPath = $hookData.transcript_path

if ([string]::IsNullOrWhiteSpace($cwd)) {
    $projectName = "unknown-project"
} else {
    $projectName = Split-Path $cwd -Leaf
}

$projectDir = Join-Path $vault "projects\$projectName"
$rawDir = Join-Path $projectDir "raw"
$sessionsDir = Join-Path $projectDir "sessions"

New-Item -ItemType Directory -Force -Path $projectDir | Out-Null
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
New-Item -ItemType Directory -Force -Path $sessionsDir | Out-Null

$metadataPath = Join-Path $sessionsDir "$timestamp-event.json"

$metadata = [ordered]@{
    session_id = $sessionId
    hook_event_name = $hookEventName
    cwd = $cwd
    transcript_path = $transcriptPath
    captured_at = $timestamp
    raw_debug_path = $rawDebugPath
}

$metadata | ConvertTo-Json -Depth 50 | Out-File -Encoding UTF8 $metadataPath

if ($transcriptPath -and (Test-Path $transcriptPath)) {
    $rawCopyPath = Join-Path $rawDir "$timestamp-transcript.jsonl"
    Copy-Item $transcriptPath $rawCopyPath -Force
}

$processor = Join-Path $vault "scripts\process-session.py"
python $processor --event "$metadataPath"

exit 0
