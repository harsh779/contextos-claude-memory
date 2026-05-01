# ContextOS v0.1.3 - Doctor Command and Self-Healing Diagnostics

Status: released after final checklist validation.

## Summary

ContextOS v0.1.3 adds `contextos-doctor`, a diagnostic command for checking whether ContextOS is installed, upgraded, and hooked into Claude Code correctly.

Doctor is read-only. It reports OK/WARN/FAIL checks and collects recommended fixes at the end.

This release also includes a doctor environment detection fix so user-level `CONTEXTOS_VAULT_PATH` is recognized even when the current PowerShell process does not have the variable loaded.

## What Changed

### New Doctor Command

New script:

```text
scripts/contextos-doctor.ps1
```

Installed wrapper:

```text
AI-Memory-Vault\contextos-doctor.ps1
```

Command:

```powershell
contextos-doctor
```

Direct fallback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
```

### Diagnostics Covered

Doctor checks:

- ContextOS version
- `CONTEXTOS_VAULT_PATH`
- resolved vault path
- expected vault folders
- installed scripts
- command wrappers
- user PATH
- Python availability
- Claude Code settings and hooks
- raw transcript privacy status

### User-Level Environment Detection

Doctor checks both:

- current process `CONTEXTOS_VAULT_PATH`
- user-level `CONTEXTOS_VAULT_PATH`

This avoids false warnings after install when the user-level environment variable is set but the current shell has not been restarted.

### Recommended Fixes

Doctor collects recommended fixes and prints them at the end, including:

- rerun install
- rerun install with a custom vault
- add vault root to PATH
- restart PowerShell after PATH changes
- merge the Claude Code settings snippet from `install.ps1`
- run `contextos-status`

### Installer Updates

`install.ps1` now installs the doctor script and creates the root wrapper.

The installer now recommends:

```powershell
contextos-status
contextos-doctor
```

### Status Updates

`contextos-status` now reports:

```text
Doctor command available:        Yes
```

## Privacy Behavior

Raw transcript privacy behavior is unchanged.

Raw transcript copying remains disabled by default and is enabled only when:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Only exact lowercase `true` enables raw transcript copying.

## Install and Upgrade Note

After pulling v0.1.3, rerun:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Then validate:

```powershell
contextos-status
contextos-doctor
```

## Validation Evidence

Validated before release tag:

- PowerShell parse checks passed.
- Python compile checks passed.
- Raw transcript privacy regression passed.
- Installed doctor smoke test passed.
- `contextos-status --version` returned `ContextOS v0.1.3`.
- `contextos-doctor` reported `ContextOS version: v0.1.3` and `Final Result`.

## Files Changed

- `scripts/contextos-doctor.ps1`
- `install.ps1`
- `scripts/contextos-status.ps1`
- `README.md`
- `docs/DOCTOR.md`
- `docs/USAGE.md`
- `docs/UPGRADE.md`
- `docs/RELEASE_NOTES_v0.1.3.md`
- `docs/RELEASE_CHECKLIST_v0.1.3.md`
- `PLANS.md`

## Release Status

Release checklist completed in `docs/RELEASE_CHECKLIST_v0.1.3.md`.
