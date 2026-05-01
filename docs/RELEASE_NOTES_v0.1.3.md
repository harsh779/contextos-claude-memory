# ContextOS v0.1.3 - Doctor Command and Self-Healing Diagnostics

Status: release notes prepared. Do not tag v0.1.3 until final release approval.

## Summary

ContextOS v0.1.3 adds `contextos-doctor`, a diagnostic command for checking whether ContextOS is installed, upgraded, and hooked into Claude Code correctly.

Doctor is read-only. It reports OK/WARN/FAIL checks and collects recommended fixes at the end.

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

## Validation Checklist

Before release, validate:

- PowerShell parse checks
- Python compile checks
- raw transcript privacy regression
- direct doctor smoke test
- installer temp-vault smoke test
- installed doctor smoke test from temp vault
- status smoke test and version check

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

Do not tag v0.1.3 yet.

Before tagging, complete `docs/RELEASE_CHECKLIST_v0.1.3.md`.
