"""Session processing — extract decisions, actions, blockers from transcripts."""

import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from .confidence import score_items
from .index import update_project_index
from .tokens import count_tokens
from .vault import DEFAULT_TEMPLATES, get_vault_path
from . import session_log


NOISE_PATTERNS = [
    "ACTIVE EVERY RESPONSE", "/caveman", "Default: **full**",
    "update-config:", "keybindings-help:", "fewer-permission-prompts:",
    "ContextOS hook loaded", "memory context injected",
    "ContextOS Retrieved Memory", "Auto-created by ContextOS",
    "Active Context Pack", "SESSION_LOG.md", "DECISIONS.md",
    "NEXT_ACTIONS.md", "PROJECT_CONTEXT.md", "graph.mmd",
    "## Persistence", "## Intensity", "Respond terse like smart caveman",
]

DECISION_SIGNALS = [
    "decision:", "decided:", "locked:", "out of scope:", "constraint:",
    "must ", "must not ", "do not ", "source of truth", "required",
]

ACTION_SIGNALS = [
    "next action:", "todo:", "to-do:", "fix ", "build ", "add ",
    "implement ", "test ", "validate ", "check ", "confirm ",
    "audit ", "push ", "create ", "update ",
]

BLOCKER_SIGNALS = [
    "error", "failed", "fails", "blocked", "blocker", "issue",
    "not working", "cannot", "can't", "repository not found",
    "permission denied",
]


def clean_text(text: str) -> str:
    text = str(text).replace("•", "-")
    return re.sub(r"\s+", " ", text).strip()


def is_noise(text: str) -> bool:
    if not text:
        return True
    lower = text.lower()
    if any(p.lower() in lower for p in NOISE_PATTERNS):
        return True
    if text.strip().startswith("#"):
        return True
    if len(text) < 10:
        return True
    if len(text) > 500:
        return True
    if re.match(r"^\d+\s+#", text):
        return True
    return False


def extract_message_text(obj: dict) -> list[str]:
    output = []
    if not isinstance(obj, dict):
        return output
    msg = obj.get("message")
    if isinstance(msg, dict):
        role = msg.get("role")
        content = msg.get("content")
        if role not in {"user", "assistant"}:
            return output
        if isinstance(content, str):
            if not is_noise(content):
                output.append(clean_text(content))
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict):
                    if block.get("type") in {"tool_result", "tool_use"}:
                        continue
                    if block.get("type") == "text" and isinstance(block.get("text"), str):
                        text = clean_text(block["text"])
                        if not is_noise(text):
                            output.append(text)
                elif isinstance(block, str):
                    text = clean_text(block)
                    if not is_noise(text):
                        output.append(text)
    for key in ["prompt", "last_assistant_message", "compact_summary"]:
        if isinstance(obj.get(key), str):
            text = clean_text(obj[key])
            if not is_noise(text):
                output.append(text)
    return output


def read_transcript_items(transcript_path: str, max_items: int = 30) -> list[str]:
    path = Path(transcript_path)
    if not path.exists():
        return []
    items = []
    lines = path.read_text(encoding="utf-8-sig", errors="ignore").splitlines()
    for line in lines[-220:]:
        try:
            obj = json.loads(line)
            items.extend(extract_message_text(obj))
        except Exception:
            continue
    return items[-max_items:]


def split_candidates(items: list[str]) -> list[str]:
    candidates = []
    for item in items:
        parts = re.split(r"[\n\r]+|(?<=[.!?])\s+", item)
        for part in parts:
            part = clean_text(part).strip("- ").strip()
            if not is_noise(part):
                candidates.append(part)
    return candidates


def dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output = []
    for item in items:
        item = clean_text(item)
        key = item.lower()
        if key not in seen:
            seen.add(key)
            output.append(item)
    return output


def classify_candidates(items: list[str]) -> dict:
    decisions, actions, blockers, files_cmds = [], [], [], []
    for item in split_candidates(items):
        lower = item.lower()
        if lower.startswith(("decision:", "decided:", "locked:", "constraint:", "out of scope:")):
            decisions.append(item)
            continue
        if lower.startswith(("next action:", "todo:", "to-do:")):
            actions.append(item)
            continue
        if any(s in lower for s in DECISION_SIGNALS):
            decisions.append(item)
        if any(s in lower for s in ACTION_SIGNALS):
            actions.append(item)
        if any(s in lower for s in BLOCKER_SIGNALS):
            blockers.append(item)
        if re.search(r"\b[\w\-]+\.(py|js|ts|tsx|jsx|json|md|yml|yaml|env|html|css)\b", item, re.I):
            files_cmds.append(item)
        if any(cmd in lower for cmd in ["git ", "npm ", "python ", "powershell", "curl ", "claude "]):
            files_cmds.append(item)
    return {
        "decisions": score_items(dedupe(decisions), "decision"),
        "actions": score_items(dedupe(actions), "action"),
        "blockers": dedupe(blockers),
        "files_or_commands": dedupe(files_cmds),
    }


def make_summary(items: list[str]) -> str:
    clean = [clean_text(i) for i in items[-8:] if not is_noise(clean_text(i))]
    if not clean:
        return "No useful summary captured after filtering noise."
    return "\n".join(f"- {i}" for i in clean[:6])


