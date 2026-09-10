"""Exact, bounded-input reference oracle for an endpoint incident branch.

This is original audit code, NOT execution or a replacement of AsymptoticAnalysis.
Scope: univariate QQ polynomials, a finite rational source endpoint, a rational
point target, and source side +1/-1.  The selected component ends at the first
real critical point on that side, even if the critical point does not turn the
function.  No floating point comparison or numerical Newton seed is used.
Input budgets do not constitute a wall-clock or memory sandbox.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import cmp_to_key
import sympy as sp


class ReferenceRefused(ValueError):
    """The requested reference is outside the intentionally bounded contract."""


@dataclass(frozen=True)
class BranchReference:
    endpoint: sp.Rational
    side: int
    target: sp.Rational
    lower: sp.Expr
    upper: sp.Expr
    root: sp.Expr
    derivative_sign: int
    equation_roots: tuple[sp.Expr, ...]
    same_side_roots: tuple[sp.Expr, ...]
    scope: str = "Exact QQ polynomial; open critical-point-free endpoint component"

    def to_dict(self) -> dict:
        return {
            "endpoint": str(self.endpoint), "side": self.side,
            "target": str(self.target), "component": [str(self.lower), str(self.upper)],
            "reference_root": str(self.root), "derivative_sign": self.derivative_sign,
            "equation_roots": list(map(str, self.equation_roots)),
            "same_side_roots": list(map(str, self.same_side_roots)),
            "scope": self.scope,
        }


def _sign(value: sp.Expr) -> int:
    value = sp.simplify(value)
    if value == 0:
        return 0
    if value is sp.oo or value.is_positive is True:
        return 1
    if value is -sp.oo or value.is_negative is True:
        return -1
    # Algebraic relational comparisons can succeed when sign properties do not.
    positive = sp.Gt(value, 0)
    negative = sp.Lt(value, 0)
    if positive is sp.true:
        return 1
    if negative is sp.true:
        return -1
    raise ReferenceRefused(f"Exact order proof unavailable: {value}")


def _rational(value: object, name: str) -> sp.Rational:
    value = sp.sympify(value)
    if not isinstance(value, sp.Rational):
        raise ReferenceRefused(f"{name} must be an exact rational, not {value!r}")
    return value


def _roots(poly: sp.Poly) -> tuple[sp.Expr, ...]:
    # SymPy isolates algebraic roots exactly; radicals=False avoids large formulas.
    values = list(dict.fromkeys(poly.real_roots(radicals=False)))
    return tuple(sorted(values, key=cmp_to_key(lambda a, b: _sign(a - b))))


def _preflight_degree(expr: sp.Expr, variable: sp.Symbol, limit: int, bits: int) -> int:
    """Conservative syntax-degree bound BEFORE polynomial expansion.

    Cancellation is deliberately not used to rescue an over-budget expression.
    Already-evaluated caller expressions cannot be retroactively sandboxed.
    """
    if isinstance(expr, sp.Rational):
        if max(abs(int(expr.p)).bit_length(), int(expr.q).bit_length()) > bits:
            raise ReferenceRefused("input rational bit budget exceeded")
        return 0
    if expr == variable:
        return 1
    if expr.is_Add:
        degree = max(_preflight_degree(a, variable, limit, bits) for a in expr.args)
    elif expr.is_Mul:
        degree = sum(_preflight_degree(a, variable, limit, bits) for a in expr.args)
    elif expr.is_Pow and expr.exp.is_Integer and 0 <= expr.exp <= limit:
        degree = int(expr.exp) * _preflight_degree(expr.base, variable, limit, bits)
    else:
        raise ReferenceRefused("unsupported expression or syntactic power budget exceeded")
    if degree > limit:
        raise ReferenceRefused("syntactic degree budget exceeded before expansion")
    return degree


def endpoint_branch_reference(
    expression: sp.Expr,
    variable: sp.Symbol,
    endpoint: object,
    target: object,
    side: int = 1,
    *,
    max_degree: int = 32,
    max_coefficient_bits: int = 4096,
    max_input_ops: int = 2000,
) -> BranchReference:
    """Identify the exact root in the first monotonic source component.

    Raising ReferenceRefused never means the inverse branch does not exist
    globally: it can mean this conservative reference domain is exhausted.
    This API accepts expressions, not strings to parse from untrusted sources.
    """
    if not isinstance(variable, sp.Symbol):
        raise ReferenceRefused("variable must be a Symbol")
    if type(side) is not int or side not in (-1, 1):
        raise ReferenceRefused("side must be +1 or -1")
    for name, value in (("max_degree", max_degree),
                        ("max_coefficient_bits", max_coefficient_bits),
                        ("max_input_ops", max_input_ops)):
        if type(value) is not int or value < 1:
            raise ReferenceRefused(f"{name} must be a positive integer")
    endpoint = _rational(endpoint, "endpoint")
    target = _rational(target, "target")
    expression = sp.sympify(expression)
    if expression.has(sp.Float):
        raise ReferenceRefused("floating-point coefficients are not admitted")
    if expression.free_symbols - {variable}:
        raise ReferenceRefused("parameter-dependent polynomials are not admitted")
    if sp.count_ops(expression) > max_input_ops:
        raise ReferenceRefused("input expression operation budget exceeded")
    _preflight_degree(expression, variable, max_degree, max_coefficient_bits)
    try:
        poly = sp.Poly(expression, variable, domain=sp.QQ)
    except (sp.PolynomialError, sp.CoercionFailed) as exc:
        raise ReferenceRefused("a QQ polynomial is required") from exc
    if poly.degree() < 1 or poly.degree() > max_degree:
        raise ReferenceRefused("polynomial degree is outside the admitted budget")
    all_numbers = poly.all_coeffs() + [endpoint, target]
    if any(max(abs(int(q.p)).bit_length(), int(q.q).bit_length()) > max_coefficient_bits
           for q in all_numbers):
        raise ReferenceRefused("coefficient/endpoint/target bit budget exceeded")
    if poly.eval(endpoint) == target:
        raise ReferenceRefused("the target equals the endpoint image; use an open germ")
    derivative = poly.diff()
    critical = _roots(derivative) if derivative.degree() >= 1 else ()
    on_side = [r for r in critical if _sign(side * (r - endpoint)) > 0]
    if side == 1:
        lower, upper = endpoint, on_side[0] if on_side else sp.oo
    else:
        lower, upper = on_side[-1] if on_side else -sp.oo, endpoint
    roots = _roots(poly - sp.Poly(target, variable, domain=sp.QQ))
    same_side = tuple(r for r in roots if _sign(side * (r - endpoint)) > 0)
    candidates = [r for r in same_side if _sign(r - lower) > 0 and _sign(upper - r) > 0]
    if len(candidates) != 1:
        raise ReferenceRefused(
            f"No unique root in endpoint component ({lower}, {upper}); "
            "no continuation through a critical point was attempted"
        )
    root = candidates[0]
    return BranchReference(endpoint, side, target, lower, upper, root,
                           _sign(derivative.eval(root)), roots, same_side)


def leading_inverse_coefficients(
    expression: sp.Expr, variable: sp.Symbol, order: int
) -> tuple[sp.Expr, ...]:
    """Independent finite reversion at 0 for f(0)=0, f'(0)=1 (test oracle)."""
    if type(order) is not int or not 1 <= order <= 10:
        raise ReferenceRefused("reversion order must lie in 1..10")
    expression = sp.sympify(expression)
    if expression.subs(variable, 0) != 0 or sp.diff(expression, variable).subs(variable, 0) != 1:
        raise ReferenceRefused("this oracle requires f(0)=0 and f'(0)=1")
    y = sp.Dummy("target")
    inverse = y
    coefficients = [sp.Integer(1)]
    for k in range(2, order + 1):
        coefficient = -sp.expand(expression.subs(variable, inverse)).coeff(y, k)
        coefficients.append(coefficient)
        inverse += coefficient * y ** k
    return tuple(coefficients)
