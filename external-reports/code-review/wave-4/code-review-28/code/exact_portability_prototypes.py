"""Small exact reference algorithms; not integrated Wolfram Language patches."""
from fractions import Fraction as F
from math import prod


def affine_eventual_radius(constraints):
    """Return a rational radius proving every a+b*u relation 0 on 0<u<r.

    Each constraint is (a,b,relation), with rational a,b and one of
    >, >=, <, <=, ==, !=. Return None when the conjunction is eventually false.
    A returned radius is sufficient, not necessarily maximal.
    """
    radius = F(1)
    for a, b, relation in constraints:
        if isinstance(a, float) or isinstance(b, float):
            raise TypeError("Exact rational coefficients required")
        a, b = F(a), F(b)
        if relation in ("<", "<="):
            a, b = -a, -b
            relation = ">" if relation == "<" else ">="
        if relation == "==":
            if a != 0 or b != 0:
                return None
            continue
        if relation == "!=":
            if a == b == 0:
                return None
            if a < 0 or (a == 0 and b < 0):
                a, b = -a, -b
            relation = ">"
        if relation not in (">", ">="):
            raise ValueError("Unsupported relation")
        if a < 0 or (a == 0 and (b < 0 or (b == 0 and relation == ">"))):
            return None
        if a > 0 and b < 0:
            radius = min(radius, a/(-2*b))
    return radius


def terminating_pfq_coefficients(upper, lower, *, max_terms=10000):
    """Polynomial coefficients for a safe terminating generalized hypergeometric series.

    Lower parameters must be positive rationals. Upper parameters are rational,
    with at least one nonpositive integer. No p<=q+1 restriction is needed.
    """
    if any(isinstance(x, float) for x in [*upper, *lower]):
        raise TypeError("Exact rational parameters required")
    aa, bb = list(map(F, upper)), list(map(F, lower))
    if any(b <= 0 for b in bb):
        raise ValueError("Positive lower parameters required")
    degrees = [-int(a) for a in aa if a.denominator == 1 and a <= 0]
    if not degrees:
        raise ValueError("A nonpositive integral upper parameter is required")
    degree = min(degrees)
    if degree+1 > max_terms:
        raise ValueError("Required polynomial coefficients exceed max_terms")
    coefficients = [F(1)]
    for k in range(degree):
        coefficients.append(coefficients[-1] * prod(a+k for a in aa)
                            / ((k+1)*prod(b+k for b in bb)))
    return tuple(coefficients)
