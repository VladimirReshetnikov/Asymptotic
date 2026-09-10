import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from patch_source_shift import OLD, NEW, patch_text, main

class PatchFixtures(unittest.TestCase):
    def test_one_guard(self):
        text='If[foo || '+OLD+', fail["InvalidVariables", "message"]];'
        self.assertEqual(patch_text(text),text.replace(OLD,NEW))
    def test_missing_anchor(self):
        with self.assertRaises(ValueError): patch_text('unrelated')
    def test_duplicate_anchor(self):
        with self.assertRaises(ValueError): patch_text(OLD+'\n'+OLD)
    def test_already_patched(self):
        with self.assertRaises(ValueError): patch_text(NEW)
    def test_unrelated_bytes_and_newlines(self):
        text='(* preserved café *)\r\n'+OLD+'\r\ntrailer\r\n'
        self.assertEqual(patch_text(text).replace(NEW,OLD),text)
    def test_cli_creates_separate_copy(self):
        with tempfile.TemporaryDirectory() as d,contextlib.redirect_stdout(io.StringIO()):
            p=Path(d)/'source.wl'; q=Path(d)/'copy.wl'; p.write_text(OLD)
            self.assertEqual(main([str(p),'--output',str(q)]),0)
            self.assertEqual(p.read_text(),OLD); self.assertEqual(q.read_text(),NEW)
    def test_cli_refuses_existing_output(self):
        with tempfile.TemporaryDirectory() as d,contextlib.redirect_stderr(io.StringIO()):
            p=Path(d)/'source.wl'; q=Path(d)/'copy.wl'; p.write_text(OLD);q.write_text('keep')
            self.assertEqual(main([str(p),'--output',str(q)]),2)
            self.assertEqual(q.read_text(),'keep')
    def test_cli_refuses_original(self):
        with tempfile.TemporaryDirectory() as d,contextlib.redirect_stderr(io.StringIO()):
            p=Path(d)/'source.wl';p.write_text(OLD)
            self.assertEqual(main([str(p),'--output',str(p)]),2)
            self.assertEqual(p.read_text(),OLD)

if __name__ == '__main__': unittest.main(verbosity=2)
