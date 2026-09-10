"""Focused tests using fake kernels; neither Mathics nor Wolfram is executed.

Both the byte-verified upstream runner and the patch candidate are exercised.
Temporary files and only the subprocesses launched by these tests are modified.
"""
from __future__ import annotations
import hashlib, importlib.util, json, os, signal, subprocess, sys, tempfile, time, unittest
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
OBSERVATIONS = []


def load_module(path):
    spec = importlib.util.spec_from_file_location('audit_runner_' + path.stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class HarnessTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='audit-harness-')
        self.root = Path(self.tmp.name)
        self.val = self.root / 'validation'
        self.val.mkdir()
        self.kernel = self.root / 'src' / 'Kernel'
        self.kernel.mkdir(parents=True)
        self.source = self.kernel / 'AsymptoticAnalysis.wl'
        self.source.write_text('(* synthetic source: no package execution *)\n')
        self.suite = self.val / 'MathicsTests.wl'
        self.suite.write_text('portableTest["alpha", "basic", 1, 1];\nportableTest["beta", "basic", 1, 1];\n')
        self.fake = self.root / 'fake-kernel'
        self.fake.write_text('#!' + sys.executable + '\n' + '''
import os, time
from pathlib import Path
marker = os.environ.get("AUDIT_STARTED_MARKER")
if marker:
    Path(marker).write_text(str(os.getpid()))
time.sleep(60 if os.environ.get("AUDIT_WAIT") == "1" else 0.1)
p = "ASYMPTOTIC_PORTABLE_"
print(p+"KERNEL\\tAUDIT FAKE KERNEL; NOT MATHEMATICA OR MATHICS")
print(p+"ACTUAL_BEGIN\\nTrue\\n"+p+"ACTUAL_END")
print(p+"EXPECTED_BEGIN\\nTrue\\n"+p+"EXPECTED_END")
print(p+"RESULT\\t"+os.environ["ASYMPTOTIC_PORTABLE_CASE"]+"\\tSuccess")
''')
        self.fake.chmod(0o700)

    def tearDown(self):
        self.tmp.cleanup()

    def runner(self, patched=False):
        src = BASE / ('patches/run_mathics_tests_candidate.py' if patched else 'fixtures/run_mathics_tests.py')
        dest = self.val / ('patched.py' if patched else 'original.py')
        dest.write_bytes(src.read_bytes())
        return dest

    def command(self, patched=False, timeout='2'):
        out = self.root / ('patched.json' if patched else 'original.json')
        cmd = [sys.executable, str(self.runner(patched)), '--wolfram', str(self.fake),
               '--source', str(self.source), '--timeout', timeout, '--output', str(out)]
        return cmd, out

    def test_fixture_is_exact_retrieved_git_blob(self):
        b = (BASE / 'fixtures/run_mathics_tests.py').read_bytes()
        blob = hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\0' + b).hexdigest()
        self.assertEqual(blob, 'df59971aad4757130a5b6f826cf71d10961c525b')
        OBSERVATIONS.append({'Case': 'fixture-byte-identity', 'Verified': True, 'Bytes': len(b)})

    def test_finite_positive_control(self):
        for patched in (False, True):
            cmd, out = self.command(patched)
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=8)
            self.assertEqual(r.returncode, 0, r.stdout+r.stderr)
            d = json.loads(out.read_text())
            self.assertEqual((d['RunComplete'], d['Succeeded'], d['NotRun']), (True, 2, 0))
            OBSERVATIONS.append({'Case': 'finite-timeout-control', 'Patched': patched,
                                 'Succeeded': d['Succeeded'], 'FakeKernel': True})

    def test_nonfinite_timeouts(self):
        for value in ('nan', 'inf', '1e300'):
            for patched in (False, True):
                cmd, out = self.command(patched, value)
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=8)
                if patched:
                    self.assertEqual(r.returncode, 2)
                    self.assertIn('finite and positive', r.stderr)
                    self.assertFalse(out.exists())
                else:
                    self.assertNotEqual(r.returncode, 0)
                    self.assertTrue(out.exists())
                    self.assertIn('Traceback', r.stderr)
                    self.assertTrue('ValueError' in r.stderr or 'OverflowError' in r.stderr)
                OBSERVATIONS.append({'Case': 'nonfinite-timeout', 'Input': value,
                    'Patched': patched, 'ExitCode': r.returncode,
                    'ReportCreated': out.exists(), 'Output': r.stdout, 'Error': r.stderr})
                if out.exists(): out.unlink()

    def test_init_loader_dependency_coverage(self):
        loader = self.kernel / 'init.m'
        loader.write_text('Get[FileNameJoin[{DirectoryName[$InputFileName], "AsymptoticAnalysis.wl"}]];\n')
        for patched in (False, True):
            m = load_module(self.runner(patched))
            before = m.fingerprints(loader)
            self.source.write_text(self.source.read_text() + '(* changed child *)\n')
            after = m.fingerprints(loader)
            self.assertEqual(before == after, not patched)
            OBSERVATIONS.append({'Case': 'init-loader-source-change', 'Patched': patched,
                                 'ChangeDetected': before != after})

    def test_custom_dependency_roots(self):
        m = load_module(self.runner(True))
        loader = self.root / 'custom-loader.wl'
        loader.write_text('(* custom test loader *)')
        before = m.fingerprints(loader, (self.kernel,))
        self.source.write_text('(* modified dependency *)')
        self.assertNotEqual(before, m.fingerprints(loader, (self.kernel,)))
        OBSERVATIONS.append({'Case': 'custom-dependency-root', 'ChangeDetected': True})

    @unittest.skipIf(os.name == 'nt', 'POSIX SIGINT process test; Windows path is not exercised here')
    def test_interruption_records_started_case(self):
        for patched in (False, True):
            cmd, out = self.command(patched, '120')
            marker = self.root / ('started-patched' if patched else 'started-original')
            env = dict(os.environ, AUDIT_WAIT='1', AUDIT_STARTED_MARKER=str(marker))
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 text=True, env=env, start_new_session=True)
            child_pid = None
            try:
                until = time.monotonic()+8
                while not marker.exists() and p.poll() is None and time.monotonic() < until:
                    time.sleep(0.02)
                self.assertTrue(marker.exists(), 'Fake kernel did not start')
                child_pid = int(marker.read_text())
                p.send_signal(signal.SIGINT)
                stdout, stderr = p.communicate(timeout=8)
                d = json.loads(out.read_text())
                self.assertFalse(d['RunComplete'])
                if patched:
                    self.assertEqual(d['Started'], 1)
                    self.assertEqual(d['NotStarted'], 1)
                    self.assertEqual(d['Results'][0]['Outcome'], 'Interrupted')
                else:
                    self.assertEqual(d['Executed'], 0)
                    self.assertEqual(d['NotRun'], 2)
                    self.assertEqual(d['Results'], [])
                OBSERVATIONS.append({'Case': 'interrupt-during-first-case', 'Patched': patched,
                    'FakeKernelActuallyStarted': True, 'RunComplete': d['RunComplete'],
                    'Executed': d['Executed'], 'NotRun': d['NotRun'],
                    'Started': d.get('Started'), 'NotStarted': d.get('NotStarted'),
                    'Outcomes': [x['Outcome'] for x in d['Results']], 'ExitCode': p.returncode})
            finally:
                if p.poll() is None:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.communicate(timeout=5)
                if child_pid is not None:
                    try: os.kill(child_pid, signal.SIGKILL)
                    except ProcessLookupError: pass

if __name__ == '__main__':
    if os.name == 'nt':
        raise SystemExit('The fake-executable process harness targets POSIX; run it under Linux or WSL. The mathematical prototype tests are portable.')
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(HarnessTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    evidence = {'Python': sys.version, 'Platform': sys.platform, 'TestsRun': result.testsRun,
                'Failures': len(result.failures), 'Errors': len(result.errors),
                'Scope': 'Byte-identical upstream runner and candidate patch, with fake kernels only',
                'Observations': OBSERVATIONS}
    (BASE/'results/harness-tests.json').write_text(json.dumps(evidence, indent=2)+'\n')
    raise SystemExit(not result.wasSuccessful())
