# Review package 40 — retired

*AsymptoticAnalysis: two missed Abs contracts*

| | |
| --- | --- |
| Wave | [5](README.md) |
| Reviewed snapshot | [`651f202`](https://github.com/VladimirReshetnikov/Asymptotic/tree/651f2029d0b2cd4da9e4dfdf1f4275a124d23b99) |
| Review date | 10 September 2026 |
| Supplied files | 14 |
| Last present at | [`2396cb6`](https://github.com/VladimirReshetnikov/Asymptotic/commit/2396cb6) |
| Removed in | `fdb25cf` |

## Why it was removed

Both of its findings are duplicates. Three wave-5 packages independently reported
the same signed-real `Abs` shortcut, and two reported the same loss of a classical
derivative contract. Retaining report 37 for the first and report 42 for the
second leaves exactly one copy of each.

Retirement removes a redundant copy of an obligation, never the obligation
itself. Nothing below is closed because this package is gone, and nothing below
was closed *by* removing it.

## Entry-by-entry disposition

| Entry | Contribution | Register item | Status | Still carried by |
| --- | --- | --- | --- | --- |
| ABS-01 | The signed-real modulus shortcut accepts complex retained terms, and outer cancellation conceals a wrong real answer | wave 5, no intake yet | Duplicate finding, one unique witness | the finding is retained as [report 37 F01](code-review-37/README.md) and was also reported by retired report 41; its logarithmic witness is preserved as a case in [wave5-modulus-witness.json](../../../validation/wave5-modulus-witness.json) |
| ABS-02 | A finite modulus tail inherits unjustified classical differentiability | wave 5, no intake yet | Duplicate finding, different witness and entry point | retained [report 42 N01](code-review-42/README.md), which uses `R(y) = y^3 Sin[Log[y]]` through `AsymptoticInverse`; this package's `AsymptoticFourierInverse` route and its exact source family are recorded below |

Its ABS-01 witnesses used a literal `I`, as in `Abs[1+I u]+Abs[1-I u]`. Report 41
argued that such inputs are rejected by the package's input screen, so report 37's
`a^2 == -1` witnesses are the publicly reachable ones — which is why 37, not 40,
is the retained copy.

Two contributions here were **not** duplicates, and both are preserved rather
than dropped. Its logarithmic witness `Abs[Log[u]+I]+Abs[Log[u]-I]`, whose exact
value `2 Sqrt[Log[u]^2+1]` omits `-1/Log[u]` and does not lie in the
power-logarithmic scale at all, appears in no retained package; restated with
`a^2 == -1` it is now a case in
[wave5-modulus-witness.json](../../../validation/wave5-modulus-witness.json),
and the scale boundary it exposes is Proposition 3.6's constant-leading-block
hypothesis in the article. Its ABS-02 reached the derivative-contract defect
through `AsymptoticFourierInverse` on an exact elementary source, naming
`src/Kernel/FourierCoefficients.wl` lines 205–237 (the Fourier constructor's
default derivative order) as part of the affected path; retained report 42's N01
reaches the same defect through `AsymptoticInverse` with a declared input
remainder and a different family, `R(y) = y^3 Sin[Log[y]]`. The Fourier entry
point is therefore witnessed only here.
Its `code/modulus_jet.py` reference algorithm — square the norm, take the positive
root, transport error by the reverse triangle inequality — is preserved as
mathematics in [article section 3.2](../../../docs/article/sections/03-forward.tex),
and its cusp family `f(x) = x + x^2 Sin[Log[x]]` as Example 16.2 in the
article's section 16, whose source file is
[17-calculus.tex](../../../docs/article/sections/17-calculus.tex) — the file
prefix is not the section number.

## What it supplied

18 independent Python test methods passed on Python 3.13.5 with SymPy 1.14.0,
covering the identities, the cusp construction, the reference modulus algorithm
and exact-anchor patch fixtures. **No native package execution**: the Wolfram
service returned HTTP 502 and upstream errors, and the nine supplied WLT
regressions and the characterization script were never run.

No package-specific licence or notice file was supplied.

## Reading the original package

The directory is unchanged in Git history. Nothing in it was edited before
removal.

```bash
git show 2396cb6:external-reports/code-review/wave-5/code-review-40/README.md
```

```bash
git ls-tree -r 2396cb6 --name-only external-reports/code-review/wave-5/code-review-40
```

To work with the whole package, restore it into a scratch worktree rather than
this checkout:

```bash
git worktree add /tmp/review-40 2396cb6 && ls /tmp/review-40/external-reports/code-review/wave-5/code-review-40
```

## See also

- [Retirement register](../README.md#retired-review-packages) — all ten retired packages and the rule applied
- [Wave 5 index](README.md) — the retained packages
- [Implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) — current item statuses and the complete finding crosswalk
