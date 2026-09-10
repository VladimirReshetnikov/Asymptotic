# Review package 41 — retired

*AsymptoticAnalysis: incremental technical audit*

| | |
| --- | --- |
| Wave | [5](README.md) |
| Reviewed snapshot | [`8e85996`](https://github.com/VladimirReshetnikov/Asymptotic/tree/8e859961d7d37f008b826f3a8cad406460271614) |
| Review date | 10 September 2026 |
| Supplied files | 22 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Its single finding is the same signed-real `Abs` shortcut reported by retained
report 37 and by retired report 40. Its two development proposals were mathematics
rather than defects, and both were merged into the mathematical article before
removal.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| ABS-01 | A positive real leading coefficient is treated as proving the whole finite approximation real; a complex parameter then cancels after the invalid nonlinear rewrite | wave 5, no intake yet | Duplicate | retained [report 37 F01](code-review-37/README.md); also reported by retired report 40 |
| MOD-01 | Proposal: a modulus of complex finite coefficients on a positive real coordinate, with error transport by the reverse triangle inequality | — | Merged into the article | [section 3.2](../../../docs/article/sections/03-forward.tex), Proposition 3.6 and Remark 3.7 |
| PERF-01 | Proposal: Hermitian pairing for the modulus-specific finite convolution, 2080 versus 4096 pairs at support 64 | — | Merged into the article | [section 3.2](../../../docs/article/sections/03-forward.tex), Remark 3.7 |

This package gave the most rigorous treatment of the shared finding, including
the argument that the literal-input screen is not a codomain proof and the
`a^2 == -1` witnesses that respect it. That reasoning is why report 37, whose
witnesses use the same device, is the retained copy rather than report 40. The
witnesses themselves are now reproduced on the current source in
[wave5-modulus-witness.json](../../../validation/wave5-modulus-witness.json).

## What it supplied

115 independent mathematical, model and synthetic patch-fixture checks passed on
Python 3.13.5 with SymPy 1.14.0. **No Wolfram or Mathics package execution
succeeded**: the Wolfram service returned connection and 502 failures and no local
Mathics install was available, so its eight Wolfram regressions and its exact
package patch remain unvalidated in a kernel. It also carried a transcribed
`source-excerpts/fwdAbs.baseline.wl` with its own `PROVENANCE.txt`.

It supplied `LICENSE-AUDIT.txt` for its own material and `UPSTREAM-LICENSE.txt`
for the upstream excerpt. Both are preserved in Git history; nothing was edited
or relicensed.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-5/code-review-41/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-5/code-review-41
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-41 2396cb6 && ls /tmp/review-41/external-reports/code-review/wave-5/code-review-41
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 5 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
