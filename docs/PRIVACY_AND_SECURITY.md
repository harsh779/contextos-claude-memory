# Privacy and Security

ContextOS is designed as a local-first memory system.

It stores project memory on your machine, not in a cloud database.

## What ContextOS Stores

By default, ContextOS may store:

- Project context
- Session summaries
- Decisions
- Next actions
- Basic project graph
- Session metadata
- Raw Claude Code transcript copy, if available

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

`contextos-capture.ps1` may copy Claude Code transcript files into:

```text
projects/<project-name>/raw/
```

This is useful for audit and recovery, but it can include sensitive information from your session.

To disable raw transcript copy, edit:

```text
scripts/contextos-capture.ps1
```

Remove or comment this block:

```powershell
if ($transcriptPath -and (Test-Path $transcriptPath)) {
    $rawCopyPath = Join-Path $rawDir "$timestamp-transcript.jsonl"
    Copy-Item $transcriptPath $rawCopyPath -Force
}
```

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