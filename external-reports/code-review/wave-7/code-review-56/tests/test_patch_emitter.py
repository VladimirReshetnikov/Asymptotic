from pathlib import Path
import importlib.util
import json
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('emitter',ROOT/'patches'/'emit_candidate_patch.py')
emitter=importlib.util.module_from_spec(spec); spec.loader.exec_module(emitter)
EDITS=json.loads((ROOT/'patches'/'edits.json').read_text())

class PatchEmitterTests(unittest.TestCase):
    def fixture(self,root):
        grouped={}
        for e in EDITS: grouped.setdefault(e['file'],[]).append(e['old'])
        for name,anchors in grouped.items():
            p=root/name;p.parent.mkdir(parents=True,exist_ok=True)
            p.write_text('(* synthetic fixture, not an upstream checkout *)\n'+'\n'.join(anchors)+'\n')
    def test_all_edits_and_no_writes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            before={str(p):p.read_bytes() for p in root.rglob('*.wl')}
            diff=emitter.emit(root,verify_revision=False)
            self.assertIn('UnprovedRealRemainder',diff); self.assertIn('seriesStructuralAnd',diff)
            self.assertEqual(before,{str(p):p.read_bytes() for p in root.rglob('*.wl')})
    def test_single_finding(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            self.assertNotIn('SeriesOperations.wl',emitter.emit(root,'N01',False))
            self.assertNotIn('SeriesEnvelopeArithmetic.wl',emitter.emit(root,'N02',False))
    def test_missing_anchor_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            (root/EDITS[0]['file']).write_text('changed upstream source\n')
            with self.assertRaises(ValueError):emitter.emit(root,verify_revision=False)
    def test_duplicate_anchor_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            p=root/EDITS[0]['file'];p.write_text(p.read_text()+EDITS[0]['old'])
            with self.assertRaises(ValueError):emitter.emit(root,verify_revision=False)
    def test_git_pin_required(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            with self.assertRaises(ValueError):emitter.emit(root)
    def test_unknown_finding_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);self.fixture(root)
            with self.assertRaises(ValueError):emitter.emit(root,'N99',False)

if __name__=='__main__':unittest.main(verbosity=2)
