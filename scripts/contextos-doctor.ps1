param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ArgsList
)

$ErrorActionPreference = "SilentlyContinue"
$ContextOSVersion = "v0.1.3-dev"
$script:WarnCount = 0
$script:FailCount = 0
$script:Fixes = New-Object System.Collections.Generic.List[string]

function Add-Fix {
    param([string]$Fix)

    if (![string]::IsNullOrWhiteSpace($Fix) -and !$script:Fixes.Contains($Fix)) {
        $script:Fixes.Add($Fix) | Out-Null
    }
}

function Write-Section {
    param([string]$Name)

    Write-Host ""
    Write-Host $Name
    Write-Host ("-" * $Name.Length)
}

function Write-Check {
    param(
        [string]$Status,
        [string]$Label,
        [string]$Detail = ""
    )

    if ($Status -eq "WARN") {
        $script:WarnCount++
    } elseif ($Status -eq "FAIL") {
        $script:FailCount++
    }

    if ([string]::IsNullOrWhiteSpace($Detail)) {
        "{0,-5} {1}" -f $Status, $Label
    } else {
        "{0,-5} {1}: {2}" -f $Status, $Label, $Detail
    }
}

function Test-CopyRawTranscriptsEnabled {
    return ($env:CONTEXTOS_COPY_RAW_TRANSCRIPTS -ceq "true")
}

function Get-DefaultVaultPath {
    return (Join-Path $env:USERPROFILE "AI-Memory-Vault")
}

function Get-InferredVaultPath {
    $scriptDir = $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        return $null
    }

    $current = Get-Item $scriptDir -ErrorAction SilentlyContinue

    if (!$current -or $current.Name -ne "scripts") {
        return $null
    }

    $parent = Split-Path $scriptDir -Parent

    if (Test-Path (Join-Path $parent "install.ps1")) {
        return $null
    }

    return $parent
}

