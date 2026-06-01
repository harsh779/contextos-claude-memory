"""Status display."""

import json
import os
import sys
from pathlib import Path

from . import __version__
from .tokens import count_tokens, using_tiktoken
from .vault import get_vault_path, get_settings_path


def cli_status(args: list[str] | None = None) -> None:
    args = args or []
    if "--version" in args or "-v" in args:
        print(f"ContextOS v{__version__}")
        return

    vault = get_vault_path()
    scripts_dir = vault / "scripts"
    projects_dir = vault / "projects"
    packs_dir = vault / "context-packs"
    settings = get_settings_path()

    required = [
        "contextos-start.sh", "contextos-capture.sh", "contextos-status.sh",
        "contextos-projects.sh", "contextos-find.sh", "contextos-resume.sh",
        "contextos-open.sh", "contextos-doctor.sh", "process-session.py",
        "compress-project-memory.py",
    ]
    missing = [s for s in required if not (scripts_dir / s).exists()]

    project_count = 0
    if projects_dir.exists():
        project_count = sum(1 for p in projects_dir.iterdir() if p.is_dir())

    pack_count = 0
    if packs_dir.exists():
        pack_count = sum(1 for p in packs_dir.glob("*.md"))

    token_total = 0
    if projects_dir.exists():
        for ts in projects_dir.rglob("TOKEN_SAVINGS.md"):
            text = ts.read_text(encoding="utf-8", errors="ignore")
            for line in text.splitlines():
                if "repeated context avoided:" in line.lower():
                    try:
                        token_total += int("".join(c for c in line.split(":")[-1] if c.isdigit()))
                    except ValueError:
                        pass

    raw_status = "Enabled" if os.environ.get("CONTEXTOS_COPY_RAW_TRANSCRIPTS") == "true" else "Disabled"
    cross_status = "Disabled" if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") == "false" else "Enabled"

    hooks_ok = session_start = session_end = False
    if settings.exists():
        try:
            cfg = json.loads(settings.read_text(encoding="utf-8"))
            hooks = cfg.get("hooks", {})
            hooks_ok = bool(hooks)
            session_start = "SessionStart" in hooks
            session_end = "SessionEnd" in hooks
        except Exception:
            pass

    last_project = "None"
    last_time = "None"
    if projects_dir.exists():
        events = sorted(projects_dir.rglob("*-event.json"), key=lambda p: p.stat().st_mtime, reverse=True)
        if events:
            last_time_ts = events[0].stat().st_mtime
            from datetime import datetime
            last_time = datetime.fromtimestamp(last_time_ts).strftime("%Y-%m-%d %H:%M:%S")
            last_project = events[0].parent.parent.name

    rows = [
        ("Version:", f"v{__version__}"),
        ("Token counter:", "tiktoken (cl100k_base)" if using_tiktoken() else "chars/4 estimate"),
        ("Vault path:", str(vault)),
        ("Vault exists:", "Yes" if vault.exists() else "No"),
        ("Scripts folder exists:", "Yes" if scripts_dir.exists() else "No"),
        ("Required scripts installed:", "Yes" if not missing else "No"),
        ("Projects tracked:", str(project_count)),
        ("Context packs created:", str(pack_count)),
        ("Estimated tokens avoided:", str(token_total)),
        ("Raw transcript copying:", raw_status),
        ("Cross-project memory:", cross_status),
        ("Project index exists:", "Yes" if (vault / "PROJECT_INDEX.md").exists() else "No"),
        ("Claude settings found:", "Yes" if settings.exists() else "No"),
        ("Hooks configured:", "Yes" if hooks_ok else "No"),
        ("SessionStart hook:", "Yes" if session_start else "No"),
        ("SessionEnd hook:", "Yes" if session_end else "No"),
        ("Last captured project:", last_project),
        ("Last capture time:", last_time),
    ]

    print(f"\nContextOS Status\n{'=' * 16}\n")
    for label, value in rows:
        print(f"  {label:<32s} {value}")

    if missing:
        print("\n  Missing scripts:")
        for s in missing:
            print(f"    - {s}")
    print()
