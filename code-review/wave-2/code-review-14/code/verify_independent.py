#!/usr/bin/env python3
"""Exact, independent models for the incremental audit. Not a WL emulator.
Python 3.10+, standard library only. Run from any directory.
"""
from __future__ import annotations
import argparse
import json
import random
import sys
import unittest
from decimal import Decimal, localcontext
from fractions import Fraction as F
from pathlib import Path

Interval = tuple[F, F]
COUNTS = {"random_affine_cases": 0, "random_rounding_cases": 0,
          "parameter_curve_cases": 0, "zeta_tail_cases": 0}


def two(e: int) -> F:
    return F(2**e) if e >= 0 else F(1, 2**(-e))


def floor_log2(q: F) -> int:
    if q <= 0:
        raise ValueError("positive rational required")
    e = q.numerator.bit_length() - q.denominator.bit_length()
    return e - 1 if q < two(e) else e


def round_directed(q: F, bits: int, upper: bool) -> F:
    """Exact analogue of certRound; no floating-point decisions."""
    if bits < 2:
        raise ValueError("at least two significant bits required")
    q = F(q)
    if not q:
        return q
    grid = two(floor_log2(abs(q)) - bits + 1)
    ratio = q / grid
    k = (-((-ratio.numerator) // ratio.denominator) if upper
         else ratio.numerator // ratio.denominator)
    return grid * k


def outward(a: Interval, bits: int) -> Interval:
    if a[0] > a[1]:
        raise ValueError("unordered interval")
    return round_directed(a[0], bits, False), round_directed(a[1], bits, True)


def add(a: Interval, b: Interval, bits: int) -> Interval:
    return outward((a[0] + b[0], a[1] + b[1]), bits)


def old_affine_fold(constant: F, interval: Interval, bits: int) -> Interval:
    """The constant-first Plus fold for x + constant."""
    constant_interval = add((F(0), F(0)), (constant, constant), bits)
    return add(constant_interval, interval, bits)


def affine_enclose(slope: F, constant: F, interval: Interval, bits: int) -> Interval:
    """Proposed exact affine cancellation, followed by ONE outward rounding."""
    ends = sorted((slope * interval[0] + constant,
                   slope * interval[1] + constant))
    return outward((ends[0], ends[1]), bits)


def zeta_bound(m: int, s: int) -> F:
    if m < 1 or s <= 1:
        raise ValueError("m >= 1 and s > 1 required")
    return F(1, m**s) * (1 + F(m, s-1))


def zeta_enclosure(m: int, s: int, last: int = 100) -> Interval:
    partial = sum((F(1, n**s) for n in range(m, last+1)), F(0))
    # Integral from last+1 bounds the tail below; from last bounds it above.
    return (partial + F(1, (s-1)*(last+1)**(s-1)),
            partial + F(1, (s-1)*last**(s-1)))


def convolution(a: list[F], b: list[F]) -> list[F]:
    result = [F(0)] * (len(a)+len(b)-1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            result[i+j] += x*y
    return result


class ParameterScopeTests(unittest.TestCase):
    def test_diagonal_is_one_half(self):
        for a in (F(1, 10), F(1, 100), F(1, 10000)):
            self.assertEqual(1/(1+a/a), F(1, 2))

    def test_predicted_remainder_ratio_diverges(self):
        ratios = [abs(F(1, 2)-1)/a for a in (F(1, 10), F(1, 100), F(1, 1000))]
        self.assertEqual(ratios, [5, 50, 500])

    def test_fixed_parameter_bound_is_valid(self):
        for a in (F(1, 7), F(2), F(100)):
            for x in (F(1, 100), F(1, 1000)):
                self.assertLessEqual(abs(1/(1+x/a)-1), x/a)

    def test_power_curves_change_the_error_exponent(self):
        for alpha in range(1, 5):
            for beta in range(1, 5):
                t = F(1, 1000)
                x, a = t**alpha, t**beta
                self.assertEqual(1/(1+x/a)-1, -t**(alpha-beta)/(1+t**(alpha-beta)))
                COUNTS["parameter_curve_cases"] += 1

    def test_hidden_parameter_in_a_discarded_coefficient(self):
        a = F(1, 1000)
        # The retained constant is 1, independent of a; the exact error is not.
        self.assertEqual(1/(1+a/a)-1, F(-1, 2))

    def test_second_diagonal_witness(self):
        a = F(1, 100)
        self.assertEqual(1/(a+a)-1/a, -1/(2*a))


class IntervalTests(unittest.TestCase):
    def test_binary_exponents(self):
        for e in range(-30, 31):
            self.assertEqual(floor_log2(two(e)), e)
            self.assertEqual(floor_log2(3*two(e)/2), e)

    def test_directed_rounding_random(self):
        rng = random.Random(20260909)
        for _ in range(500):
            q = F(rng.randint(-10**10, 10**10), rng.randint(1, 10**7))
            bits = rng.randint(2, 80)
            lo, hi = outward((q, q), bits)
            self.assertLessEqual(lo, q)
            self.assertGreaterEqual(hi, q)
            COUNTS["random_rounding_cases"] += 1

    def test_exact_dyadic_points(self):
        self.assertEqual(outward((F(3,2), F(3,2)), 20), (F(3,2), F(3,2)))

    def test_large_translation_loses_zero_residual(self):
        A = F(2**10000+1)
        center = A+F(1,2)
        for bits in (48, 280, 8040):
            old = old_affine_fold(-center, (center, center), bits)
            self.assertLess(old[0], -F(1,4))
            self.assertGreater(old[1], F(1,4))
            self.assertLessEqual(old[0], 0)
            self.assertGreaterEqual(old[1], 0)

    def test_large_translation_endpoint_signs_do_not_bracket(self):
        A = F(2**10000+1)
        for point in (A+F(1,4), A+F(3,4)):
            old = old_affine_fold(-(A+F(1,2)), (point,point), 8040)
            self.assertLess(old[0], 0)
            self.assertGreater(old[1], 0)

    def test_affine_fix_recovers_exact_residual(self):
        A = F(2**10000+1)
        center = A+F(1,2)
        self.assertEqual(affine_enclose(F(1), -center, (center,center), 48), (F(0),F(0)))

    def test_affine_fix_recovers_endpoint_signs(self):
        A = F(2**10000+1)
        iv = (A+F(1,4), A+F(3,4))
        self.assertEqual(affine_enclose(F(1), -(A+F(1,2)), iv, 48), (F(-1,4),F(1,4)))

    def test_affine_enclosure_random(self):
        rng = random.Random(991)
        for _ in range(500):
            shift = F(rng.randint(-100,100))*two(rng.randint(0,1000))
            slope = F(rng.randint(-20,20), rng.randint(1,15))
            b = F(rng.randint(-10,10), rng.randint(1,13))
            l = F(rng.randint(-20,0),rng.randint(1,19))
            h = F(rng.randint(1,20),rng.randint(1,19))
            bits = rng.randint(10,100)
            shifted = affine_enclose(slope, b-slope*shift, (l+shift,h+shift), bits)
            centered = affine_enclose(slope, b, (l,h), bits)
            self.assertEqual(shifted, centered)
            exact = sorted((slope*l+b, slope*h+b))
            self.assertLessEqual(shifted[0],exact[0])
            self.assertGreaterEqual(shifted[1],exact[1])
            COUNTS["random_affine_cases"] += 1

    def test_maximum_bit_budget(self):
        self.assertEqual(4*(2000+10),8040)
        self.assertEqual(10000-8040+1,1961)


class NumericalCoordinateTests(unittest.TestCase):
    def test_original_coordinate_loses_local_root(self):
        with localcontext() as ctx:
            ctx.prec = 60
            A = Decimal(10)**100
            y = Decimal(1)/1000
            u = 2*y/(1+(1+4*y).sqrt())
            self.assertEqual(A+u, A)
            self.assertGreater(u, 0)

    def test_local_equation_is_well_resolved(self):
        with localcontext() as ctx:
            ctx.prec = 80
            y = Decimal(1)/1000
            u = 2*y/(1+(1+4*y).sqrt())
            self.assertLess(abs(u+u*u-y), Decimal('1e-78'))

    def test_retained_polynomial_error_is_nonzero_locally(self):
        with localcontext() as ctx:
            ctx.prec = 80
            y = Decimal(1)/1000
            root = 2*y/(1+(1+4*y).sqrt())
            approximation = y-y*y+2*y**3
            error = abs(root-approximation)
            self.assertGreater(error, Decimal('4.9e-12'))
            self.assertLess(error, Decimal('5e-12'))

    def test_reported_absolute_roots_can_coincide(self):
        with localcontext() as ctx:
            ctx.prec = 60
            A = Decimal(10)**100
            y = Decimal(1)/1000
            root = 2*y/(1+(1+4*y).sqrt())
            approximation = y-y*y+2*y**3
            self.assertNotEqual(root, approximation)
            self.assertEqual(A+root, A+approximation)


class QuantitativeBoundTests(unittest.TestCase):
    def test_zeta_tail_formula_encloses_tail(self):
        for s in range(2,8):
            for m in range(2,9):
                lo,hi = zeta_enclosure(m,s)
                self.assertLessEqual(F(1,m**s),lo)
                self.assertLessEqual(hi,zeta_bound(m,s))
                COUNTS["zeta_tail_cases"] += 1

    def test_truncation_transport_is_valid(self):
        for s in range(2,8):
            old_m,new_m = 6,3
            discarded = sum((F(1,n**s) for n in range(new_m,old_m)),F(0))
            transported = zeta_bound(old_m,s)+discarded
            _,hi = zeta_enclosure(new_m,s)
            self.assertLessEqual(hi,transported)

    def test_noop_keeps_same_bound(self):
        for s in range(2,8):
            self.assertEqual(zeta_bound(4,s)+abs(F(0)),zeta_bound(4,s))

    def test_general_triangle_transport(self):
        rng = random.Random(77)
        for _ in range(200):
            f,a,b = (F(rng.randint(-100,100),rng.randint(1,17)) for _ in range(3))
            B = abs(f-a)
            self.assertLessEqual(abs(f-b),B+abs(a-b))

    def test_negative_bounds_rejected_by_formula_inputs(self):
        with self.assertRaises(ValueError):
            zeta_bound(4,1)


class FourierOracleTests(unittest.TestCase):
    def test_quadratic_inverse_first_three_blocks(self):
        g = [F(0),F(1),F(-1),F(2)]
        square = convolution(g,g)
        residual = square[:]
        for i,c in enumerate(g):
            residual[i] += c
        residual[1] -= 1
        self.assertEqual(residual[:4],[0,0,0,0])
        self.assertEqual(residual[4],5)
        self.assertEqual(sum(c!=0 for c in g),3)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path,
        default=Path(__file__).resolve().parents[1]/'evidence'/'independent_results.json')
    args = parser.parse_args()
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    evidence = {
        "scope": "Independent exact rational/decimal mathematical models; not execution of the Wolfram package",
        "python_version": sys.version.split()[0],
        "tests_run": result.testsRun,
        "failures": len(result.failures), "errors": len(result.errors),
        "passed": result.wasSuccessful(), "subcases": COUNTS,
        "key_results": {
            "parameter_capture_exact_diagonal": "1/2",
            "parameter_capture_source_predicted_finite_part": "1",
            "certificate_max_bits": 8040,
            "large_shift": "2^10000+1",
            "maximum_order_initial_rounding_grid": "2^1961",
            "corrected_affine_center_residual": "[0,0]",
            "60_digit_source_sum_loses_1e_minus_3_displacement": True,
            "quadratic_inverse_through_y_cubed": "y-y^2+2y^3"
        },
        "native_wolfram_executed": False
    }
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
    return 0 if result.wasSuccessful() else 1

if __name__ == '__main__':
    raise SystemExit(main())
