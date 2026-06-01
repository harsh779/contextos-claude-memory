"""Tests for contextos.schema — versioning and migration."""

from contextos.schema import get_file_version, needs_migration, migrate_project


class TestGetFileVersion:
    def test_legacy_file_returns_1(self, tmp_path):
        f = tmp_path / "DECISIONS.md"
        f.write_text("# Decisions\n\n- Use Redis\n")
        assert get_file_version(f) == 1

    def test_v2_file_returns_2(self, tmp_path):
        f = tmp_path / "DECISIONS.md"
        f.write_text("<!-- contextos-schema: 2 -->\n# Decisions\n\n- Use Redis\n")
        assert get_file_version(f) == 2

    def test_nonexistent_returns_current(self, tmp_path):
        from contextos.schema import CURRENT_VERSION
        assert get_file_version(tmp_path / "nope.md") == CURRENT_VERSION


class TestNeedsMigration:
    def test_detects_legacy(self, tmp_path):
        (tmp_path / "DECISIONS.md").write_text("# Decisions\n- old\n")
        assert needs_migration(tmp_path) is True

    def test_no_migration_needed(self, tmp_path):
        (tmp_path / "DECISIONS.md").write_text("<!-- contextos-schema: 2 -->\n# D\n")
        (tmp_path / "NEXT_ACTIONS.md").write_text("<!-- contextos-schema: 2 -->\n# N\n")
        (tmp_path / "PROJECT_CONTEXT.md").write_text("<!-- contextos-schema: 2 -->\n# P\n")
        assert needs_migration(tmp_path) is False


class TestMigrateProject:
    def test_adds_version_headers(self, tmp_path):
        (tmp_path / "DECISIONS.md").write_text("# Decisions\n\n- Use Redis\n")
        (tmp_path / "NEXT_ACTIONS.md").write_text("# Next\n\n- Deploy\n")
        (tmp_path / "PROJECT_CONTEXT.md").write_text("# Context\n")
        actions = migrate_project(tmp_path)
        assert len(actions) > 0
        assert get_file_version(tmp_path / "DECISIONS.md") == 2
        assert get_file_version(tmp_path / "NEXT_ACTIONS.md") == 2

    def test_idempotent(self, tmp_path):
        (tmp_path / "DECISIONS.md").write_text("<!-- contextos-schema: 2 -->\n# D\n")
        actions = migrate_project(tmp_path)
        assert actions == []
