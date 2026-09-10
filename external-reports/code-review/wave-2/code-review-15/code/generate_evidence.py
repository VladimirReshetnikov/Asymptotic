from pathlib import Path
import json
import platform
from fractions import Fraction as Q
from audit_models import *
root=Path(__file__).resolve().parents[1]
geometry=[]
for q in (Q(-3),Q(-1,2),Q(1,2),Q(2)):
    for a in (Q(-3),Q(2)):
        geometry.append(dict(family='FlatMonomial',q=str(q),a=str(a),
          baseline=baseline_flat_approach(q,a),expected=monomial_approach(q,a)))
for side in (-1,1):
    for scale in (Q(-2),Q(3)):
        geometry.append(dict(family='Erfc',source_sign=side,scale=str(scale),
          baseline=baseline_erfc_approach(side,scale),expected=erfc_approach(side,scale)))
for a in (Q(-3),Q(2)):
    for scale in (Q(-2),Q(3)):
        geometry.append(dict(family='Quadratic',a=str(a),scale=str(scale),
          baseline=monomial_approach(Q(2),scale),expected=quadratic_approach(a,scale)))
evidence=dict(snapshot='921387e5ba1239bfda96e63e64e89bf63d9c41e6',
 evidence_type='Independent restricted models; not Wolfram package execution',
 python=platform.python_version(),geometry=geometry,
 geometry_mismatches=sum(r['baseline']!=r['expected'] for r in geometry),
 certificate_baseline=run_certificate_policy(),
 certificate_escalated=run_certificate_policy(adaptive=True),
 flat_square=[flat_square_tail(n) for n in (1,2,3,5,8)])
(root/'evidence'/'independent_results.json').write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps({k:v for k,v in evidence.items() if k not in ('geometry','certificate_baseline','certificate_escalated')},indent=2))
for k in ('certificate_baseline','certificate_escalated'):
    r=evidence[k]
    print(k, 'reached=',r['reached'], 'attempts=',len(r['history']), 'last=',r['history'][-1])
