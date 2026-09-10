#!/usr/bin/env python3
"""Run independent models and save reproducible receipts (overwrites receipts).

No repository access, downloads, kernel invocation or upstream modification.
Use Python >=3.10 and mpmath 1.3.0. Run from any directory.
"""
from pathlib import Path
import io
import json
import platform
import unittest
from independent_models import Arithmetic, F, certificate_witness, logarithm_witness

ROOT=Path(__file__).resolve().parents[1]

def main():
    stream=io.StringIO()
    suite=unittest.TestLoader().discover(str(ROOT/'code'),pattern='test_*.py')
    result=unittest.TextTestRunner(stream=stream,verbosity=2).run(suite)
    counts=[]
    for n in (3,7,31,255,99999):
        old=Arithmetic(48); new=Arithmetic(48)
        old.power((F(-1,4),F(1)),n)
        new.power((F(-1,4),F(1)),n,True)
        counts.append({'exponent':n,'old_multiply_calls':old.multiplications,
                       'new_multiply_calls':new.multiplications,'old_square_calls':old.squares,
                       'new_square_calls':new.squares})
    data={'audited_revision':'8cee870994f506b501bae3ea6bd4a3a7edb895c1',
          'python_version':platform.python_version(),
          'evidence_class':'independent models and synthetic patcher fixtures',
          'test_methods_run':result.testsRun,'failures':len(result.failures),
          'errors':len(result.errors),'skipped':len(result.skipped),
          'successful':result.wasSuccessful(),
          'subcase_design':{
              'directed_rounding': '1000 seeded rationals at 8,24,48 bits; both directions',
              'power_containment': '500 seeded intervals, old and candidate, exponents 0..13',
              'unaffected_paths':'300 seeded sign-definite cases, plus six zero-crossing controls',
              'odd_family':'16 exact asymmetric dyadic cases',
              'negative_powers':'32 fixed interval/exponent/candidate combinations'},
          'certificate_witness':certificate_witness(),
          'logarithm_recovery_witness':logarithm_witness(),
          'work_counts_not_timings':counts,
          'wolfram_package_executed':False,'mathics_package_executed':False,
          'wl_candidate_executed':False,'upstream_source_match_executed':False}
    (ROOT/'evidence').mkdir(exist_ok=True)
    (ROOT/'evidence'/'independent-results.json').write_text(json.dumps(data,indent=2)+'\n')
    (ROOT/'evidence'/'test-output.txt').write_text(stream.getvalue())
    print(stream.getvalue())
    print(json.dumps({'tests':result.testsRun,'successful':result.wasSuccessful()}))
    return 0 if result.wasSuccessful() else 1

if __name__=='__main__': raise SystemExit(main())
