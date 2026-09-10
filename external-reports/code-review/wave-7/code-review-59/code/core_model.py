"""Exact independent model of N01; this does NOT load or emulate the package.

On the positive target ray, c*Abs[y] = c*y. The inverse of
x+c*y + lambda*(-c*y) = y is ((1-c)+c*lambda)*y. The source-derived
remainder power is -r+n+1. See the article for fixed-parameter hypotheses.
"""
from __future__ import annotations
from fractions import Fraction
from math import comb


def family(c: Fraction, r: int, n: int, y: Fraction) -> dict[str, Fraction | int]:
    if not isinstance(c, Fraction) or not isinstance(y, Fraction):
        raise TypeError('c and y must be Fraction values')
    if not 0 < c < 1 or y <= 0:
        raise ValueError('require 0<c<1 and y>0')
    if type(r) is not int or type(n) is not int or r < 1 or n < 0:
        raise ValueError('require integer r>=1 and n>=0')
    b = 1 - c
    coefficient = sum((Fraction(comb(r, k)) * b**(r-k) * c**k
                       for k in range(min(n, r) + 1)), Fraction(0))
    approximation = y**r * coefficient
    error = y**r - approximation
    rho = -r + n + 1
    scale = (1 / (b*y))**rho
    return {'c': c, 'r': r, 'n': n, 'y': y, 'rho': rho,
            'approximation': approximation, 'exact_observable': y**r,
            'error': error, 'scale': scale, 'ratio': error/scale}


def local_marker_term(r: int, n: int):
    """Reproduce only the displayed mathematical derivative formula in SymPy.

    A denotes the fixed offset during differentiation. Only afterwards does
    the audit set A=c*y. Independent expected coefficient: binomial(r,n)*A^n.
    """
    import sympy as sp
    if type(r) is not int or type(n) is not int or r < 1 or n < 1:
        raise ValueError('positive integer r,n required')
    u, A = sp.symbols('u A', positive=True)
    fp = sp.diff(1/u + A, u)
    hp = sp.diff(u**(-r), u)
    term = sp.cancel(hp * (-A)**n / fp)
    for _ in range(n - 1):
        term = sp.cancel(sp.diff(term, u)/fp)
    return sp.factor((-1)**n * term/sp.factorial(n)), u, A
