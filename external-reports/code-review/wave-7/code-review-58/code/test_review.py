"""Independent tests: algebraic models and additive prototype, NOT upstream tests."""
from __future__ import annotations
import unittest
from fractions import Fraction as F
from math import factorial
import mpmath as mp
import sympy as sp
from uniform_lerch import bernoulli, moment_polynomial, make_model
from prepare_erfc_patch import patched_text, OLD, NEW


class ExactModelTests(unittest.TestCase):
    def test_bernoulli_against_independent_cas(self):
        for n in range(0, 19, 2):
            with self.subTest(n=n):
                self.assertEqual(sp.Rational(bernoulli(n).numerator, bernoulli(n).denominator), sp.bernoulli(n))
        self.assertEqual(bernoulli(1), F(-1, 2))

    def test_moment_three_term_recurrence(self):
        for lam in (F(1, 3), F(1), F(7, 2)):
            for s in (F(0), F(1, 2), F(2), F(5, 3)):
                p0, p1 = F(1), lam + s
                self.assertEqual(p1, moment_polynomial(1, lam, s))
                for m in range(1, 10):
                    p2 = (lam + s + m) * p1 - lam * m * p0
                    self.assertEqual(p2, moment_polynomial(m + 1, lam, s))
                    p0, p1 = p1, p2

    def test_kernel_geometric_remainder_identity(self):
        # Exact identity underlying the positive partial-fraction proof.
        for k in range(0, 7):
            for u in (F(1, 10), F(1), F(5, 2), F(100)):
                finite = sum((-u)**j for j in range(k))
                error = 1/(1+u) - finite
                self.assertEqual(error, (-u)**k/(1+u))
                self.assertGreaterEqual((-1)**k * error, 0)
                self.assertLessEqual((-1)**k * error, u**k)

    def test_exact_uniform_example_coefficients(self):
        model = make_model(1, 2, 2)
        self.assertEqual(model.correction_rows, ((F(2), F(1, 2)),
            (F(3), F(1, 4)), (F(5), F(-49, 720))))
        self.assertEqual(model.remainder_power, 7)
        self.assertEqual(model.remainder_coefficient, F(1631, 30240))
        self.assertEqual(model.remainder_sign, 1)

    def test_zero_s_reduces_to_bernoulli_kernel(self):
        for lam in (F(1, 3), F(1), F(4)):
            for m in range(0, 10):
                self.assertEqual(moment_polynomial(m, lam, 0), lam**m)

    def test_exact_erfc_coefficient_equations(self):
        L = sp.Symbol("L", real=True)
        A = -L/4
        B = -sp.Rational(1, 4) + L/8 - L**2/32
        self.assertEqual(sp.expand(2*A + L/2), 0)
        self.assertEqual(sp.expand(A**2 + 2*B + A + sp.Rational(1, 2)), 0)
        self.assertEqual(sp.expand(B + ((L-2)**2 + 4)/32), 0)
        # Reflection transforms both kept coefficients and signed omitted block.
        self.assertEqual(sp.expand((-B) + B), 0)
        self.assertNotEqual(sp.expand(B + B), 0)

    def test_patch_guard_and_non_destructive_generation(self):
        original = "before\n" + OLD + "after\n"
        revised = patched_text(original)
        self.assertEqual(revised, "before\n" + NEW + "after\n")
        self.assertEqual(original, "before\n" + OLD + "after\n")
        for invalid in ("no anchor", OLD + OLD, revised):
            with self.assertRaises(ValueError):
                patched_text(invalid)

    def test_input_validation(self):
        for args in ((0, 2, 2), (-1, 2, 2), (1, -1, 2), (1, 2, -1),
                     (1, 2, 65), (1, 2, True), (True, 2, 2), (1.0, 2, 2)):
            with self.subTest(args=args), self.assertRaises((TypeError, ValueError)):
                make_model(*args)
        for a in (0, -1, 1.0):
            with self.assertRaises((TypeError, ValueError)):
                make_model(1, 2, 2).numerical(a)

    def test_numerical_contract_label(self):
        data = make_model(1, 2, 2).numerical(10)
        self.assertIs(data["outward_rounded"], False)
        self.assertIs(data["interval_certificate"], False)


class NumericalEvidenceTests(unittest.TestCase):
    def test_uniform_signed_bounds_96_samples(self):
        # Numerical evidence only; exact proof is in the article.
        with mp.workdps(90):
            for lam in (F(1, 3), F(1), F(3)):
                for s in (F(0), F(1), F(2), F(3, 2)):
                    for a in (10, 50):
                        ll = mp.mpf(lam.numerator)/lam.denominator
                        ss = mp.mpf(s.numerator)/s.denominator
                        z = mp.exp(-ll/a)
                        true = 1/(-mp.expm1(-ll/a)) if s == 0 else mp.lerchphi(z, ss, a)
                        for k in range(4):
                            with self.subTest(lam=lam, s=s, a=a, k=k):
                                model = make_model(lam, s, k)
                                data = model.numerical(a, dps=90)
                                ratio = model.remainder_sign*(true-data["approximation"])/data["analytic_bound_value"]
                                self.assertGreaterEqual(ratio, -mp.mpf("1e-60"))
                                self.assertLessEqual(ratio, 1+mp.mpf("1e-60"))

    def test_erfc_wrong_and_correct_frontier(self):
        with mp.workdps(90):
            for v in (16, 64, 256, 1024):
                vv = mp.mpf(v)
                L = mp.log(vv)
                retained = -mp.sqrt(vv) + L/(4*mp.sqrt(vv))
                stored = (-mp.mpf(1)/4 + L/8 - L**2/32)/vv**mp.mpf("1.5")
                root = mp.findroot(lambda z: mp.log(mp.erfc(z)) + vv + mp.log(mp.pi)/2,
                                   -retained)
                truth = -root
                e0 = abs(truth-retained)
                ewrong = abs(truth-(retained+stored))
                efixed = abs(truth-(retained-stored))
                self.assertLess(stored, 0)
                self.assertGreater(ewrong, e0)
                self.assertLess(efixed, e0)

    def test_fixed_z_first_term_not_uniform_on_transition(self):
        # For lambda=1,s=2, J != 1: fixed-z first term has wrong leading coefficient.
        with mp.workdps(80):
            model = make_model(1, 2, 0)
            j = model.numerical(10, dps=80)["leading_integral"]
            self.assertTrue(0 < j < mp.mpf("0.5"))
            for a in (100, 1000):
                fixed_lead = 1/(mp.mpf(a)**2 * (-mp.expm1(-mp.mpf(1)/a)))
                correct_lead = j/a
                self.assertGreater(fixed_lead/correct_lead, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
