# v0.1.2 Installer and Upgrade Reliability Plan

## Scope

- Improve `install.ps1` output for install and safe rerun upgrade flows.
- Add a compact post-install validation summary.
- Add upgrade documentation and README links.
- Keep raw transcript privacy behavior unchanged.

## Constraints

- Do not create or push a v0.1.2 tag.
- Do not touch user project memory except expected vault folders, reusable scripts, and command wrappers.
- Keep PowerShell output readable and Windows-first.

## Unknowns

- Release tag timing: Not specified.

## Decisions

- Use `v0.1.2-dev` in installer output until an actual release tag is created.
- Keep validation checks lightweight and local.

## Implementation Sequence

1. Patch `install.ps1` output, copy reporting, PATH/env reporting, and summary.
2. Add `docs/UPGRADE.md`.
3. Update README and setup/usage docs where useful.
4. Run required validation.
5. Commit and push `main`.
6. Prepare v0.1.2 release notes and release checklist without tagging.

## Validation Sequence

- PowerShell parse checks.
- Python compile checks.
- Raw transcript privacy regression.
- Installer smoke test against a temp vault with `-SkipPathUpdate`.
- Status command smoke test.
- Git diff/status review.

## Risks

- Installer output could imply project memory is modified; messaging must explicitly say it is not deleted or overwritten.
- PATH checks must distinguish updated, skipped, and already present.
- v0.1.2 release docs must not imply the release tag already exists.
