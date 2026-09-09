#!/usr/bin/env python3
"""Independent mathematical checks; this does NOT execute Wolfram Language."""
from __future__ import annotations
import cmath
import math
import unittest
from fractions import Fraction as Q


def diagonal_values(a: Q, m: int) -> tuple[Q, Q, Q]:
    """True f(a**m,a), retained x/a, and true absolute error."""
    if a <= 0 or m < 1:
        raise ValueError("Require a > 0 and integer m >= 1")
    x = a**m
    actual, retained = x / (a + x), x / a
    return actual, retained, abs(actual - retained)


def forward_remainder(x: Q, a: Q) -> Q:
    if min(x, a) <= 0:
        raise ValueError("Require positive x and a")
    return x*x / (a*(a+x))


class IndependentMathematics(unittest.TestCase):
    def test_excluded_certificate_root(self):
        lo, hi, root = Q(1,2), Q(3,2), Q(1)
        self.assertTrue(lo < root < hi)
        self.assertEqual(root - 1, 0)
        self.assertFalse(root > 2)
        self.assertLess(hi, 2)

    def test_valid_certificate_control(self):
        lo, hi, root = Q(5,2), Q(7,2), Q(3)
        self.assertTrue(2 < lo < root < hi)
        self.assertEqual(root - 3, 0)

    def test_diagonal_exact_constant_disagreement(self):
        for a in [Q(1,10), Q(1,1000), Q(1,10**12)]:
            actual, retained, error = diagonal_values(a, 1)
            self.assertEqual((actual, retained, error), (Q(1,2), Q(1), Q(1,2)))

    def test_diagonal_general_proportional_paths(self):
        a = Q(1,1000)
        for c in [Q(1,2), Q(1), Q(2), Q(7,3)]:
            x = c*a
            self.assertEqual(x/(a+x), c/(1+c))
            self.assertEqual(x/a-x/(a+x), c*c/(1+c))

    def test_separated_path_error_order(self):
        # Mathematical extension of the observed m=1 witness, not a native result.
        for m in [2,3,5]:
            for a in [Q(1,10), Q(1,100)]:
                _, _, error = diagonal_values(a,m)
                self.assertEqual(error, a**(2*m-2)/(1+a**(m-1)))
                self.assertEqual(error/a**(2*m), 1/(a*a*(1+a**(m-1))))

    def test_explicit_parameter_majorant(self):
        for a in [Q(1,100), Q(1), Q(17)]:
            for x in [Q(1,10000), Q(2,3), Q(19)]:
                error = abs(x/(a+x)-x/a)
                self.assertEqual(error, forward_remainder(x,a))
                self.assertLessEqual(error, x*x/(a*a))

    def test_opaque_function_scaled_error(self):
        # x=exp(-k): g(x)/x**2 = log(1+k), avoiding numerical underflow.
        ks = [4,16,64,256]
        ratios = [math.log1p(k) for k in ks]
        derivatives = [math.exp(-k)*math.log1p(k) for k in ks]
        self.assertTrue(all(b > a for a,b in zip(ratios, ratios[1:])))
        self.assertTrue(all(b < a for a,b in zip(derivatives, derivatives[1:])))
        self.assertLess(derivatives[-1], 1e-100)

    def test_complex_constant_is_not_real(self):
        for a in [1,2,7]:
            z = cmath.sqrt(-a)
            self.assertEqual(z.real, 0)
            self.assertGreater(z.imag, 0)
            self.assertAlmostEqual(z.imag*z.imag, a)

    def test_positive_real_constant_control(self):
        for a in [-1,-2,-7]:
            self.assertEqual(cmath.sqrt(-a).imag, 0)

    def test_even_power_negative_branch_observable(self):
        # A development opportunity, not an observed incorrect current result.
        for x in [-1,-3,-11]:
            self.assertEqual(math.sqrt(x*x), -x)
            self.assertNotEqual(math.sqrt(x*x), x)

if __name__ == '__main__':
    unittest.main(verbosity=2)
