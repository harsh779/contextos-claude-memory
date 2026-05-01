$ErrorActionPreference = "Stop"

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

$inputJson = ($input | ForEach-Object { $_ }) -join "`n"

if ([string]::IsNullOrWhiteSpace($inputJson)) {
    $inputJson = [Console]::In.ReadToEnd()
}

if ([string]::IsNullOrWhiteSpace($inputJson)) {
    exit 0
}

$hookData = $inputJson | ConvertFrom-Json

$vault = Get-ContextOSVaultPath
$cwd = $hookData.cwd

if ([string]::IsNullOrWhiteSpace($cwd)) {
    exit 0
}

$projectName = Split-Path $cwd -Leaf
$projectDir = Join-Path $vault "projects\$projectName"
$rawDir = Join-Path $projectDir "raw"
$sessionsDir = Join-Path $projectDir "sessions"

New-Item -ItemType Directory -Force -Path $projectDir | Out-Null
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
New-Item -ItemType Directory -Force -Path $sessionsDir | Out-Null

$projectContext = Join-Path $projectDir "PROJECT_CONTEXT.md"
$decisions = Join-Path $projectDir "DECISIONS.md"
$nextActions = Join-Path $projectDir "NEXT_ACTIONS.md"
$sessionLog = Join-Path $projectDir "SESSION_LOG.md"
$graph = Join-Path $projectDir "graph.mmd"

if (!(Test-Path $projectContext)) {
@"
# Project Context: $projectName

## Purpose
Auto-created by ContextOS from Claude Code working directory.

## Current Status
New project memory created automatically.

## Working Directory
$cwd

## Active Context Pack
Use SESSION_LOG.md, DECISIONS.md, NEXT_ACTIONS.md, and graph.mmd for continuity.
"@ | Set-Content $projectContext -Encoding UTF8
}

if (!(Test-Path $decisions)) {
@"
# Decisions: $projectName

- No locked decisions captured yet.
"@ | Set-Content $decisions -Encoding UTF8
}

if (!(Test-Path $nextActions)) {
@"
# Next Actions: $projectName

1. Inspect current repo/project state.
2. Identify active goal.
3. Continue from latest Claude Code session context.
"@ | Set-Content $nextActions -Encoding UTF8
}

if (!(Test-Path $sessionLog)) {
@"
# Session Log: $projectName

"@ | Set-Content $sessionLog -Encoding UTF8
}

if (!(Test-Path $graph)) {
@"
graph TD
    A[$projectName] --> B[Sessions]
    A --> C[Decisions]
    A --> D[Next Actions]
    A --> E[Project Context]
"@ | Set-Content $graph -Encoding UTF8
}

$files = @(
    "PROJECT_CONTEXT.md",
    "DECISIONS.md",
    "NEXT_ACTIONS.md",
    "graph.mmd"
)

$context = "# ContextOS Retrieved Memory for $projectName`n`n"
$context += "ContextOS active: loaded memory for $projectName from $projectDir`n`n"
$context += "Working directory: $cwd`n`n"
$context += "ContextOS memory vault path for this project: $projectDir`n"
$context += "Do not assume memory files live inside the working repo. They live in the ContextOS memory vault unless explicitly configured otherwise.`n`n"
$context += "CRITICAL: Never create or edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd inside the working directory. ContextOS memory files live only at: $projectDir. During active sessions, read ContextOS memory only. SessionEnd hook performs all memory updates after exit.`n`n"
$context += "IMPORTANT CONTEXTOS RULE: During active Claude Code sessions, do not use Write, Edit, MultiEdit, or file-modification tools on ContextOS memory files. Do not directly edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd. These files are updated automatically by the SessionEnd hook after the session exits. You may read them for context only unless the user explicitly asks you to edit them manually.`n`n"

foreach ($file in $files) {
    $path = Join-Path $projectDir $file
    if (Test-Path $path) {
        $text = Get-Content $path -Raw
        if ($text.Length -gt 2500) {
            $text = $text.Substring([Math]::Max(0, $text.Length - 2500))
        }
        $context += "`n## $file`n$text`n"
    }
}

if ($context.Length -gt 9000) {
    $context = $context.Substring(0, 9000)
}

$response = @{
    hookSpecificOutput = @{
        hookEventName = "SessionStart"
        additionalContext = $context
    }
}

$response | ConvertTo-Json -Depth 10
exit 0
