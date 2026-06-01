#!/usr/bin/env bash
set -euo pipefail
# Thin wrapper — delegates to Python package if installed
if python3 -c "import contextos" 2>/dev/null; then
  exec python3 -m contextos capture
fi

# Fallback: inline Python
vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
debug_dir="$vault/debug"
mkdir -p "$debug_dir"

input_json="$(cat)"
raw_debug_path="$debug_dir/last-capture-raw-input.json"
printf '%s' "$input_json" > "$raw_debug_path"

if [[ -z "${input_json//[[:space:]]/}" ]]; then
  echo "ContextOS capture skipped: no JSON input received."
  exit 0
fi

python3 - "$vault" "$raw_debug_path" <<'PY'
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from datetime import datetime

vault = Path(sys.argv[1])
raw_debug_path = sys.argv[2]
raw = Path(raw_debug_path).read_text(encoding="utf-8")

try:
    hook = json.loads(raw)
except Exception:
    print(f"ContextOS capture failed: invalid JSON input.")
    print(f"Raw input saved here: {raw_debug_path}")
    sys.exit(1)

debug_dir = vault / "debug"
(debug_dir / "last-capture-parsed.json").write_text(json.dumps(hook, indent=2), encoding="utf-8")

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

processor = vault / "scripts" / "process-session.py"
if not processor.exists():
    print(f"ContextOS capture failed: processor not found at {processor}")
    sys.exit(1)

python_exe = shutil.which("python3") or shutil.which("python")
if not python_exe:
    print("ContextOS capture failed: Python was not found.")
    sys.exit(1)

completed = subprocess.run([python_exe, str(processor), "--event", str(metadata_path)], check=False)
sys.exit(completed.returncode)
PY
