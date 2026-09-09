#!/usr/bin/env python3
"""Exact/model oracles for the article, not execution of Wolfram package code.
Only Python's standard library is required. SPDX-License-Identifier: MIT-0.
"""
from __future__ import annotations
from decimal import Decimal, localcontext
from fractions import Fraction
from math import comb
from pathlib import Path
import csv
import json

ROOT = Path(__file__).resolve().parents[1]

def dec(q: Fraction) -> Decimal:
    return Decimal(q.numerator) / Decimal(q.denominator)

def catalan(n: int) -> int:
    return comb(2*n, n) // (n+1)

def old_boundary_degree(rows1: list[tuple[int, int]],
                        rows2: list[tuple[int, int]], weight: int) -> int:
    """The source's two-pointer algorithm, deliberately given duplicate weights.
    A row is (semantic weight, polynomial degree). Duplicate integer weights
    here model distinct syntax for equal transcendental weights, NOT what the
    kernel would do to literal duplicate integer input weights.
    """
    i, j, degree = 0, len(rows2)-1, 0
    while i < len(rows1) and j >= 0:
        value = rows1[i][0] + rows2[j][0]
        if value < weight:
            i += 1
        elif value > weight:
            j -= 1
        else:
            degree = max(degree, rows1[i][1] + rows2[j][1])
            i += 1
            j -= 1
    return degree

def main() -> None:
    out = ROOT / "results"
    out.mkdir(exist_ok=True)
    families = []
    # Noncancelling polynomials L^p and L^q, p < q.
    for p in range(8):
        for q in range(p+1, 13):
            reported = old_boundary_degree([(0,0),(1,p),(1,q)],
                                           [(0,0),(1,p),(1,q)], 2)
            correct = 2*q
            repaired = old_boundary_degree([(0,0),(1,q)], [(0,0),(1,q)], 2)
            assert reported == p+q < correct
            assert repaired == correct
            families.append({"p":p, "q":q, "old_degree":reported,
                             "required_degree":correct, "merged_degree":repaired})
    # Exact positive certificate for the numerical example.
    y = Fraction(1,1000)
    s = sum(((-1)**(n-1)*catalan(n-1)*y**n for n in range(1,20)), Fraction())
    residual = s+s*s-y
    assert residual > 0 and s > 0
    lower = residual / (1+s+y)
    upper = residual / (1+s)
    assert 0 < lower < upper
    with localcontext() as ctx:
        ctx.prec = 120
        yd, sd = dec(y), dec(s)
        g = 2*yd / (1+(1+4*yd).sqrt())
        error = dec(residual)/(1+sd+g)
        assert dec(lower) < error < dec(upper)
        records = []
        a = ((Decimal(2).exp()+Decimal(-2).exp())/2-1)/2
        for m in (5,10,20,40,80):
            t = (-a*Decimal(m)).exp()  # t = x^a, x = exp(-m)
            L = Decimal(-m)
            # (F^2 - [1+2t(1+L^3)]) / x^(2a), evaluated without cancellation.
            normalized = (1+L**3)**2 + 2 + 2*t*(1+L**3) + t*t
            old_ratio = abs(normalized)/(1+abs(L))**3
            good_ratio = abs(normalized)/(1+abs(L))**6
            records.append({"minus_log_x":m, "ratio_to_claimed_degree_3":str(old_ratio),
                            "ratio_to_valid_degree_6":str(good_ratio)})
        result = {
          "scope":"Independent exact arithmetic and model checks; not Wolfram tests",
          "family_cases":len(families),
          "family_assertions":3*len(families),
          "family":families,
          "numeric_oracle":{
            "target":"1/1000", "retained_powers":"1 through 19",
            "error":str(error), "strict_lower_bound_decimal":str(dec(lower)),
            "strict_upper_bound_decimal":str(dec(upper)),
            "strict_lower_bound_rational":str(lower), "strict_upper_bound_rational":str(upper),
            "positive_forward_residual_rational":str(residual),
            "proof":"g+g^2=y, 0<g<y; R=(S-g)(1+S+g); R/(1+S+y)<S-g<R/(1+S)"},
          "remainder_growth":records}
    (out/"independent_oracles.json").write_text(json.dumps(result,indent=2)+"\n")
    with (out/"remainder_growth.csv").open("w",newline="") as f:
        writer=csv.DictWriter(f,fieldnames=list(records[0]));writer.writeheader();writer.writerows(records)
    print(json.dumps({"family_cases":len(families),"family_assertions":3*len(families),
                      "numeric_oracle_error":str(error),"all_assertions_passed":True},indent=2))

if __name__=="__main__": main()
