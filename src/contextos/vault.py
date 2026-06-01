"""Vault path resolution and constants."""

import os
from pathlib import Path

SCHEMA_VERSION = 2

def get_vault_path() -> Path:
    configured = os.environ.get("CONTEXTOS_VAULT_PATH")
    if configured and configured.strip():
        return Path(configured.strip()).expanduser()
    return Path.home() / "AI-Memory-Vault"


def get_project_dir(vault: Path, project_name: str) -> Path:
    return vault / "projects" / project_name


def get_settings_path() -> Path:
    return Path.home() / ".claude" / "settings.json"


MEMORY_FILES = [
    "PROJECT_CONTEXT.md",
    "DECISIONS.md",
    "NEXT_ACTIONS.md",
    "SESSION_LOG.md",
    "graph.mmd",
]

DEFAULT_TEMPLATES = {
    "PROJECT_CONTEXT.md": "# Project Context: {name}\n\n## Purpose\nAuto-created by ContextOS.\n\n## Current Status\nNew project memory created automatically.\n\n## Working Directory\n{cwd}\n\n## Active Context Pack\nUse SESSION_LOG.md, DECISIONS.md, NEXT_ACTIONS.md, and graph.mmd for continuity.\n",
    "DECISIONS.md": "# Decisions: {name}\n\n- No locked decisions captured yet.\n",
    "NEXT_ACTIONS.md": "# Next Actions: {name}\n\n1. Inspect current repo/project state.\n2. Identify active goal.\n3. Continue from latest Claude Code session context.\n",
    "SESSION_LOG.md": "# Session Log: {name}\n\n",
    "graph.mmd": "graph TD\n    A[{name}] --> B[Sessions]\n    A --> C[Decisions]\n    A --> D[Next Actions]\n    A --> E[Project Context]\n",
}
