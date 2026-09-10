#!/usr/bin/env python3
"""Exact mathematical/structural checks, independent of the Wolfram package.

Verifies the inverse-coefficient formula via W+t W**p=1 for rational p>1,
and the repeated-subtree-validation recurrence. These are not native tests.
Python 3.9+, standard library only.
"""
from fractions import Fraction as Q
from math import factorial
import json
from pathlib import Path
import argparse


def multiply(a, b, n):
    out = [Q(0)] * (n + 1)
    for i, ai in enumerate(a[:n+1]):
        for j, bj in enumerate(b[:n+1-i]):
            out[i+j] += ai * bj
    return out


def power_of_unit(w, p, n):
    u = list(w[:n+1]) + [Q(0)] * max(0, n+1-len(w))
    if u[0] != 1:
        raise ValueError("The constant coefficient must be exactly one")
    u[0] -= 1
    out, term = [Q(0)] * (n+1), [Q(1)] + [Q(0)]*n
    coefficient = Q(1)
    for k in range(n+1):
        for j in range(n+1):
            out[j] += coefficient * term[j]
        if k < n:
            term = multiply(term, u, n)
            coefficient *= (p-k)/(k+1)
    return out


def inverse_coefficient(p, n):
    if n == 0:
        return Q(1)
    out = Q((-1)**n, factorial(n))
    for j in range(n-1):
        out *= n*p-j
    return out


def run():
    cases = []
    for p in [Q(3,2), Q(2), Q(7,3), Q(11,7), Q(5)]:
        for n in range(1, 11):
            w = [inverse_coefficient(p, k) for k in range(n+1)]
            power = power_of_unit(w, p, n)
            residual = list(w)
            residual[0] -= 1
            for k in range(1,n+1):
                residual[k] += power[k-1]
            if any(residual):
                raise AssertionError((p,n,residual))
            cases.append({"p": str(p), "formal_order": n, "zero_residual": True})
    depths = []
    for d in range(65):
        repeated = sum(j+1 for j in range(1,d+1))
        closed = d*(d+3)//2
        if repeated != closed:
            raise AssertionError((d,repeated,closed))
        depths.append({"depth": d, "validation_visits": repeated})
    return {"scope": "Independent exact rational and structural models; no Wolfram package executed",
            "inverse_identity_cases": len(cases), "inverse_cases": cases,
            "parser_recurrence_cases": len(depths), "parser_cases": depths,
            "all_passed": True}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = run()
    data = json.dumps(result, indent=2) + "\n"
    if args.output:
        with args.output.open("x", encoding="utf-8") as stream:
            stream.write(data)
    else:
        print(data, end="")
