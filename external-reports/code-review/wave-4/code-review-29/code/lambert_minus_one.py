"""Numerical real W_{-1} through a stable logarithmic branch-point coordinate.

Input delta >= 0 means z=-exp(-1-delta). We solve v-log(1+v)=delta,
v>=0, and return W_{-1}(z)=-1-v. No two-argument ProductLog is called.
Mathematical brackets are proved in the article; computed endpoints use ordinary
mpmath arithmetic, NOT directed rounding. This is not an interval certificate.
"""
from __future__ import annotations
from dataclasses import dataclass
import mpmath

@dataclass
class Result:
    value: object
    correction: object
    lower_correction: object
    upper_correction: object
    iterations: int
    log_equation_residual: object
    working_digits: int
    certified: bool = False


def stable_phase(v, ctx):
    if v < 0: raise ValueError('v must be nonnegative')
    if v == 0: return ctx.mpf(0)
    if v > ctx.mpf('0.5'): return v-ctx.log1p(v)
    term = v*v/2
    total = term
    k = 2
    while True:
        term *= -v*k/(k+1)
        total += term
        k += 1
        if abs(term) <= abs(total)*ctx.eps:
            return total
        if k > 8*ctx.dps+100:
            raise ArithmeticError('Stable local phase series did not converge within its budget')


def from_log_excess(delta, digits: int = 60, max_iterations: int | None = None) -> Result:
    """delta should be an exact decimal string or a sufficiently precise number.

    digits controls relative accuracy of the correction v, not manufactured
    information about an inexact supplied argument. Python floats are refused.
    """
    if isinstance(delta,float):
        raise TypeError('Use an exact decimal string, not a binary float')
    if isinstance(digits,bool) or not isinstance(digits,int) or not 1 <= digits <= 1000:
        raise ValueError('digits must be an integer in [1,1000]')
    ctx = mpmath.mp.clone()
    ctx.dps = digits+40
    d = ctx.mpf(delta)
    if not ctx.isfinite(d) or d < 0: raise ValueError('delta must be finite and nonnegative')
    if d == 0:
        z = ctx.mpf(0)
        return Result(ctx.mpf(-1),z,z,z,0,z,ctx.dps)
    # Extra digits preserve -1-v when v is extremely small. Keep v separately too.
    extra = max(0,int(ctx.ceil(-ctx.log10(d)/2)))
    if extra > 10000: raise ValueError('delta exceeds the prototype branch-point precision budget')
    ctx.dps = digits+40+extra
    d = ctx.mpf(delta)
    lo = ctx.sqrt(2*d)
    hi = d+ctx.sqrt(d*d+2*d)
    if max_iterations is None: max_iterations = 4*digits+100
    if (isinstance(max_iterations,bool) or not isinstance(max_iterations,int)
            or max_iterations < 1):
        raise ValueError('max_iterations must be a positive integer')
    tolerance = ctx.power(10,-digits)*lo
    iterations = 0
    while hi-lo > tolerance:
        if iterations >= max_iterations:
            raise ArithmeticError('Bisection exhausted its iteration budget')
        mid = (lo+hi)/2
        if stable_phase(mid,ctx) < d: lo = mid
        else: hi = mid
        iterations += 1
    v = (lo+hi)/2
    return Result(-1-v,v,lo,hi,iterations,stable_phase(v,ctx)-d,ctx.dps)
