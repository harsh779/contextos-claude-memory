# v0.1.3 Doctor Command and Self-Healing Diagnostics Plan

## Scope

- Add `scripts/contextos-doctor.ps1`.
- Install a root `contextos-doctor.ps1` wrapper through `install.ps1`.
- Add doctor availability to `contextos-status`.
- Add doctor docs, usage/upgrade notes, and v0.1.3 release prep docs.
- Keep raw transcript privacy behavior unchanged.

## Constraints

- Do not create or push a v0.1.3 tag.
- Keep `CONTEXTOS_COPY_RAW_TRANSCRIPTS` privacy-first and exact lowercase `true` only.
- Do not delete, rename, or move existing docs.
- Keep PowerShell output readable and Windows-first.

## Unknowns

- Final v0.1.3 release/tag timing: Not specified.

## Decisions

- Use `v0.1.3-dev` in `install.ps1`, `contextos-status.ps1`, and `contextos-doctor.ps1`.
- Let doctor infer the vault from installed script location when run from `AI-Memory-Vault\scripts\`.
- Collect recommended fixes during checks and print them at the end.

## Implementation Sequence

1. Add `scripts/contextos-doctor.ps1`.
2. Update `install.ps1` wrappers and next recommended commands.
3. Update `scripts/contextos-status.ps1`.
4. Add doctor docs and update README, usage, and upgrade docs.
5. Add v0.1.3 release prep docs.
6. Run required validation.
7. Commit and push `main`.

## Validation Sequence

- PowerShell parse checks.
- Python compile checks.
- Raw transcript privacy regression.
- Direct doctor smoke test.
- Installer temp-vault smoke test.
- Installed doctor smoke test from temp vault.
- Status smoke test and version check.
- Git diff/status review.

## Risks

- Doctor must not fail just because one diagnostic check fails.
- Temp-vault wrapper execution must resolve the temp vault, not the user's default vault.
- Diagnostics must provide actionable fixes without modifying user files.