def _ensure_file(path: Path, content: str) -> None:
    if not path.exists():
        path.write_text(content, encoding="utf-8")


def _existing_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def _append_unique_bullets(path: Path, scored_items: list[dict], now: str) -> None:
    if not scored_items:
        return
    current = _existing_text(path).lower()
    unique = []
    for item in scored_items:
        text = item["text"] if isinstance(item, dict) else clean_text(str(item))
        if is_noise(text):
            continue
        if text.lower() not in current and text not in unique:
            unique.append(text)
    if not unique:
        return
    block = f"\n\n## Auto-captured — {now}\n\n"
    for text in unique[:6]:
        block += f"- {text}\n"
    with path.open("a", encoding="utf-8") as f:
        f.write(block)


def update_project_context(path: Path, cwd: str, now: str, summary: str, extracted: dict) -> None:
    context = _existing_text(path)
    latest = f"\n---\n\n## Latest Auto-Captured Status — {now}\n\n### Working Directory\n{cwd}\n\n### Latest Session Summary\n{summary}\n\n### Possible Blockers / Issues\n"
    blockers = extracted.get("blockers", [])
    if blockers:
        for b in blockers[:5]:
            latest += f"- {b}\n"
    else:
        latest += "- None auto-detected.\n"
    latest += "\n### Important Files / Commands Mentioned\n"
    files = extracted.get("files_or_commands", [])
    if files:
        for f in files[:5]:
            latest += f"- {f}\n"
    else:
        latest += "- None auto-detected.\n"

    if "## Latest Auto-Captured Status" in context:
        context = re.sub(
            r"\n---\n\n## Latest Auto-Captured Status[\s\S]*$",
            lambda _: latest, context, flags=re.MULTILINE,
        )
        path.write_text(context, encoding="utf-8")
    else:
        with path.open("a", encoding="utf-8") as f:
            f.write(latest)


def update_token_savings(project_dir: Path, project_name: str, now: str) -> None:
    memory_text = ""
    for fn in ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md", "graph.mmd"]:
        p = project_dir / fn
        if p.exists():
            memory_text += _existing_text(p) + "\n"

    est_tokens = count_tokens(memory_text)
    session_count = _existing_text(project_dir / "SESSION_LOG.md").count("## Session Capsule")
    avoided = est_tokens * max(session_count - 1, 0)

    content = f"""# Token Savings: {project_name}

## Summary

- Sessions captured: {session_count}
- Estimated current memory context tokens: {est_tokens}
- Estimated repeated context avoided: {avoided} tokens
- Last updated: {now}
- Token counter: {"tiktoken (cl100k_base)" if count_tokens.__module__ != "builtins" else "chars/4 estimate"}

## Method

Token estimates use {"tiktoken cl100k_base encoding" if True else "chars/4 approximation"}.
"""
    (project_dir / "TOKEN_SAVINGS.md").write_text(content, encoding="utf-8")


def process_event(event_path: Path) -> None:
    try:
        event = json.loads(Path(event_path).read_text(encoding="utf-8-sig"))
    except Exception as e:
        print(f"Failed to read event: {event_path}: {e}")
        return

    vault = get_vault_path()
    cwd = event.get("cwd") or ""
    project_name = Path(cwd).name if cwd else "unknown-project"
    event_name = event.get("hook_event_name", "UnknownEvent")
    session_id = event.get("session_id", "unknown-session")
    transcript_path = event.get("transcript_path")
    compact_summary = event.get("compact_summary", "")

    project_dir = vault / "projects" / project_name
    project_dir.mkdir(parents=True, exist_ok=True)

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    graph_node = datetime.now().strftime("%Y%m%d%H%M%S")

    for fn, tmpl in DEFAULT_TEMPLATES.items():
        _ensure_file(project_dir / fn, tmpl.format(name=project_name, cwd=cwd))

    if compact_summary:
        items = [compact_summary]
    elif transcript_path:
        items = read_transcript_items(transcript_path)
    else:
        items = []

    summary = make_summary(items)
    extracted = classify_candidates(items)

    # Append to JSONL session log
    capsule_data = {
        "time": now, "event": event_name, "session_id": session_id, "cwd": cwd,
        "summary": summary,
        "decisions": extracted["decisions"],
        "actions": extracted["actions"],
        "blockers": extracted["blockers"],
    }
    session_log.append_session(project_dir, capsule_data)
    session_log.sync_markdown(project_dir)

    # Save snapshot for diff
    try:
        from .diff import save_snapshot
        save_snapshot(project_dir)
    except Exception:
        pass

    _append_unique_bullets(project_dir / "DECISIONS.md", extracted["decisions"], now)
    _append_unique_bullets(project_dir / "NEXT_ACTIONS.md", extracted["actions"], now)
    update_project_context(project_dir / "PROJECT_CONTEXT.md", cwd, now, summary, extracted)
    update_token_savings(project_dir, project_name, now)
    update_project_index(vault)

    with (project_dir / "graph.mmd").open("a", encoding="utf-8") as f:
        f.write(f'\n    B --> S{graph_node}["{event_name} - {now}"]\n')

    from .compress import compress_project
    compress_project(project_dir, threshold=30000)

    print(f"ContextOS processed {project_name} / {event_name}")
