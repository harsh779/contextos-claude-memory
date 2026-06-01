"""Tests for contextos.session_log — JSONL append, read, render, compact."""

from contextos.session_log import append_session, read_sessions, render_markdown, compact


class TestAppendAndRead:
    def test_append_creates_file(self, tmp_path):
        append_session(tmp_path, {"event": "stop", "summary": "test run"})
        assert (tmp_path / "sessions.jsonl").exists()

    def test_read_returns_appended_data(self, tmp_path):
        append_session(tmp_path, {"event": "stop", "summary": "first"})
        append_session(tmp_path, {"event": "stop", "summary": "second"})
        sessions = read_sessions(tmp_path)
        assert len(sessions) == 2
        assert sessions[0]["summary"] == "first"
        assert sessions[1]["summary"] == "second"

    def test_read_last_n(self, tmp_path):
        for i in range(5):
            append_session(tmp_path, {"event": "stop", "n": i})
        assert len(read_sessions(tmp_path, last_n=2)) == 2

    def test_read_empty(self, tmp_path):
        assert read_sessions(tmp_path) == []


class TestRenderMarkdown:
    def test_produces_valid_markdown(self, tmp_path):
        append_session(tmp_path, {
            "time": "2025-01-01 12:00:00",
            "event": "stop",
            "session_id": "abc",
            "cwd": "/tmp",
            "summary": "Did stuff",
        })
        md = render_markdown(tmp_path)
        assert "# Session Log:" in md
        assert "## Session Capsule" in md
        assert "Did stuff" in md


class TestCompact:
    def test_keeps_last_n(self, tmp_path):
        for i in range(10):
            append_session(tmp_path, {"n": i})
        removed = compact(tmp_path, keep_last=3)
        assert removed == 7
        assert len(read_sessions(tmp_path)) == 3

    def test_noop_when_under_limit(self, tmp_path):
        append_session(tmp_path, {"n": 0})
        assert compact(tmp_path, keep_last=5) == 0
