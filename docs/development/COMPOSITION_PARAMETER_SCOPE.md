# Parameter scope in composition

C15 concerns the fixed parameters of an outer remainder when the inner
expansion introduces a new varying symbol. It consolidates
[R11 N02](../../external-reports/code-review/wave-2/code-review-11/evidence/findings-delta.json)
and R14 N01 in the [review register](CODE_REVIEW_STATUS.md); report 14 is now
[retired](../../external-reports/code-review/wave-2/code-review-14.md). Its C15
and C20 entries are focused verified, its C21 entry for the ordinary checker,
and its C22 entry for truncation only — C22's arithmetic transport remains
open.
All 20 focused scope tests pass within the
[276-test acceptance](../../validation/review-normalization-tests.json).
This is a bounded repair of parameter capture, not a general uniform-asymptotic
solver or full-suite acceptance.

## The quantifier that composition must preserve

For each fixed parameter `a`, a statement

```text
F(x,a) = J(x,a) + O_a(x^P (1 + |log x|)^D)
```

means that there are a constant `C(a)` and a threshold `delta(a)` for that
parameter. Substitution of `x = v(w)` and `a = a(w)` requires the joint
path to remain below the applicable threshold. Its transported error
still contains `C(a(w))`. A bound uniform on that path, or a proved
parameter-dependent majorant transported with it, is necessary to remove
or replace that factor.

The local coordinate condition `v(w) = c w^alpha (1 + o(1))`, with positive
fixed `c` and `alpha`, establishes the endpoint and approach side. It does
not establish parameter uniformity. The mathematical treatment is in
[the calculus chapter](../article/sections/17-calculus.tex), with the
fixed-parameter distinction also developed in
[the scale chapter](../article/sections/02-scale.tex).

For `a > 0`, the exact identity

```text
x/(a+x) = x/a - x^2/(a(a+x))
```

gives `x/a + O_a(x^2)` as `x` tends to zero. On `x = a`, the finite term
is `1`, the discarded term is `-1/2`, and the complete function is `1/2`.
The old remainder cannot become `O(a^2)` on this diagonal.

Checking retained coefficients alone is insufficient. At cutoff 2, both
`1 + x^2/a^2` and `Cos[x/a]` retain the constant `1`. Their diagonal values
are respectively `2` and `Cos[1]`. The fixed parameter can occur only in
the discarded source, or remain in an earlier operand after truncation.

## Baseline observations and independent expectations

[The local baseline characterization](../../validation/composition-scope-baseline.json)
records ten bounded public probes against the `6687962` source snapshot
on Wolfram Language 15.0.1 for Windows, with stable source hashes. The
[probe source](../../validation/ProbeCompositionScope.wl) identifies the
calls; this is a characterization report, not an acceptance suite.

| Case | Recorded baseline behavior | Required conclusion |
| --- | --- | --- |
| `x/(a+x)` with exact inner `a` | `1 + O(a^2)` | Exact value `1/2`, or refusal if a new proof is unavailable. |
| `1 + x^2/a^2` at outer cutoff 2 | `1 + O(a^2)` | Exact diagonal value `2`. |
| `Cos[x/a]` at outer cutoff 2 | `1 + O(a^2)` | Exact diagonal value `Cos[1]`. |
| Truncated outer retaining an earlier source recipe | `1 + O(a^2)` | Inspect the earlier source scope; its remainder is still nonuniform. |
| Outer assumptions `a > 1`, inner `a -> 0+` | Retained `a > 1` while returning the false diagonal bound | Reject the incompatible parameter regime. |
| Exact outer `x/a`, inner `a + O(a^2)` | `1 + O(a)` | Preserve this valid amplification of inner uncertainty. |

