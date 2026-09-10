"""Synthetic helper tests only; these do not execute a Wolfram/Mathics kernel."""
from __future__ import annotations
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from patch_timeout import patched_text, OLD_IMPORT, OLD_GUARD, NEW_IMPORT, NEW_GUARD
from run_probes import extract_regular_archive

class ToolingTests(unittest.TestCase):
    def test_timeout_patch(self):
        old = OLD_IMPORT + '\ndef main():\n' + OLD_GUARD
        self.assertEqual(patched_text(old), NEW_IMPORT + '\ndef main():\n' + NEW_GUARD)
    def test_timeout_patch_idempotent(self):
        new = NEW_IMPORT + '\ndef main():\n' + NEW_GUARD
        self.assertEqual(patched_text(new), new)
    def test_timeout_patch_rejects_changed_source(self):
        with self.assertRaises(ValueError): patched_text('other source\n')
    def test_timeout_patch_rejects_duplicate_guard(self):
        with self.assertRaises(ValueError): patched_text(OLD_IMPORT + OLD_GUARD + OLD_GUARD)
    @staticmethod
    def archive(name, kind=None):
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode='w') as tar:
            info = tarfile.TarInfo(name)
            if kind is None:
                data = b'exact fixture'; info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
            else:
                info.type = kind; info.linkname = 'target'; tar.addfile(info)
        return buffer.getvalue()
    def test_regular_archive(self):
        with tempfile.TemporaryDirectory() as d:
            extract_regular_archive(self.archive('src/Kernel/example.wl'), Path(d))
            self.assertEqual((Path(d)/'src/Kernel/example.wl').read_bytes(), b'exact fixture')
    def test_archive_rejects_parent_traversal(self):
        with tempfile.TemporaryDirectory() as d, self.assertRaises(ValueError):
            extract_regular_archive(self.archive('../escape'), Path(d))
    def test_archive_rejects_absolute_path(self):
        with tempfile.TemporaryDirectory() as d, self.assertRaises(ValueError):
            extract_regular_archive(self.archive('/escape'), Path(d))
    def test_archive_rejects_symlink(self):
        with tempfile.TemporaryDirectory() as d, self.assertRaises(ValueError):
            extract_regular_archive(self.archive('link', tarfile.SYMTYPE), Path(d))

if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ToolingTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    report = {'Scope':'Synthetic tests of supplied patch/archive helpers; NOT repository or kernel execution',
              'TestsRun':result.testsRun, 'Failures':len(result.failures), 'Errors':len(result.errors),
              'PackageTestsRun':False, 'MathicsRun':False, 'WolframKernelRun':False}
    output = Path(__file__).resolve().parents[1]/'evidence/tooling-results.json'
    output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    raise SystemExit(0 if result.wasSuccessful() else 1)
