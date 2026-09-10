#!/usr/bin/env python3
"""Run independent algebra, control-flow, and candidate-emitter checks.

Requires Python >=3.10, SymPy, and mpmath. No network. No Wolfram or Mathics
execution is performed. The JSON report is rewritten only at --output.
"""
from __future__ import annotations

import argparse
from fractions import Fraction as F
import io
import itertools
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import tempfile
import unittest

import mpmath as mp
import sympy as sp

from emit_candidate_patch import EDITS, make_patch, transform
from reference_models import (
    Bound, Candidate, Rule, SymbolKey, add_bounds, candidate_count_equal_depth,
    dense_flat_candidates, desired_power, inspected_power_selection,
    inverse_unit_coefficient, join_tails, local_observation, materialized_tail,
    multiply_bounds, option_leaves, two_pass_tail,
)


class OptionChecks(unittest.TestCase):
    def test_symbol_key_becomes_string_in_wolfram_source_model(self):
        self.assertEqual(inspected_power_selection([Rule(SymbolKey("Power"), 2)], 1,
                                                   evaluator="wolfram"), "Power")

    def test_mixed_keys_choose_later_literal_in_source_model(self):
        rules = [Rule(SymbolKey("Power"), 2), Rule("Power", 3)]
        self.assertEqual(inspected_power_selection(rules, 1, evaluator="wolfram"), 3)
        self.assertEqual(desired_power(rules, 1), 2)

    def test_native_nested_control_is_not_reported_as_a_wolfram_bug(self):
        rules = [[Rule("Power", 2)]]
        self.assertEqual(inspected_power_selection(rules, 1, evaluator="wolfram"), 2)

    def test_mathics_primitive_model_omits_delayed_rules(self):
        called = []
        rules = [Rule("Power", lambda: called.append(1) or 2, delayed=True)]
        self.assertEqual(inspected_power_selection(rules, 1, evaluator="mathics"), 1)
        self.assertEqual(called, [])

    def test_mathics_primitive_model_does_not_flatten(self):
        self.assertEqual(inspected_power_selection([[Rule("Power", 2)]], 1,
                                                   evaluator="mathics"), 1)

    def test_desired_selection_preserves_first_matching_option(self):
        for keys in itertools.product(["Power", SymbolKey("Power"),
                                       SymbolKey("Power", "Other`")], repeat=2):
            self.assertEqual(desired_power([Rule(keys[0], 2), Rule(keys[1], 3)], 1), 2)

    def test_desired_nested_selection(self):
        self.assertEqual(desired_power([[], [Rule("Other", 8), [[Rule("Power", 2)]]]], 1), 2)

    def test_rule_value_lists_are_not_flattened(self):
        value = [1, [2, [3]]]
        self.assertEqual(desired_power([Rule("Power", value)], 1), value)
        self.assertEqual(len(list(option_leaves([Rule("Power", value)]))), 1)

    def test_selected_delayed_value_evaluates_once(self):
        called = []
        self.assertEqual(desired_power([Rule("Power", lambda: called.append(1) or 2,
                                                   delayed=True)], 1), 2)
        self.assertEqual(called, [1])

    def test_shadowed_delayed_value_is_not_evaluated(self):
        called = []
        rules = [Rule("Power", 2), Rule("Power", lambda: called.append(1), delayed=True)]
        self.assertEqual(desired_power(rules, 1), 2)
        self.assertEqual(called, [])

    def test_stored_value_is_only_the_omitted_default(self):
        self.assertEqual(desired_power([], 7), 7)
        self.assertEqual(desired_power([Rule("Power", 2)], 7), 2)


class AlgebraChecks(unittest.TestCase):
    def test_closed_form_inverse_identity(self):
        y = sp.Symbol("y", positive=True)
        g = (sp.sqrt(1 + 4*y) - 1)/2
        self.assertEqual(sp.simplify(g + g*g - y), 0)

    def test_power_coefficient_formula_against_sympy(self):
        y = sp.Symbol("y")
        unit = (sp.sqrt(1 + 4*y) - 1)/(2*y)
        # 56 independently compared coefficients, including removable-singularity cases.
        for r in (-3, -2, -1, 1, 2, 3, 5):
            poly = sp.series(unit**r, y, 0, 8).removeO().expand()
            for k in range(8):
                expected = inverse_unit_coefficient(r, k)
                with self.subTest(r=r, k=k):
                    self.assertEqual(poly.coeff(y, k), sp.Rational(expected.numerator,
                                                                  expected.denominator))

    def test_first_two_symbolic_coefficients(self):
        r = sp.Symbol("r")
        y = sp.Symbol("y")
        unit = sp.series((sp.sqrt(1+4*y)-1)/(2*y), y, 0, 4).removeO()
        poly = sp.series(sp.exp(r * sp.log(unit)), y, 0, 3).removeO().expand()
        self.assertEqual(sp.simplify(poly.coeff(y, 1) + r), 0)
        self.assertEqual(sp.simplify(poly.coeff(y, 2) - r*(r+3)/2), 0)

    def test_coefficient_formula_is_regular_at_negative_powers(self):
        self.assertEqual(inverse_unit_coefficient(-1, 1), 1)
        self.assertEqual(inverse_unit_coefficient(-2, 2), -1)
        self.assertEqual(inverse_unit_coefficient(-3, 3), 1)


