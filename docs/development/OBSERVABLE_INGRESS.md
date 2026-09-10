# Observable Taylor information and approach sides

W3-06 consolidates the generic observable findings in
[report 21, AUDIT-D01](../../external-reports/code-review/wave-3/code-review-21/evidence/novelty_ledger.json),
[report 22, T01](../../external-reports/code-review/wave-3/code-review-22/evidence/novelty_ledger.csv),
and [report 25, N01/N02](../../external-reports/code-review/wave-3/code-review-25/evidence/novelty_ledger.json).
See the [wave-3 intake](WAVE_3_INTAKE.md) and
[review register](CODE_REVIEW_STATUS.md) for current implementation status.
The implementation is present for focused validation; acceptance is pending
at the time of writing. The full suite is not being run.

## Reproduced baseline and independent counterexamples

[The baseline receipt](../../validation/observable-ingress-baseline.json)
records nine bounded observations on Wolfram Language 15.0.1 for 64-bit
Windows. It includes 53 kernel source hashes and
`SourcesUnchangedDuringRun -> True`. These are characterizations of the
loaded baseline, not passing acceptance tests for the repair.

| Input information and operation | Recorded baseline result | Independent reason it is insufficient or wrong |
| --- | --- | --- |
| A truthful custom sine provider returns `u + O(u^2)`; compose with exact `x` at cutoff 5. | `x + O(x^5)` | `Sin[x] - x` divided by `x^3` tends to `-1/6`; it is not `O(x^5)`. The returned provider order establishes only the coarser bound. |
| Exact inner `1-x`; apply `FractionalPart` near `x -> 0+`. | `-x + O(x^2)` | For `0<x<1`, the exact value is `1-x`. The missing constant is not an error tending to zero. |
| Truncate that inner source to `1 + O(x)` before applying `FractionalPart`. | `O(x)` | The supplied object does not determine the side. Its source `1-x` already contradicts the returned bound. |

The receipt also contains a direct native left-sided control, returning
`1-u + O(u^3)`, and right-sided, exact-point, and nonjump controls. The
left native constant was correct; the former consumer replaced it with
`FractionalPart[1] == 0`. A switch of native analytic options alone would
not repair this reconstruction error.

The short-provider fixture is not an allegation that built-in `Sin`
returns too little information. It deliberately supplies a truthful prefix
through a custom `Series` handler. A requested order is not the returned
object's postcondition, and absent stored entries beyond that object's
order are not known zeros.

The [separate complex-input receipt](../../validation/observable-reality-first-pass.json)
was recorded after the initial endpoint/side changes and before the real-input
guard. Its 53 source hashes identify that intermediate implementation; it
does not describe the original baseline. With the exact input `x` and stored
assumption `a^2 == -1`, the observable `a Re[a z]` returned `-x + O(x^3)`.
Independent substitution of both possible parameter values, `a = I` and
`a = -I`, gives zero. A real-sided Taylor polynomial for `Re` cannot be
substituted along the complex path `a x`. The fact that the final coefficient
`a^2` is real does not repair that invalid substitution.

This distinguishes two requirements: temporary complex **output** coefficients
can cancel during collection, but the **input path** must satisfy the domain
of the Taylor bound being used. Realness of retained input coefficients alone
is insufficient when a discarded term contains an imaginary displacement.

## Coefficient demand and the logarithmic boundary

Suppose the selected side has an analytic extension with a bounded Taylor
remainder, or another established estimate of the form

```text
h(c + sigma v) = Sum[a_k v^k, k=0,...,q-1] + O(v^q),  v -> 0+.
```

Here `q` is the exclusive known order. Let the positive inner displacement
satisfy `V = sigma (g-c) = O(w^alpha M^d)`, where `alpha > 0` and
`M = 1 + Abs[Log[w]]`. To retain powers strictly below `C > 0`, it is
sufficient to know coefficients with indices below
`N = Ceiling[C/alpha]`. Thus `q >= N` is sufficient; requiring `q > N`
would reject some adequate returned objects.

Truncating at Taylor index `N` contributes
`O(w^(alpha N) M^(d N))`. If `alpha N == C`, the logarithmic degree
`d N` must survive at that boundary. If `alpha N > C`, the strict power
margin absorbs the fixed logarithmic factor into `O(w^C)`. A shorter
returned order `q < N` instead contributes `O(w^(alpha q) M^(d q))`;
it cannot be relabeled with the requested higher power.

