import sys
import unittest
from fractions import Fraction
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"code"))
import patch_core as p
from independent_checks import dense_plan

class AuditArtifactTests(unittest.TestCase):
    def test_large_plan_without_allocation(self):
        self.assertEqual(dense_plan([Fraction(1,10007),Fraction(1,10009)],Fraction(1))["required_slots"],100150056)
    def test_empty_pure_remainder_plan(self):
        self.assertEqual(dense_plan([],Fraction(2))["required_slots"],0)
    def test_invalid_weight(self):
        with self.assertRaises(ValueError): dense_plan([Fraction(1)],Fraction(1))
    def test_invalid_budget(self):
        with self.assertRaises(ValueError): dense_plan([],Fraction(1),0)
    def test_patch_anchors_on_small_fixture(self):
        fixture = p.BRANCH_OLD+'\n'+p.DENSE_OLD+'\n'+p.DENSE_OLD+'\n'+p.STOP_OLD+'\n'
        output = p.rewrite(fixture)
        self.assertIn(p.BRANCH_NEW,output)
        self.assertEqual(output.count('"DenseRepresentationTooLarge"'),2)
        self.assertIn(p.STOP_NEW,output)
    def test_patch_rejects_missing_anchor(self):
        with self.assertRaises(ValueError): p.rewrite('not the reviewed source')
    def test_patch_rejects_ambiguous_anchor(self):
        with self.assertRaises(ValueError): p.replace_exact('aa','a','b',1,'test')
    def test_git_blob_hash(self):
        self.assertEqual(p.git_blob_sha1(b''),'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391')

if __name__ == '__main__': unittest.main()
