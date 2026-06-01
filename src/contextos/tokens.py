"""Token counting with tiktoken (real) or fallback (chars/4)."""

from pathlib import Path

_encoder = None
_tried_import = False


def _get_encoder():
    global _encoder, _tried_import
    if _tried_import:
        return _encoder
    _tried_import = True
    try:
        import tiktoken
        _encoder = tiktoken.get_encoding("cl100k_base")
    except (ImportError, Exception):
        _encoder = None
    return _encoder


def count_tokens(text: str) -> int:
    if not text:
        return 0
    enc = _get_encoder()
    if enc:
        return len(enc.encode(text))
    return max(1, (len(text) + 3) // 4)


def using_tiktoken() -> bool:
    return _get_encoder() is not None


def count_tokens_file(path: Path) -> int:
    if not path.exists():
        return 0
    return count_tokens(path.read_text(encoding="utf-8", errors="ignore"))
