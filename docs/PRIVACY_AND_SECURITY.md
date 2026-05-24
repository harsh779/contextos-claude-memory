# Privacy and Security

ContextOS is designed as a local-first memory system.

It stores project memory on your machine, not in a cloud database.

ContextOS injects current project memory plus a compact vault-level `PROJECT_INDEX.md` summary by default. Set `CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false` to disable cross-project startup injection for a sensitive session.

## What ContextOS Stores

By default, ContextOS may store:

- Project context
- Session summaries
- Decisions
- Next actions
- Basic project graph
- Session metadata

Raw Claude Code transcript copies are not stored by default.

Default vault path:

```text
%USERPROFILE%\AI-Memory-Vault
```

Custom vault path:

```text
CONTEXTOS_VAULT_PATH
```

## Sensitive Files

Do not commit these folders or files to Git:

```text
AI-Memory-Vault/projects/
AI-Memory-Vault/raw/
AI-Memory-Vault/sessions/
AI-Memory-Vault/archives/
AI-Memory-Vault/context-packs/
AI-Memory-Vault/debug/
AI-Memory-Vault/inbox/
*.jsonl
.env
*.secret
*.token
settings.json
settings.local.json
```

## Raw Transcript Handling

`contextos-capture.ps1` reads the original Claude Code `transcript_path` from event metadata so it can create summaries, decisions, next actions, `SESSION_LOG.md`, `TOKEN_SAVINGS.md`, and `graph.mmd`.

By default, it does not duplicate raw transcript files into the vault.

To opt in to raw transcript copying for audit or recovery, set:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Only the exact value `true` enables copying. When enabled, transcript files are copied into:

```text
projects/<project-name>/raw/
```

The copied file path is:

```text
projects/<project-name>/raw/<timestamp>-transcript.jsonl
```

Raw transcripts can include sensitive information from your session. Keep copying disabled unless you have a specific need to retain them.

## Context Packs

`contextos-resume` creates restart packs in:

```text
context-packs/
```

These packs are designed to be pasted into another assistant or coding session.

Review them before sharing externally.

## GitHub Safety

This repository should include:

- reusable scripts
- docs
- sample project files
- templates

This repository should not include:

- real project memories
- client data
- raw transcripts
- API keys
- personal Claude settings
- private context packs

## Claude Code Settings

Your Claude Code settings may contain:

- hook commands
- local paths
- allowed commands
- project permissions

Do not publish your real Claude Code settings file:

```text
%USERPROFILE%\.claude\settings.json
```

Use this public-safe template instead:

```text
docs/settings.example.json
```

## Recommended Practice

Before pushing changes:

```powershell
git status
```

Check that no private vault folder is staged:

```powershell
git diff --cached --name-only
```

If private files are staged, unstage them:

```powershell
git restore --staged <file-or-folder>
```

## Deleting Local Memory

Use:

```powershell
.\uninstall.ps1
```

This removes environment and PATH setup but keeps your memory vault.

To delete the vault:

```powershell
.\uninstall.ps1 -DeleteVault
```

This requires confirmation.

To force deletion without confirmation:

```powershell
.\uninstall.ps1 -DeleteVault -Force
```

Use force deletion carefully.
