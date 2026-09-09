#!/usr/bin/env python3
"""Independent mathematical checks; does NOT execute the Wolfram package.
Run from any directory. Requires SymPy. Writes evidence/independent_checks.json.
"""
from __future__ import annotations
import json
import math
import platform
from fractions import Fraction
from pathlib import Path
import sympy as sp

ROOT = Path(__file__).resolve().parents[1]

def lattice_span(exponents: list[Fraction], remainder: Fraction) -> dict[str, int]:
    """Exact proposed dense-array size, without allocating that array."""
    if any(p >= remainder for p in exponents):
        raise ValueError("Retained powers must lie strictly below the frontier")
    if not exponents:
        return {"denominator": remainder.denominator, "slots": 0, "blocks": 0}
    den = math.lcm(*(p.denominator for p in [*exponents, remainder]))
    span = (remainder-min(exponents))*den
    if span.denominator != 1 or span < 0:
        raise ValueError("Invalid sparse frontier")
    return {"denominator": den, "slots": int(span), "blocks": len(exponents)}


def run() -> dict:
    checks = []
    def record(name: str, condition, **details):
        ok = bool(condition)
        checks.append({"id": name, "passed": ok, **details})
        if not ok:
            raise AssertionError(name)

    dense = []
    for q in [10, 1000, 10**6, 10**9]:
        row = {"q": q, **lattice_span([Fraction(0), Fraction(1,q)], Fraction(1))}
        dense.append(row)
        record(f"dense-span-{q}", row["slots"] == q, **row)

    # Obtain the inverse independently by solving the residual coefficient at
    # each degree, rather than implementing the repository's Euler formula.
    y, L, C = sp.symbols('y L C')
    inverse = y
    coefficients = []
    for n in range(2, 6):
        trial = inverse + C*y**n
        log_trial = L + sp.series(sp.log(trial/y), y, 0, n+1).removeO()
        residual = sp.series(trial+trial**2*log_trial-y, y, 0, n+1).removeO().expand()
        solution = sp.solve(sp.Eq(residual.coeff(y,n),0), C)[0].expand()
        inverse += solution*y**n
        coefficients.append({"power": n, "coefficient_in_L": str(solution)})
    expected = [-L, 2*L**2+L, -5*L**3-sp.Rational(11,2)*L**2-L,
                14*L**4+sp.Rational(73,3)*L**3+sp.Rational(21,2)*L**2+L]
    for row, exp in zip(coefficients, expected):
        record(f"log-inverse-coefficient-{row['power']}",
               sp.expand(sp.sympify(row['coefficient_in_L'])-exp)==0, **row)
    log_inverse = L+sp.series(sp.log(inverse/y),y,0,6).removeO()
    residual = sp.series(inverse+inverse**2*log_inverse-y,y,0,6).removeO().expand()
    record("log-inverse-residual-through-five", residual==0,
           normalized_residual=str(residual), interpretation="L represents Log[y]")

    # Independent algebraic inverse and observable coefficient oracle.
    exact_g = (sp.sqrt(1+4*y)-1)/2
    ordinary = sp.series(exact_g,y,0,6).removeO()
    square = sp.series(exact_g**2,y,0,6).removeO()
    record("ordinary-inverse-first-correction", ordinary.coeff(y,2)==-1)
    record("square-observable-first-correction", square.coeff(y,3)==-2)

    # Magnitude remainder cannot be translated to a smaller Big-O.
    x=sp.symbols('x', positive=True)
    record("log-remainder-not-O-x",sp.limit(abs(sp.log(x)),x,0,dir='+')==sp.oo)
    # The derivative example is established by an exact symbolic derivative;
    # subsequences with sine=0 and cosine=1 show the unbounded ratio.
    R=x**2*sp.sin(x**-3)
    derivative=sp.diff(R,x)
    record("derivative-counterexample-identity",
           sp.simplify(derivative-(2*x*sp.sin(x**-3)-3*x**-2*sp.cos(x**-3)))==0,
           derivative=str(derivative),
           subsequence="x_n=(2*pi*n)^(-1/3): R'(x_n)/x_n=-6*pi*n")

    # A fixed replay margin does not compensate an arbitrary pole valuation.
    H=5; alpha=-100; replay_order=H+2
    attained=replay_order+alpha
    needed=H-alpha
    record("valuation-aware-demand", needed==105 and attained==-93,
           requested=H, fixed_margin_source_order=replay_order,
           resulting_error_power=attained, necessary_source_order=needed)

    # Exact exponent collisions must be combined before truncation/frontiers.
    record("algebraic-weight-collision",
           sp.simplify(sp.sqrt(8)-2*sp.sqrt(2))==0)

    # Rational certificate theorem in a simple explicit case, independently
    # of the package interval evaluator: f=x+x^2, target=1/10.
    lo,hi,c = Fraction(0),Fraction(1,5),Fraction(1,10)
    residual_c=c+c*c-Fraction(1,10)
    mu=Fraction(1); radius=abs(residual_c)/mu
    bracket=(c-radius,c+radius)
    left=lo+lo*lo-Fraction(1,10); right=hi+hi*hi-Fraction(1,10)
    record("rational-residual-certificate",lo<=bracket[0]<=bracket[1]<=hi and left<0<right,
           residual=str(residual_c), derivative_lower_bound=str(mu),
           root_bracket=[str(v) for v in bracket],
           scope="An independent elementary example, not a package certificate run")

    result={"scope":"Independent mathematical checks; no Wolfram package execution",
            "repository_commit":"07a9781212beb2eeb9ff16aa625b50ac27974078",
            "python":platform.python_version(),"sympy":sp.__version__,
            "passed":sum(c['passed'] for c in checks),"failed":sum(not c['passed'] for c in checks),
            "dense_plans":dense,"inverse_log_coefficients":coefficients,
            "checks":checks}
    dest=ROOT/'evidence'/'independent_checks.json'
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:result[k] for k in ('scope','passed','failed')},indent=2))
    return result

if __name__=='__main__':
    run()
