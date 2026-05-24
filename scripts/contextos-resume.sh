#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: contextos-resume <project-name>"
  exit 1
fi

project_name="$1"
vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
project_dir="$vault/projects/$project_name"
packs_dir="$vault/context-packs"

mkdir -p "$packs_dir"

if [[ ! -d "$project_dir" ]]; then
  echo "Project not found: $project_name"
  echo
  echo "Available projects:"
  find "$vault/projects" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true
  exit 1
fi

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
output_path="$packs_dir/$project_name-context-pack-$timestamp.md"

section() {
  local title="$1"
  local path="$2"
  local max_chars="$3"
  printf "## %s\n" "$title"
  if [[ -f "$path" ]]; then
    python3 - "$path" "$max_chars" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
max_chars = int(sys.argv[2])
text = path.read_text(encoding="utf-8", errors="ignore")
print(text[-max_chars:] if len(text) > max_chars else text)
PY
  else
    printf "Not found.\n"
  fi
  printf "\n"
}

{
  printf "# ContextOS Resume Pack: %s\n\n" "$project_name"
  printf "Generated: %s\n\n" "$timestamp"
  printf "Use this as the restart context for Claude / ChatGPT / Codex.\n\n---\n"
  section "Project Context" "$project_dir/PROJECT_CONTEXT.md" 5000
  printf "\n---\n"
  section "Decisions" "$project_dir/DECISIONS.md" 3000
  printf "\n---\n"
  section "Next Actions" "$project_dir/NEXT_ACTIONS.md" 3000
  printf "\n---\n"
  section "Project Graph" "$project_dir/graph.mmd" 2500
  printf "\n---\n"
  section "Latest Session Log" "$project_dir/SESSION_LOG.md" 5000
} > "$output_path"

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$output_path"
  copied="yes"
else
  copied="no"
fi

chars="$(wc -c < "$output_path" | tr -d ' ')"
tokens=$(( (chars + 3) / 4 ))

echo
echo "ContextOS resume pack created:"
echo "$output_path"
if [[ "$copied" == "yes" ]]; then
  echo
  echo "Copied to clipboard."
fi
echo
echo "Token estimate:"
echo "---------------"
echo "Resume pack characters: $chars"
echo "Estimated tokens: $tokens"
echo "Estimated re-explanation avoided per resumed session: ~$tokens tokens"
echo
echo "Preview:"
echo "--------"
head -n 60 "$output_path"
