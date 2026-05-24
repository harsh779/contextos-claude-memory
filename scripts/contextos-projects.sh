#!/usr/bin/env bash
set -euo pipefail

refresh_only="false"
if [[ "${1:-}" == "--refresh-only" || "${1:-}" == "-RefreshOnly" ]]; then
  refresh_only="true"
fi

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"

python3 - "$vault" "$refresh_only" <<'PY'
import re
import sys
from pathlib import Path
from datetime import datetime

vault = Path(sys.argv[1])
refresh_only = sys.argv[2] == "true"

def normalize(line):
    line = str(line or "").strip()
    line = re.sub(r"^\s*[-*]\s+", "", line)
    line = re.sub(r"^\s*\d+\.\s+", "", line)
    line = re.sub(r"^(decision|decided|next action|todo|to-do):\s*", "", line, flags=re.I)
    return line.strip()

def is_noise(line):
    clean = normalize(line)
    if not clean or clean == "---" or len(clean) > 220:
        return True
    lower = clean.lower()
    if clean.startswith("#") or clean.startswith("```") or "```" in clean:
        return True
    if re.match(r"^[A-Za-z]:\\", clean):
        return True
    noise = [
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
        "but you ",
        "yes,",
        "clicking ",
        "making the fix",
        "aim unclear",
        "want to ",
        "now ",
        "wait for ",
        "checking required files",
        "check the vault files",
        "expected ",
        "build taking time",
    ]
    return any(item in lower for item in noise)

def clean_lines(path, max_lines=4, prefix=""):
    if not path.exists():
        return []
    lines = []
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if is_noise(raw):
            continue
        line = normalize(raw)
        if prefix:
            line = prefix + line
        if line not in lines:
            lines.append(line)
    return lines[:max_lines]

def stable_context(path, max_lines=2):
    if not path.exists():
        return []
    lines = []
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if raw.startswith("## Latest Auto-Captured Status"):
            break
        if is_noise(raw):
            continue
        line = normalize(raw)
        if line not in lines:
            lines.append(line)
    return lines[:max_lines]

def is_technical(line):
    if is_noise(line):
        return False
    lower = normalize(line).lower()
    patterns = [".prisma", "prisma", "hostinger", "deploy", "build", "neon", "database", "api ", "route", "schema", "error", "failed", "logs", "npm", "package-lock", "razorpay", "signalr", "northflank", "github", "remote"]
    return any(item in lower for item in patterns)

def score(line):
    lower = normalize(line).lower()
    value = 0
    for item in [".prisma", "prisma", "schema", "hostinger", "neon", "database", "razorpay", "signalr", "northflank"]:
        if item in lower:
            value += 3
    for item in ["deploy", "build", "failed", "error", "logs", "npm", "package-lock", "github", "remote", "api ", "route"]:
        if item in lower:
            value += 1
    return value

def technical_signals(path, max_lines=2):
    if not path.exists():
        return []
    lines = []
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not is_technical(raw):
            continue
        line = normalize(raw)
        if line not in [item["line"] for item in lines]:
            lines.append({"line": line, "score": score(line)})
    lines.sort(key=lambda item: item["score"], reverse=True)
    return [item["line"] for item in lines[:max_lines]]

def signals(project):
    context = project / "PROJECT_CONTEXT.md"
    status = stable_context(context, 2)
    technical = [line for line in technical_signals(context, 3) if line not in status][:2]
    output = [f"Status: {line}" for line in status]
    output += [f"Signal: {line}" for line in technical]
    output += clean_lines(project / "DECISIONS.md", 2, "Decision: ")
    output += clean_lines(project / "NEXT_ACTIONS.md", 2, "Next: ")
    return output[:6]

def latest(project):
    candidates = []
    for path in project.rglob("*"):
        if not path.is_file():
            continue
        parts = {part.lower() for part in path.parts}
        if {"raw", "sessions", "archives"} & parts:
            continue
        if path.suffix.lower() in {".md", ".mmd"}:
            candidates.append(path.stat().st_mtime)
    return max(candidates) if candidates else project.stat().st_mtime

projects_dir = vault / "projects"
index_path = vault / "PROJECT_INDEX.md"
projects_dir.mkdir(parents=True, exist_ok=True)
projects = sorted([p for p in projects_dir.iterdir() if p.is_dir()], key=latest, reverse=True)

lines = [
    "# ContextOS Project Index",
    "",
    f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
    "",
    "This summary index is generated from project memory files. It does not include raw transcripts or full session logs.",
    "",
]

if not projects:
    lines.append("No projects tracked yet.")

for project in projects:
    lines.extend([f"## {project.name}", "", f"- Last updated: {datetime.fromtimestamp(latest(project)).strftime('%Y-%m-%d %H:%M:%S')}", f"- Memory path: {project}"])
    items = signals(project)
    if items:
        lines.append("- Summary signals:")
        lines.extend([f"  - {item}" for item in items])
    else:
        lines.append("- Summary signals: None captured yet.")
    lines.append("")

index_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

if not refresh_only:
    print()
    print("ContextOS Projects")
    print("==================")
    print()
    print(f"Vault path:       {vault}")
    print(f"Projects indexed: {len(projects)}")
    print(f"Project index:    {index_path}")
    print()
    print(index_path.read_text(encoding="utf-8", errors="ignore"))
PY
