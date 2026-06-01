"""Tests for contextos.index — normalize, noise detection, project index."""

from pathlib import Path
from contextos.index import (
    normalize_index_line,
    is_index_noise,
    clean_project_context_lines,
    update_project_index,
)


class TestNormalizeIndexLine:
    def test_strips_bullet(self):
        assert normalize_index_line("- Deploy to prod") == "Deploy to prod"

    def test_strips_star_bullet(self):
        assert normalize_index_line("* Fix the bug") == "Fix the bug"

    def test_strips_numbered(self):
        assert normalize_index_line("1. First item") == "First item"

    def test_strips_decision_prefix(self):
        assert normalize_index_line("Decision: use Redis") == "use Redis"

    def test_strips_todo_prefix(self):
        assert normalize_index_line("todo: write tests") == "write tests"

    def test_plain_text_unchanged(self):
        assert normalize_index_line("plain text") == "plain text"


class TestIsIndexNoise:
    def test_catches_can_you(self):
        assert is_index_noise("can you fix this?") is True

    def test_catches_let_me(self):
        assert is_index_noise("let me check that") is True

    def test_catches_auto_created(self):
        assert is_index_noise("auto-created by contextos") is True

    def test_catches_empty(self):
        assert is_index_noise("") is True

    def test_catches_header(self):
        assert is_index_noise("# Some Header") is True

    def test_passes_database_signal(self):
        assert is_index_noise("Database can handle 10k connections") is False

    def test_passes_deploy_failed(self):
        assert is_index_noise("Deploy failed on staging env") is False

    def test_passes_legit_decision(self):
        assert is_index_noise("Use PostgreSQL for all persistence layers") is False


class TestCleanProjectContextLines:
    def test_stops_at_auto_captured(self, tmp_path):
        f = tmp_path / "ctx.md"
        f.write_text(
            "Important context line\nAnother line\n"
            "## Latest Auto-Captured Status\nShould not appear\n"
        )
        lines = clean_project_context_lines(f, max_lines=5)
        assert "Should not appear" not in lines
        assert "Important context line" in lines

    def test_returns_empty_for_missing(self, tmp_path):
        assert clean_project_context_lines(tmp_path / "nope.md") == []


class TestUpdateProjectIndex:
    def test_creates_index_file(self, tmp_vault, sample_project):
        path = update_project_index(tmp_vault)
        assert path.exists()
        content = path.read_text()
        assert "test-project" in content
        assert "# ContextOS Project Index" in content

    def test_empty_vault(self, tmp_vault):
        path = update_project_index(tmp_vault)
        assert "No projects tracked yet." in path.read_text()
