# ContextOS v0.1.3 Release Checklist

Do not create or push the `v0.1.3` tag until this checklist is complete and release approval is explicit.

## Scope Check

- [ ] `scripts/contextos-doctor.ps1` exists.
- [ ] `install.ps1` copies `contextos-doctor.ps1` into the vault scripts folder.
- [ ] `install.ps1` creates `contextos-doctor.ps1` in the vault root.
- [ ] `install.ps1` recommends `contextos-status` and `contextos-doctor`.
- [ ] `scripts/contextos-status.ps1` reports doctor availability.
- [ ] `install.ps1`, `contextos-status.ps1`, and `contextos-doctor.ps1` use `v0.1.3-dev`.
- [ ] `docs/DOCTOR.md` exists.
- [ ] README documents `contextos-doctor`.
- [ ] `docs/USAGE.md` includes doctor diagnostics.
- [ ] `docs/UPGRADE.md` recommends doctor after upgrade.

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

- [ ] unset `CONTEXTOS_COPY_RAW_TRANSCRIPTS` keeps copying disabled.
- [ ] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=True` keeps copying disabled.
- [ ] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=true` enables copying.
- [ ] core memory files generate in all cases.

Run direct doctor smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
```

Confirm output includes:

- [ ] ContextOS Doctor
- [ ] Version
- [ ] Vault
- [ ] Scripts
- [ ] Wrappers
- [ ] PATH
- [ ] Python
- [ ] Claude Hooks
- [ ] Privacy
- [ ] Recommended Fixes
- [ ] Final Result

Run installer temp-vault smoke test:

```powershell
$tempVault = Join-Path $env:TEMP ("contextos-doctor-test-" + [guid]::NewGuid().ToString())
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath $tempVault -SkipPathUpdate
```

Confirm:

- [ ] `$tempVault` exists.
- [ ] `$tempVault\scripts` exists.
- [ ] `$tempVault\scripts\contextos-doctor.ps1` exists.
- [ ] `$tempVault\contextos-doctor.ps1` exists.
- [ ] `$tempVault\scripts\contextos-status.ps1` exists.
- [ ] `$tempVault\contextos-status.ps1` exists.

Run installed doctor smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$tempVault\contextos-doctor.ps1"
```

Confirm:

- [ ] script runs without crashing.
- [ ] it resolves the temp vault.
- [ ] output includes `Final Result`.

Run status smoke tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1 --version
```

Confirm:

- [ ] status output includes `Raw transcript copying`.
- [ ] status output includes `Doctor command available`.
- [ ] version output is `ContextOS v0.1.3-dev`.

## Git Safety

- [ ] `git status` is clean before tagging.
- [ ] `git push origin main` has completed.
- [ ] `main` is up to date with `origin/main`.

## Release Tag Step

Only after explicit approval:

```powershell
git tag v0.1.3
git push origin v0.1.3
```
