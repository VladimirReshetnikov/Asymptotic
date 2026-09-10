"""Independent mathematical and rewrite tests, not package acceptance tests."""
import random
import unittest
from fractions import Fraction as F
from independent_models import (
    Arithmetic, exact_power_hull, certificate_witness, node, protect_tree,
    assumption_witness, assumption_program, ELEMENT, PRIVATE_ELEMENT, ASSUMPTIONS,
    positive_grammar, logarithm_witness)

class IntervalTests(unittest.TestCase):
    def test_cube_witness(self):
        a = (F(-1,4), F(1))
        self.assertEqual(Arithmetic().power(a,3), (F(-1,4), F(1)))
        self.assertEqual(Arithmetic().power(a,3,True), (F(-1,64), F(1)))

    def test_reflected_witness(self):
        a = (F(-1), F(1,4))
        self.assertEqual(Arithmetic().power(a,3), (F(-1), F(1,4)))
        self.assertEqual(Arithmetic().power(a,3,True), (F(-1), F(1,64)))

    def test_certificate_derivative_stage(self):
        r = certificate_witness()
        self.assertEqual(r['old_derivative'], ['-3/16','17/16'])
        self.assertEqual(r['new_derivative'], ['3/64','17/16'])
        self.assertFalse(r['old_separates_derivative'])
        self.assertTrue(r['new_separates_derivative'])
        self.assertEqual(r['exact_residual'], '0')
        self.assertEqual(r['true_derivative_lower_bound_on_source_branch'], '11/432')

    def test_exact_odd_family(self):
        for d in (2,4,8,16):
            for n in (3,5,7,9):
                with self.subTest(d=d,n=n):
                    a = (F(-1,d), F(1))
                    self.assertEqual(Arithmetic(128).power(a,n), (F(-1,d),F(1)))
                    self.assertEqual(Arithmetic(128).power(a,n,True), exact_power_hull(a,n))

    def test_rounding_is_outward(self):
        rng = random.Random(701)
        for _ in range(1000):
            q = F(rng.randint(-10**12,10**12), rng.randint(1,10**9))
            for bits in (8,24,48):
                ar = Arithmetic(bits)
                self.assertLessEqual(ar.rounded(q,False),q)
                self.assertGreaterEqual(ar.rounded(q,True),q)

    def test_random_power_containment(self):
        rng = random.Random(702)
        for _ in range(500):
            a = tuple(sorted((F(rng.randint(-100,100),rng.randint(1,31)),
                              F(rng.randint(-100,100),rng.randint(1,31)))))
            n = rng.randint(0,13)
            exact = exact_power_hull(a,n)
            for patched in (False,True):
                result = Arithmetic(24).power(a,n,patched)
                self.assertLessEqual(result[0],exact[0])
                self.assertGreaterEqual(result[1],exact[1])

    def test_unaffected_paths_identical(self):
        rng = random.Random(703)
        for _ in range(300):
            a = tuple(sorted((F(rng.randint(1,100),rng.randint(1,20)),
                              F(rng.randint(1,100),rng.randint(1,20)))))
            if rng.randrange(2):
                a = (-a[1],-a[0])
            n = rng.randint(-9,9)
            self.assertEqual(Arithmetic(24).power(a,n),Arithmetic(24).power(a,n,True))
        for n in (0,1,2,4,6,8):
            a=(F(-2,3),F(7,5))
            self.assertEqual(Arithmetic(24).power(a,n),Arithmetic(24).power(a,n,True))

    def test_negative_power_containment(self):
        for a in ((F(1,3),F(5,2)),(F(-5,2),F(-1,3))):
            for n in range(-8,0):
                for patched in (False,True):
                    r=Arithmetic(24).power(a,n,patched)
                    e=exact_power_hull(a,n)
                    self.assertLessEqual(r[0],e[0]); self.assertGreaterEqual(r[1],e[1])

    def test_singularity_preserved(self):
        for patched in (False,True):
            with self.assertRaises(ZeroDivisionError):
                Arithmetic().power((F(-1),F(2)),-3,patched)

    def test_resource_cap_preserved(self):
        for patched in (False,True):
            with self.assertRaises(ValueError):
                Arithmetic().power((F(-1),F(1)),100001,patched)

    def test_large_exponent_bounded_arithmetic(self):
        ar=Arithmetic(24)
        result=ar.power((F(-1,4),F(1)),99999,True)
        self.assertEqual(result[1],1)
        self.assertLess(result[0],0)
        self.assertLess(ar.multiplications,100)
        self.assertLess(ar.squares,100)

    def test_invalid_inputs(self):
        with self.assertRaises(ValueError): Arithmetic(1)
        with self.assertRaises(TypeError): Arithmetic().power((F(0),F(1)),F(3,2))
        with self.assertRaises(ValueError): Arithmetic().power((F(2),F(1)),3)

