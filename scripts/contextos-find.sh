#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: contextos-find <search terms>"
  exit 1
fi

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
projects_dir="$vault/projects"
query="$*"

if [[ ! -d "$projects_dir" ]]; then
  echo "No ContextOS projects folder found at $projects_dir"
  exit 1
fi

python3 - "$projects_dir" "$query" <<'PY'
import sys
from pathlib import Path

projects_dir = Path(sys.argv[1])
terms = [term.lower() for term in sys.argv[2].split() if term.strip()]

def low_value(line):
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return True
    lower = stripped.lower()
    return any(item in lower for item in ["ai-memory-vault", "older session log archived", "compression time"])

results = []
for path in projects_dir.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in {".md", ".mmd"}:
        continue
    parts = {part.lower() for part in path.parts}
    if {"raw", "sessions", "archives"} & parts or path.name.startswith("SESSION_LOG_ARCHIVE"):
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    project = path.relative_to(projects_dir).parts[0]
    best = ""
    best_score = 0
    total = 0
    for line in text.splitlines():
        if low_value(line):
            continue
        lower = line.lower()
        score = sum(1 for term in terms if term in lower)
        total += score
        if score > best_score:
            best_score = score
            best = line.strip()
    if total:
        results.append((total, project, path.name, best, str(path)))

if not results:
    print(f"No ContextOS matches found for: {' '.join(terms)}")
    sys.exit(0)

print(f"{'Score':<6} {'Project':<28} {'File':<24} Match")
print("-" * 90)
for score, project, file_name, match, _ in sorted(results, key=lambda item: (-item[0], item[1]))[:20]:
    print(f"{score:<6} {project:<28} {file_name:<24} {match[:100]}")
PY
