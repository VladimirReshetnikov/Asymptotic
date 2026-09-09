"""Exact closed-frontier prototype for analytic functions of small power-log jets.

This is independent of the repository. Weights are exact rational numbers;
coefficients are SymPy polynomials in a supplied logarithm symbol. The prototype
retains the complete coefficient at the exclusive cutoff for error accounting,
then removes that coefficient from the returned finite part.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from typing import Callable, Iterable
import sympy as sp

Weight = Fraction
Jet = dict[Weight, sp.Expr]

class BudgetExceeded(RuntimeError):
    pass

@dataclass(frozen=True)
class Result:
    terms: Jet
    remainder_power: Weight
    remainder_log_degree: int
    boundary_polynomial: sp.Expr
    coefficient_calls: int
    pair_products: int


def canonical(rows: Iterable[tuple[Weight, sp.Expr]], log: sp.Symbol) -> Jet:
    out: Jet = {}
    for w, p in rows:
        if not isinstance(w, (int, Fraction)):
            raise TypeError("Weights must be int or Fraction, never floating point")
        w = Fraction(w)
        p = sp.sympify(p)
        if not p.is_polynomial(log):
            raise ValueError("Every coefficient must be polynomial in the log symbol")
        out[w] = sp.expand(out.get(w, sp.S.Zero) + p)
    return {w: p for w, p in sorted(out.items()) if p != 0}


def pushforward(
    rows: Iterable[tuple[Weight, sp.Expr]],
    coefficient: Callable[[int], sp.Expr | None],
    *,
    input_power: Weight | None,
    input_log_degree: int,
    cutoff: Weight,
    log: sp.Symbol,
    max_pair_products: int = 20000,
) -> Result:
    """Compute sum_{k>=1} coefficient(k) U**k, excluding the constant term.

    Input error: O(u**input_power * (1+abs(log(u)))**input_log_degree).
    input_power=None means exact input. `coefficient` must describe an analytic
    Taylor series near zero; returning None means all later coefficients vanish.
    It is called once for each requested k, in increasing order, including a
    possible boundary-only last power. Analyticity is a precondition, not inferred.
    """
    if not isinstance(cutoff, (int, Fraction)):
        raise TypeError("cutoff must be exact rational")
    c = Fraction(cutoff)
    if input_power is not None:
        if not isinstance(input_power, (int, Fraction)):
            raise TypeError("input_power must be exact rational or None")
        input_power = Fraction(input_power)
        c = min(c, input_power)
    if c <= 0:
        raise ValueError("This prototype requires a positive effective cutoff")
    if not isinstance(input_log_degree, int) or input_log_degree < 0:
        raise ValueError("input_log_degree must be a nonnegative integer")
    if not isinstance(max_pair_products, int) or max_pair_products < 1:
        raise ValueError("max_pair_products must be a positive integer")
    u = canonical(rows, log)
    if any(w <= 0 for w in u):
        raise ValueError("The small jet must have strictly positive valuation")
    if input_power is not None and any(w >= input_power for w in u):
        raise ValueError("The known input must be strictly below its error frontier")
    accumulated: Jet = {}
    power: Jet = {Fraction(0): sp.S.One}
    calls = pairs = 0
    while power and u:
        products: list[tuple[Weight, sp.Expr]] = []
        for a, pa in power.items():
            for b, pb in u.items():
                if a + b > c:
                    break  # canonical weights are increasing
                pairs += 1
                if pairs > max_pair_products:
                    raise BudgetExceeded("Closed-frontier pair-product budget exceeded")
                products.append((a + b, pa * pb))
        power = canonical(products, log)
        if not power:
            break
        calls += 1
        ck = coefficient(calls)
        if ck is None:
            break
        ck = sp.sympify(ck)
        if ck.has(log):
            raise ValueError("Taylor coefficients must not depend on the log variable")
        accumulated = canonical(
            [*accumulated.items(), *((w, ck * p) for w, p in power.items())], log
        )
    boundary = sp.expand(accumulated.get(c, sp.S.Zero))
    degree = 0 if boundary == 0 else int(sp.degree(boundary, log))
    if input_power is not None and input_power == c:
        degree = max(degree, input_log_degree)
    return Result(
        {w: p for w, p in accumulated.items() if w < c}, c, degree,
        boundary, calls, pairs,
    )
