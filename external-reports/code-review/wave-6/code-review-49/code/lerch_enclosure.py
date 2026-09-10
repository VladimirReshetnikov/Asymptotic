"""Exact rational signed Lerch remainder enclosures (review prototype).

No AsymptoticAnalysis code is imported or modified.  This implementation covers
0 <= z < 1, a > 0 rational and s a positive integer.  The article proves the
underlying bounds for real s > 0.  No floating-point input is silently accepted.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from math import factorial
from typing import TypeAlias

Exact: TypeAlias = int | Fraction
MAX_ORDER = 64


def _rational(value: Exact, name: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be int or Fraction, not an approximate value")
    return Fraction(value)


def _integer(value: int, name: str, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise ValueError(f"{name} must be an integer >= {minimum}")
    return value


def geometric_moments(z: Exact, order: int) -> tuple[Fraction, ...]:
    """M_k=sum(n**k*z**n, n>=0), including M_0=1/(1-z).

    For k>=1, use Eulerian polynomials: M_k=z*A_k(z)/(1-z)**(k+1).
    The coefficient recurrence is integer-only, with no CAS simplification.
    """
    z = _rational(z, "z")
    _integer(order, "order")
    if order > MAX_ORDER + 2:
        raise ValueError("moment order exceeds this prototype's explicit limit")
    if not 0 <= z < 1:
        raise ValueError("geometric_moments requires 0 <= z < 1")
    moments = [1 / (1 - z)]
    eulerian = [1]  # A_1(z)=1
    for k in range(1, order + 1):
        polynomial = Fraction(0)
        for coefficient in reversed(eulerian):
            polynomial = polynomial * z + coefficient
        moments.append(z * polynomial / (1 - z) ** (k + 1))
        # A_{k+1}=(1+k*z)*A_k+z*(1-z)*A'_k.
        nxt = [0] * (len(eulerian) + 1)
        for j, coefficient in enumerate(eulerian):
            nxt[j] += (j + 1) * coefficient
            nxt[j + 1] += (k - j) * coefficient
        eulerian = nxt
    return tuple(moments)


@dataclass(frozen=True)
class LerchEnclosure:
    z: Fraction
    s: int
    a: Fraction
    order: int
    polynomial: Fraction
    signed_remainder_lower: Fraction
    signed_remainder_upper: Fraction
    first_omitted_term_magnitude: Fraction
    weighted_mean: Fraction
    weighted_variance: Fraction
    lower: Fraction
    upper: Fraction

    @property
    def width(self) -> Fraction:
        return self.upper - self.lower


def lerch_enclosure(z: Exact, s: int, a: Exact, order: int) -> LerchEnclosure:
    """Enclose Phi(z,s,a), with order equal to the FIRST OMITTED Taylor index.

    The remainder has sign (-1)**order.  The function does not assert that the
    asymptotic expansion converges as order increases at fixed a.
    """
    z, a = _rational(z, "z"), _rational(a, "a")
    _integer(s, "s", 1)
    _integer(order, "order")
    if order > MAX_ORDER:
        raise ValueError(f"order exceeds explicit prototype limit {MAX_ORDER}")
    if not 0 <= z < 1 or a <= 0:
        raise ValueError("requires 0 <= z < 1 and a > 0")
    moments = geometric_moments(z, order + 2)
    polynomial, rising = Fraction(0), 1
    for k in range(order):
        polynomial += (-1) ** k * Fraction(rising, factorial(k)) * moments[k] / a ** (s + k)
        rising *= s + k
    first = Fraction(rising, factorial(order)) * moments[order] / a ** (s + order)
    if first == 0:  # z=0 and order>0: an exact finite source
        mean = variance = lo = hi = Fraction(0)
    else:
        mean = moments[order + 1] / (moments[order] * a * (order + 1))
        second = 2 * moments[order + 2] / (moments[order] * a * a * (order + 1) * (order + 2))
        variance = second - mean * mean
        if variance < 0:
            raise ArithmeticError("negative exact variance indicates an implementation error")
        p = s + order
        lo = first / (1 + mean) ** p
        hi = min(first, lo + first * Fraction(p * (p + 1), 2) * variance)
    if order % 2 == 0:
        lower, upper = polynomial + lo, polynomial + hi
    else:
        lower, upper = polynomial - hi, polynomial - lo
    return LerchEnclosure(z, s, a, order, polynomial, lo, hi, first,
                          mean, variance, lower, upper)


def defining_series_interval(z: Exact, s: int, a: Exact, terms: int = 256) -> tuple[Fraction, Fraction]:
    """Independent exact enclosure using the CONVERGENT defining series.

    No Taylor coefficients or moment bounds are used.  The omitted positive
    tail is at most z**terms / ((a+terms)**s * (1-z)).
    """
    z, a = _rational(z, "z"), _rational(a, "a")
    _integer(s, "s", 1)
    _integer(terms, "terms", 1)
    if not 0 <= z < 1 or a <= 0:
        raise ValueError("requires 0 <= z < 1 and a > 0")
    total, power = Fraction(0), Fraction(1)
    for n in range(terms):
        total += power / (a + n) ** s
        power *= z
    tail = power / ((a + terms) ** s * (1 - z))
    return total, total + tail


if __name__ == "__main__":
    example = lerch_enclosure(Fraction(1, 2), 2, 100, 3)
    print("Exact interval:", example.lower, example.upper)
    print("Display-only decimal interval:", float(example.lower), float(example.upper))
    print("Width / unsigned symmetric-bound width:",
          float(example.width / (2 * example.first_omitted_term_magnitude)))
