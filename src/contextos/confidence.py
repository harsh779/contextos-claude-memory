"""Confidence scoring for extracted decisions and actions."""

import re
from enum import Enum


class Confidence(Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


# --- Decision signals ---

_DECISION_START_SIGNALS = (
    "decision:",
    "decided:",
    "locked:",
    "constraint:",
    "must ",
    "must not ",
    "do not ",
    "source of truth",
    "required",
)

_DECISION_BODY_SIGNALS = (
    "decision",
    "decided",
    "locked",
    "constraint",
    "must",
    "required",
    "source of truth",
    "do not",
)

# --- Action signals ---

_ACTION_START_SIGNALS = (
    "next action:",
    "todo:",
    "to-do:",
)

_ACTION_VERB_PATTERN = re.compile(
    r"\b(fix|build|add|implement|test|validate|check)\s",
    re.IGNORECASE,
)

_SPECIFIC_TARGET_PATTERN = re.compile(
    r"(/[\w./\-]+)"        # file path
    r"|(`[^`]+`)"          # backtick-quoted command/path
    r"|(https?://\S+)"     # URL
    r"|(\S+\.\w{1,5}\b)",  # filename with extension
)


def score_item(text: str, item_type: str = "decision") -> Confidence:
    """Score confidence of an extracted decision or action.

    item_type: "decision" or "action"
    """
    if item_type == "decision":
        return _score_decision(text)
    if item_type == "action":
        return _score_action(text)
    raise ValueError(f"Unknown item_type: {item_type!r}. Use 'decision' or 'action'.")


def score_items(items: list[str], item_type: str = "decision") -> list[dict]:
    """Score a list of items. Returns list of {"text": str, "confidence": Confidence}."""
    return [
        {"text": item, "confidence": score_item(item, item_type)}
        for item in items
    ]


# --- Internal helpers ---


def _score_decision(text: str) -> Confidence:
    lower = text.lower().strip()
    starts = any(lower.startswith(sig) for sig in _DECISION_START_SIGNALS)
    contains = any(sig in lower for sig in _DECISION_BODY_SIGNALS)

    if starts and len(text.strip()) > 20:
        return Confidence.HIGH
    if starts or contains:
        return Confidence.MEDIUM
    return Confidence.LOW


def _score_action(text: str) -> Confidence:
    lower = text.lower().strip()

    if any(lower.startswith(sig) for sig in _ACTION_START_SIGNALS):
        return Confidence.HIGH

    has_verb = bool(_ACTION_VERB_PATTERN.search(text))
    has_target = bool(_SPECIFIC_TARGET_PATTERN.search(text))

    if has_verb and has_target:
        return Confidence.HIGH
    if has_verb:
        return Confidence.MEDIUM
    return Confidence.LOW
