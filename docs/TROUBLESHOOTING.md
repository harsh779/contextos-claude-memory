# Troubleshooting

## Hook does not appear in /hooks

First validate settings file:

```powershell
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
(Get-Content $settingsPath -Raw | ConvertFrom-Json).hooks.PSObject.Properties.Name
```

Expected:

```txt
SessionStart
SessionEnd
```

## Manual capture says unknown-project

Likely JSON parsing/BOM issue.

Ensure `process-session.py` reads event JSON with:

```python
encoding="utf-8-sig"
```

## Claude writes memory files inside repo

This is incorrect.

ContextOS memory files should live in:

```txt
AI-Memory-Vault\projects\<project-name>
```

Add this rule to startup context:

```txt
Never create or edit ContextOS memory files inside the working directory. SessionEnd hook updates memory in the vault.
```

## Permission prompts appear

Add vault permissions to Claude Code settings:

```json
"Read(C:\\Users\\<User>\\AI-Memory-Vault\\**)",
"Write(C:\\Users\\<User>\\AI-Memory-Vault\\**)",
"Edit(C:\\Users\\<User>\\AI-Memory-Vault\\**)"
```

## contextos-find not recognized

Add Memory Vault root to PATH:

```powershell
$env:Path += ";C:\Users\<User>\AI-Memory-Vault"
```

Make permanent:

```powershell
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$userPath;C:\Users\<User>\AI-Memory-Vault", "User")
```

## PowerShell parser error

Use single quotes around rules that contain inner double quotes.
