"""Main CLI entry point for ContextOS."""

import sys

from . import __version__

COMMANDS = {
    "status": "Show ContextOS status",
    "doctor": "Run diagnostics (--fix to auto-repair)",
    "projects": "Refresh and display project index",
    "find": "Search project memory (TF-IDF)",
    "resume": "Create resume pack for a project",
    "open": "Open project memory folder",
    "gc": "Garbage collect stale data (--dry-run)",
    "diff": "Show memory changes since last session",
    "migrate": "Migrate project schemas to current version",
    "init-guidelines": "Create CLAUDE.md with behavioral guidelines",
    "start": "SessionStart hook (internal)",
    "capture": "SessionEnd hook (internal)",
}


def main() -> None:
    args = sys.argv[1:]

    if not args or args[0] in ("-h", "--help"):
        print(f"ContextOS v{__version__} — local memory layer for Claude Code\n")
        print("Usage: contextos <command> [args]\n")
        print("Commands:")
        for cmd, desc in COMMANDS.items():
            print(f"  {cmd:<20s} {desc}")
        print(f"\n  --version            Show version")
        return

    if args[0] in ("--version", "-v"):
        print(f"ContextOS v{__version__}")
        return

    cmd = args[0]
    cmd_args = args[1:]

    if cmd == "status":
        from .status import cli_status
        cli_status(cmd_args)
    elif cmd == "doctor":
        from .doctor import cli_doctor
        cli_doctor(cmd_args)
    elif cmd == "projects":
        from .projects import cli_projects
        cli_projects(cmd_args)
    elif cmd == "find":
        from .search import cli_search
        cli_search(cmd_args)
    elif cmd == "resume":
        from .resume import cli_resume
        cli_resume(cmd_args)
    elif cmd == "open":
        from .open_project import cli_open
        cli_open(cmd_args)
    elif cmd == "gc":
        from .gc import cli_gc
        cli_gc(cmd_args)
    elif cmd == "diff":
        from .diff import cli_diff
        cli_diff(cmd_args)
    elif cmd == "migrate":
        from .schema import cli_migrate
        cli_migrate(cmd_args)
    elif cmd == "init-guidelines":
        from .guidelines import cli_init_guidelines
        cli_init_guidelines(cmd_args)
    elif cmd == "start":
        from .start import run_start
        run_start()
    elif cmd == "capture":
        from .capture import run_capture
        run_capture()
    else:
        print(f"Unknown command: {cmd}")
        print(f"Run 'contextos --help' for available commands.")
        sys.exit(1)


if __name__ == "__main__":
    main()
