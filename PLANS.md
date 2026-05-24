# v0.1.4 Cross-Project Awareness Plan

## Scope

- Add a vault-level `PROJECT_INDEX.md` that summarizes tracked projects.
- Add a `contextos-projects` command to refresh and display the project index.
- Make default SessionStart behavior include current project memory plus compact cross-project awareness.
- Add an opt-out for cross-project startup injection behind `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false`.
- Surface cross-project status in `contextos-status` and `contextos-doctor`.
- Update installer wrappers and user docs.

## Constraints

- Do not weaken raw transcript privacy behavior.
- Do not inject all project memory by default.
- Keep injected cross-project context compact and summary-only.
- Do not copy raw transcripts or session logs into the global index.
- Avoid new dependencies.

## Unknowns

- Final v0.1.4 release/tag timing: Not specified.
- Whether cross-project context should later use semantic ranking: Not specified.

## Decisions

- Use `v0.1.4-dev` during implementation.
- Store the global index at `AI-Memory-Vault\PROJECT_INDEX.md`.
- Add `scripts/contextos-projects.ps1` as the explicit cross-project discovery command.
- Enable startup cross-project injection by default. Disable it only when `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY` is exactly `false`.
- Rebuild `PROJECT_INDEX.md` automatically on SessionEnd so it stays current after each completed Claude Code session. SessionStart and `contextos-projects` also refresh it as fallback/manual paths.

## Implementation Sequence

1. Add shared project-index generation logic to SessionEnd and SessionStart.
2. Add `contextos-projects.ps1`.
3. Update installer wrappers and script lists.
4. Update status and doctor diagnostics.
5. Update README and relevant docs.
6. Run parse and smoke validation.

## Validation Sequence

- PowerShell parse checks for changed scripts.
- Python compile checks for existing Python scripts.
- Raw transcript privacy regression.
- `contextos-projects` temp-vault smoke test.
- `contextos-start` default mode smoke test confirms no cross-project section unless enabled.
- `contextos-start` enabled mode smoke test confirms compact cross-project context appears.
- Installer temp-vault smoke test confirms wrapper creation.

## Risks

- Cross-project context could leak unrelated project details if enabled too broadly.
- Large vaults could produce bloated startup context if index generation is not capped.
- Existing users need to rerun `install.ps1` before the new command wrapper exists in their vault.
