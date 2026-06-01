"""Session log compression."""

import re
from datetime import datetime
from pathlib import Path


def split_capsules(text: str) -> list[str]:
    parts = re.split(r"\n---\n\n## Session Capsule", text)
    if len(parts) <= 1:
        return []
    return ["---\n\n## Session Capsule" + part for part in parts[1:]]


def compress_project(project_dir: Path, threshold: int = 30000) -> str | None:
    session_log = project_dir / "SESSION_LOG.md"
    archive_dir = project_dir / "archives"

    if not session_log.exists():
        return None

    if session_log.stat().st_size <= threshold:
        return None

    archive_dir.mkdir(parents=True, exist_ok=True)
    now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    archive_file = archive_dir / f"SESSION_LOG_ARCHIVE_{now}.md"

    original = session_log.read_text(encoding="utf-8", errors="ignore")
    archive_file.write_text(original, encoding="utf-8")

    capsules = split_capsules(original)
    latest = capsules[-3:] if capsules else []
    project_name = project_dir.name

    fresh = f"# Session Log: {project_name}\n\nOlder session log archived here:\n\n{archive_file}\n\nCompression time: {now}\n\n"
    if latest:
        fresh += "\n\n".join(latest)
    else:
        fresh += "\nNo recent session capsules found during compression.\n"

    session_log.write_text(fresh, encoding="utf-8")
    return str(archive_file)
