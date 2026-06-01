"""Tests for contextos.confidence — confidence scoring."""

from contextos.confidence import Confidence, score_item, score_items


class TestScoreDecision:
    def test_high_for_explicit_decision(self):
        assert score_item("Decision: use PostgreSQL for all persistence") == Confidence.HIGH

    def test_medium_for_body_signal(self):
        assert score_item("must validate input") == Confidence.MEDIUM

    def test_low_for_vague(self):
        assert score_item("maybe try something") == Confidence.LOW

    def test_high_for_locked(self):
        assert score_item("Locked: API schema frozen until v2") == Confidence.HIGH

    def test_medium_for_required(self):
        assert score_item("auth token required for all endpoints") == Confidence.MEDIUM


class TestScoreAction:
    def test_high_for_explicit_action(self):
        assert score_item("Next action: deploy to staging", "action") == Confidence.HIGH

    def test_high_for_verb_plus_target(self):
        assert score_item("fix /src/auth/login.py", "action") == Confidence.HIGH

    def test_medium_for_verb_only(self):
        assert score_item("fix the broken tests", "action") == Confidence.MEDIUM

    def test_low_for_no_signals(self):
        assert score_item("something about later", "action") == Confidence.LOW


class TestScoreItems:
    def test_returns_list_of_dicts(self):
        result = score_items(["Decision: use Redis", "maybe later"], "decision")
        assert len(result) == 2
        assert all("text" in r and "confidence" in r for r in result)
        assert result[0]["confidence"] == Confidence.MEDIUM
        assert result[1]["confidence"] == Confidence.LOW
