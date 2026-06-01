"""Pure Python TF-IDF search over project memory files."""

import math
import re
from pathlib import Path


SKIP_DIRS = {"raw", "sessions", "archives"}
SKIP_PREFIXES = ("SESSION_LOG_ARCHIVE",)
LOW_VALUE_PATTERNS = {"ai-memory-vault", "archived", "compression time"}


def _tokenize(text: str) -> list[str]:
    return re.findall(r"[a-z0-9]+", text.lower())


def _collect_documents(vault_path: Path) -> list[dict]:
    projects_dir = vault_path / "projects"
    if not projects_dir.is_dir():
        return []

    docs = []
    for project_dir in sorted(projects_dir.iterdir()):
        if not project_dir.is_dir():
            continue
        project_name = project_dir.name
        for file_path in sorted(project_dir.rglob("*")):
            if not file_path.is_file():
                continue
            if any(part in SKIP_DIRS for part in file_path.relative_to(project_dir).parts):
                continue
            if any(file_path.name.startswith(p) for p in SKIP_PREFIXES):
                continue
            try:
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            docs.append({
                "project": project_name,
                "file": file_path.name,
                "path": str(file_path),
                "content": content,
                "tokens": _tokenize(content),
            })
    return docs


def _build_idf(docs: list[dict]) -> dict[str, float]:
    n = len(docs)
    if n == 0:
        return {}

    df: dict[str, int] = {}
    for doc in docs:
        unique_terms = set(doc["tokens"])
        for term in unique_terms:
            df[term] = df.get(term, 0) + 1

    # IDF = log(N / df) + 1, smoothed to avoid zero for universal terms
    return {term: math.log(n / count) + 1.0 for term, count in df.items()}


def _term_freq(tokens: list[str]) -> dict[str, float]:
    counts: dict[str, int] = {}
    for t in tokens:
        counts[t] = counts.get(t, 0) + 1
    total = len(tokens) if tokens else 1
    return {t: c / total for t, c in counts.items()}


def _score_document(query_tokens: list[str], doc_tf: dict[str, float], idf: dict[str, float]) -> float:
    score = 0.0
    for qt in query_tokens:
        if qt in doc_tf:
            score += doc_tf[qt] * idf.get(qt, 1.0)
    return score


def _is_low_value_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    if stripped.startswith("#"):
        return True
    lower = stripped.lower()
    return any(p in lower for p in LOW_VALUE_PATTERNS)


def _best_matching_line(content: str, query_tokens: list[str]) -> str:
    lines = content.splitlines()
    best_line = ""
    best_overlap = -1

    query_set = set(query_tokens)
    for line in lines:
        if _is_low_value_line(line):
            continue
        line_tokens = set(_tokenize(line))
        overlap = len(query_set & line_tokens)
        if overlap > best_overlap:
            best_overlap = overlap
            best_line = line.strip()

    return best_line


def search(vault_path: Path, query: str, max_results: int = 20) -> list[dict]:
    """Search project memory using TF-IDF ranking.

    Returns list of dicts with keys: score, project, file, match, path
    Sorted by score descending.
    """
    query_tokens = _tokenize(query)
    if not query_tokens:
        return []

    docs = _collect_documents(vault_path)
    if not docs:
        return []

    idf = _build_idf(docs)

    results = []
    for doc in docs:
        tf = _term_freq(doc["tokens"])
        score = _score_document(query_tokens, tf, idf)
        if score <= 0:
            continue
        match_line = _best_matching_line(doc["content"], query_tokens)
        results.append({
            "score": round(score, 4),
            "project": doc["project"],
            "file": doc["file"],
            "match": match_line[:80] if match_line else "",
            "path": doc["path"],
        })

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:max_results]


def cli_search(args: list[str]) -> None:
    """CLI entry point. args = search terms."""
    if not args:
        print("Usage: contextos search <terms...>")
        return

    vault_candidates = [
        Path.home() / ".ai-memory-vault",
        Path.home() / "ai-memory-vault",
    ]
    vault_path = None
    for candidate in vault_candidates:
        if candidate.is_dir():
            vault_path = candidate
            break

    if vault_path is None:
        print("No vault found. Checked: " + ", ".join(str(c) for c in vault_candidates))
        return

    query = " ".join(args)
    results = search(vault_path, query)

    if not results:
        print(f"No results for: {query}")
        return

    col_score = 8
    col_project = max(len(r["project"]) for r in results)
    col_project = max(col_project, 7)
    col_file = max(len(r["file"]) for r in results)
    col_file = max(col_file, 4)

    header = (
        f"{'Score':<{col_score}}"
        f"{'Project':<{col_project + 2}}"
        f"{'File':<{col_file + 2}}"
        f"Match"
    )
    print(header)
    print("-" * len(header + " " * 40))

    for r in results:
        print(
            f"{r['score']:<{col_score}.3f}"
            f"{r['project']:<{col_project + 2}}"
            f"{r['file']:<{col_file + 2}}"
            f"{r['match']}"
        )
