"""Tests of narrow source transforms on explicit fixtures, not a checkout."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("apply_fixes", ROOT/"code"/"apply_fixes.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
PATCHES = json.loads((ROOT/"code"/"patch_spec.json").read_text())["patches"]

class PatchFixtureTests(unittest.TestCase):
    def test_certificate_exact_replacement(self):
        e = PATCHES[0]["edits"]
        old = "prefix\n" + e[0]["before"] + "\nsuffix"
        new = module.transform(old,e)
        self.assertEqual(new, "prefix\n"+e[0]["after"]+"\nsuffix")
    def test_certificate_no_anchor_refused(self):
        with self.assertRaises(ValueError): module.transform("unrelated",PATCHES[0]["edits"])
    def test_certificate_duplicate_refused(self):
        e = PATCHES[0]["edits"]
        with self.assertRaises(ValueError): module.transform(e[0]["before"]*2,e)
    def test_certificate_reapply_refused(self):
        e = PATCHES[0]["edits"]
        with self.assertRaises(ValueError): module.transform(e[0]["after"],e)
    def test_flat_move_and_charge(self):
        e = PATCHES[1]["edits"]
        old=e[0]["before"]+"  aIndices = activeA;\n"+e[1]["before"]+"\n  convolution = allocate;"
        new=module.transform(old,e)
        self.assertNotIn("(na + 1) (nb + 1)",new)
        self.assertIn("Length[aIndices] Length[bIndices] > limit",new)
        self.assertLess(new.index("bIndices ="),new.index("If[Length[aIndices]"))
        self.assertLess(new.index("If[Length[aIndices]"),new.index("convolution ="))
    def test_flat_missing_second_anchor_refused(self):
        e=PATCHES[1]["edits"]
        with self.assertRaises(ValueError): module.transform(e[0]["before"],e)
    def test_flat_reapply_refused(self):
        e=PATCHES[1]["edits"]
        old=e[0]["before"]+e[1]["before"]
        with self.assertRaises(ValueError): module.transform(module.transform(old,e),e)
    def test_flat_unknown_zero_predicate_unchanged(self):
        e=PATCHES[1]["edits"]
        predicate='flatOpsExactZeroQ[j_] := j[[1]] === {} && j[[2]] === Infinity;\n'
        old=predicate+e[0]["before"]+e[1]["before"]
        self.assertTrue(module.transform(old,e).startswith(predicate))

if __name__ == "__main__": unittest.main()
