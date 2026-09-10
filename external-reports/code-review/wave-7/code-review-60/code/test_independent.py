"""Independent exact mathematics and patch-fixture tests, NOT package tests."""
from fractions import Fraction as F
from pathlib import Path
import tempfile
import unittest
from reference import (catalan, marker_coefficients as coeff, approximation as app,
                       reported_scale, root_interval, absolute_error_interval, rational)
from patch_core_validation import transform, prepare, REPLACEMENTS


def conv(a, b, k):
    return sum((a[j] * b[k-j] for j in range(k+1)), F(0))


class ExactMathematics(unittest.TestCase):
    def test_catalan_values(self):
        self.assertEqual([catalan(n) for n in range(7)], [1,1,2,5,14,42,132])
    def test_large_constant(self):
        self.assertEqual(coeff('large', 7, 2, 0), [F(9)])
    def test_large_first_marker(self):
        self.assertEqual(coeff('large', 7, 2, 1)[1], -2-F(1,9))
    def test_large_second_marker(self):
        self.assertEqual(coeff('large', 7, 2, 2)[2], -F(2,81)-F(1,729))
    def test_small_constant(self):
        self.assertEqual(coeff('small', 7, 2, 0), [F(1,9)])
    def test_small_first_marker(self):
        self.assertEqual(coeff('small', 7, 2, 1)[1], F(2,81)+F(1,729))
    def test_reciprocal_series_identity(self):
        for y,c in [(F(7),F(2)),(F(9),F(9)),(F(11,2),F(3,7))]:
            a,b=coeff('large',y,c,8),coeff('small',y,c,8)
            self.assertEqual([conv(a,b,k) for k in range(9)],[F(1)]+[F(0)]*8)
    def test_large_implicit_equation(self):
        for y,c in [(F(8),F(8)),(F(6),F(1,10)),(F(9),F(0))]:
            a=coeff('large',y,c,10)
            for k in range(11):
                r=conv(a,a,k)-(y+c)*a[k]+(c*a[k-1] if k else 0)+(1 if k==1 else 0)
                self.assertEqual(r,0)
    def test_small_implicit_equation(self):
        for y,c in [(F(8),F(8)),(F(6),F(1,10)),(F(9),F(0))]:
            a=coeff('small',y,c,10)
            for k in range(11):
                r=(conv(a,a,k-1) if k else 0)-(y+c)*a[k]+(c*a[k-1] if k else 0)+(1 if k==0 else 0)
                self.assertEqual(r,0)
    def test_native_large_formula(self):
        for y in map(F,[3,5,10,20,100]):
            self.assertEqual(app('large',y,y,2), y-F(3,4)/y-F(1,8)/y**3)
    def test_native_small_formula(self):
        for y in map(F,[3,5,10,20,100]):
            self.assertEqual(app('small',y,y,2), (1+5*y*y+14*y**4)/(16*y**5))
    def test_unshifted_large_catalan_series(self):
        y=F(7)
        self.assertEqual(app('large',y,0,6),y-sum((F(catalan(k-1))/y**(2*k-1) for k in range(1,7)),F(0)))
    def test_unshifted_small_catalan_series(self):
        y=F(7)
        self.assertEqual(app('small',y,0,6),sum((F(catalan(k))/y**(2*k+1) for k in range(7)),F(0)))
    def test_scale_changes_when_constant_row_disappears(self):
        self.assertEqual(reported_scale('large',7,0,2),F(1,7**5))
        self.assertEqual(reported_scale('large',7,1,2),F(1,8**2))
        self.assertEqual(reported_scale('small',7,0,2),F(1,7**7))
        self.assertEqual(reported_scale('small',7,1,2),F(1,8**4))
    def test_root_intervals_are_on_correct_branches(self):
        for y in map(F,[3,5,10,100]):
            lo,hi=root_interval(y,'large',60)
            self.assertGreater(lo,1)
            self.assertLessEqual(lo*lo-y*lo+1,0)
            self.assertGreaterEqual(hi*hi-y*hi+1,0)
            lo,hi=root_interval(y,'small',60)
            self.assertLess(hi,1)
            self.assertGreaterEqual(lo*lo-y*lo+1,0)
            self.assertLessEqual(hi*hi-y*hi+1,0)
    def test_exact_square_discriminant(self):
        self.assertEqual(root_interval(F(5,2),'large'),(F(2),F(2)))
        self.assertEqual(root_interval(F(5,2),'small'),(F(1,2),F(1,2)))
    def test_large_error_ratio_grows(self):
        for y in map(F,[5,10,20,50,100,1000]):
            lo,_=absolute_error_interval(app('large',y,y,2),root_interval(y,'large'))
            self.assertGreater(lo/reported_scale('large',y,y,2),y)
    def test_small_error_ratio_grows(self):
        for y in map(F,[5,10,20,50,100,1000]):
            lo,_=absolute_error_interval(app('small',y,y,2),root_interval(y,'small'))
            self.assertGreater(lo/reported_scale('small',y,y,2),y**3)
    def test_all_depth_large_asymptotic_constant(self):
        y=F(10**20)
        for lam in [F(1,2),F(1),F(2)]:
            for n in range(1,9):
                lo,hi=absolute_error_interval(app('large',y,lam*y,n),root_interval(y,'large',180))
                expected=(lam/(1+lam))**n
                self.assertLess(abs(lo*y/expected-1),F(1,10**30))
                self.assertLess(abs(hi*y/expected-1),F(1,10**30))
    def test_all_depth_small_asymptotic_constant(self):
        y=F(10**20)
        for lam in [F(1,2),F(1),F(2)]:
            for n in range(9):
                lo,hi=absolute_error_interval(app('small',y,lam*y,n),root_interval(y,'small',180))
                expected=(lam/(1+lam))**(n+1)
                self.assertLess(abs(lo*y/expected-1),F(1,10**30))
                self.assertLess(abs(hi*y/expected-1),F(1,10**30))
    def test_invalid_or_inexact_inputs(self):
        for q in [True,1.0,'2']:
            with self.assertRaises(TypeError): rational(q)
        for n in [-1,65]:
            with self.assertRaises(ValueError): coeff('large',5,1,n)
        with self.assertRaises(ValueError): coeff('bad',5,1,1)
        with self.assertRaises(ValueError): coeff('large',5,-5,1)
    def test_invalid_root_domains(self):
        for y in [0,1,2]:
            with self.assertRaises(ValueError): root_interval(y,'large')
        with self.assertRaises(ValueError): root_interval(5,'bad')
        with self.assertRaises(ValueError): root_interval(5,'large',0)


