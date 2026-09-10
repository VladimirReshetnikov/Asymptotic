"""Exact rational Euler-transform enclosures for Phi(-q, s, a).

This independent reference is not installed in AsymptoticAnalysis.
The theorem allows real s > 0; this implementation deliberately accepts
positive integer s, rational a > 0, and rational 0 <= q <= 1 only.
No floating-point input, native CAS, or network access is used.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from typing import Union

RationalInput = Union[int, Fraction]
MAX_ORDER = 256
MAX_EXPONENT = 1000
MAX_INPUT_BITS = 4096


def rational(value: RationalInput, name: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be an int or fractions.Fraction, not a float or bool")
    result = Fraction(value)
    if max(abs(result.numerator).bit_length(), result.denominator.bit_length()) > MAX_INPUT_BITS:
        raise ValueError(f"{name} exceeds the {MAX_INPUT_BITS}-bit input budget")
    return result


def integer(value: int, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError(f"{name} must be an integer")
    if not minimum <= value <= maximum:
        raise ValueError(f"{name} must lie in [{minimum}, {maximum}]")
    return value


@dataclass(frozen=True)
class LerchEnclosure:
    q: Fraction
    s: int
    a: Fraction
    order: int
    partial_sum: Fraction
    difference_coefficient: Fraction
    lower: Fraction
    upper: Fraction

    @property
    def width(self) -> Fraction:
        return self.upper - self.lower

    def as_record(self) -> dict:
        return {"q": str(self.q), "s": self.s, "a": str(self.a), "order": self.order,
                "partial_sum": str(self.partial_sum),
                "difference_coefficient": str(self.difference_coefficient),
                "lower": str(self.lower), "upper": str(self.upper), "width": str(self.width)}


def difference_coefficients(s: int, a: RationalInput, order: int) -> tuple[Fraction, ...]:
    """D_k = sum_j (-1)^j binomial(k,j) (a+j)^(-s), k=0,...,order.

    A difference table uses O(order**2) exact subtractions and O(order)
    stored rational values. This is an arithmetic-operation count, not a
    constant-bit-cost bound. Rational numerator/denominator sizes can grow.
    """
    s = integer(s, "s", 1, MAX_EXPONENT)
    order = integer(order, "order", 0, MAX_ORDER)
    a = rational(a, "a")
    if a <= 0:
        raise ValueError("a must be strictly positive")
    row = [Fraction(1) / (a+j)**s for j in range(order+1)]
    result: list[Fraction] = []
    while row:
        result.append(row[0])
        row = [left-right for left, right in zip(row, row[1:])]
    return tuple(result)


def lerch_negative_interval(q: RationalInput, s: int, a: RationalInput,
                            order: int = 16) -> LerchEnclosure:
    """Return a proved enclosure of Phi(-q, s, a), including q=1.

    E_K = (1+q)^(-1) sum_{k<K} r^k D_k, r=q/(1+q).
    Lower = E_K + r^K D_K/(1+q), upper = E_K + r^K D_K.
    The closed width is r^(K+1) D_K. Fraction's 0**0=1 implements
    the empty-power convention needed at q=0, K=0.
    """
    q = rational(q, "q")
    a = rational(a, "a")
    s = integer(s, "s", 1, MAX_EXPONENT)
    order = integer(order, "order", 0, MAX_ORDER)
    if not 0 <= q <= 1:
        raise ValueError("q must lie in [0,1]")
    if a <= 0:
        raise ValueError("a must be strictly positive")
    ds = difference_coefficients(s, a, order)
    r = q/(1+q)
    partial = sum((r**k * ds[k]/(1+q) for k in range(order)), Fraction(0))
    tail = r**order * ds[-1]
    return LerchEnclosure(q, s, a, order, partial, ds[-1],
                         partial+tail/(1+q), partial+tail)


def log1p_interval(q: RationalInput, terms: int = 96) -> tuple[Fraction, Fraction]:
    """Independent exact log(1+q) enclosure by the atanh series, 0<=q<=1."""
    q = rational(q, "q")
    terms = integer(terms, "terms", 1, 1000)
    if not 0 <= q <= 1:
        raise ValueError("q must lie in [0,1]")
    u = q/(2+q)
    lo = 2*sum((u**(2*j+1)/Fraction(2*j+1) for j in range(terms)), Fraction(0))
    tail = 2*u**(2*terms+1)/(Fraction(2*terms+1)*(1-u*u))
    return lo, lo+tail


def lerch_s1_integer_a_reference(q: RationalInput, a: int,
                               terms: int = 96) -> tuple[Fraction, Fraction]:
    """Independent closed form for s=1, integral a>=1; uses no Euler table."""
    q = rational(q, "q")
    a = integer(a, "a", 1, 100)
    if not 0 <= q <= 1:
        raise ValueError("q must lie in [0,1]")
    if q == 0:
        return Fraction(1, a), Fraction(1, a)
    loglo, loghi = log1p_interval(q, terms)
    finite = sum(((-q)**j/Fraction(j) for j in range(1, a)), Fraction(0))
    scale = (-q)**(-a)
    ends = [scale*(-loghi-finite), scale*(-loglo-finite)]
    return min(ends), max(ends)


def alternating_reference(q: RationalInput, s: int, a: RationalInput,
                          terms: int = 128) -> tuple[Fraction, Fraction]:
    """Independent alternating partial-sum enclosure; may be wide at q=1."""
    q = rational(q, "q"); a = rational(a, "a")
    s = integer(s, "s", 1, MAX_EXPONENT)
    terms = integer(terms, "terms", 1, 2000)
    if not (0 <= q <= 1 and a > 0):
        raise ValueError("require 0<=q<=1 and a>0")
    total = sum(((-q)**j/(a+j)**s for j in range(terms)), Fraction(0))
    other = total+(-q)**terms/(a+terms)**s
    return min(total, other), max(total, other)
