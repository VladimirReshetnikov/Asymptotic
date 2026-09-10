"""Executed independent checks. None of these starts Mathics or Wolfram."""
import argparse
from dataclasses import replace
from fractions import Fraction as F
import json
import math
import os
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest

from bounded_process import positive_finite_timeout, run_bounded
from certified_entropy_inverse import certify, log_bounds
from exact_portability_prototypes import affine_eventual_radius, terminating_pfq_coefficients
from run_audit_probes import freeze_package


class ExactChecks(unittest.TestCase):
    def test_log_one(self):
        self.assertEqual(log_bounds(F(1)), (F(0), F(0)))

    def test_log_reciprocal(self):
        lo, hi = log_bounds(F(7, 3))
        il, ih = log_bounds(F(3, 7))
        self.assertLessEqual(lo+il, 0)
        self.assertGreaterEqual(hi+ih, 0)

    def test_log_four_proves_branch(self):
        self.assertGreater(log_bounds(F(4), 8)[0], 1)
        self.assertLess(log_bounds(F(4), 8)[1], 2)

    def test_log_bounds_external_numerical_check(self):
        import mpmath as mp
        with mp.workdps(100):
            for q in [F(1, 10**20), F(1, 3), F(7, 5), F(10**20), F(127, 64)]:
                lo, hi = log_bounds(q, 32)
                reference = mp.log(mp.mpf(q.numerator)/q.denominator)
                self.assertLessEqual(mp.mpf(lo.numerator)/lo.denominator, reference)
                self.assertGreaterEqual(mp.mpf(hi.numerator)/hi.denominator, reference)

    def test_certificate_four_targets(self):
        import mpmath as mp
        with mp.workdps(100):
            for y in [F(1, 4), F(1, 10), F(1, 100), F(1, 10**6)]:
                c = certify(y, 64)
                self.assertTrue(c.verify())
                yy = mp.mpf(y.numerator)/y.denominator
                reference = -yy/mp.lambertw(-yy, -1)
                self.assertLess(mp.mpf(c.lower.numerator)/c.lower.denominator, reference)
                self.assertGreater(mp.mpf(c.upper.numerator)/c.upper.denominator, reference)

    def test_reject_mutated_certificate(self):
        c = certify(F(1, 100), 40)
        self.assertFalse(replace(c, lower=c.upper+1).verify())
        self.assertFalse(replace(c, target=F(1, 10)).verify())
        self.assertFalse(replace(c, bits=400).verify())
        self.assertFalse(replace(c, target=.01).verify())
        self.assertFalse(replace(c, bits=True).verify())
        self.assertFalse(replace(c, logarithm_terms=0).verify())

    def test_reject_inexact_target(self):
        with self.assertRaises(TypeError):
            certify(0.01)

    def test_reject_out_of_domain(self):
        for y in [F(0), F(-1, 100), F(1, 3)]:
            with self.assertRaises(ValueError):
                certify(y)

    def test_affine_small_neighborhood(self):
        constraints = [(F(1,1000), -1, '>'), (0, 1, '>')]
        self.assertEqual(affine_eventual_radius(constraints), F(1,2000))
        # None of the seven fixed full intervals has the required property.
        self.assertTrue(all(F(1,2**j) > F(1,1000) for j in range(7)))

    def test_affine_zero_endpoint(self):
        self.assertEqual(affine_eventual_radius([(0,1,'>')]), F(1))
        self.assertIsNone(affine_eventual_radius([(0,-1,'>=')]))
        self.assertEqual(affine_eventual_radius([(0,0,'>=')]), F(1))

    def test_affine_equal_unequal(self):
        self.assertEqual(affine_eventual_radius([(0,0,'=='),(-1,2,'!=')]), F(1,4))
        self.assertIsNone(affine_eventual_radius([(0,1,'==')]))
        self.assertIsNone(affine_eventual_radius([(0,0,'!=')]))

    def test_terminating_pfq(self):
        self.assertEqual(terminating_pfq_coefficients([-2,3,5],[7]), (F(1),F(-30,7),F(45,7)))
        self.assertEqual(terminating_pfq_coefficients([0,3,5],[7]), (F(1),))

    def test_terminating_pfq_multiple_terminators(self):
        self.assertEqual(len(terminating_pfq_coefficients([-8,-2,3],[7])), 3)

    def test_terminating_pfq_budget_and_poles(self):
        with self.assertRaises(ValueError):
            terminating_pfq_coefficients([-20],[1], max_terms=3)
        with self.assertRaises(ValueError):
            terminating_pfq_coefficients([-2],[0])
        with self.assertRaises(ValueError):
            terminating_pfq_coefficients([1],[2])


