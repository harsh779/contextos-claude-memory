# ContextOS v0.1.3 Release Checklist

Final release approval received. The `v0.1.3` tag can be created after this checklist is committed and pushed.

## Scope Check

- [x] `scripts/contextos-doctor.ps1` exists.
- [x] `install.ps1` copies `contextos-doctor.ps1` into the vault scripts folder.
- [x] `install.ps1` creates `contextos-doctor.ps1` in the vault root.
- [x] `install.ps1` recommends `contextos-status` and `contextos-doctor`.
- [x] `scripts/contextos-status.ps1` reports doctor availability.
- [x] `install.ps1`, `contextos-status.ps1`, and `contextos-doctor.ps1` use `v0.1.3`.
- [x] `docs/DOCTOR.md` exists.
- [x] README documents `contextos-doctor`.
- [x] `docs/USAGE.md` includes doctor diagnostics.
- [x] `docs/UPGRADE.md` recommends doctor after upgrade.

## Required Validation

Run PowerShell parse checks:

```powershell
$null = [scriptblock]::Create((Get-Content .\install.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\contextos-status.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\contextos-capture.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\contextos-doctor.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\test-raw-transcript-privacy.ps1 -Raw))
Write-Host "PowerShell parse OK"
```

Run Python compile checks:

```powershell
python -m py_compile .\scripts\process-session.py .\scripts\compress-project-memory.py
```

Run raw transcript privacy regression:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-raw-transcript-privacy.ps1
```

Expected:

- [x] unset `CONTEXTOS_COPY_RAW_TRANSCRIPTS` keeps copying disabled.
- [x] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=True` keeps copying disabled.
- [x] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=true` enables copying.
- [x] core memory files generate in all cases.

Run direct doctor smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
```

Confirm output includes:

- [x] ContextOS Doctor
- [x] Version
- [x] Vault
- [x] Scripts
- [x] Wrappers
- [x] PATH
- [x] Python
- [x] Claude Hooks
- [x] Privacy
- [x] Recommended Fixes
- [x] Final Result

Run installer temp-vault smoke test:

```powershell
$tempVault = Join-Path $env:TEMP ("contextos-doctor-test-" + [guid]::NewGuid().ToString())
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath $tempVault -SkipPathUpdate
```

Confirm:

- [x] `$tempVault` exists.
- [x] `$tempVault\scripts` exists.
- [x] `$tempVault\scripts\contextos-doctor.ps1` exists.
- [x] `$tempVault\contextos-doctor.ps1` exists.
- [x] `$tempVault\scripts\contextos-status.ps1` exists.
- [x] `$tempVault\contextos-status.ps1` exists.

Run installed doctor smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$tempVault\contextos-doctor.ps1"
```

Confirm:

- [x] script runs without crashing.
- [x] it resolves the temp vault.
- [x] output includes `Final Result`.

Run status smoke tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1 --version
```

Confirm:

- [x] status output includes `Raw transcript copying`.
- [x] status output includes `Doctor command available`.
- [x] version output is `ContextOS v0.1.3`.

## Validation Evidence

- PowerShell parse checks passed.
- Python compile checks passed.
- Raw transcript privacy regression passed.
- Installed doctor smoke test passed.
- `contextos-status --version` returned `ContextOS v0.1.3`.
- `contextos-doctor` showed `ContextOS version: v0.1.3`.
- `contextos-doctor` output included `Final Result`.

## Git Safety

- [x] `git status` is clean before tagging.
- [x] `git push origin main` has completed.
- [x] `main` is up to date with `origin/main`.

## Release Tag Step

Approved:

```powershell
git tag v0.1.3
git push origin v0.1.3
```
