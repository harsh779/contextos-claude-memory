param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName
)

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

$vault = Get-ContextOSVaultPath
$projectsPath = Join-Path $vault "projects"
$projectDir = Join-Path $projectsPath $ProjectName
$packsDir = Join-Path $vault "context-packs"

New-Item -ItemType Directory -Force -Path $packsDir | Out-Null

if (!(Test-Path $projectDir)) {
    Write-Host "Project not found: $ProjectName"
    Write-Host ""
    Write-Host "Available projects:"
    Get-ChildItem $projectsPath -Directory | Select-Object -ExpandProperty Name
    exit 1
}

function Get-FileSection {
    param(
        [string]$Title,
        [string]$Path,
        [int]$MaxChars = 4000
    )

    if (!(Test-Path $Path)) {
        return "## $Title`nNot found.`n"
    }

    $text = Get-Content $Path -Raw -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($text)) {
        return "## $Title`nEmpty.`n"
    }

    if ($text.Length -gt $MaxChars) {
        $text = $text.Substring([Math]::Max(0, $text.Length - $MaxChars))
    }

    return "## $Title`n$text`n"
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputPath = Join-Path $packsDir "$ProjectName-context-pack-$timestamp.md"

$projectContext = Join-Path $projectDir "PROJECT_CONTEXT.md"
$decisions = Join-Path $projectDir "DECISIONS.md"
$nextActions = Join-Path $projectDir "NEXT_ACTIONS.md"
$sessionLog = Join-Path $projectDir "SESSION_LOG.md"
$graph = Join-Path $projectDir "graph.mmd"

$pack = @"
# ContextOS Resume Pack: $ProjectName

Generated: $timestamp

Use this as the restart context for Claude / ChatGPT / Codex.

---
"@

$pack += Get-FileSection -Title "Project Context" -Path $projectContext -MaxChars 5000
$pack += "`n---`n"
$pack += Get-FileSection -Title "Decisions" -Path $decisions -MaxChars 3000
$pack += "`n---`n"
$pack += Get-FileSection -Title "Next Actions" -Path $nextActions -MaxChars 3000
$pack += "`n---`n"
$pack += Get-FileSection -Title "Project Graph" -Path $graph -MaxChars 2500
$pack += "`n---`n"
$pack += Get-FileSection -Title "Latest Session Log" -Path $sessionLog -MaxChars 5000

$pack | Set-Content $outputPath -Encoding UTF8

try {
    $pack | Set-Clipboard
    $copied = $true
} catch {
    $copied = $false
}

Write-Host ""
Write-Host "ContextOS resume pack created:"
Write-Host $outputPath

if ($copied) {
    Write-Host ""
    Write-Host "Copied to clipboard."
}

Write-Host ""
Write-Host "Preview:"
Write-Host "--------"
Get-Content $outputPath -TotalCount 60
