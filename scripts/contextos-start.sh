#!/usr/bin/env bash
set -euo pipefail

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"

input_json="$(cat)"
if [[ -z "${input_json//[[:space:]]/}" ]]; then
  exit 0
fi

tmp_input="$(mktemp)"
printf '%s' "$input_json" > "$tmp_input"

python3 - "$vault" "$tmp_input" <<'PY'
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

import hashlib
cwd_path = Path(cwd)
base_name = cwd_path.name or "unknown-project"
parent_hash = hashlib.md5(str(cwd_path.parent).encode()).hexdigest()[:6]
candidate = vault / "projects" / base_name
if candidate.exists():
    existing_ctx = candidate / "PROJECT_CONTEXT.md"
    if existing_ctx.exists():
        ctx_text = existing_ctx.read_text(encoding="utf-8", errors="ignore")
        if cwd not in ctx_text:
            base_name = f"{base_name}-{parent_hash}"
project_name = base_name
project_dir = vault / "projects" / project_name
sessions_dir = project_dir / "sessions"
raw_dir = project_dir / "raw"

project_dir.mkdir(parents=True, exist_ok=True)
sessions_dir.mkdir(parents=True, exist_ok=True)
raw_dir.mkdir(parents=True, exist_ok=True)

defaults = {
    "PROJECT_CONTEXT.md": f"""# Project Context: {project_name}

## Purpose
Auto-created by ContextOS from Claude Code working directory.

## Current Status
New project memory created automatically.

## Working Directory
{cwd}

## Active Context Pack
Use SESSION_LOG.md, DECISIONS.md, NEXT_ACTIONS.md, and graph.mmd for continuity.
""",
    "DECISIONS.md": f"# Decisions: {project_name}\n\n- No locked decisions captured yet.\n",
    "NEXT_ACTIONS.md": f"# Next Actions: {project_name}\n\n1. Inspect current repo/project state.\n2. Identify active goal.\n3. Continue from latest Claude Code session context.\n",
    "SESSION_LOG.md": f"# Session Log: {project_name}\n\n",
    "graph.mmd": f"""graph TD
    A[{project_name}] --> B[Sessions]
    A --> C[Decisions]
    A --> D[Next Actions]
    A --> E[Project Context]
""",
}

for name, content in defaults.items():
    path = project_dir / name
    if not path.exists():
        path.write_text(content, encoding="utf-8")

def read_tail(path, max_chars):
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="ignore")
    if len(text) > max_chars:
        text = text[-max_chars:]
    return text

scripts_dir = vault / "scripts"
sys.path.insert(0, str(scripts_dir))
try:
    from contextos_index import update_project_index as _shared_update
    index_path = _shared_update(vault)
except ImportError:
    index_path = vault / "PROJECT_INDEX.md"

context = f"""# ContextOS Retrieved Memory for {project_name}

ContextOS active: loaded memory for {project_name} from {project_dir}

Working directory: {cwd}

ContextOS memory vault path for this project: {project_dir}
Do not assume memory files live inside the working repo. They live in the ContextOS memory vault unless explicitly configured otherwise.

CRITICAL: Never create or edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd inside the working directory. ContextOS memory files live only at: {project_dir}. During active sessions, read ContextOS memory only. SessionEnd hook performs all memory updates after exit.

IMPORTANT CONTEXTOS RULE: During active Claude Code sessions, do not use Write, Edit, MultiEdit, or file-modification tools on ContextOS memory files. Do not directly edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd. These files are updated automatically by the SessionEnd hook after the session exits. You may read them for context only unless the user explicitly asks you to edit them manually.
"""

for file_name in ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md", "graph.mmd"]:
    text = read_tail(project_dir / file_name, 2500)
    if text:
        context += f"\n## {file_name}\n{text}\n"

PROJECT_BUDGET = 6000
CROSS_PROJECT_BUDGET = 3000

if len(context) > PROJECT_BUDGET:
    context = context[:PROJECT_BUDGET] + "\n\n[Current project context truncated.]\n"

if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") != "false" and index_path.exists():
    index_text = index_path.read_text(encoding="utf-8", errors="ignore")[:CROSS_PROJECT_BUDGET]
    context += "\n## Cross-Project Awareness\n"
    context += "Cross-project memory is enabled by default. Use this vault-level index to identify possibly related prior work. Do not assume unrelated project details apply to the current project without user confirmation. To disable this startup section, set CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false.\n\n"
    context += index_text

response = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context,
    }
}
print(json.dumps(response))
PY
