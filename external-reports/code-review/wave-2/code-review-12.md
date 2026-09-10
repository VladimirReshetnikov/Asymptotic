# Review package 12 — retired

*Asymptotic: incremental audit after nine reviews*

| | |
| --- | --- |
| Wave | [2](README.md) |
| Reviewed snapshot | [`921387e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6) |
| Review date | 9 September 2026 |
| Supplied files | 17 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

All three findings map to items that are now focused verified. The two secondary
components of N02 stay open and are carried by four other retained reports.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| N01 | False source-domain certification under ambient assumptions | C05 | Focused verified | — |
| N02 | A false trigonometric error bound after nonreal coefficient admission | C07 | Focused verified | — |
| N02 | …its composition-domain component | C13 | Audit candidate | reports 4, 7 |
| N02 | …its native-representation component | B01 | Partial | reports 11, 18 |
| N03 | Native series indices exceed the representable range despite a one-slot coefficient array | C17 | Focused verified | — |

## What it supplied

Focused experiments in **Wolfram Language 15.0.0 on Linux x86-64**, transcribed
selectively rather than as a complete session log, plus 23 independent Python
arithmetic and source-transformation checks. Individual patch mechanisms were
tested separately; no combined candidate was qualified, and no repository file
was modified by the audit. C17's current evidence is the 46/0 focused acceptance
and the fourteen native constructor characterizations in `validation/`.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-2/code-review-12/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-2/code-review-12
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-12 2396cb6 && ls /tmp/review-12/external-reports/code-review/wave-2/code-review-12
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 2 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
