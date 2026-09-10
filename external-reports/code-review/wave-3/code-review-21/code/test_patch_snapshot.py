"""Synthetic source-fixture tests ONLY, not a checkout or Wolfram execution."""
import unittest
from pathlib import Path
from patch_snapshot import PATCHES, NATIVE, OPS, patch_texts, replace_once


def fixture():
    d={}
    for path,label,old,new in PATCHES:
        d[path]=d.get(path,'')+'\n(* fixture '+label+' *)\n'+old+'\n'
    return d

class PatchTests(unittest.TestCase):
    def test_all_exact_anchors_apply(self):
        out=patch_texts(fixture())
        self.assertEqual(set(out),{NATIVE,OPS,Path('README.md')})
    def test_default_is_option_driven(self):
        self.assertIn('OptionValue[AsymptoticExpansion, {}, "Backend"]',patch_texts(fixture())[NATIVE])
    def test_nested_function_blank_removed_from_recursive_guard(self):
        text=patch_texts(fixture())[NATIVE]
        self.assertNotIn('_InverseFunction | _Function',text)
        self.assertIn('HoldComplete[_Function]',text)
    def test_name_helper_preserves_symbol_non_evaluation(self):
        self.assertIn('SymbolName[Unevaluated[name]]',patch_texts(fixture())[NATIVE])
    def test_observable_guard_precedes_coefficient_use(self):
        text=patch_texts(fixture())[OPS]
        self.assertLess(text.index('InsufficientNativeOrder'),text.index('completed observable'))
    def test_exact_fast_path_records_no_replay(self):
        text=patch_texts(fixture())[OPS]
        self.assertIn('"SourceReplayRequired" -> False',text)
        self.assertIn('! less[Last[j[[1]]][[1]], h]',text)
    def test_missing_anchor_fails_closed(self):
        with self.assertRaises(ValueError): replace_once('no anchor','missing','new','test')
    def test_duplicate_anchor_fails_closed(self):
        with self.assertRaises(ValueError): replace_once('x x','x','new','test')
    def test_staging_is_not_silently_idempotent(self):
        once=patch_texts(fixture())
        with self.assertRaises(ValueError): patch_texts(once)
    def test_input_mapping_is_not_mutated(self):
        old=fixture(); before=dict(old); patch_texts(old); self.assertEqual(old,before)

if __name__=='__main__': unittest.main(verbosity=2)
