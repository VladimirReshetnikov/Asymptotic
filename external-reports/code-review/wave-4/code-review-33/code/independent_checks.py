"""Run ONLY independent Python/reference checks; not a Mathics package test.
SPDX-License-Identifier: MIT-0
"""
from fractions import Fraction
from pathlib import Path
import json
import platform
import time
import unittest
import mpmath as mp
import sympy as sp
from lambert_minus_one import log_interval, lambert_minus_one, ProofBudgetExceeded

OUT = Path(__file__).resolve().parents[1] / "evidence" / "independent-checks.json"
OBSERVATIONS = {}


def mpr(q: Fraction):
    return mp.mpf(q.numerator) / q.denominator


class ReferenceTests(unittest.TestCase):
    def test_01_log_enclosures(self):
        values = [Fraction(1), Fraction(2), Fraction(3,2), Fraction(1,10),
                  Fraction(10**30), Fraction(1,10**30), Fraction(999,1000)]
        data = []
        with mp.workdps(120):
            for q in values:
                lo, hi = log_interval(q, 160)
                oracle = mp.log(mpr(q))
                self.assertLessEqual(mpr(lo), oracle)
                self.assertLessEqual(oracle, mpr(hi))
                self.assertLessEqual(hi-lo, Fraction(1,10**40))
                data.append({"input": str(q), "lower": str(lo), "upper": str(hi),
                             "oracle": mp.nstr(oracle,70)})
        OBSERVATIONS["log_enclosures"] = data

    def test_02_lambert_enclosures(self):
        values = [Fraction(1,10), Fraction(1,1000), Fraction(1,10**30),
                  Fraction(9,25), Fraction(367879,10**6)]
        data = []
        with mp.workdps(120):
            for q in values:
                certificate = lambert_minus_one(q, 35)
                oracle = mp.lambertw(-mpr(q), -1)
                self.assertLessEqual(mpr(certificate.lower), oracle)
                self.assertLessEqual(oracle, mpr(certificate.upper))
                self.assertLessEqual(certificate.width, Fraction(1,10**35))
                self.assertLess(certificate.h_at_t_lower[1], 0)
                self.assertGreater(certificate.h_at_t_upper[0], 0)
                row = certificate.to_dict()
                row["mpmath_oracle"] = mp.nstr(oracle,70)
                data.append(row)
        OBSERVATIONS["lambert_enclosures"] = data

    def test_03_invalid_inputs_and_budget(self):
        for q in [Fraction(0), Fraction(-1), Fraction(1,2), Fraction(1)]:
            with self.assertRaises(ValueError):
                lambert_minus_one(q)
        with self.assertRaises(TypeError):
            lambert_minus_one(0.1)
        with self.assertRaises(ProofBudgetExceeded):
            lambert_minus_one(Fraction(1,10), 30, max_bisections=1)
        with self.assertRaises(ValueError):
            log_interval(Fraction(-1))

    def test_04_symbolic_bridge_argument_order(self):
        z = -sp.Rational(1,10)
        wrong = sp.LambertW(-1, z)
        correct = sp.LambertW(z, -1)
        self.assertEqual(sp.LambertW(0, sp.E), -sp.oo)
        self.assertEqual(sp.LambertW(sp.E, 0), 1)
        self.assertNotEqual(sp.im(wrong.evalf(40)), 0)
        self.assertEqual(sp.im(correct.evalf(40)), 0)
        y = sp.Symbol("y")
        wrong_derivative = sp.diff(sp.LambertW(-1,y), y)
        right_derivative = sp.diff(sp.LambertW(y,-1), y)
        self.assertTrue(wrong_derivative.has(sp.Derivative))
        self.assertFalse(right_derivative.has(sp.Derivative))
        OBSERVATIONS["sympy_bridge_stage_only"] = {
            "wrong_two_argument_principal": str(sp.LambertW(0,sp.E)),
            "correct_principal": str(sp.LambertW(sp.E,0)),
            "wrong_nonprincipal": str(wrong.evalf(50)),
            "correct_nonprincipal": str(correct.evalf(50)),
            "wrong_derivative": str(wrong_derivative),
            "correct_derivative": str(right_derivative),
            "scope": "Direct SymPy stage; not execution of Mathics, Wolfram, or the package"
        }

    def test_05_logarithmic_inverse_coefficients(self):
        # A formal ring computation: log(y*v)=L+log(v), y>0, v->1.
        y, L = sp.symbols("y L")
        g = y-y**2*L+y**3*(2*L**2+L)-y**4*(5*L**3+sp.Rational(11,2)*L**2+L)
        lg = L+sp.series(sp.log(g/y),y,0,4).removeO()
        residual = sp.series(g+g**2*lg-y,y,0,5).removeO().expand()
        self.assertEqual(residual, 0)
        OBSERVATIONS["formal_log_inverse"] = {"expression": str(g),
                                               "residual_below_y5": str(residual)}

    def test_06_first_match_work_model(self):
        # Deterministic comparison counts for the exposed adapter mechanism.
        counts=[]
        for m in [4,16,64,256]:
            rows=list(range(m)); r=100
            full=sum(1 for _ in range(r) for _ in rows)
            short=r  # each query matches the first already-existing bucket
            self.assertEqual(full, r*m)
            counts.append({"existing_buckets": m, "repeated_queries": r,
                           "all_position_predicate_calls": full,
                           "first_match_predicate_calls": short})
        OBSERVATIONS["operation_count_model_not_runtime_benchmark"] = counts

    def test_07_log_interval_order_and_exact_one(self):
        self.assertEqual(log_interval(Fraction(1),64), (Fraction(0),Fraction(0)))
        for numerator in range(1,15):
            lo,hi=log_interval(Fraction(numerator,7),96)
            self.assertLessEqual(lo,hi)
            if numerator>7:
                self.assertGreater(lo,0)
            elif numerator<7:
                self.assertLess(hi,0)


def main():
    started=time.perf_counter()
    result=unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(ReferenceTests))
    report={"python": platform.python_version(), "sympy": sp.__version__,
            "mpmath": mp.__version__, "tests_run": result.testsRun,
            "failures": len(result.failures), "errors": len(result.errors),
            "elapsed_seconds": round(time.perf_counter()-started,3),
            "package_executed": False, "mathics_executed": False,
            "wolfram_executed": False, "observations": OBSERVATIONS}
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    raise SystemExit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    main()
