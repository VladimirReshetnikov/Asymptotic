#!/usr/bin/env python3
"""Run independent tests and write their receipt and exact numerical enclosures."""
from __future__ import annotations
import csv
import io
import json
from decimal import Decimal, localcontext
from fractions import Fraction
from pathlib import Path
import platform
import sys
import time
import unittest
from reference import approximation, reported_scale, root_interval, absolute_error_interval

ROOT=Path(__file__).resolve().parents[1]

def dec(q: Fraction) -> str:
    with localcontext() as ctx:
        ctx.prec=18
        return str(Decimal(q.numerator)/Decimal(q.denominator))

def main() -> int:
    evidence=ROOT/'evidence'; evidence.mkdir(exist_ok=True)
    stream=io.StringIO(); started=time.perf_counter()
    suite=unittest.defaultTestLoader.discover(str(Path(__file__).resolve().parent),pattern='test_independent.py')
    result=unittest.TextTestRunner(stream=stream,verbosity=2).run(suite)
    transcript=stream.getvalue(); sys.stdout.write(transcript)
    (evidence/'independent-tests.txt').write_text(transcript)
    receipt={'kind':'independent rational mathematics and patch-fixture tests',
             'package_executed':False,'python':platform.python_version(),
             'tests_run':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),
             'skipped':len(result.skipped),'success':result.wasSuccessful(),
             'seconds':time.perf_counter()-started}
    (evidence/'independent-tests.json').write_text(json.dumps(receipt,indent=2)+'\n')
    rows=[]; enclosures=[]
    for branch in ['large','small']:
        for y in [5,10,20,50,100,1000]:
            n=2; a=approximation(branch,y,y,n); scale=reported_scale(branch,y,y,n)
            root=root_interval(y,branch,100); error=absolute_error_interval(a,root)
            rows.append({'branch':branch,'y':y,'depth':n,'approximation':dec(a),
                         'error_lower':dec(error[0]),'error_upper':dec(error[1]),
                         'reported_scale':dec(scale),'ratio_lower':dec(error[0]/scale),
                         'ratio_upper':dec(error[1]/scale)})
            enclosures.append({'branch':branch,'y':y,'depth':n,'approximation':str(a),
                               'root_interval':[str(q) for q in root],
                               'error_interval':[str(q) for q in error],
                               'reported_scale':str(scale),
                               'provenance':'independent exact quadratic oracle; not an additional package run'})
    with (evidence/'numerical-samples.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    (evidence/'exact-enclosures.json').write_text(json.dumps(enclosures,indent=2)+'\n')
    return 0 if result.wasSuccessful() else 1

if __name__=='__main__':
    raise SystemExit(main())
