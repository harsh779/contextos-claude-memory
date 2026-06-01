"""Project index management."""

import sys
from pathlib import Path

from .index import update_project_index
from .cache import mark_index_built
from .vault import get_vault_path


def cli_projects(args: list[str] | None = None) -> None:
    refresh_only = "--refresh-only" in (args or []) or "-RefreshOnly" in (args or [])
    vault = get_vault_path()

    update_project_index(vault)
    mark_index_built(vault)

    if not refresh_only:
        index_path = vault / "PROJECT_INDEX.md"
        projects_dir = vault / "projects"
        count = sum(1 for p in projects_dir.iterdir() if p.is_dir()) if projects_dir.exists() else 0

        print(f"\nContextOS Projects\n{'=' * 18}\n")
        print(f"  Vault path:       {vault}")
        print(f"  Projects indexed: {count}")
        print(f"  Project index:    {index_path}\n")

        if index_path.exists():
            print(index_path.read_text(encoding="utf-8", errors="ignore"))
