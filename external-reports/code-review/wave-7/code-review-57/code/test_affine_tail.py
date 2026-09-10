"""Independent model tests; not package acceptance tests."""
from fractions import Fraction as Q
import unittest
from affine_tail import (Tail, moment, merge_omitted_constant, split_bound,
                        lerch_model, lerch_interval, affine_error_interval)

class AffineTailTests(unittest.TestCase):
    def test_exact_main_counterexample(self):
        m=lerch_model(Q(1,2),2,1,1,0)
        self.assertEqual(m.rows,())
        self.assertEqual(m.atom_tail,Tail(2,Q(2)))
        self.assertEqual(m.source_predicted_unrepaired_bound(2),Q(3,4))
        self.assertGreaterEqual(affine_error_interval(m,2)[0],Q(5,4))
        self.assertEqual(m.tail,Tail(0,Q(3)))
    def test_limit_order_counterfamily(self):
        for s in range(1,7):
            m=lerch_model(Q(1,2),s,1,1,0)
            for a in (4,8,16,32):
                self.assertGreater(affine_error_interval(m,a)[0],
                                   m.source_predicted_unrepaired_bound(a))
    def test_negative_cutoff_does_not_fix_grade(self):
        for h in (Q(-7),Q(-1,2),Q(0)):
            self.assertEqual(lerch_model(Q(1,2),2,1,1,h).tail.order,0)
    def test_zero_beta_preserves_atom(self):
        for r in (None,-4,-1,0,1,5):
            t=Tail(r,0 if r is None else 3)
            self.assertIs(merge_omitted_constant(t,0),t)
    def test_exact_plus_constant_is_not_exact(self):
        self.assertEqual(merge_omitted_constant(Tail(None,0),7),Tail(0,7))
    def test_equal_grade(self):
        self.assertEqual(merge_omitted_constant(Tail(0,3),-5),Tail(0,8))
    def test_growing_tail(self):
        self.assertEqual(merge_omitted_constant(Tail(-3,2),5),Tail(-3,7))
    def test_decaying_tail(self):
        self.assertEqual(merge_omitted_constant(Tail(3,2),5),Tail(0,7))
    def test_grade_bound_grid(self):
        count=0
        for r in (None,-5,-2,-1,0,1,2,5):
            for c in (0,1,3,11):
                if r is None and c: continue
                t=Tail(r,c)
                for beta in (-7,-1,0,2,9):
                    for a in (1,2,5,11,100):
                        u=merge_omitted_constant(t,beta)
                        self.assertGreaterEqual(u.bound(a),split_bound(t,beta,a))
                        count+=1
        self.assertEqual(count,725)
    def test_concrete_lerch_grid(self):
        # 3,000 parameter combinations, one unittest method.
        count=0
        for z in (Q(-1,2),Q(0),Q(1,4),Q(1,2),Q(3,4)):
            for s in (1,2,4):
                for alpha in (-2,1):
                    for beta in (-1,0,1,3):
                        for h in (-1,0,1,3,5):
                            m=lerch_model(z,s,alpha,beta,h)
                            for a in (1,2,4,8,16):
                                lo,hi=affine_error_interval(m,a,48)
                                self.assertLessEqual(max(abs(lo),abs(hi)),m.tail.bound(a))
                                count+=1
        self.assertEqual(count,3000)
    def test_positive_cutoff_retains_constant(self):
        m=lerch_model(Q(1,2),2,1,1,3)
        self.assertEqual(m.rows,((0,Q(1)),(2,Q(2))))
        self.assertEqual(m.charged,0)
        self.assertEqual(m.tail,m.atom_tail)
    def test_zero_base_exact_control(self):
        m=lerch_model(Q(0),2,1,1,3)
        self.assertEqual(m.tail,Tail(None,0))
        self.assertEqual(affine_error_interval(m,2),(Q(0),Q(0)))
    def test_moment_controls(self):
        self.assertEqual([moment(Q(1,2),k) for k in range(4)],[2,2,6,26])
    def test_negative_multiplier(self):
        m=lerch_model(Q(1,2),2,-3,-2,0)
        self.assertEqual(m.tail,Tail(0,8))
        self.assertLessEqual(max(map(abs,affine_error_interval(m,2))),8)
    def test_reference_interval_nesting(self):
        for z in (Q(-1,2),Q(1,2)):
            lo,hi=lerch_interval(z,2,2,8)
            lo2,hi2=lerch_interval(z,2,2,16)
            self.assertLessEqual(lo,lo2); self.assertLessEqual(hi2,hi)
    def test_exact_tail_validation(self):
        with self.assertRaises(ValueError): Tail(None,1)
        with self.assertRaises(ValueError): Tail(1,-1)
    def test_inexact_inputs_rejected(self):
        with self.assertRaises(TypeError): Tail(1,0.1)
        with self.assertRaises(TypeError): merge_omitted_constant(Tail(1,2),0.1)
    def test_bound_domain_rejected(self):
        with self.assertRaises(ValueError): Tail(1,2).bound(Q(1,2))
    def test_oracle_domain_rejected(self):
        with self.assertRaises(ValueError): lerch_model(Q(1),2,1,1,0)
        with self.assertRaises(ValueError): lerch_model(Q(1,2),-3,1,1,0)
    def test_source_prediction_not_used_as_oracle(self):
        m=lerch_model(Q(1,2),2,1,1,0)
        actual_lo,_=affine_error_interval(m,2)
        self.assertFalse(actual_lo <= m.source_predicted_unrepaired_bound(2))

if __name__=='__main__': unittest.main(verbosity=2)
