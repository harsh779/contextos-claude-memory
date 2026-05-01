# ContextOS for Claude Code

**A Windows-first local memory layer for Claude Code that reduces repeated context-setting across AI coding sessions.**

ContextOS creates a reusable memory vault for each project, captures session progress, extracts decisions and next actions, estimates repeated context avoided, and generates restart packs so long-running AI-assisted builds can continue without re-explaining the same context every time.

---

## 5-Minute Quickstart

### 1. Clone the repo

```powershell
git clone https://github.com/harsh779/contextos-claude-memory.git
cd contextos-claude-memory
```

### 2. Run the installer

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Optional custom vault location:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath "D:\ContextOS"
```

Rerunning `install.ps1` after pulling a new ContextOS version is safe. It updates reusable scripts in your vault and does not delete existing project memory.

### 3. Add hooks to Claude Code

The installer prints a Claude Code settings snippet.

Add or merge that snippet into:

```text
%USERPROFILE%\.claude\settings.json
```

### 4. Test auto-bootstrap

```powershell
mkdir $env:USERPROFILE\Desktop\contextos-auto-test
cd $env:USERPROFILE\Desktop\contextos-auto-test
claude
```

Ask Claude Code:

```text
What ContextOS memory did you receive?
```

Expected result: Claude should mention auto-created memory files like `PROJECT_CONTEXT.md`, `DECISIONS.md`, `NEXT_ACTIONS.md`, and `graph.mmd`.

### 5. Test commands

Open a new PowerShell window, then run:

```powershell
contextos-status
contextos-status --version
contextos-doctor
contextos-find "test"
contextos-resume contextos-auto-test
contextos-open contextos-auto-test
```

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
| Status check | Shows whether ContextOS is installed, hooked, and working |
| Version check | Prints the installed ContextOS version |
| Token estimate | Estimates repeated context avoided across resumed sessions |
| Local-first design | Keeps private project memory on the user's machine |

---

## How it works

```text
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

```text
AI-Memory-Vault/
  projects/
    project-name/
      PROJECT_CONTEXT.md
      DECISIONS.md
      NEXT_ACTIONS.md
      SESSION_LOG.md
      TOKEN_SAVINGS.md
      graph.mmd
      raw/        (only when raw transcript copying is enabled)
      sessions/
      archives/
```

---

## Commands

Check whether ContextOS is working:

```powershell
contextos-status
```

Check the installed ContextOS version:

```powershell
contextos-status --version
```

Run install diagnostics:

```powershell
contextos-doctor
```

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

## Demo

### 1. Check whether ContextOS is working

Run:

```powershell
contextos-status
```

Example output:

```text
ContextOS Status
================

Version:                         v0.1.3
Vault path:                      C:\Users\<User>\AI-Memory-Vault
Vault exists:                    Yes
Scripts folder exists:           Yes
Required scripts installed:      Yes
Projects tracked:                6
Context packs created:           5
Token savings files:             1
Estimated tokens avoided:        2150
Raw transcript copying:          Disabled
Doctor command available:        Yes
Claude settings found:           Yes
Hooks configured:                Yes
SessionStart hook:               Yes
SessionEnd hook:                 Yes
Last captured project:           contextos-auto-test
Last capture time:               2026-05-01 16:43:36
```

Key checks:

- `Version` shows the installed ContextOS version.
- `Vault exists: Yes` means the memory vault is present.
- `Required scripts installed: Yes` means ContextOS scripts are installed.
- `Hooks configured: Yes` means Claude Code settings include ContextOS hooks.
- `SessionStart hook: Yes` means memory injection is configured.
- `SessionEnd hook: Yes` means session capture is configured.
- `Token savings files` means ContextOS has started tracking token-savings estimates.
- `Estimated tokens avoided` is the estimated repeated context avoided across tracked sessions.
- `Raw transcript copying: Disabled` means ContextOS will process Claude's original transcript path but will not duplicate raw transcript files into the vault.
- `Doctor command available: Yes` means the diagnostic command wrapper is installed in the vault.

Version-only check:

```powershell
contextos-status --version
```

Expected output:

```text
ContextOS v0.1.3
```

### 2. Generate a restart pack

Run:

```powershell
contextos-resume resume-customiser-repo
```

Example output:

```text
ContextOS resume pack created:
C:\Users\<User>\AI-Memory-Vault\context-packs\resume-customiser-repo-context-pack-2026-05-01_16-55-00.md

Copied to clipboard.

Token estimate:
---------------
Resume pack characters: 4,800
Estimated tokens: 1,200
Estimated re-explanation avoided per resumed session: ~1,200 tokens
```

### 3. Confirm Claude receives project memory

When Claude Code starts inside a tracked project, ContextOS injects a visible startup line:

```text
ContextOS active: loaded memory for resume-customiser-repo from C:\Users\<User>\AI-Memory-Vault\projects\resume-customiser-repo
```

That line confirms Claude received local project memory before the session begins.

---

## Token savings estimate

ContextOS estimates token savings using a simple approximation:

```text
1 token ≈ 4 characters of English text
```

The estimate is not an exact model-provider token count. It is a practical directional metric that shows how much repeated project explanation ContextOS helps avoid.

Example:

```text
Estimated current memory context tokens: 1,075
Sessions captured: 3
Estimated repeated context avoided: 2,150 tokens
```

This means ContextOS likely helped avoid re-explaining around 2,150 tokens of project context across resumed sessions.

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
- status command
- version command
- token-savings estimate

---

## Portfolio relevance

This project shows how AI workflows can be operationalised beyond one-off prompting. The goal is not just to use AI tools, but to build a repeatable system that improves continuity, reduces wasted tokens, and makes long-running product builds easier to resume.

---

## Privacy note

Do not commit actual memory vault data.

This repository should contain only reusable scripts, templates, docs, and examples.

Raw Claude Code transcript copying is disabled by default. ContextOS still reads the original `transcript_path` from Claude Code event metadata to create summaries, decisions, next actions, `SESSION_LOG.md`, and `TOKEN_SAVINGS.md`. To opt in to keeping duplicate raw transcript files under `projects/<project-name>/raw/`, set:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

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
- [Upgrade guide](docs/UPGRADE.md)
- [Doctor diagnostics](docs/DOCTOR.md)
- [Configuration](docs/CONFIGURATION.md)
- [Privacy and security](docs/PRIVACY_AND_SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Roadmap](docs/ROADMAP.md)
- [v0.1.3 release notes](docs/RELEASE_NOTES_v0.1.3.md)
- [v0.1.3 release checklist](docs/RELEASE_CHECKLIST_v0.1.3.md)
- [v0.1.2 release notes](docs/RELEASE_NOTES_v0.1.2.md)
- [v0.1.2 release checklist](docs/RELEASE_CHECKLIST_v0.1.2.md)
- [v0.1.1 release notes](docs/RELEASE_NOTES_v0.1.1.md)
- [v0.1.0 release notes](docs/RELEASE_NOTES_v0.1.0.md)

---

## Release

Latest release notes:

[ContextOS v0.1.3 - Doctor Command and Self-Healing Diagnostics](docs/RELEASE_NOTES_v0.1.3.md)

---

## Upgrade

After pulling a new ContextOS version, rerun the installer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Then validate:

```powershell
contextos-status
contextos-doctor
```

See [Upgrade guide](docs/UPGRADE.md) for custom vaults and troubleshooting.

---

## Author

Built by [Harsh Khandelwal](https://github.com/harsh779) as part of a broader AI-assisted product-building and workflow automation stack.
