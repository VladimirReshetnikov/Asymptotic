#!/usr/bin/env python3
"""Run independent tests and write their actual results; no package is loaded."""
from __future__ import annotations
import io, json, math, random, sys, unittest
from pathlib import Path
from fractions import Fraction as Q
from audit_models import *

class IndependentTests(unittest.TestCase):
    def test_derivative_recurrence(self):
        self.assertEqual(derivative_coefficients(3, 1, 0, 1), (2,3,1))
        self.assertEqual(derivative_coefficients(3, 1, 0, 2), (1,5,5))
        self.assertEqual(derivative_coefficients(3, 1, 0, 3), (0,0,10))
        for k in range(12):
            p,a,b = derivative_coefficients(3,1,0,k)
            self.assertEqual(p,3-k)
            self.assertGreater(a*a+b*b,0)
    def test_monotone_inverse_family_bounds(self):
        # sqrt(10)<4 gives |H'-1|<4/16 and |H/y-1|<=1/16 on 0<y<1/4.
        self.assertLess(10,4**2)
        self.assertGreater(Q(1)-Q(4,16),0)
        self.assertEqual(Q(1)-Q(1,16),Q(15,16))
    def test_simple_zeros(self):
        theta=math.atan(Q(1,3))
        for n in range(1,9):
            y=math.exp(-theta-n*math.pi)
            A=3*math.sin(math.log(y))+math.cos(math.log(y))
            self.assertLess(abs(A),2e-14)
            slope=5*y*(math.sin(math.log(y))+math.cos(math.log(y)))
            self.assertAlmostEqual(abs(slope)/y,math.sqrt(10),places=12)
    def test_cusp_one_sided_difference_quotients(self):
        for n in range(1,7):
            y=math.exp(-math.atan(1/3)-n*math.pi)
            eps=1e-5*y
            f=lambda v: abs(v*v*(3*math.sin(math.log(v))+math.cos(math.log(v))))
            right=(f(y+eps)-f(y))/eps/y
            left=(f(y-eps)-f(y))/(-eps)/y
            self.assertAlmostEqual(right,math.sqrt(10),places=3)
            self.assertAlmostEqual(left,-math.sqrt(10),places=3)
    def test_affine_pair(self):
        count=Counts()
        self.assertEqual(affine_pair(add(rat(7),mul(rat(-3),X)),count),(Q(-3),Q(7)))
    def test_affine_cancellation(self):
        e=mul(add(X,mul(rat(-1),X)),add(rat(1),X))
        self.assertEqual(affine_pair(e,Counts()),(Q(0),Q(0)))
    def test_nonlinearity_rejected(self):
        self.assertIsNone(affine_pair(mul(X,X),Counts()))
        self.assertIsNone(affine_pair(square(X),Counts()))
    def test_horner_probe_counts(self):
        for d in [0,1,2,4,8,16,32,64,128]:
            e=horner(d); old=Counts(); new=Counts()
            a=enclose_reprobing(e,(Q(0),Q(1,2)),old)
            b=enclose_annotated(annotate(e,new),(Q(0),Q(1,2)),new)
            self.assertEqual(a,b)
            self.assertEqual(old.probes,4*(d+1)**2-1)
            self.assertEqual(new.annotations,4*d+5)
    def test_random_interval_equivalence_and_sampled_soundness(self):
        rng=random.Random(6512026)
        def tree(depth):
            if depth==0: return rng.choice([X,rat(Q(rng.randint(-5,5),rng.randint(1,7)))])
            k=rng.randrange(3)
            if k==0: return add(tree(depth-1),tree(depth-1))
            if k==1: return mul(tree(depth-1),tree(depth-1))
            return square(tree(depth-1))
        for _ in range(300):
            e=tree(3); lo=Q(rng.randint(-7,0),7); hi=Q(rng.randint(1,9),7)
            old=enclose_reprobing(e,(lo,hi),Counts())
            new=enclose_annotated(annotate(e,Counts()),(lo,hi),Counts())
            self.assertEqual(old,new)
            for i in range(7):
                value=evaluate(e,lo+(hi-lo)*Q(i,6))
                self.assertLessEqual(new[0],value)
                self.assertLessEqual(value,new[1])
    def test_large_affine_coefficients_preserved(self):
        for k in [10,100,1000]:
            A=Q(2**k+3,7); e=add(mul(rat(-2),X),rat(2*A+1))
            interval=(A-Q(1,9),A+Q(2,9))
            expected=(Q(5,9),Q(11,9))
            self.assertEqual(enclose_reprobing(e,interval,Counts()),expected)
            self.assertEqual(enclose_annotated(annotate(e,Counts()),interval,Counts()),expected)
    def test_prefix_random_equivalence(self):
        rng=random.Random(2210)
        for _ in range(500):
            n=rng.randrange(101); m=rng.randrange(n+1)
            before=[(Q(i,3),(rng.randrange(-9,10),rng.randrange(-9,10))) for i in range(n)]
            after=before[:m]
            self.assertEqual(old_removed(before,after,MembershipCounts()),
                             prefix_removed(before,after,MembershipCounts()))
    def test_prefix_general_fallback(self):
        before=[(i,i*i) for i in range(10)]
        for after in [before[::2],list(reversed(before[:5])),[],before]:
            self.assertEqual(old_removed(before,after,MembershipCounts()),
                             prefix_removed(before,after,MembershipCounts()))
    def test_prefix_invalid_subset(self):
        for fn in [old_removed,prefix_removed]:
            with self.assertRaises(ValueError): fn([1,2],[1,3],MembershipCounts())
    def test_membership_counts(self):
        for n in [8,16,32,64,128,256,512]:
            for m in [0,n//2,n]:
                before=list(range(n)); after=before[:m]
                old=MembershipCounts(); new=MembershipCounts()
                self.assertEqual(old_removed(before,after,old),prefix_removed(before,after,new))
                self.assertEqual(old.comparisons,n*m-m*(m-1)//2)
                self.assertEqual(new.comparisons,m)

def main() -> int:
    out=Path(__file__).resolve().parents[1]/'evidence'; out.mkdir(exist_ok=True)
    stream=io.StringIO()
    result=unittest.TextTestRunner(stream=stream,verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(IndependentTests))
    transcript=stream.getvalue(); print(transcript,end='')
    data={'scope':'Independent mathematical and structural models; no Wolfram/Mathics package execution',
          'tests_run':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),
          'successful':result.wasSuccessful(),'random_interval_trees':300,
          'exact_rational_sample_points':2100,'random_prefix_cases':500,
          'affine_counts':[],'membership_counts':[],'cusp_samples':[]}
    for d in [1,2,4,8,16,32,64,128]:
        c=Counts(); nc=Counts(); e=horner(d)
        enclose_reprobing(e,(Q(0),Q(1,2)),c); annotate(e,nc)
        data['affine_counts'].append({'depth':d,'repeated_probe_calls':c.probes,
                                      'single_annotation_nodes':nc.annotations})
    for n in [16,32,64,128,256,512]:
        for m in [n//2,n]:
            c=MembershipCounts(); nc=MembershipCounts()
            old_removed(list(range(n)),list(range(m)),c)
            prefix_removed(list(range(n)),list(range(m)),nc)
            data['membership_counts'].append({'input_blocks':n,'kept_blocks':m,
              'linear_membership_model_comparisons':c.comparisons,'prefix_row_comparisons':nc.comparisons})
    for n in range(1,6):
        y=math.exp(-math.atan(1/3)-n*math.pi); h=y*1e-5
        f=lambda v: abs(v*v*(3*math.sin(math.log(v))+math.cos(math.log(v))))
        data['cusp_samples'].append({'n':n,'y':y,
          'left_quotient_divided_by_y':(f(y-h)-f(y))/(-h*y),
          'right_quotient_divided_by_y':(f(y+h)-f(y))/(h*y)})
    (out/'independent_results.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    (out/'independent_tests.txt').write_text(transcript,encoding='utf-8')
    return 0 if result.wasSuccessful() else 1

if __name__=='__main__': raise SystemExit(main())
