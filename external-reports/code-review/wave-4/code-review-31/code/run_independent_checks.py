"""Independent Python evidence; no Wolfram or Mathics package execution.

Writes a JSON record of a real POSIX venv witness, nonfinite subprocess
arguments, exact affine-interval counterexample checks, defining Taylor
coefficient identities, Stirling order arithmetic, and traversal counts.
"""
from __future__ import annotations
import argparse
from fractions import Fraction as Q
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import venv
from runner_fixes import interpreter_path


def venv_witness() -> dict:
    if os.name != "posix": return {"status": "not-run", "reason": "POSIX witness"}
    with tempfile.TemporaryDirectory(prefix="asymptotic-identity-") as directory:
        root = Path(directory) / "env"
        venv.EnvBuilder(with_pip=False, symlinks=True).create(root)
        executable = root / "bin/python"
        code = ('import sys,sysconfig,json; print(json.dumps(dict(executable=sys.executable,'
                'prefix=sys.prefix,base_prefix=sys.base_prefix,site=sysconfig.get_path("purelib"))))')
        def run(path, text):
            p = subprocess.run([str(path), "-I", "-c", text], capture_output=True,
                               text=True, timeout=10)
            return p
        preserved = json.loads(run(interpreter_path(str(executable)), code).stdout)
        resolved = json.loads(run(executable.resolve(), code).stdout)
        site = Path(preserved["site"]); site.mkdir(parents=True, exist_ok=True)
        (site / "asymptotic_env_only_731.py").write_text("value = 731\n")
        test = "from asymptotic_env_only_731 import value; print(value)"
        fixed = run(interpreter_path(str(executable)), test)
        original = run(executable.resolve(), test)
        assert fixed.returncode == 0 and original.returncode != 0
        return {"status": "observed", "symlink": executable.is_symlink(),
                "preserved": preserved, "production_resolve": resolved,
                "venv_only_import_preserved_exit": fixed.returncode,
                "venv_only_import_resolved_exit": original.returncode,
                "resolved_import_stderr": original.stderr.strip(),
                "scope": "Python launcher mechanism; no Mathics installed"}


def timeout_witness() -> list[dict]:
    records = []
    # Child is explicitly terminated after every probe. No nonfinite timeout
    # is ever passed to our cleanup operation.
    for label in ("nan", "inf", "1e100"):
        value = float(label)
        p = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(.05); print('done')"],
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        record = {"argument": label, "original_guard_accepts": not (value <= 0)}
        try:
            out, _ = p.communicate(timeout=value)
            record.update(outcome="returned", output=out.decode().strip())
        except Exception as exc:
            record.update(outcome=type(exc).__name__, message=str(exc))
        finally:
            if p.poll() is None: p.kill()
            p.communicate(timeout=5)
        records.append(record)
    return records


def affine_claim(a: Q, b: Q, relation: str):
    nonnegative = a >= 0 and b >= 0
    nonpositive = a <= 0 and b <= 0
    positive = nonnegative and (a > 0 or b > 0)
    negative = nonpositive and (a < 0 or b < 0)
    zero = a == b == 0
    if relation == ">": return True if positive else False if nonpositive else None
    if relation == ">=": return True if nonnegative else False if negative else None
    if relation == "<": return True if negative else False if nonnegative else None
    if relation == "<=": return True if nonpositive else False if positive else None
    if relation == "==": return True if zero else False if positive or negative else None
    if relation == "!=": return True if positive or negative else False if zero else None
    raise ValueError(relation)


def compare(v: Q, relation: str) -> bool:
    return {">": v > 0, ">=": v >= 0, "<": v < 0, "<=": v <= 0,
            "==": v == 0, "!=": v != 0}[relation]


