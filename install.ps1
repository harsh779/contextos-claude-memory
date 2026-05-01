param(
    [string]$VaultPath = "",
    [switch]$SetEnvironmentVariable = $true,
    [switch]$SkipPathUpdate
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

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceScripts = Join-Path $repoRoot "scripts"
$vault = Resolve-ContextOSVaultPath -InputPath $VaultPath
$vaultScripts = Join-Path $vault "scripts"

Write-Step "Installing ContextOS"
Write-Step "Repo root: $repoRoot"
Write-Step "Vault path: $vault"

if (!(Test-Path $sourceScripts)) {
    throw "Source scripts folder not found: $sourceScripts"
}

$folders = @(
    $vault,
    $vaultScripts,
    (Join-Path $vault "projects"),
    (Join-Path $vault "context-packs"),
    (Join-Path $vault "debug"),
    (Join-Path $vault "inbox")
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

Write-Step "Created vault folders."

Copy-Item (Join-Path $sourceScripts "*.ps1") $vaultScripts -Force
Copy-Item (Join-Path $sourceScripts "*.py") $vaultScripts -Force

Write-Step "Copied scripts to vault/scripts."

$wrapperMap = @{
    "contextos-find.ps1" = "contextos-find.ps1"
    "contextos-resume.ps1" = "contextos-resume.ps1"
    "contextos-open.ps1" = "contextos-open.ps1"
}

foreach ($wrapperName in $wrapperMap.Keys) {
    $targetScript = $wrapperMap[$wrapperName]
    $wrapperPath = Join-Path $vault $wrapperName
    $targetPath = Join-Path $vaultScripts $targetScript

    @"
param(
    [Parameter(ValueFromRemainingArguments=`$true)]
    [string[]]`$ArgsList
)

& "$targetPath" @ArgsList
"@ | Set-Content $wrapperPath -Encoding UTF8
}

Write-Step "Created command wrappers in vault root."

if ($SetEnvironmentVariable) {
    [Environment]::SetEnvironmentVariable("CONTEXTOS_VAULT_PATH", $vault, "User")
    $env:CONTEXTOS_VAULT_PATH = $vault
    Write-Step "Set user environment variable CONTEXTOS_VAULT_PATH."
}

if (!$SkipPathUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $userPath = ""
    }

    if ($userPath -notlike "*$vault*") {
        $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $vault } else { "$userPath;$vault" }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Step "Added vault root to user PATH. Restart PowerShell for permanent PATH to load."
    } else {
        Write-Step "Vault root already present in user PATH."
    }
}

try {
    python --version | Out-Null
    Write-Step "Python detected."
} catch {
    Write-Host "[ContextOS] WARNING: Python was not detected. Install Python before using SessionEnd processing."
}

$settingsSnippet = @"
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$vaultScripts\contextos-start.ps1\"",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$vaultScripts\contextos-capture.ps1\"",
            "timeout": 60
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Read($vault\\**)",
      "Write($vault\\**)",
      "Edit($vault\\**)",
      "Bash(powershell -NoProfile -ExecutionPolicy Bypass -File \"$vaultScripts\contextos-start.ps1\")",
      "Bash(powershell -NoProfile -ExecutionPolicy Bypass -File \"$vaultScripts\contextos-capture.ps1\")",
      "Bash(python \"$vaultScripts\process-session.py\"*)"
    ]
  }
}
"@

Write-Host ""
Write-Host "Claude Code settings snippet:"
Write-Host "--------------------------------"
Write-Host $settingsSnippet
Write-Host "--------------------------------"
Write-Host ""
Write-Step "Install complete."
Write-Host ""
Write-Host "Next test:"
Write-Host "  mkdir `$env:USERPROFILE\Desktop\contextos-auto-test"
Write-Host "  cd `$env:USERPROFILE\Desktop\contextos-auto-test"
Write-Host "  claude"
Write-Host ""
Write-Host "Then ask: What ContextOS memory did you receive?"
