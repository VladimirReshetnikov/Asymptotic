"""Tests of patch-tool guards on synthetic fixtures, not a repository checkout."""
from pathlib import Path
import importlib.util
import unittest
p=Path(__file__).resolve().parents[1]/"code"/"apply_semantic_weight_patch.py"
spec=importlib.util.spec_from_file_location("patchtool",p)
m=importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(m)
class PatchToolTests(unittest.TestCase):
    def test_one_anchor(self):
        data=b"prefix\n"+m.ANCHOR+b"\nsuffix\n"
        actual=m.patch_bytes(data,m.git_blob_hash(data))
        self.assertIn(m.REPLACEMENT,actual)
        self.assertNotIn(m.ANCHOR,actual)
    def test_wrong_hash(self):
        with self.assertRaises(ValueError):m.patch_bytes(m.ANCHOR)
    def test_missing_anchor(self):
        data=b"other source"
        with self.assertRaises(ValueError):m.patch_bytes(data,m.git_blob_hash(data))
    def test_duplicate_anchor(self):
        data=m.ANCHOR+b"\n"+m.ANCHOR
        with self.assertRaises(ValueError):m.patch_bytes(data,m.git_blob_hash(data))
    def test_git_hash(self):
        self.assertEqual(m.git_blob_hash(b""),"e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")
if __name__=="__main__":unittest.main(verbosity=2)
