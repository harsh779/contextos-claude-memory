# Cross-Project Memory

ContextOS is per-project by default. When Claude Code starts in a folder, ContextOS loads memory for that project only.

Cross-project awareness adds a vault-level index so you can see related work across projects without injecting every project into every session.

## What It Creates

ContextOS maintains:

```text
AI-Memory-Vault/
  PROJECT_INDEX.md
```

The index is generated from summary memory files:

- `PROJECT_CONTEXT.md`
- `DECISIONS.md`
- `NEXT_ACTIONS.md`
- `graph.mmd`

It does not include raw transcripts or full session logs.

## Refresh The Index

`PROJECT_INDEX.md` stays fresh automatically:

- SessionEnd rebuilds it after ContextOS processes a completed Claude Code session.
- SessionStart refreshes it before startup memory is returned.
- `contextos-projects` refreshes it on demand and prints the result.

The primary freshness path is SessionEnd. That keeps the index current with minimal overhead because ContextOS is already processing session memory at that point.

Run:

```bash
contextos-projects
```

This manually refreshes `PROJECT_INDEX.md` and prints it to the terminal.

Direct script fallback from the repo:

```bash
# macOS / Linux
bash ./scripts/contextos-projects.sh
```

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-projects.ps1
```

## Startup Injection

Default behavior includes compact cross-project startup context:

```text
Cross-project memory: Enabled
```

To disable compact cross-project startup context for a sensitive session:

```bash
# macOS / Linux
export CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false
```

```powershell
# Windows
$env:CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY = "false"
```

Only the exact lowercase value `false` disables cross-project startup injection. Any other value, including unset, keeps it enabled.

When enabled, Claude receives a compact `PROJECT_INDEX.md` summary during SessionStart. It should use that summary only to identify possibly related prior work and should not assume unrelated project details apply without user confirmation.

## Recommended Workflow

1. Keep the default enabled behavior for normal development sessions.
2. Use `contextos-projects` or `contextos-find` when you need to inspect prior work directly.
3. Set `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false` only for sessions where cross-project summaries should not be injected.
4. Run `contextos-doctor` after upgrade to confirm the command wrapper is installed.

## Privacy Notes

Cross-project awareness is summary-only. It does not change the raw transcript privacy toggle.

Raw transcript copying remains disabled unless:

```bash
# macOS / Linux
export CONTEXTOS_COPY_RAW_TRANSCRIPTS=true
```

```powershell
# Windows
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Keep project names and summaries in mind before using default cross-project startup injection in sensitive client or personal work. Disable it with `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false` when needed.
