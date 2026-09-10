"""Uniform Lerch transition model; an additive research prototype.

For a > 0, lam > 0, s >= 0, expand Phi(exp(-lam/a), s, a).
Exact rational coefficient generation is separated from mpmath evaluation.
The analytic bound concerns exact expressions. Floating-point endpoints are
NOT outward-rounded interval certificates. No upstream code is imported.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from functools import lru_cache
from math import comb, factorial
from typing import Union

RationalInput = Union[int, Fraction]
MAX_ORDER = 64


def _rational(value: RationalInput, name: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be an int or Fraction, not a float")
    return Fraction(value)


@lru_cache(maxsize=256)
def bernoulli(n: int) -> Fraction:
    """Exact Bernoulli number with B_1=-1/2; bounded cache and degree."""
    if isinstance(n, bool) or not isinstance(n, int) or not 0 <= n <= 2 * MAX_ORDER + 2:
        raise ValueError("Bernoulli index is outside the supported exact range")
    values = [Fraction(1)]
    for m in range(1, n + 1):
        values.append(-sum(Fraction(comb(m + 1, k)) * values[k]
                           for k in range(m)) / (m + 1))
    return values[n]


def moment_polynomial(m: int, lam: RationalInput, s: RationalInput) -> Fraction:
    """P_m(lam,s)=sum binom(m,j) lam^(m-j) (s)_j; nonnegative summands."""
    lam, s = _rational(lam, "lam"), _rational(s, "s")
    if isinstance(m, bool) or not isinstance(m, int) or not 0 <= m <= 2 * MAX_ORDER + 1:
        raise ValueError("moment degree is outside the supported range")
    if lam <= 0 or s < 0:
        raise ValueError("require lam > 0 and s >= 0")
    rising, result = Fraction(1), Fraction(0)
    for j in range(m + 1):
        if j:
            rising *= s + j - 1
        result += comb(m, j) * lam ** (m - j) * rising
    return result


@dataclass(frozen=True)
class UniformLerchModel:
    lam: Fraction
    s: Fraction
    order: int
    # A row (p,c) represents c*a**(-p). The leading integral is separate.
    correction_rows: tuple[tuple[Fraction, Fraction], ...]
    remainder_power: Fraction
    remainder_coefficient: Fraction  # strictly positive
    remainder_sign: int

    def numerical(self, a: RationalInput, *, dps: int = 80) -> dict[str, object]:
        """Evaluate the model and analytic bound; this is not interval arithmetic."""
        import mpmath as mp
        a = _rational(a, "a")
        if a <= 0:
            raise ValueError("require a > 0")
        if isinstance(dps, bool) or not isinstance(dps, int) or not 30 <= dps <= 10000:
            raise ValueError("dps must be an integer from 30 to 10000")
        def conv(q: Fraction):
            return mp.mpf(q.numerator) / q.denominator
        with mp.workdps(dps):
            aa, ll, ss = conv(a), conv(self.lam), conv(self.s)
            integral = (1 / ll if self.s == 0 else
                        mp.exp(ll) * ll**(ss - 1) * mp.gammainc(1 - ss, ll, mp.inf))
            value = aa**(1 - ss) * integral
            value += mp.fsum(conv(c) * aa**(-conv(p)) for p, c in self.correction_rows)
            bound = conv(self.remainder_coefficient) * aa**(-conv(self.remainder_power))
            return {"approximation": +value, "analytic_bound_value": +bound,
                    "signed_first_omitted_term": +(self.remainder_sign * bound),
                    "leading_integral": +integral, "dps": dps,
                    "outward_rounded": False, "interval_certificate": False}

    def exact_description(self) -> dict[str, object]:
        return {"lambda": str(self.lam), "s": str(self.s), "order": self.order,
                "leading_term": "a**(1-s) * exp(lambda) * lambda**(s-1) * Gamma(1-s,lambda)",
                "correction_rows": [[str(p), str(c)] for p, c in self.correction_rows],
                "remainder_power": str(self.remainder_power),
                "absolute_bound_coefficient": str(self.remainder_coefficient),
                "remainder_sign": self.remainder_sign,
                "conditions": "a>0; fixed lambda>0 and fixed s>=0; exact parameters",
                "statement": "0 <= remainder_sign*(Phi-S_K) <= C*a**(-remainder_power)"}


def make_model(lam: RationalInput, s: RationalInput, order: int) -> UniformLerchModel:
    lam, s = _rational(lam, "lam"), _rational(s, "s")
    if lam <= 0 or s < 0:
        raise ValueError("require lam > 0 and s >= 0")
    if isinstance(order, bool) or not isinstance(order, int) or not 0 <= order <= MAX_ORDER:
        raise ValueError(f"order must be an integer from 0 to {MAX_ORDER}")
    rows = [(s, Fraction(1, 2))]
    for k in range(1, order + 1):
        c = bernoulli(2 * k) * moment_polynomial(2 * k - 1, lam, s) / factorial(2 * k)
        rows.append((s + 2 * k - 1, c))
    p = s + 2 * order + 1
    c = abs(bernoulli(2 * order + 2)) * moment_polynomial(2 * order + 1, lam, s)
    c /= factorial(2 * order + 2)
    return UniformLerchModel(lam, s, order, tuple(rows), p, c, (-1) ** order)


if __name__ == "__main__":
    import argparse, json
    import mpmath as mp
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lambda", dest="lam", default="1", help="exact integer or fraction")
    parser.add_argument("--s", default="2", help="exact nonnegative integer or fraction")
    parser.add_argument("--order", type=int, default=2)
    parser.add_argument("--a", default="10", help="exact positive integer or fraction")
    parser.add_argument("--dps", type=int, default=80)
    args = parser.parse_args()
    try:
        model = make_model(Fraction(args.lam), Fraction(args.s), args.order)
        report = model.exact_description()
        report["numerical_evaluation"] = {k: mp.nstr(v, args.dps) if k not in
           {"dps", "outward_rounded", "interval_certificate"} else v
           for k, v in model.numerical(Fraction(args.a), dps=args.dps).items()}
        print(json.dumps(report, indent=2))
    except (ValueError, TypeError, ZeroDivisionError) as exc:
        parser.error(str(exc))
