from __future__ import annotations
import math
import unittest
from fractions import Fraction as F
import mpmath as mp
from review_math import (moment_table, stirling_moments, lerch_coefficients,
                         lerch_bound_constant, logarithm_tail_bounds,
                         translation_correction_coefficients)
from prepare_shift_patch import ANCHOR, INSERT, changed, make_diff

mp.mp.dps = 100

def M(q):
    q = F(q)
    return mp.mpf(q.numerator)/q.denominator

def log_tail(y, n):
    y=mp.mpf(y)
    return -mp.log1p(-1/y)-mp.fsum(1/(k*y**k) for k in range(1,n+1))

class SourceShiftModels(unittest.TestCase):
    def test_rational_tail_bounds_ordering(self):
        for y in (F(3,2),F(2),F(10),F(100)):
            for n in (0,1,3,8):
                low, high=logarithm_tail_bounds(y,n)
                self.assertGreater(low,0); self.assertGreater(high,low)
    def test_tail_inside_proved_bounds(self):
        for y in (2,5,10,100):
            for n in (0,1,3,8):
                low,high=logarithm_tail_bounds(y,n)
                e=log_tail(y,n)
                self.assertGreaterEqual(e,M(low)); self.assertLessEqual(e,M(high))
    def test_bad_shift_ratio_lower_bound(self):
        for y in (5,10,20):
            for n in (0,1,3):
                ratio=log_tail(y,n)*(mp.mpf(y)*mp.exp(y))**(n+1)
                self.assertGreater(ratio,mp.exp((n+1)*y)/(n+1))
    def test_bad_shift_has_admitted_eventual_domain(self):
        for y in (4,10,100):
            v=mp.log(y)+y
            self.assertGreater(v,1)
            self.assertGreater(mp.mpf(y)*mp.exp(y),1)
    def test_fixed_shift_normalized_error_stays_bounded(self):
        for shift in (-3,0,2):
            for n in (0,1,3):
                limit=mp.exp(-(n+1)*shift)/(n+1)
                ratio=log_tail(10000,n)*(mp.mpf(10000)*mp.exp(-shift))**(n+1)
                self.assertGreater(ratio,limit)
                self.assertLess(ratio,limit/(1-mp.mpf(1)/10000))
    def test_coefficient_recurrence_matches_closed_form(self):
        for a in (F(1,3),F(1),F(5,2)):
            closed=translation_correction_coefficients(a,10)
            for n in range(1,11):
                q=1/a
                for j in range(1,n): q=-j*q/a
                self.assertEqual((-1)**n*q/math.factorial(n),closed[n-1])
    def test_displayed_corrections_cancel_chart_amplitude(self):
        for a in (F(1,7),F(1),F(13)):
            for y in (F(5),F(100)):
                for n,c in enumerate(translation_correction_coefficients(a,8),1):
                    self.assertEqual(c*(a/y)**n,-F(1,n)/y**n)
    def test_target_translation_is_exact(self):
        for c in (-2,1,3):
            for y in (10,50):
                self.assertTrue(mp.almosteq(mp.exp(mp.log(y-c))+c,y))
    def test_tail_argument_validation(self):
        for y,n in ((1,0),(0,0),(2,-1),(2,257)):
            with self.assertRaises(ValueError): logarithm_tail_bounds(y,n)

