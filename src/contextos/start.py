"""SessionStart hook — inject project memory into Claude Code."""

import hashlib
import json
import os
import sys
from pathlib import Path

from .cache import index_is_stale, mark_index_built
from .index import update_project_index
from .vault import DEFAULT_TEMPLATES, get_vault_path

PROJECT_BUDGET = 6000
CROSS_PROJECT_BUDGET = 3000


def _read_tail(path: Path, max_chars: int) -> str:
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="ignore")
    return text[-max_chars:] if len(text) > max_chars else text


def _resolve_project_name(vault: Path, cwd: str) -> str:
    cwd_path = Path(cwd)
    base = cwd_path.name or "unknown-project"
    candidate = vault / "projects" / base
    if candidate.exists():
        ctx = candidate / "PROJECT_CONTEXT.md"
        if ctx.exists() and cwd not in ctx.read_text(encoding="utf-8", errors="ignore"):
            parent_hash = hashlib.md5(str(cwd_path.parent).encode()).hexdigest()[:6]
            base = f"{base}-{parent_hash}"
    return base


def run_start() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        sys.exit(0)

    try:
        hook = json.loads(raw)
    except Exception:
        sys.exit(0)

    cwd = hook.get("cwd") or ""
    if not cwd:
        sys.exit(0)

    vault = get_vault_path()
    project_name = _resolve_project_name(vault, cwd)
    project_dir = vault / "projects" / project_name

    for d in [project_dir, project_dir / "sessions", project_dir / "raw"]:
        d.mkdir(parents=True, exist_ok=True)

    for fn, tmpl in DEFAULT_TEMPLATES.items():
        path = project_dir / fn
        if not path.exists():
            path.write_text(tmpl.format(name=project_name, cwd=cwd), encoding="utf-8")

    if index_is_stale(vault):
        index_path = update_project_index(vault)
        mark_index_built(vault)
    else:
        index_path = vault / "PROJECT_INDEX.md"

    context = f"""# ContextOS Retrieved Memory for {project_name}

ContextOS active: loaded memory for {project_name} from {project_dir}

Working directory: {cwd}

ContextOS memory vault path for this project: {project_dir}
Do not assume memory files live inside the working repo. They live in the ContextOS memory vault unless explicitly configured otherwise.

CRITICAL: Never create or edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd inside the working directory. ContextOS memory files live only at: {project_dir}. During active sessions, read ContextOS memory only. SessionEnd hook performs all memory updates after exit.

IMPORTANT CONTEXTOS RULE: During active Claude Code sessions, do not use Write, Edit, MultiEdit, or file-modification tools on ContextOS memory files. Do not directly edit PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md, SESSION_LOG.md, or graph.mmd. These files are updated automatically by the SessionEnd hook after the session exits. You may read them for context only unless the user explicitly asks you to edit them manually.
"""

    for fn in ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md", "graph.mmd"]:
        text = _read_tail(project_dir / fn, 2500)
        if text:
            context += f"\n## {fn}\n{text}\n"

    if len(context) > PROJECT_BUDGET:
        context = context[:PROJECT_BUDGET] + "\n\n[Current project context truncated.]\n"

    if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") != "false" and index_path.exists():
        index_text = index_path.read_text(encoding="utf-8", errors="ignore")[:CROSS_PROJECT_BUDGET]
        context += "\n## Cross-Project Awareness\n"
        context += (
            "Cross-project memory is enabled by default. Use this vault-level index to identify "
            "possibly related prior work. Do not assume unrelated project details apply to the "
            "current project without user confirmation. To disable this startup section, set "
            "CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY=false.\n\n"
        )
        context += index_text

    response = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context,
        }
    }
    print(json.dumps(response))
