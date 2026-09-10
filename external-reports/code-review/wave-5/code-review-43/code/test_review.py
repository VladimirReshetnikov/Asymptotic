"""Independent tests. These never load or execute the Asymptotic package."""
import copy
import json
from pathlib import Path
import platform
import unittest
import sympy as sp
from exact_models import inverse_contribution, model_target_limit, perturbative_inverse
from polynomial_certificate import produce_certificate, verify_certificate

x, y, a = sp.symbols("x y a", real=True)

class CoordinateTests(unittest.TestCase):
    def test_left_identity(self):
        local, oriented, off = inverse_contribution(y, leading_coefficient=-1,
            leading_power=1, observable_power=1, source_sign=-1)
        self.assertEqual((local, oriented, off), (-y, y, 0))

    def test_translated_left_identity(self):
        local, oriented, off = inverse_contribution(y, leading_coefficient=-1,
            leading_power=1, observable_power=1, source_sign=-1, source_endpoint=3)
        self.assertEqual(off + oriented, 3 + y)

    def test_negative_infinity_identity(self):
        local, oriented, off = inverse_contribution(y, leading_coefficient=-1,
            leading_power=-1, observable_power=1, source_sign=-1,
            source_infinite=True, target_infinite=True)
        self.assertEqual((local, oriented, off), (-y, y, 0))

    def test_even_negative_branch(self):
        local, oriented, _ = inverse_contribution(y, leading_coefficient=-1,
            leading_power=1, observable_power=2, source_sign=-1)
        self.assertEqual(local, oriented)
        self.assertEqual(oriented, y**2)

    def test_odd_negative_branch(self):
        _, oriented, _ = inverse_contribution(y, leading_coefficient=-1,
            leading_power=1, observable_power=3, source_sign=-1)
        self.assertEqual(oriented, y**3)

    def test_right_control(self):
        local, oriented, _ = inverse_contribution(y, leading_coefficient=2,
            leading_power=1, observable_power=1)
        self.assertEqual(local, oriented)
        self.assertEqual(oriented, y/2)

    def test_negative_branch_fractional_refusal(self):
        with self.assertRaises(ValueError):
            inverse_contribution(y, leading_coefficient=-1, leading_power=1,
                                 observable_power=sp.Rational(1, 2), source_sign=-1)

    def test_finite_limit(self):
        self.assertEqual(model_target_limit(7, -2, 3), 7)

    def test_positive_infinite_limit(self):
        self.assertEqual(model_target_limit(0, 1, -1), sp.oo)

    def test_negative_infinite_limit(self):
        self.assertEqual(model_target_limit(0, -1, -1), -sp.oo)

    def test_unresolved_limit_refusal(self):
        with self.assertRaises(ValueError): model_target_limit(0, a, -1)

class PerturbativeTests(unittest.TestCase):
    def test_invalid_core_model(self):
        raw = perturbative_inverse(x+y, x**2, x, y, 1, validate=False)
        self.assertEqual(sp.expand(raw-(x+y-(x+y)**2)), 0)
        self.assertTrue(raw.has(x))

    def test_invalid_core_is_rejected(self):
        with self.assertRaises(ValueError): perturbative_inverse(x+y, x**2, x, y, 1)

    def test_zero_order_still_validates(self):
        with self.assertRaises(ValueError): perturbative_inverse(x+y, x**2, x, y, 0)

    def test_quadratic_perturbation(self):
        self.assertEqual(perturbative_inverse(y, a*x**2, x, y, 3),
                         y-a*y**2+2*a**2*y**3-5*a**3*y**4)

    def test_nonidentity_core(self):
        actual = perturbative_inverse(sp.sqrt(y), a*x**2, x, y, 3)
        expected = sp.sqrt(y)*(1-a/2+3*a**2/8-5*a**3/16)
        self.assertEqual(sp.simplify(actual-expected), 0)

    def test_target_in_perturbation_rejected(self):
        with self.assertRaises(ValueError): perturbative_inverse(y, x+y, x, y, 1)

    def test_distinct_variables_required(self):
        with self.assertRaises(ValueError): perturbative_inverse(x, x**2, x, x, 1)

