"""Independent semantic and mathematical oracles, not package execution."""
from __future__ import annotations
from fractions import Fraction as Q
import fnmatch
import json
from pathlib import Path
import sys
import unittest
import mpmath as mp
import sympy as sp
from lambert_certificate import enclose_lambert_minus_one, log_interval
from productlog_bridge import ProductLogOrderMixin

ROOT = Path(__file__).resolve().parents[1]
OBS = {"evidence_kind": "Independent SymPy/mpmath/rational arithmetic; not Mathics or Wolfram execution",
       "python": sys.version.split()[0], "sympy": sp.__version__, "mpmath": mp.__version__}


class TupleBase:
    def from_sympy(self, elements):
        return tuple(elements)


class Bridge(ProductLogOrderMixin, TupleBase):
    pass


class IndependentTests(unittest.TestCase):
    def test_exact_order_loss_witnesses(self):
        wrong = sp.LambertW(-1, -sp.Rational(1, 100)).evalf(40)
        correct = sp.LambertW(-sp.Rational(1, 100), -1).evalf(40)
        self.assertEqual(sp.LambertW(0, sp.E), -sp.oo)
        self.assertTrue(correct.is_real)
        self.assertFalse(wrong.is_real)
        OBS["lambert_order_witness"] = {"wrong_exact_principal": str(sp.LambertW(0, sp.E)),
           "wrong_argument_order_value": str(wrong), "correct_value": str(correct),
           "small_inverse_correct": str((-sp.Rational(1,100)/correct).evalf(30)),
           "small_inverse_wrong": str((-sp.Rational(1,100)/wrong).evalf(30))}

    def test_candidate_bridge_exact_and_round_trip(self):
        bridge = Bridge()
        z, k = sp.symbols("z k")
        self.assertEqual(bridge.prepare_sympy((k, z)), (z, k))
        self.assertEqual(bridge.from_sympy((z, k)), (k, z))
        self.assertEqual(bridge.from_sympy((z,)), (z,))
        self.assertEqual(sp.LambertW(*bridge.prepare_sympy((0, sp.E))), 1)
        self.assertTrue(sp.LambertW(*bridge.prepare_sympy((-1, -sp.Rational(1,100)))).is_real)

    def test_candidate_bridge_numerical_orders(self):
        bridge = Bridge()
        with mp.workdps(70):
            for k in (0, -1, 1, 2):
                z = mp.mpf("0.2") if k >= 0 else mp.mpf("-0.01")
                fn = bridge.get_mpmath_function((k, z))
                w = fn(k, z)
                self.assertLess(abs(w * mp.exp(w) - z), mp.mpf("1e-60"))
                self.assertEqual(w, mp.lambertw(z, k))
        self.assertIsNone(bridge.get_mpmath_function(()))
        self.assertIsNone(bridge.get_mpmath_function((1, 2, 3)))

    def test_exact_log_enclosures(self):
        with mp.workdps(100):
            for value in (Q(1), Q(2), Q(1,10), Q(12345,17), Q(1, 10**8)):
                lo, hi = log_interval(value, 24)
                oracle = mp.log(mp.mpf(value.numerator) / value.denominator)
                self.assertLessEqual(mp.mpf(lo.numerator) / lo.denominator, oracle)
                self.assertGreaterEqual(mp.mpf(hi.numerator) / hi.denominator, oracle)

    def test_certified_nonprincipal_branch(self):
        rows = []
        with mp.workdps(100):
            for t in (Q(1,3), Q(1,10), Q(1,100), Q(1,100000)):
                c = enclose_lambert_minus_one(t, bits=40)
                self.assertTrue(c.verify())
                lo, hi = c.w_interval
                expected = mp.lambertw(-mp.mpf(t.numerator) / t.denominator, -1)
                self.assertLess(mp.mpf(lo.numerator) / lo.denominator, expected)
                self.assertGreater(mp.mpf(hi.numerator) / hi.denominator, expected)
                xlo, xhi = c.small_entropy_inverse_interval
                rows.append({"t": str(t), "w_lower": str(lo), "w_upper": str(hi),
                             "x_lower": str(xlo), "x_upper": str(xhi),
                             "requested_bits": c.requested_bits, "log_terms": c.log_terms,
                             "exact_verifier": c.verify(), "oracle": mp.nstr(expected, 50)})
        OBS["rational_certificates"] = rows

    def test_certificate_input_rejections(self):
        for t in (Q(0), Q(-1), Q(1), 0.01):
            with self.subTest(t=t):
                with self.assertRaises(ValueError):
                    enclose_lambert_minus_one(t, bits=20)
        with self.assertRaises(ValueError):
            enclose_lambert_minus_one(Q(1,100), bits=0)

    def test_limit_direction_counterexample(self):
        x = sp.symbols("x", real=True)
        e = sp.Abs(x)/x
        left = sp.limit(e, x, 0, dir="-")
        right = sp.limit(e, x, 0, dir="+")
        self.assertEqual((left, right), (-1, 1))
        OBS["limit_direction"] = {"left": str(left), "right": str(right), "two_sided_exists": False}

    def test_sparse_degree_cost(self):
        x = sp.symbols("x")
        rows = []
        for degree in (100, 10000, 100000):
            sparse = sp.Poly(1+x**degree, x).terms()
            self.assertEqual(len(sparse), 2)
            rows.append({"degree": degree, "dense_slots_required_by_CoefficientList": degree+1,
                         "nonzero_support": 2})
        OBS["sparse_degree_counts_not_kernel_benchmarks"] = rows

    def test_workflow_path_dependency_gap(self):
        patterns = ["src/Kernel/**", "AsymptoticAnalysis.wl", "validation/*mathics*",
                    "validation/MathicsTests.wl", ".github/workflows/mathics.yml"]
        # The relevant patterns here contain no negations or exotic syntax;
        # the witness is the plain ASCII case-sensitive substring mismatch.
        witnesses = {name: any(fnmatch.fnmatchcase(name, p) for p in patterns)
            for name in ("validation/CheckMathicsDefinitions.wl", "validation/build_standalone.py",
                         "validation/run_mathics_tests.py", "validation/MathicsTests.wl")}
        self.assertFalse(witnesses["validation/CheckMathicsDefinitions.wl"])
        self.assertFalse(witnesses["validation/build_standalone.py"])
        self.assertTrue(witnesses["validation/run_mathics_tests.py"])
        self.assertTrue(witnesses["validation/MathicsTests.wl"])
        OBS["workflow_path_matches"] = witnesses


if __name__ == "__main__":
    program = unittest.main(exit=False, verbosity=2)
    (ROOT / "evidence" / "independent-observations.json").write_text(json.dumps(OBS, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(not program.result.wasSuccessful())