class PatchFixtures(unittest.TestCase):
    def setUp(self):
        self.source='(* fixture, not a repository copy *)\n'+REPLACEMENTS[0][0]+'\n'+REPLACEMENTS[1][0]+' fail[]];\n'
    def test_two_anchors_changed(self):
        result=transform(self.source)
        for old,new in REPLACEMENTS:
            self.assertNotIn(old,result)
            self.assertIn(new,result)
    def test_missing_anchor_refused(self):
        for old,_ in REPLACEMENTS:
            with self.assertRaises(ValueError): transform(self.source.replace(old,''))
    def test_duplicate_anchor_refused(self):
        for old,_ in REPLACEMENTS:
            with self.assertRaises(ValueError): transform(self.source+'\n'+old)
    def test_already_patched_refused(self):
        with self.assertRaises(ValueError): transform(transform(self.source))
    def test_diff_only_does_not_modify_source(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'source.wl'; p.write_text(self.source)
            diff=prepare(p)
            self.assertEqual(p.read_text(),self.source)
            self.assertIn('--- a/src/Kernel/CorePerturbation.wl',diff)
    def test_output_is_exclusive(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'source.wl'; p.write_text(self.source)
            q=Path(directory)/'patched.wl'; prepare(p,q)
            self.assertEqual(q.read_text(),transform(self.source))
            with self.assertRaises(FileExistsError): prepare(p,q)
            with self.assertRaises(FileExistsError): prepare(p,p)
            self.assertEqual(p.read_text(),self.source)
    def test_invalid_utf8_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'source.wl'; p.write_bytes(b'\xff')
            with self.assertRaises(UnicodeError): prepare(p)
    def test_unrelated_text_unchanged(self):
        tail='\nother[core, perturbation, y] := original;\n'
        self.assertTrue(transform(self.source+tail).endswith(tail))

if __name__=='__main__':
    unittest.main(verbosity=2)
