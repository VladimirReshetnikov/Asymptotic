"""Exact independent oracles for the audit's moving-core counterexamples.

This module DOES NOT load or emulate the AsymptoticAnalysis package. It solves
its quadratic counterexamples independently, with rational arithmetic.
"""
from __future__ import annotations
from fractions import Fraction
from math import comb, isqrt
from typing import Literal

Branch = Literal["large", "small"]
MAX_DEPTH = 64
MAX_BITS = 16384


def rational(value: int | Fraction) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError("An integer or Fraction is required; floats are not exact inputs.")
    q = Fraction(value)
    if max(abs(q.numerator).bit_length(), q.denominator.bit_length()) > MAX_BITS:
        raise ValueError("Rational input exceeds the oracle's bit budget.")
    return q


def depth_checked(depth: int) -> int:
    if isinstance(depth, bool) or not isinstance(depth, int):
        raise TypeError("depth must be an integer")
    if not 0 <= depth <= MAX_DEPTH:
        raise ValueError(f"depth must be between 0 and {MAX_DEPTH}")
    return depth


def catalan(n: int) -> int:
    depth_checked(n)
    return comb(2 * n, n) // (n + 1)


def marker_coefficients(branch: Branch, y: int | Fraction, c: int | Fraction,
                        depth: int) -> list[Fraction]:
    """Taylor coefficients in epsilon, keeping y and c fixed.

    Large: X^2 - (y+c-epsilon*c) X + epsilon = 0; X(0)=y+c.
    Small: epsilon X^2 - (y+c-epsilon*c) X + 1 = 0; X(0)=1/(y+c).
    These are two source charts for the same final equation x+1/x=y.
    """
    depth_checked(depth)
    y, c = rational(y), rational(c)
    a = y + c
    if a == 0:
        raise ValueError("The unperturbed root coordinate y+c must be nonzero.")
    if branch not in ("large", "small"):
        raise ValueError("branch must be 'large' or 'small'")
    result: list[Fraction] = []
    for k in range(depth + 1):
        if branch == "large":
            value = a if k == 0 else (-c if k == 1 else Fraction(0))
            if k:
                value -= sum((Fraction(catalan(m - 1) * comb(k + m - 2, k - m))
                              * c ** (k - m) / a ** (k + m - 1)
                              for m in range(1, k + 1)), Fraction(0))
        else:
            value = sum((Fraction(catalan(m) * comb(k + m, k - m))
                         * c ** (k - m) / a ** (k + m + 1)
                         for m in range(k + 1)), Fraction(0))
        result.append(value)
    return result


def approximation(branch: Branch, y: int | Fraction, c: int | Fraction,
                  depth: int) -> Fraction:
    return sum(marker_coefficients(branch, y, c, depth), Fraction(0))


def reported_scale(branch: Branch, y: int | Fraction, c: int | Fraction,
                   depth: int) -> Fraction:
    """Source-predicted scale from the inspected constructor, not a valid bound.

    c is nonzero: source gap=1. c=0 removes that row, so the source gap=2.
    Public native observations in this audit establish the c=y, depth=2 cases.
    """
    depth_checked(depth)
    y, c = rational(y), rational(c)
    if y + c <= 0 or branch not in ("large", "small"):
        raise ValueError("A positive core coordinate and a recognized branch are required.")
    gap = 1 if c else 2
    rint = -1 if branch == "large" else 1
    return (y + c) ** (-(rint + (depth + 1) * gap))


def root_interval(y: int | Fraction, branch: Branch, digits: int = 100
                  ) -> tuple[Fraction, Fraction]:
    """Outward EXACT rational enclosure; no floating point enters this proof."""
    y = rational(y)
    if y <= 2 or branch not in ("large", "small"):
        raise ValueError("Require y>2 and branch 'large' or 'small'.")
    if isinstance(digits, bool) or not isinstance(digits, int) or not 1 <= digits <= 2000:
        raise ValueError("digits must be an integer in [1, 2000]")
    rad = y * y - 4
    grid = 10 ** digits
    k = isqrt((rad.numerator * grid * grid) // rad.denominator)
    lo = Fraction(k, grid)
    hi = lo if lo * lo == rad else Fraction(k + 1, grid)
    if branch == "large":
        return (y + lo) / 2, (y + hi) / 2
    return 2 / (y + hi), 2 / (y + lo)


def absolute_error_interval(approx: Fraction,
                            roots: tuple[Fraction, Fraction]) -> tuple[Fraction, Fraction]:
    approx = rational(approx)
    lo, hi = roots
    if lo > hi:
        raise ValueError("Root endpoints are reversed")
    lower = lo - approx if approx < lo else (approx - hi if approx > hi else Fraction(0))
    return lower, max(abs(approx - lo), abs(approx - hi))
