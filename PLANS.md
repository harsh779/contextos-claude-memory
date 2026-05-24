# v0.1.5 macOS Support Plan

## Scope

- Add `install-macos.sh`.
- Add macOS/Linux Bash command scripts for Claude Code hooks and user commands.
- Reuse existing Python processing for SessionEnd and project index updates.
- Keep Windows PowerShell scripts unchanged.
- Add macOS setup documentation and README links.
- Keep raw transcript privacy disabled by default.
- Keep cross-project startup memory enabled by default, with `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false` opt-out.

## Constraints

- Do not tag v0.1.5 yet.
- Avoid new dependencies beyond Bash and Python 3.
- Do not weaken Windows behavior.
- Do not store or copy raw transcripts unless `CONTEXTOS_COPY_RAW_TRANSCRIPTS=true`.
- Keep shell scripts POSIX-friendly enough for macOS Bash 3.2.

## Unknowns

- Full macOS runtime validation is not available from this Windows environment.
- Exact Claude Code macOS settings location is assumed to be `~/.claude/settings.json`.

## Decisions

- Use `v0.1.5-dev` in install/status/doctor outputs.
- Use `~/AI-Memory-Vault` as the default macOS vault path.
- Add Bash scripts with the same command names as Windows, using `.sh` suffix in `scripts/` and extensionless wrappers in the vault root.
- Keep Python as the shared SessionEnd processor and use Bash for SessionStart/status/index/search/resume/open/doctor.

## Implementation Sequence

1. Add Bash scripts under `scripts/`.
2. Add `install-macos.sh`.
3. Update Windows installer/status/doctor script lists so they recognize macOS scripts when copied.
4. Add macOS docs and update README/config/usage/upgrade/changelog.
5. Run PowerShell parse, Python compile, Bash syntax checks if available, privacy regression, and installer smoke tests.
6. Commit and push.

## Validation Sequence

- PowerShell parse checks.
- Python compile checks.
- Bash syntax checks with `bash -n` where available.
- Raw transcript privacy regression.
- Windows installer smoke check.
- macOS installer syntax/static smoke check from Windows.
- Status/doctor smoke checks.

## Risks

- Bash scripts are syntax-checked locally but not fully executed on macOS in this environment.
- Clipboard behavior for `contextos-resume.sh` depends on macOS `pbcopy`.
- Opening folders uses `open` on macOS and falls back to printing the path elsewhere.
