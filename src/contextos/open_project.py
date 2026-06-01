"""Open project memory folder."""

import subprocess
import shutil
import sys

from .vault import get_vault_path


def cli_open(args: list[str] | None = None) -> None:
    if not args:
        print("Usage: contextos open <project-name>")
        sys.exit(1)

    project_name = args[0]
    vault = get_vault_path()
    project_dir = vault / "projects" / project_name

    if not project_dir.is_dir():
        print(f"Project not found: {project_name}\n\nAvailable projects:")
        projects_dir = vault / "projects"
        if projects_dir.exists():
            for p in sorted(projects_dir.iterdir()):
                if p.is_dir():
                    print(f"  {p.name}")
        sys.exit(1)

    if shutil.which("open"):
        subprocess.run(["open", str(project_dir)], check=False)
        print(f"Opened ContextOS project folder:\n{project_dir}")
    elif shutil.which("xdg-open"):
        subprocess.run(["xdg-open", str(project_dir)], check=False)
        print(f"Opened ContextOS project folder:\n{project_dir}")
    else:
        print(f"ContextOS project folder:\n{project_dir}")
