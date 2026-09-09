"""Fixture-only checks of the proposed source-edit script; no Wolfram execution."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "proposals"))
from apply_bridge_hardening import harden_text, git_blob_sha

FIXTURE = '''makeSeriesData[args___] := Module[{exps, den, nmin, nmax, coeffs, ptx, dirSign},
If[remData === None, Return[Missing["Exact"], Module]];
coeffs = Table[0, {nmax - nmin}];
];
makeInverseSeriesData[args___] := Module[{exps, den, nmin, nmax, coeffs},
If[remData === None, Return[Missing["Exact"], Module]];
coeffs = Table[0, {nmax - nmin}];
];
'''

class PatchFixtureTests(unittest.TestCase):
    def test_both_bridges_hardened(self):
        result = harden_text(FIXTURE)
        self.assertEqual(result.count('Missing["LogarithmicRemainder"]'), 2)
        self.assertEqual(result.count('Missing["DenseSeriesDataBudget"'), 2)
        self.assertNotIn('Table[0, {nmax - nmin}]', result)

    def test_custom_budget(self):
        self.assertEqual(harden_text(FIXTURE, 17).count('denseLength > 17'), 2)

    def test_refuse_second_application(self):
        with self.assertRaises(ValueError):
            harden_text(harden_text(FIXTURE))

    def test_refuse_bad_budget(self):
        with self.assertRaises(ValueError):
            harden_text(FIXTURE, 0)

    def test_git_hash_known_empty_blob(self):
        self.assertEqual(git_blob_sha(b''), 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391')

if __name__ == '__main__':
    unittest.main(verbosity=2)
