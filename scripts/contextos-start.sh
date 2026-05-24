#!/usr/bin/env bash
set -euo pipefail

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"

input_json="$(cat)"
if [[ -z "${input_json//[[:space:]]/}" ]]; then
  exit 0
fi

python3 - "$vault" "$input_json" <<'PY'
import json
import os
import sys
from pathlib import Path
from datetime import datetime

vault = Path(sys.argv[1])
raw = sys.argv[2]

try:
    hook = json.loads(raw)
except Exception:
    sys.exit(0)

cwd = hook.get("cwd") or ""
if not cwd:
    sys.exit(0)

project_name = Path(cwd).name or "unknown-project"
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

def clean_line(line):
    line = line.strip()
    while line.startswith(("-", "*")):
        line = line[1:].strip()
    if len(line) > 220:
        return ""
    lower = line.lower()
    noise = [
        "auto-created by contextos",
        "new project memory created automatically",
        "no locked decisions captured yet",
        "inspect current repo/project state",
        "identify active goal",
        "continue from latest claude code session context",
        "no useful summary captured",
        "none auto-detected",
        "do not respond to these messages",
        "local-command-caveat",
    ]
    if not line or line.startswith("#") or line == "---" or any(item in lower for item in noise):
        return ""
    return line

def project_signals(path):
    signals = []
    for file_name, prefix in [
        ("PROJECT_CONTEXT.md", "Status: "),
        ("DECISIONS.md", "Decision: "),
        ("NEXT_ACTIONS.md", "Next: "),
    ]:
        file_path = path / file_name
        if not file_path.exists():
            continue
        for raw_line in file_path.read_text(encoding="utf-8", errors="ignore").splitlines():
            if raw_line.startswith("## Latest Auto-Captured Status"):
                break
            line = clean_line(raw_line)
            if line:
                signals.append(prefix + line)
            if len(signals) >= 6:
                return signals
    return signals

def update_project_index():
    projects_dir = vault / "projects"
    index_path = vault / "PROJECT_INDEX.md"
    projects_dir.mkdir(parents=True, exist_ok=True)
    projects = sorted([p for p in projects_dir.iterdir() if p.is_dir()], key=lambda p: p.stat().st_mtime, reverse=True)
    lines = [
        "# ContextOS Project Index",
        "",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "This summary index is generated from project memory files. It does not include raw transcripts or full session logs.",
        "",
    ]
    for project in projects:
        lines.extend([f"## {project.name}", "", f"- Last updated: {datetime.fromtimestamp(project.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S')}", f"- Memory path: {project}"])
        signals = project_signals(project)
        if signals:
            lines.append("- Summary signals:")
            lines.extend([f"  - {signal}" for signal in signals[:6]])
        else:
            lines.append("- Summary signals: None captured yet.")
        lines.append("")
    index_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return index_path

index_path = update_project_index()

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

if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") != "false" and index_path.exists():
    if len(context) > 6000:
        context = context[:6000] + "\n\n[Current project context truncated before cross-project index.]\n"
    index_text = index_path.read_text(encoding="utf-8", errors="ignore")[:3000]
    context += "\n## Cross-Project Awareness\n"
    context += "Cross-project memory is enabled by default. Use this vault-level index to identify possibly related prior work. Do not assume unrelated project details apply to the current project without user confirmation. To disable this startup section, set CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false.\n\n"
    context += index_text

context = context[:9000]

response = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context,
    }
}
print(json.dumps(response))
PY
