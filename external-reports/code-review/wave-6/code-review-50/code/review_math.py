"""Independent exact models and proposed rational Lerch moment implementation.

This module does not import, emulate, or execute AsymptoticAnalysis or a WL kernel.
All rational algorithms use fractions.Fraction. Numeric observations are in
run_evidence.py and are deliberately separate from these exact computations.
"""
from __future__ import annotations
from fractions import Fraction
from math import comb, factorial
from typing import Sequence

MAX_DEGREE = 256

def rational(value: int | Fraction, name: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be an int or Fraction, not an approximation")
    return Fraction(value)

def degree(value: int, cap: int = MAX_DEGREE) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError("degree must be an integer")
    if not 0 <= value <= cap:
        raise ValueError(f"degree must be in [0,{cap}]")
    return value

def moment_table(z: int | Fraction, highest: int) -> list[Fraction]:
    """Return M_0,...,M_highest, including the n=0 contribution to M_0.

    Uses integer Eulerian numerators and exact rational Horner evaluation.
    Complexity is O(K^2) arithmetic operations, not O(K^2) bit operations.
    No global cache, symbolic simplification, or special-function call is used.
    """
    z = rational(z, "z")
    degree(highest)
    if abs(z) >= 1:
        raise ValueError("the admitted defining-sum domain is |z|<1")
    denominator = 1 - z
    numerator = [1]  # coefficients of P_k(z), ascending powers
    out = []
    for k in range(highest + 1):
        value = Fraction(0)
        for coefficient in reversed(numerator):
            value = value * z + coefficient
        out.append(value / denominator)
        if k != highest:
            new = [0] * (len(numerator) + 1)
            for j, coefficient in enumerate(numerator):
                new[j] += j * coefficient
                new[j + 1] += (k + 1 - j) * coefficient
            numerator = new
            denominator *= 1 - z
    return out

def stirling_moments(z: int | Fraction, highest: int) -> list[Fraction]:
    """Independent oracle: falling-factorial expansion of n^k."""
    z = rational(z, "z")
    degree(highest)
    if abs(z) >= 1:
        raise ValueError("|z|<1 is required")
    row = [1]  # Stirling S(0,0)
    result = []
    for k in range(highest + 1):
        result.append(sum((Fraction(row[j] * factorial(j)) * z**j /
                           (1-z)**(j+1) for j in range(k+1)), Fraction(0)))
        nxt = [0] * (k + 2)
        for j in range(1, k+2):
            nxt[j] = (row[j-1] if j-1 < len(row) else 0) + j * (row[j] if j < len(row) else 0)
        row = nxt
    return result

def lerch_coefficients(z: int | Fraction, s: int | Fraction, highest: int) -> list[Fraction]:
    """Coefficients of a^(-s-k), k=0,...,highest; retain exact zeros."""
    s = rational(s, "s")
    moments = moment_table(z, highest)
    factor = Fraction(1)
    out = []
    for k, moment in enumerate(moments):
        out.append(factor * moment)
        factor *= -(s+k) / (k+1)
    return out

def lerch_bound_constant(z: int | Fraction, s: int | Fraction, first_omitted: int) -> Fraction:
    """Existing repository bound, evaluated by rational moments; valid a>=1.

    This deliberately preserves the old mathematical theorem rather than
    claiming a new remainder bound. Index is the first omitted Taylor degree,
    not the count of nonzero displayed blocks.
    """
    z = rational(z, "z"); s = rational(s, "s"); n = degree(first_omitted)
    value = -s-n
    ceiling = -((-value.numerator)//value.denominator)
    d = max(0, ceiling)
    degree(n+d)
    moments = moment_table(abs(z), n+d)
    factor = Fraction(1)
    for k in range(n):
        factor *= (s+k)/(k+1)
    return abs(factor) * sum((comb(d,j)*moments[n+j] for j in range(d+1)), Fraction(0))

def logarithm_tail_bounds(y: int | Fraction, retained_depth: int) -> tuple[Fraction, Fraction]:
    """Exact rational bounds for -log(1-1/y)-sum_(k=1)^N 1/(k*y^k)."""
    y = rational(y, "y"); degree(retained_depth)
    if y <= 1:
        raise ValueError("y must exceed one")
    n = retained_depth + 1
    lower = Fraction(1, n) / y**n
    return lower, lower/(1-Fraction(1)/y)

def translation_correction_coefficients(amplitude: int | Fraction, depth: int) -> list[Fraction]:
    """Independent closed form C_n=-1/(n*a^n) for a*exp(v)+1."""
    amplitude = rational(amplitude, "amplitude"); degree(depth)
    if amplitude <= 0:
        raise ValueError("amplitude must be positive")
    return [-Fraction(1,n)/amplitude**n for n in range(1, depth+1)]
