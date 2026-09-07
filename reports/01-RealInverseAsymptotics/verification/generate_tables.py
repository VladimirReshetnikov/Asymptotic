#!/usr/bin/env python3
"""Regenerate manuscript table inputs from the recorded independent checks.

This script formats existing data; it does not run tests or manufacture new
numerical results. Run verify.py first to regenerate the underlying JSON.
"""
from __future__ import annotations
import json
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def scientific_tex(value: str) -> str:
    mantissa, exponent = format(Decimal(value), '.4E').split('E')
    return rf'${mantissa}\times10^{{{int(exponent)}}}$'


def main() -> None:
    report = json.loads((ROOT/'verification/verification_results.json').read_text())
    cases = [
        ('logarithmic', 'm', 'highest_power', 'numeric_log.tex', 'lognumeric'),
        ('irrational', 'N', 'corrections', 'numeric_irr.tex', 'irrnumeric'),
    ]
    for model, index, key, name, label in cases:
        lines = [r'\begin{table}[htbp]', r'\centering\small',
                 r'\begin{tabular}{rrrr}', r'\toprule',
                 rf'$y$ & ${index}$ & Absolute error & Error / stated scale \\',
                 r'\midrule']
        rows = [r for r in report['numerical_results'] if r['model'] == model]
        if len(rows) != 12:
            raise ValueError(f'Expected 12 recorded rows for {model}; got {len(rows)}')
        for row in rows:
            exponent = int(row['y'].split('e')[1])
            ratio = format(Decimal(row['error_over_remainder_scale']), '.6g')
            lines.append(rf'$10^{{{exponent}}}$ & {row[key]} & '
                         + scientific_tex(row['absolute_error'])
                         + rf' & {ratio} \\')
        lines.extend([r'\bottomrule', r'\end{tabular}',
                      r'\caption{Positive-branch numerical diagnostics for the '
                      + model + ' example. Computations use 150 decimal digits; '
                      + 'displayed values are rounded.}',
                      rf'\label{{tab:{label}}}', r'\end{table}'])
        (ROOT/'article'/name).write_text('\n'.join(lines)+'\n')
        print('Wrote', ROOT/'article'/name)


if __name__ == '__main__':
    main()
