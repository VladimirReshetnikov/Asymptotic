import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("affine",ROOT/"code"/"affine_domain_proof.py")
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class AffineProofTests(unittest.TestCase):
    def test_counterexample(self):
        r=m.prove_affine(1,"-1/4","<","9/10","11/10")
        self.assertEqual(r["status"],"Disproved");self.assertTrue(m.verify_affine(r))
        self.assertEqual(r["range"],["13/20","17/20"])
    def test_valid_branch(self):
        r=m.prove_affine(1,"-1/4","<","9/100","11/100")
        self.assertEqual(r["status"],"Proved");self.assertTrue(m.verify_affine(r))
    def test_strict_endpoint(self):
        r=m.prove_affine(1,"-1/4","<","1/5","1/4")
        self.assertEqual(r["counterexample"],"1/4")
    def test_weak_endpoint(self):
        self.assertEqual(m.prove_affine(1,"-1/4","<=","1/5","1/4")["status"],"Proved")
    def test_interior_unequal_counterexample(self):
        r=m.prove_affine(2,-1,"!=",0,1)
        self.assertEqual(r["counterexample"],"1/2");self.assertTrue(m.verify_affine(r))
    def test_zero_equality(self):
        self.assertEqual(m.prove_affine(0,0,"==",-1,1)["status"],"Proved")
    def test_negative_slope(self):
        r=m.prove_affine(-2,3,">",0,1)
        self.assertEqual(r["range"],["1","3"]);self.assertEqual(r["status"],"Proved")
    def test_tampered_claim(self):
        r=m.prove_affine(1,"-1/4","<","9/10","11/10")
        r["status"]="Proved";self.assertFalse(m.verify_affine(r))
    def test_tampered_range(self):
        r=m.prove_affine(1,"-1/4","<","9/10","11/10")
        r["range"]=["-1","-1/2"];self.assertFalse(m.verify_affine(r))
    def test_added_assumption(self):
        r=m.prove_affine(1,"-1/4","<","9/10","11/10")
        r["assumptions"]=["x<1/4"];self.assertFalse(m.verify_affine(r))
    def test_inexact_refused(self):
        with self.assertRaises(TypeError): m.prove_affine(1,-0.25,"<",0,1)
    def test_reversed_refused(self):
        with self.assertRaises(ValueError): m.prove_affine(1,0,"<",1,0)
if __name__=="__main__":unittest.main()
