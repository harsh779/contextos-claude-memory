"""Append-only JSONL session log with markdown rendering."""

import json
from datetime import datetime
from pathlib import Path


def append_session(project_dir: Path, capsule: dict) -> None:
    """Append a session capsule to the JSONL log."""
    jsonl_path = project_dir / "sessions.jsonl"
    capsule["_ts"] = datetime.now().isoformat()
    with jsonl_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(capsule, ensure_ascii=False) + "\n")


def read_sessions(project_dir: Path, last_n: int | None = None) -> list[dict]:
    jsonl_path = project_dir / "sessions.jsonl"
    if not jsonl_path.exists():
        return []
    sessions = []
    for line in jsonl_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        try:
            sessions.append(json.loads(line))
        except Exception:
            continue
    if last_n is not None:
        sessions = sessions[-last_n:]
    return sessions


def render_markdown(project_dir: Path) -> str:
    """Render JSONL sessions to SESSION_LOG.md format."""
    sessions = read_sessions(project_dir)
    project_name = project_dir.name
    lines = [f"# Session Log: {project_name}\n"]

    for s in sessions:
        lines.append("\n---\n")
        lines.append("## Session Capsule\n")
        lines.append(f"**Time:** {s.get('time', 'Unknown')}  ")
        lines.append(f"**Event:** {s.get('event', 'Unknown')}  ")
        lines.append(f"**Session ID:** {s.get('session_id', 'Unknown')}  ")
        lines.append(f"**Working Directory:** {s.get('cwd', 'Unknown')}\n")
        lines.append("### Captured Summary")
        lines.append(s.get("summary", "No summary.") + "\n")

        for section, key in [
            ("Auto-Extracted Decisions", "decisions"),
            ("Auto-Extracted Next Actions", "actions"),
            ("Auto-Detected Blockers / Issues", "blockers"),
        ]:
            lines.append(f"### {section}")
            items = s.get(key, [])
            if items:
                for item in items:
                    text = item if isinstance(item, str) else item.get("text", str(item))
                    lines.append(f"- {text}")
            else:
                lines.append("- None auto-detected.")
            lines.append("")

    return "\n".join(lines)


def sync_markdown(project_dir: Path) -> None:
    """Update SESSION_LOG.md from JSONL source."""
    md = render_markdown(project_dir)
    (project_dir / "SESSION_LOG.md").write_text(md, encoding="utf-8")


def compact(project_dir: Path, keep_last: int = 50) -> int:
    """Compact JSONL log, keeping only the last N entries."""
    jsonl_path = project_dir / "sessions.jsonl"
    if not jsonl_path.exists():
        return 0
    sessions = read_sessions(project_dir)
    if len(sessions) <= keep_last:
        return 0
    removed = len(sessions) - keep_last
    kept = sessions[-keep_last:]
    jsonl_path.write_text(
        "\n".join(json.dumps(s, ensure_ascii=False) for s in kept) + "\n",
        encoding="utf-8",
    )
    return removed
