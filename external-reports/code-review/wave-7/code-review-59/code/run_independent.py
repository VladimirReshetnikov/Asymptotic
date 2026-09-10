"""Run local independent models and emit evidence with explicit population labels."""
from __future__ import annotations
import csv
from fractions import Fraction as F
import io
import json
from pathlib import Path
import platform
import sys
import unittest
import sympy
from bootstrap_reference import mathics_bootstrap,decode_statements
from bootstrap_fixed import split_statements
from core_model import family

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'evidence'
OUT.mkdir(exist_ok=True)
suite=unittest.defaultTestLoader.discover(str(ROOT/'code'),pattern='test_review.py')
log=io.StringIO()
result=unittest.TextTestRunner(stream=log,verbosity=2).run(suite)
transcript=log.getvalue()
(OUT/'test-output.txt').write_text(transcript,encoding='utf-8')
summary={
 'population':'Independent Python models, transcribed builder helpers, candidate splitter, and synthetic patch fixtures',
 'python':platform.python_version(),'sympy':sympy.__version__,
 'tests_run':result.testsRun,'failures':len(result.failures),
 'errors':len(result.errors),'skipped':len(result.skipped),
 'subcases_counted_as_separate_tests':False,
 'wolfram_package_executed':False,'mathics_package_executed':False,
 'repository_builder_executed':False,'transcribed_two_function_fixture_executed':True,
 'success':result.wasSuccessful()}
(OUT/'independent-results.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
s='settings = <| counter = 1; "key" -> counter |>;\nafter = 2;\n'
fragments={'source':s,'reference':decode_statements(mathics_bootstrap(s)),
           'candidate':split_statements(s),
           'WL_parsing_executed':False,
           'interpretation':'Python splitting observed; WL parse failure of unmatched association fragments is grammar-derived.'}
(OUT/'bootstrap-fragments.json').write_text(json.dumps(fragments,indent=2)+'\n',encoding='utf-8')
rows=[]
for r,n in ((1,0),(2,1),(3,1),(4,2)):
 for y in (16,32,64,128):
  rows.append({k:str(v) for k,v in family(F(1,2),r,n,F(y)).items()})
with (OUT/'core-cancellation-family.csv').open('w',newline='',encoding='utf-8') as fp:
 writer=csv.DictWriter(fp,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
print(transcript,end='')
print(json.dumps(summary,indent=2))
sys.exit(0 if result.wasSuccessful() else 1)
