# Architecture

## Components

### 1. Claude Code Hooks

ContextOS uses Claude Code lifecycle hooks:

- `SessionStart`
- `SessionEnd`

These hooks are configured in Claude Code settings and call PowerShell scripts.

On macOS, Claude Code hooks call the Bash equivalents:

- `contextos-start.sh`
- `contextos-capture.sh`

### 2. Memory Vault

Default local vault path:

```text
# macOS / Linux
~/AI-Memory-Vault

# Windows
C:\Users\<User>\AI-Memory-Vault
```

The vault stores project-level memory outside individual repos.

### 3. SessionStart Flow

```text
Claude Code opens
-> contextos-start.ps1 runs
-> current working directory is detected
-> project memory folder is created if missing
-> PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, and graph.mmd are created if missing
-> PROJECT_INDEX.md is refreshed at the vault root
-> compact memory is injected into Claude Code
```

By default, SessionStart injects current project memory plus a compact summary from `PROJECT_INDEX.md`. Set `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false` to disable the cross-project section for a sensitive session.

### 4. SessionEnd Flow

```text
Claude Code exits
-> contextos-capture.ps1 receives hook JSON
-> session metadata and transcript path are captured
-> process-session.py processes transcript
-> decision/action extraction runs
-> project files are updated
-> PROJECT_INDEX.md is refreshed
-> compression runs if SESSION_LOG.md exceeds threshold
```

SessionEnd is the primary freshness path for `PROJECT_INDEX.md`. It keeps the vault-level index current after every completed session while the processor is already updating project memory.

### 5. Search, Index, And Resume

| Command | Windows | macOS / Linux |
|---------|---------|---------------|
| Search memory | `contextos-find.ps1` | `contextos-find.sh` |
| Refresh index | `contextos-projects.ps1` | `contextos-projects.sh` |
| Resume pack | `contextos-resume.ps1` | `contextos-resume.sh` |
| Open folder | `contextos-open.ps1` | `contextos-open.sh` |
| Health check | `contextos-doctor.ps1` | `contextos-doctor.sh` |
| Status | `contextos-status.ps1` | `contextos-status.sh` |

### 6. Shared Index Module

`contextos_index.py` contains the shared signal filtering, noise detection, and index generation logic used by both `process-session.py` and the `contextos-projects` scripts. This prevents drift between the two code paths.

## Design Principle

ContextOS is not a raw transcript dump.

It separates:

- raw history for audit
- distilled memory for reuse
- decisions for continuity
- next actions for execution
- project index for explicit cross-project recall
- resume packs for cross-tool context transfer
