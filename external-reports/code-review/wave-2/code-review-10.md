# Review package 10 — retired

*Asymptotic 1.8.0 — focused delta audit and native evidence*

| | |
| --- | --- |
| Wave | [2](README.md) |
| Reviewed snapshot | [`921387e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6) |
| Review date | 9 September 2026 |
| Supplied files | 26 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Its soundness finding is implemented and focused verified. Its only other entry
is the shared resource-budget item, which five retained reports also carry.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| N01 | An interval certificate reports `SourceDomainVerified -> True` for an interval the conditional source's domain excludes, under an ambient assumption | C05 | Focused verified | — |
| N02 | Flat multiplication charges inactive coefficient pairs against the work budget | P06 | Decision / pending | reports 1, 4, 6, 8, 16 |

Its restricted affine-domain proof checker was a prototype for the domain helper,
not a finding. The current domain work is tracked under C05 and W4-03.

## What it supplied

The unmodified package and a two-edit temporary standalone were loaded in a
**Wolfram Language 15.0.0, Linux x86-64** kernel, and the combined batch passed
**10/10 targeted checks**. Separately, 20 independent exact mathematical checks
and 20 Python tests passed, including 12 for the affine-domain proof checker.
These are distinct populations, and the full upstream suite was not run.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-2/code-review-10/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-2/code-review-10
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-10 2396cb6 && ls /tmp/review-10/external-reports/code-review/wave-2/code-review-10
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 2 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