R11 separately records selected native observations on its historical
revision; [its README](../../external-reports/code-review/wave-2/code-review-11/README.md#what-ran)
states that scope. R14 supplied source tracing and independent mathematical
checks, with no native Wolfram execution. Neither report is current acceptance
evidence, and the acceptance records linked above are.

## Admission and replay contract

[`SeriesOperations.wl`](../../src/Kernel/SeriesOperations.wl) centralizes
composition admission in `seriesCompositionAdmission`.

1. `seriesCompositionScope` inspects the retained expression, source,
   assumptions, domain, remainder data, coordinate data, and recursively
   retained operation operands. A parameter hidden by discarded terms is
   still relevant. Source variables of inverse equations are bound and
   must not be mistaken for fixed parameters.
2. A nonexact outer object with insufficient retained source or operation
   scope is refused with `MissingParameterScope`. Detectable capture
   requires a new joint proof; relabeling the old bound is forbidden.
3. `seriesCompositionSourceReplay` currently admits a complete `Forward`
   source and an exact `Forward` inner expression. It excludes source
   expressions containing declared remainder objects, native `SeriesData`,
   embedded generalized series, or inverse-function expressions.
4. Replay substitutes the exact inner expression into the complete outer
   source, retains both original domains, and calls the strict
   `"Backend" -> "Package"` constructor in the inner variable and chart.
   Original parameter assumptions involving that variable become approach
   conditions and must hold on the joint path.
5. The resulting `Forward` object retains the new composed source for
   refinement. Its `CompositionScope` records that the original outer
   remainder was not transported and no uniform parameter bound was asserted.

If this replay is unavailable, detectable nonexact capture returns
`ParameterCapture`. Derived outer recipes are inspected to detect capture;
they are not generally reconstructed as exact source functions. An
unsupported strict replay can return the constructor's more specific
failure. The explicit
[`ReciprocalLogCompose` entry](../../src/Kernel/ReciprocalLogOperations.wl)
shares scope admission and conservatively declines moving carrier parameters.

## Exact expressions and uncertain inputs

An exact outer identity has no outer remainder needing uniform transport.
For example, `x+a` composed with exact `a` gives `2a`. Its parameter and
branch conditions must nevertheless hold along the joint approach.

An exact outer expression can act on an uncertain inner object through
the existing precision calculus. The identity `x/a`, with
`x = a + O(a^2)`, gives `1 + O(a)`. Exactness of the outer expression
does not erase the inner error or justify keeping its old power.

Conversely, a known exact source behind a *truncated* inner object does
not make the supplied object exact. Replaying that source silently would
replace the user's approximation and its error contract. The current
joint replay therefore requires zero inner remainder and established
exactness; it does not refine or substitute the inner source implicitly.

## Limits and focused checks

This is bounded source replay, not a general uniform-asymptotic solver.
There is no public uniform-majorant input, general reconstruction of
derived outer sources, joint inverse-equation solver, or automatic
sensitivity proof for a captured nonexact inner object. Ordinary Wolfram
symbol definitions and hidden callable dependencies are not frozen by
retaining an expression; opaque-function analyticity remains the separate
C16 source-admission issue.

Refinement in a fixed-parameter regime does not by itself repair a diagonal
bound. Arithmetic and coordinate changes likewise do not supply a missing
uniformity theorem. Future parameter-specialization or shifting operations
must preserve the same distinction between fixed data and varying coordinates.

[`ReviewCompositionScope.wlt`](../../src/Tests/ReviewCompositionScope.wlt)
contains 20 focused tests covering the independent examples, hidden source
dependencies, exact and uncertain inner objects, incompatible conditions,
infinite endpoints, bound inverse variables, replay refinement, option
validation, and both composition entries. The
[fifteen-file acceptance](../../validation/review-normalization-tests.json)
passes **276 tests, zero failures**, including all 20 scope cases and 23
equal-exponent cases, on Wolfram 15.0.1 Windows with unchanged source hashes.
The [first 43-case run](../../validation/review-scope-and-equality-first-pass.json)
passed 42 tests: the violated source-condition case was refused with a
coefficient error instead of the required condition error. Replay now checks
that condition before substitution can collapse a `ConditionalExpression`.
The full package suite was skipped.
