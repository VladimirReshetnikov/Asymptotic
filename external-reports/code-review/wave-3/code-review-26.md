# Review package 26 — retired

*AsymptoticAnalysis: incremental native-boundary audit*

| | |
| --- | --- |
| Wave | [3](README.md) |
| Reviewed snapshot | [`6687962`](https://github.com/VladimirReshetnikov/Asymptotic/tree/6687962f3c858a4f93623cfc496f33e35c6763d4) |
| Review date | 9 September 2026 |
| Supplied files | 19 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Nothing here is implemented yet, and nothing here is unique. Every entry restates
a wave-3 work item that three to seven retained packages also report, so this is
the one wave-3 package that adds no obligation of its own.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| N1 | Configured public routing defaults and copied alias defaults are ignored by the dispatcher | W3-01 | Pending | reports 19, 20, 21, 23, 24, 25, 27 |
| N2 | An equivalent string option spelling is rejected by structural held-key comparison | W3-02 | Pending | reports 19, 20, 21, 24, 25, 27 |
| N3 | A valid option-named positional variable loses its specification metadata and numerical application | W3-02 | Pending | reports 19, 20, 21, 24, 25, 27 |
| P-N1 | The native constructor eagerly builds `Normal` even for native-result-only use | W3-04 | Pending | reports 19, 20, 25 |

It proposed an alias-default ownership policy distinct from the primary-only
repairs in reports 19, 21, 25 and 27. That alternative is **not** lost: the
[wave-3 intake](../../../docs/development/WAVE_3_INTAKE.md) records both it and
report 20's competing alternative as open options, and report 20 is retained.

## What it supplied

The unmodified pinned standalone passed 90 tests across four existing
native-interface files in **Wolfram Language 15.0.0 for Linux x86-64**. A
candidate corrected five focused probes and passed 68 existing tests in
`NativeAutomatic.wlt` and `NativeCompatibility.wlt`; the supplied 25-case
regression file was not executed. Wrapper sizes at native orders 100 and 1000
are `ByteCount` observations, not peak memory or runtime.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-3/code-review-26/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-3/code-review-26
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-26 2396cb6 && ls /tmp/review-26/external-reports/code-review/wave-3/code-review-26
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 3 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
