"""Exact rational model of the reviewed logarithm enclosures.

This is NOT the repository and is NOT a Mathics execution.  baseline_log_point
transcribes certRound/certLogUnit/certLogPoint at the pinned revision.  The stable
variant and affine_log implement the proposed, separately proved changes.
No binary floating-point arithmetic participates in the enclosure calculation.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from typing import TypeAlias

Interval: TypeAlias = tuple[F, F]

@dataclass(frozen=True)
class Context:
    order: int = 2
    bits: int = 48
    def __post_init__(self) -> None:
        if type(self.order) is not int or self.order < 2:
            raise ValueError("order must be an integer >= 2")
        if type(self.bits) is not int or self.bits < 2:
            raise ValueError("bits must be an integer >= 2")


def pow2(n: int) -> F:
    return F(2**n) if n >= 0 else F(1, 2**(-n))


def floor_log2(q: F) -> int:
    q = F(q)
    if q <= 0:
        raise ValueError("floor_log2 requires a positive rational")
    exponent = q.numerator.bit_length() - q.denominator.bit_length()
    return exponent - (q < pow2(exponent))


def round_point(q: F, bits: int, upper: bool) -> F:
    q = F(q)
    if not q:
        return F(0)
    grid = pow2(floor_log2(abs(q)) - bits + 1)
    scaled = q / grid
    integer = (-((-scaled.numerator) // scaled.denominator) if upper
               else scaled.numerator // scaled.denominator)
    return integer * grid


def outward(a: Interval, ctx: Context) -> Interval:
    if a[0] > a[1]:
        raise ValueError("unordered interval")
    return round_point(a[0], ctx.bits, False), round_point(a[1], ctx.bits, True)


def add(a: Interval, b: Interval, ctx: Context) -> Interval:
    return outward((a[0]+b[0], a[1]+b[1]), ctx)


def negate(a: Interval) -> Interval:
    return -a[1], -a[0]


def multiply(a: Interval, b: Interval, ctx: Context) -> Interval:
    products = [x*y for x in a for y in b]
    return outward((min(products), max(products)), ctx)


def log_unit(q: F, ctx: Context) -> Interval:
    q = F(q)
    if not F(1) <= q <= F(2):
        raise ValueError("log_unit requires 1 <= q <= 2")
    if q == 1:
        return F(0), F(0)
    u = (q-1)/(q+1)
    n = ctx.order
    partial = 2*sum((u**(2*k+1)/F(2*k+1) for k in range(n)), F(0))
    tail = 2*u**(2*n+1)/(F(2*n+1)*(1-u*u))
    return outward((partial, partial+tail), ctx)


def baseline_log_point(q: F, ctx: Context) -> Interval:
    q = F(q)
    if q <= 0:
        raise ValueError("logarithm requires a positive rational")
    if q == 1:
        return F(0), F(0)
    exponent = floor_log2(q)
    unit = log_unit(q / pow2(exponent), ctx)
    if exponent == 0:
        return unit
    return add(unit, multiply((F(exponent), F(exponent)), log_unit(F(2), ctx), ctx), ctx)


def stable_log_point(q: F, ctx: Context) -> Interval:
    q = F(q)
    if q <= 0:
        raise ValueError("logarithm requires a positive rational")
    if q < 1:
        return negate(baseline_log_point(1/q, ctx))
    return baseline_log_point(q, ctx)


def log_interval(a: Interval, ctx: Context, *, reciprocal: bool = True) -> Interval:
    if a[0] <= 0 or a[0] > a[1]:
        raise ValueError("logarithm interval must be ordered and strictly positive")
    point = stable_log_point if reciprocal else baseline_log_point
    return point(a[0], ctx)[0], point(a[1], ctx)[1]


def affine_log(a: F, b: F, interval: Interval, ctx: Context, *,
               fused: bool, reciprocal: bool = True) -> Interval:
    """Enclose log(a*x+b), optionally avoiding premature argument rounding."""
    if interval[0] > interval[1]:
        raise ValueError("unordered interval")
    endpoints = sorted([F(a)*x+F(b) for x in interval])
    image = endpoints[0], endpoints[1]
    if not fused:
        image = outward(image, ctx)
    return log_interval(image, ctx, reciprocal=reciprocal)


def tail_at_two(n: int) -> F:
    if type(n) is not int or n < 1:
        raise ValueError("n must be a positive integer")
    return F(3, 4*(2*n+1)*3**(2*n))


def width(a: Interval) -> F:
    return a[1]-a[0]
