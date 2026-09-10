#!/usr/bin/env python3
"""Run independent checks and write their own, explicitly scoped evidence."""
import contextlib, io, json, platform, sys, unittest
from datetime import datetime, timezone
from pathlib import Path
import sympy

class RecordingResult(unittest.TextTestResult):
    def __init__(self,*a,**k): super().__init__(*a,**k); self.passed=[]
    def addSuccess(self,test): super().addSuccess(test); self.passed.append(test.id())

def main():
    here=Path(__file__).resolve().parent
    suite=unittest.defaultTestLoader.discover(str(here),pattern='test_*.py')
    log=io.StringIO()
    result=unittest.TextTestRunner(stream=log,verbosity=2,resultclass=RecordingResult).run(suite)
    evidence=here.parent/'evidence'; evidence.mkdir(exist_ok=True)
    (evidence/'independent_checks.txt').write_text(log.getvalue(),encoding='utf-8')
    payload={'scope':'Independent Python mathematical/contract models and synthetic patch fixtures. NOT native package tests.',
        'upstream_commit':'6687962f3c858a4f93623cfc496f33e35c6763d4',
        'executed_at_utc':datetime.now(timezone.utc).isoformat(),
        'python':platform.python_version(),'sympy':sympy.__version__,
        'tests_run':result.testsRun,'successful_test_methods':len(result.passed),
        'failures':len(result.failures),'errors':len(result.errors),'skipped':len(result.skipped),
        'subcase_note':'Several methods contain deterministic subcases; they are not added to the method count.',
        'passed':result.passed,'failure_details':[(t.id(),msg) for t,msg in result.failures+result.errors],
        'native_package_loaded':False,'candidate_patches_natively_tested':False}
    (evidence/'independent_validation.json').write_text(json.dumps(payload,indent=2)+'\n',encoding='utf-8')
    print(log.getvalue()); print(json.dumps({k:payload[k] for k in ['tests_run','successful_test_methods','failures','errors']},indent=2))
    return 0 if result.wasSuccessful() else 1
if __name__=='__main__': sys.exit(main())
