"""Exact rational enclosures for the real W_{-1} branch.

No Mathics, SymPy, floating-point logarithms, or rounding-mode assumptions.
The input t is exact rational and the result encloses W_{-1}(-t).
This is an independent reference implementation, not a package monkey patch.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from functools import lru_cache

Q = Fraction


def _log_unit_interval(r: Q, terms: int) -> tuple[Q, Q]:
    """Enclose log(r), assuming 1 <= r <= 2, by the atanh series."""
    if not Q(1) <= r <= Q(2) or terms < 1:
        raise ValueError("Internal logarithm range/order violation")
    s = (r - 1) / (r + 1)
    square = s * s
    power = s
    total = Q(0)
    for j in range(terms):
        total += power / (2 * j + 1)
        power *= square
    lower = 2 * total
    tail = 2 * power / ((2 * terms + 1) * (1 - square))
    return lower, lower + tail


@lru_cache(maxsize=32)
def _log_two(terms: int) -> tuple[Q, Q]:
    return _log_unit_interval(Q(2), terms)


def log_interval(value: Q, terms: int) -> tuple[Q, Q]:
    if not isinstance(value, Q) or value <= 0:
        raise ValueError("value must be a positive fractions.Fraction")
    if not isinstance(terms, int) or isinstance(terms, bool) or terms < 1:
        raise ValueError("terms must be a positive integer")
    k = value.numerator.bit_length() - value.denominator.bit_length()
    scale = Q(2**k) if k >= 0 else Q(1, 2**(-k))
    r = value / scale
    if r < 1:
        k -= 1
        r *= 2
    elif r >= 2:
        k += 1
        r /= 2
    lo, hi = _log_unit_interval(r, terms)
    l2, u2 = _log_two(terms)
    return (lo + k * l2, hi + k * u2) if k >= 0 else (lo + k * u2, hi + k * l2)


def _h_interval(v: Q, t: Q, terms: int) -> tuple[Q, Q]:
    # h(v) = v - log(v/t), h'(v) = 1 - 1/v > 0 for v > 1.
    lo, hi = log_interval(v / t, terms)
    return v - hi, v - lo


def _h_sign(v: Q, t: Q, initial_terms: int, max_terms: int) -> tuple[int, int]:
    terms = initial_terms
    while terms <= max_terms:
        lo, hi = _h_interval(v, t, terms)
        if hi < 0:
            return -1, terms
        if lo > 0:
            return 1, terms
        terms *= 2
    raise ArithmeticError("The exact logarithm budget did not determine the sign")


@dataclass(frozen=True)
class LambertMinusOneCertificate:
    t: Q
    v_lower: Q
    v_upper: Q
    log_terms: int
    requested_bits: int

    @property
    def w_interval(self) -> tuple[Q, Q]:
        return -self.v_upper, -self.v_lower

    @property
    def small_entropy_inverse_interval(self) -> tuple[Q, Q]:
        """Enclose the small x solving -x log(x) = t."""
        return self.t / self.v_upper, self.t / self.v_lower

    def verify(self) -> bool:
        if not (0 < self.t and 1 <= self.v_lower < self.v_upper):
            return False
        left = _h_interval(self.v_lower, self.t, self.log_terms)
        right = _h_interval(self.v_upper, self.t, self.log_terms)
        return (left[1] < 0 < right[0] and
                self.v_upper - self.v_lower <= Q(1, 2**self.requested_bits))


def enclose_lambert_minus_one(t: Q, bits: int = 64, *, max_log_terms: int = 4096,
                              max_bracket_doublings: int = 128) -> LambertMinusOneCertificate:
    if not isinstance(t, Q) or t <= 0:
        raise ValueError("t must be an exact positive fractions.Fraction")
    if not isinstance(bits, int) or isinstance(bits, bool) or not 1 <= bits <= 1024:
        raise ValueError("bits must be an integer in [1, 1024]")
    if not isinstance(max_log_terms, int) or max_log_terms < 8:
        raise ValueError("max_log_terms must be an integer >= 8")
    if not isinstance(max_bracket_doublings, int) or max_bracket_doublings < 1:
        raise ValueError("max_bracket_doublings must be a positive integer")
    initial = min(max_log_terms, max(8, bits // 3 + 4))
    sign, used = _h_sign(Q(1), t, initial, max_log_terms)
    if sign != -1:
        raise ValueError("The real branch requires 0 < t < 1/e")
    lo, hi = Q(1), Q(2)
    for _ in range(max_bracket_doublings):
        sign, n = _h_sign(hi, t, initial, max_log_terms)
        used = max(used, n)
        if sign == 1:
            break
        hi *= 2
    else:
        raise ArithmeticError("The bracketing budget was exhausted")
    tolerance = Q(1, 2**bits)
    while hi - lo > tolerance:
        middle = (lo + hi) / 2
        sign, n = _h_sign(middle, t, initial, max_log_terms)
        used = max(used, n)
        if sign < 0:
            lo = middle
        else:
            hi = middle
    certificate = LambertMinusOneCertificate(t, lo, hi, used, bits)
    if not certificate.verify():
        raise ArithmeticError("Internal certificate verification failed")
    return certificate
