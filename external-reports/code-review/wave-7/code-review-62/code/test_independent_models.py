#!/usr/bin/env python3
"""Independent Boolean/count models and staging fixtures, NOT package execution."""
from __future__ import annotations
import itertools
from pathlib import Path
import unittest
from patch_merge_only import OLD, NEW, START, patch_text

ROOT = Path(__file__).resolve().parents[1]


def baseline(left: tuple[str, ...], right: tuple[str, ...]) -> tuple[str, ...]:
    aligned_right = left + right
    return left + aligned_right


def merge_only(left: tuple[str, ...], right: tuple[str, ...]) -> tuple[str, ...]:
    aligned_right = left + right
    return aligned_right


class MergeModelTests(unittest.TestCase):
    def test_native_count_transcription_matches_recurrence(self):
        observed = [1, 3, 7, 15, 31, 63, 127, 255, 511]
        left = ("x>0",)
        predicted = [len(left)]
        for _ in range(8):
            left = baseline(left, ("x>0",))
            predicted.append(len(left))
        self.assertEqual(predicted, observed)

    def test_merge_only_fixed_operand_chain_is_linear(self):
        left = ("x>0",)
        for n in range(1, 65):
            left = merge_only(left, ("x>0",))
            self.assertEqual(len(left), n + 1)

    def test_all_boolean_assignments_preserved(self):
        for left, right in [(('A',), ('B',)), (('A', 'C'), ('B', 'C')), ((), ('B',)), (('A',), ())]:
            for values in itertools.product([False, True], repeat=3):
                assignment = dict(zip('ABC', values))
                evaluate = lambda clauses: all(assignment[c] for c in clauses)
                self.assertEqual(evaluate(baseline(left, right)), evaluate(merge_only(left, right)))

    def test_repeated_left_and_right_folds_are_asymmetric_before_fix(self):
        left = right = ("D",)
        for _ in range(10):
            left = baseline(left, ("D",))
            right = baseline(("D",), right)
        self.assertEqual((len(left), len(right)), (2047, 21))

    def test_order_count_symmetry_after_merge_only(self):
        left = right = ("D",)
        for _ in range(10):
            left = merge_only(left, ("D",))
            right = merge_only(("D",), right)
        self.assertEqual((len(left), len(right)), (11, 11))

    def test_balanced_tree_count(self):
        value = ("D",)
        for height in range(1, 8):
            value = baseline(value, value)
            self.assertEqual(len(value), 3 ** height)


class PatchFixtureTests(unittest.TestCase):
    def setUp(self):
        self.fixture = (ROOT / 'fixtures' / 'series_binary.wl').read_text(encoding='utf-8')

    def test_exact_retrieved_definition_site_is_replaced(self):
        result = patch_text(self.fixture)
        self.assertNotIn(OLD, result)
        self.assertEqual(result.count(NEW), 1)
        self.assertIn('ass = seriesAss[a] && seriesAss[b]', result)
        self.assertIn('seriesCompatible[a, b]', result)

    def test_unrelated_prefix_and_suffix_preserved(self):
        result = patch_text('(* sentinel prefix *)\n' + self.fixture + '\n(* sentinel suffix *)')
        self.assertTrue(result.startswith('(* sentinel prefix *)\n'))
        self.assertTrue(result.endswith('\n(* sentinel suffix *)'))

    def test_refuses_drifted_merge_site(self):
        with self.assertRaises(ValueError):
            patch_text(self.fixture.replace(OLD, OLD.replace('order', 'otherOrder')))

    def test_refuses_duplicate_definition(self):
        with self.assertRaises(ValueError):
            patch_text(self.fixture + self.fixture)

    def test_refuses_reapplication(self):
        with self.assertRaises(ValueError):
            patch_text(patch_text(self.fixture))

    def test_refuses_missing_definition(self):
        with self.assertRaises(ValueError):
            patch_text(self.fixture.replace(START, 'renamed['))

    def test_preserves_unrelated_lookalike_site(self):
        text = OLD + '\n' + self.fixture
        result = patch_text(text)
        self.assertTrue(result.startswith(OLD + '\n'))
        self.assertEqual(result.count(OLD), 1)


