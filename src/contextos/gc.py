"""Garbage collection for ContextOS vaults."""

from __future__ import annotations

import argparse
import shutil
import time
from pathlib import Path


def gc(vault_path: Path, dry_run: bool = False, stale_days: int = 90) -> dict:
    """Clean up stale project memory.

    - Remove debug files older than 7 days
    - Compress session logs over 30KB (move to archives/)
    - Report stale projects (no updates in stale_days) but don't delete them
    - Remove orphaned .lock files

    Returns {"debug_removed": int, "logs_compressed": int, "stale_projects": list[str], "bytes_freed": int}
    """
    result = {
        "debug_removed": 0,
        "logs_compressed": 0,
        "stale_projects": [],
        "bytes_freed": 0,
    }

    if not vault_path.is_dir():
        return result

    now = time.time()
    seven_days = 7 * 86400
    stale_seconds = stale_days * 86400
    size_threshold = 30 * 1024  # 30KB

    for project_dir in vault_path.iterdir():
        if not project_dir.is_dir():
            continue

        # --- Track latest mtime across the project ---
        latest_mtime = 0.0

        # --- Remove debug files older than 7 days ---
        for debug_file in project_dir.rglob("*debug*"):
            if not debug_file.is_file():
                continue
            age = now - debug_file.stat().st_mtime
            if age > seven_days:
                size = debug_file.stat().st_size
                if not dry_run:
                    debug_file.unlink()
                result["debug_removed"] += 1
                result["bytes_freed"] += size

        # --- Compress session logs over 30KB ---
        sessions_dir = project_dir / "sessions"
        if sessions_dir.is_dir():
            archives_dir = sessions_dir / "archives"
            for log_file in sessions_dir.iterdir():
                if not log_file.is_file():
                    continue
                stat = log_file.stat()
                if stat.st_mtime > latest_mtime:
                    latest_mtime = stat.st_mtime
                if stat.st_size > size_threshold:
                    if not dry_run:
                        archives_dir.mkdir(exist_ok=True)
                        shutil.move(str(log_file), str(archives_dir / log_file.name))
                    result["logs_compressed"] += 1
                    # No bytes freed — moved, not deleted

        # --- Remove orphaned .lock files ---
        for lock_file in project_dir.rglob("*.lock"):
            if not lock_file.is_file():
                continue
            size = lock_file.stat().st_size
            if not dry_run:
                lock_file.unlink()
            result["bytes_freed"] += size

        # --- Check project staleness ---
        # Scan all files for latest mtime if sessions didn't cover it
        for f in project_dir.rglob("*"):
            if f.is_file():
                mt = f.stat().st_mtime
                if mt > latest_mtime:
                    latest_mtime = mt

        if latest_mtime > 0 and (now - latest_mtime) > stale_seconds:
            result["stale_projects"].append(project_dir.name)

    return result


def cli_gc(args: list[str]) -> None:
    """CLI: contextos gc [--dry-run] [--stale-days N]"""
    parser = argparse.ArgumentParser(prog="contextos gc", description="Garbage-collect stale project memory")
    parser.add_argument("vault", type=Path, help="Path to the ContextOS vault")
    parser.add_argument("--dry-run", action="store_true", help="Report what would be done without changing anything")
    parser.add_argument("--stale-days", type=int, default=90, help="Days without updates before a project is considered stale (default: 90)")
    parsed = parser.parse_args(args)

    result = gc(parsed.vault, dry_run=parsed.dry_run, stale_days=parsed.stale_days)

    prefix = "[DRY RUN] " if parsed.dry_run else ""
    print(f"{prefix}Debug files removed: {result['debug_removed']}")
    print(f"{prefix}Session logs compressed: {result['logs_compressed']}")
    print(f"{prefix}Bytes freed: {result['bytes_freed']}")
    if result["stale_projects"]:
        print(f"{prefix}Stale projects (>{parsed.stale_days} days):")
        for name in result["stale_projects"]:
            print(f"  - {name}")
    else:
        print(f"{prefix}No stale projects found.")
