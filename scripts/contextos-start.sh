#!/usr/bin/env bash
set -euo pipefail
# Thin wrapper — delegates to Python package if installed, falls back to inline
if python3 -c "import contextos" 2>/dev/null; then
  exec python3 -m contextos start
fi

# Fallback: inline Python for users who haven't pip-installed yet
vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"

input_json="$(cat)"
if [[ -z "${input_json//[[:space:]]/}" ]]; then
  exit 0
fi

tmp_input="$(mktemp)"
printf '%s' "$input_json" > "$tmp_input"

python3 - "$vault" "$tmp_input" <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path
from datetime import datetime

vault = Path(sys.argv[1])
tmp_path = Path(sys.argv[2])

try:
    raw = tmp_path.read_text(encoding="utf-8")
finally:
    tmp_path.unlink(missing_ok=True)

try:
    hook = json.loads(raw)
except Exception:
    sys.exit(0)

cwd = hook.get("cwd") or ""
if not cwd:
    sys.exit(0)

cwd_path = Path(cwd)
base_name = cwd_path.name or "unknown-project"
candidate = vault / "projects" / base_name
if candidate.exists():
    ctx = candidate / "PROJECT_CONTEXT.md"
    if ctx.exists() and cwd not in ctx.read_text(encoding="utf-8", errors="ignore"):
        base_name = f"{base_name}-{hashlib.md5(str(cwd_path.parent).encode()).hexdigest()[:6]}"
project_name = base_name
project_dir = vault / "projects" / project_name

for d in [project_dir, project_dir / "sessions", project_dir / "raw"]:
    d.mkdir(parents=True, exist_ok=True)

defaults = {
    "PROJECT_CONTEXT.md": f"# Project Context: {project_name}\n\n## Purpose\nAuto-created by ContextOS.\n\n## Current Status\nNew project memory created automatically.\n\n## Working Directory\n{cwd}\n\n## Active Context Pack\nUse SESSION_LOG.md, DECISIONS.md, NEXT_ACTIONS.md, and graph.mmd for continuity.\n",
    "DECISIONS.md": f"# Decisions: {project_name}\n\n- No locked decisions captured yet.\n",
    "NEXT_ACTIONS.md": f"# Next Actions: {project_name}\n\n1. Inspect current repo/project state.\n2. Identify active goal.\n3. Continue from latest Claude Code session context.\n",
    "SESSION_LOG.md": f"# Session Log: {project_name}\n\n",
    "graph.mmd": f"graph TD\n    A[{project_name}] --> B[Sessions]\n    A --> C[Decisions]\n    A --> D[Next Actions]\n    A --> E[Project Context]\n",
}

for name, content in defaults.items():
    path = project_dir / name
    if not path.exists():
        path.write_text(content, encoding="utf-8")

scripts_dir = vault / "scripts"
sys.path.insert(0, str(scripts_dir))
try:
    from contextos_index import update_project_index
    index_path = update_project_index(vault)
except ImportError:
    index_path = vault / "PROJECT_INDEX.md"

def read_tail(path, max_chars):
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="ignore")
    return text[-max_chars:] if len(text) > max_chars else text

context = f"""# ContextOS Retrieved Memory for {project_name}

ContextOS active: loaded memory for {project_name} from {project_dir}

Working directory: {cwd}

ContextOS memory vault path for this project: {project_dir}
Do not assume memory files live inside the working repo. They live in the ContextOS memory vault unless explicitly configured otherwise.

CRITICAL: Never create or edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd inside the working directory. ContextOS memory files live only at: {project_dir}. During active sessions, read ContextOS memory only. SessionEnd hook performs all memory updates after exit.

IMPORTANT CONTEXTOS RULE: During active Claude Code sessions, do not use Write, Edit, MultiEdit, or file-modification tools on ContextOS memory files. Do not directly edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd. These files are updated automatically by the SessionEnd hook after the session exits. You may read them for context only unless the user explicitly asks you to edit them manually.
"""

for fn in ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md", "graph.mmd"]:
    text = read_tail(project_dir / fn, 2500)
    if text:
        context += f"\n## {fn}\n{text}\n"

if len(context) > 6000:
    context = context[:6000] + "\n\n[Current project context truncated.]\n"

if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") != "false" and index_path.exists():
    idx = index_path.read_text(encoding="utf-8", errors="ignore")[:3000]
    context += "\n## Cross-Project Awareness\nCross-project memory is enabled by default. Use this vault-level index to identify possibly related prior work. Do not assume unrelated project details apply to the current project without user confirmation. To disable this startup section, set CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false.\n\n"
    context += idx

print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}))
PY
