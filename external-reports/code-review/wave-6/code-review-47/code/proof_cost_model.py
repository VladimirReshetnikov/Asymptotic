"""Source-faithful *restricted* model of MathicsAssumptions.wl proof traversal.

Only the immutable grammar a | 2 | Cosh[e] | e^2 is modeled. This is not a
Mathics emulator and its timings are not package timings. The relevant upstream
branches and their depth decrements are retained; calls to facts/numeric helpers
are deliberately not counted. Each query gets a separate memo table.
"""
from __future__ import annotations
from collections import Counter
from functools import lru_cache
import json
from pathlib import Path
from typing import Any

A = ("symbol", "a")
TWO = ("number", 2)
POSITIVE = frozenset({1})
NONNEGATIVE = frozenset({0, 1})
ALL_SIGNS = frozenset({-1, 0, 1})

class BudgetExceeded(RuntimeError):
    """A model execution limit, never a mathematical False/None result."""

def family(n: int) -> tuple:
    if type(n) is not int or not 0 <= n <= 64:
        raise ValueError("n must be an integer in [0, 64]")
    e = A
    for _ in range(n):
        e = ("power", ("cosh", e), TWO)
    return e

class ProofQuery:
    def __init__(self, *, memoize: bool = False, a_is_real: bool = False,
                 max_body_calls: int = 1_000_000) -> None:
        if type(max_body_calls) is not int or max_body_calls <= 0:
            raise ValueError("max_body_calls must be a positive integer")
        self.calls: Counter[str] = Counter()
        self._known = bool(a_is_real)
        self._budget = max_body_calls
        if memoize:
            self.real = lru_cache(maxsize=None)(self.real)
            self.sign = lru_cache(maxsize=None)(self.sign)

    def _tick(self, name: str) -> None:
        if self.total_calls >= self._budget:
            raise BudgetExceeded("Restricted proof-model body-call budget exhausted")
        self.calls[name] += 1

    @property
    def total_calls(self) -> int:
        return sum(self.calls.values())

    def real(self, e: tuple, depth: int) -> bool | None:
        self._tick("real")
        if depth <= 0:
            return None
        if e == A:
            return True if self._known else None
        if e[0] == "number":
            return True
        if e[0] == "cosh":
            return True if self.real(e[1], depth - 1) is True else None
        if e[0] == "power":
            base, exponent = e[1:]
            if self.real(exponent, depth - 1) is not True:
                return None
            signs = self.sign(base, depth - 1)
            if signs == POSITIVE:
                return True
            # The only exponent in the admitted grammar is the integer +2.
            if self.real(base, depth - 1) is True:
                return True
            if signs and signs <= NONNEGATIVE:
                return True
        return None

    def sign(self, e: tuple, depth: int) -> frozenset[int] | None:
        self._tick("sign")
        if depth <= 0:
            return None
        if e[0] == "number":
            return POSITIVE
        if e[0] == "power":
            base, exponent = e[1:]
            signs = self.sign(base, depth - 1)
            if signs == POSITIVE and self.real(exponent, depth - 1) is True:
                return POSITIVE
            if signs:
                return frozenset(0 if x == 0 else 1 for x in signs)
        if e[0] == "cosh" and self.real(e[1], depth - 1) is True:
            return POSITIVE
        # Crucially, the realness fallback receives the original expression.
        return ALL_SIGNS if self.real(e, depth - 1) is True else None

    def evaluate(self, n: int, depth: int = 24) -> bool | None:
        if type(depth) is not int or not 0 <= depth <= 64:
            raise ValueError("depth must be an integer in [0, 64]")
        return self.real(family(n), depth)

@lru_cache(maxsize=None)
def recurrence(n: int, depth: int) -> int:
    """Independent closed control-flow recurrence for the UNKNOWN family."""
    if n == 0 or depth <= 0:
        return 1
    if depth == 1:
        return 2
    if depth == 2:
        return 7
    return 5 + 2 * recurrence(n - 1, depth - 2) + recurrence(n - 1, depth - 3)

def observations() -> list[dict[str, Any]]:
    rows = []
    for n in range(15):
        plain, memo = ProofQuery(), ProofQuery(memoize=True)
        before, after = plain.evaluate(n), memo.evaluate(n)
        if before != after or plain.total_calls != recurrence(n, 24):
            raise RuntimeError("Independent checks disagree")
        rows.append({"n": n, "depth_budget": 24, "leaf_count": 1 + 3*n,
                     "result": "None" if before is None else before,
                     "plain_body_calls": plain.total_calls,
                     "memoized_body_calls": memo.total_calls,
                     "recurrence_body_calls": recurrence(n, 24),
                     "count_ratio": plain.total_calls / memo.total_calls})
    return rows

if __name__ == "__main__":
    print(json.dumps({"evidence": "Independent restricted Python model",
                      "not_mathics_execution": True,
                      "observations": observations()}, indent=2))
