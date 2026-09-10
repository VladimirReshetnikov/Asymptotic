#!/usr/bin/env python3
"""Recompute independent-model and synthetic-validator observations."""
from fractions import Fraction as Q
from pathlib import Path
import json
import platform
from affine_model import horner, tree_size, enclose_old, enclose_cached
from synthetic_receipts import fixture
from receipt_excerpt import validate_shard
from receipt_guard import validate_shard_strict

ROOT = Path(__file__).resolve().parents[1]
rows=[]
for n in [1,2,4,8,16,32,64]:
    e=horner(n)
    old=dict(affine_visits=0,enclosure_visits=0)
    new=dict(classification_visits=0,enclosure_visits=0)
    a=enclose_old(e,(Q(1,4),Q(1,2)),32,old)
    b=enclose_cached(e,(Q(1,4),Q(1,2)),32,new)
    rows.append(dict(depth=n,tree_nodes=tree_size(e),old_affine_visits=old['affine_visits'],
                     predicted_old_visits=4*n*(n+1),new_classification_visits=new['classification_visits'],
                     intervals_identical=a==b,interval=[str(x) for x in a]))
receipts=[]
for case in ['control','unfingerprinted-entry','nonentry-module','recorded-drift']:
    report,ref=fixture()
    if case=='unfingerprinted-entry':
        report['Source']=report['Source'].replace('/checkout/','/NOT-FINGERPRINTED/')
    elif case=='nonentry-module':
        report['Source']='/checkout/src/Kernel/InverseCertificates.wl'
    elif case=='recorded-drift':
        report['FirstObservedSourceDriftSHA256']={report['Source']:'f'*64}
    results={}
    for label,validator in [('upstream_excerpt',validate_shard),('candidate_guard',validate_shard_strict)]:
        try:
            validated=validator(report,ref)
            layout,seen=validated['Layout'],validated['Cases']
            results[label]=dict(accepted=True,layout=layout,cases=sorted(seen))
        except ValueError as exc:
            results[label]=dict(accepted=False,reason=str(exc))
    receipts.append(dict(case=case,results=results))
payload=dict(evidence_type='Independent Python model and synthetic receipt tests; no package runtime',
             review_commit='651f2029d0b2cd4da9e4dfdf1f4275a124d23b99',
             python=platform.python_version(),affine_counts=rows,receipt_observations=receipts)
(ROOT/'evidence'/'independent-results.json').write_text(json.dumps(payload,indent=2)+'\n')
print(json.dumps(payload,indent=2))
