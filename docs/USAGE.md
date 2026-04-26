# Usage

## Start Claude Code normally

```powershell
cd C:\path\to\your\project
claude
```

ContextOS runs automatically.

## Search old memory

```powershell
contextos-find "github remote"
contextos-find "resume customiser"
contextos-find "ATS compliance"
```

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
