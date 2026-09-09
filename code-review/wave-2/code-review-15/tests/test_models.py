from pathlib import Path
import random
import sys
import unittest
from fractions import Fraction as Q
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'code'))
from audit_models import *

class GeometryTests(unittest.TestCase):
    def test_monomial_orientations(self):
        self.assertEqual(monomial_approach(Q(-1), Q(1)), ('Infinity', 'FromBelow'))
        self.assertEqual(monomial_approach(Q(-1), Q(-1)), ('-Infinity', 'FromAbove'))
        self.assertEqual(monomial_approach(Q(2), Q(1), Q(7)), ('7', 'FromAbove'))
        self.assertEqual(monomial_approach(Q(2), Q(-1), Q(7)), ('7', 'FromBelow'))
    def test_flat_baseline_wrong_only_on_poles_in_this_family(self):
        for q in (Q(-3), Q(-1,2), Q(1,2), Q(2)):
            for a in (Q(-3), Q(2)):
                with self.subTest(q=q, a=a):
                    self.assertEqual(baseline_flat_approach(q,a) == monomial_approach(q,a), q>0)
    def test_erfc_both_source_ends_and_both_target_scales(self):
        for side in (-1,1):
            for scale in (Q(-2), Q(3)):
                with self.subTest(side=side,scale=scale):
                    self.assertEqual(erfc_approach(side,scale)==baseline_erfc_approach(side,scale),side==1)
    def test_quadratic_orientation_uses_both_factors(self):
        self.assertEqual(quadratic_approach(Q(-1),Q(1)), ('0','FromBelow'))
        self.assertEqual(quadratic_approach(Q(-1),Q(-1)), ('0','FromAbove'))
    def test_invalid_geometry(self):
        with self.assertRaises(ValueError): monomial_approach(Q(0),Q(1))
        with self.assertRaises(ValueError): erfc_approach(0,Q(1))

class CertificateTests(unittest.TestCase):
    def test_outward_rounding(self):
        rng=random.Random(921387)
        for _ in range(500):
            x=Q(rng.randint(-10**9,10**9),rng.randint(1,10**8))
            bits=rng.randint(2,100)
            self.assertLessEqual(rounded(x,bits,False),x)
            self.assertGreaterEqual(rounded(x,bits,True),x)
    def test_rounding_idempotent(self):
        for x in (Q(-7,13),Q(2,3),Q(0),Q(2)**-91,Q(2)**95):
            for upper in (False,True):
                y=rounded(x,48,upper)
                self.assertEqual(y,rounded(y,48,upper))
    def test_interval_product_contains_samples(self):
        a=(Q(-3,2),Q(4,3));b=(Q(-2,7),Q(9,2));c=mul(a,b,17)
        for x in (a[0],sum(a)/2,a[1]):
            for y in (b[0],sum(b)/2,b[1]):
                self.assertLessEqual(c[0],x*y);self.assertLessEqual(x*y,c[1])
    def test_certificate_stagnation(self):
        r=run_certificate_policy()
        self.assertFalse(r['reached'])
        self.assertEqual(len(r['history']),65)
        self.assertEqual({h['order'] for h in r['history']},{2})
        self.assertGreater(r['history'][-1]['radius'],1e-18)
    def test_escalated_certificate_policy(self):
        r=run_certificate_policy(adaptive=True)
        self.assertTrue(r['reached'])
        self.assertLessEqual(r['history'][-1]['radius'],1e-60)
    def test_relative_only_planner_omission(self):
        # Direct transcription of the inspected Automatic-order expression:
        def automatic_order(wp, tolerance):
            digits=0 if tolerance is None else max(0,len(str(tolerance.denominator))-len(str(tolerance.numerator)))
            return max(wp+10,digits+15)
        self.assertEqual(automatic_order(50,None),60) # RelativeError is not an argument.
        self.assertGreater(automatic_order(50,Q(1,10**150)),150)

class FlatGradingTests(unittest.TestCase):
    def test_first_three_coefficients(self):
        self.assertEqual(flat_inverse_coefficient(1),{0:Q(-1)})
        self.assertEqual(flat_inverse_coefficient(2),{-2:Q(1)})
        self.assertEqual(flat_inverse_coefficient(3),{-3:Q(1),-4:Q(-3,2)})
    def test_general_leading_coefficient(self):
        from math import factorial
        for k in range(1,10):
            c=flat_inverse_coefficient(k)
            self.assertEqual(min(c),-2*(k-1))
            self.assertEqual(c[min(c)],Q((-1)**k*k**(k-1),factorial(k)))
    def test_square_first_omitted_coefficient(self):
        c2=poly_add(poly_mul({1:Q(1)},flat_inverse_coefficient(2)),
                    poly_mul(flat_inverse_coefficient(2),{1:Q(1)}))
        c2=poly_add(c2,poly_mul(flat_inverse_coefficient(1),flat_inverse_coefficient(1)))
        self.assertEqual(c2,{-1:Q(2),0:Q(1)})
    def test_depth_one_old_and_new_tail(self):
        r=flat_square_tail(1)
        self.assertEqual(r['baseline_power'],'-4')
        self.assertEqual(r['graded_power'],'-1')
        self.assertEqual(r['graded_sector'],2)
    def test_all_depths_tail_formula(self):
        for n in range(1,11):
            r=flat_square_tail(n)
            self.assertEqual(Q(r['baseline_power']),-4*n)
            self.assertEqual(Q(r['graded_power']),1-2*n)
    def test_sector_precedes_any_fixed_algebraic_power(self):
        self.assertEqual(dominant([Envelope(2,Q(100)),Envelope(3,Q(-10**6))]),Envelope(2,Q(100)))
    def test_log_order_at_equal_sector_and_power(self):
        self.assertEqual(dominant([Envelope(2,Q(3),1),Envelope(2,Q(3),7)]),Envelope(2,Q(3),7))
    def test_exact_zero_has_no_envelope(self):
        self.assertIsNone(dominant([]))
    def test_negative_even_observable_positive(self):
        # The rejected semantic identity does not require reassociating complex powers.
        for x in (-1,-2,-9):
            self.assertEqual((x*x)**0.5,-x)

if __name__=='__main__': unittest.main(verbosity=2)
