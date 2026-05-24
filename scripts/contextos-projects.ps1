param(
    [switch]$RefreshOnly
)

$ErrorActionPreference = "Stop"

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
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
        New-Item -ItemType Directory -Force -Path $projectsPath | Out-Null
    }

    $projects = Get-ChildItem $projectsPath -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $content = "# ContextOS Project Index`n`n"
    $content += "Generated: $timestamp`n`n"
    $content += "This summary index is generated from project memory files. It does not include raw transcripts or full session logs.`n`n"

    if (@($projects).Count -eq 0) {
        $content += "No projects tracked yet.`n"
    }

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

    return [PSCustomObject]@{
        IndexPath = $indexPath
        ProjectCount = @($projects).Count
    }
}

$vault = Get-ContextOSVaultPath
$result = Update-ProjectIndex -VaultPath $vault

if ($RefreshOnly) {
    exit 0
}

Write-Host ""
Write-Host "ContextOS Projects"
Write-Host "=================="
Write-Host ""
Write-Host ("Vault path:       {0}" -f $vault)
Write-Host ("Projects indexed: {0}" -f $result.ProjectCount)
Write-Host ("Project index:    {0}" -f $result.IndexPath)
Write-Host ""

Get-Content $result.IndexPath
