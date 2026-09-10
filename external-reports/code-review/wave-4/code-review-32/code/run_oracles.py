"""Run independent exact/mathematical checks and write a scoped evidence report."""
from __future__ import annotations
import argparse
from fractions import Fraction as F
import json
import platform
from pathlib import Path
import random
import time
import unittest
import sympy as sp
import mpmath as mp
from reference_algorithms import (
    SparsePolynomial, sparse_rules_from_sympy, polynomial_eventual_certificate,
    affine_interval_truth, seven_radius_witness, terminating_hypergeometric,
    wolfram_productlog_to_sympy, unevaluated_productlog_roundtrip,
    demonstrate_aba, validate_timeout,
)


class Oracles(unittest.TestCase):
    def test_sparse_zero_and_constant(self):
        self.assertEqual(SparsePolynomial.from_mapping({}).coefficient_rules(), ())
        self.assertEqual(SparsePolynomial.from_mapping({0: 7}).coefficient_rules(), (((0,), F(7)),))

    def test_sparse_duplicate_cancellation(self):
        p = SparsePolynomial.from_pairs([(3, 1), (3, -1), (2, F(5, 7))])
        self.assertEqual(p.terms, ((2, F(5, 7)),))

    def test_sparse_gap_hundred_million(self):
        p = SparsePolynomial.from_mapping({0: 1, 100_000_000: 1})
        self.assertEqual(len(p.terms), 2)
        self.assertEqual(p.derivative().terms, ((99_999_999, F(100_000_000)),))

    def test_sympy_sparse_gap(self):
        x = sp.Symbol('x')
        rules = sparse_rules_from_sympy(1 + x**100_000_000, x)
        self.assertEqual(rules, (((100_000_000,), 1), ((0,), 1)))

    def test_sympy_symbolic_coefficients(self):
        x, a = sp.symbols('x a')
        self.assertEqual(sparse_rules_from_sympy(a*x**5 + (1-a)*x + 2, x),
                         (((5,), a), ((1,), 1-a), ((0,), 2)))

    def test_nonpolynomial_refusal(self):
        x = sp.Symbol('x')
        for e in [1/x, sp.sin(x), x**sp.Rational(1, 2)]:
            with self.assertRaises(ValueError):
                sparse_rules_from_sympy(e, x)

    def test_sparse_random_low_degree_against_sympy(self):
        rng = random.Random(5092026)
        x = sp.Symbol('x')
        for _ in range(100):
            pairs = [(rng.randrange(30), F(rng.randrange(-9, 10), rng.randrange(1, 8)))
                     for _ in range(12)]
            p = SparsePolynomial.from_pairs(pairs)
            expression = sum(sp.Rational(c.numerator, c.denominator)*x**i for i, c in pairs)
            expected = sp.Poly(expression, x).as_dict()  # degree <= 29 only
            actual = {d: sp.Rational(c.numerator, c.denominator)
                      for d, c in p.coefficient_rules()}
            self.assertEqual(actual, expected)

    def test_sparse_product_and_budget(self):
        p = SparsePolynomial.from_mapping({0: 1, 1_000_000: 1})
        self.assertEqual(p.multiply(p).terms,
                         ((0, F(1)), (1_000_000, F(2)), (2_000_000, F(1))))
        with self.assertRaises(ValueError):
            p.multiply(p, max_pairs=3)

    def test_narrow_neighborhood_missed_by_seven_trials(self):
        self.assertIsNone(seven_radius_witness(F(1, 1000), -1, '>'))
        self.assertEqual(seven_radius_witness(1, -1, '>'), F(1))

    def test_crossing_is_unknown_not_false(self):
        self.assertIsNone(affine_interval_truth(F(1, 1000), -1, F(1, 64), '>'))

    def test_affine_constructive_radius(self):
        p = SparsePolynomial.from_mapping({0: F(1, 1000), 1: -1})
        c = polynomial_eventual_certificate(p)
        self.assertEqual(c.radius, F(1, 4000))
        self.assertTrue(c.truth('>'))
        self.assertTrue(c.verify_majorant())

    def test_affine_arbitrarily_small_margin(self):
        for power in (1, 20, 200, 1000):
            p = SparsePolynomial.from_mapping({0: F(1, 2**power), 1: -1})
            c = polynomial_eventual_certificate(p)
            self.assertEqual(c.radius, F(1, 2**(power+2)))
            self.assertTrue(c.verify_majorant())

    def test_zero_and_linear_certificates(self):
        for b in (-3, 0, 5):
            p = SparsePolynomial.from_mapping({1: b})
            c = polynomial_eventual_certificate(p)
            self.assertEqual(c.sign, (b > 0) - (b < 0))
            self.assertTrue(c.verify_majorant())
            self.assertEqual(c.truth('=='), b == 0)

    def test_polynomial_radius_exact_400_cases(self):
        rng = random.Random(8302026)
        for _ in range(400):
            p = SparsePolynomial.from_pairs((rng.randrange(18), F(rng.randrange(-6, 7), rng.randrange(1, 7)))
                                             for _ in range(8))
            c = polynomial_eventual_certificate(p)
            self.assertTrue(c.verify_majorant())
            for fraction in (F(1, 2), F(1, 3), F(99, 100)):
                v = p.evaluate(c.radius * fraction)
                self.assertEqual((v > 0) - (v < 0), c.sign)

    def test_fixed_interval_cannot_be_replaced_by_eventual_claim(self):
        c = polynomial_eventual_certificate(SparsePolynomial.from_mapping({0: 1, 1: -1000}))
        self.assertTrue(c.truth('>'))
        self.assertLess(c.radius, F(1, 1000))
        self.assertIsNone(affine_interval_truth(1, -1000, 1, '>'))

    def test_parameter_inverse_coefficients(self):
        a, y = sp.symbols('a y', positive=True)
        g = sum((-1)**n * sp.binomial(3*n, n) * y**(2*n+1) /
                ((2*n+1)*a**(3*n+1)) for n in range(5))
        expected = y/a - y**3/a**4 + 3*y**5/a**7 - 12*y**7/a**10 + 55*y**9/a**13
        self.assertEqual(sp.expand(g-expected), 0)
        residual = sp.Poly(sp.expand(a*g+g**3-y), y)
        self.assertTrue(all(residual.coeff_monomial(y**n) == 0 for n in range(11)))

    def test_parameter_domain_derivative(self):
        a, x = sp.symbols('a x', positive=True)
        self.assertTrue(sp.ask(sp.Q.positive(a+3*x**2)))
        a = sp.Symbol('a', positive=True)
        x = sp.Symbol('x', real=True)
        self.assertTrue(sp.ask(sp.Q.positive(a+3*x**2)))

    def test_terminating_3f1_polynomial(self):
        p = terminating_hypergeometric([-2, 3, 4], [5])
        self.assertEqual(p.terms, ((0, F(1)), (1, F(-24, 5)), (2, F(8))))
        z = sp.Symbol('z')
        self.assertEqual(sp.expand(sp.hyperexpand(sp.hyper([-2, 3, 4], [5], z)) -
                                   (1-sp.Rational(24, 5)*z+8*z*z)), 0)

    def test_terminating_scaled_monomial(self):
        p = terminating_hypergeometric([-2, 3, 4], [5], argument_coefficient=2, argument_degree=3)
        self.assertEqual(p.terms, ((0, F(1)), (3, F(-48, 5)), (6, F(32))))

    def test_terminating_zero_and_earliest_stop(self):
        self.assertEqual(terminating_hypergeometric([0, 3], [2]).terms, ((0, F(1)),))
        self.assertEqual(terminating_hypergeometric([-8, -2, 3], [4]).degree, 2)

    def test_terminating_refusals(self):
        for args in [([2, 3], [5]), ([-2, 3], [0]), ([-2, 3], [-4])]:
            with self.assertRaises(ValueError):
                terminating_hypergeometric(*args)
        with self.assertRaises(ValueError):
            terminating_hypergeometric([-100], [1], max_terms=10)

    def test_productlog_principal_argument_order(self):
        self.assertEqual(wolfram_productlog_to_sympy(0, sp.E), 1)
        self.assertEqual(sp.LambertW(0, sp.E), -sp.oo)

    def test_productlog_minus_one_argument_order(self):
        self.assertEqual(wolfram_productlog_to_sympy(-1, -2/sp.E**2), -2)
        swapped = sp.LambertW(-1, -2/sp.E**2).evalf(40)
        self.assertNotEqual(sp.im(swapped), 0)

    def test_productlog_symbolic_roundtrip(self):
        z = sp.Symbol('z')
        for branch in (-3, -1, 0, 2):
            self.assertEqual(unevaluated_productlog_roundtrip(branch, z), (branch, z))

    def test_productlog_fixed_point_correct_numeric_bridge(self):
        with mp.workdps(60):
            for z in (mp.mpf('-0.1'), -2/mp.e**2, mp.mpf('-0.00001')):
                w = mp.lambertw(z, -1)
                self.assertLess(abs(w*mp.exp(w)-z), mp.mpf('1e-58'))
                self.assertLessEqual(w, -1)

    def test_aba_countermodel(self):
        self.assertEqual(demonstrate_aba(), {'BeforeAfterEqual': True,
                         'ReadBytesDifferedFromInitialBytes': True})

    def test_timeout_finite_guard(self):
        for value in [float('nan'), float('inf'), -float('inf'), 0, -1]:
            with self.assertRaises(ValueError):
                validate_timeout(value)
        self.assertEqual(validate_timeout(0.01), 0.01)
        self.assertFalse(float('nan') <= 0)  # current runner's narrow check
        self.assertFalse(float('inf') <= 0)


class RecordingResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.records = []
    def addSuccess(self, test):
        super().addSuccess(test)
        self.records.append({'TestID': test.id().split('.')[-1], 'Outcome': 'Success'})
    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.records.append({'TestID': test.id().split('.')[-1], 'Outcome': 'Failure'})
    def addError(self, test, err):
        super().addError(test, err)
        self.records.append({'TestID': test.id().split('.')[-1], 'Outcome': 'Error'})


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1]/'evidence/oracle-results.json')
    args = parser.parse_args()
    started = time.monotonic()
    result = unittest.TextTestRunner(verbosity=2, resultclass=RecordingResult).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(Oracles))
    report = {
        'Scope': 'Independent reference algorithms and mathematical/receipt countermodels; NOT AsymptoticAnalysis or Mathics execution',
        'RepositoryRevisionUnderReview': '513917b5b387152256b14ac76d92dd30cd13a11d',
        'PythonVersion': platform.python_version(), 'SymPyVersion': sp.__version__,
        'mpmathVersion': mp.__version__, 'PackageTestsRun': False, 'MathicsRun': False,
        'WolframKernelRun': False, 'TestsRun': result.testsRun,
        'Failures': len(result.failures), 'Errors': len(result.errors),
        'ElapsedSeconds': round(time.monotonic()-started, 4), 'Results': result.records,
        'AdditionalParameterizedWork': {'SparsePolynomialOracleCases': 100, 'PolynomialRadiusCases': 400,
                                        'InteriorEvaluationsPerRadiusCase': 3},
        'BridgeCountermodels': {
            'CorrectProductLog0E': '1', 'IncorrectUnreorderedSymPyCall': str(sp.LambertW(0, sp.E)),
            'CorrectCoreAtExp2Over2': '2',
            'SwappedSymPyCoreEvaluatedIndependently': str(-sp.LambertW(-1, -2/sp.E**2).evalf(30)),
            'Warning': 'The last value is SymPy evalf, NOT an observed Mathics or package output'},
        'SparseRepresentationCounts': [
            {'LargestDegree': d, 'DensePositions': d+1, 'RetainedSparseTerms': 2}
            for d in (100, 10_000, 1_000_000, 100_000_000)],
        'ABA': demonstrate_aba(),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(f'Evidence: {args.output}')
    return 0 if result.wasSuccessful() else 1

if __name__ == '__main__':
    raise SystemExit(main())
