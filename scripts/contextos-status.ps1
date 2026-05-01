param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ArgsList
)

$ErrorActionPreference = "SilentlyContinue"
$ContextOSVersion = "v0.1.1-dev"

if ($ArgsList -contains "--version" -or $ArgsList -contains "-v") {
    Write-Host "ContextOS $ContextOSVersion"
    exit 0
}

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

function Test-CopyRawTranscriptsEnabled {
    return ($env:CONTEXTOS_COPY_RAW_TRANSCRIPTS -ceq "true")
}

function Write-Status {
    param(
        [string]$Label,
        [string]$Value
    )

    "{0,-32} {1}" -f $Label, $Value
}

$vault = Get-ContextOSVaultPath
$scriptsDir = Join-Path $vault "scripts"
$projectsDir = Join-Path $vault "projects"
$packsDir = Join-Path $vault "context-packs"
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"

$requiredScripts = @(
    "contextos-start.ps1",
    "contextos-capture.ps1",
    "process-session.py",
    "compress-project-memory.py",
    "contextos-find.ps1",
    "contextos-resume.ps1",
    "contextos-open.ps1"
)

$missingScripts = @()

foreach ($script in $requiredScripts) {
    $path = Join-Path $scriptsDir $script
    if (!(Test-Path $path)) {
        $missingScripts += $script
    }
}

$projectCount = 0
if (Test-Path $projectsDir) {
    $projectCount = @(Get-ChildItem $projectsDir -Directory).Count
}

$contextPackCount = 0
if (Test-Path $packsDir) {
    $contextPackCount = @(Get-ChildItem $packsDir -File -Filter "*.md").Count
}

$tokenSavingsFiles = @()
$totalEstimatedAvoided = 0

if (Test-Path $projectsDir) {
    $tokenSavingsFiles = Get-ChildItem $projectsDir -Recurse -File -Filter "TOKEN_SAVINGS.md"

    foreach ($file in $tokenSavingsFiles) {
        $text = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($text -match "Estimated repeated context avoided:\s*([\d,]+)\s*tokens") {
            $value = $matches[1] -replace ",", ""
            $totalEstimatedAvoided += [int]$value
        }
    }
}

$hooksConfigured = "No"
$sessionStartHook = "No"
$sessionEndHook = "No"

if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settings.hooks) {
            $hooksConfigured = "Yes"
            if ($settings.hooks.SessionStart) {
                $sessionStartHook = "Yes"
            }
            if ($settings.hooks.SessionEnd) {
                $sessionEndHook = "Yes"
            }
        }
    } catch {
        $hooksConfigured = "Settings JSON unreadable"
    }
}

$lastEvent = $null

if (Test-Path $projectsDir) {
    $events = Get-ChildItem $projectsDir -Recurse -File -Filter "*-event.json" |
        Sort-Object LastWriteTime -Descending

    if ($events.Count -gt 0) {
        $lastEvent = $events[0]
    }
}

$lastProject = "None"
$lastCapture = "None"

if ($lastEvent) {
    $lastCapture = $lastEvent.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

    try {
        $eventData = Get-Content $lastEvent.FullName -Raw | ConvertFrom-Json
        if ($eventData.cwd) {
            $lastProject = Split-Path $eventData.cwd -Leaf
        } else {
            $lastProject = Split-Path (Split-Path $lastEvent.DirectoryName -Parent) -Leaf
        }
    } catch {
        $lastProject = Split-Path (Split-Path $lastEvent.DirectoryName -Parent) -Leaf
    }
}

Write-Host ""
Write-Host "ContextOS Status"
Write-Host "================"
Write-Host ""

Write-Status "Version:" $ContextOSVersion
Write-Status "Vault path:" $vault
Write-Status "Vault exists:" $(if (Test-Path $vault) { "Yes" } else { "No" })
Write-Status "Scripts folder exists:" $(if (Test-Path $scriptsDir) { "Yes" } else { "No" })
Write-Status "Required scripts installed:" $(if ($missingScripts.Count -eq 0) { "Yes" } else { "No" })
Write-Status "Projects tracked:" $projectCount
Write-Status "Context packs created:" $contextPackCount
Write-Status "Token savings files:" @($tokenSavingsFiles).Count
Write-Status "Estimated tokens avoided:" $totalEstimatedAvoided
Write-Status "Raw transcript copying:" $(if (Test-CopyRawTranscriptsEnabled) { "Enabled" } else { "Disabled" })
Write-Status "Claude settings found:" $(if (Test-Path $settingsPath) { "Yes" } else { "No" })
Write-Status "Hooks configured:" $hooksConfigured
Write-Status "SessionStart hook:" $sessionStartHook
Write-Status "SessionEnd hook:" $sessionEndHook
Write-Status "Last captured project:" $lastProject
Write-Status "Last capture time:" $lastCapture

if ($missingScripts.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing scripts:"
    foreach ($script in $missingScripts) {
        Write-Host "- $script"
    }
}

Write-Host ""
