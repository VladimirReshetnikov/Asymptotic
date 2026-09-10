"""Independent rational-model and patch-fixture tests; no package execution."""
import unittest
from fractions import Fraction as F
import mpmath as mp
from reference_log import *
from emit_candidate import patch_text, REPAIRS

class ArithmeticTests(unittest.TestCase):
    def test_dyadic_rounding_encloses(self):
        for numerator in range(-40,41):
            for denominator in range(1,24):
                q=F(numerator,denominator)
                for bits in (2,5,17,48):
                    lo=round_point(q,bits,False); hi=round_point(q,bits,True)
                    self.assertLessEqual(lo,q); self.assertLessEqual(q,hi)

    def test_rounding_idempotence(self):
        for q in (F(-2,3),F(1,7),F(37,9),pow2(-200)):
            for bits in (2,5,48):
                a=outward((q,q),Context(bits=bits))
                self.assertEqual(outward(a,Context(bits=bits)),a)

    def test_floor_binary_exponent(self):
        for n in range(-250,251):
            for factor in (F(1),F(5,4),F(7,4)):
                self.assertEqual(floor_log2(factor*pow2(n)),n)

    def test_arithmetic_small_grid(self):
        ctx=Context(bits=5)
        for a in ((F(-2),F(3)),(F(1,3),F(3,2)),(F(-4),F(-1))):
            for b in ((F(-1),F(2)),(F(2,7),F(3,5))):
                p=multiply(a,b,ctx); s=add(a,b,ctx)
                for x in a:
                    for y in b:
                        self.assertLessEqual(p[0],x*y); self.assertLessEqual(x*y,p[1])
                        self.assertLessEqual(s[0],x+y); self.assertLessEqual(x+y,s[1])

    def test_invalid_context(self):
        for kwargs in ({'order':1},{'bits':1},{'order':2.0},{'bits':True}):
            with self.assertRaises(ValueError): Context(**kwargs)

