"""Patcher fixture tests. No upstream checkout or native kernel is involved."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import subprocess
import sys

PATH=Path(__file__).resolve().parents[1]/'patches'/'emit_candidate_patch.py'
spec=importlib.util.spec_from_file_location('candidate',PATH)
candidate=importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate)

class PatchTests(unittest.TestCase):
    def test_each_unique_anchor(self):
        for relative,old,new in candidate.EDITS.values():
            self.assertEqual(candidate.transform('BEFORE\n'+old+'\nAFTER\n',old,new),
                             'BEFORE\n'+new+'\nAFTER\n')

    def test_missing_anchor_refused(self):
        for _,old,new in candidate.EDITS.values():
            with self.assertRaises(ValueError): candidate.transform('other',old,new)

    def test_ambiguous_anchor_refused(self):
        for _,old,new in candidate.EDITS.values():
            with self.assertRaises(ValueError): candidate.transform(old+'\n'+old,old,new)

    def test_diff_only_preserves_files(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); original={}
            for rel,old,_ in candidate.EDITS.values():
                path=root/rel; path.parent.mkdir(parents=True,exist_ok=True)
                original[rel]='(* synthetic fixture *)\n'+old+'\n'
                path.write_text(original[rel],encoding='utf-8')
            result=subprocess.run([sys.executable,str(PATH),str(root),'--skip-commit-check'],
                                  capture_output=True,text=True,check=False)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertIn('+++ b/src/Kernel/InverseCertificates.wl',result.stdout)
            for rel,text in original.items(): self.assertEqual((root/rel).read_text(),text)

    def test_failure_emits_no_partial_diff(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            for rel,old,_ in candidate.EDITS.values():
                path=root/rel; path.parent.mkdir(parents=True,exist_ok=True)
                path.write_text(old if 'NumericalInverseChecks' not in rel else 'bad')
            result=subprocess.run([sys.executable,str(PATH),str(root),'--skip-commit-check'],
                                  capture_output=True,text=True,check=False)
            self.assertEqual(result.returncode,2)
            self.assertEqual(result.stdout,'')

    def test_commit_check_is_default(self):
        with tempfile.TemporaryDirectory() as td:
            result=subprocess.run([sys.executable,str(PATH),td],capture_output=True,text=True)
            self.assertEqual(result.returncode,2)
            self.assertEqual(result.stdout,'')

if __name__=='__main__': unittest.main(verbosity=2)
