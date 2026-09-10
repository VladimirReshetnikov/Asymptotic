"""Synthetic-source checks of candidate staging, not Mathics integration."""
from __future__ import annotations
import ast
import unittest
from stage_productlog_patch import stage

FIXTURE = '''"""Synthetic module for staging tests."""
from __future__ import annotations
class MPMathFunction:
    def from_sympy(self, elements):
        return ("ProductLog", tuple(elements))
class ProductLog(MPMathFunction):
    """Synthetic target, not copied Mathics source."""
    sympy_name = "LambertW"
class Sentinel:
    pass
'''

class StagingTests(unittest.TestCase):
    def test_staged_methods_execute_on_synthetic_base(self):
        namespace = {}
        result = stage(FIXTURE)
        ast.parse(result)
        exec(compile(result, "<synthetic staged source>", "exec"), namespace)
        obj = namespace["ProductLog"]()
        self.assertEqual(obj.nargs, {1, 2})
        self.assertEqual(obj.prepare_sympy((-1, "z")), ("z", -1))
        self.assertEqual(obj.from_sympy(("z", -1)), ("ProductLog", (-1, "z")))
        self.assertIsNotNone(namespace["Sentinel"])

    def test_repeated_staging_is_rejected(self):
        with self.assertRaises(ValueError):
            stage(stage(FIXTURE))

    def test_changed_target_is_rejected(self):
        for text in (FIXTURE.replace("ProductLog(MPMathFunction)", "ProductLog(object)"),
                     FIXTURE.replace("class ProductLog", "class Other")):
            with self.subTest(text=text), self.assertRaises(ValueError):
                stage(text)

if __name__ == "__main__":
    unittest.main(verbosity=2)
