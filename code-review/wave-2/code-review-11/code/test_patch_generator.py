"""Tests on explicit small source-anchor fixtures, NOT the full upstream module."""
import unittest
from make_certificate_patch import ANCHOR, REPLACEMENT, candidate, git_blob

class PatchMechanics(unittest.TestCase):
    def setUp(self):
        self.source = ('(* fixture *)\nc = '+ANCHOR+';\n').encode()
        self.sha = git_blob(self.source)

    def test_single_replacement(self):
        patched, meta = candidate(self.source, self.sha)
        self.assertIn(REPLACEMENT.encode(),patched)
        self.assertEqual(patched.replace(REPLACEMENT.encode(),ANCHOR.encode()),self.source)
        self.assertEqual(meta['replacement_count'],1)

    def test_wrong_snapshot_refused(self):
        with self.assertRaises(ValueError):
            candidate(self.source,'0'*40)

    def test_duplicate_anchor_refused(self):
        source = self.source+self.source
        with self.assertRaises(ValueError):
            candidate(source,git_blob(source))

    def test_missing_anchor_refused(self):
        source=b'(* unrelated *)\n'
        with self.assertRaises(ValueError):
            candidate(source,git_blob(source))

    def test_crlf_checked_after_normalization(self):
        patched, meta = candidate(self.source.replace(b'\n',b'\r\n'),self.sha)
        self.assertTrue(meta['input_newlines_normalized'])
        self.assertNotIn(b'\r',patched)

if __name__=='__main__':
    unittest.main(verbosity=2)
