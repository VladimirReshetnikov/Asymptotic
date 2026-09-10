"""Restricted independent models for the 921387e Asymptotic audit.

These routines do not execute Wolfram Language or claim to implement the package.
They model selected exact-rational arithmetic, target geometry, and flat grading.
Python 3.10+; standard library only.
"""
from __future__ import annotations
from dataclasses import dataclass
from decimal import Decimal, localcontext
from fractions import Fraction as Q
from math import factorial
from typing import Iterable

Interval = tuple[Q, Q]
Poly = dict[int, Q]


def sign(x: Q) -> int:
    return (x > 0) - (x < 0)


def monomial_approach(q: Q, a: Q, offset: Q = Q(0)) -> tuple[str, str]:
    """y = offset + a*u**q, u -> 0+, with a*q != 0."""
    if not q or not a:
        raise ValueError("q and a must be nonzero")
    if q > 0:
        return str(offset), "FromAbove" if a > 0 else "FromBelow"
    return ("Infinity", "FromBelow") if a > 0 else ("-Infinity", "FromAbove")


def baseline_flat_approach(q: Q, a: Q, offset: Q = Q(0)) -> tuple[str, str]:
    """The inspected fallback selects Offset without checking CorePower."""
    if not q or not a:
        raise ValueError("q and a must be nonzero")
    return str(offset), "FromAbove" if a > 0 else "FromBelow"


def erfc_approach(source_sign: int, target_scale: Q,
                  offset: Q = Q(0)) -> tuple[str, str]:
    if source_sign not in (-1, 1) or not target_scale:
        raise ValueError("invalid orientation")
    point = offset if source_sign == 1 else offset + 2 * target_scale
    return str(point), "FromAbove" if source_sign * target_scale > 0 else "FromBelow"


def baseline_erfc_approach(source_sign: int, target_scale: Q,
                           offset: Q = Q(0)) -> tuple[str, str]:
    point, _ = erfc_approach(source_sign, target_scale, offset)
    return point, "FromAbove" if target_scale > 0 else "FromBelow"


def quadratic_approach(coefficient: Q, target_scale: Q,
                       offset: Q = Q(0)) -> tuple[str, str]:
    return monomial_approach(Q(2), coefficient * target_scale, offset)


def pow2(n: int) -> Q:
    return Q(2**n) if n >= 0 else Q(1, 2**(-n))


