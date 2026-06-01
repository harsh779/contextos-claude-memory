# ContextOS

<!-- Uncomment when published:
[![PyPI version](https://img.shields.io/pypi/v/contextos-claude-memory)](https://pypi.org/project/contextos-claude-memory/)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue)](https://python.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
-->

**Local memory layer for Claude Code.** Session continuity, decision tracking, and cross-project recall — entirely on your machine.

---

## The Problem

- Claude Code forgets everything between sessions. You re-explain project goals, decisions, and state every time.
- Long-running builds lose momentum. Context that took 20 minutes to establish vanishes when you close the terminal.
- There's no structured way to resume where you left off across projects.

## The Solution

ContextOS hooks into Claude Code's session lifecycle. It captures decisions, next actions, and project state on session end, then injects that memory back on session start. No cloud, no API keys, no config files to maintain — just `pip install` and go.

---

## Install

```bash
pip install contextos-claude-memory[tiktoken]
contextos doctor
```

That's it. `doctor` validates the install, checks your Claude Code hooks, and reports any issues.

> **Windows:** Same commands work in PowerShell. Python 3.10+ required on all platforms.

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│                  Claude Code                     │
│                                                  │
│  SessionStart hook          SessionEnd hook       │
│       │                          │                │
│       ▼                          ▼                │
│  ┌──────────┐             ┌───────────┐          │
│  │  Inject  │             │  Capture  │          │
│  │  memory  │             │  progress │          │
│  └────┬─────┘             └─────┬─────┘          │
│       │                         │                 │
└───────┼─────────────────────────┼─────────────────┘
        │                         │
        ▼                         ▼
┌─────────────────────────────────────────────────┐
│              ~/.contextos/vault/                 │
│                                                  │
│  PROJECT_INDEX.md      projects/                 │
│                          └─ my-app/              │
│                              ├─ PROJECT_CONTEXT  │
│                              ├─ DECISIONS        │
│                              ├─ NEXT_ACTIONS     │
│                              ├─ SESSION_LOG      │
│                              └─ graph.mmd        │
└─────────────────────────────────────────────────┘
```

---

## Features

| Feature | Description |
|---|---|
| Auto-bootstrap | Detects new projects, creates memory structure on first session |
| Session injection | Loads project memory into Claude Code at session start |
| Session capture | Extracts decisions, next actions, and progress at session end |
| Restart packs | Generates compact context packs for resuming work |
| Cross-project index | Maintains a vault-level summary so Claude sees related projects |
| Memory search | Full-text search across all project memory |
| Token savings | Estimates repeated context avoided across sessions |
| Doctor diagnostics | Validates install, hooks, vault health, and privacy state |
| Garbage collection | Cleans stale sessions and archives old data |
| Schema migrations | Upgrades vault structure across ContextOS versions |
| Privacy-first | Local-only. No cloud. Raw transcript copying off by default |

---

## Commands

| Command | What it does |
|---|---|
| `contextos doctor` | Validate install, hooks, vault health |
| `contextos-status` | Show vault state, hook status, token savings |
| `contextos-status --version` | Print installed version |
| `contextos-projects` | Rebuild and display the cross-project index |
| `contextos-find "query"` | Search across all project memory |
| `contextos-resume <project>` | Generate a restart pack (copies to clipboard) |
| `contextos-open <project>` | Open a project's memory folder in Finder/Explorer |
| `contextos-gc` | Clean stale sessions and archives |
| `contextos-diff` | Show what changed since last session |
| `contextos-migrate` | Run vault schema migrations |

---

## Before / After

**Without ContextOS** — every session starts cold:

```
You: Build the auth module for my Flask app
Claude: What framework are you using? What's the project structure?
        What auth approach did you decide on? Where did you leave off?
You: [spends 5 minutes re-explaining context from yesterday]
```

**With ContextOS** — Claude already knows:

```
ContextOS active: loaded memory for my-flask-app

You: Build the auth module
Claude: Continuing from yesterday — you chose JWT with refresh tokens,
        the User model is in models/user.py, and the /login endpoint
        skeleton is ready. I'll implement the token generation next.
```

---

## What Gets Created

```
~/.contextos/vault/
├── PROJECT_INDEX.md              # cross-project summary
├── context-packs/                # generated restart packs
└── projects/
    └── <project-name>/
        ├── PROJECT_CONTEXT.md    # project goals, stack, structure
        ├── DECISIONS.md          # extracted technical decisions
        ├── NEXT_ACTIONS.md       # follow-up work items
        ├── SESSION_LOG.md        # compressed session history
        ├── TOKEN_SAVINGS.md      # token reuse estimates
        ├── graph.mmd             # project dependency graph
        ├── sessions/             # individual session snapshots
        └── archives/             # rotated old sessions
```

---

## Configuration

All configuration is via environment variables. No config files to manage.

| Variable | Default | Purpose |
|---|---|---|
| `CONTEXTOS_VAULT_PATH` | `~/.contextos/vault` | Custom vault location |
| `CONTEXTOS_COPY_RAW_TRANSCRIPTS` | `false` | Enable raw transcript archiving |
| `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY` | `true` | Include project index in session injection |

```bash
# Example: custom vault location
export CONTEXTOS_VAULT_PATH="$HOME/my-vault"

# Example: disable cross-project memory for a sensitive session
CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false claude
```

---

## Privacy

- **Local-only.** All data stays on your machine. No cloud, no telemetry, no API calls.
- **Raw transcripts off by default.** ContextOS reads Claude's transcript to extract summaries but does not copy the raw file unless you opt in.
- **Never commit your vault.** The vault contains project-specific memory. Add `~/.contextos/` to your global gitignore.

---

## Documentation

| Doc | Contents |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | System design, hook lifecycle, data flow |
| [Configuration](docs/CONFIGURATION.md) | All env vars and settings |
| [Usage](docs/USAGE.md) | Detailed command reference |
| [macOS Setup](docs/SETUP_MACOS.md) | macOS-specific install notes |
| [Windows Setup](docs/SETUP_WINDOWS.md) | Windows-specific install notes |
| [Doctor](docs/DOCTOR.md) | Diagnostic checks and remediation |
| [Cross-project Memory](docs/CROSS_PROJECT_MEMORY.md) | How the project index works |
| [Privacy & Security](docs/PRIVACY_AND_SECURITY.md) | Data handling and privacy model |
| [Upgrade](docs/UPGRADE.md) | Version upgrade procedures |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and fixes |

---

## Contributing

```bash
git clone https://github.com/harsh779/contextos-claude-memory.git
cd contextos-claude-memory
pip install -e ".[tiktoken]"
contextos doctor
```

PRs welcome. Keep it simple — ContextOS is a local tool, not a platform.

---

## License

MIT. See [LICENSE](LICENSE).

Built by [Harsh Khandelwal](https://github.com/harsh779).
