"""Tests for contextos.cache — index staleness and cache marking."""

from contextos.cache import index_is_stale, mark_index_built


class TestIndexCache:
    def test_stale_when_no_cache(self, tmp_vault, sample_project):
        assert index_is_stale(tmp_vault) is True

    def test_fresh_after_mark(self, tmp_vault, sample_project):
        mark_index_built(tmp_vault)
        assert index_is_stale(tmp_vault) is False

    def test_mark_creates_cache_file(self, tmp_vault):
        mark_index_built(tmp_vault)
        assert (tmp_vault / ".contextos-cache.json").exists()

    def test_stale_after_file_update(self, tmp_vault, sample_project):
        mark_index_built(tmp_vault)
        assert index_is_stale(tmp_vault) is False
        # Touch a memory file to make it newer than cache
        import time
        time.sleep(0.05)
        (sample_project / "DECISIONS.md").write_text("# Updated\n- new decision\n")
        assert index_is_stale(tmp_vault) is True
