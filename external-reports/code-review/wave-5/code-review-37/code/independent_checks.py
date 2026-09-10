#!/usr/bin/env python3
"""Independent exact countermodels and synthetic patch tests; NOT package tests.

Standard-library Python 3.9+. No Wolfram kernel, emulation, or external network.
The public Wolfram predictions in the article are not observations from this code.
"""
from __future__ import annotations
import argparse
from decimal import Decimal, localcontext
from fractions import Fraction as F
import json
from pathlib import Path
import platform
from typing import Dict, Tuple
import emit_candidate_patch as patch

Gaussian = Tuple[F, F]
Poly = Dict[int, Gaussian]
ZERO = (F(0), F(0))
ONE = (F(1), F(0))

def add(a: Gaussian, b: Gaussian) -> Gaussian:
    return a[0] + b[0], a[1] + b[1]

def mul(a: Gaussian, b: Gaussian) -> Gaussian:
    return a[0]*b[0] - a[1]*b[1], a[0]*b[1] + a[1]*b[0]

def padd(*args: Poly) -> Poly:
    out: Poly = {}
    for p in args:
        for k, c in p.items():
            out[k] = add(out.get(k, ZERO), c)
    return {k: c for k, c in out.items() if c != ZERO}

def pmul(a: Poly, b: Poly) -> Poly:
    out: Poly = {}
    for i, x in a.items():
        for j, y in b.items():
            out[i+j] = add(out.get(i+j, ZERO), mul(x, y))
    return {k: c for k, c in out.items() if c != ZERO}

def conjugate(a: Poly) -> Poly:
    return {k: (r, -i) for k, (r, i) in a.items()}

def source_model_abs(p: Poly) -> Poly:
    """Faithful ONLY for the positive-real-leading branch under investigation."""
    c = p[min(p)]
    if c[1] != 0 or c[0] <= 0:
        raise ValueError("This reduced source model covers positive real leading coefficients only")
    return dict(p)

def binomial(q: F, n: int) -> F:
    r = F(1)
    for k in range(n):
        r *= (q-k)/(k+1)
    return r

def synthetic_sources() -> Dict[str, str]:
    # Deliberately SMALL source fragments, not fetched complete source files.
    return {
        patch.CORE: "(* synthetic anchor fixture *)\n" + patch.ABS_OLD + "\n  Null];\n",
        patch.OPS: "(* synthetic anchor fixture *)\n" + patch.POWER_HEAD + "\n" + patch.ZERO_OLD + "\n  Null];\n",
        patch.GAMMA: "(* synthetic anchor fixture *)\n" + patch.GAMMA_OLD + "\n" + patch.MEANING_OLD + "\n",
    }

