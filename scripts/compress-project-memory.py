import argparse
import re
from pathlib import Path
from datetime import datetime


def split_capsules(text):
    parts = re.split(r"\n---\n\n## Session Capsule", text)
    if len(parts) <= 1:
        return []

    capsules = []
    for part in parts[1:]:
        capsules.append("---\n\n## Session Capsule" + part)

    return capsules


def compress_project(project_dir, threshold):
    project_dir = Path(project_dir)
    session_log = project_dir / "SESSION_LOG.md"
    archive_dir = project_dir / "archives"

    if not session_log.exists():
        print("Compression skipped: SESSION_LOG.md not found.")
        return

    size = session_log.stat().st_size

    if size <= threshold:
        print(f"Compression skipped: SESSION_LOG.md size {size} bytes under threshold {threshold}.")
        return

    archive_dir.mkdir(parents=True, exist_ok=True)

    now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    archive_file = archive_dir / f"SESSION_LOG_ARCHIVE_{now}.md"

    original = session_log.read_text(encoding="utf-8", errors="ignore")
    archive_file.write_text(original, encoding="utf-8")

    capsules = split_capsules(original)
    latest_capsules = capsules[-3:] if capsules else []

    project_name = project_dir.name

    fresh_log = f"""# Session Log: {project_name}

Older session log archived here:

{archive_file}

Compression time: {now}

"""

    if latest_capsules:
        fresh_log += "\n\n".join(latest_capsules)
    else:
        fresh_log += "\nNo recent session capsules found during compression.\n"

    session_log.write_text(fresh_log, encoding="utf-8")

    print(f"Compressed SESSION_LOG.md for {project_name}.")
    print(f"Archived old log to: {archive_file}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-dir", required=True)
    parser.add_argument("--threshold", type=int, default=30000)
    args = parser.parse_args()

    compress_project(args.project_dir, args.threshold)


if __name__ == "__main__":
    main()
