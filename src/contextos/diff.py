"""Memory diff for ContextOS projects."""

from __future__ import annotations

import argparse
import difflib
import json
from datetime import datetime, timezone
from pathlib import Path

TRACKED_FILES = ["PROJECT_CONTEXT.md", "DECISIONS.md", "NEXT_ACTIONS.md"]


def _latest_snapshot(sessions_dir: Path) -> dict[str, str] | None:
    """Find and load the most recent snapshot JSON from sessions/."""
    if not sessions_dir.is_dir():
        return None

    snapshots = sorted(sessions_dir.glob("*-snapshot.json"))
    if not snapshots:
        return None

    with snapshots[-1].open("r", encoding="utf-8") as f:
        return json.load(f)


def save_snapshot(project_dir: Path) -> Path:
    """Save a snapshot of tracked memory files into sessions/.

    Returns the path to the created snapshot file.
    """
    sessions_dir = project_dir / "sessions"
    sessions_dir.mkdir(exist_ok=True)

    snapshot: dict[str, str] = {}
    for name in TRACKED_FILES:
        fpath = project_dir / name
        if fpath.is_file():
            snapshot[name] = fpath.read_text(encoding="utf-8")

    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = sessions_dir / f"{ts}-snapshot.json"
    with out.open("w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2)

    return out


def diff_project(vault_path: Path, project_name: str) -> str:
    """Show what changed in project memory since last session.

    Compare current PROJECT_CONTEXT.md, DECISIONS.md, NEXT_ACTIONS.md
    against snapshots stored in sessions/ (the latest *-snapshot.json).

    Uses difflib.unified_diff for the actual diff.
    If no previous snapshot exists, returns "No previous session found."

    Returns formatted diff string with headers.
    """
    project_dir = vault_path / project_name
    if not project_dir.is_dir():
        return f"Project '{project_name}' not found in vault."

    sessions_dir = project_dir / "sessions"
    old_snapshot = _latest_snapshot(sessions_dir)

    if old_snapshot is None:
        return "No previous session found."

    parts: list[str] = []

    for name in TRACKED_FILES:
        old_content = old_snapshot.get(name, "")
        current_path = project_dir / name
        new_content = current_path.read_text(encoding="utf-8") if current_path.is_file() else ""

        if old_content == new_content:
            continue

        diff_lines = list(
            difflib.unified_diff(
                old_content.splitlines(keepends=True),
                new_content.splitlines(keepends=True),
                fromfile=f"a/{name}",
                tofile=f"b/{name}",
            )
        )
        if diff_lines:
            parts.append("".join(diff_lines))

    if not parts:
        return "No changes since last session."

    return "\n".join(parts)


def cli_diff(args: list[str]) -> None:
    """CLI: contextos diff <project-name>"""
    parser = argparse.ArgumentParser(prog="contextos diff", description="Show memory changes since last session")
    parser.add_argument("vault", type=Path, help="Path to the ContextOS vault")
    parser.add_argument("project", type=str, help="Project name to diff")
    parsed = parser.parse_args(args)

    output = diff_project(parsed.vault, parsed.project)
    print(output)
