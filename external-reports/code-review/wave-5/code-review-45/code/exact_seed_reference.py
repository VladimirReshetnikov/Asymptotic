#!/usr/bin/env python3
"""Independent bounded rational-polynomial root admission.

This is NOT a Wolfram Language or Mathics emulator and does not run Asymptotic.
A seed proposes a candidate. Only exact polynomial equality admits that candidate.
Coefficients are supplied in increasing degree order. No third-party packages.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from math import gcd, isfinite
from typing import Iterable


class BudgetExceeded(ValueError):
    """The exact admission check declined work before its large-integer loop."""


@dataclass(frozen=True)
class Budget:
    max_degree: int = 256
    max_input_bits: int = 4096
    max_work_bits: int = 32768

    def __post_init__(self) -> None:
        if any(isinstance(x, bool) or not isinstance(x, int) for x in
               (self.max_degree, self.max_input_bits, self.max_work_bits)):
            raise TypeError("Budget fields must be integers")
        if self.max_degree < 0 or self.max_input_bits < 1 or self.max_work_bits < 1:
            raise ValueError("Budget fields must be positive, except degree may be zero")


@dataclass(frozen=True)
class EqualityWitness:
    coefficients: tuple[Fraction, ...]
    candidate: Fraction
    degree: int
    denominator_lcm: int
    homogeneous_value: int

    def to_json(self) -> dict:
        def encode(x: Fraction) -> str:
            return f"{x.numerator}/{x.denominator}"
        return {
            "schema": "exact-polynomial-point-equality-v1",
            "coefficients_increasing_degree": [encode(x) for x in self.coefficients],
            "candidate": encode(self.candidate),
            "degree": self.degree,
            "denominator_lcm": str(self.denominator_lcm),
            "homogeneous_value": str(self.homogeneous_value),
            "claim": "The candidate satisfies this polynomial equation exactly.",
            "not_claimed": ["uniqueness", "inverse-branch identity", "package acceptance"],
        }


def _fraction(value: int | Fraction) -> Fraction:
    # Float coefficients would change the mathematical problem, so reject them.
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError("Coefficients and explicit candidates must be exact int/Fraction")
    return Fraction(value)


def _size(value: Fraction) -> int:
    return max(abs(value.numerator).bit_length(), value.denominator.bit_length(), 1)


def _prepare(coefficients: Iterable[int | Fraction], candidate: int | Fraction,
             budget: Budget) -> tuple[tuple[Fraction, ...], Fraction, int, list[int]]:
    c: list[Fraction] = []
    for raw in coefficients:
        if len(c) > budget.max_degree:
            raise BudgetExceeded("Degree/input length exceeds budget")
        value = _fraction(raw)
        if _size(value) > budget.max_input_bits:
            raise BudgetExceeded("Coefficient bit size exceeds budget")
        c.append(value)
    if not c:
        raise ValueError("Supply at least one coefficient")
    while len(c) > 1 and c[-1] == 0:
        c.pop()
    q = _fraction(candidate)
    if _size(q) > budget.max_input_bits:
        raise BudgetExceeded("Candidate bit size exceeds budget")
    degree = len(c) - 1
    # Conservative upper bound for clearing denominators and evaluating the
    # homogeneous polynomial. This is a work guard, not a floating-point estimate.
    denominator_bits = 1 + sum(x.denominator.bit_length() for x in c)
    coefficient_bits = max(abs(x.numerator).bit_length() for x in c) + denominator_bits
    estimate = coefficient_bits + degree * _size(q) + (degree + 1).bit_length() + 3
    if estimate > budget.max_work_bits:
        raise BudgetExceeded("Predicted homogeneous integer work exceeds budget")
    common = 1
    for a in c:
        common = common // gcd(common, a.denominator) * a.denominator
    integers = [a.numerator * (common // a.denominator) for a in c]
    return tuple(c), q, common, integers


def _homogeneous(integers: list[int], p: int, q: int, modulus: int | None = None) -> int:
    value = integers[-1]
    qpower = 1
    for a in reversed(integers[:-1]):
        qpower *= q
        value = value * p + a * qpower
        if modulus is not None:
            value %= modulus
            qpower %= modulus
    return value % modulus if modulus is not None else value


def prove_root(coefficients: Iterable[int | Fraction], candidate: int | Fraction,
               budget: Budget = Budget(), *, modular_rejection: bool = True) -> EqualityWitness | None:
    """Return an exact equality witness, or None. Budget rejection raises.

    Modular checks can reject, never accept. Zero/constant polynomials are
    treated as point equalities; a successful witness still says nothing about
    uniqueness. The caller must enforce inverse-object/domain contracts.
    """
    coeffs, x, common, ints = _prepare(coefficients, candidate, budget)
    if modular_rejection:
        for prime in (101, 103):
            if _homogeneous(ints, x.numerator, x.denominator, prime) != 0:
                return None
    value = _homogeneous(ints, x.numerator, x.denominator)
    if value != 0:
        return None
    return EqualityWitness(coeffs, x, len(coeffs) - 1, common, value)


def verify_witness(payload: dict, budget: Budget = Budget()) -> bool:
    """Recompute equality; do not trust stored degree, LCM, or value fields."""
    if not isinstance(payload, dict) or payload.get("schema") != "exact-polynomial-point-equality-v1":
        return False
    try:
        raw = payload["coefficients_increasing_degree"]
        if not isinstance(raw, list) or not 1 <= len(raw) <= budget.max_degree + 1:
            return False
        strings = raw + [payload["candidate"]]
        # Bound input before constructing arbitrary-sized integers.
        if any(not isinstance(s, str) or len(s) > 2 * budget.max_input_bits + 3
               or any(ch not in "-0123456789/" for ch in s) for s in strings):
            return False
        coeffs = tuple(Fraction(s) for s in raw)
        x = Fraction(payload["candidate"])
        result = prove_root(coeffs, x, budget)
    except (ValueError, TypeError, KeyError, ZeroDivisionError, OverflowError):
        return False
    return result is not None and result.to_json() == payload


def old_integer_admission(coefficients: Iterable[int | Fraction], seed: int | Fraction) -> Fraction | None:
    """Exact-arithmetic model of the INTEGER-only gate, not Mathics execution."""
    seed = _fraction(seed)
    candidate = Fraction(round(seed))
    if seed != candidate:
        return None
    return candidate if prove_root(coefficients, candidate) else None


def rational_admission(coefficients: Iterable[int | Fraction], seed: int | Fraction) -> Fraction | None:
    seed = _fraction(seed)
    return seed if prove_root(coefficients, seed) else None


def propose_binary_float(value: float) -> Fraction:
    """Exact value of a Python binary float, NOT a model of WL Rationalize."""
    if not isinstance(value, float) or not isfinite(value):
        raise ValueError("A finite Python float is required")
    return Fraction.from_float(value)


def evaluate(coefficients: Iterable[int | Fraction], x: int | Fraction) -> Fraction:
    value = Fraction(0)
    for a in reversed(tuple(coefficients)):
        value = value * _fraction(x) + _fraction(a)
    return value
