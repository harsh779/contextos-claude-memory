"""Startup caching — skip index rebuild if nothing changed."""

import json
from pathlib import Path
from .index import latest_memory_update


def _cache_path(vault: Path) -> Path:
    return vault / ".contextos-cache.json"


def _read_cache(vault: Path) -> dict:
    cp = _cache_path(vault)
    if not cp.exists():
        return {}
    try:
        return json.loads(cp.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _write_cache(vault: Path, data: dict) -> None:
    _cache_path(vault).write_text(json.dumps(data), encoding="utf-8")


def index_is_stale(vault: Path) -> bool:
    cache = _read_cache(vault)
    last_build = cache.get("last_index_build", 0)

    projects_dir = vault / "projects"
    if not projects_dir.exists():
        return True

    for project in projects_dir.iterdir():
        if not project.is_dir():
            continue
        if latest_memory_update(project) > last_build:
            return True

    return False


def mark_index_built(vault: Path) -> None:
    import time
    cache = _read_cache(vault)
    cache["last_index_build"] = time.time()
    _write_cache(vault, cache)