function Get-ContextOSVaultPath {
    if (![string]::IsNullOrWhiteSpace($env:CONTEXTOS_VAULT_PATH)) {
        return $env:CONTEXTOS_VAULT_PATH
    }

    $inferred = Get-InferredVaultPath

    if (![string]::IsNullOrWhiteSpace($inferred)) {
        return $inferred
    }

    return (Get-DefaultVaultPath)
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

function Test-FileContains {
    param(
        [string]$Path,
        [string]$Pattern
    )

    if (!(Test-Path $Path)) {
        return $false
    }

    $text = Get-Content $Path -Raw -ErrorAction SilentlyContinue

    if ($null -eq $text) {
        return $false
    }

    return ($text -like "*$Pattern*")
}

$vaultEnvValue = $env:CONTEXTOS_VAULT_PATH
$vault = Get-ContextOSVaultPath
$scriptsDir = Join-Path $vault "scripts"
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host ""
Write-Host "ContextOS Doctor"
Write-Host "================"

Write-Section "Version"
Write-Check "OK" "ContextOS version" $ContextOSVersion

Write-Section "Vault"
if ([string]::IsNullOrWhiteSpace($vaultEnvValue)) {
    Write-Check "WARN" "CONTEXTOS_VAULT_PATH" "Not set; resolved vault from install location or default"
    Add-Fix "Rerun install: powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1"
} else {
    Write-Check "OK" "CONTEXTOS_VAULT_PATH" $vaultEnvValue
}

Write-Check "OK" "Resolved vault path" $vault

$vaultChecks = [ordered]@{
    "Vault exists" = $vault
    "projects folder exists" = (Join-Path $vault "projects")
    "scripts folder exists" = $scriptsDir
    "context-packs folder exists" = (Join-Path $vault "context-packs")
    "debug folder exists" = (Join-Path $vault "debug")
    "inbox folder exists" = (Join-Path $vault "inbox")
}

foreach ($label in $vaultChecks.Keys) {
    $path = $vaultChecks[$label]
    if (Test-Path $path) {
        Write-Check "OK" $label $path
    } else {
        Write-Check "FAIL" $label $path
        Add-Fix "Rerun install with this vault: powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath `"$vault`""
    }
}

Write-Section "Scripts"
$requiredScripts = @(
    "contextos-start.ps1",
    "contextos-capture.ps1",
    "contextos-status.ps1",
    "contextos-find.ps1",
    "contextos-resume.ps1",
    "contextos-open.ps1",
    "process-session.py",
    "compress-project-memory.py",
    "test-raw-transcript-privacy.ps1"
)

foreach ($scriptName in $requiredScripts) {
    $path = Join-Path $scriptsDir $scriptName
    if (Test-Path $path) {
        Write-Check "OK" $scriptName $path
    } else {
        Write-Check "FAIL" $scriptName "Missing from vault scripts"
        Add-Fix "Rerun install with this vault: powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath `"$vault`""
    }
}

Write-Section "Wrappers"
$wrappers = @(
    "contextos-status.ps1",
    "contextos-find.ps1",
    "contextos-resume.ps1",
    "contextos-open.ps1",
    "contextos-doctor.ps1"
)

foreach ($wrapperName in $wrappers) {
    $path = Join-Path $vault $wrapperName
    if (Test-Path $path) {
        Write-Check "OK" $wrapperName $path
    } else {
        Write-Check "FAIL" $wrapperName "Missing from vault root"
        Add-Fix "Rerun install with this vault: powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath `"$vault`""
    }
}

Write-Section "PATH"
if (Test-PathContainsEntry -PathValue $userPath -Entry $vault) {
    Write-Check "OK" "User PATH contains vault root" $vault
} else {
    Write-Check "WARN" "User PATH contains vault root" "Missing"
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $pathFixValue = $vault
    } else {
        $pathFixValue = "$userPath;$vault"
    }
    Add-Fix "Add vault to PATH: [Environment]::SetEnvironmentVariable(`"Path`", `"$pathFixValue`", `"User`")"
    Add-Fix "Restart PowerShell after PATH changes."
}

Write-Section "Python"
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCommand) {
    Write-Check "OK" "python available" $pythonCommand.Source
    $pythonVersion = (& python --version 2>&1)
    if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrWhiteSpace($pythonVersion)) {
        Write-Check "OK" "python --version" $pythonVersion
    } else {
        Write-Check "WARN" "python --version" "Could not read version"
        Add-Fix "Install or repair Python; SessionEnd processing requires Python."
    }
} else {
    Write-Check "FAIL" "python available" "Not found"
    Add-Fix "Install Python; SessionEnd processing requires Python."
}

Write-Section "Claude Hooks"
if (Test-Path $settingsPath) {
    Write-Check "OK" "Claude settings file exists" $settingsPath
    $settingsText = Get-Content $settingsPath -Raw -ErrorAction SilentlyContinue
    try {
        $settings = $settingsText | ConvertFrom-Json
        Write-Check "OK" "Settings JSON readable"

        if ($settings.hooks) {
            Write-Check "OK" "hooks block exists"
        } else {
            Write-Check "FAIL" "hooks block exists" "Missing"
            Add-Fix "Rerun install and merge the printed Claude Code settings snippet."
        }

        if ($settings.hooks -and $settings.hooks.SessionStart) {
            Write-Check "OK" "SessionStart hook exists"
        } else {
            Write-Check "FAIL" "SessionStart hook exists" "Missing"
            Add-Fix "Rerun install and merge the printed Claude Code settings snippet."
        }

        if ($settings.hooks -and $settings.hooks.SessionEnd) {
            Write-Check "OK" "SessionEnd hook exists"
        } else {
            Write-Check "FAIL" "SessionEnd hook exists" "Missing"
            Add-Fix "Rerun install and merge the printed Claude Code settings snippet."
        }
    } catch {
        Write-Check "FAIL" "Settings JSON readable" $_.Exception.Message
        Add-Fix "Fix JSON syntax in $settingsPath, then rerun install and merge the printed settings snippet."
    }

    if ($settingsText -like "*contextos-start.ps1*") {
        Write-Check "OK" "contextos-start.ps1 appears in settings"
    } else {
        Write-Check "FAIL" "contextos-start.ps1 appears in settings" "Missing"
        Add-Fix "Rerun install and merge the printed Claude Code settings snippet."
    }

    if ($settingsText -like "*contextos-capture.ps1*") {
        Write-Check "OK" "contextos-capture.ps1 appears in settings"
    } else {
        Write-Check "FAIL" "contextos-capture.ps1 appears in settings" "Missing"
        Add-Fix "Rerun install and merge the printed Claude Code settings snippet."
    }
} else {
    Write-Check "FAIL" "Claude settings file exists" $settingsPath
    Add-Fix "Rerun install and merge the printed Claude Code settings snippet into %USERPROFILE%\.claude\settings.json."
}

Write-Section "Privacy"
if (Test-CopyRawTranscriptsEnabled) {
    Write-Check "WARN" "Raw transcript copying" "Enabled"
    Write-Host "WARN  Raw transcript copying is enabled. This may store duplicate raw Claude transcripts in the vault."
} else {
    Write-Check "OK" "Raw transcript copying" "Disabled"
}

Write-Section "Recommended Fixes"
if ($script:Fixes.Count -eq 0) {
    Write-Host "OK    No recommended fixes."
} else {
    foreach ($fix in $script:Fixes) {
        Write-Host "- $fix"
    }
    Write-Host "- Run status: contextos-status"
}

Write-Section "Final Result"
if ($script:FailCount -gt 0) {
    Write-Host "FAIL: ContextOS is not correctly installed."
} elseif ($script:WarnCount -gt 0) {
    Write-Host "WARN: ContextOS works, but some improvements are recommended."
} else {
    Write-Host "OK: ContextOS looks healthy."
}

exit 0
