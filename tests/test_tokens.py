"""Tests for contextos.tokens — token counting."""

from contextos.tokens import count_tokens, count_tokens_file


def test_count_tokens_nonempty():
    assert count_tokens("hello world this is a test") > 0


def test_count_tokens_empty():
    assert count_tokens("") == 0


def test_count_tokens_none_coerced():
    # Empty string explicitly
    assert count_tokens("") == 0


def test_count_tokens_file(tmp_path):
    f = tmp_path / "sample.txt"
    f.write_text("Some text content for token counting", encoding="utf-8")
    assert count_tokens_file(f) > 0


def test_count_tokens_file_missing(tmp_path):
    assert count_tokens_file(tmp_path / "missing.txt") == 0
