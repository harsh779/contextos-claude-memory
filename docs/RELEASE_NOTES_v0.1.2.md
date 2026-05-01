# ContextOS v0.1.2 - Installer and Upgrade Reliability

Status: released after final checklist validation.

## Summary

ContextOS v0.1.2 improves install and upgrade reliability.

The installer now gives clearer output, explains that rerunning it is safe after pulling a new version, and prints a compact validation summary so users can confirm the active vault scripts were updated.

## What Changed

### Clearer Install and Upgrade Output

`install.ps1` now prints:

- ContextOS version being installed
- repo root
- vault path
- scripts copied into the vault
- command wrappers created
- `CONTEXTOS_VAULT_PATH` status
- PATH update status
- Python detection status
- Claude Code settings snippet
- next recommended command: `contextos-status`

### Safe Rerun Messaging

The installer now states that rerunning `install.ps1` after pulling a new ContextOS version is safe.

Rerunning the installer updates reusable scripts in:

```text
AI-Memory-Vault\scripts\
```

Existing project memory is not deleted or overwritten.

### Upgrade Guide

Added:

```text
docs/UPGRADE.md
```

It covers:

- when to rerun `install.ps1`
- standard upgrade command
- custom vault upgrade command
- what gets updated
- what does not get touched
- how to validate after upgrade
- troubleshooting old behavior after upgrade

### Post-Install Validation Summary

The installer now ends with a compact summary:

```text
Vault exists:                 Yes
Scripts folder exists:        Yes
Scripts copied:               9/9
Command wrappers created:     4/4
Python:                       Detected (...)
Claude settings snippet:      Printed
CONTEXTOS_VAULT_PATH:         ...
PATH update:                  ...
```

### Environment Reliability

If Windows blocks setting user-level `CONTEXTOS_VAULT_PATH` or PATH, the installer now reports a warning instead of failing the entire install.

The installer still completes vault setup, script copying, wrapper creation, and snippet output.

## Privacy Behavior

Raw transcript privacy behavior is unchanged from v0.1.1.

Raw transcript copying remains disabled by default and is enabled only when:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Only exact lowercase `true` enables raw transcript copying.

## Upgrade Instructions

After pulling v0.1.2, rerun:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

For a custom vault:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath "D:\ContextOS"
```

Then validate:

```powershell
contextos-status
```

## Validation Evidence

Validated before release tag:

- PowerShell parse checks passed.
- Python compile checks passed.
- Raw transcript privacy regression passed.
- Installer temp-vault smoke test passed.
- Status command smoke test passed.

## Files Changed

- `install.ps1`
- `scripts/contextos-status.ps1`
- `README.md`
- `docs/UPGRADE.md`
- `docs/SETUP_WINDOWS.md`
- `docs/USAGE.md`
- `PLANS.md`

## Release Status

Release checklist completed in `docs/RELEASE_CHECKLIST_v0.1.2.md`.