class MonotonicityTests(unittest.TestCase):
    def assertCert(self, coefficients, direction, stationary):
        record = produce_certificate(coefficients)
        out = verify_certificate(record)
        self.assertTrue(out["accepted"], out)
        self.assertEqual(out["conclusion"], direction)
        self.assertEqual(out["stationary_real_roots"], stationary)
        self.assertFalse(out["positive_derivative_lower_bound_asserted"])
        return record

    def test_quintic_two_stationary_points(self):
        self.assertCert([0,1,0,"-2/3",0,"1/5"], "StrictlyIncreasing", 2)

    def test_negative_quintic(self):
        self.assertCert([0,-1,0,"2/3",0,"-1/5"], "StrictlyDecreasing", 2)

    def test_cube(self):
        self.assertCert([0,0,0,1], "StrictlyIncreasing", 1)

    def test_linear(self):
        self.assertCert([3,-2], "StrictlyDecreasing", 0)

    def test_positive_derivative_no_real_roots(self):
        self.assertCert([0,1,0,1], "StrictlyIncreasing", 0)

    def test_irrational_stationary_points(self):
        self.assertCert([0,4,0,"-4/3",0,"1/5"], "StrictlyIncreasing", 2)

    def test_mixed_nonreal_and_repeated_real_factors(self):
        # f' = x^2 (x^2+1)^2
        self.assertCert([0,0,0,"1/3",0,"2/5",0,"1/7"], "StrictlyIncreasing", 1)

    def test_nonmonotone_refused(self):
        self.assertEqual(produce_certificate([0,0,1])["status"], "NoCertificate")

    def test_constant_refused(self):
        self.assertEqual(produce_certificate([7])["reason"], "ConstantPolynomial")

    def test_stationary_inverse_scale(self):
        f = x-sp.Rational(2,3)*x**3+sp.Rational(1,5)*x**5
        h = sp.Symbol("h")
        self.assertEqual(sp.expand(f.subs(x,1+h)-sp.Rational(8,15)),
                         sp.Rational(4,3)*h**3+h**4+h**5/5)

    def test_mutated_direction_rejected(self):
        c = produce_certificate([0,1,0,"-2/3",0,"1/5"])
        c["conclusion"] = "StrictlyDecreasing"
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_mutated_factorization_rejected(self):
        c = produce_certificate([0,1,0,"-2/3",0,"1/5"])
        c["factor_coefficient"] = "2"
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_mutated_derivative_rejected(self):
        c = produce_certificate([0,1,0,"-2/3",0,"1/5"])
        c["derivative"][0] = "2"
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_mutated_sturm_chain_rejected(self):
        c = produce_certificate([0,1,0,1])
        c["odd_part_sturm"][-1][0] = "999"
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_mutated_stationary_count_rejected(self):
        c = produce_certificate([0,0,0,1])
        c["stationary_real_roots"] = 0
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_excess_degree_rejected(self):
        c = produce_certificate([0,0,0,1])
        c["factors"][0]["multiplicity"] = 10**9
        self.assertFalse(verify_certificate(c)["accepted"])

    def test_nonreal_domain_rejected(self):
        c = produce_certificate([0,0,0,1])
        c["domain"] = "C"
        self.assertFalse(verify_certificate(c)["accepted"])

if __name__ == "__main__":
    import io
    stream = io.StringIO()
    suite = unittest.defaultTestLoader.loadTestsFromModule(__import__(__name__))
    result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
    print(stream.getvalue())
    root = Path(__file__).resolve().parents[1]
    report = {"scope": "Independent Python models and prototype checker; no Wolfram or Mathics package execution",
              "python": platform.python_version(), "sympy": sp.__version__,
              "tests_run": result.testsRun, "failures": len(result.failures),
              "errors": len(result.errors), "skipped": len(result.skipped),
              "successful": result.wasSuccessful()}
    (root/"evidence"/"independent-tests.json").write_text(json.dumps(report, indent=2)+"\n")
    (root/"evidence"/"independent-tests.txt").write_text(stream.getvalue())
    cert = produce_certificate([0,1,0,"-2/3",0,"1/5"])
    (root/"evidence"/"quintic-monotonicity-certificate.json").write_text(json.dumps(cert, indent=2)+"\n")
    (root/"evidence"/"quintic-certificate-verification.json").write_text(json.dumps(verify_certificate(cert), indent=2)+"\n")
    raise SystemExit(0 if result.wasSuccessful() else 1)
