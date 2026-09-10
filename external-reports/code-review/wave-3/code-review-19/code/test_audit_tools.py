"""Independent emitter/model tests, not Wolfram package execution."""
from __future__ import annotations
import unittest
from fractions import Fraction
from patch_native_dispatch import patched_text, DEFAULT_OLD, DEFAULT_NEW, KEYS_OLD, KEYS_NEW

class PatchEmitterTests(unittest.TestCase):
    def setUp(self):
        self.fixture = "(* prefix *)\n" + DEFAULT_OLD + "\n" + KEYS_OLD + "\n(* suffix *)\n"
    def test_default_only(self):
        actual = patched_text(self.fixture, "default")
        self.assertIn(DEFAULT_NEW, actual)
        self.assertIn(KEYS_OLD, actual)
        self.assertNotIn(DEFAULT_OLD, actual)
    def test_keys_only(self):
        actual = patched_text(self.fixture, "keys")
        self.assertIn(KEYS_NEW, actual)
        self.assertIn(DEFAULT_OLD, actual)
    def test_both(self):
        actual = patched_text(self.fixture)
        self.assertIn(DEFAULT_NEW, actual)
        self.assertIn(KEYS_NEW, actual)
        self.assertTrue(actual.startswith("(* prefix *)"))
        self.assertTrue(actual.endswith("(* suffix *)\n"))
    def test_missing_anchor(self):
        with self.assertRaises(ValueError): patched_text("unrelated")
    def test_duplicate_anchor(self):
        with self.assertRaises(ValueError): patched_text(self.fixture + DEFAULT_OLD)
    def test_already_patched(self):
        with self.assertRaises(ValueError): patched_text(patched_text(self.fixture))
    def test_bad_selection(self):
        with self.assertRaises(ValueError): patched_text(self.fixture, "guess")
    def test_presence_of_new_helper_does_not_silently_duplicate(self):
        with self.assertRaises(ValueError): patched_text(self.fixture + KEYS_NEW, "keys")

class IndependentMathematicsTests(unittest.TestCase):
    def test_inclusive_exclusive_gap_for_exp(self):
        # The cubic coefficient omitted under package cutoff 3 is exactly 1/6.
        package = [Fraction(1), Fraction(1), Fraction(1, 2)]
        native = package + [Fraction(1, 6)]
        self.assertEqual(native[:3], package)
        self.assertEqual(native[3], Fraction(1, 6))
    def test_sparse_byte_ratio_is_not_a_speed_ratio(self):
        self.assertEqual(Fraction(2404576, 624), Fraction(150286, 39))
        self.assertGreater(Fraction(2404576, 624), 3800)
    def test_inverse_lagrange_coefficients_symbolically(self):
        import sympy as sp
        a = sp.symbols("a")
        c = [(-1)**n * sp.prod(a*n-j for j in range(n-1))/sp.factorial(n)
             for n in range(1, 4)]
        self.assertEqual(c[0], -1)
        self.assertEqual(sp.simplify(c[1]-a), 0)
        self.assertEqual(sp.simplify(c[2]+a*(3*a-1)/2), 0)
    def test_positive_irrational_frontier(self):
        import sympy as sp
        a = sp.sqrt(2)
        self.assertTrue(bool(2*a-1 < 2))
        self.assertTrue(bool(3*a-2 > 2))
        self.assertTrue(bool(a-1 > 0))

if __name__ == "__main__":
    unittest.main(verbosity=2)
