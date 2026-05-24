# Changelog

## 0.1.4-dev - In Progress

### Added
- `contextos-projects` command to refresh and print a vault-level `PROJECT_INDEX.md`.
- `PROJECT_INDEX.md` summary index across tracked projects.
- Default-on cross-project startup injection, disabled only with `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false`.
- Status and doctor diagnostics for cross-project memory and project index availability.
- Cross-project memory documentation.

### Changed
- `contextos-start.ps1` refreshes the project index during SessionStart.
- `process-session.py` refreshes the project index after SessionEnd processing.
- Documentation now defines the freshness model: SessionEnd is primary, SessionStart and `contextos-projects` are fallback/manual refresh paths.
- Project index summaries now prefer stable purpose/status, decisions, and next actions while filtering conversational chat fragments and tool-output noise.
- Project index extraction preserves high-value technical signals from latest status, such as deploy/build/database/schema errors, while leaving bootstrap-only projects as `None captured yet`.
- Installer creates a `contextos-projects.ps1` wrapper.

## 0.1.3 — 2026-05-01

### Added
- `contextos-doctor` — new diagnostic command that checks the full ContextOS environment in one shot: vault path, installed scripts, command wrappers, Python availability, Claude Code settings, SessionStart/SessionEnd hooks, and raw transcript privacy state
- Doctor reports `OK`, `WARN`, or `FAIL` per check and collects recommended fixes at the end
- User-level `CONTEXTOS_VAULT_PATH` detection — doctor now checks both the current process and user-level environment so it doesn't report false warnings after a fresh install before shell restart
- `contextos-status` now reports `Doctor command available: Yes`
- Installer now creates the doctor wrapper and recommends running `contextos-doctor` after install

### Files changed
- `scripts/contextos-doctor.ps1` (new)
- `install.ps1`
- `scripts/contextos-status.ps1`
- `docs/DOCTOR.md` (new)
- `docs/USAGE.md`
- `docs/UPGRADE.md`
- `README.md`

---

## 0.1.2 — 2026-05-01

### Added
- Upgrade-safe installer: rerunning `install.ps1` after pulling a new version is now safe — it refreshes vault scripts and command wrappers without touching existing project memory, context packs, or session logs
- Post-install validation summary printed at the end of install
- `docs/UPGRADE.md` — covers when to rerun the installer, what gets updated, what is preserved, and how to validate after upgrade

### Changed
- Installer output is clearer: prints ContextOS version, vault path, scripts copied, wrappers created, Python detection status, and next recommended command
- If Windows blocks setting `CONTEXTOS_VAULT_PATH` or PATH at user level, installer now warns instead of failing the entire install

### Files changed
- `install.ps1`
- `scripts/contextos-status.ps1`
- `docs/UPGRADE.md` (new)
- `docs/SETUP_WINDOWS.md`
- `docs/USAGE.md`
- `README.md`

---

## 0.1.1 — 2026-05-01

### Added
- Raw transcript privacy toggle: `CONTEXTOS_COPY_RAW_TRANSCRIPTS` environment variable controls whether duplicate raw transcript files are written to the vault. Default is disabled.
- Only exact lowercase `true` enables raw copying — values like `True`, `TRUE`, `1`, `yes`, or unset all keep it disabled
- `contextos-status --version` flag — prints installed version without full status output
- `contextos-status` now reports `Raw transcript copying: Disabled` or `Enabled`

### Changed
- Raw Claude Code transcript copying is now **disabled by default**. ContextOS still reads the original `transcript_path` to generate `PROJECT_CONTEXT.md`, `SESSION_LOG.md`, `DECISIONS.md`, `NEXT_ACTIONS.md`, `TOKEN_SAVINGS.md`, and `graph.mmd` — the toggle only controls duplicate raw file copies in the vault `raw/` folder

### Files changed
- `scripts/contextos-capture.ps1`
- `scripts/contextos-status.ps1`
- `scripts/test-raw-transcript-privacy.ps1` (new)
- `docs/CONFIGURATION.md`
- `docs/PRIVACY_AND_SECURITY.md`
- `docs/USAGE.md`
- `README.md`

---

## 0.1.0 — 2026-04-26

Initial working version.

- Added global Claude Code hook flow
- Added auto-bootstrap memory
- Added SessionStart injection
- Added SessionEnd capture
- Added decision extraction
- Added next-action extraction
- Added log compression
- Added contextos-find
- Added contextos-resume
- Added contextos-open
- Added documentation and examples
