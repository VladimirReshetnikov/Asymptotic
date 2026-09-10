#!/usr/bin/env python3
from __future__ import annotations
import csv, io, json, platform, sys, time, unittest
from pathlib import Path
import mpmath as mp
from review_math import moment_table

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'evidence'; OUT.mkdir(exist_ok=True)
mp.mp.dps=100
stream=io.StringIO()
suite=unittest.defaultTestLoader.discover(str(ROOT/'code'),pattern='test_review.py')
t0=time.perf_counter(); result=unittest.TextTestRunner(stream=stream,verbosity=2).run(suite)
elapsed=time.perf_counter()-t0
(OUT/'independent-test-output.txt').write_text(stream.getvalue(),encoding='utf-8')
record={'review_commit':'8cee870994f506b501bae3ea6bd4a3a7edb895c1',
        'population':'independent Python models, rational prototype and patch-fragment fixtures; NOT package tests',
        'python':platform.python_version(),'mpmath':mp.__version__,
        'methods_run':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),
        'skipped':len(result.skipped),'elapsed_seconds':elapsed,
        'success':result.wasSuccessful(),'working_decimal_digits':mp.mp.dps,
        'wolfram_execution':'unavailable; service calls failed',
        'mathics_execution':'unavailable; not installed, installation unavailable',
        'full_checkout':'not obtained; commit-pinned source read via GitHub connector',
        'patch_execution':'synthetic fragment fixtures only; no patched package run'}
(OUT/'independent-results.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
rows=[]
for depth in (0,1,3):
 for y in (5,10,20):
    yy=mp.mpf(y)
    error=-mp.log1p(-1/yy)-mp.fsum(1/(k*yy**k) for k in range(1,depth+1))
    badscale=(mp.exp(-yy)/yy)**(depth+1)
    rows.append({'depth':depth,'y':y,'error':mp.nstr(error,18),
      'source_predicted_scale':mp.nstr(badscale,18),'ratio':mp.nstr(error/badscale,18),
      'proven_ratio_lower_bound':mp.nstr(mp.exp((depth+1)*yy)/(depth+1),18)})
with (OUT/'shift-counterexample.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
(OUT/'shift-counterexample.json').write_text(json.dumps({
 'scope':'Numerical evaluation of independently derived formulas, not observed package output',
 'exact_inverse':'log(y-1)', 'displayed_formula':'log(y)-sum(k=1..N,1/(k*y^k))',
 'source_predicted_remainder_scale':'exp(-(N+1)*y)*y^(-(N+1))',
 'rigorous_inequality':'error / scale >= exp((N+1)*y)/(N+1), for real y>1',
 'samples':rows},indent=2)+'\n')
# Timing concerns this Python prototype only: no comparison with the package.
bench=[]
from fractions import Fraction
for k in (16,32,64,128):
    timings=[]
    for _ in range(3):
        start=time.perf_counter(); values=moment_table(Fraction(1,2),k)
        timings.append(time.perf_counter()-start)
    bench.append({'max_degree':k,'rational_moments':len(values),
                  'best_seconds':min(timings),'last_numerator_bits':values[-1].numerator.bit_length()})
(OUT/'prototype-timing.json').write_text(json.dumps({
 'scope':'Python prototype timings only; no package speedup or Mathics/Wolfram timing claim',
 'runs_per_degree':3,'records':bench},indent=2)+'\n')
print(json.dumps(record,indent=2))
if not result.wasSuccessful():
 print(stream.getvalue()); raise SystemExit(1)
