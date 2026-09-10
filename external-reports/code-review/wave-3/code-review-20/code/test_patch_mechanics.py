"""Anchor-mechanics tests, explicitly not full-source integration tests."""
import unittest
from make_candidate import apply_rules, patch_rules

class PatchMechanics(unittest.TestCase):
    def setUp(self):
        self.rules = patch_rules()
        self.fixture = '\n\n'.join(r['old'] * r['count'] for r in self.rules)
    def test_all_edits_present(self):
        result = apply_rules(self.fixture)
        for rule in self.rules:
            self.assertIn(rule['new'], result)
    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError):
            apply_rules(self.fixture.replace(self.rules[0]['old'], '', 1))
    def test_duplicate_anchor_refused(self):
        with self.assertRaises(ValueError):
            apply_rules(self.fixture + self.rules[0]['old'])
    def test_second_application_refused(self):
        with self.assertRaises(ValueError):
            apply_rules(apply_rules(self.fixture))
    def test_failure_does_not_mutate_input(self):
        original = self.fixture
        with self.assertRaises(ValueError):
            apply_rules(self.fixture, [{'id':'absent','old':'NO SUCH ANCHOR','new':'x','count':1}])
        self.assertEqual(self.fixture, original)

if __name__ == '__main__':
    unittest.main(verbosity=2)
