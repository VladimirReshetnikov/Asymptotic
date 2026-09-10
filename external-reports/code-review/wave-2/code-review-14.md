# Review package 14 — retired

*Asymptotic — incremental technical audit*

| | |
| --- | --- |
| Wave | [2](README.md) |
| Reviewed snapshot | [`921387e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6) |
| Review date | 9 September 2026 |
| Supplied files | 22 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Four of its five findings are implemented and focused verified. The fifth is an
API request-normalization decision carried by four to five retained reports.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| N01 | An exact inner germ captures a fixed outer parameter, invalidating the remainder and the limiting finite part | C15 | Focused verified | — |
| N02 | Intermediate dyadic interval rounding prevents certification of a translated linear equation at every admitted precision | C20 | Focused verified | — |
| N03 | The ordinary numerical inverse checker loses a small source displacement in a huge absolute source coordinate | C21 | Focused verified | — |
| N04 | The Fourier constructor inherits `SeriesTermGoal` but never reads it | D01, D02 | Decision | D01: reports 1, 4, 6, 7, 16; D02: reports 1, 4, 6, 7 |
| N05 | Ordinary truncation drops already available quantitative Zeta and Lerch bounds | C22 | Focused verified for truncation | the open arithmetic-transport half stays under the retained C22 record |

The [composition parameter-scope notes](../../../docs/development/COMPOSITION_PARAMETER_SCOPE.md)
now cite the C15 baseline and acceptance records rather than this package.

## What it supplied

25 independent Python mathematical-model tests passed, including 500 random
directed-rounding cases, 500 affine translation cases, 16 parameter curves, 42
Zeta tail cases and 200 rational triangle-inequality cases, plus five
patch-emitter fixtures. **No native Wolfram execution**: the remote evaluator
could not connect and no local kernel was available.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-2/code-review-14/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-2/code-review-14
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-14 2396cb6 && ls /tmp/review-14/external-reports/code-review/wave-2/code-review-14
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 2 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
