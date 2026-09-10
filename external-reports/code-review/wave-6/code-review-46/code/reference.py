"""Independent oracle for a*exp(c*x)+delta=y; not an Asymptotic port.

All identities here are proved in the article. SymPy is only needed for the
coefficient-recurrence check; rational tail bounds use the standard library.
"""
from __future__ import annotations
from fractions import Fraction
import sympy as sp


def require_depth(n: int) -> None:
    if isinstance(n, bool) or not isinstance(n, int) or n < 0:
        raise ValueError('Depth must be a nonnegative integer.')


def positive_tail_bounds(y: Fraction, delta: Fraction, c: Fraction,
                         depth: int) -> tuple[Fraction, Fraction]:
    """Rigorous bounds for approximation minus exact inverse, 0<delta<y,c>0."""
    require_depth(depth)
    y, delta, c = map(Fraction, (y, delta, c))
    if not (c > 0 and 0 < delta < y):
        raise ValueError('Require c>0 and 0<delta<y.')
    t = delta / y
    lower = t ** (depth + 1) / (c * (depth + 1))
    return lower, lower / (1 - t)


def normalized_coefficient(n: int, amplitude: sp.Expr, c: sp.Expr,
                           perturbation: sp.Expr, v: sp.Symbol) -> sp.Expr:
    """Transcription of the read WL recurrence, specialized to b=0,p=1.

    amplitude is the NORMALIZED core amplitude A=a*exp(c*sigma), not a.
    It must be independent of v for this recurrence's differentiation.
    """
    if isinstance(n, bool) or not isinstance(n, int) or n < 1:
        raise ValueError('Coefficient index must be a positive integer.')
    amplitude, c, perturbation = map(sp.sympify, (amplitude, c, perturbation))
    if not isinstance(v, sp.Symbol):
        raise ValueError('The local variable must be a SymPy Symbol.')
    if amplitude.has(v) or c.has(v):
        raise ValueError('Core amplitude and c must be independent of v.')
    denominator = amplitude * c
    q = sp.cancel(perturbation ** n / denominator)
    for j in range(1, n):
        q = sp.cancel((sp.diff(q, v) - j * c * q) / denominator)
    return sp.simplify((-1) ** n * q / sp.factorial(n))


def finite_inverse(y: sp.Expr, a: sp.Expr, c: sp.Expr,
                   delta: sp.Expr, depth: int) -> sp.Expr:
    require_depth(depth)
    y, a, c, delta = map(sp.sympify, (y, a, c, delta))
    return (sp.log(y / a) - sum(delta ** n / (n * y ** n)
                                for n in range(1, depth + 1))) / c


def reported_scale(y: sp.Expr, a: sp.Expr, c: sp.Expr,
                   sigma: sp.Expr, depth: int) -> sp.Expr:
    """Read constructor formula for constant nonzero perturbation, b=0,p=r=1."""
    require_depth(depth)
    y, a, c, sigma = map(sp.sympify, (y, a, c, sigma))
    return (a * sp.exp(c * sigma) / y) ** (depth + 1)
