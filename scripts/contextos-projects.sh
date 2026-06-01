#!/usr/bin/env bash
set -euo pipefail

refresh_only="false"
if [[ "${1:-}" == "--refresh-only" || "${1:-}" == "-RefreshOnly" ]]; then
  refresh_only="true"
fi

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"

python3 - "$vault" "$refresh_only" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent if not __file__.startswith("<") else Path(sys.argv[1]) / "scripts"))
scripts_dir = Path(sys.argv[1]) / "scripts"
sys.path.insert(0, str(scripts_dir))

from contextos_index import update_project_index, latest_memory_update

vault = Path(sys.argv[1])
refresh_only = sys.argv[2] == "true"

update_project_index(vault)

if not refresh_only:
    index_path = vault / "PROJECT_INDEX.md"
    projects_dir = vault / "projects"
    projects = [p for p in projects_dir.iterdir() if p.is_dir()] if projects_dir.exists() else []
    print()
    print("ContextOS Projects")
    print("==================")
    print()
    print(f"Vault path:       {vault}")
    print(f"Projects indexed: {len(projects)}")
    print(f"Project index:    {index_path}")
    print()
    if index_path.exists():
        print(index_path.read_text(encoding="utf-8", errors="ignore"))
PY
