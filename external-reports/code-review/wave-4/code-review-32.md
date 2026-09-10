# Review package 32 — retired

*AsymptoticAnalysis: incremental review after wave 3*

| | |
| --- | --- |
| Wave | [4](README.md) |
| Reviewed snapshot | [`513917b`](https://github.com/VladimirReshetnikov/Asymptotic/tree/513917b5b387152256b14ac76d92dd30cd13a11d) |
| Review date | 9 September 2026 |
| Supplied files | 17 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Its timeout finding is closed. Each of its other seven entries restates a wave-4
work item that two to seven retained packages also report, and unlike reports 30,
31 and 35 it is not cited as evidence in the portable-validation contracts.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| M01 | Mathics `ProductLog` exact conversion and order, distinct from the inherited numerical arity gate | W4-01 | Pending | reports 28, 29, 30, 33, 34 |
| M02 | Retained parameter assumptions are not passed into the polynomial real-domain proof | W4-03 | Pending | reports 28, 35, 36 |
| M03 | Seven absolute radius trials replaced by a constructive positive-neighborhood certificate | W4-03 | Pending | reports 28, 35, 36 |
| D-P06 | Dense inner logarithmic coefficient polynomials inside otherwise sparse jets and Fourier modes | W4-07 | Pending | reports 30, 33, 34, 35, 36 |
| D-V01 | Source endpoint equality does not establish which bytes the interpreter consumed | W4-12 | Partly addressed | reports 28, 29, 30, 34, 35 |
| L01 | A latent `Limit`-default mismatch | W4-05 | Pending | reports 28, 29, 30, 31, 33, 34, 35 |
| G01 | A safe terminating-hypergeometric extension | W4-08 | Pending | reports 28, 30, 36 |
| T01 | Nonfinite timeout input validation | W4-10 | Focused verified | — |

Its seventeen files are recorded in
[wave4-payload-provenance.json](../../../validation/wave4-payload-provenance.json),
which compares every supplied wave-4 file with its arrival Git blob. That record
still describes what arrived at `8cb9b7f`; a `RetiredAfterArrival` field now says
these seventeen are no longer in the working tree. The
[intake crosswalk](../../../validation/wave4-intake-crosswalk.json) still maps all
64 wave-4 ledger IDs, including this package's eight.

## What it supplied

27 independent Python, SymPy and mpmath reference tests and eight synthetic
tooling tests passed. **No Wolfram or Mathics package execution, WL candidate
run, or repository CI run**: no local kernel was available and both the container
network and the remote Wolfram connection failed. Its swapped-Lambert value is a
SymPy countermodel, not an observed Mathics output.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-4/code-review-32/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-4/code-review-32
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-32 2396cb6 && ls /tmp/review-32/external-reports/code-review/wave-4/code-review-32
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 4 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
