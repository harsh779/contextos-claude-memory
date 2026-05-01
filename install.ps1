param(
    [string]$VaultPath = "",
    [switch]$SetEnvironmentVariable = $true,
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = "Stop"
$ContextOSVersion = "v0.1.3-dev"

function Write-Step {
    param([string]$Message)
    Write-Host "[ContextOS] $Message"
}

function Write-Detail {
    param([string]$Message)
    Write-Host "  - $Message"
}

function Format-YesNo {
    param([bool]$Value)
    if ($Value) { return "Yes" }
    return "No"
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

function Test-PathContainsEntry {
    param(
        [string]$PathValue,
        [string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }

    $entries = $PathValue -split ";" | ForEach-Object { $_.Trim().TrimEnd("\") }
    $normalizedEntry = $Entry.Trim().TrimEnd("\")

    return @($entries | Where-Object { $_ -ieq $normalizedEntry }).Count -gt 0
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceScripts = Join-Path $repoRoot "scripts"
$vault = Resolve-ContextOSVaultPath -InputPath $VaultPath
$vaultScripts = Join-Path $vault "scripts"
$envVarStatus = "Skipped"
$pathStatus = "Skipped"
$pythonStatus = "Warning shown"
$settingsSnippetPrinted = $false

Write-Host ""
Write-Step "Installing ContextOS $ContextOSVersion"
Write-Detail "Repo root: $repoRoot"
Write-Detail "Vault path: $vault"
Write-Detail "Safe to rerun after pulling a new ContextOS version."
Write-Detail "Existing project memory is not deleted or overwritten."
Write-Detail "Rerunning install.ps1 updates reusable scripts in: $vaultScripts"
Write-Host ""

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

Write-Step "Vault folders ready."

$scriptFiles = @(
    Get-ChildItem -Path (Join-Path $sourceScripts "*.ps1") -File
    Get-ChildItem -Path (Join-Path $sourceScripts "*.py") -File
)

foreach ($scriptFile in $scriptFiles) {
    Copy-Item $scriptFile.FullName $vaultScripts -Force
}

Write-Step "Scripts copied to $vaultScripts"
foreach ($scriptFile in ($scriptFiles | Sort-Object Name)) {
    Write-Detail $scriptFile.Name
}

$wrapperMap = [ordered]@{
    "contextos-find.ps1" = "contextos-find.ps1"
    "contextos-resume.ps1" = "contextos-resume.ps1"
    "contextos-open.ps1" = "contextos-open.ps1"
    "contextos-status.ps1" = "contextos-status.ps1"
    "contextos-doctor.ps1" = "contextos-doctor.ps1"
}

$createdWrappers = @()

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

    $createdWrappers += $wrapperName
}

Write-Step "Command wrappers ready in vault root."
foreach ($wrapperName in $createdWrappers) {
    Write-Detail $wrapperName
}

if ($SetEnvironmentVariable) {
    try {
        [Environment]::SetEnvironmentVariable("CONTEXTOS_VAULT_PATH", $vault, "User")
        $env:CONTEXTOS_VAULT_PATH = $vault
        $envVarStatus = "Set to $vault"
    } catch {
        $env:CONTEXTOS_VAULT_PATH = $vault
        $envVarStatus = "Warning: could not set user environment variable; set for current process only"
        Write-Host "[ContextOS] WARNING: Could not set user CONTEXTOS_VAULT_PATH. $($_.Exception.Message)"
    }
} else {
    $envVarStatus = "Skipped"
}

Write-Step "CONTEXTOS_VAULT_PATH: $envVarStatus"

if ($SkipPathUpdate) {
    $pathStatus = "Skipped by -SkipPathUpdate"
} else {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $userPath = ""
    }

    if (Test-PathContainsEntry -PathValue $userPath -Entry $vault) {
        $pathStatus = "Already present"
    } else {
        $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $vault } else { "$userPath;$vault" }
        try {
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $pathStatus = "Updated; restart PowerShell for permanent PATH to load"
        } catch {
            $pathStatus = "Warning: could not update user PATH"
            Write-Host "[ContextOS] WARNING: Could not update user PATH. $($_.Exception.Message)"
        }
    }
}

Write-Step "PATH update: $pathStatus"

if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonVersion = (& python --version 2>&1)
    $pythonStatus = "Detected ($pythonVersion)"
    Write-Step "Python detected: $pythonVersion"
} else {
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
$settingsSnippetPrinted = $true

$wrapperChecks = foreach ($wrapperName in $wrapperMap.Keys) {
    Test-Path (Join-Path $vault $wrapperName)
}

$scriptsCopied = foreach ($scriptFile in $scriptFiles) {
    Test-Path (Join-Path $vaultScripts $scriptFile.Name)
}

if ($settingsSnippetPrinted) {
    $settingsSnippetStatus = "Printed"
} else {
    $settingsSnippetStatus = "Not printed"
}

Write-Host ""
Write-Host "Post-install validation summary"
Write-Host "-------------------------------"
Write-Host ("Vault exists:                 {0}" -f (Format-YesNo (Test-Path $vault)))
Write-Host ("Scripts folder exists:        {0}" -f (Format-YesNo (Test-Path $vaultScripts)))
Write-Host ("Scripts copied:               {0}/{1}" -f @($scriptsCopied | Where-Object { $_ }).Count, @($scriptFiles).Count)
Write-Host ("Command wrappers created:     {0}/{1}" -f @($wrapperChecks | Where-Object { $_ }).Count, @($wrapperMap.Keys).Count)
Write-Host ("Python:                       {0}" -f $pythonStatus)
Write-Host ("Claude settings snippet:      {0}" -f $settingsSnippetStatus)
Write-Host ("CONTEXTOS_VAULT_PATH:         {0}" -f $envVarStatus)
Write-Host ("PATH update:                  {0}" -f $pathStatus)
Write-Host ""
Write-Host "Next recommended command:"
Write-Host "  contextos-status"
Write-Host "  contextos-doctor"
Write-Host ""
Write-Step "Install/upgrade complete."