def rounded(q: Q, bits: int, upper: bool) -> Q:
    """Exact counterpart of certRound, not floating-point rounding."""
    if bits < 2:
        raise ValueError("bits must be >= 2")
    if not q:
        return Q(0)
    a = abs(q)
    exponent = a.numerator.bit_length() - a.denominator.bit_length()
    if a < pow2(exponent):
        exponent -= 1
    grid = pow2(exponent - bits + 1)
    ratio = q / grid
    floor = ratio.numerator // ratio.denominator
    ceil = -((-ratio.numerator) // ratio.denominator)
    return grid * (ceil if upper else floor)


def round_interval(a: Interval, bits: int) -> Interval:
    if a[0] > a[1]:
        raise ValueError("unordered interval")
    return rounded(a[0], bits, False), rounded(a[1], bits, True)


def add(a: Interval, b: Interval, bits: int) -> Interval:
    return round_interval((a[0] + b[0], a[1] + b[1]), bits)


def mul(a: Interval, b: Interval, bits: int) -> Interval:
    products = [x * y for x in a for y in b]
    return round_interval((min(products), max(products)), bits)


def reciprocal(a: Interval, bits: int) -> Interval:
    if a[0] <= 0 <= a[1]:
        raise ValueError("singular interval")
    return round_interval((1 / a[1], 1 / a[0]), bits)


def square(a: Interval, bits: int) -> Interval:
    vals = [a[0]**2, a[1]**2]
    return round_interval((Q(0) if a[0] <= 0 <= a[1] else min(vals), max(vals)), bits)


def sqrt2_certificate(interval: Interval, center: Q, order: int) -> dict:
    """certAttempt's relevant arithmetic for f(x)=x^2, target=2, x>0.

    The first residual bracket is contained; later intervals contain the root
    by the previous certificate. Continuity and positive derivative are direct.
    """
    bits = 4 * (order + 10)
    derivative = mul((Q(2), Q(2)), interval, bits)
    if derivative[0] <= 0:
        raise ValueError("derivative not separated")
    residual = add(square((center, center), bits), (Q(-2), Q(-2)), bits)
    epsilon = max(map(abs, residual))
    radius = epsilon / derivative[0]
    correction = mul(residual, reciprocal(derivative, bits), bits)
    sharp = (max(interval[0], center - radius, center - correction[1]),
             min(interval[1], center + radius, center - correction[0]))
    if sharp[0] > sharp[1]:
        raise ArithmeticError("empty root enclosure")
    # Exact, independent verification that the new positive interval contains sqrt(2).
    if not (0 < sharp[0] and sharp[0]**2 <= 2 <= sharp[1]**2):
        raise ArithmeticError("sqrt(2) containment failed")
    return dict(interval=sharp, center=center, radius=radius,
                residual=residual, order=order, bits=bits,
                sharp_bound=max(abs(sharp[0]-center),abs(sharp[1]-center)))


def run_certificate_policy(*, initial_order: int = 2,
                           target_error: Q = Q(1, 10**60),
                           maximum: int = 64, adaptive: bool = False) -> dict:
    """Compare inspected successful-attempt scheduling with simple escalation.

    Center is a high-accuracy rational seed, not a native-kernel observation.
    The repaired model doubles order after every certificate that misses its
    goal. The report recommends a more selective uncertainty/stagnation rule.
    """
    with localcontext() as ctx:
        ctx.prec = 90
        center = Q(Decimal(2).sqrt())
    interval = (Q(1), Q(2))
    order = initial_order
    history = []
    for i in range(maximum + 1):
        c = sqrt2_certificate(interval, center, order)
        history.append(dict(iteration=i, order=order, bits=c['bits'],
                            radius_exact=str(c['radius']), radius=float(c['radius']),
                            sharp_bound_exact=str(c['sharp_bound']), sharp_bound=float(c['sharp_bound']),
                            interval_width=float(c['interval'][1]-c['interval'][0])))
        if c['radius'] <= target_error:
            return dict(reached=True, history=history)
        interval = c['interval']
        center = (interval[0] + interval[1]) / 2
        if adaptive:
            order = min(2000, 2 * order)
    return dict(reached=False, history=history)


@dataclass(frozen=True)
class Envelope:
    """E**sector * O(u**power * (1+abs(log(u)))**log_degree)."""
    sector: int
    power: Q
    log_degree: int = 0

    def __post_init__(self) -> None:
        if self.sector < 0 or self.log_degree < 0:
            raise ValueError("negative sector or logarithmic degree")

    def key(self) -> tuple:
        return self.sector, self.power, -self.log_degree

    def product(self, other: Envelope) -> Envelope:
        return Envelope(self.sector + other.sector,
                        self.power + other.power,
                        self.log_degree + other.log_degree)


def dominant(envelopes: Iterable[Envelope]) -> Envelope | None:
    return min(envelopes, key=Envelope.key, default=None)


def poly_add(a: Poly, b: Poly) -> Poly:
    c = dict(a)
    for p, v in b.items():
        c[p] = c.get(p, Q(0)) + v
        if not c[p]:
            del c[p]
    return c


def poly_mul(a: Poly, b: Poly) -> Poly:
    c: Poly = {}
    for i, x in a.items():
        for j, y in b.items():
            c[i + j] = c.get(i + j, Q(0)) + x * y
    return {p: v for p, v in c.items() if v}


def exponential_derivative(a: Poly, rate: int) -> Poly:
    """(d/du + rate/u**2) a(u), after factoring exp(-rate/u)."""
    ordinary = {p-1: p*v for p, v in a.items() if p}
    phase = {p-2: rate*v for p, v in a.items()}
    return poly_add(ordinary, phase)


def flat_inverse_coefficient(k: int) -> Poly:
    """Coefficient of E**k for inverse of x + exp(-1/x), E=exp(-1/y)."""
    if k < 1:
        raise ValueError("k must be positive")
    c = {0: Q(1)}
    for _ in range(k-1):
        c = exponential_derivative(c, k)
    factor = Q((-1)**k, factorial(k))
    return {p: factor*v for p, v in c.items()}


def flat_square_tail(n: int) -> dict:
    if n < 1:
        raise ValueError("n must be positive")
    coeffs = [{1: Q(1)}] + [flat_inverse_coefficient(k) for k in range(1, n+1)]
    tail = Envelope(n+1, Q(-2*n))
    candidates = []
    for i, ai in enumerate(coeffs):
        for j, bj in enumerate(coeffs):
            if i+j > n:
                candidates.append(Envelope(i+j, Q(min(ai)+min(bj))))
    for j, bj in enumerate(coeffs):
        candidates.append(tail.product(Envelope(j, Q(min(bj)))))
        candidates.append(Envelope(j, Q(min(bj))).product(tail))
    candidates.append(tail.product(tail))
    best = dominant(candidates)
    assert best is not None
    legacy_power = min(c.power for c in candidates)
    return dict(depth=n, baseline_power=str(legacy_power),
                graded_sector=best.sector, graded_power=str(best.power),
                algebraic_orders_saved=str(best.power-legacy_power),
                full_coefficient_pairs=(n+1)**2,
                retained_coefficient_pairs=(n+1)*(n+2)//2)
