# Review package 2 — retired

*Asymptotic 1.8.0 — technical review*

| | |
| --- | --- |
| Wave | [1](README.md) |
| Reviewed snapshot | [`07a9781`](https://github.com/VladimirReshetnikov/Asymptotic/tree/07a9781212beb2eeb9ff16aa625b50ac27974078) |
| Review date | 9 September 2026 |
| Supplied files | 20 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

All four of its defect findings are implemented and focused verified in the
register. The three entries that remain open are each carried by two to four
retained reports, and every roadmap proposal it fed keeps other cited sources.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| F01 | Nonlinear arithmetic loses boundary logarithmic degree at an input precision ceiling | C04 | Focused verified | — |
| F02 | A fractional power of a pure remainder bypasses the real-branch check | C02 | Focused verified | — |
| F03 | Outbound `SeriesData` drops the explicit logarithmic remainder degree | C03 | Focused verified | — |
| F04 | Eager native export allocates a huge dense rational-lattice vector | C01 | Focused verified | — |
| F05 | Derived refinement returns valid but insufficient precision | C08 | Pending | reports 5, 6, 9, 18 |
| F06 | Grouped and Newton methods still pay full multi-index enumeration | P04 | Pending | reports 5, 9 |
| F07 | The flat parser rejects commensurate rates that do not divide the smallest | X01 | Pending scope decision | reports 5, 7 |

Its article was also cited as a source for the X02, X03, X06 and X08 extension
proposals. Each of those keeps its other cited sources, so no proposal lost its
last attribution.

## What it supplied

A source-level review with independent executed mathematics: 262 mathematical
checks passed, including 250 deterministic randomized exact-polynomial cases, of
which 186 showed the old nonlinear frontier rule understating the omitted
logarithmic polynomial's degree. Six patch-helper unit tests passed. **No native
Wolfram execution**: the connector could not connect and no local kernel was
available. It supplied twelve native regression candidates, a fresh-kernel runner,
sixteen built-in comparison fixtures, and a hash-guarded patch applicator.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-1/code-review-2/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-1/code-review-2
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-2 2396cb6 && ls /tmp/review-2/external-reports/code-review/wave-1/code-review-2
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 1 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