class RunnerChecks(unittest.TestCase):
    def test_finite_timeout(self):
        self.assertEqual(positive_finite_timeout('0.25'), .25)
        for invalid in ['nan','inf','-inf','0','-1','no']:
            with self.assertRaises(argparse.ArgumentTypeError):
                positive_finite_timeout(invalid)

    def test_original_guard_admits_nonfinite(self):
        # Exact predicate used by the inspected runner, not an executed copy.
        self.assertFalse(float('nan') <= 0)
        self.assertFalse(float('inf') <= 0)

    def test_completed_process(self):
        r = run_bounded([sys.executable,'-c','print("ok")'], timeout=2)
        self.assertEqual((r.outcome,r.returncode,r.output), ('Completed',0,'ok\n'))

    def test_nonzero_exit_preserved(self):
        r = run_bounded([sys.executable,'-c','raise SystemExit(7)'], timeout=2)
        self.assertEqual((r.outcome,r.returncode), ('Completed',7))

    def test_timeout(self):
        r = run_bounded([sys.executable,'-c','import time;time.sleep(2)'], timeout=.1)
        self.assertEqual(r.outcome,'Timeout')

    def test_bounded_transcript(self):
        r = run_bounded([sys.executable,'-c','import sys;sys.stdout.write("x"*2000000)'],
                        timeout=3, max_output_bytes=16384)
        self.assertEqual(r.outcome,'OutputLimit')
        self.assertEqual(r.retained_bytes,16384)
        self.assertGreater(r.observed_bytes,r.retained_bytes)

    def test_utf8(self):
        r = run_bounded([sys.executable,'-c','print("lambda: \\u03bb")'], timeout=2)
        self.assertEqual(r.output,'lambda: λ\n')

    def test_launch_error(self):
        r = run_bounded(['/this/executable/does/not/exist'], timeout=1)
        self.assertEqual(r.outcome,'LaunchError')


    def test_git_snapshot_ignores_worktree(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)/'repo'; root.mkdir()
            def git(*args):
                return subprocess.check_output(['git','-C',str(root),*args], stderr=subprocess.STDOUT)
            git('init','-q'); git('config','user.name','Synthetic Test')
            git('config','user.email','test@example.invalid')
            kernel=root/'src'/'Kernel'; kernel.mkdir(parents=True)
            entry=kernel/'AsymptoticAnalysis.wl'; entry.write_text('original entry',encoding='utf-8')
            (kernel/'Helper.wl').write_text('original helper',encoding='utf-8')
            (root/'AsymptoticAnalysis.wl').write_text('original standalone',encoding='utf-8')
            git('add','.'); git('commit','-qm','synthetic fixture')
            commit=git('rev-parse','HEAD').decode().strip()
            entry.write_text('changed worktree',encoding='utf-8')
            (kernel/'Helper.wl').unlink()
            frozen=freeze_package(root,Path(d)/'frozen',commit,'modular')
            self.assertEqual(frozen.read_text(),'original entry')
            self.assertEqual(frozen.with_name('Helper.wl').read_text(),'original helper')
            standalone=freeze_package(root,Path(d)/'single',commit,'standalone')
            self.assertEqual(standalone.read_text(),'original standalone')
            self.assertEqual(entry.read_text(),'changed worktree')

    def test_git_snapshot_rejects_invalid_selector(self):
        with tempfile.TemporaryDirectory() as d:
            for commit,entry in [('main','modular'),('a'*40,'unknown')]:
                with self.assertRaises(ValueError):
                    freeze_package(Path(d),Path(d)/'out',commit,entry)

    def test_edit_and_revert_counterexample(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'source.wl'
            p.write_bytes(b'original')
            before=p.read_bytes()
            p.write_bytes(b'changed')
            consumed=p.read_bytes()
            p.write_bytes(before)
            after=p.read_bytes()
            self.assertEqual(before,after)
            self.assertNotEqual(before,consumed)


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    output = Path(__file__).resolve().parents[1]/'evidence'/'independent-checks.json'
    output.write_text(json.dumps({
        'Python':sys.version, 'Platform':sys.platform,
        'TestsRun':result.testsRun, 'Failures':len(result.failures), 'Errors':len(result.errors),
        'MathicsExecuted':False, 'WolframExecuted':False,
        'Scope':'Independent rational arithmetic, mathematical countermodels and synthetic child processes',
        'Successful':result.wasSuccessful(),
    },indent=2)+'\n',encoding='utf-8')
    raise SystemExit(0 if result.wasSuccessful() else 1)
