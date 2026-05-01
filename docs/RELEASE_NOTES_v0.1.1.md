# ContextOS v0.1.1 - Privacy Hardening

## Summary

ContextOS v0.1.1 hardens raw transcript handling.

Raw Claude Code transcript copying is now disabled by default. ContextOS still reads the original `transcript_path` from Claude Code event metadata to generate project memory, but it does not duplicate raw transcript files into the vault unless the user explicitly opts in.

## What Changed

### Raw Transcript Privacy Toggle

New setting:

```text
CONTEXTOS_COPY_RAW_TRANSCRIPTS
```

Default:

```text
Disabled
```

Enable raw transcript copying only with the exact lowercase value:

```powershell
$env:CONTEXTOS_COPY_RAW_TRANSCRIPTS = "true"
```

Values such as `True`, `TRUE`, `1`, `yes`, or an unset variable keep raw transcript copying disabled.

### Copy Destination When Enabled

When enabled, ContextOS preserves the existing raw transcript copy behavior:

```text
projects/<project-name>/raw/<timestamp>-transcript.jsonl
```

### Memory Generation Still Works When Disabled

When raw transcript copying is disabled, ContextOS still uses Claude Code's original `transcript_path` to update:

- `PROJECT_CONTEXT.md`
- `SESSION_LOG.md`
- `DECISIONS.md`
- `NEXT_ACTIONS.md`
- `TOKEN_SAVINGS.md`
- `graph.mmd`

The toggle only controls duplicate raw transcript copies in the vault `raw/` folder.

### Status Output

`contextos-status` now shows:

```text
Raw transcript copying:          Disabled
```

or:

```text
Raw transcript copying:          Enabled
```

## Upgrade Note

After pulling v0.1.1, rerun the installer so the updated scripts are copied into your active vault:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

If you use a custom vault:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -VaultPath "D:\ContextOS"
```

This updates:

```text
AI-Memory-Vault\scripts\
```

## Validation Checklist

Run syntax checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$null = [scriptblock]::Create((Get-Content .\scripts\contextos-capture.ps1 -Raw)); $null = [scriptblock]::Create((Get-Content .\scripts\contextos-status.ps1 -Raw)); $null = [scriptblock]::Create((Get-Content .\scripts\test-raw-transcript-privacy.ps1 -Raw)); 'PowerShell parse OK'"
```

Run Python compile checks:

```powershell
python -m py_compile .\scripts\process-session.py .\scripts\compress-project-memory.py
```

Run the raw transcript privacy regression check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-raw-transcript-privacy.ps1
```

Expected result:

```text
PASS disabled-unset
PASS disabled-nonexact
PASS enabled-exact
Raw transcript privacy regression checks passed.
```

## Validation Evidence

Validated scenarios:

- `CONTEXTOS_COPY_RAW_TRANSCRIPTS` unset: raw transcript copy disabled.
- `CONTEXTOS_COPY_RAW_TRANSCRIPTS=True`: raw transcript copy disabled.
- `CONTEXTOS_COPY_RAW_TRANSCRIPTS=true`: raw transcript copy enabled.
- Core memory files are generated in all cases.
- Enabled mode copies exactly one raw transcript into `projects/<project-name>/raw/`.
- Disabled mode creates no copied `*.jsonl` transcript under `projects/<project-name>/raw/`.

## Safe Default

The safe default is:

```text
Raw transcript copying: Disabled
```

This protects users from storing duplicate raw transcripts in the ContextOS vault unless they explicitly opt in.

## Files Changed

- `scripts/contextos-capture.ps1`
- `scripts/contextos-status.ps1`
- `scripts/test-raw-transcript-privacy.ps1`
- `README.md`
- `docs/CONFIGURATION.md`
- `docs/PRIVACY_AND_SECURITY.md`
- `docs/USAGE.md`
