"""Form & streak analytics (PT §9.2).

Decodes `teamform` / `teamlongform` / `teamshortform` strings (each character
is one match result, oldest -> newest by FC convention) into typed result
sequences and derives streaks.

Note: the Sprint 1 probe for `teamplayerlinks.form` (per-player) is partial,
but team-level form fields are stored as plain strings of W/D/L characters
in the standings/season-overview CSVs (see schema dtypes). Unknown characters
are dropped.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal, Optional

Result = Literal["W", "D", "L"]
_VALID: frozenset[str] = frozenset({"W", "D", "L"})


@dataclass(frozen=True)
class Streak:
    kind: Optional[Result]
    length: int


def decode_team_form(teamform: str | int | None) -> list[Result]:
    """Decode a team-form field into an ordered list of W/D/L tokens.

    Strings are parsed character-by-character (case-insensitive); any
    character outside {W,D,L} is silently skipped. `None`, empty strings,
    or non-string inputs return an empty list.
    """
    if teamform is None:
        return []
    if not isinstance(teamform, str):
        return []
    out: list[Result] = []
    for ch in teamform.upper():
        if ch in _VALID:
            out.append(ch)  # type: ignore[arg-type]
    return out


def current_streak(results: list[Result]) -> Streak:
    """Return the streak at the end of the result list.

    Streak.kind is the result type of the trailing run; Streak.length is the
    number of consecutive matches with that result. An empty input yields
    `Streak(None, 0)`.
    """
    if not results:
        return Streak(None, 0)
    last = results[-1]
    length = 0
    for r in reversed(results):
        if r == last:
            length += 1
        else:
            break
    return Streak(last, length)


def longest_unbeaten(results: list[Result]) -> int:
    """Length of the longest run without a loss (W or D count, L resets)."""
    best = 0
    run = 0
    for r in results:
        if r == "L":
            run = 0
        else:
            run += 1
            if run > best:
                best = run
    return best


__all__ = ["Result", "Streak", "decode_team_form", "current_streak", "longest_unbeaten"]
