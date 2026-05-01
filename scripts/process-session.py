import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from datetime import datetime


def get_contextos_vault_path():
    configured = os.environ.get("CONTEXTOS_VAULT_PATH")
    if configured and configured.strip():
        return Path(configured.strip())
    return Path.home() / "AI-Memory-Vault"


VAULT = get_contextos_vault_path()

NOISE_PATTERNS = [
    "ACTIVE EVERY RESPONSE",
    "/caveman",
    "Default: **full**",
    "update-config:",
    "keybindings-help:",
    "fewer-permission-prompts:",
    "ContextOS hook loaded",
    "memory context injected",
    "ContextOS Retrieved Memory",
    "Auto-created by ContextOS",
    "Active Context Pack",
    "SESSION_LOG.md",
    "DECISIONS.md",
    "NEXT_ACTIONS.md",
    "PROJECT_CONTEXT.md",
    "graph.mmd",
    "## Persistence",
    "## Intensity",
    "Respond terse like smart caveman",
]

DECISION_SIGNALS = [
    "decision:",
    "decided:",
    "locked:",
    "out of scope:",
    "constraint:",
    "must ",
    "must not ",
    "do not ",
    "source of truth",
    "required",
]

ACTION_SIGNALS = [
    "next action:",
    "todo:",
    "to-do:",
    "fix ",
    "build ",
    "add ",
    "implement ",
    "test ",
    "validate ",
    "check ",
    "confirm ",
    "audit ",
    "push ",
    "create ",
    "update ",
]

BLOCKER_SIGNALS = [
    "error",
    "failed",
    "fails",
    "blocked",
    "blocker",
    "issue",
    "not working",
    "cannot",
    "can't",
    "repository not found",
    "permission denied",
]


def safe_read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8-sig"))
    except Exception as e:
        print(f"Failed to read JSON event file: {path}")
        print(f"Error: {e}")
        return {}


def clean_text(text):
    text = str(text)
    text = text.replace("•", "-")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def is_noise(text):
    if not text:
        return True

    lower = text.lower()

    if any(pattern.lower() in lower for pattern in NOISE_PATTERNS):
        return True

    if text.strip().startswith("#"):
        return True

    if len(text) < 15:
        return True

    if len(text) > 500:
        return True

    if re.match(r"^\d+\s+#", text):
        return True

    return False


def extract_message_text(obj):
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
                    block_type = block.get("type")

                    if block_type in {"tool_result", "tool_use"}:
                        continue

                    if block_type == "text" and isinstance(block.get("text"), str):
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


def read_transcript_items(transcript_path, max_items=30):
    path = Path(transcript_path)

    if not path.exists():
        return []

    items = []
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()

    for line in lines[-220:]:
        try:
            obj = json.loads(line)
            items.extend(extract_message_text(obj))
        except Exception:
            continue

    return items[-max_items:]


def split_candidates(items):
    candidates = []

    for item in items:
        parts = re.split(r"[\n\r]+|(?<=[.!?])\s+", item)

        for part in parts:
            part = clean_text(part).strip("- ").strip()

            if is_noise(part):
                continue

            candidates.append(part)

    return candidates


def dedupe(items):
    seen = set()
    output = []

    for item in items:
        item = clean_text(item)
        key = item.lower()

        if key in seen:
            continue

        seen.add(key)
        output.append(item)

    return output


def classify_candidates(items):
    decisions = []
    actions = []
    blockers = []
    files_or_commands = []

    candidates = split_candidates(items)

    for item in candidates:
        lower = item.lower()

        if lower.startswith(("decision:", "decided:", "locked:", "constraint:", "out of scope:")):
            decisions.append(item)
            continue

        if lower.startswith(("next action:", "todo:", "to-do:")):
            actions.append(item)
            continue

        if any(signal in lower for signal in DECISION_SIGNALS):
            decisions.append(item)

        if any(signal in lower for signal in ACTION_SIGNALS):
            actions.append(item)

        if any(signal in lower for signal in BLOCKER_SIGNALS):
            blockers.append(item)

        if re.search(r"\b[\w\-]+\.(py|js|ts|tsx|jsx|json|md|yml|yaml|env|html|css)\b", item, re.I):
            files_or_commands.append(item)

        if any(cmd in lower for cmd in ["git ", "npm ", "python ", "powershell", "curl ", "claude "]):
            files_or_commands.append(item)

    return {
        "decisions": dedupe(decisions),
        "actions": dedupe(actions),
        "blockers": dedupe(blockers),
        "files_or_commands": dedupe(files_or_commands),
    }


def ensure_file(path, default_content):
    if not path.exists():
        path.write_text(default_content, encoding="utf-8")


def append(path, content):
    with path.open("a", encoding="utf-8") as f:
        f.write(content)


def existing_text(path):
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def append_unique_bullets(path, bullets, now):
    if not bullets:
        return

    current = existing_text(path).lower()
    unique = []

    for bullet in bullets:
        bullet = clean_text(bullet)

        if is_noise(bullet):
            continue

        if bullet.lower() not in current and bullet not in unique:
            unique.append(bullet)

    if not unique:
        return

    block = f"\n\n## Auto-captured — {now}\n\n"

    for item in unique[:6]:
        block += f"- {item}\n"

    append(path, block)


