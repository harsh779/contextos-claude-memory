# Architecture

## Components

### 1. Claude Code hooks

ContextOS uses Claude Code lifecycle hooks:

- `SessionStart`
- `SessionEnd`

These hooks are configured in Claude Code settings and call PowerShell scripts.

### 2. Memory Vault

Default local vault path:

```txt
C:\Users\<User>\AI-Memory-Vault
```

The vault stores project-level memory outside individual repos.

### 3. SessionStart flow

```txt
Claude Code opens
↓
contextos-start.ps1 runs
↓
current working directory is detected
↓
project memory folder is created if missing
↓
PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, graph.mmd are created if missing
↓
compact memory is injected into Claude Code
```

### 4. SessionEnd flow

```txt
Claude Code exits
↓
contextos-capture.ps1 receives hook JSON
↓
session metadata and transcript path are captured
↓
process-session.py processes transcript
↓
decision/action extraction runs
↓
project files are updated
↓
compression runs if SESSION_LOG.md exceeds threshold
```

### 5. Search and resume

`contextos-find.ps1` searches project memory files.

`contextos-resume.ps1` creates a compact restart pack and copies it to clipboard.

`contextos-open.ps1` opens a project memory folder in Explorer.

## Design principle

ContextOS is not a raw transcript dump.

It separates:

- raw history for audit
- distilled memory for reuse
- decisions for continuity
- next actions for execution
- resume packs for cross-tool context transfer
