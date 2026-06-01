"""Diagnostics and auto-repair."""

import json
import os
import sys
from pathlib import Path

from . import __version__
from .vault import get_vault_path, get_settings_path


class DiagResult:
    def __init__(self):
        self.checks: list[tuple[str, str, str]] = []
        self.fixes: list[str] = []
        self.warn_count = 0
        self.fail_count = 0

    def ok(self, label: str, detail: str = ""):
        self.checks.append(("OK", label, detail))

    def warn(self, label: str, detail: str = ""):
        self.checks.append(("WARN", label, detail))
        self.warn_count += 1

    def fail(self, label: str, detail: str = "", fix: str = ""):
        self.checks.append(("FAIL", label, detail))
        self.fail_count += 1
        if fix:
            self.fixes.append(fix)

    def print(self):
        for status, label, detail in self.checks:
            if detail:
                print(f"  {status:5s} {label}: {detail}")
            else:
                print(f"  {status:5s} {label}")


def diagnose(auto_fix: bool = False) -> DiagResult:
    result = DiagResult()
    vault = get_vault_path()
    settings = get_settings_path()

    print(f"\nContextOS Doctor v{__version__}")
    print("=" * 30)

    # Vault
    print("\nVault")
    print("-" * 20)
    result.ok("Vault path", str(vault))
    for name in ["", "projects", "scripts", "context-packs", "debug", "inbox"]:
        d = vault / name if name else vault
        label = name or "vault root"
        if d.exists():
            result.ok(f"{label} exists")
        else:
            if auto_fix:
                d.mkdir(parents=True, exist_ok=True)
                result.ok(f"{label} exists", "auto-created")
            else:
                result.fail(f"{label} exists", str(d), fix=f"mkdir -p {d}")

    # Scripts
    print("\nScripts")
    print("-" * 20)
    scripts_dir = vault / "scripts"
    required = [
        "contextos-start.sh", "contextos-capture.sh", "contextos-status.sh",
        "contextos-projects.sh", "contextos-find.sh", "contextos-resume.sh",
        "contextos-open.sh", "contextos-doctor.sh", "process-session.py",
        "compress-project-memory.py", "contextos_index.py",
    ]
    for script in required:
        if (scripts_dir / script).exists():
            result.ok(script)
        else:
            result.fail(script, "Missing", fix="Rerun installer")

    # Python
    print("\nPython")
    print("-" * 20)
    import shutil
    py = shutil.which("python3")
    if py:
        result.ok("python3 available", py)
    else:
        result.fail("python3 available", "Not found", fix="Install Python 3")

    # tiktoken
    try:
        import tiktoken
        result.ok("tiktoken available", "Real token counting enabled")
    except ImportError:
        result.warn("tiktoken available", "Using chars/4 fallback. pip install tiktoken for accuracy")

    # Claude hooks
    print("\nClaude Hooks")
    print("-" * 20)
    if settings.exists():
        result.ok("Claude settings file", str(settings))
        try:
            cfg = json.loads(settings.read_text(encoding="utf-8"))
            hooks = cfg.get("hooks", {})
            for key in ["hooks", "SessionStart", "SessionEnd"]:
                if key == "hooks":
                    (result.ok if hooks else result.fail)(key, "present" if hooks else "missing")
                elif key in hooks:
                    result.ok(f"{key} hook")
                else:
                    result.fail(f"{key} hook", "Missing", fix="Merge settings snippet from installer")
            text = json.dumps(cfg)
            for script in ["contextos-start", "contextos-capture"]:
                if script in text:
                    result.ok(f"{script} in settings")
                else:
                    result.fail(f"{script} in settings", "Missing", fix="Merge settings snippet")
        except Exception as e:
            result.fail("Claude settings parse", str(e))
    else:
        result.fail("Claude settings file", str(settings), fix="Create settings.json with hooks")

    # Privacy
    print("\nPrivacy")
    print("-" * 20)
    if os.environ.get("CONTEXTOS_COPY_RAW_TRANSCRIPTS") == "true":
        result.warn("Raw transcript copying", "Enabled")
    else:
        result.ok("Raw transcript copying", "Disabled")

    # Cross-project
    print("\nCross-Project Memory")
    print("-" * 20)
    idx = vault / "PROJECT_INDEX.md"
    if idx.exists():
        result.ok("Project index", str(idx))
    else:
        if auto_fix:
            from .index import update_project_index
            update_project_index(vault)
            result.ok("Project index", "auto-created")
        else:
            result.warn("Project index", "Missing. Run: contextos projects")

    if os.environ.get("CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY") == "false":
        result.warn("Cross-project injection", "Disabled")
    else:
        result.ok("Cross-project injection", "Enabled")

    # Orphaned locks
    lock = vault / "PROJECT_INDEX.lock"
    if lock.exists():
        if auto_fix:
            lock.unlink(missing_ok=True)
            result.ok("Orphaned lock", "auto-removed")
        else:
            result.warn("Orphaned lock", str(lock))

    # Schema check
    print("\nSchema")
    print("-" * 20)
    projects_dir = vault / "projects"
    if projects_dir.exists():
        from .schema import needs_migration, migrate_project
        needs_update = []
        for p in projects_dir.iterdir():
            if p.is_dir() and needs_migration(p):
                needs_update.append(p.name)
        if needs_update:
            if auto_fix:
                for name in needs_update:
                    migrate_project(projects_dir / name)
                result.ok("Schema migration", f"Migrated {len(needs_update)} projects")
            else:
                result.warn("Schema migration needed", f"{len(needs_update)} projects. Run: contextos migrate")
        else:
            result.ok("Schema", "All projects at current version")

    # Results
    result.print()

    print("\nFixes" if result.fixes else "")
    if result.fixes:
        for fix in result.fixes:
            print(f"  - {fix}")

    print(f"\n{'FAIL' if result.fail_count else 'WARN' if result.warn_count else 'OK'}: ", end="")
    if result.fail_count:
        print("ContextOS is not correctly installed.")
    elif result.warn_count:
        print("ContextOS works, but improvements recommended.")
    else:
        print("ContextOS looks healthy.")

    return result


def cli_doctor(args: list[str] | None = None) -> None:
    auto_fix = "--fix" in (args or [])
    result = diagnose(auto_fix=auto_fix)
    sys.exit(1 if result.fail_count else 0)