def make_summary(items):
    clean_items = []

    for item in items[-8:]:
        item = clean_text(item)

        if not is_noise(item):
            clean_items.append(item)

    if not clean_items:
        return "No useful summary captured after filtering noise."

    return "\n".join(f"- {item}" for item in clean_items[:6])


def update_project_context(project_context, cwd, now, summary, extracted):
    context = existing_text(project_context)

    latest_block = f"""
---

## Latest Auto-Captured Status — {now}

### Working Directory
{cwd}

### Latest Session Summary
{summary}

### Possible Blockers / Issues
"""

    blockers = extracted.get("blockers", [])

    if blockers:
        for blocker in blockers[:5]:
            latest_block += f"- {blocker}\n"
    else:
        latest_block += "- None auto-detected.\n"

    latest_block += "\n### Important Files / Commands Mentioned\n"

    files_or_commands = extracted.get("files_or_commands", [])

    if files_or_commands:
        for item in files_or_commands[:5]:
            latest_block += f"- {item}\n"
    else:
        latest_block += "- None auto-detected.\n"

    if "## Latest Auto-Captured Status" in context:
        context = re.sub(
            r"\n---\n\n## Latest Auto-Captured Status[\s\S]*$",
            latest_block,
            context,
            flags=re.MULTILINE,
        )
        project_context.write_text(context, encoding="utf-8")
    else:
        append(project_context, latest_block)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--event", required=True)
    args = parser.parse_args()

    event = safe_read_json(args.event)

    cwd = event.get("cwd") or ""
    project_name = Path(cwd).name if cwd else "unknown-project"
    event_name = event.get("hook_event_name", "UnknownEvent")
    session_id = event.get("session_id", "unknown-session")
    transcript_path = event.get("transcript_path")
    compact_summary = event.get("compact_summary", "")

    project_dir = VAULT / "projects" / project_name
    project_dir.mkdir(parents=True, exist_ok=True)

    project_context = project_dir / "PROJECT_CONTEXT.md"
    session_log = project_dir / "SESSION_LOG.md"
    decisions = project_dir / "DECISIONS.md"
    next_actions = project_dir / "NEXT_ACTIONS.md"
    graph = project_dir / "graph.mmd"

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    graph_node_id = datetime.now().strftime("%Y%m%d%H%M%S")

    ensure_file(project_context, f"""# Project Context: {project_name}

## Purpose
Auto-created by ContextOS from Claude Code working directory.

## Current Status
New project memory created automatically.

## Working Directory
{cwd}

## Active Context Pack
Use SESSION_LOG.md, DECISIONS.md, NEXT_ACTIONS.md, and graph.mmd for project continuity.
""")

    ensure_file(session_log, f"# Session Log: {project_name}\n\n")
    ensure_file(decisions, f"# Decisions: {project_name}\n\n- No locked decisions captured yet.\n")
    ensure_file(next_actions, f"# Next Actions: {project_name}\n\n1. Inspect current repo/project state.\n2. Identify active goal.\n3. Continue from latest Claude Code session context.\n")
    ensure_file(graph, f"""graph TD
    A[{project_name}] --> B[Sessions]
    A --> C[Decisions]
    A --> D[Next Actions]
    A --> E[Project Context]
""")

    if compact_summary:
        items = [compact_summary]
    elif transcript_path:
        items = read_transcript_items(transcript_path)
    else:
        items = []

    summary = make_summary(items)
    extracted = classify_candidates(items)

    capsule = f"""
---

## Session Capsule

**Time:** {now}  
**Event:** {event_name}  
**Session ID:** {session_id}  
**Working Directory:** {cwd}

### Captured Summary
{summary}

### Auto-Extracted Decisions
"""

    if extracted["decisions"]:
        for item in extracted["decisions"][:6]:
            capsule += f"- {item}\n"
    else:
        capsule += "- None auto-detected.\n"

    capsule += "\n### Auto-Extracted Next Actions\n"

    if extracted["actions"]:
        for item in extracted["actions"][:6]:
            capsule += f"- {item}\n"
    else:
        capsule += "- None auto-detected.\n"

    capsule += "\n### Auto-Detected Blockers / Issues\n"

    if extracted["blockers"]:
        for item in extracted["blockers"][:5]:
            capsule += f"- {item}\n"
    else:
        capsule += "- None auto-detected.\n"

    append(session_log, capsule)

    append_unique_bullets(decisions, extracted["decisions"], now)
    append_unique_bullets(next_actions, extracted["actions"], now)

    update_project_context(project_context, cwd, now, summary, extracted)

    append(graph, f"""
    B --> S{graph_node_id}["{event_name} - {now}"]
""")

    compress_script = VAULT / "scripts" / "compress-project-memory.py"

    if compress_script.exists():
        try:
            subprocess.run(
                [
                    sys.executable,
                    str(compress_script),
                    "--project-dir",
                    str(project_dir),
                    "--threshold",
                    "30000",
                ],
                check=False,
            )
        except Exception as e:
            print(f"ContextOS compression skipped due to error: {e}")

    print(f"ContextOS processed {project_name} / {event_name}")


if __name__ == "__main__":
    main()
