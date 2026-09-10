#!/usr/bin/env python3
"""Run exact mathematical/model checks and patch-fixture checks, not WL tests."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
from fractions import Fraction as F
import json
from pathlib import Path
import platform
import sys
import sympy as sp
from abs_guard_patch import BASELINE, CANDIDATE, patched_text
from modulus_jet import Jet, Error, Budget, L, modulus, as_expression, hermitian_square, mul


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path('evidence/independent_results.json'))
    args = parser.parse_args()
    results = []
    def check(name, condition, detail=''):
        passed = bool(condition)
        results.append(dict(name=name, passed=passed, detail=str(detail)))
        if not passed:
            print('FAILED:', name, detail, file=sys.stderr)
    def rejected(name, fn, cls=ValueError):
        try:
            fn()
        except cls:
            check(name, True)
        except Exception as exc:
            check(name, False, f'unexpected {type(exc).__name__}: {exc}')
        else:
            check(name, False, 'expected refusal')

    x = sp.Symbol('x', positive=True)
    a = sp.Symbol('a')  # No implicit real assumption.
    # Model the reviewed shortcut symbolically, BEFORE a -> I specialization.
    predicted_pair = sp.expand((1+a*x)+(1-a*x))
    predicted_squares = sp.expand((1+a*x)**2+(1-a*x)**2).subs(a**2, -1)
    oracle_pair = 2*sp.sqrt(1+x*x)
    oracle_squares = 2+2*x*x
    check('source-model/pair-cancels-to-exact-two', predicted_pair == 2)
    check('oracle/pair-has-quadratic-term', sp.limit((oracle_pair-2)/x**2, x, 0) == 1)
    check('oracle/pair-difference-not-O-x4', sp.limit((oracle_pair-2)/x**4, x, 0) == sp.oo)
    check('oracle/rational-witness-three-quarters', oracle_pair.subs(x, sp.Rational(3,4)) == sp.Rational(5,2))
    check('source-model/squares-wrong-sign', sp.expand(predicted_squares-(2-2*x*x)) == 0)
    check('oracle/square-pair-error-exact', sp.expand(oracle_squares-predicted_squares) == 4*x*x)
    check('oracle/square-pair-exact-identity', sp.simplify(
        (1+sp.I*x)*(1-sp.I*x)+(1-sp.I*x)*(1+sp.I*x)-oracle_squares) == 0)
    # Direct I would be rejected by exactQ in the package. This mathematical
    # specialization is an oracle, NOT a package-call reproduction.

    for q in [F(1,2), F(1), F(3,2), F(2)]:
        for c in [sp.Rational(1,2), sp.Integer(1), sp.Integer(3)]:
            for mult in [2,3,5]:
                cut = mult*q
                jet = Jet({F(0): sp.S.One, q: sp.I*c})
                out = modulus(jet, cut)
                t = sp.Symbol('t', positive=True)
                den = q.denominator
                output = as_expression(out,x).subs(x,t**den)
                expected = sp.sqrt(1+c*c*t**(2*q.numerator))
                order = int(cut*den)
                delta = sp.series(output-expected,t,0,order).removeO().expand()
                check(f'modulus/grid/q={q}/c={c}/cut={cut}', delta == 0)
                check(f'modulus/error/q={q}/c={c}/cut={cut}',
                      out.error is not None and out.error.power == cut and out.error.log_degree == 0)

    original = Jet({F(-1): 1, F(1,2): 2+sp.I, F(2): 1-sp.I})
    target = modulus(original,F(4))
    for k, phase in enumerate([sp.I, -1, sp.Rational(3,5)+sp.Rational(4,5)*sp.I]):
        rotated = Jet({w: phase*c for w,c in original.rows.items()})
        check(f'modulus/unit-phase-invariance/{k}', modulus(rotated,F(4)) == target)
    conjugated = Jet({w:sp.conjugate(c) for w,c in original.rows.items()})
    check('modulus/conjugation-invariance', modulus(conjugated,F(4)) == target)
    check('modulus/complex-leading-constant', modulus(Jet({F(2): 3+4*sp.I}),F(4)) == Jet({F(2):sp.Integer(5)}))
    check('modulus/pure-error', modulus(Jet({},Error(F(3),2)),F(5)) == Jet({},Error(F(3),2)))
    check('modulus/negative-real-fast-path', modulus(Jet({F(0):-2,F(1):1}),F(3)) == Jet({F(0):sp.Integer(2),F(1):sp.Integer(-1)}))
    check('modulus/real-log-fast-path', modulus(Jet({F(1):L}),F(3)) == Jet({F(1):-L}))
    check('modulus/exact-zero', modulus(Jet({}),F(3)) == Jet({}))
    out = modulus(Jet({F(0):1,F(1):sp.I*L}),F(4))
    check('modulus/log-coefficients', out.rows == {F(0):sp.Integer(1),F(2):L**2/2})
    check('modulus/log-tail-degree', out.error == Error(F(4),4))
    out = modulus(Jet({F(0):1,F(1):sp.I},Error(F(3),7)),F(5))
    check('modulus/input-precision-clips-output', out.error == Error(F(3),7) and max(out.rows)<F(3))
    check('modulus/leading-cutoff-bound', modulus(Jet({F(2):sp.I}),F(1)) == Jet({},Error(F(2),0)))
    rejected('model/refuses-symbolic-unproved-coefficients', lambda:modulus(Jet({F(0):1,F(1):a}),F(3)))
    rejected('model/refuses-complex-leading-log-amplitude',lambda:modulus(Jet({F(0):1+sp.I*L}),F(3)))
    rejected('model/refuses-inexact-coefficients',lambda:modulus(Jet({F(0):1.1}),F(3)))
    rejected('model/refuses-retained-term-at-error',lambda:modulus(Jet({F(0):1,F(2):sp.I},Error(F(2))),F(3)))
    rejected('model/refuses-zero-budget',lambda:modulus(Jet({F(0):1}),F(3),Budget(max_products=0)))
    rejected('model/product-budget-stops',lambda:modulus(Jet({F(0):1,F(1):sp.I}),F(8),Budget(max_products=1)),RuntimeError)
    rejected('model/step-budget-stops',lambda:modulus(Jet({F(0):1,F(1):sp.I}),F(8),Budget(max_steps=1)),RuntimeError)

    fixture = '(* isolated source fixture, not a checkout *)\n'+BASELINE+'\n'
    patch = patched_text(fixture)
    check('patch/one-guard',patch.count('"UnprovedAbsJetRealness"') == 1)
    check('patch/preserves-surroundings',patch.startswith('(* isolated') and patch.endswith('\n'))
    check('patch/replaces-whole-reviewed-definition', CANDIDATE in patch and BASELINE not in patch)
    excerpt=Path(__file__).resolve().parents[1]/'source-excerpts'/'fwdAbs.baseline.wl'
    check('patch/anchor-matches-transcribed-source-excerpt',excerpt.read_text().strip()==BASELINE)
    rejected('patch/rejects-missing-anchor',lambda:patched_text('unrelated source'))
    rejected('patch/rejects-duplicate-anchor',lambda:patched_text(BASELINE+'\n'+BASELINE))
    rejected('patch/rejects-already-patched',lambda:patched_text(patch))
    rejected('patch/rejects-modified-anchor',lambda:patched_text(BASELINE.replace('degree},','degree, extra},')))

    counts = []
    for m in [8,16,32,64]:
        rows = {F(i):sp.Integer(i+1)+sp.I*(2*i-1) for i in range(m)}
        b1, b2 = Budget(), Budget()
        full = mul(rows,{w:sp.conjugate(c) for w,c in rows.items()},None,b1)
        paired = hermitian_square(rows,b2)
        check(f'hermitian/same-polynomial/m={m}',full==paired)
        check(f'hermitian/pair-count/m={m}',b1.products==m*m and b2.products==m*(m+1)//2)
        counts.append({'support':m,'ordered_pair_products':b1.products,'hermitian_pair_products':b2.products})

    output = {
      'timestamp_utc':datetime.now(timezone.utc).isoformat(),
      'python':platform.python_version(), 'sympy':sp.__version__,
      'scope':'Independent mathematical, abstract-jet, and synthetic patch-fixture checks only.',
      'native_package_executed':False, 'native_candidate_executed':False,
      'tests':len(results),'passed':sum(r['passed'] for r in results),
      'failed':sum(not r['passed'] for r in results), 'pair_counts':counts, 'results':results}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
    print(f"{output['passed']}/{output['tests']} independent checks passed; {output['failed']} failed.")
    print('No Wolfram or Mathics package tests are represented by this count.')
    return int(output['failed'] != 0)

if __name__=='__main__':
    raise SystemExit(main())
