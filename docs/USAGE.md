# Usage

## Start Claude Code normally

Windows:

```powershell
cd C:\path\to\your\project
claude
```

macOS:

```bash
cd /path/to/your/project
claude
```

ContextOS runs automatically.

## Search old memory

```powershell
contextos-find "github remote"
contextos-find "resume customiser"
contextos-find "ATS compliance"
```

## View tracked projects

```powershell
contextos-projects
```

This refreshes and prints the vault-level `PROJECT_INDEX.md` summary. Use it when you want to see what ContextOS knows across projects without injecting cross-project memory into Claude startup context.

The index is rebuilt automatically after each SessionEnd capture. The command is for manual inspection or an immediate refresh.

## Create restart pack

```powershell
contextos-resume resume-customiser-repo
```

This creates a markdown context pack and copies it to clipboard.

Use it in Claude, ChatGPT, Codex, or any other assistant.

## Open project memory

```powershell
contextos-open resume-customiser-repo
```

## Recommended restart prompt

```txt
Use this ContextOS resume pack. Continue from Next Actions. Do not ask me to re-explain the project.
```

## What not to do

Do not ask Claude to manually edit ContextOS memory files during a live session.

Correct behaviour:

```txt
During session: Claude reads memory only
After exit: SessionEnd hook updates memory
```

## Memory file roles

### PROJECT_CONTEXT.md

Compressed truth file for the project.

### DECISIONS.md

Locked decisions, constraints, scope exclusions.

### NEXT_ACTIONS.md

Execution backlog.

### SESSION_LOG.md

Recent session capsules.

### graph.mmd

Text-based project map.

## Checking ContextOS Status

Run:

```powershell
contextos-status
```

On macOS, the command name is the same after running `install-macos.sh`.

This shows whether ContextOS is installed and working. Run it after install or upgrade.

Example:

```text
ContextOS Status
================

Vault path:                      C:\Users\<User>\AI-Memory-Vault
Vault exists:                    Yes
Scripts folder exists:           Yes
Required scripts installed:      Yes
Projects tracked:                6
Context packs created:           5
Token savings files:             1
Estimated tokens avoided:        2150
Raw transcript copying:          Disabled
Cross-project memory:            Enabled
Project index exists:            Yes
Projects command available:      Yes
Claude settings found:           Yes
Hooks configured:                Yes
SessionStart hook:               Yes
SessionEnd hook:                 Yes
Last captured project:           contextos-auto-test
Last capture time:               2026-05-01 16:43:36
```

How to read this:

- `Vault exists: Yes` means the local memory vault is present.
- `Required scripts installed: Yes` means the ContextOS scripts are installed.
- `Hooks configured: Yes` means Claude Code settings include ContextOS hooks.
- `SessionStart hook: Yes` means ContextOS can inject memory when Claude Code starts.
- `SessionEnd hook: Yes` means ContextOS can capture memory when Claude Code exits.
- `Projects tracked` shows how many project memory folders exist.
- `Context packs created` shows how many restart packs have been generated.
- `Token savings files` shows how many projects have token-savings tracking.
- `Estimated tokens avoided` estimates repeated project context avoided.
- `Raw transcript copying` shows whether ContextOS is duplicating raw Claude Code transcripts into `projects/<project-name>/raw/`. It is disabled unless `CONTEXTOS_COPY_RAW_TRANSCRIPTS` is exactly `true`.
- `Cross-project memory` shows whether SessionStart injects compact summary context from other tracked projects. It is enabled unless `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY` is exactly `false`.
- `Project index exists` shows whether `AI-Memory-Vault\PROJECT_INDEX.md` has been created.
- `Projects command available` shows whether the `contextos-projects` wrapper is installed in the vault.

## Doctor Diagnostics

Run:

```powershell
contextos-doctor
```

This checks the vault, installed scripts, command wrappers, PATH, Python, Claude Code hooks, raw transcript privacy status, and recommended fixes.

Direct fallback from the repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\contextos-doctor.ps1
```

## Cross-Project Memory

ContextOS keeps Claude startup memory scoped to the current project by default.

Compact cross-project startup context is enabled by default.

To disable it for a sensitive session:

```powershell
$env:CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY = "false"
```

Only exact lowercase `false` disables it. Any other value keeps cross-project startup injection enabled.

Use `contextos-projects` or `contextos-find` for manual cross-project recall without enabling startup injection.

## Generating a Resume Pack

Run:

```powershell
contextos-resume <project-name>
```

Example:

```powershell
contextos-resume resume-customiser-repo
```

This creates a restart pack in:

```text
AI-Memory-Vault/context-packs/
```

It also copies the pack to your clipboard.

Use it in Claude, ChatGPT, Codex, or another assistant with this prompt:

```text
Use this ContextOS resume pack. Continue from Next Actions. Do not ask me to re-explain the project.
```

## Token Estimate in Resume Packs

When `contextos-resume` runs, it shows a token estimate.

Example:

```text
Resume pack characters: 4,800
Estimated tokens: 1,200
Estimated re-explanation avoided per resumed session: ~1,200 tokens
```

ContextOS uses this rough method:

```text
1 token ≈ 4 characters of English text
```

This is not an exact model-provider count. It is a practical estimate to show how much repeated explanation ContextOS helps avoid.

## Project Token Savings

After Claude Code sessions are processed, ContextOS creates:

```text
AI-Memory-Vault/projects/<project-name>/TOKEN_SAVINGS.md
```

This file shows:

- sessions captured
- estimated current memory context tokens
- estimated repeated context avoided
- last updated timestamp
- calculation method

Example:

```text
Sessions captured: 3
Estimated current memory context tokens: 1,075
Estimated repeated context avoided: 2,150 tokens
```

This means ContextOS likely helped avoid re-explaining around 2,150 tokens of project context across resumed sessions.

## Regression Checks

Run the raw transcript privacy regression check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-raw-transcript-privacy.ps1
```

This verifies that raw transcript copying is disabled by default, remains disabled for non-exact values like `True`, and is enabled only when `CONTEXTOS_COPY_RAW_TRANSCRIPTS` is exactly `true`.
