#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: contextos-open <project-name>"
  exit 1
fi

project_name="$1"
vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
project_dir="$vault/projects/$project_name"

if [[ ! -d "$project_dir" ]]; then
  echo "Project not found: $project_name"
  echo
  echo "Available projects:"
  find "$vault/projects" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true
  exit 1
fi

if command -v open >/dev/null 2>&1; then
  open "$project_dir"
  echo "Opened ContextOS project folder:"
else
  echo "ContextOS project folder:"
fi

echo "$project_dir"
