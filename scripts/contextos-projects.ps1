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

function Normalize-IndexLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return ""
    }

    $clean = $Line.Trim()
    $clean = $clean -replace "^\s*[-*]\s+", ""
    $clean = $clean -replace "^\s*\d+\.\s+", ""
    $clean = $clean -replace "^(?i)(decision|decided|next action|todo|to-do):\s*", ""
    return $clean.Trim()
}

function Test-IndexNoiseLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return $true }

    $clean = Normalize-IndexLine $Line
    $lower = $clean.ToLower()

    if ([string]::IsNullOrWhiteSpace($clean)) { return $true }
    if ($clean -eq "---") { return $true }
    if ($clean.Length -gt 220) { return $true }
    if ($clean.StartsWith("#")) { return $true }
    if ($clean.StartsWith('```')) { return $true }
    if ($clean.Contains('```')) { return $true }
    if ($clean -match "^[A-Za-z]:\\") { return $true }

    $noisePatterns = @(
        "auto-created by contextos",
        "new project memory created automatically",
        "use session_log.md",
        "no locked decisions captured yet",
        "inspect current repo/project state",
        "identify active goal",
        "continue from latest claude code session context",
        "no useful summary captured",
        "none auto-detected",
        "do not respond to these messages",
        "local-command-caveat",
        "you're out of extra usage",
        "let me ",
        "can you ",
        "can ",
        "but you ",
        "you ",
        "yes,",
        "clicking ",
        "making the fix",
        "aim unclear",
        "want to ",
        "i'll ",
        "i will ",
        "i can ",
        "now ",
        "now update ",
        "now run ",
        "wait for ",
        "checking required files",
        "check the vault files",
        "let me check",
        "expected ",
        "click ",
        "run npm",
        "run git",
        "build taking time"
    )

    foreach ($pattern in $noisePatterns) {
        if ($lower.Contains($pattern)) {
            return $true
        }
    }

    return $false
}

function Get-CleanProjectContextLines {
    param(
        [string]$Path,
        [int]$MaxLines = 2
    )

    if (!(Test-Path $Path)) {
        return @()
    }

    $stableLines = @()

    foreach ($line in (Get-Content $Path -ErrorAction SilentlyContinue)) {
        if ($line -like "## Latest Auto-Captured Status*") {
            break
        }

        if (Test-IndexNoiseLine $line) {
            continue
        }

        $clean = Normalize-IndexLine $line

        if ($stableLines -notcontains $clean) {
            $stableLines += $clean
        }
    }

    return @($stableLines | Select-Object -First $MaxLines)
}

function Get-CleanIndexLines {
    param(
        [string]$Path,
        [int]$MaxLines = 4,
        [string]$Prefix = ""
    )

    if (!(Test-Path $Path)) {
        return @()
    }

    $lines = @()

    foreach ($line in (Get-Content $Path -ErrorAction SilentlyContinue)) {
        if (Test-IndexNoiseLine $line) {
            continue
        }

        $clean = Normalize-IndexLine $line

        if (![string]::IsNullOrWhiteSpace($Prefix)) {
            $clean = "$Prefix$clean"
        }

        if ($lines -notcontains $clean) {
            $lines += $clean
        }
    }

    return @($lines | Select-Object -First $MaxLines)
}

function Test-TechnicalSignalLine {
    param([string]$Line)

    if (Test-IndexNoiseLine $Line) {
        return $false
    }

    $clean = Normalize-IndexLine $Line
    $lower = $clean.ToLower()

    $technicalPatterns = @(
        ".prisma",
        "prisma",
        "hostinger",
        "deploy",
        "build",
        "neon",
        "database",
        "db ",
        "api ",
        "route",
        "schema",
        "error",
        "failed",
        "blocker",
        "logs",
        "npm",
        "package-lock",
        "razorpay",
        "signalr",
        "northflank",
        "github",
        "remote"
    )

    foreach ($pattern in $technicalPatterns) {
        if ($lower.Contains($pattern)) {
            return $true
        }
    }

    return $false
}

function Get-TechnicalSignalScore {
    param([string]$Line)

    $lower = (Normalize-IndexLine $Line).ToLower()
    $score = 0

    foreach ($pattern in @(".prisma", "prisma", "schema", "hostinger", "neon", "database", "razorpay", "signalr", "northflank")) {
        if ($lower.Contains($pattern)) {
            $score += 3
        }
    }

    foreach ($pattern in @("deploy", "build", "failed", "error", "logs", "npm", "package-lock", "github", "remote", "api ", "route")) {
        if ($lower.Contains($pattern)) {
            $score += 1
        }
    }

    return $score
}

function Get-LatestTechnicalSignals {
    param(
        [string]$Path,
        [int]$MaxLines = 2
    )

    if (!(Test-Path $Path)) {
        return @()
    }

    $signals = @()

    foreach ($line in (Get-Content $Path -ErrorAction SilentlyContinue)) {
        if (!(Test-TechnicalSignalLine $line)) {
            continue
        }

        $clean = Normalize-IndexLine $line

        if (@($signals | Where-Object { $_.Line -eq $clean }).Count -eq 0) {
            $signals += [PSCustomObject]@{
                Line = $clean
                Score = Get-TechnicalSignalScore $clean
            }
        }
    }

    return @($signals |
        Sort-Object @{Expression="Score";Descending=$true} |
        Select-Object -First $MaxLines |
        ForEach-Object { $_.Line })
}

function Get-ProjectIndexSignals {
    param([string]$ProjectDir)

    $projectContext = Join-Path $ProjectDir "PROJECT_CONTEXT.md"
    $decisions = Join-Path $ProjectDir "DECISIONS.md"
    $nextActions = Join-Path $ProjectDir "NEXT_ACTIONS.md"

    $signals = @()
    $statusLines = Get-CleanProjectContextLines -Path $projectContext -MaxLines 2
    $technicalLines = Get-LatestTechnicalSignals -Path $projectContext -MaxLines 3 |
        Where-Object { $statusLines -notcontains $_ } |
        Select-Object -First 2

    $signals += $statusLines | ForEach-Object { "Status: $_" }
    $signals += $technicalLines | ForEach-Object { "Signal: $_" }
    $signals += Get-CleanIndexLines -Path $decisions -MaxLines 2 -Prefix "Decision: "
    $signals += Get-CleanIndexLines -Path $nextActions -MaxLines 2 -Prefix "Next: "

    return @($signals | Select-Object -First 6)
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

        $summaryLines = Get-ProjectIndexSignals -ProjectDir $project.FullName

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
