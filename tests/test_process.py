"""Tests for contextos.process — noise detection, classification, summarization."""

from contextos.process import is_noise, clean_text, classify_candidates, make_summary


class TestIsNoise:
    def test_catches_empty(self):
        assert is_noise("") is True

    def test_catches_short(self):
        assert is_noise("hi") is True

    def test_catches_noise_pattern(self):
        assert is_noise("ContextOS hook loaded successfully") is True

    def test_catches_header(self):
        assert is_noise("# Some heading text here") is True

    def test_catches_caveman(self):
        assert is_noise("Default: **full** /caveman") is True

    def test_passes_valid_decision(self):
        assert is_noise("Use PostgreSQL for all database operations") is False

    def test_passes_valid_action(self):
        assert is_noise("Deploy the staging environment tonight") is False

    def test_catches_too_long(self):
        assert is_noise("x" * 501) is True


class TestCleanText:
    def test_normalizes_whitespace(self):
        assert clean_text("  hello   world  ") == "hello world"

    def test_replaces_bullet_char(self):
        assert clean_text("• item one") == "- item one"


class TestClassifyCandidates:
    def test_extracts_decisions(self):
        items = ["Decision: use PostgreSQL for persistence"]
        result = classify_candidates(items)
        assert len(result["decisions"]) > 0
        assert "PostgreSQL" in result["decisions"][0]["text"]

    def test_extracts_actions(self):
        items = ["Next action: deploy to staging environment"]
        result = classify_candidates(items)
        assert len(result["actions"]) > 0

    def test_extracts_blockers(self):
        items = ["Build failed on the CI pipeline again"]
        result = classify_candidates(items)
        assert len(result["blockers"]) > 0

    def test_empty_input(self):
        result = classify_candidates([])
        assert result["decisions"] == []
        assert result["actions"] == []
        assert result["blockers"] == []


class TestMakeSummary:
    def test_returns_bullet_list(self):
        items = ["First important thing to note", "Second important thing to note"]
        result = make_summary(items)
        assert result.startswith("- ")
        assert "First important thing" in result

    def test_empty_items(self):
        result = make_summary([])
        assert "No useful summary" in result
