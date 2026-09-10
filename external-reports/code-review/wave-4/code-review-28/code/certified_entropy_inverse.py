"""Exact rational enclosure of the small inverse of -x*log(x).

Admitted targets: rational 0 < y <= 1/4.  No floating-point arithmetic is
used to establish the certificate.  This is an independent reference
implementation, not a patch to AsymptoticAnalysis or a general Lambert W API.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from fractions import Fraction as F
from functools import lru_cache
import json
from pathlib import Path


def _fraction(value: F | int | str) -> F:
    if isinstance(value, (float, bool)):
        raise TypeError("Use an exact Fraction, integer, or rational string")
    return F(value)


def _unit_log_bounds(q: F, terms: int) -> tuple[F, F]:
    """Bounds for log(q), 1 <= q <= 2, from the atanh series."""
    if not F(1) <= q <= F(2):
        raise ValueError("Internal range-reduction invariant failed")
    z = (q - 1) / (q + 1)
    z2 = z*z
    power, total = z, F(0)
    for j in range(terms):
        total += 2*power/(2*j + 1)
        power *= z2
    tail = 2*power/((2*terms + 1)*(1-z2))
    return total, total + tail


@lru_cache(maxsize=16)
def _log2_bounds(terms: int) -> tuple[F, F]:
    return _unit_log_bounds(F(2), terms)


def log_bounds(q: F | int | str, terms: int = 24) -> tuple[F, F]:
    q = _fraction(q)
    if q <= 0 or not isinstance(terms, int) or isinstance(terms, bool) or terms < 1:
        raise ValueError("Positive rational argument and positive integer term count required")
    k = q.numerator.bit_length() - q.denominator.bit_length()
    scale = F(2)**k
    v = q/scale
    if v < 1:
        k -= 1
        v *= 2
    elif v >= 2:
        k += 1
        v /= 2
    low, high = _unit_log_bounds(v, terms)
    l2, h2 = _log2_bounds(terms)
    return (low + k*l2, high + k*h2) if k >= 0 else (low + k*h2, high + k*l2)


def residual_bounds(x: F, y: F, terms: int) -> tuple[F, F]:
    lower_log, upper_log = log_bounds(x, terms)
    return -x*upper_log-y, -x*lower_log-y


def _signed_residual(x: F, y: F, initial_terms: int, max_terms: int):
    terms = initial_terms
    while terms <= max_terms:
        lo, hi = residual_bounds(x, y, terms)
        if hi < 0:
            return -1, terms, (lo, hi)
        if lo > 0:
            return 1, terms, (lo, hi)
        terms *= 2
    raise ArithmeticError("Logarithm enclosure budget exhausted; no sign was guessed")


@dataclass(frozen=True)
class Certificate:
    target: F
    lower: F
    upper: F
    bits: int
    logarithm_terms: int
    iterations: int

    def verify(self) -> bool:
        """Recheck final enclosure without trusting the construction history."""
        if not all(isinstance(v, F) for v in (self.target, self.lower, self.upper)):
            return False
        if (not isinstance(self.bits, int) or isinstance(self.bits, bool)
                or not 1 <= self.bits <= 4096
                or not isinstance(self.logarithm_terms, int)
                or isinstance(self.logarithm_terms, bool) or self.logarithm_terms < 1):
            return False
        if not (0 < self.target <= F(1, 4) and 0 < self.lower < self.upper <= F(1, 4)):
            return False
        if self.upper-self.lower > F(1, 2**self.bits):
            return False
        # f'(x) = -log(x)-1 >= log(4)-1 > 0 on this whole interval.
        if log_bounds(F(4), self.logarithm_terms)[0] <= 1:
            return False
        return (residual_bounds(self.lower, self.target, self.logarithm_terms)[1] < 0
                and residual_bounds(self.upper, self.target, self.logarithm_terms)[0] > 0)

    def as_dict(self) -> dict:
        w_lo, w_hi = -self.target/self.lower, -self.target/self.upper
        return {
            "Equation": "-x log(x) = y", "Target": str(self.target),
            "SourceInterval": [str(self.lower), str(self.upper)],
            "AbsoluteSourceWidth": str(self.upper-self.lower),
            "RequestedSourceWidth": f"1/{2**self.bits}",
            "LambertWMinusOneInterval": [str(w_lo), str(w_hi)],
            "LambertIntervalWidth": str(w_hi-w_lo),
            "LogarithmTerms": self.logarithm_terms, "Bisections": self.iterations,
            "Verified": self.verify(),
            "Scope": "Exact rational interval certificate; source-width goal, not a W-width goal",
        }


def certify(y: F | int | str, bits: int = 80, max_log_terms: int = 2048) -> Certificate:
    y = _fraction(y)
    if not 0 < y <= F(1, 4):
        raise ValueError("Admitted target range is 0 < y <= 1/4")
    if not isinstance(bits, int) or isinstance(bits, bool) or not 1 <= bits <= 4096:
        raise ValueError("bits must be an integer in [1,4096]")
    if not isinstance(max_log_terms, int) or max_log_terms < 8:
        raise ValueError("max_log_terms must be an integer >= 8")
    lo, hi = y*y, F(1, 4)
    n = min(24, max_log_terms)
    sl, nl, _ = _signed_residual(lo, y, n, max_log_terms)
    sh, nh, _ = _signed_residual(hi, y, n, max_log_terms)
    if sl != -1 or sh != 1:
        raise ArithmeticError("Initial bracketing invariant failed")
    n = max(nl, nh)
    iterations = 0
    while hi-lo > F(1, 2**bits):
        mid = (lo+hi)/2
        sign, used, _ = _signed_residual(mid, y, n, max_log_terms)
        n = max(n, used)
        if sign < 0:
            lo = mid
        else:
            hi = mid
        iterations += 1
        if iterations > bits+2:
            raise ArithmeticError("Bisection invariant failed")
    result = Certificate(y, lo, hi, bits, n, iterations)
    if not result.verify():
        raise ArithmeticError("Independent certificate verification failed")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", help="Exact target, for example 1/100")
    parser.add_argument("--bits", type=int, default=80)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    data = json.dumps(certify(args.target, args.bits).as_dict(), indent=2)+"\n"
    if args.output:
        args.output.write_text(data, encoding="utf-8")
    else:
        print(data, end="")


if __name__ == "__main__":
    main()