class AssumptionRewriteTests(unittest.TestCase):
    def test_bare_symbol_program(self):
        h=assumption_witness()
        self.assertEqual(assumption_program(h),'a > 0')
        self.assertEqual(assumption_program(protect_tree(h,False)),'a < 0')
        self.assertEqual(assumption_program(protect_tree(h,True)),'a > 0')

    def test_actual_membership_protected(self):
        for kind in ('Rule','RuleDelayed'):
            h=node(kind,ASSUMPTIONS,node(ELEMENT,node('Sin','a'),'Reals'))
            expected=node(kind,ASSUMPTIONS,node(PRIVATE_ELEMENT,node('Sin','a'),'Reals'))
            self.assertEqual(protect_tree(h,False),expected)
            self.assertEqual(protect_tree(h,True),expected)

    def test_bare_symbol_in_pattern_preserved(self):
        h=node('Rule',ASSUMPTIONS,node('MatchQ','datum',node('Blank',ELEMENT)))
        self.assertNotEqual(protect_tree(h,False),h)
        self.assertEqual(protect_tree(h,True),h)

    def test_outside_assumption_value_unchanged(self):
        h=node('Call',node(ELEMENT,'a','Reals'),node('Rule','other',ELEMENT))
        self.assertEqual(protect_tree(h,False),h)
        self.assertEqual(protect_tree(h,True),h)

    def test_wrong_arity_unchanged_by_candidate(self):
        h=node('Rule',ASSUMPTIONS,node(ELEMENT,'a','Reals','extra'))
        self.assertNotEqual(protect_tree(h,False),h)
        self.assertEqual(protect_tree(h,True),h)

    def test_idempotence(self):
        h=node('Call',assumption_witness(),node('Rule',ASSUMPTIONS,node(ELEMENT,'a','Reals')))
        for patched in (False,True):
            once=protect_tree(h,patched)
            self.assertEqual(protect_tree(once,patched),once)

    def test_nested_rule_preserves_scope(self):
        h=node('HoldComplete',node('Call',node('List',assumption_witness())))
        self.assertNotEqual(protect_tree(h,False),h)
        self.assertEqual(protect_tree(h,True),h)

    def test_quotation_limitation_is_explicit(self):
        h=node('Rule',ASSUMPTIONS,node('HoldComplete',node(ELEMENT,'a','Reals')))
        self.assertNotEqual(protect_tree(h,True),h)
        # The candidate repairs bare data, not every quoted membership program.

class LogRecoveryTests(unittest.TestCase):
    def test_binary53_countermodel(self):
        r=logarithm_witness()
        self.assertEqual(r['model_signs'],[1,1])
        self.assertEqual(r['true_signs'],[-1,-1])

    def test_principal_log_branch_error(self):
        r=logarithm_witness()
        self.assertEqual(r['principal_log_product_imaginary_part'],'0.0')
        self.assertIn('1.0',r['difference_divided_by_2pii'])
        self.assertFalse(r['public_Indeterminate_trigger_demonstrated'])

    def test_intended_positive_recovery_grammar(self):
        self.assertTrue(positive_grammar(node('Power','Pi',F(1,2))))
        self.assertTrue(positive_grammar(F(1,10**1000)))
        self.assertTrue(positive_grammar(node('Times',node('Power','Pi',F(1,2)),F(1,10**1000))))

    def test_positive_atoms(self):
        for e in (1,F(2,3),'Pi','E','Glaisher'):
            self.assertTrue(positive_grammar(e))

    def test_unknown_sign_is_not_a_proof(self):
        for e in (0,-1,F(-1,3),'a',node('Plus',1,-2),node('Sin','a'),
                  node('Power',-1,F(1,2))):
            self.assertFalse(positive_grammar(e))

    def test_approximate_numbers_rejected(self):
        for e in (1.0,1e-20,-1.0):
            self.assertFalse(positive_grammar(e))

class MetadataTests(unittest.TestCase):
    def test_signed_observable_not_positive_coordinate_power(self):
        u=F(2); side=-1; power=3
        local_root=u; local_approx=(side*u)**power
        self.assertEqual(local_root,2)
        self.assertEqual(local_approx,-8)
        self.assertNotEqual(local_approx,u**power)
        self.assertNotEqual(local_root,u**power)

    def test_positive_side_still_has_different_root_field(self):
        u=F(2); power=2
        self.assertEqual(u,2); self.assertEqual(u**power,4)
        self.assertNotEqual(u,u**power)

if __name__=='__main__':
    unittest.main(verbosity=2)
