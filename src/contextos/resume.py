"""Resume pack generation."""

import subprocess
import sys
from datetime import datetime
from pathlib import Path

from .tokens import count_tokens
from .vault import get_vault_path


def _read_tail(path: Path, max_chars: int) -> str:
    if not path.exists():
        return "Not found.\n"
    text = path.read_text(encoding="utf-8", errors="ignore")
    return text[-max_chars:] if len(text) > max_chars else text


def create_resume_pack(vault: Path, project_name: str) -> Path | None:
    project_dir = vault / "projects" / project_name
    packs_dir = vault / "context-packs"
    packs_dir.mkdir(parents=True, exist_ok=True)

    if not project_dir.is_dir():
        return None

    ts = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    output = packs_dir / f"{project_name}-context-pack-{ts}.md"

    sections = [
        ("Project Context", "PROJECT_CONTEXT.md", 5000),
        ("Decisions", "DECISIONS.md", 3000),
        ("Next Actions", "NEXT_ACTIONS.md", 3000),
        ("Project Graph", "graph.mmd", 2500),
        ("Latest Session Log", "SESSION_LOG.md", 5000),
    ]

    content = f"# ContextOS Resume Pack: {project_name}\n\nGenerated: {ts}\n\n"
    content += "Use this as restart context for Claude / ChatGPT / Codex.\n\n---\n"

    for title, fn, max_chars in sections:
        content += f"\n## {title}\n{_read_tail(project_dir / fn, max_chars)}\n---\n"

    output.write_text(content, encoding="utf-8")
    return output


def cli_resume(args: list[str] | None = None) -> None:
    if not args:
        print("Usage: contextos resume <project-name>")
        sys.exit(1)

    project_name = args[0]
    vault = get_vault_path()
    project_dir = vault / "projects" / project_name

    if not project_dir.is_dir():
        print(f"Project not found: {project_name}\n\nAvailable projects:")
        projects_dir = vault / "projects"
        if projects_dir.exists():
            for p in sorted(projects_dir.iterdir()):
                if p.is_dir():
                    print(f"  {p.name}")
        sys.exit(1)

    output = create_resume_pack(vault, project_name)
    if not output:
        sys.exit(1)

    # Copy to clipboard on macOS
    import shutil
    copied = False
    if shutil.which("pbcopy"):
        try:
            subprocess.run(["pbcopy"], input=output.read_text(encoding="utf-8"),
                         text=True, check=True)
            copied = True
        except Exception:
            pass

    text = output.read_text(encoding="utf-8")
    tokens = count_tokens(text)

    print(f"\nContextOS resume pack created:\n{output}")
    if copied:
        print("\nCopied to clipboard.")
    print(f"\nToken estimate:\n{'-' * 15}")
    print(f"Resume pack characters: {len(text)}")
    print(f"Estimated tokens: {tokens}")
    print(f"Estimated re-explanation avoided per resumed session: ~{tokens} tokens")
    print(f"\nPreview:\n{'-' * 8}")
    for line in text.splitlines()[:60]:
        print(line)
