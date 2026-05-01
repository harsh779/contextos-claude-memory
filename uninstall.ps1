param(
    [string]$VaultPath = "",
    [switch]$DeleteVault,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[ContextOS] $Message"
}

function Resolve-ContextOSVaultPath {
    param([string]$InputPath)

    if (![string]::IsNullOrWhiteSpace($InputPath)) {
        return $InputPath
    }

    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

$vault = Resolve-ContextOSVaultPath -InputPath $VaultPath
$vault = [System.IO.Path]::GetFullPath($vault)

Write-Step "Uninstalling ContextOS shell setup"
Write-Step "Vault path: $vault"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (![string]::IsNullOrWhiteSpace($userPath)) {
    $parts = $userPath -split ";" | Where-Object {
        ![string]::IsNullOrWhiteSpace($_) -and
        ($_.TrimEnd("\") -ne $vault.TrimEnd("\"))
    }

    $newPath = ($parts -join ";")
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Step "Removed vault root from user PATH if present."
}

[Environment]::SetEnvironmentVariable("CONTEXTOS_VAULT_PATH", $null, "User")
Remove-Item Env:CONTEXTOS_VAULT_PATH -ErrorAction SilentlyContinue
Write-Step "Removed user environment variable CONTEXTOS_VAULT_PATH."

if ($DeleteVault) {
    if (!(Test-Path $vault)) {
        Write-Step "Vault folder not found. Nothing to delete."
    } else {
        if (!$Force) {
            Write-Host ""
            Write-Host "WARNING: This will delete the full ContextOS vault, including project memories, session logs, context packs, debug files, and inbox files:"
            Write-Host $vault
            Write-Host ""
            $confirmation = Read-Host "Type DELETE to continue"
            if ($confirmation -ne "DELETE") {
                Write-Step "Vault deletion cancelled."
                Write-Step "Uninstall complete. Memory vault preserved."
                exit 0
            }
        }

        Remove-Item $vault -Recurse -Force
        Write-Step "Deleted ContextOS vault."
    }
} else {
    Write-Step "Memory vault preserved. Pass -DeleteVault to remove it."
}

Write-Host ""
Write-Step "Uninstall complete. Restart PowerShell for PATH/env changes to refresh."
Write-Host ""
Write-Host "Note: This script does not edit Claude Code settings.json automatically."
Write-Host "Remove ContextOS hooks manually from: $env:USERPROFILE\.claude\settings.json"