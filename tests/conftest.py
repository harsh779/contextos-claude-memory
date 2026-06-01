"""Shared fixtures for ContextOS tests."""

import pytest
from pathlib import Path

VAULT_DIRS = ["projects", "scripts", "context-packs", "debug", "inbox"]

MEMORY_FILES = {
    "PROJECT_CONTEXT.md": "# Project Context: {name}\n\nWorking directory: /tmp/test\n",
    "DECISIONS.md": "# Decisions: {name}\n\n- Use PostgreSQL for persistence\n",
    "NEXT_ACTIONS.md": "# Next Actions: {name}\n\n1. Set up CI pipeline\n",
    "SESSION_LOG.md": "# Session Log: {name}\n",
    "graph.mmd": "graph TD\n    B[Base]\n",
}


@pytest.fixture
def tmp_vault(tmp_path):
    """Create a temporary vault with standard directory structure."""
    vault = tmp_path / "vault"
    for d in VAULT_DIRS:
        (vault / d).mkdir(parents=True)
    return vault


@pytest.fixture
def sample_project(tmp_vault):
    """Create a sample project within tmp_vault with all default memory files."""
    project = tmp_vault / "projects" / "test-project"
    project.mkdir(parents=True)
    for filename, template in MEMORY_FILES.items():
        (project / filename).write_text(template.format(name="test-project"), encoding="utf-8")
    return project
