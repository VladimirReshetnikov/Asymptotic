#!/usr/bin/env python3
"""These tests validate text transformation only, not Wolfram semantics."""
import importlib.util
import json
from pathlib import Path
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('audit_patch', HERE / 'patch_native_boundary.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
PATCH = json.loads((HERE / 'native_boundary_patch.json').read_text())

class PatchTransformationTests(unittest.TestCase):
    def fixture(self):
        return '\n\n'.join(edit['old'] for edit in PATCH['replacements']
                            for _ in range(edit['count'])) + '\n'
    def test_all_expected_anchors_are_replaced(self):
        before = self.fixture()
        after = module.apply_text(before, PATCH)
        expected = {}
        for edit in PATCH['replacements']:
            self.assertNotIn(edit['old'], after)
            expected[edit['new']] = expected.get(edit['new'], 0) + edit['count']
        for new, count in expected.items():
            self.assertEqual(after.count(new), count)
    def test_missing_anchor_is_refused(self):
        with self.assertRaises(ValueError):
            module.apply_text(self.fixture().replace(PATCH['replacements'][0]['old'], '', 1), PATCH)
    def test_extra_anchor_is_refused(self):
        with self.assertRaises(ValueError):
            module.apply_text(self.fixture() + PATCH['replacements'][0]['old'], PATCH)
    def test_second_application_is_refused(self):
        with self.assertRaises(ValueError):
            module.apply_text(module.apply_text(self.fixture(), PATCH), PATCH)
    def test_input_is_not_mutated_by_failed_validation(self):
        before = 'incompatible source\n'
        with self.assertRaises(ValueError):
            module.apply_text(before, PATCH)
        self.assertEqual(before, 'incompatible source\n')
    def test_helper_excerpt_matches_authoritative_specification(self):
        self.assertEqual((HERE / 'native_boundary_helpers.wl').read_text(), PATCH['append'])

if __name__ == '__main__':
    unittest.main(verbosity=2)
