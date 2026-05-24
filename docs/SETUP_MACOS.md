# macOS Setup

ContextOS supports macOS with Bash command scripts and the same Python session processor used by Windows.

Status: `v0.1.5-dev`.

## Requirements

- macOS terminal
- Bash
- Python 3
- Claude Code

Check Python:

```bash
python3 --version
```

## Install

From the repo root:

```bash
bash ./install-macos.sh
```

Optional custom vault:

```bash
bash ./install-macos.sh --vault "$HOME/ContextOS"
```

The default vault is:

```text
~/AI-Memory-Vault
```

The installer is safe to rerun after pulling updates. It refreshes reusable scripts and command wrappers without deleting project memory.

## Add Claude Code Hooks

The installer prints a Claude Code settings snippet.

Merge it into:

```text
~/.claude/settings.json
```

The hook commands use:

```bash
bash "$HOME/AI-Memory-Vault/scripts/contextos-start.sh"
bash "$HOME/AI-Memory-Vault/scripts/contextos-capture.sh"
```

Use your custom vault path if you installed somewhere else.

## Commands

After install, restart your terminal or run:

```bash
source ~/.zshrc
```

Then run:

```bash
contextos-status
contextos-doctor
contextos-projects
contextos-find "github remote"
contextos-resume <project-name>
contextos-open <project-name>
```

## Privacy Defaults

Raw transcript copying is disabled by default.

Enable duplicate raw transcript copies only with:

```bash
export CONTEXTOS_COPY_RAW_TRANSCRIPTS=true
```

Cross-project memory is enabled by default. Disable it for a sensitive session with:

```bash
export CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false
```

## Validate

Run:

```bash
contextos-status
contextos-doctor
contextos-projects
```

Expected:

```text
Required scripts installed:      Yes
Cross-project memory:            Enabled
Project index exists:            Yes
Projects command available:      Yes
```

## Notes

- `contextos-resume` copies to clipboard with `pbcopy` when available.
- `contextos-open` uses macOS `open` when available.
- If commands are not found, restart the terminal or confirm `~/AI-Memory-Vault` is on `PATH`.
