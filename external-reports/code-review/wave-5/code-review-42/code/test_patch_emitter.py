#!/usr/bin/env python3
"""Fixture tests of the read-only emitter; not full upstream/native tests."""
import importlib.util, io, json, sys, unittest
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('emitter',root/'patches'/'emit_candidate_patch.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
class PatchFixtures(unittest.TestCase):
    def fixture(self): return 'prefix\n'+m.ABS_ANCHOR+'\nmiddle\n'+m.PREFIX_ANCHOR+'\nsuffix\n'
    def test_both_edits(self):
        s=m.transform(self.fixture())
        self.assertIn(m.ABS_REPLACEMENT,s); self.assertIn(m.PREFIX_REPLACEMENT,s)
        self.assertTrue(s.startswith('prefix\n')); self.assertTrue(s.endswith('suffix\n'))
    def test_only_regularity(self):
        s=m.transform(self.fixture(),'regularity')
        self.assertIn(m.ABS_REPLACEMENT,s); self.assertIn(m.PREFIX_ANCHOR,s)
    def test_only_prefix(self):
        s=m.transform(self.fixture(),'prefix')
        self.assertIn(m.ABS_ANCHOR,s); self.assertIn(m.PREFIX_REPLACEMENT,s)
    def test_duplicate_anchor_refused(self):
        with self.assertRaises(ValueError): m.transform(self.fixture()+m.PREFIX_ANCHOR)
    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError): m.transform('unrelated text')
    def test_already_changed_source_refused(self):
        with self.assertRaises(ValueError): m.transform(m.transform(self.fixture()))
if __name__=='__main__':
    stream=io.StringIO()
    r=unittest.TextTestRunner(stream=stream,verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(PatchFixtures))
    print(stream.getvalue(),end='')
    (root/'evidence'/'patch_fixture_tests.txt').write_text(stream.getvalue(),encoding='utf-8')
    (root/'evidence'/'patch_fixture_results.json').write_text(json.dumps({
        'scope':'Synthetic source-anchor fixtures only; complete upstream source application not executed',
        'tests_run':r.testsRun,'failures':len(r.failures),'errors':len(r.errors),'successful':r.wasSuccessful()},indent=2)+'\n',encoding='utf-8')
    raise SystemExit(0 if r.wasSuccessful() else 1)
