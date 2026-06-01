"""Shared index logic for ContextOS project index generation.

Used by both process-session.py and contextos-projects.sh to avoid drift.
"""

import re
from datetime import datetime
from pathlib import Path


def normalize_index_line(line):
    line = str(line or "").strip()
    line = re.sub(r"^\s*[-*]\s+", "", line)
    line = re.sub(r"^\s*\d+\.\s+", "", line)
    line = re.sub(r"^(decision|decided|next action|todo|to-do):\s*", "", line, flags=re.I)
    return line.strip()


def is_index_noise(line):
    clean = normalize_index_line(line)

    if not clean:
        return True

    lower = clean.lower()

    if clean == "---":
        return True

    if len(clean) > 220:
        return True

    if clean.startswith("#"):
        return True

    if clean.startswith("```"):
        return True

    if "```" in clean:
        return True

    if re.match(r"^[A-Za-z]:\\", clean):
        return True

    noise_patterns = [
        "auto-created by contextos",
        "new project memory created automatically",
        "use session_log.md",
        "no locked decisions captured yet",
        "inspect current repo/project state",
        "identify active goal",
        "continue from latest claude code session context",
        "no useful summary captured",
        "none auto-detected",
        "do not respond to these messages",
        "local-command-caveat",
        "you're out of extra usage",
        "let me ",
        "can you ",
        "could you ",
        "but you ",
        "yes,",
        "clicking ",
        "making the fix",
        "aim unclear",
        "want to ",
        "i'll ",
        "i will ",
        "i can ",
        "now update ",
        "now run ",
        "wait for ",
        "checking required files",
        "check the vault files",
        "let me check",
        "expected ",
        "click ",
        "run npm",
        "run git",
        "build taking time",
    ]

    return any(pattern in lower for pattern in noise_patterns)


def clean_project_context_lines(path, max_lines=2):
    if not path.exists():
        return []

    lines = []

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if raw_line.strip().startswith("## Latest Auto-Captured Status"):
            break

        if is_index_noise(raw_line):
            continue

        line = normalize_index_line(raw_line)

        if line not in lines:
            lines.append(line)

    return lines[:max_lines]


def clean_index_lines(path, max_lines=4, prefix=""):
    if not path.exists():
        return []

    lines = []

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if is_index_noise(raw_line):
            continue

        line = normalize_index_line(raw_line)

        if prefix:
            line = f"{prefix}{line}"

        if line not in lines:
            lines.append(line)

    return lines[:max_lines]


def is_technical_signal(line):
    if is_index_noise(line):
        return False

    lower = normalize_index_line(line).lower()
    technical_patterns = [
        ".prisma", "prisma", "hostinger", "deploy", "build", "neon",
        "database", "db ", "api ", "route", "schema", "error", "failed",
        "blocker", "logs", "npm", "package-lock", "razorpay", "signalr",
        "northflank", "github", "remote",
    ]

    return any(pattern in lower for pattern in technical_patterns)


def technical_signal_score(line):
    lower = normalize_index_line(line).lower()
    score = 0

    for pattern in [".prisma", "prisma", "schema", "hostinger", "neon", "database", "razorpay", "signalr", "northflank"]:
        if pattern in lower:
            score += 3

    for pattern in ["deploy", "build", "failed", "error", "logs", "npm", "package-lock", "github", "remote", "api ", "route"]:
        if pattern in lower:
            score += 1

    return score


def latest_technical_signals(path, max_lines=2):
    if not path.exists():
        return []

    signals = []

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not is_technical_signal(raw_line):
            continue

        line = normalize_index_line(raw_line)

        if not any(existing["line"] == line for existing in signals):
            signals.append({"line": line, "score": technical_signal_score(line)})

    signals.sort(key=lambda item: item["score"], reverse=True)
    return [item["line"] for item in signals[:max_lines]]


def project_index_signals(project):
    signals = []
    project_context = project / "PROJECT_CONTEXT.md"
    status_lines = clean_project_context_lines(project_context, 2)
    technical_lines = [
        line for line in latest_technical_signals(project_context, 3)
        if line not in status_lines
    ][:2]

    signals.extend([f"Status: {line}" for line in status_lines])
    signals.extend([f"Signal: {line}" for line in technical_lines])
    signals.extend(clean_index_lines(project / "DECISIONS.md", 2, "Decision: "))
    signals.extend(clean_index_lines(project / "NEXT_ACTIONS.md", 2, "Next: "))
    return signals[:6]


def latest_memory_update(project_dir):
    candidates = []

    for path in project_dir.rglob("*"):
        if not path.is_file():
            continue

        parts = {part.lower() for part in path.parts}

        if {"raw", "sessions", "archives"} & parts:
            continue

        if path.suffix.lower() not in {".md", ".mmd"}:
            continue

        candidates.append(path)

    if not candidates:
        return project_dir.stat().st_mtime

    return max(path.stat().st_mtime for path in candidates)


def estimate_tokens(text):
    if not text:
        return 0
    return max(1, (len(text) + 3) // 4)


def update_project_index(vault):
    projects_dir = vault / "projects"
    index_path = vault / "PROJECT_INDEX.md"
    lock_path = vault / "PROJECT_INDEX.lock"

    projects_dir.mkdir(parents=True, exist_ok=True)

    try:
        fd = lock_path.open("x")
        fd.close()
    except FileExistsError:
        import time
        if lock_path.exists() and (time.time() - lock_path.stat().st_mtime) > 30:
            lock_path.unlink(missing_ok=True)
            fd = lock_path.open("x")
            fd.close()
        else:
            return index_path

    try:
        projects = [path for path in projects_dir.iterdir() if path.is_dir()]
        projects.sort(key=latest_memory_update, reverse=True)

        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        content = [
            "# ContextOS Project Index",
            "",
            f"Generated: {now}",
            "",
            "This summary index is generated from project memory files. It does not include raw transcripts or full session logs.",
            "",
        ]

        if not projects:
            content.append("No projects tracked yet.")

        for project in projects:
            last_updated = datetime.fromtimestamp(latest_memory_update(project)).strftime("%Y-%m-%d %H:%M:%S")
            summary_lines = project_index_signals(project)

            content.extend(
                [
                    f"## {project.name}",
                    "",
                    f"- Last updated: {last_updated}",
                    f"- Memory path: {project}",
                ]
            )

            if summary_lines:
                content.append("- Summary signals:")
                for line in summary_lines[:6]:
                    content.append(f"  - {line}")
            else:
                content.append("- Summary signals: None captured yet.")

            content.append("")

        index_path.write_text("\n".join(content).rstrip() + "\n", encoding="utf-8")
    finally:
        lock_path.unlink(missing_ok=True)

    return index_path