Uncertainty in the inner object and discarded blocks in its finite powers
still contribute their own error bounds. The implementation combines those
through the existing unit-series calculus. See the
[mathematical calculus chapter](../article/sections/17-calculus.tex), equations
`eq:sided-taylor-contract` and `eq:sided-taylor-demand`, for the proof and
the fixed-parameter uniformity qualification.

## Point values and sided germs

For a known side, prove `sigma (g-c) > 0` eventually for the complete input
germ, including its uncertainty. A retained leading block below the input
remainder can establish this when its leading logarithmic coefficient has
a proved sign. A guessed sign or a formal positive dummy variable cannot.

At `c = 1`, the three relevant fractional-part values are

```text
FractionalPart[1] = 0
FractionalPart[1-v] = 1-v     (0 < v < 1)
FractionalPart[1+v] = v       (0 < v < 1).
```

An exactly constant input uses the point value without requesting a Taylor
expansion. A proved punctured side uses its native zeroth coefficient,
which need not equal that point value. Changing only the function's value
at the center cannot affect a composition that is eventually separated
from the center.

When no side is proved, the current path compares the positive and negative
Taylor coefficients after reversing the negative displacement:
`a_k^+ == (-1)^k a_k^-` for the consumed indices. The common constant must
also equal the point value, because the input may reach the center.
With only a pure uncertain displacement, the constant comparison supplies
the needed first-order magnitude bound under the admitted sided Taylor
contracts. Disagreement or an unresolved comparison causes refusal.
The original source is not silently refined to recover a lost side.

## Implementation boundary and failures

In [`SeriesOperations.wl`](../../src/Kernel/SeriesOperations.wl):

- `seriesObservableTaylorData` checks the actual returned variable, zero
  center, regular nonnegative integer index range, unit denominator,
  coefficient independence from the dummy variable, and sufficient endpoint.
- `seriesObservableTaylorCoefficient` distinguishes zero entries inside the
  known interval from requests at or beyond its exclusive endpoint.
- The generic branch of `seriesJetApply` handles exact points, proved sides,
  or compatible two-sided Taylor information, preserving the selected constant.

| Failure | Boundary it protects |
| --- | --- |
| `InvalidObservableNativeChart` | The returned native variable or center differs from the requested local chart. |
| `InsufficientObservableNativeOrder` | The returned exclusive endpoint is too short, or a coefficient query crosses it. |
| `UnprovedObservableApproach` | No side is proved and the required Taylor/point compatibility is unproved or false. |
| `UnprovedObservableArgument` | The complete inner argument is not proved real on the represented input approach, so a real-sided Taylor bound cannot be transported through it. |

Existing unsupported-shape, resource, real-coefficient, and stored-assumption
checks remain applicable. Complete observable coefficients are checked after
collection, preserving permitted cancellation of temporary complex terms.

The argument-reality check operates on the complete symbolic argument before
discarding its tail. Its formal input value is renamed independently of the
expansion coordinate: an assumption that the coordinate is positive does not
say that the represented function value is positive. A bounded proof for all
real input values suffices. Local domain proofs additionally need the actual
represented input approach and fixed-parameter hypotheses. A neighborhood
proved with a varying coordinate held fixed is not a joint-domain proof.

These guards preserve available information; they do not prove analyticity
of every opaque function accepted by a native symbolic engine. General
source regularity is still C16. A structurally valid `SeriesData`, a
continuity test, and `Analytic -> False` are each insufficient on their own
to establish every requested Taylor remainder. Native formal result contracts
remain separate from the package's analytic error contract.

## Focused validation

[`ReviewObservableIngress.wlt`](../../src/Tests/ReviewObservableIngress.wlt)
contains the focused repair tests. The expected acceptance receipt is
`validation/observable-ingress-tests.json`; no passing result is asserted
until that run is completed and inspected. Adjacent ordinary observable,
nonlinear logarithmic-degree, coefficient-reality, assumption-replay, and
composition tests are needed to check preservation of their existing contracts.
The [user guide](../../src/Documentation/UserGuide.md#SeriesObservable)
documents the public examples and failure meanings.
