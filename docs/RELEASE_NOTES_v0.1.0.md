\# ContextOS v0.1.0 — Local Claude Code Memory MVP



\## Summary



ContextOS v0.1.0 is the first working release of a Windows-first local memory layer for Claude Code.



It helps reduce repeated context-setting across AI coding sessions by creating a local project memory vault, injecting useful context at session start, capturing session progress at exit, extracting decisions and next actions, and generating restart packs.



\## What ContextOS Solves



AI coding sessions often lose efficiency because users need to repeatedly explain:



\- what the project is

\- what has already been decided

\- what is pending

\- what failed

\- what files matter

\- what the next action is



ContextOS keeps this information locally so future sessions can resume faster.



\## Included in v0.1.0



\### Local Memory Vault



ContextOS creates a local memory vault at:



```text

%USERPROFILE%\\AI-Memory-Vault

```



Users can override this with:



```text

CONTEXTOS\_VAULT\_PATH

```



\### Project Memory Files



Each project gets:



```text

PROJECT\_CONTEXT.md

DECISIONS.md

NEXT\_ACTIONS.md

SESSION\_LOG.md

graph.mmd

TOKEN\_SAVINGS.md

```



\### Claude Code Hooks



ContextOS supports:



```text

SessionStart

SessionEnd

```



SessionStart loads project memory into Claude Code.



SessionEnd captures session progress and updates project memory.



\### Search Command



```powershell

contextos-find "github remote"

```



Searches across project memory.



\### Resume Pack Command



```powershell

contextos-resume <project-name>

```



Creates a compact restart pack and copies it to clipboard.



\### Open Project Memory



```powershell

contextos-open <project-name>

```



Opens a project memory folder in Windows Explorer.



\### Status Command



```powershell

contextos-status

```



Shows whether ContextOS is installed and working.



Example:



```text

Vault exists:                    Yes

Required scripts installed:      Yes

Hooks configured:                Yes

SessionStart hook:               Yes

SessionEnd hook:                 Yes

Projects tracked:                6

Token savings files:             1

Estimated tokens avoided:        2150

```



\### Token Savings Estimate



ContextOS estimates token savings using:



```text

1 token ≈ 4 characters of English text

```



This is not an exact provider-level token count. It is a practical directional estimate showing repeated context avoided.



\## Installation



Run:



```powershell

powershell -NoProfile -ExecutionPolicy Bypass -File .\\install.ps1

```



Optional custom vault:



```powershell

powershell -NoProfile -ExecutionPolicy Bypass -File .\\install.ps1 -VaultPath "D:\\ContextOS"

```



Then add the printed Claude Code settings snippet to:



```text

%USERPROFILE%\\.claude\\settings.json

```



\## Validation



Run:



```powershell

contextos-status

```



Expected:



```text

Vault exists: Yes

Required scripts installed: Yes

Hooks configured: Yes

SessionStart hook: Yes

SessionEnd hook: Yes

```



\## Known Limitations



\- Windows-first implementation.

\- Token savings are estimated, not exact.

\- Claude Code settings must still be updated manually.

\- Raw transcript copy is enabled by default if transcript path is available.

\- No UI yet.

\- No semantic/vector search yet.

\- No cross-device sync yet.



\## Privacy



ContextOS is local-first.



Do not commit:



\- real project memory

\- raw transcripts

\- session logs from private work

\- context packs

\- Claude settings

\- API keys

\- client data



See:



```text

docs/PRIVACY\_AND\_SECURITY.md

```



\## Next Roadmap



Planned future improvements:



\- better installer automation

\- optional raw transcript copy toggle

\- SQLite index

\- semantic search

\- local UI

\- cross-tool inbox capture for Claude Chat / CoWork

\- richer token analytics

\- GitHub release packaging

