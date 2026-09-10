"""Independent reference algorithms for the Asymptotic incremental review.

These are mathematical oracles, NOT a port or execution of AsymptoticAnalysis.
Only the polynomial interchange helpers depend on SymPy. No routine constructs
an array indexed by the largest polynomial exponent.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from math import isfinite
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Iterable, Mapping, Literal

Relation = Literal["<", "<=", ">", ">=", "==", "!="]


def _fraction(value: int | Fraction) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Fraction)):
        raise TypeError("Use exact integers or fractions, not floats")
    return Fraction(value)


@dataclass(frozen=True)
class SparsePolynomial:
    """An exact rational polynomial, stored as sorted nonzero (degree, value) pairs."""
    terms: tuple[tuple[int, Fraction], ...]

    @classmethod
    def from_mapping(cls, data: Mapping[int, int | Fraction]) -> "SparsePolynomial":
        pairs = []
        for degree, value in data.items():
            if isinstance(degree, bool) or not isinstance(degree, int) or degree < 0:
                raise ValueError("Polynomial degrees must be nonnegative integers")
            coefficient = _fraction(value)
            if coefficient:
                pairs.append((degree, coefficient))
        return cls(tuple(sorted(pairs)))

    @classmethod
    def from_pairs(cls, pairs: Iterable[tuple[int, int | Fraction]]) -> "SparsePolynomial":
        data: dict[int, Fraction] = {}
        for degree, coefficient in pairs:
            if isinstance(degree, bool) or not isinstance(degree, int) or degree < 0:
                raise ValueError("Polynomial degrees must be nonnegative integers")
            data[degree] = data.get(degree, Fraction(0)) + _fraction(coefficient)
        return cls.from_mapping(data)

    def __post_init__(self) -> None:
        previous = -1
        for degree, coefficient in self.terms:
            if type(degree) is not int or degree <= previous or degree < 0:
                raise ValueError("Terms must have distinct, increasing nonnegative degrees")
            if not isinstance(coefficient, Fraction) or not coefficient:
                raise ValueError("Terms must have nonzero Fraction coefficients")
            previous = degree

    def coefficient_rules(self) -> tuple[tuple[tuple[int], Fraction], ...]:
        return tuple(((degree,), coefficient) for degree, coefficient in reversed(self.terms))

    def derivative(self) -> "SparsePolynomial":
        return SparsePolynomial.from_pairs((degree - 1, degree * coefficient)
                                           for degree, coefficient in self.terms if degree)

    def multiply(self, other: "SparsePolynomial", *, max_pairs: int = 100_000) -> "SparsePolynomial":
        if type(max_pairs) is not int or max_pairs < 0:
            raise ValueError("max_pairs must be a nonnegative integer")
        if len(self.terms) * len(other.terms) > max_pairs:
            raise ValueError("Candidate product budget exceeded")
        return SparsePolynomial.from_pairs((i + j, a * b)
                                           for i, a in self.terms for j, b in other.terms)

    def evaluate(self, x: int | Fraction) -> Fraction:
        x = _fraction(x)
        return sum((coefficient * x**degree for degree, coefficient in self.terms), Fraction(0))

    @property
    def valuation(self) -> int | None:
        return self.terms[0][0] if self.terms else None

    @property
    def degree(self) -> int | None:
        return self.terms[-1][0] if self.terms else None


def sparse_rules_from_sympy(expression, variable):
    """Sparse extraction after expansion; does not construct a SymPy Poly/DMP.

    Expansion itself is not budgeted here. The report explicitly separates
    sparse extraction from the different problem of expression-swell control.
    Symbolic coefficients are allowed if independent of variable.
    """
    import sympy as sp
    if not isinstance(variable, sp.Symbol):
        raise TypeError("variable must be a SymPy Symbol")
    expanded = sp.expand(expression)
    if expanded == 0:
        return ()
    data = {}
    for term in sp.Add.make_args(expanded):
        coefficient, exponent = term.as_coeff_exponent(variable)
        if exponent.is_Integer is not True or exponent < 0 or coefficient.has(variable):
            raise ValueError("Not a polynomial in the selected variable")
        degree = int(exponent)
        data[degree] = data.get(degree, sp.S.Zero) + coefficient
    return tuple(((degree,), sp.expand(coefficient))
                 for degree, coefficient in sorted(data.items(), reverse=True)
                 if sp.expand(coefficient) != 0)


def _sign(value: Fraction) -> int:
    return (value > 0) - (value < 0)


def truth_from_sign(sign: int, relation: Relation) -> bool:
    comparisons = {"<": sign < 0, "<=": sign <= 0, ">": sign > 0,
                   ">=": sign >= 0, "==": sign == 0, "!=": sign != 0}
    if relation not in comparisons:
        raise ValueError("Unknown relation")
    return comparisons[relation]


@dataclass(frozen=True)
class EventualCertificate:
    """A sign theorem on 0 < u < radius, not a theorem on an arbitrary interval."""
    sign: int
    radius: Fraction
    valuation: int | None
    leading: Fraction
    tail_l1: Fraction

    def truth(self, relation: Relation) -> bool:
        return truth_from_sign(self.sign, relation)

    def verify_majorant(self) -> bool:
        if not 0 < self.radius <= 1:
            return False
        if self.valuation is None:
            return self.sign == 0 and self.leading == self.tail_l1 == 0
        return self.sign == _sign(self.leading) and self.sign != 0 and (
            self.tail_l1 == 0 or self.radius * self.tail_l1 < abs(self.leading) / 2)


def polynomial_eventual_certificate(polynomial: SparsePolynomial) -> EventualCertificate:
    """Construct the radius proved in the article, using exact rational arithmetic."""
    if not polynomial.terms:
        return EventualCertificate(0, Fraction(1), None, Fraction(0), Fraction(0))
    valuation, leading = polynomial.terms[0]
    tail = sum((abs(c) for _, c in polynomial.terms[1:]), Fraction(0))
    radius = min(Fraction(1), abs(leading) / (2 * (1 + tail)))
    return EventualCertificate(_sign(leading), radius, valuation, leading, tail)


def affine_interval_truth(a: int | Fraction, b: int | Fraction,
                          radius: int | Fraction, relation: Relation) -> bool | None:
    """Faithful rational model of the current endpoint-sign decision.

    True means true throughout (0,r); False means false throughout (0,r).
    A predicate changing truth inside the interval is None, not False.
    """
    a, b, radius = _fraction(a), _fraction(b), _fraction(radius)
    if radius <= 0:
        raise ValueError("radius must be positive")
    endpoints = (a, a + b * radius)
    nonnegative = all(v >= 0 for v in endpoints)
    nonpositive = all(v <= 0 for v in endpoints)
    positive = nonnegative and any(v > 0 for v in endpoints)
    negative = nonpositive and any(v < 0 for v in endpoints)
    zero = all(v == 0 for v in endpoints)
    decisions = {
        ">": (positive, nonpositive), ">=": (nonnegative, negative),
        "<": (negative, nonnegative), "<=": (nonpositive, positive),
        "==": (zero, positive or negative), "!=": (positive or negative, zero),
    }
    if relation not in decisions:
        raise ValueError("Unknown relation")
    true_condition, false_condition = decisions[relation]
    return True if true_condition else False if false_condition else None


def seven_radius_witness(a: int | Fraction, b: int | Fraction,
                         relation: Relation) -> Fraction | None:
    """Only models the seven explicit trials, NOT the Mathics fallback evaluator."""
    for j in range(7):
        radius = Fraction(1, 2**j)
        if affine_interval_truth(a, b, radius, relation) is True:
            return radius
    return None


def terminating_hypergeometric(upper: Iterable[int | Fraction],
                               lower: Iterable[int | Fraction], *,
                               argument_coefficient: int | Fraction = 1,
                               argument_degree: int = 1,
                               max_terms: int = 10_000) -> SparsePolynomial:
    """Exact terminating pFq polynomial, retaining the conservative lower > 0 policy."""
    upper = tuple(_fraction(v) for v in upper)
    lower = tuple(_fraction(v) for v in lower)
    scale = _fraction(argument_coefficient)
    if type(argument_degree) is not int or argument_degree < 1:
        raise ValueError("argument_degree must be a positive integer")
    if type(max_terms) is not int or max_terms < 1:
        raise ValueError("max_terms must be a positive integer")
    if any(v <= 0 for v in lower):
        raise ValueError("This reference deliberately requires positive lower parameters")
    stops = [-int(v) for v in upper if v.denominator == 1 and v <= 0]
    if not stops:
        raise ValueError("No exact nonpositive-integer upper parameter")
    stop = min(stops)
    if stop + 1 > max_terms:
        raise ValueError("Finite coefficient budget exceeded")
    coefficient = Fraction(1)
    pairs = [(0, coefficient)]
    for n in range(stop):
        coefficient *= scale / (n + 1)
        for value in upper:
            coefficient *= value + n
        for value in lower:
            coefficient /= value + n
        pairs.append(((n + 1) * argument_degree, coefficient))
    return SparsePolynomial.from_pairs(pairs)


def wolfram_productlog_to_sympy(branch: int | None, argument, *, evaluate: bool = True):
    """Correct WL ProductLog[k,z] -> SymPy LambertW(z,k) argument order."""
    import sympy as sp
    if branch is not None and type(branch) is not int:
        raise TypeError("An explicit branch must be an integer")
    return sp.LambertW(argument, 0 if branch is None else branch, evaluate=evaluate)


def unevaluated_productlog_roundtrip(branch: int, argument):
    """Round-trip syntax only; evaluated constants need not retain branch syntax."""
    expression = wolfram_productlog_to_sympy(branch, argument, evaluate=False)
    if len(expression.args) == 1:
        return (0, expression.args[0])
    return (int(expression.args[1]), expression.args[0])


def demonstrate_aba() -> dict[str, bool]:
    """A deterministic countermodel to 'before==after implies unchanged throughout'."""
    import hashlib
    with TemporaryDirectory(prefix="review-aba-") as temporary:
        path = Path(temporary) / "module.wl"
        a, b = b"answer = 1;\n", b"answer = 2;\n"
        path.write_bytes(a)
        before = hashlib.sha256(path.read_bytes()).digest()
        path.write_bytes(b)
        actually_read = path.read_bytes()
        path.write_bytes(a)
        after = hashlib.sha256(path.read_bytes()).digest()
        return {"BeforeAfterEqual": before == after,
                "ReadBytesDifferedFromInitialBytes": actually_read != a}


def validate_timeout(value: float) -> float:
    if not isfinite(value) or value <= 0:
        raise ValueError("The timeout must be positive and finite")
    return value
