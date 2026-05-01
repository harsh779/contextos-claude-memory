# ContextOS v0.1.2 Release Checklist

Do not create or push the `v0.1.2` tag until this checklist is complete and release approval is explicit.

## Scope Check

- [ ] `install.ps1` prints the ContextOS version being installed.
- [ ] `install.ps1` prints repo root and vault path.
- [ ] `install.ps1` lists copied scripts.
- [ ] `install.ps1` reports command wrappers created.
- [ ] `install.ps1` reports `CONTEXTOS_VAULT_PATH` status.
- [ ] `install.ps1` reports PATH update status.
- [ ] `install.ps1` states rerunning after pull is safe.
- [ ] `install.ps1` states existing project memory is not deleted or overwritten.
- [ ] `install.ps1` states reruns update `AI-Memory-Vault\scripts\`.
- [ ] `docs/UPGRADE.md` exists and covers standard and custom vault upgrades.
- [ ] README links to `docs/UPGRADE.md`.

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

- [ ] unset `CONTEXTOS_COPY_RAW_TRANSCRIPTS` keeps copying disabled.
- [ ] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=True` keeps copying disabled.
- [ ] `CONTEXTOS_COPY_RAW_TRANSCRIPTS=true` enables copying.
- [ ] core memory files generate in all cases.

Run installer smoke test with a temp vault:

```powershell
$tempVault = Join-Path $env:TEMP ("contextos-install-test-" + [guid]::NewGuid().ToString())
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath $tempVault -SkipPathUpdate
```

Confirm:

- [ ] `$tempVault` exists.
- [ ] `$tempVault\scripts` exists.
- [ ] `$tempVault\scripts\contextos-capture.ps1` exists.
- [ ] `$tempVault\scripts\contextos-status.ps1` exists.
- [ ] `$tempVault\scripts\process-session.py` exists.
- [ ] `$tempVault\contextos-status.ps1` exists.
- [ ] `$tempVault\contextos-find.ps1` exists.
- [ ] `$tempVault\contextos-resume.ps1` exists.
- [ ] `$tempVault\contextos-open.ps1` exists.

Run status smoke test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-status.ps1
```

Confirm:

- [ ] status output includes `Raw transcript copying`.
- [ ] status output reports `v0.1.2-dev` before release tagging.

## Git Safety

- [ ] `git status` is clean before tagging.
- [ ] `git log --oneline -5` shows the installer reliability commit and release prep commit.
- [ ] `git push origin main` has completed.
- [ ] `main` is up to date with `origin/main`.

## Release Tag Step

Only after explicit approval:

```powershell
git tag v0.1.2
git push origin v0.1.2
```

Post-tag:

- [ ] Confirm GitHub shows the `v0.1.2` tag.
- [ ] Update release notes or GitHub release body if needed.
