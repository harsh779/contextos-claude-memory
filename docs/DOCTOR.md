# ContextOS Doctor

`contextos-doctor` checks whether ContextOS is installed, upgraded, and hooked into Claude Code correctly.

It is read-only. It reports diagnostics and recommended fixes, but it does not modify your vault or Claude settings.

## When to Run It

Run doctor after:

- first install
- pulling a new ContextOS version
- rerunning `install.ps1`
- changing vault location
- editing Claude Code settings
- seeing old behavior after upgrade
- `contextos-status` reports missing scripts or hooks

## Command

If the vault root is on PATH:

```powershell
contextos-doctor
```

Direct repo fallback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
```

Installed vault fallback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\AI-Memory-Vault\contextos-doctor.ps1"
```

## What It Checks

Doctor checks:

- vault path resolution
- expected vault folders
- installed scripts
- root command wrappers
- user PATH
- Python availability
- Claude Code settings and hooks
- raw transcript privacy status
- ContextOS version

## Reading OK, WARN, and FAIL

`OK` means the check passed.

`WARN` means ContextOS can usually still work, but there is something to improve. Examples include PATH not containing the vault root or raw transcript copying being enabled.

`FAIL` means a required part is missing or broken. Examples include missing vault scripts, missing Claude hooks, or missing Python.

Final result meanings:

```text
OK: ContextOS looks healthy.
WARN: ContextOS works, but some improvements are recommended.
FAIL: ContextOS is not correctly installed.
```

## Common Fixes

Rerun install:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Rerun install with a custom vault:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath "D:\ContextOS"
```

Run status:

```powershell
contextos-status
```

Restart PowerShell after PATH changes.

If Claude hooks are missing, rerun `install.ps1` and merge the printed Claude Code settings snippet into:

```text
%USERPROFILE%\.claude\settings.json
```

## Privacy Note

Doctor reports raw transcript copying as enabled only when:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Only exact lowercase `true` enables raw transcript copying.

If enabled, doctor prints a caution because duplicate raw Claude transcripts may be stored in the vault.

## Upgrade Note

After pulling a new ContextOS version, rerun:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

This installs or refreshes `contextos-doctor.ps1` in:

```text
AI-Memory-Vault\scripts\
AI-Memory-Vault\contextos-doctor.ps1
```