class LogarithmTests(unittest.TestCase):
    def test_exact_baseline_model_anchor(self):
        # Exact model endpoints; the displayed native primitive agrees numerically.
        # Its full exact primitive interval was not returned in the native transcript.
        ctx=Context(); q=1-pow2(-200)
        actual=baseline_log_point(q,ctx)
        self.assertEqual(actual,(-F(65156244609,35184372088832),F(65156244609,35184372088832)))

    def test_exact_reciprocal_model_width(self):
        ctx=Context(); delta=pow2(-200)
        self.assertEqual(width(stable_log_point(1-delta,ctx))/delta,pow2(-47))

    def test_exact_affine_model_width(self):
        ctx=Context(); delta=pow2(-200)
        a=affine_log(1,1,(delta,delta),ctx,fused=False)
        b=affine_log(1,1,(delta,delta),ctx,fused=True)
        self.assertEqual(a,(F(0),pow2(-47)))
        self.assertEqual(width(b)/delta,pow2(-48))

    def test_below_one_sign_grid(self):
        for n in (2,3,8,16):
            ctx=Context(order=n,bits=4*(n+10))
            for m in (100,200,500,1000):
                q=1-pow2(-m)
                old=baseline_log_point(q,ctx); new=stable_log_point(q,ctx)
                self.assertLess(old[0],0); self.assertGreater(old[1],0)
                self.assertLess(new[1],0)

    def test_affine_precision_grid(self):
        for m in (100,200,500,1000):
            for slope in (F(1),F(-1),F(3,2),F(-7,3)):
                delta=pow2(-m)
                for sign in (-1,1):
                    point=sign*delta/slope
                    a=affine_log(slope,1,(point,point),Context(),fused=False)
                    b=affine_log(slope,1,(point,point),Context(),fused=True)
                    self.assertLessEqual(a[0],0); self.assertGreaterEqual(a[1],0)
                    self.assertLess(width(b),width(a))
                    self.assertLess(width(b)/delta,pow2(-44))

    def test_reciprocity_exact(self):
        for q in (F(1,1000),F(1,2),F(2,3),1-pow2(-500)):
            self.assertEqual(stable_log_point(q,Context()),negate(stable_log_point(1/q,Context())))

    def test_independent_mpmath_grid(self):
        with mp.workdps(180):
            ctx=Context(order=12,bits=88)
            for numerator in range(1,24):
                for denominator in range(1,18):
                    q=F(numerator,denominator)
                    truth=mp.log(mp.mpf(q.numerator)/q.denominator)
                    for fn in (baseline_log_point,stable_log_point):
                        lo,hi=fn(q,ctx)
                        self.assertLessEqual(mp.mpf(lo.numerator)/lo.denominator,truth)
                        self.assertLessEqual(truth,mp.mpf(hi.numerator)/hi.denominator)

    def test_independent_near_unit_log1p(self):
        with mp.workdps(450):
            for m in (20,50,200,500,1000):
                d=pow2(-m)
                for sign in (-1,1):
                    truth=mp.log1p(sign*mp.power(2,-m))
                    lo,hi=stable_log_point(1+sign*d,Context())
                    self.assertLessEqual(mp.mpf(lo.numerator)/lo.denominator,truth)
                    self.assertLessEqual(truth,mp.mpf(hi.numerator)/hi.denominator)

    def test_exact_one(self):
        for fn in (baseline_log_point,stable_log_point):
            self.assertEqual(fn(F(1),Context()),(F(0),F(0)))

    def test_domain_failures(self):
        for q in (F(0),F(-1),F(-3,2)):
            for fn in (baseline_log_point,stable_log_point):
                with self.assertRaises(ValueError): fn(q,Context())
        with self.assertRaises(ValueError): affine_log(1,0,(F(-1),F(1)),Context(),fused=True)

    def test_affine_monotone_interval(self):
        ctx=Context()
        for a in (F(-3),F(1),F(7,2)):
            interval=F(-1,1000),F(1,1000)
            result=affine_log(a,1,interval,ctx,fused=True)
            for x in interval:
                point=stable_log_point(1+a*x,ctx)
                self.assertLessEqual(result[0],point[0]); self.assertGreaterEqual(result[1],point[1])

    def test_tail_formula(self):
        for n in range(1,31):
            u=F(1,3)
            self.assertEqual(tail_at_two(n),2*u**(2*n+1)/(F(2*n+1)*(1-u*u)))
        self.assertEqual(tail_at_two(2),F(1,540))

    def test_fixed_order_root_radius_model(self):
        # MVT check for a model residual formed from two independent valid
        # logarithm enclosures at the known root. This is not certAttempt.
        ctx=Context()
        for m in (100,200,500,1000):
            d=pow2(-m)
            for root in (1-d,1+d):
                enclosure=stable_log_point(root,ctx)
                residual=add(enclosure,negate(enclosure),ctx)
                epsilon=max(abs(v) for v in residual)
                radius=epsilon*(1+2*d)
                self.assertLess(radius,d/8)

class EmitterTests(unittest.TestCase):
    def fixture(self): return '\n'.join(before for before,_ in REPAIRS)
    def test_both(self):
        result=patch_text(self.fixture())
        for _,after in REPAIRS: self.assertIn(after,result)
    def test_modes(self):
        for mode,index in (('reciprocal',0),('affine',1)):
            self.assertIn(REPAIRS[index][1],patch_text(self.fixture(),mode))
    def test_missing_anchor(self):
        with self.assertRaises(ValueError): patch_text('nothing')
    def test_duplicate_anchor(self):
        with self.assertRaises(ValueError): patch_text(self.fixture()*2)
    def test_repeat_refused(self):
        with self.assertRaises(ValueError): patch_text(patch_text(self.fixture()))
    def test_bad_mode(self):
        with self.assertRaises(ValueError): patch_text(self.fixture(),'typo')

if __name__=='__main__': unittest.main(verbosity=2)
