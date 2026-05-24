$ErrorActionPreference = "Stop"

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

function Test-CrossProjectMemoryEnabled {
    return ($env:CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY -cne "false")
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxChars
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    if ($Text.Length -le $MaxChars) {
        return $Text
    }

    return $Text.Substring(0, $MaxChars)
}

function Get-UsefulLines {
    param(
        [string]$Path,
        [int]$MaxLines = 4
    )

    if (!(Test-Path $Path)) {
        return @()
    }

    $lines = Get-Content $Path -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            ![string]::IsNullOrWhiteSpace($_) -and
            !$_.StartsWith("#") -and
            $_ -notlike "Working Directory*" -and
            $_ -notlike "*AI-Memory-Vault*" -and
            $_ -notlike "Auto-created by ContextOS*" -and
            $_ -notlike "New project memory created automatically*" -and
            $_ -notlike "Use SESSION_LOG.md*" -and
            $_ -notlike "- No locked decisions captured yet*" -and
            $_ -notlike "1. Inspect current repo/project state*" -and
            $_ -notlike "2. Identify active goal*" -and
            $_ -notlike "3. Continue from latest Claude Code session context*" -and
            $_ -notmatch "^[A-Za-z]:\\"
        } |
        Select-Object -Last $MaxLines

    return @($lines)
}

function Update-ProjectIndex {
    param(
        [string]$VaultPath
    )

    $projectsPath = Join-Path $VaultPath "projects"
    $indexPath = Join-Path $VaultPath "PROJECT_INDEX.md"

    if (!(Test-Path $projectsPath)) {
        return $indexPath
    }

    $projects = Get-ChildItem $projectsPath -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $content = "# ContextOS Project Index`n`n"
    $content += "Generated: $timestamp`n`n"
    $content += "This summary index is generated from project memory files. It does not include raw transcripts or full session logs.`n`n"

    foreach ($project in $projects) {
        $projectContext = Join-Path $project.FullName "PROJECT_CONTEXT.md"
        $decisions = Join-Path $project.FullName "DECISIONS.md"
        $nextActions = Join-Path $project.FullName "NEXT_ACTIONS.md"

        $latest = Get-ChildItem $project.FullName -File -Include "*.md","*.mmd" -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notlike "*\raw\*" -and
                $_.FullName -notlike "*\sessions\*" -and
                $_.FullName -notlike "*\archives\*"
            } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        $lastUpdated = if ($latest) { $latest.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $project.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") }

        $content += "## $($project.Name)`n`n"
        $content += "- Last updated: $lastUpdated`n"
        $content += "- Memory path: $($project.FullName)`n"

        $summaryLines = @()
        $summaryLines += Get-UsefulLines -Path $projectContext -MaxLines 3
        $summaryLines += Get-UsefulLines -Path $decisions -MaxLines 3
        $summaryLines += Get-UsefulLines -Path $nextActions -MaxLines 3

        if ($summaryLines.Count -gt 0) {
            $content += "- Summary signals:`n"
            foreach ($line in ($summaryLines | Select-Object -First 6)) {
                $content += "  - $line`n"
            }
        } else {
            $content += "- Summary signals: None captured yet.`n"
        }

        $content += "`n"
    }

    $content | Set-Content $indexPath -Encoding UTF8
    return $indexPath
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
$projectIndex = Join-Path $vault "PROJECT_INDEX.md"

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

$projectIndex = Update-ProjectIndex -VaultPath $vault

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

if ((Test-CrossProjectMemoryEnabled) -and (Test-Path $projectIndex)) {
    if ($context.Length -gt 6000) {
        $context = $context.Substring(0, 6000)
        $context += "`n`n[Current project context truncated before cross-project index.]`n"
    }

    $indexText = Get-Content $projectIndex -Raw -ErrorAction SilentlyContinue
    $indexText = Limit-Text -Text $indexText -MaxChars 3000

    if (![string]::IsNullOrWhiteSpace($indexText)) {
        $context += "`n## Cross-Project Awareness`n"
        $context += "Cross-project memory is enabled by default. Use this vault-level index to identify possibly related prior work. Do not assume unrelated project details apply to the current project without user confirmation. To disable this startup section, set CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false.`n`n"
        $context += $indexText
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
