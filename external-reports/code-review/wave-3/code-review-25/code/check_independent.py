#!/usr/bin/env python3
"""Independent exact mathematics and patch-fixture tests; NOT package execution."""
from __future__ import annotations
from fractions import Fraction
from pathlib import Path
import json
import math
import sys
import unittest
from stage_patch import transform

HERE = Path(__file__).resolve().parent
SPEC = json.loads((HERE / 'patch_spec.json').read_text(encoding='utf-8'))


def frac_positive(x: Fraction) -> Fraction:
    assert x >= 0
    return x - math.floor(x)


def compose_order(alpha: Fraction, native_order: int) -> Fraction:
    if alpha <= 0 or native_order < 1:
        raise ValueError('Positive valuation and native order are required.')
    return alpha * native_order


class ExactChecks(unittest.TestCase):
    def test_fractional_part_coarse_false_bound(self):
        for n in range(2, 101):
            x = Fraction(1, n)
            actual = frac_positive(1 - x)
            self.assertEqual(actual, 1 - x)
            self.assertEqual(actual / x, n - 1)

    def test_fractional_part_retained_false_bound(self):
        for n in range(2, 101):
            x = Fraction(1, n)
            actual, reported = frac_positive(1 - x), -x
            self.assertEqual(actual - reported, 1)
            self.assertEqual((actual - reported) / x**2, n*n)

    def test_fractional_part_valid_controls(self):
        for n in range(3, 80):
            x = Fraction(1, n)
            self.assertEqual(frac_positive(1 + x), x)
            self.assertEqual(frac_positive(Fraction(1, 2) + x), Fraction(1, 2) + x)
        self.assertEqual(frac_positive(Fraction(1)), 0)

    def test_native_short_jet_tail_cannot_be_upgraded(self):
        # The analytic polynomial q(v)=v-v^3/6 has the truthful coarse jet v+O(v^2).
        # Replacing its unknown coefficients by zero and claiming O(v^5) is false.
        for n in range(2, 101):
            x = Fraction(1, n)
            true_value, reported = x - x**3 / 6, x
            self.assertEqual((true_value - reported) / x**5, -Fraction(n*n, 6))

    def test_composition_native_order_transport(self):
        for numerator in range(1, 8):
            for denominator in range(1, 6):
                a = Fraction(numerator, denominator)
                self.assertEqual(compose_order(a, 2), 2*a)
                self.assertEqual(compose_order(a, 5), 5*a)
                self.assertLess(compose_order(a, 2), compose_order(a, 5))

    def test_logarithmic_order_transport(self):
        # v = w^alpha (log w)^d; an O(v^m) tail has power alpha*m, degree d*m.
        for a in [Fraction(1, 2), Fraction(1), Fraction(3, 2)]:
            for d in range(5):
                for m in range(1, 6):
                    self.assertEqual((a*m, d*m), (compose_order(a, m), d*m))

    def test_backend_order_difference(self):
        coefficients = [Fraction(1), Fraction(1), Fraction(1, 2)]
        package_exclusive = coefficients[:2]
        native_inclusive = coefficients[:3]
        self.assertEqual(len(package_exclusive), 2)
        self.assertEqual(native_inclusive[-1], Fraction(1, 2))

    def test_zero_derivative_cutoff(self):
        rows = [(Fraction(1), Fraction(1))]
        trimmed = [row for row in rows if row[0] < 1]
        self.assertEqual(trimmed, [])
        self.assertNotEqual(trimmed, rows)


class PatchFixtures(unittest.TestCase):
    def fixture(self):
        sources: dict[str, str] = {}
        for edit in SPEC['edits']:
            sources[edit['path']] = sources.get(edit['path'], '') + edit['old'] + '\n'
        return sources

    def test_exact_anchors(self):
        source = self.fixture()
        result = transform(source, SPEC)
        for edit in SPEC['edits']:
            self.assertIn(edit['new'], result[edit['path']])
        self.assertIn('Automatic, ReleaseHold', source['src/Kernel/NativeCompatibility.wl'])

    def test_missing_anchor(self):
        source = self.fixture()
        source['src/Kernel/NativeCompatibility.wl'] = 'changed source'
        with self.assertRaises(ValueError):
            transform(source, SPEC)

    def test_duplicate_anchor(self):
        source = self.fixture()
        first = SPEC['edits'][0]
        source[first['path']] += first['old']
        with self.assertRaises(ValueError):
            transform(source, SPEC)

    def test_missing_file(self):
        source = self.fixture()
        del source['src/Kernel/SeriesOperations.wl']
        with self.assertRaises(ValueError):
            transform(source, SPEC)

    def test_second_application_rejected(self):
        patched = transform(self.fixture(), SPEC)
        with self.assertRaises(ValueError):
            transform(patched, SPEC)

    def test_failure_is_nonmutating(self):
        source = self.fixture()
        before = dict(source)
        broken = dict(SPEC, edits=SPEC['edits'] + [dict(SPEC['edits'][0], old='not present')])
        with self.assertRaises(ValueError):
            transform(source, broken)
        self.assertEqual(source, before)


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    output = HERE.parent / 'evidence' / 'independent_checks.json'
    output.write_text(json.dumps({
        'scope': 'Exact rational mathematical models and synthetic source-anchor fixtures; not native package tests',
        'python': sys.version.split()[0], 'test_methods': result.testsRun,
        'failures': len(result.failures), 'errors': len(result.errors),
        'success': result.wasSuccessful()}, indent=2) + '\n', encoding='utf-8')
    raise SystemExit(0 if result.wasSuccessful() else 1)
