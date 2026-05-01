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
$projectDir = Join-Path $vault "projects\$ProjectName"

if (!(Test-Path $projectDir)) {
    Write-Host "Project not found: $ProjectName"
    Write-Host ""
    Write-Host "Available projects:"
    Get-ChildItem (Join-Path $vault "projects") -Directory | Select-Object -ExpandProperty Name
    exit 1
}

Start-Process explorer.exe $projectDir
Write-Host "Opened ContextOS project folder:"
Write-Host $projectDir
