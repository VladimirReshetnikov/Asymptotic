# Equality of exact exponents

The C14 repair collects contributions at provably equal exact weights before
complete blocks are counted or used in remainder and inverse calculations.
It addresses R13 A1 in the [code review register](CODE_REVIEW_STATUS.md).
The [user guide](../../src/Documentation/UserGuide.md#equal-exponent-blocks)
describes the public behavior. All 23 focused exponent cases pass within the
[276-test acceptance](../../validation/review-normalization-tests.json).
The comparator's general proof policy and resource contracts remain separate
work items; this acceptance is not a full-suite result.

## Mathematical contract

An ordinary power-log block is `w^a P[Log[w]]` for positive `w` tending to
zero. If two exact exponents are proved equal, their coefficient
polynomials belong to one block:

```text
a = b  =>  w^a P(L) + w^b Q(L) = w^a (P(L) + Q(L)).
```

The complete coefficient can vanish or have a smaller degree than either
contribution. Collect and simplify it before choosing a leading block,
counting a term goal, or deriving a logarithmic remainder degree.
In particular, the two-pointer product-boundary scan requires distinct,
increasing weights in both operands. Equal numerical values represented by
different expression trees must not occupy separate positions in that scan.

For a forward model used in inversion, cancellation can change the leading
power itself. A cancelled pair must disappear before perturbation gaps and
the corresponding multi-index region are constructed. Two nonzero
contributions at the same power also form one perturbation generator with
their summed coefficient.

## Recorded R13 counterexamples

Report 13 inspected revision
[`921387e5ba1239bfda96e63e64e89bf63d9c41e6`](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6).
Its selected native observations recorded Wolfram Language 15.0.0 on Linux.
These were historical transcriptions of selected calls, not a current
checkout's aggregate test report. The package has since been
[retired](../../external-reports/code-review/wave-2/code-review-13.md),
because C14, C07 and C21 are focused verified and its remaining C12 component
is carried by report 6; the current evidence for this item is the baseline and
acceptance record linked above, not the historical transcription.

Set

```wolfram
a = Sinh[1]^2;
b = (Cosh[2] - 1)/2;
FullSimplify[a - b]
(* 0 *)
```

The identity follows from `Cosh[2 t] - 1 == 2 Sinh[t]^2`. Separately
canonicalizing the two exponents did not give identical expression trees
on the reviewed kernel.

| Request at the reviewed revision | Recorded wrong result | Required result |
| --- | --- | --- |
| `AsymptoticExpansion[x^a - x^b + x^2, {x, 0}, SeriesTermGoal -> 1]` | `Normal[s] == 0`, no returned terms, and a remainder at power `b`. | One exact block `x^2`, with zero remainder. |
| Construct `s` from `1 + x^a + x^b Log[x]^3 + x^(2 a)` at cutoff `2 a`, then call `SeriesMultiply[s, s]`. | Remainder power `2 a` with logarithmic degree `3`. | Remainder power `2 a` with logarithmic degree `6`. |
| `AsymptoticInverse[x^a - x^b + x^2, {x, 0}, {y, 2}]` | `Failure["ResourceLimit", ...]` during multi-index enumeration with `MaxTerms == 20000`. | The exact positive inverse `Sqrt[y]`, with zero remainder. |

For the product, write `q = 1 + Log[x]^3`. The source is exactly
`f = 1 + x^a q + x^(2 a)`, and

```text
f^2 - (1 + 2 x^a q)
  = x^(2 a) (q^2 + 2) + 2 x^(3 a) q + x^(4 a).
```

Since `a > 0`, this difference is asymptotic to `x^(2 a) Log[x]^6`.
It is not bounded by a constant multiple of
`x^(2 a) (1 + Abs[Log[x]])^3`. The degree-six correction repairs an
analytic bound, not only the displayed representation.

The report also records successful reruns of its three examples after an
equality-grouping transformation. That observation concerns the supplied
transformation on the historical snapshot; it does not establish execution
of the current implementation or of the report's complete proposed suite.

## Shared grouping strategy

[`orderedWeightGroups`](../../src/Kernel/AsymptoticAnalysis.wl) operates on
rows whose first entries are canonicalized exact weights:

1. Bucket structurally identical weights, preserving their associated rows.
2. Sort the structural representatives with the existing exact comparator.
3. Join adjacent buckets only when that comparator proves their weights
   equal.

Only the `m` structural representatives are sorted. The subsequent scan
uses at most `m - 1` explicit adjacent equality checks. It does not run an
all-pairs symbolic equality search or retain a global comparison cache.
Ordering comparisons can themselves require symbolic work; this count is
not a wall-clock bound on the native simplifier.

The ordinary `jetMerge` retains its earlier structural coefficient
normalization and zero elimination before the new cross-weight grouping.
Thus a structurally cancelled block does not introduce an unnecessary
ordering proof against another weight. After grouping, only coefficients
in newly combined groups are normalized again. Singleton coefficients are
reused, and complete cancellations are removed.

The same grouping primitive is used by:

- [`logarithmicMerge`](../../src/Kernel/LogarithmicScales.wl), whose
  coefficients can belong to a generalized logarithmic hierarchy.
- The power rows inside each carrier of
  [`specialNativeSectors`](../../src/Kernel/NativeSpecialFunctions.wl),
  before leading-power extraction and amplitude-degree calculation.
- [`fourierWeightGroups`](../../src/Kernel/FourierCoefficients.wl), for
  source weights and frequencies. Its existing semantic grouping contract
  is preserved through the shared implementation.

Each caller retains its own coefficient algebra and simplification policy.
The native amplitude path retains its simplification timeouts. Outer
exponential carriers are not identified by this numeric-weight helper.
Symbolic-depth grouping continues to use its separate assumption-aware
equality checks.

## Distinct powers, undecidable order, and budgets

No tolerance is used to identify weights. For example, `1` and
`1 + 10^-200` are distinct exact rationals. Likewise, the equal class
containing `a` and `b` above is distinct from `b - 10^-100` and
`b + 10^-100`. Their support and ordering must survive collection.

This repair uses the existing `canon`, `compare`, and `equal` machinery.
It does not turn an unresolved comparison into an equality, replace the
strict-order proof policy, or introduce a shared budget for symbolic proof
work. C12 in the [register](CODE_REVIEW_STATUS.md#c12--prove-comparator-equality-and-strict-order-separately)
tracks that broader comparison work. P06 records the proposed separation
of resource categories.

`MaxTerms` continues to count the same admitted sparse products and
enumeration work. The Fourier frequency limit still rejects too many
distinct frequencies. Eliminating a cancelled or duplicate mathematical
generator can reduce the actual work without relaxing either limit.

## Focused checks and evidence boundary

[`ReviewExponentEquality.wlt`](../../src/Tests/ReviewExponentEquality.wlt)
contains 23 focused cases. They cover the three public counterexamples,
three inverse methods, model normalization, one-generator inversion after
nonzero coefficient collection, complete-zero and frontier cancellations,
both addition orders, nine polynomial-degree pairs, input permutations,
very close distinct weights, unresolved-order refusal, structural proof
work, the adjacent coefficient algebras, and existing budget failures.

[`ProbeExponentEquality.wl`](../../validation/ProbeExponentEquality.wl)
records five bounded observations for baseline and repaired source runs:

```powershell
wolfram.exe -script validation/ProbeExponentEquality.wl
```

The probe loads the current modular package from `src/Kernel/`; each
observation has a 45-second cap. It prints the kernel version, elapsed
time, and result. It is an exploratory reproduction tool, not an acceptance
suite. A baseline reproduction requires the corresponding immutable source
snapshot. The [baseline observations](../../validation/exponent-equality-baseline.json)
record those five probes against commit `6687962` with exact source hashes.

The [fifteen-file acceptance](../../validation/review-normalization-tests.json)
passes **276 tests, zero failures**, including all 23 exponent cases and the
20 composition-scope cases, on Wolfram 15.0.1 Windows. The selected neighboring
tests exercise ordinary and inverse arithmetic, Fourier and logarithmic
normalization, assumptions, real coefficients and native-special ingress.
The runner records every tested source hash and verifies that sources did
not change during execution. The full package suite was skipped.
