#!/usr/bin/env bash
set -euo pipefail

version="v0.1.5-dev"

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  echo "ContextOS $version"
  exit 0
fi

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
scripts_dir="$vault/scripts"
projects_dir="$vault/projects"
packs_dir="$vault/context-packs"
settings_path="$HOME/.claude/settings.json"

required=(
  contextos-start.sh
  contextos-capture.sh
  contextos-status.sh
  contextos-projects.sh
  contextos-find.sh
  contextos-resume.sh
  contextos-open.sh
  contextos-doctor.sh
  process-session.py
  compress-project-memory.py
)

missing=()
for item in "${required[@]}"; do
  [[ -f "$scripts_dir/$item" ]] || missing+=("$item")
done

project_count=0
if [[ -d "$projects_dir" ]]; then
  project_count="$(find "$projects_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
fi

pack_count=0
if [[ -d "$packs_dir" ]]; then
  pack_count="$(find "$packs_dir" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
fi

raw_status="Disabled"
[[ "${CONTEXTOS_COPY_RAW_TRANSCRIPTS:-}" == "true" ]] && raw_status="Enabled"

cross_status="Enabled"
[[ "${CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY:-}" == "false" ]] && cross_status="Disabled"

hooks_configured="No"
session_start="No"
session_end="No"
if [[ -f "$settings_path" ]]; then
  grep -q '"hooks"' "$settings_path" && hooks_configured="Yes"
  grep -q 'SessionStart' "$settings_path" && session_start="Yes"
  grep -q 'SessionEnd' "$settings_path" && session_end="Yes"
fi

last_project="None"
last_capture="None"
if [[ -d "$projects_dir" ]] && command -v python3 >/dev/null 2>&1; then
  last_event="$(python3 - "$projects_dir" <<'PY'
import sys
from pathlib import Path

projects = Path(sys.argv[1])
events = list(projects.rglob("*-event.json"))
if events:
    print(max(events, key=lambda path: path.stat().st_mtime))
PY
)"
  if [[ -n "$last_event" ]]; then
    last_capture="$(date -r "$last_event" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo Unknown)"
    last_project="$(basename "$(dirname "$(dirname "$last_event")")")"
  fi
fi

printf "\nContextOS Status\n================\n\n"
printf "%-32s %s\n" "Version:" "$version"
printf "%-32s %s\n" "Vault path:" "$vault"
printf "%-32s %s\n" "Vault exists:" "$([[ -d "$vault" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Scripts folder exists:" "$([[ -d "$scripts_dir" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Required scripts installed:" "$([[ ${#missing[@]} -eq 0 ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Projects tracked:" "$project_count"
printf "%-32s %s\n" "Context packs created:" "$pack_count"
printf "%-32s %s\n" "Raw transcript copying:" "$raw_status"
printf "%-32s %s\n" "Cross-project memory:" "$cross_status"
printf "%-32s %s\n" "Project index exists:" "$([[ -f "$vault/PROJECT_INDEX.md" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Projects command available:" "$([[ -x "$vault/contextos-projects" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Doctor command available:" "$([[ -x "$vault/contextos-doctor" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Claude settings found:" "$([[ -f "$settings_path" ]] && echo Yes || echo No)"
printf "%-32s %s\n" "Hooks configured:" "$hooks_configured"
printf "%-32s %s\n" "SessionStart hook:" "$session_start"
printf "%-32s %s\n" "SessionEnd hook:" "$session_end"
printf "%-32s %s\n" "Last captured project:" "$last_project"
printf "%-32s %s\n" "Last capture time:" "$last_capture"

if [[ ${#missing[@]} -gt 0 ]]; then
  printf "\nMissing scripts:\n"
  for item in "${missing[@]}"; do
    printf -- "- %s\n" "$item"
  done
fi

printf "\n"
