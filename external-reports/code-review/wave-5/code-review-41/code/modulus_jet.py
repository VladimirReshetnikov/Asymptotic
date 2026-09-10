"""Independent sparse power-log modulus model; NOT an upstream package port.

Python 3.9+, SymPy. Exact rational exponents and exact numeric complex
coefficients polynomial in L are supported. L denotes log(u), u -> 0+.
Magnitude errors are O(u**power * (1 + abs(log(u)))**log_degree).
Derivative contracts, parameter proof search and arbitrary complex sectors
are deliberately absent. Counts describe this model, not Wolfram performance.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from typing import Dict, Mapping, Optional
import sympy as sp

L = sp.Symbol("L", real=True)
Weight = Fraction
Rows = Dict[Weight, sp.Expr]


@dataclass(frozen=True)
class Error:
    power: Weight
    log_degree: int = 0
    def __post_init__(self) -> None:
        if not isinstance(self.power, Fraction):
            raise TypeError("error power must be Fraction")
        if not isinstance(self.log_degree, int) or self.log_degree < 0:
            raise ValueError("error logarithmic degree must be nonnegative")


@dataclass(frozen=True)
class Jet:
    rows: Mapping[Weight, sp.Expr]
    error: Optional[Error] = None  # None means an exact finite expression.


@dataclass
class Budget:
    max_products: int = 100_000
    max_steps: int = 1_000
    products: int = 0
    steps: int = 0
    def validate(self) -> None:
        if self.max_products < 1 or self.max_steps < 1:
            raise ValueError("positive operation budgets are required")
    def product(self) -> None:
        self.products += 1
        if self.products > self.max_products:
            raise RuntimeError("candidate-product budget exhausted")
    def step(self) -> None:
        self.steps += 1
        if self.steps > self.max_steps:
            raise RuntimeError("Taylor-step budget exhausted")


def canonical(rows: Mapping[Weight, sp.Expr]) -> Rows:
    out: Rows = {}
    for weight, coefficient in rows.items():
        if not isinstance(weight, Fraction):
            raise TypeError("weights must be Fraction objects")
        value = sp.expand(sp.sympify(coefficient))
        if value.has(sp.Float, sp.nan, sp.oo, -sp.oo, sp.zoo):
            raise ValueError("coefficients must be exact and finite")
        try:
            poly = sp.Poly(value, L)
        except sp.PolynomialError as exc:
            raise ValueError("coefficients must be polynomials in L") from exc
        if any(not c.is_number for c in poly.all_coeffs()):
            raise ValueError("this reference model does not implement parameter proofs")
        if value != 0:
            out[weight] = value
    return dict(sorted(out.items()))


def combine(a: Optional[Error], b: Optional[Error]) -> Optional[Error]:
    if a is None:
        return b
    if b is None:
        return a
    if a.power != b.power:
        return a if a.power < b.power else b
    return Error(a.power, max(a.log_degree, b.log_degree))


def add(a: Mapping[Weight, sp.Expr], b: Mapping[Weight, sp.Expr]) -> Rows:
    result = dict(a)
    for weight, value in b.items():
        result[weight] = result.get(weight, sp.S.Zero) + value
    return canonical(result)


def mul(a: Mapping[Weight, sp.Expr], b: Mapping[Weight, sp.Expr],
        cutoff: Optional[Weight], budget: Budget) -> Rows:
    result: Rows = {}
    for wa, ca in sorted(a.items()):
        for wb, cb in sorted(b.items()):
            w = wa + wb
            if cutoff is not None and w >= cutoff:
                break
            budget.product()
            result[w] = result.get(w, sp.S.Zero) + ca * cb
    return canonical(result)


def degree(coefficient: sp.Expr) -> int:
    return 0 if coefficient == 0 else int(sp.degree(coefficient, L))


def trim(jet: Jet, cutoff: Weight) -> Jet:
    rows = canonical(jet.rows)
    omitted = [(w, c) for w, c in rows.items() if w >= cutoff]
    error = jet.error
    if omitted:
        w, c = omitted[0]
        error = combine(error, Error(w, degree(c)))
    retained = {w: c for w, c in rows.items()
                if w < cutoff and (error is None or w < error.power)}
    return Jet(retained, error)


def as_expression(jet: Jet, u: sp.Symbol) -> sp.Expr:
    return sp.Add(*(u**sp.Rational(w.numerator, w.denominator) * c.subs(L, sp.log(u))
                    for w, c in jet.rows.items()))


def modulus(jet: Jet, cutoff: Weight, budget: Optional[Budget] = None) -> Jet:
    """Compute a conservative modulus jet on a positive real coordinate.

    Real finite approximations use the exact eventual sign shortcut.
    Complex approximations require a nonzero, log-independent leading
    coefficient; unsupported leading logarithmic amplitudes are refused.
    Existing magnitude error is transported by ||z|-|p|| <= |z-p|.
    """
    if not isinstance(cutoff, Fraction):
        raise TypeError("cutoff must be Fraction")
    budget = budget if budget is not None else Budget()
    budget.validate()
    rows = canonical(jet.rows)
    if jet.error is not None and any(w >= jet.error.power for w in rows):
        raise ValueError("retained weights must lie strictly below the error power")
    if not rows:
        return Jet({}, jet.error)
    alpha = next(iter(rows))
    leading = rows[alpha]
    # A real finite polynomial has an eventual sign. This is a magnitude
    # theorem even when the unknown error is complex.
    if all(sp.simplify(c - sp.conjugate(c)) == 0 for c in rows.values()):
        d = degree(leading)
        dominant = sp.simplify((-1)**d * sp.Poly(leading, L).LC())
        if dominant.is_positive:
            return trim(Jet(rows, jet.error), cutoff)
        if dominant.is_negative:
            return trim(Jet({w: -c for w, c in rows.items()}, jet.error), cutoff)
        raise ValueError("eventual sign is not decided")
    if leading.has(L) or leading == 0:
        raise ValueError("complex leading coefficient must be nonzero and log-independent")
    norm = sp.sqrt(sp.simplify(leading * sp.conjugate(leading)))
    if norm.is_positive is not True:
        raise ValueError("leading modulus is not proved positive")
    if cutoff <= alpha:
        return Jet({}, combine(jet.error, Error(alpha, 0)))
    # Never request finite coefficients beyond the original uncertainty.
    effective = min(cutoff, jet.error.power) if jet.error else cutoff
    rel = effective - alpha
    ujet = canonical({w - alpha: c / leading for w, c in rows.items() if w != alpha})
    ubar = canonical({w: sp.conjugate(c) for w, c in ujet.items()})
    # Full finite H is formed in this bounded reference implementation.
    # It is NOT a proposed claim of an optimal truncated convolution.
    h = add(add(ujet, ubar), mul(ujet, ubar, None, budget))
    if not h:
        return trim(Jet({alpha: norm}, jet.error), cutoff)
    v = min(h)
    if v <= 0:
        raise ValueError("normalized modulus increment is not small")
    d = max(degree(c) for c in h.values())
    ratio = rel / v
    kmax = (ratio.numerator + ratio.denominator - 1) // ratio.denominator
    answer: Rows = {Fraction(0): sp.S.One}
    power: Rows = {Fraction(0): sp.S.One}
    # Keep Taylor degrees k < K, so the analytic tail is O(H**K).
    for k in range(1, kmax):
        budget.step()
        power = mul(power, h, rel, budget)
        if not power:
            break
        answer = add(answer, {w: sp.binomial(sp.Rational(1, 2), k) * c
                              for w, c in power.items()})
    # A deliberately conservative boundary degree covers discarded finite
    # products as well as the analytic Taylor tail.
    tail = Error(effective, kmax * d)
    error = combine(jet.error, tail)
    out = canonical({alpha + w: norm * c for w, c in answer.items()})
    return Jet({w: c for w, c in out.items() if error is None or w < error.power}, error)


def hermitian_square(rows: Mapping[Weight, sp.Expr], budget: Optional[Budget] = None) -> Rows:
    """Prototype paired convolution for p*conjugate(p), with exact real L.

    This is provided separately from modulus(): it measures pair-count
    reduction, not Wolfram timing or an integrated optimization.
    """
    budget = budget if budget is not None else Budget()
    budget.validate()
    items = list(canonical(rows).items())
    out: Rows = {}
    for i, (wa, ca) in enumerate(items):
        for j in range(i, len(items)):
            wb, cb = items[j]
            budget.product()
            product = sp.expand(ca * sp.conjugate(cb))
            coefficient = product if i == j else 2*sp.re(product)
            w = wa+wb
            out[w] = out.get(w, sp.S.Zero)+coefficient
    return canonical(out)