def run() -> dict:
    results = []
    def check(name: str, predicate: bool, scope: str) -> None:
        if not predicate:
            raise AssertionError(name)
        results.append({"name": name, "passed": True, "scope": scope})
    plus = {0: ONE, 1: (F(0), F(1))}
    minus = conjugate(plus)
    wrong = padd(source_model_abs(plus), source_model_abs(minus), {0: (F(-2), F(0))})
    check("F01: sign-only sparse model returns exact zero", wrong == {}, "source-model algebra")
    check("F01: conjugate norm is 1+x^2", pmul(plus, minus) == {0: ONE, 2: ONE}, "exact Gaussian-rational algebra")
    coeff = {2*k: 2*binomial(F(1, 2), k) for k in range(1, 7)}
    check("F01: nonzero correct leading term", coeff[2] == 1, "exact binomial algebra")
    check("F01: six coefficients of the correct modulus expansion",
          list(coeff.values()) == [F(1), -F(1,4), F(1,8), -F(5,64), F(7,128), -F(21,512)],
          "exact binomial algebra")
    general_cases = []
    for a in [F(1, 3), F(1), F(7, 2)]:
        p = {0: ONE, 1: (F(0), a)}
        check(f"F01 norm identity for imaginary amplitude {a}",
              pmul(p, conjugate(p)) == {0: ONE, 2: (a*a, F(0))}, "exact parameter-family algebra")
        general_cases.append(str(a))
    check("F01 narrow guard rejects nonreal retained coefficients", any(c[1] != 0 for c in plus.values()), "guard predicate model")
    realp = {0: ONE, 1: (F(3), F(0))}
    check("F01 narrow guard preserves real retained coefficients", all(c[1] == 0 for c in realp.values()), "guard predicate model")
    # Logical domain test, not a simulation of FullSimplify or a WL evaluator.
    allowed = [-2, -1, 0, 1, 2]
    old_domain = {a: True for a in allowed}  # nonempty symbolic row before specializing
    required_domain = {a: a != 0 for a in allowed}
    check("F02: nonempty symbolic row does not exclude a=0", old_domain[0] and not required_domain[0], "finite logical countermodel")
    check("F02: unsigned but nonzero real amplitudes are admissible",
          all(required_domain[a] for a in [-2, -1, 1, 2]), "finite logical controls")
    cutoffs = [F(-2), F(-1), F(0), F(1,3), F(1), F(2)]
    cutoff_rows = []
    for h in cutoffs:
        expected_expression = 1 if h > 0 else 0
        row = {"cutoff": str(h), "expected_expression": expected_expression,
               "expected_remainder_power": "Infinity" if h > 0 else "0",
               "old_branch_expression": 1, "old_branch_cutoff": "1"}
        cutoff_rows.append(row)
    check("F03: zero cutoff excludes the constant monomial", cutoff_rows[2]["expected_expression"] == 0, "exclusive-cutoff model")
    check("F03: every positive cutoff retains the constant monomial",
          all(row["expected_expression"] == 1 for row in cutoff_rows[3:]), "exclusive-cutoff controls")
    before = synthetic_sources()
    after = patch.transform_sources(before)
    check("Candidate transformations modify exactly three fixture files", set(after) == set(before) and all(after[k] != before[k] for k in before), "synthetic text fixture")
    check("F01 candidate installs local real-polynomial guard", "UnprovedAbsArgument" in after[patch.CORE], "synthetic text fixture")
    check("F02 candidate checks nonvanishing without choosing a sign", 'c != 0 && d["Prefactor"] != 0' in after[patch.OPS], "synthetic text fixture")
    check("F03 candidate forwards explicit cutoff", "If[cut === Automatic, 1, cut]" in after[patch.GAMMA], "synthetic text fixture")
    check("Candidate unified diff has all three source paths", all("+++ b/"+p in patch.make_diff(before, after) for p in before), "synthetic text fixture")
    for name, altered in [
        ("missing anchor", {**before, patch.CORE: before[patch.CORE].replace(patch.ABS_OLD, "missing")}),
        ("duplicate anchor", {**before, patch.CORE: before[patch.CORE] + patch.ABS_OLD}),
        ("already patched", after),
        ("missing file", {k:v for k,v in before.items() if k != patch.OPS}),
    ]:
        refused = False
        try:
            patch.transform_sources(altered)
        except ValueError:
            refused = True
        check("Candidate refuses " + name, refused, "synthetic text fixture")
    table = []
    with localcontext() as ctx:
        ctx.prec = 70
        for j in [1, 2, 3, 4, 6]:
            x = Decimal(10) ** (-j)
            root = (1+x*x).sqrt()
            # Rationalized expression avoids cancellation in the tiny defect.
            value = 2*x*x/(root+1)
            table.append({"x": str(x), "true_modulus_defect": str(value),
                          "defect_over_x_squared": str(value/(x*x))})
    return {"python": platform.python_version(), "reviewed_commit": patch.COMMIT,
            "status": "passed", "named_checks": len(results), "checks": results,
            "F01_correct_coefficients": {str(k):str(v) for k,v in coeff.items()},
            "F01_decimal_witnesses": table, "F03_cutoff_cases": cutoff_rows,
            "scope": "Independent mathematical/source-model checks and small synthetic text fixtures only.",
            "wolfram_package_executed": False, "wolfram_candidate_executed": False,
            "real_checkout_patch_tested": False, "native_timings_measured": False}

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parents[1]/"evidence"/"independent_results.json")
    args = parser.parse_args()
    report = run()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(f"PASS: {report['named_checks']} named independent checks; no Wolfram package execution.")
    print(args.output)

if __name__ == "__main__":
    main()
