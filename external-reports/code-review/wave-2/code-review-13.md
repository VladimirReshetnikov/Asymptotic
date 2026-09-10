# Review package 13 — retired

*Asymptotic: incremental technical audit*

| | |
| --- | --- |
| Wave | [2](README.md) |
| Reviewed snapshot | [`921387e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6) |
| Review date | 9 September 2026 |
| Supplied files | 23 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

All three principal results map to items that are now focused verified. A1's
comparator component remains open, and the register cites report 6 as its source.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| A1 | Provably equal exponents grouped under different expression trees invalidate the distinct-support invariant | C14 | Focused verified | — |
| A1 | …its comparator component | C12 | Audit candidate | report 6, the register's cited source |
| A2 | Exact nonreal expressions such as `ArcSin[2]` bypass a syntactic `Complex`-atom check | C07 | Focused verified | — |
| A2 | …its native-representation component | B01 | Partial | reports 11, 18 |
| A3 | A numerical inverse check returns a zero whose uncertainty exceeds the true error | C21 | Focused verified | — |

The [equal-exponent notes](../../../docs/development/EXPONENT_EQUALITY.md) now
cite the C14 baseline and the 276/0 acceptance instead of this package's
historical transcription.

## What it supplied

The pinned standalone loaded in **Wolfram Language 15.0.0, Linux x86-64**;
selected public baselines, the three A1 examples after the grouping
transformation, and built-in comparisons were executed and transcribed
selectively. Independently, 68 degree-pair cases with 204 family conditions and
an exact positive-error oracle passed, together with five patch-guard tests. The
complete suite, the supplied nine-test runner, the hotfix installer and the
numerical wrapper were not run.

It supplied a `NOTICE.md` covering its audit code. That notice, like every other
file, is preserved in Git history; nothing in it was edited or relicensed.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-2/code-review-13/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-2/code-review-13
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-13 2396cb6 && ls /tmp/review-13/external-reports/code-review/wave-2/code-review-13
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 2 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
