"""SessionEnd hook — capture session metadata and trigger processing."""

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from .vault import get_vault_path


def run_capture() -> None:
    vault = get_vault_path()
    debug_dir = vault / "debug"
    debug_dir.mkdir(parents=True, exist_ok=True)

    raw = sys.stdin.read()
    raw_debug_path = debug_dir / "last-capture-raw-input.json"
    raw_debug_path.write_text(raw, encoding="utf-8")

    if not raw.strip():
        print("ContextOS capture skipped: no JSON input received.")
        sys.exit(0)

    try:
        hook = json.loads(raw)
    except Exception:
        print(f"ContextOS capture failed: invalid JSON input.")
        print(f"Raw input saved here: {raw_debug_path}")
        sys.exit(1)

    (debug_dir / "last-capture-parsed.json").write_text(
        json.dumps(hook, indent=2), encoding="utf-8"
    )

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    cwd = hook.get("cwd") or ""
    project_name = Path(cwd).name if cwd else "unknown-project"
    project_dir = vault / "projects" / project_name
    sessions_dir = project_dir / "sessions"

    project_dir.mkdir(parents=True, exist_ok=True)
    sessions_dir.mkdir(parents=True, exist_ok=True)

    transcript_path = hook.get("transcript_path")
    copy_raw = os.environ.get("CONTEXTOS_COPY_RAW_TRANSCRIPTS") == "true"

    raw_copy_path = None
    if copy_raw and transcript_path and Path(transcript_path).exists():
        raw_dir = project_dir / "raw"
        raw_dir.mkdir(parents=True, exist_ok=True)
        raw_copy_path = raw_dir / f"{timestamp}-transcript.jsonl"
        shutil.copyfile(transcript_path, raw_copy_path)

    metadata = {
        "session_id": hook.get("session_id"),
        "hook_event_name": hook.get("hook_event_name"),
        "cwd": cwd,
        "transcript_path": transcript_path,
        "captured_at": timestamp,
        "copy_raw_transcripts": copy_raw,
        "raw_copy_path": str(raw_copy_path) if raw_copy_path else None,
    }

    metadata_path = sessions_dir / f"{timestamp}-event.json"
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    from .process import process_event
    process_event(metadata_path)
