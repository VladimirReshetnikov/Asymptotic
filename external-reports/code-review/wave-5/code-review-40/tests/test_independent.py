"""Independent mathematical and patch-anchor checks; no upstream kernel runs."""
from __future__ import annotations
import json
from pathlib import Path
import sys
import unittest
import sympy as sp
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "code"))
from modulus_jet import modulus_jet
from stage_patch import transform_sources, CORE, OPERATIONS, ABS_OLD, ABS_NEW, OBS_OLD, OBS_NEW
u = sp.Symbol("u", positive=True)
t = sp.Symbol("t", positive=True)

class IndependentChecks(unittest.TestCase):
    def test_conjugate_pair_coefficient_family(self):
        for a in (sp.Rational(1, 2), sp.Integer(1), sp.Integer(3)):
            for b in (sp.Integer(-2), sp.Rational(1, 3), sp.Integer(1)):
                for n in (1, 2, 3):
                    actual = 2 * sp.sqrt(a*a + b*b*u**(2*n))
                    series = sp.series(actual, u, 0, 2*n+2).removeO()
                    self.assertEqual(sp.expand(series).coeff(u, 2*n), b*b/a)
                    self.assertNotEqual(b*b/a, 0)
    def test_exact_unit_counterexample(self):
        self.assertEqual(sp.series(2*sp.sqrt(1+u*u), u, 0, 8),
                         2+u*u-u**4/4+u**6/8+sp.Order(u**8))
    def test_logarithmic_counterexample(self):
        self.assertEqual(sp.limit(t*(2*sp.sqrt(t*t+1)-2*t), t, sp.oo), 1)
        for n in (1, 2, 3):
            self.assertEqual(sp.limit(sp.exp(n*t)/t, t, sp.oo), sp.oo)
    def test_derivative_witness_identities(self):
        r = u**4*sp.sin(1/u)
        self.assertEqual(sp.simplify(sp.diff(r,u) - (4*u**3*sp.sin(1/u)-u**2*sp.cos(1/u))), 0)
        self.assertEqual(sp.simplify(sp.diff(r,u,2) - (12*u*u*sp.sin(1/u)-6*u*sp.cos(1/u)-sp.sin(1/u))), 0)
    def test_derivative_zero_is_simple(self):
        second = 12*u*u*sp.sin(1/u)-6*u*sp.cos(1/u)-sp.sin(1/u)
        at_zero = second.subs(sp.cos(1/u), 4*u*sp.sin(1/u))
        self.assertEqual(sp.simplify(at_zero + (1+12*u*u)*sp.sin(1/u)), 0)
    def test_oscillatory_zero_brackets(self):
        for n in range(1, 31):
            left = -n*sp.pi*(-1)**n
            right = 4*(-1)**n
            self.assertTrue((left*right).is_negative)
    def test_exact_fourier_source_derivatives(self):
        f = u + u*u*sp.sin(sp.log(u))
        self.assertEqual(sp.simplify(sp.diff(f,u)-(1+u*(2*sp.sin(sp.log(u))+sp.cos(sp.log(u))))),0)
        self.assertEqual(sp.simplify(sp.diff(f,u,2)-(sp.sin(sp.log(u))+3*sp.cos(sp.log(u)))),0)
    def test_exact_fourier_source_simple_zeros(self):
        theta = -sp.atan(sp.Rational(1,2))
        for n in range(12):
            phase = theta - n*sp.pi
            sine, cosine = sp.simplify(sp.sin(phase)), sp.simplify(sp.cos(phase))
            self.assertEqual(sp.simplify(2*sine+cosine),0)
            self.assertEqual(sp.simplify((sine+3*cosine)**2),5)
    def test_log_periodic_derivative_contract_all_fixed_orders(self):
        a,b=sp.Integer(1),sp.Integer(0)
        remainder=u*u*sp.sin(sp.log(u))
        for k in range(7):
            expected=u**(2-k)*(a*sp.sin(sp.log(u))+b*sp.cos(sp.log(u)))
            self.assertEqual(sp.simplify(sp.diff(remainder,u,k)-expected),0)
            a,b=(2-k)*a-b,a+(2-k)*b
    def test_modulus_reference_basic(self):
        out = modulus_jet({0:1, 1:sp.I}, 6)
        self.assertEqual(sp.expand(out.expression(u)), 1+u*u/2-u**4/8)
        self.assertEqual(out.error_power, 6)
        self.assertEqual(out.derivative_order, 0)
    def test_modulus_reference_negative_and_imaginary_leading(self):
        for c in (-2, sp.I, -3*sp.I, 1+sp.I):
            out = modulus_jet({0:c}, 4)
            self.assertEqual(out.rows, ((0,sp.sqrt(sp.expand(c*sp.conjugate(c)))),))
    def test_modulus_reference_norm_square_residual_family(self):
        for a in (-2, 1, 1+sp.I):
            for b in (sp.I, 1-sp.I, sp.Rational(1,2)):
                for alpha in (-2, 0, 3):
                    h = alpha+6
                    out = modulus_jet({alpha:a, alpha+1:b, alpha+3:sp.I}, h)
                    source = a*u**alpha+b*u**(alpha+1)+sp.I*u**(alpha+3)
                    residual = sp.expand((out.expression(u)**2-source*sp.conjugate(source))/u**(2*alpha))
                    for k in range(6):
                        self.assertEqual(sp.simplify(residual.coeff(u,k)),0)
    def test_modulus_precision_cap(self):
        out = modulus_jet({0:1, 1:sp.I}, 9, input_error_power=3)
        self.assertEqual(out.error_power,3)
        self.assertEqual(out.expression(u), 1+u*u/2)
    def test_modulus_empty_and_truncated_leading(self):
        self.assertEqual(modulus_jet({},3,input_error_power=2).error_power,2)
        out = modulus_jet({5:sp.I},3)
        self.assertEqual(out.rows,())
        self.assertEqual(out.error_power,5)
    def test_modulus_refuses_invalid_input(self):
        for args in (({0:sp.Float(1)},4), ({sp.Rational(1,2):1},4), ({0:sp.Symbol('a')},4)):
            with self.assertRaises((ValueError,TypeError)):
                modulus_jet(*args)
        with self.assertRaises(ValueError):
            modulus_jet({2:1},5,input_error_power=2)
    def test_modulus_budgets(self):
        with self.assertRaises(ValueError):
            modulus_jet({0:1},100,max_order=10)
        with self.assertRaises(ValueError):
            modulus_jet({0:1,1:sp.I,2:1},8,max_pairs=2)
    def test_patch_exact_anchors(self):
        fixture={CORE:"prefix\n"+ABS_OLD+"\nsuffix", OPERATIONS:"prefix\n"+OBS_OLD+"\nsuffix"}
        out=transform_sources(fixture)
        self.assertIn(ABS_NEW,out[CORE])
        self.assertIn(OBS_NEW,out[OPERATIONS])
        self.assertIn(ABS_OLD,fixture[CORE])
    def test_patch_rejects_missing_duplicated_and_reapplication(self):
        good={CORE:ABS_OLD,OPERATIONS:OBS_OLD}
        for fixture in ({}, {CORE:ABS_OLD,OPERATIONS:""}, {CORE:ABS_OLD*2,OPERATIONS:OBS_OLD},
                        transform_sources(good)):
            with self.assertRaises(ValueError):
                transform_sources(fixture)

if __name__ == "__main__":
    suite=unittest.defaultTestLoader.loadTestsFromTestCase(IndependentChecks)
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    receipt={"scope":"Independent SymPy mathematics, reference modulus algorithm, exact-anchor patch fixtures",
             "upstream_wolfram_tests_executed":False,"native_package_observations":[],
             "tests_run":result.testsRun,"failures":len(result.failures),"errors":len(result.errors),
             "successful":result.wasSuccessful(),"python":sys.version.split()[0],"sympy":sp.__version__,
             "parameterized_controls":{"conjugate_pairs":27,"norm_square_cases":27,"zero_brackets":30,"exact_fourier_cusp_phases":12,"log_periodic_derivative_orders":7},
             "source_revision":"651f2029d0b2cd4da9e4dfdf1f4275a124d23b99"}
    (ROOT/"evidence"/"independent_checks.json").write_text(json.dumps(receipt,indent=2)+"\n")
    raise SystemExit(0 if result.wasSuccessful() else 1)
