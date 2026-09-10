#!/usr/bin/env python3
"""Run independent tests and write receipts inside the bundle's evidence folder."""
from pathlib import Path
import io
import json
import platform
import sys
import unittest
from fractions import Fraction
from exact_seed_reference import prove_root
import test_exact_seed

root = Path(__file__).resolve().parent.parent
out = root / "evidence"
out.mkdir(exist_ok=True)
stream = io.StringIO()
suite = unittest.defaultTestLoader.loadTestsFromModule(test_exact_seed)
result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
(out / "independent-tests.txt").write_text(stream.getvalue(), encoding="utf-8")
record = {
    "scope": "Independent Python rational-polynomial models and candidate admission; NOT package execution",
    "python": sys.version,
    "platform": platform.platform(),
    "unittest_methods": result.testsRun,
    "failures": len(result.failures), "errors": len(result.errors),
    "success": result.wasSuccessful(),
    "nested_cases": {"dyadic_family": 96, "affine_rescaling": 9,
                     "random_oracle_comparisons": 200, "constructed_roots": 150},
    "package_execution": False, "wolfram_candidate_execution": False,
    "mathics_candidate_execution": False,
}
(out / "independent-tests.json").write_text(json.dumps(record, indent=2)+"\n", encoding="utf-8")
examples = [prove_root([-1,2], Fraction(1,2)).to_json(),
            prove_root([-1,3], Fraction(1,3)).to_json(),
            prove_root([Fraction(-231,1000),2,-3,1], Fraction(21,10)).to_json()]
(out / "point-equality-examples.json").write_text(json.dumps(examples, indent=2)+"\n", encoding="utf-8")
print(stream.getvalue())
print(json.dumps(record, indent=2))
raise SystemExit(0 if result.wasSuccessful() else 1)