class NumericalChecks(unittest.TestCase):
    def test_exact_python_operation_in_mathics_rational_round_underflows(self):
        for exponent in (324, 400, 1000, 5000):
            value = sp.Rational(1, 10**exponent)
            with self.subTest(exponent=exponent):
                self.assertGreater(value, 0)
                self.assertEqual(float(value), 0.0)
                self.assertFalse(float(value) > 0)

    def test_positive_subnormal_control(self):
        self.assertGreater(float(sp.Rational(1, 10**323)), 0.0)

    def test_exact_rational_sign_survives_scale(self):
        for exponent in (20, 324, 400, 1000, 5000):
            q = F(1, 10**exponent)
            self.assertTrue(q > 0)
            self.assertFalse(-q > 0)
        self.assertFalse(F(0) > 0)

    def test_logarithmic_target_stays_finite(self):
        with mp.workdps(100):
            for exponent in (20, 400, 1000, 5000):
                q = mp.mpf(10)**(-exponent)
                direct = mp.log(mp.sqrt(mp.pi) * q)
                split = mp.log(mp.pi)/2 - exponent*mp.log(10)
                self.assertTrue(mp.isfinite(direct))
                self.assertLess(abs(direct-split), mp.mpf("1e-93"))

    def test_positive_square_fields_use_different_units(self):
        fields = local_observation(F(2), 1, 2)
        self.assertEqual(fields["LocalRoot"], 2)
        self.assertEqual(fields["LocalApproximation"], 4)
        self.assertEqual(fields["LocalReferenceObservable"], 4)

    def test_negative_cube_includes_source_orientation(self):
        fields = local_observation(F(2), -1, 3)
        self.assertEqual(fields["LocalRoot"], 2)
        self.assertEqual(fields["LocalApproximation"], -8)
        self.assertNotEqual(fields["LocalApproximation"], F(2)**3)

    def test_power_one_uses_the_unsigned_local_coordinate(self):
        fields = local_observation(F(2), -1, 1)
        self.assertEqual(fields["LocalRoot"], fields["LocalReferenceObservable"])

    def test_negative_power_observable(self):
        self.assertEqual(local_observation(F(2), -1, -3)["LocalReferenceObservable"], F(-1, 8))


class GradedTailChecks(unittest.TestCase):
    def test_grade_precedes_every_algebraic_power(self):
        self.assertEqual(join_tails(Candidate(2, Bound(F(1000))),
                                    Candidate(3, Bound(F(-100000)))),
                         Candidate(2, Bound(F(1000))))

    def test_equal_grade_uses_power_then_log_degree(self):
        self.assertEqual(join_tails(Candidate(2, Bound(F(1), 99)),
                                    Candidate(2, Bound(F(0), 0))),
                         Candidate(2, Bound(F(0), 0)))
        self.assertEqual(add_bounds(Bound(F(-1), 2), Bound(F(-1), 6)), Bound(F(-1), 6))

    def test_unknown_bounds_are_idempotent_not_cancellable(self):
        t = Candidate(3, Bound(F(-2), 5))
        self.assertEqual(join_tails(t, t), t)
        self.assertEqual(join_tails(None, t), t)
        self.assertEqual(join_tails(t, None), t)

    def test_join_associative_and_commutative(self):
        items = [None] + [Candidate(g, Bound(F(p, 2), k))
                          for g in (1, 2) for p in (-2, 0, 3) for k in (0, 2)]
        for a, b in itertools.product(items, repeat=2):
            self.assertEqual(join_tails(a, b), join_tails(b, a))
        for a, b, c in itertools.product(items, repeat=3):
            self.assertEqual(join_tails(join_tails(a, b), c), join_tails(a, join_tails(b, c)))

    def test_product_bound_adds_log_degrees(self):
        self.assertEqual(multiply_bounds(Bound(F(-2, 3), 2), Bound(F(1, 6), 5)),
                         Bound(F(-1, 2), 7))

    def test_two_pass_matches_materialized_random_candidates(self):
        randomizer = random.Random(20260910)
        for _ in range(300):
            items = [Candidate(randomizer.randrange(1, 20),
                               Bound(F(randomizer.randrange(-20, 21), randomizer.randrange(1, 8)),
                                     randomizer.randrange(0, 8)))
                     for _ in range(randomizer.randrange(0, 50))]
            self.assertEqual(two_pass_tail(lambda: iter(items)), materialized_tail(items))

    def test_candidate_count_formula(self):
        for n in range(1, 31):
            self.assertEqual(sum(1 for _ in dense_flat_candidates(n)), candidate_count_equal_depth(n))
        self.assertEqual(candidate_count_equal_depth(100), 5154)
        self.assertEqual(candidate_count_equal_depth(140), 10014)

    def test_dense_family_two_pass_equivalence(self):
        for n in (1, 2, 3, 10, 30, 100, 140):
            self.assertEqual(two_pass_tail(lambda: dense_flat_candidates(n)),
                             materialized_tail(dense_flat_candidates(n)))

    def test_first_omitted_coefficient_must_be_summed_before_grading(self):
        z = sp.Symbol("z")
        product = sp.expand((1+z+z*z)*(1+z-z*z))
        self.assertEqual(product.coeff(z, 3), 0)
        self.assertEqual(product.coeff(z, 4), -1)
        self.assertEqual(two_pass_tail(lambda: iter([Candidate(4, Bound(F(0)))])),
                         Candidate(4, Bound(F(0))))

    def test_two_pass_skips_comparisons_at_ultimately_dominated_grades(self):
        class Uncomparable:
            def __lt__(self, other):
                raise AssertionError("Dominated algebraic comparison was attempted")
            def __gt__(self, other):
                raise AssertionError("Dominated algebraic comparison was attempted")
        class OpaqueBound:
            def __init__(self):
                self.power, self.log_degree = Uncomparable(), 0
        # Runtime Python permits this deliberately adversarial comparator fixture.
        items = [Candidate(9, OpaqueBound()), Candidate(9, OpaqueBound()),
                 Candidate(2, Bound(F(1)))]
        self.assertEqual(two_pass_tail(lambda: iter(items)), Candidate(2, Bound(F(1))))
        with self.assertRaisesRegex(AssertionError, "Dominated"):
            answer = None
            for item in items:
                answer = join_tails(answer, item)

    def test_empty_tail_is_exact_zero(self):
        self.assertIsNone(materialized_tail([]))
        self.assertIsNone(two_pass_tail(lambda: iter([])))


