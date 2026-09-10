"""Exact-rational enclosure of the real Lambert W_{-1} branch.

This independent reference algorithm does not import or patch Mathics or the
AsymptoticAnalysis package. It uses integer/Fraction arithmetic for every proof
step; optional decimal formatting is NOT used in the enclosure computation.

Domain: z=-q, where q is a positive Fraction strictly below exp(-1).
The irrational branch endpoint itself cannot be a rational input.
SPDX-License-Identifier: MIT-0
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from functools import lru_cache
import argparse
import json


class ProofBudgetExceeded(RuntimeError):
    """A sign could not be certified within the requested resource limits."""


def _ceil_ratio(numerator: int, denominator: int) -> int:
    return -(-numerator // denominator)


def _log_mantissa_bounds(m: Fraction, bits: int) -> tuple[int, int]:
    """Integers l,u with l/2**bits <= log(m) <= u/2**bits, 1 <= m <= 2.

    Uses the atanh series with nonnegative terms. Each term is rounded outwards
    on a dyadic lattice, and the omitted tail has an explicit rational bound.
    No assumed floating-point precision or numerical convergence test occurs.
    """
    if not Fraction(1) <= m <= Fraction(2):
        raise ValueError("mantissa must lie in [1,2]")
    if m == 1:
        return 0, 0
    scale = 1 << bits
    a = (m - 1) / (m + 1)
    an, ad = a.numerator, a.denominator
    pn, pd = an, ad
    lo = hi = 0
    # a <= 1/3; the explicit tail bound is valid for any count.
    count = bits // 3 + 4
    for j in range(count):
        numerator = 2 * pn * scale
        denominator = (2*j + 1) * pd
        lo += numerator // denominator
        hi += _ceil_ratio(numerator, denominator)
        pn *= an * an
        pd *= ad * ad
    # Now pn/pd = a**(2*count+1).
    tail_n = 2 * pn * ad * ad * scale
    tail_d = (2*count + 1) * pd * (ad*ad - an*an)
    hi += _ceil_ratio(tail_n, tail_d)
    return lo, hi


@lru_cache(maxsize=128)
def _log_two_bounds(bits: int) -> tuple[int, int]:
    return _log_mantissa_bounds(Fraction(2), bits)


def log_interval(value: Fraction, bits: int = 128) -> tuple[Fraction, Fraction]:
    """Return a rigorous rational interval containing log(value)."""
    if not isinstance(value, Fraction):
        raise TypeError("value must be Fraction (not a binary float)")
    if value <= 0:
        raise ValueError("log argument must be positive")
    if not isinstance(bits, int) or isinstance(bits, bool) or bits < 8:
        raise ValueError("bits must be an integer >= 8")
    k = value.numerator.bit_length() - value.denominator.bit_length()
    m = value / (Fraction(2) ** k)
    if m < 1:
        k -= 1
        m *= 2
    elif m >= 2:
        k += 1
        m /= 2
    assert 1 <= m < 2
    ml, mu = _log_mantissa_bounds(m, bits)
    ll, lu = _log_two_bounds(bits)
    if k >= 0:
        low, high = ml + k*ll, mu + k*lu
    else:
        low, high = ml + k*lu, mu + k*ll
    scale = 1 << bits
    return Fraction(low, scale), Fraction(high, scale)


@dataclass(frozen=True)
class LambertMinusOneEnclosure:
    q: Fraction
    lower: Fraction
    upper: Fraction
    decimal_digits: int
    bisections: int
    maximum_working_bits: int
    h_at_t_lower: tuple[Fraction, Fraction]
    h_at_t_upper: tuple[Fraction, Fraction]

    @property
    def width(self) -> Fraction:
        return self.upper - self.lower

    def to_dict(self) -> dict:
        return {
            "q": str(self.q), "z": str(-self.q),
            "branch": -1, "lower": str(self.lower), "upper": str(self.upper),
            "width": str(self.width), "requested_decimal_digits": self.decimal_digits,
            "bisections": self.bisections,
            "maximum_working_bits": self.maximum_working_bits,
            "h_at_t_lower": [str(v) for v in self.h_at_t_lower],
            "h_at_t_upper": [str(v) for v in self.h_at_t_upper],
            "proof": "h(t)=t-log(t)+log(q), h'(t)>0 for t>1; outward rational log bounds",
        }


def lambert_minus_one(q: Fraction, digits: int = 30, *,
                      max_bits: int = 16384,
                      max_bisections: int = 10000) -> LambertMinusOneEnclosure:
    """Enclose W_{-1}(-q) in a rational interval of width <= 10**(-digits).

    Resource exhaustion raises ProofBudgetExceeded, never returns a guessed sign.
    """
    if not isinstance(q, Fraction):
        raise TypeError("q must be Fraction; use Fraction('0.1') for decimal input")
    if q <= 0:
        raise ValueError("q must be positive")
    if not isinstance(digits, int) or isinstance(digits, bool) or not 1 <= digits <= 1000:
        raise ValueError("digits must be an integer in [1,1000]")
    if not isinstance(max_bits, int) or max_bits < 32:
        raise ValueError("max_bits must be an integer >= 32")
    if not isinstance(max_bisections, int) or max_bisections < 1:
        raise ValueError("max_bisections must be positive")
    bits = min(max_bits, max(64, 4*digits + 32))
    largest_bits = bits
    log_q_cache: dict[int, tuple[Fraction, Fraction]] = {}

    def h_bounds(t: Fraction, b: int) -> tuple[Fraction, Fraction]:
        if b not in log_q_cache:
            log_q_cache[b] = log_interval(q, b)
        ql, qu = log_q_cache[b]
        tl, tu = log_interval(t, b)
        return t - tu + ql, t - tl + qu

    def sign_at(t: Fraction) -> tuple[int, tuple[Fraction, Fraction]]:
        nonlocal largest_bits
        b = bits
        while True:
            interval = h_bounds(t, b)
            largest_bits = max(largest_bits, b)
            if interval[1] < 0:
                return -1, interval
            if interval[0] > 0:
                return 1, interval
            if b >= max_bits:
                raise ProofBudgetExceeded(f"unresolved sign at t={t}; max_bits={max_bits}")
            b = min(2*b, max_bits)

    lower_t = Fraction(1)
    lower_sign, lower_h = sign_at(lower_t)
    if lower_sign != -1:
        raise ValueError("q must be strictly below exp(-1)")
    upper_t = Fraction(2)
    for _ in range(max_bisections):
        upper_sign, upper_h = sign_at(upper_t)
        if upper_sign == 1:
            break
        upper_t *= 2
    else:
        raise ProofBudgetExceeded("initial bracket budget exceeded")
    tolerance = Fraction(1, 10**digits)
    iterations = 0
    while upper_t - lower_t > tolerance:
        if iterations >= max_bisections:
            raise ProofBudgetExceeded("bisection budget exceeded")
        middle = (upper_t + lower_t) / 2
        sign, h = sign_at(middle)
        if sign < 0:
            lower_t, lower_h = middle, h
        else:
            upper_t, upper_h = middle, h
        iterations += 1
    assert lower_t >= 1 and lower_h[1] < 0 < upper_h[0]
    return LambertMinusOneEnclosure(q, -upper_t, -lower_t, digits, iterations,
                                   largest_bits, lower_h, upper_h)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("q", help="positive rational q, e.g. 1/10 or 0.1; input z=-q")
    parser.add_argument("--digits", type=int, default=30)
    args = parser.parse_args()
    print(json.dumps(lambert_minus_one(Fraction(args.q), args.digits).to_dict(), indent=2))


if __name__ == "__main__":
    main()