def affine_checks() -> dict:
    claims = samples = inconclusive = 0
    relations = (">", ">=", "<", "<=", "==", "!=")
    for a in range(-8, 9):
        for b in range(-8, 9):
            for relation in relations:
                truth = affine_claim(Q(a), Q(b), relation)
                if truth is None:
                    inconclusive += 1; continue
                claims += 1
                for j in range(1, 20):
                    t = Q(j, 20)
                    value = (1-t)*a + t*b
                    assert compare(value, relation) == truth, (a, b, relation, t)
                    samples += 1
    return dict(claims=claims, rational_point_checks=samples, unknown_preserved=inconclusive,
                failures=0, scope="independent model of endpoint inequalities; not a Mathics run")


def pochhammer(a: Q, k: int) -> Q:
    value = Q(1)
    for j in range(k): value *= a + j
    return value


def hyper_coefficient(upper: tuple[Q,...], lower: tuple[Q,...], k: int) -> Q:
    numerator = math.prod(pochhammer(a, k) for a in upper)
    denominator = math.factorial(k) * math.prod(pochhammer(b, k) for b in lower)
    return Q(numerator, denominator)


def taylor_checks() -> dict:
    checked = 0
    for k in range(31):
        assert hyper_coefficient((), (Q(1),), k) * Q(-1, 4)**k == Q((-1)**k, 4**k * math.factorial(k)**2)
        assert hyper_coefficient((Q(1),), (Q(2),), k) == Q(1, math.factorial(k+1))
        assert hyper_coefficient((Q(1),Q(1)), (Q(2),), k) == Q(1, k+1)
        assert hyper_coefficient((Q(-4),), (Q(2),), k) == (Q((-1)**k * math.comb(4,k), math.factorial(k+1)) if k <= 4 else 0)
        checked += 4
    monomial_checks = 0
    for degree in (1,2,3,7):
        for order in range(31):
            indices = [k for k in range(order+1) if k % degree == 0]
            assert all(i//degree <= order//degree for i in indices)
            first_omitted = degree * (order//degree + 1)
            assert first_omitted >= order + 1
            monomial_checks += 1
    return dict(exact_coefficient_identities=checked, monomial_order_checks=monomial_checks,
                failures=0, scope="exact rational identities and degree bookkeeping; not native Series")


def stirling_checks() -> dict:
    checked = 0
    for rate in (Q(1,5),Q(1,2),Q(1),Q(3,2),Q(2),Q(7)):
        for i in range(-12, 161):
            cutoff = Q(i, 7)
            count = max(0, math.ceil((cutoff/rate + 1)/2) - 1)
            assert (2*count+1)*rate >= cutoff
            if count: assert (2*count-1)*rate < cutoff
            checked += 1
    return dict(cutoff_rate_pairs=checked, failures=0,
                scope="arithmetic of the stated Stirling tail exponent, not proof of a package result")


def search_counts() -> list[dict]:
    results=[]
    for m in (10, 100, 1000, 10000):
        # out contains m distinct weights; every new duplicate is at position 1.
        repeats = 100
        full = 0; short = 0
        values = list(range(m))
        for _ in range(repeats):
            matches=[]
            for i, value in enumerate(values):
                full += 1
                if value == 0: matches.append(i)
            for i, value in enumerate(values):
                short += 1
                if value == 0: break
            assert matches[0] == 0
        results.append(dict(existing_rows=m, appended_duplicates=repeats,
                            full_position_predicates=full, stop_after_first_predicates=short))
    return results


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("evidence/independent_checks.json"))
    args=parser.parse_args()
    data={"Python":sys.version,"Platform":sys.platform,
          "WolframPackageExecution":False,"MathicsPackageExecution":False,
          "venv":venv_witness(),"timeouts":timeout_witness(),
          "affine":affine_checks(),"taylor":taylor_checks(),
          "stirling":stirling_checks(),"search_operation_counts":search_counts()}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, indent=2)+"\n")
    print(json.dumps(data, indent=2))
    return 0

if __name__ == "__main__": raise SystemExit(main())
