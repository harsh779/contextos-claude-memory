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

`contextos-find.ps1` searches project memory files.

`contextos-projects.ps1` refreshes and prints the vault-level project index.

`contextos-resume.ps1` creates a compact restart pack and copies it to clipboard.

`contextos-open.ps1` opens a project memory folder in Explorer.

## Design Principle

ContextOS is not a raw transcript dump.

It separates:

- raw history for audit
- distilled memory for reuse
- decisions for continuity
- next actions for execution
- project index for explicit cross-project recall
- resume packs for cross-tool context transfer
