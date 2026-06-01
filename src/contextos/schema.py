"""Schema versioning and migration for ContextOS memory files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

CURRENT_VERSION = 2

VERSION_HEADER_RE = re.compile(r"^<!--\s*contextos-schema:\s*(\d+)\s*-->")

MEMORY_FILES = ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md"]


def get_file_version(path: Path) -> int:
    """Read version from file header. Returns 1 if no version header found (legacy)."""
    if not path.is_file():
        return CURRENT_VERSION  # non-existent files don't need migration

    first_line = ""
    with path.open("r", encoding="utf-8") as f:
        first_line = f.readline()

    m = VERSION_HEADER_RE.match(first_line.strip())
    if m:
        return int(m.group(1))
    return 1  # legacy


def needs_migration(project_dir: Path) -> bool:
    """Check if any memory files need migration."""
    for name in MEMORY_FILES:
        fpath = project_dir / name
        if fpath.is_file() and get_file_version(fpath) < CURRENT_VERSION:
            return True
    return False


def _normalize_decisions(content: str) -> str:
    """Ensure DECISIONS.md uses bullet list format.

    Converts numbered lists or bare lines into '- ' prefixed bullets.
    Preserves blank lines and headers.
    """
    lines = content.splitlines()
    out: list[str] = []
    for line in lines:
        stripped = line.strip()
        # Skip blanks and headers
        if not stripped or stripped.startswith("#") or stripped.startswith("<!--"):
            out.append(line)
            continue
        # Already a bullet
        if stripped.startswith("- ") or stripped.startswith("* "):
            out.append(line)
            continue
        # Numbered list: "1. something" or "1) something"
        m = re.match(r"^\d+[.)]\s+(.*)", stripped)
        if m:
            out.append(f"- {m.group(1)}")
            continue
        # Bare text line — make it a bullet
        out.append(f"- {stripped}")
    return "\n".join(out)


def _normalize_next_actions(content: str) -> str:
    """Ensure NEXT_ACTIONS.md uses numbered list format.

    Converts bullet lists or bare lines into numbered items.
    Preserves blank lines and headers.
    """
    lines = content.splitlines()
    out: list[str] = []
    counter = 0
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped.startswith("<!--"):
            out.append(line)
            continue
        # Already numbered
        if re.match(r"^\d+[.)]\s+", stripped):
            counter += 1
            text = re.sub(r"^\d+[.)]\s+", "", stripped)
            out.append(f"{counter}. {text}")
            continue
        # Bullet
        if stripped.startswith("- ") or stripped.startswith("* "):
            counter += 1
            out.append(f"{counter}. {stripped[2:]}")
            continue
        # Bare text
        counter += 1
        out.append(f"{counter}. {stripped}")
    return "\n".join(out)


def _add_version_header(content: str, version: int) -> str:
    """Prepend version header, replacing existing one if present."""
    header = f"<!-- contextos-schema: {version} -->"
    # Remove existing header if present
    if VERSION_HEADER_RE.match(content.split("\n", 1)[0].strip()):
        _, rest = content.split("\n", 1)
        return f"{header}\n{rest}"
    return f"{header}\n{content}"


def migrate_project(project_dir: Path) -> list[str]:
    """Migrate project memory files to current schema version.

    v1 -> v2 changes:
    - Add '<!-- contextos-schema: 2 -->' header to all .md files
    - Normalize DECISIONS.md format (ensure bullet list)
    - Normalize NEXT_ACTIONS.md format (ensure numbered list)

    Returns list of actions taken.
    """
    actions: list[str] = []

    for name in MEMORY_FILES:
        fpath = project_dir / name
        if not fpath.is_file():
            continue

        version = get_file_version(fpath)
        if version >= CURRENT_VERSION:
            continue

        content = fpath.read_text(encoding="utf-8")
        new_content = content

        if version < 2:
            # Normalize format based on file type
            if name == "DECISIONS.md":
                new_content = _normalize_decisions(new_content)
                actions.append(f"{name}: normalized to bullet list format")
            elif name == "NEXT_ACTIONS.md":
                new_content = _normalize_next_actions(new_content)
                actions.append(f"{name}: normalized to numbered list format")

            # Add version header
            new_content = _add_version_header(new_content, CURRENT_VERSION)
            actions.append(f"{name}: added schema version {CURRENT_VERSION} header")

        fpath.write_text(new_content, encoding="utf-8")

    return actions


def cli_migrate(args: list[str]) -> None:
    """CLI: contextos migrate [project-name]
    If no project specified, migrate all projects.
    """
    parser = argparse.ArgumentParser(prog="contextos migrate", description="Migrate memory files to current schema")
    parser.add_argument("vault", type=Path, help="Path to the ContextOS vault")
    parser.add_argument("project", nargs="?", default=None, help="Project name (omit to migrate all)")
    parsed = parser.parse_args(args)

    vault = parsed.vault
    if not vault.is_dir():
        print(f"Vault not found: {vault}")
        return

    if parsed.project:
        project_dir = vault / parsed.project
        if not project_dir.is_dir():
            print(f"Project not found: {parsed.project}")
            return
        dirs = [project_dir]
    else:
        dirs = [d for d in vault.iterdir() if d.is_dir()]

    total = 0
    for project_dir in dirs:
        if not needs_migration(project_dir):
            continue
        actions = migrate_project(project_dir)
        if actions:
            print(f"{project_dir.name}:")
            for a in actions:
                print(f"  - {a}")
            total += len(actions)

    if total == 0:
        print("All projects are up to date.")
    else:
        print(f"\n{total} migration action(s) completed.")
