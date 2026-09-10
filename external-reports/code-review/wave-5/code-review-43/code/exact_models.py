"""Independent exact models for the accompanying review, not package execution.

Python >= 3.9; SymPy is used only for symbolic expressions in this module.
The monotonicity certificate checker is a separate standard-library module.
"""
from __future__ import annotations
from typing import Tuple
import sympy as sp


def inverse_contribution(y: sp.Symbol, *, leading_coefficient: sp.Expr,
                         leading_power: sp.Expr, observable_power: sp.Expr,
                         weight: sp.Expr = sp.Integer(0),
                         coefficient: sp.Expr = sp.Integer(1),
                         source_sign: int = 1, source_endpoint: sp.Expr = sp.Integer(0),
                         target_offset: sp.Expr = sp.Integer(0),
                         source_infinite: bool = False,
                         target_infinite: bool = False) -> Tuple[sp.Expr, sp.Expr, sp.Expr]:
    """Return (unsigned/local contribution, oriented contribution, additive offset).

    This reproduces the displayed algebra, not the package's dispatch or proof
    engine. coefficient has already had its formal logarithm substituted.
    """
    if source_sign not in (-1, 1):
        raise ValueError("source_sign must be -1 or 1")
    p, r, a, w = map(sp.sympify,
                    (leading_power, observable_power, leading_coefficient, weight))
    if p == 0 or a == 0:
        raise ValueError("A nonzero leading coefficient and power are required")
    if source_sign == -1 and r.is_integer is not True:
        raise ValueError("This model restricts negative-source observables to integer powers")
    internal_power = -r if source_infinite else r
    v = y if target_infinite else y - target_offset
    local = sp.sympify(coefficient) * (v / a) ** ((internal_power + w) / p)
    oriented = sp.Integer(source_sign) ** r * local
    offset = source_endpoint if not source_infinite and r == 1 else sp.Integer(0)
    return sp.simplify(local), sp.simplify(oriented), sp.sympify(offset)


def model_target_limit(offset: sp.Expr, a: sp.Expr, p: sp.Expr) -> sp.Expr:
    """Exact numeric-parameter model; never guesses an unresolved sign."""
    offset, a, p = map(sp.sympify, (offset, a, p))
    if p.is_positive is True:
        return offset
    if p.is_negative is True:
        if a.is_positive is True:
            return sp.oo
        if a.is_negative is True:
            return -sp.oo
    raise ValueError("Nonzero real leading power and coefficient signs must be known")


def perturbative_inverse(phi: sp.Expr, h: sp.Expr, x: sp.Symbol,
                         y: sp.Symbol, n: int, *, validate: bool = True) -> sp.Expr:
    """Finite formal Lagrange--Buermann formula; not an analytic error theorem."""
    if not isinstance(x, sp.Symbol) or not isinstance(y, sp.Symbol):
        raise TypeError("x and y must be symbols")
    if isinstance(n, bool) or not isinstance(n, int) or n < 0:
        raise ValueError("n must be a nonnegative integer")
    phi, h = map(sp.sympify, (phi, h))
    if x == y or h.has(y):
        raise ValueError("Use distinct variables; h must not contain the target variable")
    if validate and phi.has(x):
        raise ValueError("The core inverse phi must not contain the eliminated source variable")
    hy = h.subs(x, phi)
    return sp.expand(phi + sum(
        (-1) ** k / sp.factorial(k) * sp.diff(sp.diff(phi, y) * hy ** k, y, k - 1)
        for k in range(1, n + 1)))
