"""Tests for contextos.search — TF-IDF search over vault."""

from contextos.search import search


def _make_project(vault, name, files):
    proj = vault / "projects" / name
    proj.mkdir(parents=True)
    for fname, content in files.items():
        (proj / fname).write_text(content, encoding="utf-8")


class TestSearch:
    def test_returns_correct_keys(self, tmp_vault):
        _make_project(tmp_vault, "alpha", {
            "DECISIONS.md": "Use PostgreSQL for the database layer",
        })
        results = search(tmp_vault, "PostgreSQL database")
        assert len(results) > 0
        r = results[0]
        assert set(r.keys()) == {"score", "project", "file", "match", "path"}

    def test_ranks_relevant_higher(self, tmp_vault):
        _make_project(tmp_vault, "relevant", {
            "DECISIONS.md": "PostgreSQL is the primary database for all services",
        })
        _make_project(tmp_vault, "unrelated", {
            "DECISIONS.md": "The sky is blue and grass is green",
        })
        results = search(tmp_vault, "PostgreSQL database")
        assert results[0]["project"] == "relevant"

    def test_empty_for_no_matches(self, tmp_vault):
        _make_project(tmp_vault, "proj", {
            "DECISIONS.md": "Use Redis for caching",
        })
        results = search(tmp_vault, "xyznonexistent")
        assert results == []

    def test_empty_vault(self, tmp_vault):
        results = search(tmp_vault, "anything")
        assert results == []
