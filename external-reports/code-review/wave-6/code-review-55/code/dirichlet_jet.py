"""Exact integer-indexed Dirichlet jets and elementary coefficient majorants.

A jet records EVERY coefficient for 1 <= n <= known_through; omitted dictionary
keys in that prefix mean zero. Beyond the prefix the coefficients are unknown,
not zero, and satisfy |a_n| <= growth_constant * n**growth_power.

The public constructor DECLARES the infinite coefficient bound. It checks the
known prefix, but cannot verify an arbitrary infinite sequence. The zeta() and
finite() factories establish their bounds by construction; the arithmetic
methods transport those bounds by the proofs in the accompanying article.

No dependency beyond Python 3.9's standard library. No native-kernel calls.
This is an independent prototype, not a replacement for GeneralizedSeries.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from types import MappingProxyType
from typing import Dict, Mapping, Union

Rational = Union[int, Fraction]


def _integer(value: object, name: str, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise ValueError(f"{name} must be an integer >= {minimum}")
    return value


def _fraction(value: Rational, name: str = "coefficient") -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError(f"{name} must be int or Fraction, not an approximate number")
    return Fraction(value)


@dataclass(frozen=True)
class DirichletJet:
    known_through: int
    coefficients: Mapping[int, Rational]
    growth_constant: Rational
    growth_power: int
    provenance: str = "Caller-declared coefficient bound"

    def __post_init__(self) -> None:
        nmax = _integer(self.known_through, "known_through", 1)
        power = _integer(self.growth_power, "growth_power")
        constant = _fraction(self.growth_constant, "growth_constant")
        if constant < 0:
            raise ValueError("growth_constant must be nonnegative")
        normalized: Dict[int, Fraction] = {}
        for n, raw in self.coefficients.items():
            _integer(n, "coefficient index", 1)
            if n > nmax:
                raise ValueError("a stored coefficient lies outside the known prefix")
            coefficient = _fraction(raw)
            if abs(coefficient) > constant * n**power:
                raise ValueError("the declared growth bound fails on a known coefficient")
            if coefficient:
                normalized[n] = coefficient
        if not isinstance(self.provenance, str):
            raise TypeError("provenance must be a string")
        object.__setattr__(self, "coefficients", MappingProxyType(dict(sorted(normalized.items()))))
        object.__setattr__(self, "growth_constant", constant)

    @classmethod
    def zeta(cls, known_through: int) -> "DirichletJet":
        _integer(known_through, "known_through", 1)
        return cls(known_through, {n: 1 for n in range(1, known_through + 1)},
                   1, 0, "Zeta defining coefficients a_n=1 for every positive integer n")

    @classmethod
    def finite(cls, coefficients: Mapping[int, Rational], known_through: int) -> "DirichletJet":
        """Represent exactly a finite Dirichlet polynomial, with a valid global bound.

        The generic tail estimate remains conservative if the caller does not
        otherwise exploit this factory's exact finite-support provenance.
        """
        values = [_fraction(c) for c in coefficients.values()]
        constant = max((abs(c) for c in values), default=Fraction(0))
        return cls(known_through, coefficients, constant, 0,
                   "Finite Dirichlet polynomial; coefficients beyond supplied support are zero")

    def coefficient(self, n: int) -> Fraction:
        _integer(n, "coefficient index", 1)
        if n > self.known_through:
            raise IndexError("unknown coefficient: absence beyond the prefix is not zero")
        return self.coefficients.get(n, Fraction(0))

    def restrict(self, known_through: int) -> "DirichletJet":
        _integer(known_through, "known_through", 1)
        if known_through > self.known_through:
            raise ValueError("restriction cannot invent additional coefficients")
        return DirichletJet(known_through,
                            {n: c for n, c in self.coefficients.items() if n <= known_through},
                            self.growth_constant, self.growth_power,
                            "Prefix restriction of an existing coefficient-bound declaration")

    def scale(self, factor: Rational) -> "DirichletJet":
        factor = _fraction(factor, "factor")
        return DirichletJet(self.known_through,
                            {n: factor * c for n, c in self.coefficients.items()},
                            abs(factor) * self.growth_constant, self.growth_power,
                            "Scalar multiplication of a bounded coefficient sequence")

    def add(self, other: "DirichletJet") -> "DirichletJet":
        if not isinstance(other, DirichletJet):
            raise TypeError("other must be a DirichletJet")
        nmax = min(self.known_through, other.known_through)
        keys = set(self.coefficients) | set(other.coefficients)
        data = {n: self.coefficient(n) + other.coefficient(n) for n in keys if n <= nmax}
        return DirichletJet(nmax, data, self.growth_constant + other.growth_constant,
                            max(self.growth_power, other.growth_power),
                            "Sum bound: C=C_a+C_b, p=max(p_a,p_b)")

    def multiply(self, other: "DirichletJet", *, max_pairs: int = 2_000_000) -> "DirichletJet":
        if not isinstance(other, DirichletJet):
            raise TypeError("other must be a DirichletJet")
        _integer(max_pairs, "max_pairs", 1)
        nmax = min(self.known_through, other.known_through)
        result: Dict[int, Fraction] = {}
        pairs = 0
        for d, ad in self.coefficients.items():
            if d > nmax:
                break
            for m, bm in other.coefficients.items():
                if m > nmax // d:
                    break
                pairs += 1
                if pairs > max_pairs:
                    raise RuntimeError("retained Dirichlet convolution pair budget exhausted")
                n = d * m
                result[n] = result.get(n, Fraction(0)) + ad * bm
        # There are at most n divisors of n. This intentionally elementary
        # bound trades sharpness for exact, inexpensive portable arithmetic.
        return DirichletJet(nmax, result, self.growth_constant * other.growth_constant,
                            max(self.growth_power, other.growth_power) + 1,
                            "Dirichlet convolution bound using tau(n)<=n")

    def reciprocal(self, *, max_growth_steps: int = 128,
                   max_pairs: int = 2_000_000) -> "DirichletJet":
        """Compute the reciprocal prefix, with a proved coefficient majorant.

        Choose integer q>p+1 with
          (C/|a_1|) 2**(p-q) (1+2/(q-p-1)) < 1.
        Strong induction then bounds |b_n| by n**q/|a_1|.
        The article specifies the common half-line where the analytic series
        and its reciprocal are both represented by these absolute series.
        """
        _integer(max_growth_steps, "max_growth_steps", 1)
        _integer(max_pairs, "max_pairs", 1)
        a1 = self.coefficient(1)
        if not a1:
            raise ZeroDivisionError("reciprocal requires a nonzero n=1 coefficient")
        p = self.growth_power
        for step in range(max_growth_steps):
            q = p + 2 + step
            kappa = (self.growth_constant / abs(a1) * Fraction(2) ** (p - q)
                     * (1 + Fraction(2, q - p - 1)))
            if kappa < 1:
                break
        else:
            raise RuntimeError("reciprocal growth-majorant search budget exhausted")
        nmax = self.known_through
        accum: Dict[int, Fraction] = {}
        result: Dict[int, Fraction] = {}
        nonunit = [(d, ad) for d, ad in self.coefficients.items() if d >= 2]
        pairs = 0
        # At the start of iteration m, all proper-divisor contributions to
        # coefficient m have already been accumulated from smaller indices.
        for m in range(1, nmax + 1):
            bm = 1 / a1 if m == 1 else -accum.pop(m, Fraction(0)) / a1
            if not bm:
                continue
            result[m] = bm
            for d, ad in nonunit:
                if d > nmax // m:
                    break
                pairs += 1
                if pairs > max_pairs:
                    raise RuntimeError("reciprocal coefficient pair budget exhausted")
                n = d * m
                accum[n] = accum.get(n, Fraction(0)) + ad * bm
        return DirichletJet(nmax, result, 1 / abs(a1), q,
                            f"Reciprocal induction with q={q}, exact kappa={kappa}<1")

    def evaluate_prefix(self, s: int) -> Fraction:
        """Evaluate the finite expression at a nonnegative integer phase s."""
        _integer(s, "s")
        return sum((c / n**s for n, c in self.coefficients.items()), Fraction(0))

    def tail_bound(self, s: int) -> Fraction:
        """Exact rational absolute tail bound for integer s>growth_power+1.

        This certifies the tail ONLY conditional on the object's declared
        global coefficient bound; it is not an inverse-root certificate.
        """
        _integer(s, "s")
        if s <= self.growth_power + 1:
            raise ValueError("tail bound requires s > growth_power + 1")
        m = self.known_through + 1
        return (self.growth_constant * Fraction(m) ** (self.growth_power - s)
                * (1 + Fraction(m, s - self.growth_power - 1)))


def dense_retained_pair_count(nmax: int) -> int:
    _integer(nmax, "nmax", 1)
    return sum(nmax // n for n in range(1, nmax + 1))
