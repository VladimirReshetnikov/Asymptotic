# Principal-logarithm normalization and real exponents

This note records W3-10 from [report 23, N01](../../external-reports/code-review/wave-3/code-review-23/results/novelty_ledger.json).
The [wave-3 intake](WAVE_3_INTAKE.md) and [review register](CODE_REVIEW_STATUS.md)
track the implementation milestone. The source mechanism and mathematical
counterexample have been independently reviewed. The two guards are implemented
and the targeted before/after probes are recorded; **focused native suite
acceptance is pending**. The report's Python models and proposed Wolfram
tests are not executions of the current package. No full-suite result is claimed.

The [13-observation baseline](../../validation/log-power-normalization-baseline.json),
produced by [the bounded probe](../../validation/ProbeLogPowerNormalization.wl),
records Wolfram 15.0.1 for 64-bit Windows at checkpoint `41ac72d`, with
55 kernel hashes and `SourcesUnchangedDuringRun -> True`. Both public depth
witnesses returned `y + y^2 Log[y]^2`. Flat multiplication replaced the
winding scalar by `-Log[y]^2`. The exact-core depth-one probe instead
retained `Log[y^a]^2`; that observation concerns unsupported model admission,
not the same changed finite expression. Exact native winding-zero values
and the divergent normalized-error limit are recorded separately.

The [same 13 probes after the guard](../../validation/log-power-normalization-after-guard.json)
record unchanged sources during that run and preserve the real-negative and
positive-scaled real controls. Both public depth witnesses now return
`UnsupportedInput`; the exact-core witness returns
`UnsupportedCorePerturbation`, and flat multiplication returns
`UnsupportedFlatCoefficient`. The complex-exponent parser probes return
`$Failed`. These are bounded characterizations, not the acceptance suite.

The [focused acceptance runner](../../validation/CheckLogPowerNormalization.wl)
will record its result in `validation/log-power-normalization-tests.json`.
The baseline characterizes the defect; it does not establish acceptance of
the guard or correctness of every parser consumer.

## Identity required before constructing a model

For a positive local coordinate `u` and fixed real `k`, principal powers
give `Log[u^k] == k Log[u]`. The exponent need not be positive. For
`Log[c u^k]`, a proved positive `c` is an additional sufficient condition.
See the official [Log](https://reference.wolfram.com/language/ref/Log.html)
and [PowerExpand](https://reference.wolfram.com/language/ref/PowerExpand.html)
references for the principal-branch distinction.

If `k = alpha + I beta`, the actual imaginary part is
`Arg[Exp[I beta Log[u]]]`, not the unbounded `beta Log[u]`. For fixed
nonzero `beta`, shrinking a neighborhood of zero or infinity cannot make
the discarded winding vanish throughout the positive approach. This is
an identity obligation, before the reality and ordering checks of a
finite coefficient model.

Both logarithm rules in
[`parseFinite`](../../src/Kernel/AsymptoticAnalysis.wl) now require
`TrueQ[Simplify[Element[k, Reals], ass]]`, in addition to independence from
the local variable and the scaled rule's existing positivity check.
An inconclusive proof leaves the logarithm unnormalized; the finite parser
then returns `$Failed` and its caller retains the applicable unsupported-input
failure. Do not replace this with a sign condition on `k`, a numerical sample,
or a blanket rejection of temporary complex expressions.

The proof uses the retained `ass` inside the public
[neutral assumption scope](ASSUMPTION_CONTEXT.md). Later ambient assumptions
must not supply an unrecorded realness hypothesis. Exact structural
cancellation before parsing remains valid. Explicit native backends preserve
their own complex/formal result contracts and do not acquire a new real-input
restriction from this parser guard.

## Real source counterexample

Under `a^2 == -1`, both `a == I` and `a == -I` give

```text
f(x) = x + x^2 Log[x^a]^2 = x - x^2 P(Log[x]),
P(t) = Arg(Exp[I t])^2.
```

`P` is continuous, periodic, bounded by `Pi^2`, and Lipschitz with constant
`2 Pi`. For `0 < x <= 1/(4 (Pi^2 + Pi))`, the piecewise derivative of `f`
is at least `1/2`; continuity across its corners gives strict monotonicity.
The [mathematical chapter](../article/sections/12-boundaries.tex),
`sec:log-power-normalization`, proves existence of the real inverse and
the exact sequence counterexample.

At `y_n = Exp[-2 Pi n]`, the true inverse satisfies `g(y_n) == y_n`.
The branch-erased model instead produces the depth-one candidate
`y + y^2 Log[y]^2` with a claimed `O[y^3 (1 + Abs[Log[y]])^4]` tail.
The error-to-scale ratio is exactly

```text
Exp[2 Pi n] (2 Pi n)^2 / (1 + 2 Pi n)^4,
```

which diverges. Realness of the final coefficients therefore does not
establish source equality; this differs from C07's
[coefficient reality](REAL_COEFFICIENTS.md) and C16's unresolved general
analyticity admission.

The scaled real witness
`x + x^2 (Log[2 x^a] + Log[x^a/2])^2/4` is the same function on this
parameter domain. Its real `Log[2]` contributions cancel, so it exercises
the scaled rewrite without relying on an unrelated rejection for nonreal
final coefficients.

## Shared consumers and focused validation

The shared parser is used by more than symbolic-depth inversion:

| Source | Consumed information |
| --- | --- |
| [AsymptoticAnalysis.wl](../../src/Kernel/AsymptoticAnalysis.wl) | Finite source rows for the depth inverse. |
| [CorePerturbation.wl](../../src/Kernel/CorePerturbation.wl) | Exact core and perturbation rows. |
| [ExponentialCorePerturbation.wl](../../src/Kernel/ExponentialCorePerturbation.wl) | Perturbation growth and logarithmic degree. |
| [FlatSectors.wl](../../src/Kernel/FlatSectors.wl) and [FlatSectorOperations.wl](../../src/Kernel/FlatSectorOperations.wl) | Phases, cores, and exact sector coefficients. |
| [LambertInverse.wl](../../src/Kernel/LambertInverse.wl) | Logarithmic cores and discarded exponential-core perturbations. |
| [LogarithmicScales.wl](../../src/Kernel/LogarithmicScales.wl) and [SourceCoordinates.wl](../../src/Kernel/SourceCoordinates.wl) | Scale and coordinate admission. |

Characterize the private parser, core constructor, and public depth call
separately: an earlier public refusal does not show that the parser identity
was sound. Include the scaled real witness, unproved exponents, proved-real
exponents of either sign, positive scaled bases, exact cancellation, and
stored-assumption reuse. Representative exact-core and flat consumers check
that the shared fix preserves their existing valid logarithmic inputs.
Record actual failure tags rather than assuming every caller takes the same
route. Native principal-log evaluations provide independent branch controls.

## Constructive periodic extension remains separate

The same example has the valid approximation
`g(y) = y + y^2 P(Log[y]) + O[y^3]`. Continuous strict monotonicity and the
existing transport theorem first give `g(y) = y + O[y^2]`; the Lipschitz
bound then controls `P(Log[g(y)]) - P(Log[y])` by `O[y]`. The mathematical
chapter supplies the short proof.

This is a theorem for a retained bounded periodic coefficient, not an
implemented new constructor. Its accumulating corners do not satisfy the
analytic or arbitrary derivative contracts of the finite Fourier engine.
A fixed finite Fourier approximation introduces a separate coefficient
error and cannot silently retain the cubic remainder. Any future API needs
explicit value, regularity, parameter-domain, and remainder contracts.
