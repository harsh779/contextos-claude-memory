"""Behavioral guidelines template management."""

import shutil
import sys
from pathlib import Path


def _guidelines_source() -> Path:
    return Path(__file__).resolve().parent.parent.parent / "CLAUDE_GUIDELINES.md"


def cli_init_guidelines(args: list[str] | None = None) -> None:
    target = Path.cwd() / "CLAUDE.md"
    source = _guidelines_source()

    if not source.exists():
        print(f"Guidelines template not found at {source}")
        sys.exit(1)

    if target.exists():
        print(f"CLAUDE.md already exists at {target}")
        print("To append guidelines, run: cat CLAUDE_GUIDELINES.md >> CLAUDE.md")
        sys.exit(1)

    shutil.copy2(source, target)
    print(f"Created {target} with ContextOS behavioral guidelines.")
    print("Edit to add project-specific rules.")
