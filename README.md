# ContextOS for Claude Code

ContextOS is a Windows-first local memory layer for Claude Code.

It auto-creates project memory, injects context at session start, captures session context at exit, extracts decisions and next actions, compresses long logs, and lets you search or resume old work without re-explaining everything.

## Why this exists

Claude Code sessions can become expensive and repetitive because users often need to re-explain:

- project goal
- prior decisions
- current blockers
- next actions
- repo state
- files touched
- commands used

ContextOS solves this by maintaining a local memory vault outside Claude.

## Core behavior

```txt
Open Claude Code in any folder
↓
ContextOS detects current working directory
↓
Auto-creates project memory if missing
↓
Injects relevant memory into Claude Code
↓
Session ends
↓
ContextOS captures transcript metadata
↓
Updates SESSION_LOG.md
↓
Extracts decisions into DECISIONS.md
↓
Extracts actions into NEXT_ACTIONS.md
↓
Updates PROJECT_CONTEXT.md
↓
Compresses logs when they grow too large
```

## Features

- Global Claude Code hooks
- Zero per-project setup
- Auto-bootstrap for new projects
- SessionStart memory injection
- SessionEnd session capture
- Decision extraction
- Next-action extraction
- Log compression
- Global search command: `contextos-find`
- Restart brief generator: `contextos-resume`
- Project memory opener: `contextos-open`
- Privacy-safe local-first design

## What gets created per project

```txt
AI-Memory-Vault/
  projects/
    project-name/
      PROJECT_CONTEXT.md
      DECISIONS.md
      NEXT_ACTIONS.md
      SESSION_LOG.md
      graph.mmd
      raw/
      sessions/
      archives/
```

## Commands

Search memory:

```powershell
contextos-find "github remote"
```

Create restart pack:

```powershell
contextos-resume resume-customiser-repo
```

Open memory folder:

```powershell
contextos-open resume-customiser-repo
```

## Current status

MVP working:

- global auto-bootstrap works
- session-start context injection works
- session-end capture works
- clean decision extraction works
- clean next-action extraction works
- compression works
- search works
- resume pack generation works

## Privacy note

Do not commit your actual memory vault data.

This repository should contain only reusable scripts, templates, docs, and examples.

Private files to avoid committing:

- raw transcripts
- session logs from real projects
- context packs from private work
- API keys
- personal Claude settings
- project-specific client data

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Windows setup](docs/SETUP_WINDOWS.md)
- [Usage](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Roadmap](docs/ROADMAP.md)
