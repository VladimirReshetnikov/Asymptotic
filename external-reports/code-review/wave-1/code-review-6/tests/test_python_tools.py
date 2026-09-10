import importlib.util
import unittest
from fractions import Fraction
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module
patch=load('audit_patch',ROOT/'patches'/'make_export_patch.py')
checks=load('audit_checks',ROOT/'code'/'independent_checks.py')

class AuditToolTests(unittest.TestCase):
    def test_exact_span(self):
        self.assertEqual(checks.lattice_span([Fraction(0),Fraction(1,10**9)],Fraction(1))['slots'],10**9)
    def test_empty_span(self):
        self.assertEqual(checks.lattice_span([],Fraction(3,2))['slots'],0)
    def test_negative_span(self):
        for values in ([Fraction(2)], [Fraction(0),Fraction(2)], [Fraction(1)]):
            with self.subTest(values=values), self.assertRaises(ValueError):
                checks.lattice_span(values,Fraction(1))
    def test_patch_guards_both_exporters(self):
        text=(ROOT/'evidence'/'exporters_excerpt.wl').read_text()
        result=patch.patch_text(text)
        self.assertEqual(result.count('Missing["LogarithmicRemainder"]'),2)
        self.assertEqual(result.count('Missing["DenseRepresentationBudget", nmax - nmin]'),2)
    def test_patch_is_not_reapplied(self):
        text=(ROOT/'evidence'/'exporters_excerpt.wl').read_text()
        with self.assertRaises(ValueError):
            patch.patch_text(patch.patch_text(text))
    def test_missing_source_refused(self):
        with self.assertRaises(ValueError):
            patch.patch_text('unrelated source')
    def test_git_blob_hash(self):
        self.assertEqual(patch.git_blob_sha(b''),'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391')

if __name__=='__main__': unittest.main()
