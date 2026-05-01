# ContextOS v0.1.2 Release Checklist

Final release approval received. The `v0.1.2` tag can be created after this checklist is committed and pushed.

## Scope Check

- [x] `install.ps1` prints the ContextOS version being installed.
- [x] `install.ps1` prints repo root and vault path.
- [x] `install.ps1` lists copied scripts.
- [x] `install.ps1` reports command wrappers created.
- [x] `install.ps1` reports `CONTEXTOS_VAULT_PATH` status.
- [x] `install.ps1` reports PATH update status.
- [x] `install.ps1` states rerunning after pull is safe.
- [x] `install.ps1` states existing project memory is not deleted or overwritten.
- [x] `install.ps1` states reruns update `AI-Memory-Vault\scripts\`.
- [x] `docs/UPGRADE.md` exists and covers standard and custom vault upgrades.
- [x] README links to `docs/UPGRADE.md`.

## Required Validation

Run PowerShell parse checks:

```powershell
$null = [scriptblock]::Create((Get-Content .\install.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\contextos-capture.ps1 -Raw))
$null = [scriptblock]::Create((Get-Content .\scripts\contextos-status.ps1 -Raw))
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

Run installer smoke test with a temp vault:

```powershell
$tempVault = Join-Path $env:TEMP ("contextos-install-test-" + [guid]::NewGuid().ToString())
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath $tempVault -SkipPathUpdate
```

Confirm:

- [x] `$tempVault` exists.
- [x] `$tempVault\scripts` exists.
- [x] `$tempVault\scripts\contextos-capture.ps1` exists.
- [x] `$tempVault\scripts\contextos-status.ps1` exists.
- [x] `$tempVault\scripts\process-session.py` exists.
- [x] `$tempVault\contextos-status.ps1` exists.
- [x] `$tempVault\contextos-find.ps1` exists.
- [x] `$tempVault\contextos-resume.ps1` exists.
- [x] `$tempVault\contextos-open.ps1` exists.

Run status smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1
```

Confirm:

- [x] status output includes `Raw transcript copying`.
- [x] status output reports `v0.1.2`.

## Git Safety

- [x] `git status` is clean before tagging.
- [x] `git log --oneline -5` shows the installer reliability commit and release prep commit.
- [x] `git push origin main` has completed.
- [x] `main` is up to date with `origin/main`.

## Release Tag Step

Approved:

```powershell
git tag v0.1.2
git push origin v0.1.2
```

Post-tag verification:

- [ ] Confirm GitHub shows the `v0.1.2` tag.
- [ ] Update release notes or GitHub release body if needed.
