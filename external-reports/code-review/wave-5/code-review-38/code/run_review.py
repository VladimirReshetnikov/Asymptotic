"""Run independent checks and write reproducible, explicitly scoped evidence."""
from __future__ import annotations
import io
import json
import platform
import sys
import unittest
from pathlib import Path
import sympy as sp
import mpmath as mp
import test_review
from branch_reference import endpoint_branch_reference, leading_inverse_coefficients

ROOT=Path(__file__).resolve().parents[1]
EVIDENCE=ROOT/'evidence'
REVISION='8e859961d7d37f008b826f3a8cad406460271614'

def main() -> int:
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    suite=unittest.defaultTestLoader.loadTestsFromModule(test_review)
    stream=io.StringIO()
    result=unittest.TextTestRunner(stream=stream,verbosity=2).run(suite)
    transcript=stream.getvalue()
    (EVIDENCE/'python-tests.txt').write_text(transcript,encoding='utf-8')
    x=test_review.x
    examples={}
    for label,expr in [('cubic',test_review.f),('quartic',test_review.g)]:
        ref=endpoint_branch_reference(expr,x,0,sp.Rational(1,2))
        examples[label]={
            'polynomial':str(expr),'reference':ref.to_dict(),
            'leading_inverse_coefficients':list(map(str,leading_inverse_coefficients(expr,x,3))),
            'finite_approximation_at_target':'1/2',
            'same_side_exact_root_candidate':'1/2',
            'candidate_equation_residual':str(expr.subs(x,sp.Rational(1,2))-sp.Rational(1,2)),
            'actual_selected_branch_error':str(abs(ref.root-sp.Rational(1,2))),
            'candidate_derivative':str(sp.diff(expr,x).subs(x,sp.Rational(1,2))),
            'evidence_type':'Independent exact mathematical oracle; no package evaluation',
        }
    with mp.workdps(80):
        B=mp.log(3)-mp.mpf(19)/108
        derivative=mp.digamma(3)/2
        numerical={
            'x':3,'family':'LogGamma','target_scale':'1/2',
            'stored_unscaled_expression_value':mp.nstr(B,60),
            'original_derivative_value':mp.nstr(derivative,60),
            'corrected_pointwise_magnitude_lower_bound':mp.nstr(B/2,60),
            'evidence_type':'Independent 80-decimal mpmath sample; not an interval certificate',
        }
    report={
        'reviewed_repository':'VladimirReshetnikov/Asymptotic',
        'reviewed_revision':REVISION,
        'environment':{'python':sys.version,'platform':platform.platform(),
                       'sympy':sp.__version__,'mpmath':mp.__version__},
        'tests':{'methods_run':result.testsRun,'successful':result.wasSuccessful(),
                 'failures':len(result.failures),'errors':len(result.errors),
                 'skipped':len(result.skipped),
                 'scaled_polynomial_family_subcases':12,
                 'derivative_transport_family_scale_point_subcases':18,
                 'counting_policy':'Subcases are included in method tests, not additional package tests.'},
        'native_execution':{'Wolfram_package':False,'Mathics_package':False,
                            'native_helper':False,'native_regressions':False,
                            'upstream_suite':False,'fresh_upstream_CI':False},
        'examples':examples,'derivative_sample':numerical,
        'development_note':('An initial algebraic-root test used structural simplify equality for a CRootOf. '
                            'It was replaced by an exact minimal-polynomial and positivity test; '
                            'the branch-reference algorithm was unchanged.'),
    }
    (EVIDENCE/'independent-results.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(transcript,end='')
    return 0 if result.wasSuccessful() else 1

if __name__=='__main__':
    raise SystemExit(main())
