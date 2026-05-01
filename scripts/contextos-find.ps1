param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Query
)

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

$vault = Get-ContextOSVaultPath
$projectsPath = Join-Path $vault "projects"
$queryText = ($Query -join " ").Trim()

if ([string]::IsNullOrWhiteSpace($queryText)) {
    Write-Host "Usage: contextos-find <search terms>"
    exit 1
}

if (!(Test-Path $projectsPath)) {
    Write-Host "No ContextOS projects folder found at $projectsPath"
    exit 1
}

$terms = $queryText.ToLower().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

$files = Get-ChildItem $projectsPath -Recurse -File -Include *.md,*.mmd |
    Where-Object {
        $_.FullName -notlike "*\raw\*" -and
        $_.FullName -notlike "*\sessions\*" -and
        $_.FullName -notlike "*\archives\*" -and
        $_.Name -notlike "SESSION_LOG_ARCHIVE*"
    }

$results = @()

function Is-LowValueLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return $true }

    $trimmed = $Line.Trim()

    if ($trimmed.StartsWith("#")) { return $true }
    if ($trimmed -like "**Working Directory:**") { return $true }
    if ($trimmed -like "*$vault*") { return $true }
    if ($trimmed -like "*Older session log archived here:*") { return $true }
    if ($trimmed -like "*Compression time:*") { return $true }
    if ($trimmed -like "*matched file*") { return $true }

    return $false
}

foreach ($file in $files) {
    $text = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($text)) { continue }

    $projectName = ($file.FullName -replace [regex]::Escape($projectsPath + "\"), "").Split("\")[0]

    $bestLine = ""
    $bestLineScore = 0
    $fileScore = 0

    $lines = $text -split "`r?`n"

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if (Is-LowValueLine $trimmed) { continue }

        $lineLower = $trimmed.ToLower()
        $lineScore = 0

        foreach ($term in $terms) {
            if ($lineLower.Contains($term)) {
                $lineScore += 1
            }
        }

        if ($lineScore -gt 0) {
            $fileScore += $lineScore
        }

        if ($lineScore -gt $bestLineScore) {
            $bestLineScore = $lineScore
            $bestLine = $trimmed
        }
    }

    if ($fileScore -gt 0) {
        if ([string]::IsNullOrWhiteSpace($bestLine)) {
            $bestLine = "[matched file, but only low-value lines matched]"
        }

        $results += [PSCustomObject]@{
            Score = $fileScore
            Project = $projectName
            File = $file.Name
            Match = $bestLine
            Path = $file.FullName
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No ContextOS matches found for: $queryText"
    exit 0
}

$results |
    Sort-Object @{Expression="Score";Descending=$true}, @{Expression="Project";Descending=$false} |
    Select-Object -First 20 |
    Format-Table Score, Project, File, Match -AutoSize
