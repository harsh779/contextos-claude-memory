# ContextOS for Claude Code

**A Windows-first local memory layer for Claude Code that reduces repeated context-setting across AI coding sessions.**

ContextOS creates a reusable memory vault for each project, captures session progress, extracts decisions and next actions, and generates restart packs so long-running AI-assisted builds can continue without re-explaining the same context every time.

---

## Why this exists

AI coding sessions often lose efficiency because the user has to repeatedly explain:

- project goal
- repo state
- prior decisions
- current blockers
- next actions
- files touched
- commands already tested

ContextOS solves this by keeping a local, project-level memory system outside the AI chat window.

---

## What it does

| Capability | What it means |
|---|---|
| Project memory vault | Creates structured memory files for each local project |
| Session start context | Injects relevant project memory when Claude Code starts |
| Session end capture | Saves session progress when work ends |
| Decision extraction | Pulls key decisions into `DECISIONS.md` |
| Next-action extraction | Pulls follow-up work into `NEXT_ACTIONS.md` |
| Restart packs | Generates compact context packs for future AI sessions |
| Search | Lets you search across prior project memory |
| Local-first design | Keeps private project memory on the user's machine |

---

## How it works

```txt
Open Claude Code inside any project folder
↓
ContextOS detects the current project
↓
Creates or loads project memory
↓
Injects relevant memory at session start
↓
User works normally in Claude Code
↓
Session ends
↓
ContextOS captures progress, decisions, and next actions
↓
Future sessions can restart from a compact context pack
```

---

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

---

## Commands

Search memory:

```powershell
contextos-find "github remote"
```

Create a restart pack:

```powershell
contextos-resume resume-customiser-repo
```

Open a project memory folder:

```powershell
contextos-open resume-customiser-repo
```

---

## Current status

Working MVP:

- global auto-bootstrap
- session-start context injection
- session-end capture
- decision extraction
- next-action extraction
- log compression
- memory search
- restart pack generation

---

## Portfolio relevance

This project shows how AI workflows can be operationalised beyond one-off prompting. The goal is not just to use AI tools, but to build a repeatable system that improves continuity, reduces wasted tokens, and makes long-running product builds easier to resume.

---

## Privacy note

Do not commit actual memory vault data.

This repository should contain only reusable scripts, templates, docs, and examples.

Private files to avoid committing:

- raw transcripts
- session logs from real projects
- context packs from private work
- API keys
- personal Claude settings
- project-specific client data

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Windows setup](docs/SETUP_WINDOWS.md)
- [Usage](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Roadmap](docs/ROADMAP.md)

---

## Author

Built by [Harsh Khandelwal](https://github.com/harsh779) as part of a broader AI-assisted product-building and workflow automation stack.
