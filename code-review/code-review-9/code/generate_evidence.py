"""Regenerate the independent numerical/count evidence (no networking)."""
from __future__ import annotations
from dataclasses import asdict
from fractions import Fraction as F
from pathlib import Path
import hashlib
import json
import platform
import sys
from audit_models import Work, integer_power, dense_bridge_plan, collision_fixture

ROOT = Path(__file__).resolve().parents[1]
results = ROOT / 'results'
results.mkdir(exist_ok=True)
metrics = []
for n in (16, 256, 10**6):
    work = Work()
    answer = integer_power({F(0): F(1), F(1): F(1)}, n, F(3), work)
    metrics.append({'n': n, 'exclusive_cutoff': 3, **asdict(work),
                    'coefficients': {str(w): str(c) for w, c in answer.items()}})
manifest = {
    'audit_commit': '07a9781212beb2eeb9ff16aa625b50ac27974078',
    'scope': 'Independent Python mathematical models; not execution of the Wolfram package',
    'python': sys.version, 'platform': platform.platform(),
    'collision_fixture': collision_fixture(),
    'dense_bridge_dimensions': [
        {'q': q, **dense_bridge_plan([F(0), F(1, q)], F(1)),
         'minimal_native_prefix': 2,
         'wider_example_minimal_prefix': q + 1}
        for q in (101, 997, 100003, 10**9)],
    'bounded_power_work': metrics,
    'refinement_example': {'requested_power': 5, 'operand_a_replayed_power': 7,
                           'operand_b_valuation': -10, 'transported_power': -3,
                           'needed_operand_a_power': 15},
    'native_status': 'NOT_RUN: Wolfram connector context request failed, evaluator returned HTTP 502',
    'source_files_downloaded_to_runtime': False,
    'code_sha256': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                   for directory in ('code', 'proposals')
                   for p in sorted((ROOT / directory).glob('*.py'))}
}
(results / 'independent_evidence.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(json.dumps(manifest['collision_fixture'], indent=2))
print(json.dumps(metrics, indent=2))
