from pathlib import Path
import io
import json
import platform
import sys
import unittest
import test_review

root=Path(__file__).resolve().parents[1]
stream=io.StringIO()
suite=unittest.defaultTestLoader.loadTestsFromModule(test_review)
result=unittest.TextTestRunner(stream=stream,verbosity=2).run(suite)
text=stream.getvalue()
print(text,end="")
(root/"evidence"/"python-tests.txt").write_text(text,encoding="utf-8")
record={"python":platform.python_version(),"platform":platform.platform(),
        "tests_run":result.testsRun,"failures":len(result.failures),
        "errors":len(result.errors),"skipped":len(result.skipped),
        "scope":"Independent exact-rational models and synthetic patch fixtures; no upstream package execution",
        "subcase_counts":test_review.COUNTS}
(root/"evidence"/"python-results.json").write_text(json.dumps(record,indent=2)+"\n",encoding="utf-8")
sys.exit(0 if result.wasSuccessful() else 1)
