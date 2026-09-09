#!/usr/bin/env python3
"""Exact independent mathematical checks; this does not execute Wolfram code."""
from __future__ import annotations
from fractions import Fraction as Q
import json
from pathlib import Path
import platform
import sympy as sp


def main() -> None:
    x, y = sp.symbols("x y")
    checks: dict[str, bool] = {}
    f = lambda q: q + q*q
    checks["false-certificate-root-solves-unrestricted-equation"] = f(Q(1)) == 2
    checks["false-certificate-root-violates-domain"] = not Q(1) < Q(1,4)
    checks["entire-invalid-interval-violates-domain"] = Q(9,10) > Q(1,4)
    checks["branch-image-supremum-is-5/16"] = f(Q(1,4)) == Q(5,16)
    checks["requested-target-outside-branch-image"] = Q(2) > Q(5,16)
    checks["valid-control-root"] = f(Q(1,10)) == Q(11,100)
    checks["valid-control-whole-interval-in-domain"] = 0 < Q(9,100) < Q(11,100) < Q(1,4)
    checks["strict-boundary-contact-is-excluded"] = not Q(1,4) < Q(1,4)
    checks["new-center-is-strictly-interior"] = Q(1,5) < Q(9,40) < Q(1,4)
    checks["invalid-interval-derivative-positive"] = 1 + 2*Q(9,10) > 0
    checks["flat-dense-pair-count"] = (8+1)**2 == 81
    checks["flat-budget-sandwich"] = 49 <= 60 < 81
    # Independent sparse support calculation; no emulation of the package's pMul.
    a = {0: Q(1)}
    b = {0: Q(1)}
    convolution: dict[int,Q] = {}
    for i, ai in a.items():
        for j, bj in b.items():
            convolution[i+j] = convolution.get(i+j,Q(0)) + ai*bj
    checks["flat-active-pair-count"] = len(a)*len(b) == 1
    checks["flat-constant-convolution"] = convolution == {0: Q(1)}
    g = y-y**2+2*y**3-5*y**4+14*y**5
    checks["polynomial-inverse-residual"] = sp.series(g+g*g-y,y,0,6).removeO() == 0
    checks["polynomial-root-expansion"] = sp.series((sp.sqrt(1+4*y)-1)/2,y,0,6).removeO() == g
    # Formal coefficient computation: x^x = exp(x log x).
    L = sp.symbols("L")
    checks["logarithmic-coefficients"] = sp.series(sp.exp(x*L),x,0,3).removeO() == 1+x*L+x*x*L*L/2
    alpha = sp.sqrt(2)
    checks["irrational-inverse-retained-weights"] = bool(1 < alpha < 2*alpha-1 < 2)
    checks["irrational-inverse-first-omitted-weight"] = bool(3*alpha-2 > 2)
    # h(t) + t h(t)^alpha = 1, h=1+c1*t+c2*t^2+c3*t^3+...
    t = sp.symbols("t")
    c1, c2, c3 = -1, alpha, -alpha*(3*alpha-1)/2
    h = 1+c1*t+c2*t**2+c3*t**3
    checks["irrational-inverse-independent-composition"] = sp.simplify(sp.series(h+t*h**alpha-1,t,0,4).removeO()) == 0
    result = {"evidence_class":"Independent exact mathematics, not Wolfram execution",
              "python":platform.python_version(),"sympy":sp.__version__,
              "checks":checks,"passed":sum(checks.values()),"total":len(checks)}
    path = Path(__file__).resolve().parents[1]/"evidence"/"independent_checks.json"
    path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))
    if not all(checks.values()):
        raise SystemExit(1)

if __name__ == "__main__":
    main()
