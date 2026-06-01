"""Shared index logic for project index generation. Single source of truth."""

import re
import time
from datetime import datetime
from pathlib import Path


def normalize_index_line(line: str) -> str:
    line = str(line or "").strip()
    line = re.sub(r"^\s*[-*]\s+", "", line)
    line = re.sub(r"^\s*\d+\.\s+", "", line)
    line = re.sub(r"^(decision|decided|next action|todo|to-do):\s*", "", line, flags=re.I)
    return line.strip()


_NOISE_PATTERNS = [
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


def is_index_noise(line: str) -> bool:
    clean = normalize_index_line(line)
    if not clean or clean == "---" or len(clean) > 220:
        return True
    lower = clean.lower()
    if clean.startswith("#") or clean.startswith("```") or "```" in clean:
        return True
    if re.match(r"^[A-Za-z]:\\", clean):
        return True
    return any(pattern in lower for pattern in _NOISE_PATTERNS)


def clean_project_context_lines(path: Path, max_lines: int = 2) -> list[str]:
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


def clean_index_lines(path: Path, max_lines: int = 4, prefix: str = "") -> list[str]:
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


_TECH_PATTERNS_HIGH = [
    ".prisma", "prisma", "schema", "hostinger", "neon",
    "database", "razorpay", "signalr", "northflank",
]
_TECH_PATTERNS_LOW = [
    "deploy", "build", "failed", "error", "logs", "npm",
    "package-lock", "github", "remote", "api ", "route",
]
_ALL_TECH = _TECH_PATTERNS_HIGH + _TECH_PATTERNS_LOW + ["db ", "blocker"]


def is_technical_signal(line: str) -> bool:
    if is_index_noise(line):
        return False
    lower = normalize_index_line(line).lower()
    return any(p in lower for p in _ALL_TECH)


def technical_signal_score(line: str) -> int:
    lower = normalize_index_line(line).lower()
    score = 0
    for p in _TECH_PATTERNS_HIGH:
        if p in lower:
            score += 3
    for p in _TECH_PATTERNS_LOW:
        if p in lower:
            score += 1
    return score


def latest_technical_signals(path: Path, max_lines: int = 2) -> list[str]:
    if not path.exists():
        return []
    signals: list[dict] = []
    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not is_technical_signal(raw_line):
            continue
        line = normalize_index_line(raw_line)
        if not any(s["line"] == line for s in signals):
            signals.append({"line": line, "score": technical_signal_score(line)})
    signals.sort(key=lambda s: s["score"], reverse=True)
    return [s["line"] for s in signals[:max_lines]]


def project_index_signals(project: Path) -> list[str]:
    signals = []
    ctx = project / "PROJECT_CONTEXT.md"
    status = clean_project_context_lines(ctx, 2)
    tech = [l for l in latest_technical_signals(ctx, 3) if l not in status][:2]
    signals.extend([f"Status: {l}" for l in status])
    signals.extend([f"Signal: {l}" for l in tech])
    signals.extend(clean_index_lines(project / "DECISIONS.md", 2, "Decision: "))
    signals.extend(clean_index_lines(project / "NEXT_ACTIONS.md", 2, "Next: "))
    return signals[:6]


def latest_memory_update(project_dir: Path) -> float:
    candidates = []
    for path in project_dir.rglob("*"):
        if not path.is_file():
            continue
        parts = {p.lower() for p in path.parts}
        if {"raw", "sessions", "archives"} & parts:
            continue
        if path.suffix.lower() not in {".md", ".mmd"}:
            continue
        candidates.append(path)
    if not candidates:
        return project_dir.stat().st_mtime
    return max(p.stat().st_mtime for p in candidates)


def update_project_index(vault: Path) -> Path:
    projects_dir = vault / "projects"
    index_path = vault / "PROJECT_INDEX.md"
    lock_path = vault / "PROJECT_INDEX.lock"

    projects_dir.mkdir(parents=True, exist_ok=True)

    try:
        fd = lock_path.open("x")
        fd.close()
    except FileExistsError:
        if lock_path.exists() and (time.time() - lock_path.stat().st_mtime) > 30:
            lock_path.unlink(missing_ok=True)
            fd = lock_path.open("x")
            fd.close()
        else:
            return index_path

    try:
        projects = [p for p in projects_dir.iterdir() if p.is_dir()]
        projects.sort(key=latest_memory_update, reverse=True)

        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        content = [
            "# ContextOS Project Index", "",
            f"Generated: {now}", "",
            "This summary index is generated from project memory files. "
            "It does not include raw transcripts or full session logs.", "",
        ]

        if not projects:
            content.append("No projects tracked yet.")

        for project in projects:
            updated = datetime.fromtimestamp(
                latest_memory_update(project)
            ).strftime("%Y-%m-%d %H:%M:%S")
            sigs = project_index_signals(project)
            content.extend([f"## {project.name}", "", f"- Last updated: {updated}", f"- Memory path: {project}"])
            if sigs:
                content.append("- Summary signals:")
                content.extend([f"  - {s}" for s in sigs[:6]])
            else:
                content.append("- Summary signals: None captured yet.")
            content.append("")

        index_path.write_text("\n".join(content).rstrip() + "\n", encoding="utf-8")
    finally:
        lock_path.unlink(missing_ok=True)

    return index_path
