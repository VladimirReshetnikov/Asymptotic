"""Exact Gauss/Radau bounds for Phi(q, 1, a); no third-party dependencies.

This is an independent review prototype, not integrated AsymptoticAnalysis code.
Only int/Fraction inputs are accepted. The order limit is an explicit prototype
resource policy. Arithmetic-operation counts do not include rational bit cost.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
import argparse
import json

MAX_ORDER = 64


def exact_rational(value: object, name: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be int or Fraction, not an approximate value")
    return Fraction(value)


@dataclass(frozen=True)
class GaussValue:
    value: Fraction
    denominator: Fraction
    norm: Fraction


@dataclass(frozen=True)
class LerchBounds:
    q: Fraction
    a: Fraction
    order: int
    lower: Fraction
    upper: Fraction
    lower_error_cap: Fraction
    upper_error_cap: Fraction
    exact: bool = False

    @property
    def width(self) -> Fraction:
        return self.upper - self.lower

    def to_dict(self) -> dict[str, object]:
        return {"q": str(self.q), "a": str(self.a), "order": self.order,
                "lower": str(self.lower), "upper": str(self.upper),
                "width": str(self.width),
                "lower_error_cap": str(self.lower_error_cap),
                "upper_error_cap": str(self.upper_error_cap),
                "exact": self.exact,
                "method": "Meixner-Gauss/Radau; s=1; exact rational arithmetic"}


def _gauss(q: Fraction, a: Fraction, n: int, beta: int,
           shift: int, mass: Fraction) -> GaussValue:
    """Jacobi convergent for a shifted negative-binomial measure.

    Invariants: D_j = (-1)^j p_j(-a), N_j / D_j is the j-node
    Gaussian resolvent, and norm = integral p_j^2 dmu after the loop.
    The positive finite Meixner sum in the article proves D_j > 0.
    """
    one_minus = 1 - q
    d_prev, d = Fraction(1), a + shift + beta*q/one_minus
    num_prev, num = Fraction(0), mass
    # h_1 / h_0 = lambda_1.
    norm = mass * q * beta / one_minus**2
    for j in range(1, n):
        diagonal = shift + ((1 + q)*j + beta*q) / one_minus
        subdiagonal = q*j*(j + beta - 1) / one_minus**2
        d_prev, d = d, (a + diagonal)*d - subdiagonal*d_prev
        num_prev, num = num, (a + diagonal)*num - subdiagonal*num_prev
        next_lambda = q*(j + 1)*(j + beta) / one_minus**2
        norm *= next_lambda
    if d <= 0:
        raise ArithmeticError("positive-denominator invariant violated")
    return GaussValue(num/d, d, norm)


def lerch_bounds(q: int | Fraction, a: int | Fraction, order: int) -> LerchBounds:
    """Return lower <= sum(q**k/(a+k), k>=0) <= upper.

    Domain: 0 <= q < 1, a > 0, 1 <= order <= MAX_ORDER, exact inputs.
    q=0 is handled exactly rather than by a degenerate orthogonal measure.
    Error caps separately bound F-lower and upper-F; they are NOT the
    error of a truncated asymptotic polynomial from AsymptoticAnalysis.
    """
    q, a = exact_rational(q, "q"), exact_rational(a, "a")
    if not 0 <= q < 1:
        raise ValueError("q must satisfy 0 <= q < 1")
    if a <= 0:
        raise ValueError("a must be positive")
    if isinstance(order, bool) or not isinstance(order, int):
        raise TypeError("order must be an integer")
    if not 1 <= order <= MAX_ORDER:
        raise ValueError(f"order must be between 1 and {MAX_ORDER}")
    if q == 0:
        return LerchBounds(q, a, order, 1/a, 1/a, Fraction(0), Fraction(0), True)
    mass0 = 1/(1-q)
    lower = _gauss(q, a, order, 1, 0, mass0)
    weighted = _gauss(q, a, order, 2, 1, q/(1-q)**2)
    upper = mass0/a - weighted.value/a
    lower_cap = lower.norm/(a*lower.denominator**2)
    upper_cap = weighted.norm/(a*(a+1)*weighted.denominator**2)
    if not Fraction(0) < lower.value < upper:
        raise ArithmeticError("strict-enclosure invariant violated")
    return LerchBounds(q, a, order, lower.value, upper, lower_cap, upper_cap)


def defining_sum_interval(q: int | Fraction, a: int | Fraction,
                          terms: int) -> tuple[Fraction, Fraction]:
    """Independent convergent-series enclosure, used only as a test oracle."""
    q, a = exact_rational(q, "q"), exact_rational(a, "a")
    if not 0 <= q < 1 or a <= 0:
        raise ValueError("outside the positive-measure domain")
    if isinstance(terms, bool) or not isinstance(terms, int) or terms < 1:
        raise ValueError("terms must be a positive integer")
    power, partial = Fraction(1), Fraction(0)
    for k in range(terms):
        partial += power/(a+k)
        power *= q
    return partial, partial + power/((a+terms)*(1-q))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("q", type=Fraction)
    parser.add_argument("a", type=Fraction)
    parser.add_argument("order", type=int)
    args = parser.parse_args()
    try:
        result = lerch_bounds(args.q, args.a, args.order)
    except (ValueError, TypeError, ArithmeticError) as exc:
        parser.error(str(exc))
    print(json.dumps(result.to_dict(), indent=2))


if __name__ == "__main__":
    main()