class RationalMoments(unittest.TestCase):
    def test_known_half_values(self):
        self.assertEqual(moment_table(F(1,2),5),list(map(F,[2,2,6,26,150,1082])))
    def test_zero_moments(self):
        self.assertEqual(moment_table(0,8),[F(1)]+[F(0)]*8)
    def test_stirling_independent_oracle(self):
        for z in (F(0),F(1,2),F(-1,2),F(1,10),F(-1,5),F(9,10)):
            self.assertEqual(moment_table(z,24),stirling_moments(z,24))
    def test_first_moment_rational_identity(self):
        for z in (F(1,2),F(-1,2),F(2,3)):
            self.assertEqual(moment_table(z,1)[1],z/(1-z)**2)
    def test_second_moment_rational_identity(self):
        for z in (F(1,2),F(-1,2),F(2,3)):
            self.assertEqual(moment_table(z,2)[2],z*(1+z)/(1-z)**3)
    def test_positive_weights_positive_moments(self):
        self.assertTrue(all(x>0 for x in moment_table(F(2,3),50)))
    def test_absolute_moment_dominates_signed(self):
        for signed,absolute in zip(moment_table(F(-1,2),30),moment_table(F(1,2),30)):
            self.assertLessEqual(abs(signed),absolute)
    def test_negative_integer_s_terminates(self):
        self.assertEqual(lerch_coefficients(F(1,2),-2,6),list(map(F,[2,4,6,0,0,0,0])))
    def test_s_zero_terminates(self):
        self.assertEqual(lerch_coefficients(F(-1,2),0,8),[F(2,3)]+[F(0)]*8)
    def test_coefficient_factor_matches_direct_pochhammer(self):
        for z in (F(1,2),F(-1,2)):
            for s in (F(3,2),F(-3,2),F(2)):
                moments=stirling_moments(z,10)
                coeffs=lerch_coefficients(z,s,10)
                for k in range(11):
                    rising=math.prod((s+j for j in range(k)),start=F(1))
                    self.assertEqual(coeffs[k],(-1)**k*rising*moments[k]/math.factorial(k))
    def test_finite_lerch_expansion_at_negative_s(self):
        z=F(1,2); a=F(10); s=F(-2)
        coeffs=lerch_coefficients(z,s,2)
        total=sum((c*a**int(-s-k) for k,c in enumerate(coeffs)),F(0))
        self.assertEqual(total,a*a/(1-z)+2*a*z/(1-z)**2+z*(1+z)/(1-z)**3)
    def test_nonterminating_lerch_bound_numerically(self):
        for z,s,n,a in ((F(1,2),F(3,2),3,10),(F(-1,2),F(3,2),3,10),
                        (F(1,3),F(-3,2),2,5),(F(-1,3),F(-7,2),1,10)):
            coeffs=lerch_coefficients(z,s,n-1)
            approximation=mp.fsum(M(c)*mp.power(a,-M(s)-k) for k,c in enumerate(coeffs))
            error=abs(mp.lerchphi(M(z),M(s),a)-approximation)
            bound=M(lerch_bound_constant(z,s,n))*mp.power(a,-M(s)-n)
            self.assertLessEqual(error,bound)
    def test_bound_zero_after_termination(self):
        self.assertEqual(lerch_bound_constant(F(1,2),-2,3),0)
    def test_n_zero_bound_includes_zero_geometric_index(self):
        self.assertEqual(lerch_bound_constant(0,F(-3,2),0),1)
    def test_exact_rational_domain_refusals(self):
        for z in (1,-1,2):
            with self.assertRaises(ValueError): moment_table(z,3)
        for z in (0.5,True,'1/2'):
            with self.assertRaises(TypeError): moment_table(z,3)
    def test_degree_refusals(self):
        for n in (-1,257):
            with self.assertRaises(ValueError): moment_table(F(1,2),n)
        with self.assertRaises(TypeError): moment_table(F(1,2),2.5)
    def test_budget_checks_bound_degree(self):
        with self.assertRaises(ValueError): lerch_bound_constant(F(1,2),-300,0)

class CandidatePatchFixtures(unittest.TestCase):
    def fixture(self):
        return 'exponentialCoreConstruct[core_] := Module[{},\n'+ANCHOR+'  Null];\n'
    def test_insertion_once(self):
        out=changed(self.fixture())
        self.assertEqual(out.count('"TargetDependentSourceShift"'),1)
        self.assertIn(INSERT+ANCHOR,out)
    def test_preserves_existing_source(self):
        self.assertEqual(changed(self.fixture()).replace(INSERT,''),self.fixture())
    def test_rejects_missing_anchor(self):
        with self.assertRaises(ValueError): changed('exponentialCoreConstruct[] := Null;')
    def test_rejects_ambiguous_anchor(self):
        with self.assertRaises(ValueError): changed(self.fixture()+ANCHOR)
    def test_rejects_already_changed(self):
        with self.assertRaises(ValueError): changed(changed(self.fixture()))
    def test_diff_is_nonmutating_text_operation(self):
        before=self.fixture(); diff=make_diff(before)
        self.assertIn('--- a/src/Kernel/ExponentialCorePerturbation.wl',diff)
        self.assertIn('+  If[! FreeQ[shift, y],',diff)
        self.assertNotIn('TargetDependentSourceShift',before)

if __name__ == '__main__':
    unittest.main(verbosity=2)
