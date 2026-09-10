# Recent development changes

This is a guide to selected user-visible changes on `main`, with links to
their implementation commits and maintained documentation. It is not a list
of tagged releases or a claim that every historical test was rerun on the
current source. The package manifest currently declares version **1.8.0**;
different commits with that version can expose different behavior. Use
[commit-pinned loading](../src/Documentation/UserGuide.md#loading-fixed-versions)
for reproducible calculations.

The three [complete-coverage requirements](development/COVERAGE_TARGETS.md)
remain open: Wolfram built-in input coverage, Mathics compatibility, and all
asymptotics in the vendored article corpus. The changes below are implemented
milestones within that scope.

## September 10, 2026

### Composite target charts, minimum-precision refinement, and tooling

The composite fallback derives an operand's target endpoint and approach side
from its complete target chart: the reflected `Erfc` adapter now approaches
`2` from below, a negative quadratic curvature approaches its vertex value from
below, and a flat inverse with a pole core tends to a signed infinity instead
of its finite offset (C18). `SeriesRefine[s, h]` with a lower cutoff is documented as deliberate
retargeting that keeps the larger computation cache (D10). The
standalone builder's dependency gate now flags every spelling of a loading
primitive (W3-11). The vendored-PDF tooling preserves POSIX permissions on
publication, captures the TeX recorder after every pass, and updates its
ledger by a locked fresh-read merge (wave-5 report 44 T02–T04).

### Wave-7 contract repairs and arithmetic bound transport

A composite `Sin[s]` or `Cos[s]` of an expansion with a nonzero remainder now
requires the remainder envelope to vanish and otherwise returns
`Failure["UnprovedRealRemainder", ...]`, since a real finite part does not prove
that the omitted error is real; `Abs[s]` keeps its complex Lipschitz bound.
Operand conditions are joined idempotently, so repeated self-addition no
longer triples the stored assumptions. An affine constant charged above a
nonpositive cutoff of a `Zeta` or `LerchPhi` expansion sets the remainder
order to zero and enters the absolute bound as its own term. The reflected
`Erfc` adapter's `"FrontierTerm"` carries the source sign.
`AsymptoticCoreInverse` validates the core and the perturbation separately and
refuses a target-dependent offset that cancels in their sum. A membership
condition on an observable is proved only on an exact jet. The standalone
builder's Mathics bootstrap keeps association delimiters whole. `SeriesAdd`
and `SeriesMultiply` now transport the explicit tail bound of `Zeta` and
`LerchPhi` expansions, recording `"ArithmeticDiscardedPart"`, and the
certificate evaluator memoizes its affine recognizer within one attempt. The
certificate logarithm keeps relative precision near one: a rational below one
is enclosed as the negated logarithm of its reciprocal, and a rational affine
argument passes its exact range to the logarithm instead of a dyadically
rounded interval, so `Log[1 - 2^-200]` and `Log[1 + 2^-200]` certificates at
enclosure order 2 succeed instead of failing with
`ResidualBracketOutsideInterval`. See
the [implementation register](development/CODE_REVIEW_STATUS.md) (wave-7
reports 56–63, C22, wave-5 reports 39 N02 and 42 N02).

### Modulus of nonreal expansions

The forward `Abs` no longer replaces a modulus by its signed argument when a
retained coefficient is not provably real. Under `a^2 == -1`,
`Abs[1 + a x] + Abs[1 - a x] - 2` previously expanded to exact `0`; it now
expands to `x^2 (Abs[a]^2 - Re[a]^2) + O[x^4]`, which is `x^2 + O[x^4]` at
`a = ±I`, through the norm square on the real coordinate and its positive
root. A nonconstant logarithmic leading block with nonreal coefficients is
refused with `LogarithmicLeadingPower`. A modulus applied to a nonzero
remainder records `"RemainderDerivativeOrder" -> 0`, so `SeriesDifferentiate`
refuses a derivative that the magnitude bound cannot justify. Real-coefficient
behaviour is unchanged. See the
[operations guide](../src/Documentation/UserGuide.md#series-operations) and the
[implementation register](development/CODE_REVIEW_STATUS.md) (wave-5 reports
37 F01 and 42 N01).

### Wave-5 contract repairs

`SeriesPower[s, 0]` and `s^0` require a retained leading coefficient that is
provably nonzero on the parameter domain and refuse a pure remainder; on a
Gamma or Barnes inverse the requested cutoff is recorded. `InverseNumericalCheck`
selects, for an exact numeric polynomial source, the unique equation root on
the monotone component incident to the endpoint and reports
`"EndpointComponent"` and `"BranchComponentVerified"`, so an approximation that
is itself an exact root of another branch no longer produces a zero error.
`InverseExpansionCoefficient` on a result object returns `"SourceOrientation"`,
`"ObservableCoefficient"`, `"AdditiveOffset"` and `"ContributionExpression"`;
`PowerLogModel` returns `"ModelOffset"` and `"TargetLimit"` beside the legacy
`"Limit"`; `PerturbativeInverse` refuses a core containing the source symbol;
the Gamma/LogGamma adapters name the scope of their derivative lower bounds;
and a no-op `SeriesTruncate` keeps `"TruncationDiscardedPart"`. On Mathics an
exact rational seed such as `1/2` is verified by substitution instead of being
refused. See the [implementation register](development/CODE_REVIEW_STATUS.md)
(wave-5 reports 37, 38, 39, 42, 43, 45).

### Wave-6 public-boundary repairs

Seven public behaviours reported by the sixth review wave changed.
`AsymptoticExponentialCoreInverse` refuses a `"SourceShift"` that depends on
the target variable with `Failure["TargetDependentSourceShift", ...]`; such a
shift cancelled out of the displayed coefficients but made the reported
remainder scale exponentially too small. `InverseExpansionCoefficient[s, k,
Power -> p]` with the symbol spelling, a nested option list or a delayed rule
now returns the same coefficient as the string spelling, and the first
occurrence wins. `InverseNumericalCheck` returns `"LocalReferenceObservable"`
and `"ObservablePower"`, and its `"LocalCoordinate"` sentence now says that
`"LocalRoot"` is always the positive displacement while
`"LocalApproximation"` approximates the signed powered observable; the
[user guide](../src/Documentation/UserGuide.md#InverseNumericalCheck) and
[result reference](../src/Documentation/ResultReference.md) were corrected
with it. A named numeric constant such as `Pi` or `E` is refused as an
expansion, source or target coordinate. `FourierInverseResidual[s,
"MaxTerms" -> n]` no longer binds the option to the optional cutoff.
`SeriesObservable` peels an outer `ConditionalExpression` before choosing the
exact logarithm, exponential or power route and records
`"ObservableCondition"`. An affine combination `alpha Zeta[S] + beta` or
`alpha LerchPhi[z, s, a] + beta` with fixed exact coefficients is expanded
with its atom, scaling the retained coefficients and absolute tail bound and
recording `"AffineCoefficients"`; see the
[Zeta section](../src/Documentation/UserGuide.md#zeta-dirichlet-expansions).
The [focused run](../validation/README.md#wave-6-public-boundary-repairs)
passes 185/185 across ten files, and the
[implementation register](development/CODE_REVIEW_STATUS.md) records the
repaired wave-6 entries. The documentation checker's gates now survive
`python -O`, ignore TeX comments, and reject links that resolve outside the
checkout.

`InverseCertificate` encloses an integer power of an interval by the range of
its endpoint powers, so odd powers across zero keep their sign structure;
rational powers of a nonnegative base use exact dyadic roots instead of
`Exp[(p/q) Log[base]]` and its exponent budget; and a failure no precision can
repair stops the refinement with
`"StoppingReason" -> "NonRefinableArithmeticFailure"`. On both kernels a
parameter-only clause of an inline `ConditionalExpression`, such as
`ConditionalExpression[x + a x^2, a > 0]`, is now a parameter assumption
instead of an approach condition that was refused. On Mathics the
inline-assumption protector rewrites only applied `Element[_, _]` heads inside
`Assumptions` values and inline conditions, leaving a bare `Element` symbol
held as data untouched, and the numerical logarithm split is authorized by an
exact positive grammar rather than a machine-precision sign; see the
[input-assumption](Mathics/INPUT-ASSUMPTIONS.md) and
[numerical](Mathics/NUMERICAL.md) notes.

An explicit cutoff and `SeriesTermGoal` now stop the `Zeta` and `LerchPhi`
defining-sum expansions independently, whichever comes first, as every other
constructor already did; `AsymptoticExpansion[Zeta[x], {x, Infinity, Log[4]},
SeriesTermGoal -> 1]` returns the single constant term with first omitted
integer `2`, and a small goal no longer lets a large cutoff exhaust
`"MaxTerms"` on work it does not perform. `FlatSeriesMultiply` evaluates only
the least-grade omitted-tail candidates, with unchanged results, and the
Mathics realness and sign provers reuse proof results within one entry call.

### Certificate interval diagnostics, runner gates, and license metadata

`InverseCertificate` without an `"Interval"` option now returns
`Failure["InvalidInterval", ...]` with `"Reason" -> "IntervalNotSupplied"`;
malformed endpoints return the same tag with `"Reason" -> "MalformedInterval"`.
The certificate never infers an interval from asymptotic constants. The
[certificate guide](../src/Documentation/UserGuide.md#InverseCertificate)
records the option table. The aggregate runner `src/Tests/RunTests.wl` now
fails on empty, aborted or unexported runs instead of passing vacuously; its
JSON export gains per-file summaries and rejected-file names. The paclet and
standalone header declare the SPDX identifier `MIT-0`, matching the root MIT
No Attribution license. The
[implementation register](development/CODE_REVIEW_STATUS.md) links the
focused evidence (D04, D08, V02). The mathematical article records the
affine-range rule and the truncation transport of tail bounds in its
certificate and zeta sections.

`InverseCertificate` evaluates rational affine subexpressions exactly before
interval rounding, so a linear equation translated by a huge constant, such
as `x - (2^10000 + 1)` with an exact supplied center, now certifies at the
lowest enclosure order instead of failing at every order. Nonlinear parts
keep their outward enclosures.

`FlatSeriesMultiply` selects the complete omitted-sector bound by exponential
grade before weakening it to sector `N + 1`, and reports the selected sector
as `"SectorTailGrade"`. The square of the depth-`N` inverse of `x + Exp[-1/x]`
now carries the tail power `1 - 2 N` instead of `-4 N`; retained coefficients
are unchanged. See the
[flat product guide](../src/Documentation/UserGuide.md#FlatSeriesMultiply).

On Mathics, the explicit `Erfc`, `LogGamma`, `Gamma` and `LambertThreshold`
adapters now have portable cases, the numerical consumers reject
`Indeterminate` values before realness tests instead of aborting the Mathics
evaluator, and the Mathics numerical adapter retries a logarithm of a small
positive product as a sum of logarithms. See the
[numerical note](Mathics/NUMERICAL.md#logarithms-of-small-products) and
[notes on Mathics behaviour](MATHICS-NOTES.md).

`InverseExpansionCoefficient[s, k, "Power" -> p]` on a result object now
lets the explicit option override the stored observable power, with the same
infinite-endpoint conversion. `InverseResidual` reports `"TargetOffset"` and
labels its normalization `(f(g(y)) - y0)/(a z^p) - 1` at a finite target.

`InverseNumericalCheck` solves in the local source coordinate and reports
`"LocalRoot"`, `"LocalApproximation"`, `"SourceOffset"` and `"SourceSide"`.
A small displacement at a huge source origin such as `x -> 10^100` is no
longer lost; absolute fields gain extra presentation digits at large offsets,
and zero-offset results are unchanged. See the
[numerical check guide](../src/Documentation/UserGuide.md#InverseNumericalCheck).

`SeriesTruncate` now transports the explicit tail bound of a large-argument
`Zeta` or `LerchPhi` expansion instead of discarding it: the truncated result's
`"AbsoluteRemainderBound"` adds the absolute discarded part, recorded as
`"TruncationDiscardedPart"`, and keeps the bound conditions. A no-op truncation
keeps every bound field; a shorter expansion drops the signed lower bound and
the Lerch constant form. See the
[truncation section](../src/Documentation/UserGuide.md#SeriesTruncate).

The merged inverse coefficient-model admission work now refuses coefficient
queries on results without an ordinary inverse model with
`Failure["UnsupportedCoefficientModel", ...]` and no messages; see the
[contract note](development/INVERSE_COEFFICIENT_MODELS.md).

## September 9, 2026

### Package identity and loading

The package, public context, and standalone file changed from
`AsymptoticInverse` to `AsymptoticAnalysis`
([rename](https://github.com/VladimirReshetnikov/Asymptotic/commit/a6c90ce)).
The public constructor named `AsymptoticInverse` is unchanged. The modular
package then moved to `src/`
([layout update](https://github.com/VladimirReshetnikov/Asymptotic/commit/77ca544)).
Local code should load `src/Kernel/AsymptoticAnalysis.wl`; remote loading uses
the repository-root `AsymptoticAnalysis.wl`. Start a fresh kernel when changing
package contexts, and update old context-qualified names and saved loader paths.
The [loading guide](../src/Documentation/UserGuide.md#getting-started) gives
the complete commands, including pre-rename revisions.

Earlier that day, the result head changed from `PowerLogSeries` to
`GeneralizedSeries`
([result representation](https://github.com/VladimirReshetnikov/Asymptotic/commit/07a9781)).
Update explicit patterns to `_GeneralizedSeries`. Continue to use constructors
and public operations instead of modifying stored precision or branch metadata.

### Native input routing

Explicit `"Backend" -> "Series"` and `"Backend" -> "Asymptotic"` preserve
native results, and `AsymptoticExpand` is a held alias of `AsymptoticExpansion`
([explicit backends](https://github.com/VladimirReshetnikov/Asymptotic/commit/b6ee894)).
Automatic routing now recognizes selected native request forms/options and
can fall back after selected package representation failures
([automatic routing](https://github.com/VladimirReshetnikov/Asymptotic/commit/01b18ab)).
It also tries the second compatible native engine after an unresolved or
failed first attempt
([candidate search](https://github.com/VladimirReshetnikov/Asymptotic/commit/5b2b6cd)).

For eligible `Automatic` requests without explicit package constraints,
scalar rule-form goals `Automatic`, `0`, and negative integers are
admitted to the native path
([rule goals](https://github.com/VladimirReshetnikov/Asymptotic/commit/1ced1ae)).
Configured-default and equivalent-option issues remain open. Native results
retain their backend's order convention and do not receive an independently
proved package analytic remainder. See the
[native guide](../src/Documentation/UserGuide.md#native-backend-expansions)
for working examples and the [deviation register](development/NATIVE_COMPATIBILITY.md)
for the remaining coverage gaps, including the absent `DiscreteAsymptotic` backend.

### More precise coefficient and error contracts

| Change | User-visible consequence | Details |
| --- | --- | --- |
| Retain constructor assumptions through arithmetic and refinement | Later changes to ambient `$Assumptions` do not silently replace the stored proof context. | [Assumption context](development/ASSUMPTION_CONTEXT.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/a2c05e1) |
| Check complete collected coefficients for realness | Complex intermediate terms may cancel, but a surviving nonreal or unproved coefficient is refused on the strict package path. | [Real coefficients](development/REAL_COEFFICIENTS.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/5ca0ee7) |
| Collect provably equal exact exponents before block counting | Different exact forms of the same exponent no longer create spurious separate blocks or incorrect logarithmic frontier degrees. | [Equal exponents](development/EXPONENT_EQUALITY.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/5b2b6cd) |
| Check parameter capture in composition | A fixed-parameter remainder cannot simply be specialized to a moving parameter. Supported complete sources are replayed in the joint regime; other captured remainders are refused. | [Composition scope](development/COMPOSITION_PARAMETER_SCOPE.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/5b2b6cd) |
| Preserve logarithmic remainder degrees at native-series boundaries | A tail with a positive logarithmic degree is not exported as a stronger plain-power analytic bound. | [Native remainder contracts](development/NATIVE_SERIES_REMAINDERS.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/232aab4) |
| Bound optional dense `SeriesData` export and its integer indices | A sparse analytic result remains usable when the optional native representation would allocate too much memory or overflow native index/order-span fields. | [Native view](../src/Documentation/UserGuide.md#native-series-remainder-view) · [index repair](https://github.com/VladimirReshetnikov/Asymptotic/commit/6195452) |
| Repair certificate accuracy planning | Relative targets, precision retries, enclosure width, and achieved accuracy have separate recorded outcomes; obtaining an enclosure does not itself mean the requested accuracy was met. | [Certificates](../src/Documentation/UserGuide.md#InverseCertificate) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/01b18ab) |
| Validate observable Taylor information and the actual approach to its center | A native Taylor result must cover the requested coefficients in the correct chart. Exact-center inputs use the point value; punctured inputs use an admitted sided germ. A real constant term alone does not prove the complete substituted argument is real. | [Observable contracts and known limits](development/OBSERVABLE_INGRESS.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/8427715) |
| Require real exponents when normalizing logarithms of powers | A positive local base alone does not justify replacing a principal logarithm of a complex power by the exponent times the logarithm. The finite parser retains the real-exponent proof requirement, including every nested exponent and positive factor in recursive monomial normalization. | [Principal-logarithm contract and counterexample](development/LOG_POWER_NORMALIZATION.md) · [initial guard](https://github.com/VladimirReshetnikov/Asymptotic/commit/290f1af) · [recursive normalization](https://github.com/VladimirReshetnikov/Asymptotic/commit/6224ae2) |
| Stop Fourier composition before unnecessary products | Identically zero complete coefficients and weights beyond the exclusive cutoff stop the recurrence before an unused multiplication consumes its budget. `FourierInverseResidual` also accepts explicit work-budget options. Required retained products remain budgeted, and integer exponents alone do not imply termination. | [Fourier termination](development/FOURIER_TERMINATION.md) · [implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/10fe5d2) |

### Mathics compatibility work

The package now has a Mathics-only bootstrap and package-owned adapters for
selected evaluator, assumption, callable, algebra, calculus, refinement,
special-function, and certificate behavior
([bootstrap](https://github.com/VladimirReshetnikov/Asymptotic/commit/54e2ec5),
[exact assumptions and callables](https://github.com/VladimirReshetnikov/Asymptotic/commit/46382d7),
[refinement and branches](https://github.com/VladimirReshetnikov/Asymptotic/commit/88779b8),
[special functions](https://github.com/VladimirReshetnikov/Asymptotic/commit/add6357)).
The official Wolfram loading path skips those adapters.

Standalone loading preserves conditional-definition and span tokens when
splitting streamed Mathics bootstrap statements
([parser repair](https://github.com/VladimirReshetnikov/Asymptotic/commit/5d4ff7c)).
Private empty-list maps avoid a Mathics cache-corruption path while preserving
native behavior for other mapping forms
([list repair](https://github.com/VladimirReshetnikov/Asymptotic/commit/776fe8d)).

Held analytic entry points also protect explicit membership conditions in
syntactic `Assumptions` options before Mathics evaluates those conditions
([input-assumption repair](https://github.com/VladimirReshetnikov/Asymptotic/commit/c50ff6b)).
This preserves the supplied condition on those paths; it cannot recover a
caller value that already evaluated to `False`. The
[input-assumption contract](Mathics/INPUT-ASSUMPTIONS.md) documents that boundary,
and the [API coverage inventory](Mathics/API-COVERAGE.md) separates the portable
case inventory from completed execution evidence.

These are compatibility milestones, not full Mathics acceptance. Consult the
[current Mathics status](Mathics/COMPATIBILITY.md), [evaluator notes](MATHICS-NOTES.md),
and each linked receipt for tested source hashes and feature scope. The
portable test inventory, completed runtime checks, and Wolfram preservation
comparisons are different evidence.

## September 8, 2026

| Change | What to use now | Implementation |
| --- | --- | --- |
| Interpreted asymptotic display and ordinary arithmetic | Keep the series object through arithmetic to retain the error contract; `Normal` selects its stored approximation expression. See [series operations](../src/Documentation/UserGuide.md#series-operations). | [Display](https://github.com/VladimirReshetnikov/Asymptotic/commit/ea5d37d) · [arithmetic](https://github.com/VladimirReshetnikov/Asymptotic/commit/83c0e25) |
| Gamma normalization and increasing Gamma inverse | Gamma products retain exact growth factors; supported inverse branches use an exact Lambert core and reciprocal-logarithmic coefficient blocks. See [Gamma and LogGamma](../src/Documentation/UserGuide.md#inverse-gamma-and-loggamma). | [Forward normalization](https://github.com/VladimirReshetnikov/Asymptotic/commit/106f1f4) · [inverse](https://github.com/VladimirReshetnikov/Asymptotic/commit/f9ab7e0) |
| Barnes G normalization and increasing inverse | Use the documented branch and shifted reciprocal-logarithmic coordinate. See [Barnes G](../src/Documentation/UserGuide.md#barnes-inverse-expansions). | [Forward](https://github.com/VladimirReshetnikov/Asymptotic/commit/4cb7ea4) · [inverse](https://github.com/VladimirReshetnikov/Asymptotic/commit/7d3da2c) |
| Structured special-function expansions | Selected exponential and oscillatory carriers retain separate absolute error envelopes and scale-specific block counts. See [special functions](../src/Documentation/UserGuide.md#special-function-expansions). | [Implementation](https://github.com/VladimirReshetnikov/Asymptotic/commit/8b3b3dc) |
| Standalone distribution and robust URL loading | Download the complete file with `URLDownload`, then load the local file with `Get`; this avoids the observed direct compressed-response reader issue. | [Distribution](https://github.com/VladimirReshetnikov/Asymptotic/commit/fd357dd) · [loader](https://github.com/VladimirReshetnikov/Asymptotic/commit/0ddac97) |
| Separate mathematical article and package guide | Read the article for hypotheses and proofs and the guide for implemented syntax and result contracts. Historical engineering chapters remain preserved separately. | [Documentation split](https://github.com/VladimirReshetnikov/Asymptotic/commit/93fbc65) |

For a new change, update this overview when users need a migration note or a
new capability becomes available. Keep the detailed
[validation record](../validation/README.md) and [review register](development/CODE_REVIEW_STATUS.md)
as the authoritative locations for evidence and unresolved findings. Earlier
history remains available in the repository's Git log.
