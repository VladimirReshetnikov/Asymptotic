from __future__ import annotations
from fractions import Fraction as F
from itertools import product
from math import comb
from pathlib import Path
import json
import sys
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'code'))
from negative_lerch import (lerch_negative_interval as enc, difference_coefficients as ds,
    lerch_s1_integer_a_reference as logref, alternating_reference as altref)

QS = [F(0),F(1,10),F(1,2),F(9,10),F(1)]
AS = [F(1,4),F(1),F(3,2),F(10),F(100)]
SS = [1,2,3,5]
KS = [0,1,2,4,8,16,32]

class ReferenceTests(unittest.TestCase):
    def test_difference_formula(self):
        for a,s,k in product(AS,SS,range(9)):
            expected=sum(((-1)**j*comb(k,j)/(a+j)**s for j in range(k+1)),F(0))
            self.assertEqual(ds(s,a,k)[-1],expected)

    def test_complete_monotonicity(self):
        for a,s in product(AS,SS):
            d=ds(s,a,32)
            self.assertTrue(all(v>0 for v in d))
            self.assertTrue(all(x>=y for x,y in zip(d,d[1:])))

    def test_closed_difference_log2(self):
        self.assertEqual(ds(1,F(1),64),tuple(F(1,k+1) for k in range(65)))

    def test_grid_width_and_nestedness(self):
        records=[]
        for q,s,a in product(QS,SS,AS):
            previous=None
            for k in KS:
                e=enc(q,s,a,k); r=q/(1+q)
                self.assertLessEqual(e.lower,e.upper)
                self.assertEqual(e.width,r**(k+1)*e.difference_coefficient)
                self.assertLessEqual(e.width,a**(-s)*F(1,2)**(k+1))
                if previous:
                    self.assertGreaterEqual(e.lower,previous.lower)
                    self.assertLessEqual(e.upper,previous.upper)
                previous=e; records.append(e.as_record())
        self.assertEqual(len(records),700)
        (ROOT/'evidence'/'lerch_grid.json').write_text(json.dumps(records,indent=2)+'\n')

    def test_independent_log_reference_contained(self):
        count=0
        for q,a,k in product(QS[1:],[1,2,5],KS):
            e=enc(q,1,a,k); lo,hi=logref(q,a)
            self.assertLessEqual(e.lower,lo)
            self.assertGreaterEqual(e.upper,hi)
            count+=1
        self.assertEqual(count,84)

    def test_independent_alternating_intervals_overlap(self):
        for q,s,a in product(QS,[1,2,5],[F(1,4),F(1),F(10)]):
            e=enc(q,s,a,16); lo,hi=altref(q,s,a,128)
            self.assertLessEqual(max(e.lower,lo),min(e.upper,hi))
        # Overlap is explicitly a consistency check, not proof of containment.

    def test_q_zero_all_orders(self):
        for s,a,k in product(SS,AS,KS):
            e=enc(0,s,a,k)
            self.assertEqual((e.lower,e.upper),(a**(-s),a**(-s)))

    def test_reject_invalid_inputs(self):
        invalid=[(0.5,1,1,2),(True,1,1,2),(F(1,2),True,1,2),
                 (F(1,2),1,1,False),(F(1,2),1,1.0,2),
                 (F(-1,2),1,1,2),(F(3,2),1,1,2),(1,0,1,2),
                 (1,1,0,2),(1,1,1,-1),(1,1,1,257),(1,1001,1,2)]
        for args in invalid:
            with self.subTest(args=args), self.assertRaises((TypeError,ValueError)):
                enc(*args)

    def test_complex_source_exact_decomposition(self):
        for n in [2,5,10,20,50,100]:
            x=F(1,n); u=-x*x/(1+x**6); v=1/(x*(1+x**6))
            # (u+i v)*x*(1-i x^3)=i, with exact rational components.
            self.assertEqual(x*(u+v*x**3),0)
            self.assertEqual(x*(v-u*x**3),1)
            self.assertGreaterEqual(v,F(n,2))

    def test_counterexample_lower_bound_growth(self):
        # sinh(v)>=v^7/7!, v>=n/2; these exact bounds already diverge.
        denomin=128*5040
        values=[F(n**5,denomin) for n in [10,20,50,100]]
        self.assertTrue(all(a<b for a,b in zip(values,values[1:])))
        self.assertGreater(values[-1],10000)
        (ROOT/'evidence'/'counterexample_exact_bounds.json').write_text(json.dumps([
            {'n':n,'sine_normalized_lower_bound':str(F(n**5,denomin)),
             'cosine_normalized_lower_bound':str(F(n**5,denomin)-F(1,n*n))}
            for n in [10,20,50,100]],indent=2)+'\n')

    def test_metadata_recurrence(self):
        counts=[1]
        for _ in range(5): counts.append(3*counts[-1])
        self.assertEqual(counts,[1,3,9,27,81,243])
        self.assertEqual([1+3*v for v in counts[1:]],[10,28,82,244,730])

if __name__=='__main__': unittest.main(verbosity=2)