def normalized(left: tuple[str, ...], right: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(dict.fromkeys(left + right))


class ScalarAndNormalizedModelTests(unittest.TestCase):
    def test_scalar_baseline_matches_native_observations(self):
        clauses = ("D",)
        actual = []
        for _ in range(4):
            clauses = baseline(clauses, clauses)
            actual.append(len(clauses))
        self.assertEqual(actual, [3, 9, 27, 81])

    def test_merge_only_is_not_a_complete_scalar_fix(self):
        clauses = ("D",)
        actual = []
        for _ in range(4):
            clauses = merge_only(clauses, clauses)
            actual.append(len(clauses))
        self.assertEqual(actual, [2, 4, 8, 16])

    def test_normalized_scalar_and_fixed_operand_chains(self):
        scalar = fixed = ("D",)
        for _ in range(100):
            scalar = normalized(scalar, scalar)
            fixed = normalized(fixed, ("D",))
            self.assertEqual((scalar, fixed), (("D",), ("D",)))

    def test_normalized_join_preserves_distinct_conditions(self):
        self.assertEqual(normalized(("A", "B"), ("B", "C")), ("A", "B", "C"))

    def test_normalized_join_is_semantically_equivalent(self):
        for left in [(), ("A",), ("A", "A", "B")]:
            for right in [(), ("B",), ("C", "B", "C")]:
                for bits in itertools.product([False, True], repeat=3):
                    env = dict(zip("ABC", bits))
                    evaluate = lambda cs: all(env[c] for c in cs)
                    self.assertEqual(evaluate(baseline(left, right)), evaluate(normalized(left, right)))

    def test_duplicate_disjunction_is_opaque_not_distributed(self):
        # Strings are atomic predicates in this independent structural model.
        clause = "(A or B)"
        self.assertEqual(normalized((clause,), (clause, "C")), (clause, "C"))


class CompletePatchFixtureTests(unittest.TestCase):
    def setUp(self):
        from patch_conditions import patch_text, OLD_ALIGN, NEW_ALIGN
        self.patch = patch_text
        self.old_align = OLD_ALIGN
        self.new_align = NEW_ALIGN
        self.fixture = (ROOT / 'fixtures/series_alignment_and_binary.wl').read_text()

    def test_both_sites_replaced(self):
        result = self.patch(self.fixture)
        self.assertNotIn(self.old_align, result)
        self.assertNotIn(OLD, result)
        self.assertEqual(result.count(self.new_align), 1)
        self.assertEqual(result.count(NEW), 1)

    def test_guards_coefficient_and_branch_code_unchanged(self):
        result = self.patch(self.fixture)
        for fragment in ['seriesCompatible[a, b]', 'j = pAdd[a["Jet"]',
                         'j = pMul[a["Jet"]', 'seriesMake[d, {op, {s, t}}, h]']:
            self.assertIn(fragment, result)

    def test_reapplication_refused(self):
        with self.assertRaises(ValueError):
            self.patch(self.patch(self.fixture))

    def test_alignment_drift_refused(self):
        with self.assertRaises(ValueError):
            self.patch(self.fixture.replace(self.old_align, self.old_align + '\n(* drift *)'))

    def test_merge_drift_refused_before_any_staging(self):
        with self.assertRaises(ValueError):
            self.patch(self.fixture.replace(OLD, OLD.replace('order', 'otherOrder')))

    def test_duplicate_alignment_refused(self):
        with self.assertRaises(ValueError):
            self.patch(self.old_align + '\n' + self.fixture)

    def test_unrelated_prefix_and_suffix_preserved(self):
        result = self.patch('(* prefix *)\n' + self.fixture + '\n(* suffix *)')
        self.assertTrue(result.startswith('(* prefix *)\n'))
        self.assertTrue(result.endswith('\n(* suffix *)'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
