# Upgrade Guide

ContextOS upgrades are handled by rerunning `install.ps1` after pulling the latest repo changes.

The installer is safe to rerun. It updates reusable scripts and command wrappers, but it does not delete or overwrite existing project memory.

## When to Rerun install.ps1

Rerun the installer after:

- pulling a new ContextOS release
- changing your vault location
- restoring a machine or PowerShell profile
- seeing old behavior after updating the repo
- editing Claude Code settings to point at a new vault

## Standard Upgrade Command

From the repo root:

```powershell
git pull
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Custom Vault Upgrade Command

If you use a custom vault:

```powershell
git pull
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath "D:\ContextOS"
```

## What Gets Updated

The installer updates reusable ContextOS files in:

```text
AI-Memory-Vault\scripts\
```

It also creates or refreshes command wrappers in the vault root:

```text
contextos-status.ps1
contextos-find.ps1
contextos-projects.ps1
contextos-resume.ps1
contextos-open.ps1
contextos-doctor.ps1
```

The installer may also update:

- user `CONTEXTOS_VAULT_PATH`
- user PATH, unless `-SkipPathUpdate` is passed

## What Does Not Get Touched

The installer does not delete or overwrite existing project memory, including:

- `projects\<project-name>\PROJECT_CONTEXT.md`
- `projects\<project-name>\SESSION_LOG.md`
- `projects\<project-name>\DECISIONS.md`
- `projects\<project-name>\NEXT_ACTIONS.md`
- `projects\<project-name>\TOKEN_SAVINGS.md`
- `projects\<project-name>\graph.mmd`
- existing `context-packs\`
- existing `debug\` files

Raw transcript copying remains disabled by default. It is enabled only when `CONTEXTOS_COPY_RAW_TRANSCRIPTS` is exactly lowercase `true`.

Cross-project startup injection is enabled by default. It is disabled only when `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY` is exactly lowercase `false`.

## Validate After Upgrade

Open a new PowerShell window if PATH was updated, then run:

```powershell
contextos-status
contextos-doctor
contextos-projects
```

Expected checks:

```text
Vault exists:                    Yes
Scripts folder exists:           Yes
Required scripts installed:      Yes
Raw transcript copying:          Disabled
Cross-project memory:            Enabled
Project index exists:            Yes
```

You can also run the local script directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-projects.ps1
```

## Troubleshooting Old Behavior

If old behavior remains after an upgrade:

1. Confirm you ran `install.ps1` from the updated repo root.
2. Confirm `contextos-status` points to the expected vault path.
3. Confirm the updated scripts exist in:

```text
AI-Memory-Vault\scripts\
```

4. If you use a custom vault, rerun install with the same `-VaultPath`.
5. Open a new PowerShell window if PATH was updated.
6. Check Claude Code settings and confirm hooks point to the current vault scripts.
7. Run `contextos-doctor` and follow the Recommended Fixes section.
8. Run `contextos-projects` to refresh the vault-level project index.

For v0.1.1 and later, verify raw transcript privacy behavior with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-raw-transcript-privacy.ps1
```
