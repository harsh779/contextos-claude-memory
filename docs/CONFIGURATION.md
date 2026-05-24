# Configuration



ContextOS is designed to work with sensible defaults, but most paths and behavior can be configured.



## Vault Path



ContextOS stores memory in a local vault.



Default path:



```txt

%USERPROFILE%\\AI-Memory-Vault
```

macOS default path:

```text
~/AI-Memory-Vault
```

## Raw Transcript Copying

ContextOS is privacy-first by default. It does not copy raw Claude Code transcript files into the memory vault unless explicitly enabled.

To enable duplicate raw transcript copies:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

macOS:

```bash
export CONTEXTOS_COPY_RAW_TRANSCRIPTS=true
```

Only the exact value `true` enables copying. Any other value, including an unset variable, disables it.

When enabled, `contextos-capture.ps1` copies the original transcript into:

```text
projects/<project-name>/raw/<timestamp>-transcript.jsonl
```

When disabled, ContextOS still reads the original `transcript_path` from Claude Code event metadata so `PROJECT_CONTEXT.md`, `SESSION_LOG.md`, `DECISIONS.md`, `NEXT_ACTIONS.md`, `TOKEN_SAVINGS.md`, and `graph.mmd` continue to update.

## Cross-Project Memory

ContextOS creates project memory per folder by default. It can also maintain a vault-level project index:

```text
PROJECT_INDEX.md
```

Refresh and view it with:

```powershell
contextos-projects
```

Freshness model:

- SessionEnd rebuilds `PROJECT_INDEX.md` after each completed Claude Code session.
- SessionStart refreshes it before returning startup context.
- `contextos-projects` refreshes it manually when you want to inspect it.

Claude startup injection includes compact cross-project memory by default.

To disable it for a sensitive session:

```powershell
$env:CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY = "false"
```

macOS:

```bash
export CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false
```

Only the exact lowercase value `false` disables cross-project startup injection. Any other value, including unset, keeps it enabled.

When enabled, ContextOS injects a compact summary of `PROJECT_INDEX.md` during SessionStart. The index is generated from summary memory files and excludes raw transcripts, raw copies, and full session logs.

## Token Savings Configuration

ContextOS estimates token savings to show the value of avoided repeated context-setting.

### Token estimate method

ContextOS uses a simple approximation:

```text
1 token ≈ 4 characters of English text
```

This is not an exact model-provider token count. It is a practical estimate for understanding how much repeated project explanation ContextOS helps avoid.

### TOKEN_SAVINGS.md

After session processing, ContextOS creates or updates:

```text
projects/<project-name>/TOKEN_SAVINGS.md
```

This file includes:

- sessions captured
- estimated current memory context tokens
- estimated repeated context avoided
- last updated timestamp
- calculation method

### Estimated repeated context avoided

ContextOS calculates:

```text
estimated current memory context tokens × resumed session count
```

Where:

```text
resumed session count = sessions captured - 1
```

Example:

```text
Estimated current memory context tokens: 1,075
Sessions captured: 3
Estimated repeated context avoided: 2,150 tokens
```

### Status command

`contextos-status` reads token savings files across projects and shows:

```text
Token savings files:      1
Estimated tokens avoided: 2150
Raw transcript copying:   Disabled
Cross-project memory:     Enabled
Project index exists:     Yes
```

### Resume pack token estimate

`contextos-resume` shows the estimated token size of the generated restart pack.

Example:

```text
Resume pack characters: 4,800
Estimated tokens: 1,200
Estimated re-explanation avoided per resumed session: ~1,200 tokens
```

### Tuning the estimate

The token estimate is currently hardcoded as:

```text
characters / 4
```

To change this, edit:

```text
scripts/process-session.py
scripts/contextos-resume.ps1
```

Look for token-estimation logic in those files.

### Related settings

Compression threshold is controlled in:

```text
scripts/process-session.py
```

Look for:

```text
--threshold
30000
```

Injected context size is controlled in:

```text
scripts/contextos-start.ps1
```

Current defaults:

```text
Per-file injected context limit: 2500 characters
Total injected context limit: 9000 characters
```
