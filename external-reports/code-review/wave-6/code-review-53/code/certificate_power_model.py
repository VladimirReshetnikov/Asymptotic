"""Independent exact-rational models for the Asymptotic certificate audit.

This is NOT the Wolfram package and is NOT an interpreter for Wolfram Language.
legacy_integer_power mirrors the inspected arithmetic algorithm.  The other
functions are candidate algorithms, checked against separate exact oracles.
Python 3.9+; no third-party dependencies.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from typing import Union

Rational = Union[int, Fraction]


def rational(value: Rational) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError("An exact integer or Fraction is required")
    return Fraction(value)


@dataclass(frozen=True)
class Interval:
    lo: Fraction
    hi: Fraction

    def __post_init__(self) -> None:
        object.__setattr__(self, "lo", rational(self.lo))
        object.__setattr__(self, "hi", rational(self.hi))
        if self.lo > self.hi:
            raise ValueError("Unordered interval")

    def contains(self, value: Rational) -> bool:
        q = rational(value)
        return self.lo <= q <= self.hi

    def includes(self, other: Interval) -> bool:
        return self.lo <= other.lo and other.hi <= self.hi


@dataclass(frozen=True)
class Limits:
    max_integer_exponent: int = 100_000
    max_root_degree: int = 128
    max_work_bits: int = 1_000_000


class BudgetExceeded(ValueError):
    pass


def pow2(exponent: int) -> Fraction:
    return Fraction(1 << exponent) if exponent >= 0 else Fraction(1, 1 << -exponent)


def floor_log2(q: Fraction) -> int:
    if q <= 0:
        raise ValueError("Positive rational required")
    e = q.numerator.bit_length() - q.denominator.bit_length()
    return e - 1 if q < pow2(e) else e


def round_dyadic(q: Rational, bits: int, upper: bool) -> Fraction:
    q = rational(q)
    if isinstance(bits, bool) or not isinstance(bits, int) or bits < 2:
        raise ValueError("bits must be an integer >= 2")
    if not q:
        return q
    grid = pow2(floor_log2(abs(q)) - bits + 1)
    scaled = q / grid
    m = (-(-scaled.numerator // scaled.denominator) if upper
         else scaled.numerator // scaled.denominator)
    return m * grid


def rounded(a: Interval, bits: int) -> Interval:
    return Interval(round_dyadic(a.lo, bits, False),
                    round_dyadic(a.hi, bits, True))


def multiply(a: Interval, b: Interval, bits: int) -> Interval:
    values = [a.lo*b.lo, a.lo*b.hi, a.hi*b.lo, a.hi*b.hi]
    return rounded(Interval(min(values), max(values)), bits)


def add(a: Interval, b: Interval, bits: int) -> Interval:
    return rounded(Interval(a.lo+b.lo, a.hi+b.hi), bits)


def reciprocal(a: Interval, bits: int) -> Interval:
    if a.lo <= 0 <= a.hi:
        raise ValueError("Interval reciprocal contains zero")
    return rounded(Interval(1/a.hi, 1/a.lo), bits)


def square(a: Interval, bits: int) -> Interval:
    values = [a.lo*a.lo, a.hi*a.hi]
    return rounded(Interval(0 if a.lo <= 0 <= a.hi else min(values),
                            max(values)), bits)


def _check_exponent(n: int, limits: Limits) -> None:
    if isinstance(n, bool) or not isinstance(n, int):
        raise TypeError("Integer exponent required")
    if abs(n) > limits.max_integer_exponent:
        raise BudgetExceeded("Integer exponent budget")


def legacy_integer_power(a: Interval, n: int, bits: int = 80,
                         limits: Limits = Limits()) -> Interval:
    """Source-faithful model of certIntegerPower (not package execution)."""
    _check_exponent(n, limits)
    base, power, answer = a, abs(n), Interval(1, 1)
    if n < 0:
        base = reciprocal(base, bits)
    while power > 0:
        if power % 2:
            answer = multiply(answer, base, bits)
        power //= 2
        if power > 0:
            base = square(base, bits)
    return answer


def integer_power(a: Interval, n: int, bits: int = 80,
                  limits: Limits = Limits()) -> Interval:
    """Range-aware endpoint powering, retaining bounded rounded products."""
    _check_exponent(n, limits)
    if n == 0:
        return Interval(1, 1)
    if n < 0:
        a, n = reciprocal(a, bits), -n
    left = legacy_integer_power(Interval(a.lo, a.lo), n, bits, limits)
    right = legacy_integer_power(Interval(a.hi, a.hi), n, bits, limits)
    if n % 2:
        return Interval(left.lo, right.hi)
    if a.lo >= 0:
        return Interval(left.lo, right.hi)
    if a.hi <= 0:
        return Interval(right.lo, left.hi)
    return Interval(0, max(left.hi, right.hi))


def integer_root_floor(n: int, d: int) -> int:
    """floor(n**(1/d)), using integer Newton iteration, never floating point."""
    if not isinstance(n, int) or n < 0 or not isinstance(d, int) or d < 1:
        raise ValueError("Nonnegative integer and positive degree required")
    if n < 2 or d == 1:
        return n
    if d >= n.bit_length():
        return 1
    if n & (n-1) == 0 and (n.bit_length()-1) % d == 0:
        return 1 << ((n.bit_length()-1)//d)
    x = 1 << ((n.bit_length()+d-1)//d)
    while True:
        y = ((d-1)*x + n//pow(x, d-1))//d
        if y >= x:
            return x
        x = y


def _v2(n: int) -> int:
    return (n & -n).bit_length()-1


def root_point(q: Rational, d: int, bits: int = 80,
               limits: Limits = Limits()) -> Interval:
    """Enclose the nonnegative real d-th root of an exact rational.

    Nonperfect roots use a significant-bit dyadic grid. Exact rational roots
    are returned exactly. Resource limits are checked before shifted operands.
    """
    q = rational(q)
    if q < 0:
        raise ValueError("Negative bases are not admitted")
    if isinstance(d, bool) or not isinstance(d, int) or d < 1:
        raise ValueError("Positive integer degree required")
    if isinstance(bits, bool) or not isinstance(bits, int) or bits < 2:
        raise ValueError("bits must be an integer >= 2")
    if d > limits.max_root_degree:
        raise BudgetExceeded("Root-degree budget")
    a, b = q.numerator, q.denominator
    if max(a.bit_length(), b.bit_length()) > limits.max_work_bits:
        raise BudgetExceeded("Input-rational bit budget")
    if not q or d == 1:
        return Interval(q, q)
    ra, rb = integer_root_floor(a, d), integer_root_floor(b, d)
    if pow(ra, d) == a and pow(rb, d) == b:
        r = Fraction(ra, rb)
        return Interval(r, r)
    k = floor_log2(q)//d
    gexp = k-bits+1
    shift = d*gexp
    if shift >= 0:
        cancel = min(_v2(a), shift)
        a >>= cancel
        shift -= cancel
        if b.bit_length()+shift > limits.max_work_bits:
            raise BudgetExceeded("Scaled-denominator bit budget")
        b <<= shift
    else:
        shift = -shift
        cancel = min(_v2(b), shift)
        b >>= cancel
        shift -= cancel
        if a.bit_length()+shift > limits.max_work_bits:
            raise BudgetExceeded("Scaled-numerator bit budget")
        a <<= shift
    m = integer_root_floor(a//b, d)
    grid = pow2(gexp)
    lo = m*grid
    hi = lo if pow(m, d)*b == a else (m+1)*grid
    return Interval(lo, hi)


def rational_power(a: Interval, exponent: Rational, bits: int = 80,
                   limits: Limits = Limits()) -> Interval:
    exponent = rational(exponent)
    p, d = exponent.numerator, exponent.denominator
    _check_exponent(p, limits)
    if d == 1:
        return integer_power(a, p, bits, limits)
    if a.lo < 0 or (p < 0 and a.lo <= 0):
        raise ValueError("Principal-real rational power requires an admitted nonnegative base")
    left = root_point(a.lo, d, bits, limits)
    right = root_point(a.hi, d, bits, limits)
    return integer_power(Interval(left.lo, right.hi), p, bits, limits)


def legacy_log_point(q: Rational, order: int) -> Interval:
    """Exact model of certLogPoint/Unit, solely to test the magnitude witness."""
    q = rational(q)
    if q <= 0 or order < 2:
        raise ValueError("Positive rational and order >= 2 required")
    bits = 4*(order+10)

    def unit(t: Fraction) -> Interval:
        if t == 1:
            return Interval(0, 0)
        u = (t-1)/(t+1)
        s = 2*sum((u**(2*k+1)/Fraction(2*k+1) for k in range(order)), Fraction(0))
        tail = 2*u**(2*order+1)/(Fraction(2*order+1)*(1-u*u))
        return rounded(Interval(s, s+tail), bits)

    e = floor_log2(q)
    r = unit(q/pow2(e))
    if e == 0:
        return r
    return add(r, multiply(Interval(e, e), unit(Fraction(2)), bits), bits)


def retry_orders(max_refinements: int, initial_order: int = 60,
                 terminal: bool = False) -> list[int]:
    """A model of the persistent-failure branch of the inspected retry loop."""
    if max_refinements < 0 or initial_order < 2 or initial_order > 2000:
        raise ValueError("Invalid retry request")
    history, order = [], initial_order
    for iteration in range(max_refinements+1):
        history.append(order)
        if terminal:
            break
        order = min(2000, 2*order)
    return history
