"""Fixture-level tests only; this does not load or compile Wolfram source."""
import importlib.util
from pathlib import Path
import unittest

p = Path(__file__).resolve().parents[1]/'patches'/'emit_affine_patch.py'
spec = importlib.util.spec_from_file_location('emitter',p)
emitter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emitter)

class PatchEmitterTests(unittest.TestCase):
    def setUp(self):
        self.fixture = emitter.HEADER+'\n  Which[\n'+emitter.OLD+'\n  ]];\n'
    def test_fixture_transformation(self):
        result = emitter.transform(self.fixture,'(* helper fixture *)\n')
        self.assertIn(emitter.NEW,result)
        self.assertEqual(result.count('(* helper fixture *)'),1)
    def test_missing_anchor(self):
        with self.assertRaises(ValueError):
            emitter.transform('unrelated source','helper')
    def test_duplicate_anchor(self):
        with self.assertRaises(ValueError):
            emitter.transform(self.fixture+self.fixture,'helper')
    def test_already_patched(self):
        with self.assertRaises(ValueError):
            emitter.transform('certAuditAffinePair\n'+self.fixture,'helper')
    def test_git_blob_algorithm(self):
        self.assertEqual(emitter.git_blob(b'hello\n'),'ce013625030ba8dba906f756967f9e9ca394464a')

if __name__ == '__main__':
    unittest.main(verbosity=2)
