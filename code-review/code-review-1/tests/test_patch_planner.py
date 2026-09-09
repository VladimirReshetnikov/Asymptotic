"""Tests of patch mechanics only: synthetic fixture, not the repository kernel."""
import importlib.util
import pathlib
import unittest

p = pathlib.Path(__file__).resolve().parents[1] / "code" / "propose_core_patch.py"
spec = importlib.util.spec_from_file_location("propose_core_patch", p)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

FIXTURE = '''fwdPower[args___] := Module[{},
  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],
    fail["UnknownLeadingTerm", "old"]]];
];

makeSeriesData[terms_, x_, other___] := Module[{},
  If[remData === None, Return[Missing["Exact"], Module]];
  coeffs = Table[0, {nmax - nmin}];
];

makeInverseSeriesData[terms_, y_, other___] := Module[{},
  If[remData === None, Return[Missing["Exact"], Module]];
  coeffs = Table[0, {nmax - nmin}];
];
'''

class PatchPlannerTests(unittest.TestCase):
    def test_all_guards_inserted(self):
        out = module.transform(FIXTURE)
        self.assertEqual(out.count('P =!= Infinity && ! IntegerQ[rr]'), 1)
        self.assertEqual(out.count('Missing["LogarithmicRemainder"]'), 2)
        self.assertEqual(out.count('Missing["SeriesDataSizeLimit"'), 2)
        self.assertIn('FreeQ[#[[2]], x]', out)
        self.assertIn('FreeQ[#[[2]], y]', out)

    def test_duplicate_definitions_refused(self):
        # Duplicated definition content is rejected rather than silently edited.
        with self.assertRaises(ValueError):
            module.transform(FIXTURE + FIXTURE)

    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError):
            module.transform('not the pinned implementation')

    def test_bad_budget_refused(self):
        for budget in (0, -1, True):
            with self.assertRaises(ValueError):
                module.transform(FIXTURE, budget)

    def test_budget_is_substituted(self):
        out = module.transform(FIXTURE, 1000)
        self.assertEqual(out.count('nmax - nmin > 1000'), 2)

    def test_known_git_blob_hash(self):
        # Standard Git blob hash for an empty file.
        self.assertEqual(module.git_blob_sha(b''), 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391')

if __name__ == '__main__':
    unittest.main()
