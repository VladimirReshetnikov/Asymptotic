# Native series and analytic remainder contracts

This note records the C03 export and C06 analytic-import decisions in the
[code review register](CODE_REVIEW_STATUS.md). The
[user guide](../../src/Documentation/UserGuide.md#native-series-remainder-view)
describes the public behavior. Implementation and focused native validation
are separate evidence; this document does not certify a test run.

The separate `"Kind" -> "Native"` representation preserves a built-in result
without asserting these analytic contracts. It is available through explicit
native backends and selected automatic routes. See
[native compatibility and routing](NATIVE_COMPATIBILITY.md) and
[native result contracts](NATIVE_RESULT_CONTRACTS.md). A representation fallback
does not establish a hypothesis that the analytic importer failed to prove.

## Formal representation and analytic meaning

Wolfram Language represents rational exponent series by
`SeriesData[x, x0, coefficients, nmin, nmax, den]` and displays omitted terms
using `O`. Logarithms and other functions that grow slower than powers may
occur in its coefficients. These are documented representation conventions,
not a separate logarithmic degree field for the unknown tail.
[SeriesData](https://reference.wolfram.com/language/ref/SeriesData.html),
[Series](https://reference.wolfram.com/language/ref/Series.html),
[O](https://reference.wolfram.com/language/ref/O.html).

The package's analytic representations additionally assert a magnitude bound
on a retained real branch:

```wolfram
PowerLogRemainder[w, rho, degree]
```

means `O[w^rho (1 + Abs[Log[w]])^degree]` for positive `w` tending to zero.
In the formal exponent filtration, `w^rho Log[w]` is omitted at exponent
`rho`; analytically it is not `O[w^rho]`. The two conventions must not be
silently identified. This policy does not redefine Wolfram Language's formal
series arithmetic.

## Outgoing optional view

For an otherwise eligible view, the shared exporter refuses a nonzero
remainder of positive logarithmic degree with

```wolfram
Missing["LogarithmicRemainder",
  <|"RemainderPower" -> rho, "RemainderLogDegree" -> degree|>]
```

The sparse coefficients, `Normal`, complete remainder and supported package
operations remain available. The guard concerns the **remainder degree**;
it must not reject logarithms in retained coefficients when that degree is
zero. Preserve the precedence among the existing coordinate, irrational-exponent,
exact-result and dense-allocation guards. In particular, this change neither
adds an exact native export nor weakens the retained-slot allocation limit.

Independent controls are an omitted `x^2 Log[x]` block, which requires degree
one, and a retained `x Log[x]` with an omitted `x^3`, whose remainder has
degree zero. Both forward and inverse views use the same export contract.

## Incoming unknown tail

This section applies only when native output is promoted into a package
analytic representation. A preserved `NativeResult` needs no such promotion
and receives `Missing["NativeContract"]` for its package remainder.

For an admitted function and branch, suppose a separate finite-order theorem
establishes `E = O[w^rho M^D]`, where `M = 1 + Abs[Log[w]]` and `D` is some
fixed finite degree. For every fixed positive `epsilon`, power dominance
gives `E = o[w^(rho - epsilon)]`. A native lattice spacing `1/q` therefore
permits the conservative choice `epsilon = 1/(2 q)` with reported degree
zero. Finite logarithmic degree is a sufficient hypothesis; the shape of a
`SeriesData` object does not establish it by itself.

When a complete omitted block `w^beta C[Log[w]]` is visible and the remaining
unknown tail has an independently justified exponent `rho > beta`, choose
`epsilon < rho - beta`. The unresolved part is then `o[w^beta]`, so the
visible block supplies a bound of power `beta` and degree `Exponent[C[L], L]`.
At equal powers the unknown tail degree is still relevant. Looking one order
further without resolving the tail does not prove a degree-zero boundary.

The formal cutoff selects complete retained blocks; a conservative analytic
bound can have a smaller exponent. Every subsequent precision decision must
use the returned bound. Negative source powers and exact prefactors must
transport this bound before it is compared with discarded blocks or used by
an operation. Multiple uncertain contributions retain their own errors until
an applicable absorption argument combines them.

The public regression trigger is

```wolfram
AsymptoticExpansion[EllipticK[1 - x^2]/x^3, {x, 0, 3}]
```

Its first omitted power-three block has a nonzero logarithmic coefficient,
so power three with degree zero is not a valid error class. A smaller-power
degree-zero bound or a justified power-three logarithmic bound is acceptable;
the contract does not require the sharpest representable bound. This note
does not prescribe a particular lookahead depth or assert a native test
result. To require an analytic result, the example can explicitly select
`"Backend" -> "Package"`; an automatic native fallback has a different
contract and is not an alternative proof of the displayed analytic bound.

## Automatic delegation is not analytic promotion

Automatic routing can preserve native-only options and request structures, or
retry a selected real-representation failure using one native backend. The
returned `OrderConvention -> "Native"` identifies the backend's order, which
is not translated into the package's exclusive cutoff or nonzero-block goal.
`PackageFailure` retains the preceding representation failure when one
occurred; its absence for direct native routing does not supply analytic
evidence. `NativeEvaluationStatus -> "Computed"` is only an evaluation status.

Native `SeriesData` may carry formal orders in complex or successive
expansions. Native `Asymptotic` may return a finite expression without an
explicit tail. Both retain `Exact -> Missing["NotEstablished"]` and no package
analytic remainder. `Normal` can preserve an infinite expression, and analytic
arithmetic or refinement declines native objects with `NativeSeriesContract`.
Native formal operations remain available through `NativeResult`.

Explicit branch, direction and resource requests conservatively retain the
package path in Automatic mode. So do existing series and remainder inputs;
their unknown errors must not become native exact coefficients by delegation.
The routing policy is narrower than complete native input coverage.

Fallback after a package attempt reuses the prepared source and specifications
and materializes the already-consumed common options. Preparation evaluates
the source in the neutral package proof context; literal explicit native calls
release it under the captured ambient context. Computed trailing arguments and
option containers are resolved before backend selection while the source stays
held. This prevents wrapper replay of the original source on fallback; it does
not freeze surviving symbol definitions or promise arbitrary side-effect
ordering identical to a direct native call. Use the held `OriginalArguments`
and actual `NativeRequest` together when diagnosing these distinctions.

## Proof sources and maintenance obligations

The mathematical article separates the exponent quotient from analytic
remainders in [the power-log scale](../article/sections/02-scale.tex).
[Finite-order propagation](../article/sections/03-forward.tex), especially
`lem:tail` and `prop:soundness`, requires complete input-tail assertions.
[The inverse remainder theorem](../article/sections/08-remainders.tex)
derives its first omitted block from that complete-tail control.
[The special-function chapter](../article/sections/35-special-function-expansions.tex),
`lem:special-function-logarithmic-margin`, proves the exponent allowance and
states its finite-degree premise.

Maintain these distinctions when extending native ingress:

- Real-valuedness on an approach is a branch condition, not an asymptotic-tail
  theorem. An arbitrary unknown function or manually constructed formal
  series must not acquire a tail proof from its syntax.
- Kept coefficient degrees, a vanished sampled coefficient, and an
  unevaluated native expansion do not establish an unknown degree or exactness.
  Exact special-function identities need their separate exactness proof.
- A fixed finite degree may depend on fixed parameters. Uniform constants
  and thresholds require uniform hypotheses; a degree varying with the small
  coordinate is outside the allowance lemma.
- An asymptotic error class has an unspecified constant. It does not supply
  a pointwise certificate, convergence, or a differentiated error bound.
- Refinement can improve the bound by obtaining more justified source
  information. It must not relabel an unchanged unknown tail at a stronger
  power or a smaller logarithmic degree.