class EmitterChecks(unittest.TestCase):
    def fixture(self, path):
        return "(* synthetic context, NOT the repository file *)\n" + "\n".join(
            old for old, _ in EDITS[path]) + "\n"

    def test_exact_anchors_transform_once(self):
        for path, edits in EDITS.items():
            changed = transform(path, self.fixture(path))
            for old, new in edits:
                self.assertIn(new, changed)

    def test_missing_anchor_is_refused(self):
        for path in EDITS:
            with self.assertRaises(ValueError):
                transform(path, "No anchor")

    def test_duplicate_anchor_is_refused(self):
        for path in EDITS:
            with self.assertRaises(ValueError):
                transform(path, self.fixture(path)*2)

    def test_already_patched_fixture_is_refused(self):
        for path in EDITS:
            with self.assertRaises(ValueError):
                transform(path, transform(path, self.fixture(path)))

    def test_synthetic_git_checkout_success_and_dirty_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.run(["git", "-C", str(root), *args], check=True,
                                      text=True, capture_output=True).stdout
            git("init", "-q")
            git("config", "user.name", "Audit fixture")
            git("config", "user.email", "fixture@example.invalid")
            for path in EDITS:
                file = root/path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(self.fixture(path), encoding="utf-8")
            git("add", ".")
            git("commit", "-qm", "synthetic fixture")
            fixture_pin = git("rev-parse", "HEAD").strip()
            patch = make_patch(root, expected_pin=fixture_pin)
            self.assertEqual(patch.count("--- a/"), 3)
            self.assertIn("LocalReferenceObservable", patch)
            with self.assertRaisesRegex(ValueError, "pinned"):
                make_patch(root)  # Production pin cannot match this synthetic repo.
            file = root/next(iter(EDITS))
            file.write_text(file.read_text()+"dirty\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "not clean"):
                make_patch(root, expected_pin=fixture_pin)


class RecordingResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.passed_ids = []
    def addSuccess(self, test):
        super().addSuccess(test)
        self.passed_ids.append(test.id())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1]/
                        "evidence"/"independent-results.json")
    args = parser.parse_args()
    suite = unittest.defaultTestLoader.loadTestsFromModule(__import__(__name__))
    result = unittest.TextTestRunner(verbosity=2, resultclass=RecordingResult).run(suite)
    report = {
        "scope": "Independent Python mathematics/control-flow models and synthetic patch fixtures only",
        "wolfram_executed_by_this_script": False, "mathics_executed_by_this_script": False,
        "python": platform.python_version(), "sympy": sp.__version__, "mpmath": mp.__version__,
        "tests_run": result.testsRun, "passed_test_ids": result.passed_ids,
        "failures": [{"test": str(t), "traceback": text} for t, text in result.failures],
        "errors": [{"test": str(t), "traceback": text} for t, text in result.errors],
        "success": result.wasSuccessful(),
        "candidate_counts": [{"depth": n, "tail_candidate_records": candidate_count_equal_depth(n),
                              "existing_pair_preflight": (n+1)**2}
                             for n in (1, 2, 3, 10, 30, 100, 140, 500, 1000)],
        "notes": ["Subtests are not separate named tests in tests_run.",
                  "The Git success path used synthetic source fixtures and a test-only expected pin.",
                  "Real-checkout CLI execution is not established by that fixture.",
                  "Native Wolfram results, obtained separately, are in native-observations.json."]
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
