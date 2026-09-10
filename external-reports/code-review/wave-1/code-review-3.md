# Review package 3 — retired

*AsymptoticInverse 1.8.0 — technical audit*

| | |
| --- | --- |
| Wave | [1](README.md) |
| Reviewed snapshot | [`07a9781`](https://github.com/VladimirReshetnikov/Asymptotic/tree/07a9781212beb2eeb9ff16aa625b50ac27974078) |
| Review date | 9 September 2026 |
| Supplied files | 15 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Four of its five findings are implemented and focused verified. The fifth is the
shared inversion-cost item, which reports 5 and 9 also carry.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| F01 | Nested fractional powers bypass the direct real-branch guard, including a conditional-realness check | C02 | Focused verified | — |
| F02 | Eager native `SeriesData` export requests an unbudgeted dense rational lattice | C01 | Focused verified | — |
| F03 | Native export loses a logarithmic remainder factor | C03 | Focused verified | — |
| F04 | Ambient assumptions are used but omitted from a reusable result's recorded hypotheses | C05 | Focused verified | — |
| F05 | Optimized inversion engines still inherit multi-index enumeration and frontier work | P04 | Pending | reports 5, 9 |

Its roadmap and API discussion are cited by seven register rows: the D06
compatibility decision and the X03, X04, X05, X06, X09 and X10 proposals. D06
keeps reports 4, 6 and 7 plus reviews 5 and 9 as its other sources, and all the
X rows but X04 keep several others; the X04 row now cites report 16's O01/O02
derivative-tail entries, which the register's prose already treated as an
X04/X05 source. Every `[R3-article]` citation therefore resolves to this page.

## What it supplied

One of only two wave-1 packages with limited native execution. The pinned
standalone (573,940 bytes, SHA-256 `b2aebac8…`) loaded in **Wolfram Language
15.0.0 for Linux x86-64**, and selected baseline observations, built-in
comparisons and four guard-logic spot checks completed. Neither the full upstream
suite nor the complete supplied regression file was run. That native evidence
concerned C01, C02, C03 and C05, all of which now have their own current focused
acceptance records.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-1/code-review-3/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-1/code-review-3
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-3 2396cb6 && ls /tmp/review-3/external-reports/code-review/wave-1/code-review-3
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 1 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
