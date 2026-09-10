from fractions import Fraction
import unittest
import mpmath as mp
import sympy as sp
from reference import (positive_tail_bounds, normalized_coefficient,
                       finite_inverse, reported_scale, require_depth)

class IndependentMathematics(unittest.TestCase):
    def test_constant_perturbation_recurrence(self):
        A, c, delta = sp.symbols('A c delta', positive=True)
        v = sp.Symbol('v', real=True)
        for n in range(1, 8):
            with self.subTest(n=n):
                self.assertEqual(sp.simplify(normalized_coefficient(n,A,c,delta,v)
                                            + delta**n/(c*n*A**n)), 0)

    def test_sector_product_cancels_amplitude(self):
        A, c, delta, y = sp.symbols('A c delta y', positive=True)
        v = sp.Symbol('v', real=True)
        for n in range(1, 8):
            with self.subTest(n=n):
                term = normalized_coefficient(n,A,c,delta,v)*(A/y)**n
                self.assertEqual(sp.simplify(term + delta**n/(c*n*y**n)), 0)

    def test_nonconstant_recurrence_residual_through_three(self):
        # A=c=1; y=exp(v0). Compare the equation directly, not a second inverse algorithm.
        v, v0, eps = sp.symbols('v v0 eps', real=True)
        coeffs = [normalized_coefficient(n,sp.Integer(1),sp.Integer(1),v+1,v)
                  .subs(v,v0)*sp.exp(-n*v0) for n in range(1,4)]
        displacement = sum(coeffs[n-1]*eps**n for n in range(1,4))
        residual = sp.exp(v0)*sum(displacement**k/sp.factorial(k) for k in range(1,4)) \
                   + eps*(v0+1+displacement)
        residual = sp.Poly(sp.expand(residual), eps)
        for n in range(1,4):
            with self.subTest(n=n):
                self.assertEqual(sp.simplify(residual.coeff_monomial(eps**n)),0)

    def test_finite_inverse_coefficients_against_log_series(self):
        t = sp.Symbol('t', positive=True)
        for n in range(0,7):
            with self.subTest(n=n):
                exact_correction = sp.series(sp.log(1-t), t, 0, n+1).removeO()
                approx_correction = finite_inverse(1/t,1,1,1,n) - sp.log(1/t)
                self.assertEqual(sp.simplify(exact_correction-approx_correction),0)

    def test_exact_rational_tail_enclosures(self):
        with mp.workdps(90):
            for y in (Fraction(3,2), Fraction(3), Fraction(10), Fraction(100)):
                for n in range(0,6):
                    with self.subTest(y=y,n=n):
                        lo,hi=positive_tail_bounds(y,Fraction(1),Fraction(1),n)
                        t=mp.mpf(y.denominator)/y.numerator
                        err=-mp.log1p(-t)-sum(t**k/k for k in range(1,n+1))
                        self.assertLess(mp.mpf(lo.numerator)/lo.denominator,err)
                        self.assertLess(err,mp.mpf(hi.numerator)/hi.denominator)

    def test_scaled_equation_tail_enclosures(self):
        with mp.workdps(90):
            for c in (Fraction(1,2),Fraction(3)):
                for delta in (Fraction(1,3),Fraction(2)):
                    for n in (0,1,4):
                        with self.subTest(c=c,delta=delta,n=n):
                            y=Fraction(7)
                            lo,hi=positive_tail_bounds(y,delta,c,n)
                            t=mp.mpf(delta.numerator)/delta.denominator/7
                            cc=mp.mpf(c.numerator)/c.denominator
                            err=(-mp.log1p(-t)-sum(t**k/k for k in range(1,n+1)))/cc
                            self.assertLess(mp.mpf(lo.numerator)/lo.denominator,err)
                            self.assertLess(err,mp.mpf(hi.numerator)/hi.denominator)

    def test_moving_shift_reported_scale(self):
        y=sp.Symbol('y',positive=True)
        for n in range(0,5):
            with self.subTest(n=n):
                self.assertEqual(sp.simplify(reported_scale(y,1,1,-y,n)
                                            - sp.exp(-(n+1)*y)/y**(n+1)),0)

    def test_fixed_shift_only_changes_constant(self):
        y=sp.Symbol('y',positive=True)
        for shift in (-3,0,2):
            for n in (0,1,4):
                with self.subTest(shift=shift,n=n):
                    ratio=reported_scale(y,1,1,sp.Integer(shift),n)/reported_scale(y,1,1,0,n)
                    self.assertEqual(sp.simplify(ratio),sp.exp((n+1)*shift))
                    self.assertFalse(sp.simplify(ratio).has(y))

    def test_counterexample_ratio_grows(self):
        with mp.workdps(90):
            for n in (0,1,3):
                ratios=[]
                for y in (5,10,20,50):
                    t=mp.mpf(1)/y
                    err=-mp.log1p(-t)-sum(t**k/k for k in range(1,n+1))
                    scale=mp.exp(-(n+1)*y)/mp.mpf(y)**(n+1)
                    ratios.append(err/scale)
                self.assertTrue(all(a<b for a,b in zip(ratios,ratios[1:])))
                self.assertGreater(ratios[-1],mp.mpf('1e20'))

    def test_tail_coefficient_limit_squeeze(self):
        # Rational bounds on y^(N+1)*error squeeze to 1/(N+1).
        for n in range(0,8):
            y=Fraction(10**8)
            lo,hi=positive_tail_bounds(y,Fraction(1),Fraction(1),n)
            self.assertEqual(lo*y**(n+1),Fraction(1,n+1))
            self.assertLess(hi*y**(n+1)-lo*y**(n+1),Fraction(1,10**7))

    def test_invalid_depths(self):
        for n in (-1,True,1.5,'1'):
            with self.subTest(n=n),self.assertRaises(ValueError):
                require_depth(n)

    def test_invalid_tail_domains(self):
        for y,delta,c in ((1,1,1),(0,1,1),(2,0,1),(2,1,0),(2,1,-1)):
            with self.subTest(data=(y,delta,c)),self.assertRaises(ValueError):
                positive_tail_bounds(Fraction(y),Fraction(delta),Fraction(c),1)

if __name__ == '__main__': unittest.main(verbosity=2)
