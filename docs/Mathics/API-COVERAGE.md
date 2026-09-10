# Mathics public API coverage

This inventory maps all **38 exported symbols** to representative cases in
[the portable suite](../../validation/MathicsTests.wl). A row records a tested
operation. It does not establish compatibility for
every input, option, branch, precision, or resource limit of that symbol.
The [compatibility status](COMPATIBILITY.md) describes the broader goal.

## Evidence and current scope

The suite currently contains **101 cases**. Its first 77 cases have complete
modular and standalone runs on the recorded earlier source snapshots. Each
full run reported **76 successes and one failure** in the exact-normalization
assertion for `inverse-perturbative-formula`. Replacing `Expand` with `Simplify`
proved the same expected exact zero; the corrected case then passed on both
unchanged package snapshots. The original failing receipts are retained.
This is reconciled evidence for 77 cases, not a claim that either full run
originally passed all 77. Those snapshots contained 53 kernel modules.

Thirteen additional cases covering public operations and the empty-list
`Map` regression passed on both modular and standalone snapshots containing
54 modules. Their package hashes differ from the earlier 77-case snapshots.
The four remaining direct-export cases and four held inline-assumption
contracts passed on both layouts of the recorded 55-module candidate; the
standalone batch also repeated its five loading cases. The original Wolfram
kernel independently validated all 98 case expectations across separate
batches. The combined evidence for those batches covers 98 unique cases per
layout across three package snapshots.
Three further cases for Newton inversion, retained Newton refinement,
additional-block requests and product-recipe replay passed on the same
55-module modular and standalone snapshots and in the original Wolfram
kernel. The full aggregate now covers **101 unique cases per layout across
three package snapshots**. All 101 current expectations have original Wolfram
controls, across separate batches. A full run on one final source snapshot is
a separate acceptance check; this aggregate does not claim it has completed.

The [machine-readable evidence summary](../../validation/mathics-test-coverage.json)
records each receipt hash, package source fingerprint, original outcome and
reconciliation. Its underlying [full modular](../../validation/mathics-modular-tests.json)
and [full standalone](../../validation/mathics-standalone-tests.json) receipts
remain unchanged. The [summary generator](../../validation/summarize_mathics_tests.py)
rejects reconciliations between different package sources or with unresolved
original failures. Additional operation receipts retain their own source scope.
Each receipt retains the exact suite byte hash used for that run, including
historical CRLF snapshots. Normalizing the published suite to LF does not
rewrite those receipts or make their historical byte hashes identical.
The initial publication checkpoint `bc6d570` normalized those receipt files
to LF. The publication correction restores their captured bytes and marks
`validation/mathics-*-tests.json` with `-text`, so Git preserves their recorded
hashes before final acceptance.

The table uses these evidence labels:

- **Core**: first 77 cases, with the explicit exact-normalization reconciliation above.
- **Operations**: the additional 13 cases, passed on both package layouts.
- **Latest**: the final eight direct-export and held-assumption cases, passed on both 55-module layouts.
- **Refinement**: three additional cases passed on both recorded 55-module layouts and original Wolfram.

All passing symbolic checks use exact values or exact logical predicates.
The numerical checks below are explicitly limited smoke checks. The full
original MUnit suite is a separate validation target and has not been run in
Mathics. Two inverse-domain fixtures explicitly characterize different runtime
behavior: Wolfram evaluates `InverseFunction` before package dispatch, while
Mathics retains the operator and conservatively rejects an unproved branch.
Their native and Mathics assertions are both checked; neither runtime is skipped.

## Export inventory

Case IDs in this table are exact searchable identifiers in the portable suite.
An infix call covers an overloaded operator; a constructor check covers a
returned data head and its public evaluation behavior.

| Export | Representative case IDs | Semantics exercised and evidence |
| --- | --- | --- |
| `AsymptoticCoreInverse` | `operations-core-inverse-marker-frontier` | Direct call with core `x`, perturbation `x^2`, exact marker coefficients and first omitted frontier. **Operations**. |
| `AsymptoticExpand` | `native-held-alias` | Direct alias agrees with explicit native `Series` expansion and backend metadata. **Core**. |
| `AsymptoticExpansion` | `forward-polynomial-exact`, `forward-exponential`, `forward-logarithmic-coefficients`, `forward-irrational-exponent`, `forward-finite-point-from-below`, `forward-decaying-exponential`; all six `special-*` cases | Exact termination, power/log terms, irrational exponent, finite chart and direction, exponential and selected special-function scales. **Core**. |
| `AsymptoticExponentialCoreInverse` | `families-exponential-core-first-sector`, `families-exponential-core-exact-specialization` | Principal ProductLog core, first sector and marker coefficients, exact specialization at `E`. **Core**. |
| `AsymptoticFlatInverse` | `flat-first-exponential-sector`, `operations-flat-series-calculus-and-error` | First exponentially small sector and retained sector/inner error. **Core**, **Operations**. |
| `AsymptoticFourierInverse` | `families-fourier-first-correction`, `operations-fourier-coefficient-and-residual` | One logarithmic sine frequency, complete first correction, coefficient and residual metadata. **Core**, **Operations**. |
| `AsymptoticInverse` | `inverse-quadratic`, `inverse-depth-quadratic`, `inverse-logarithmic-coefficients`, `inverse-irrational-exponent`, `inverse-infinity`, `inverse-finite-point`, `inverse-ramified`, `inverse-exact-termination`; `families-lambert-negative-branch`, `families-gamma-inverse-first-correction`, `families-barnes-inverse-leading-core`; `operations-newton-inverse-and-retained-refinement` | Ordinary, logarithmic and ramified inversion; coordinate charts, depth frontier, exact termination, and selected Lambert/Gamma/Barnes families. **Core**. Exact Newton quadratic inversion is **Refinement**. |
| `AsymptoticLogarithmicInverse` | `logarithmic-reciprocal-core`, `operations-reciprocal-log-differentiate`, `operations-reciprocal-log-compose` | Reciprocal-log blocks for `x+x/Log[x]`, derivative and composition contracts. **Core**, **Operations**. |
| `AsymptoticSpecialInverse` | `operations-special-inverse-quadratic-threshold` | Direct quadratic-threshold adapter with translated source, target offset and negative target scale; exact remainder. **Operations**. |
| `FlatSeriesDifferentiate` | `operations-flat-series-calculus-and-error` | Exact derivative of retained first sector and nonzero derivative remainder. **Operations**. |
| `FlatSeriesMultiply` | `operations-flat-series-calculus-and-error` | Direct multiplication by an exact scalar. **Operations**. |
| `FlatSeriesObservable` | `operations-flat-series-calculus-and-error` | Affine observable preserves the first flat correction. **Operations**. |
| `FlatSeriesTruncate` | `operations-flat-series-calculus-and-error` | Inner truncation removes a displayed flat coefficient and records its nonzero inner remainder. **Operations**. |
| `FourierInverseCoefficient` | `operations-fourier-coefficient-and-residual` | Exact single-index trigonometric coefficient and weight. **Operations**. |
| `FourierInverseResidual` | `operations-fourier-coefficient-and-residual` | Exact empty residual blocks below the declared cutoff. **Operations**. |
| `GeneralizedSeries` | `loading-reload`, `operations-series-data-reconstruction` | Returned head, `Normal`, properties and reload are **Core**; explicit reconstruction from stored association and exact point evaluation are **Latest**. |
| `InverseCertificate` | `certificate-exact-rational-root`, `certificate-fixed-center-accuracy-floor` | Exact rational quadratic-root certificate and explicit fixed-center accuracy-floor failure. **Core**. |
| `InverseExpansionCoefficient` | `families-single-index-coefficient` | Direct Euler coefficient at index `{2}` with a degree-two formal-log polynomial. **Core**. |
| `InverseNumericalCheck` | `numerical-exact-quadratic-inverse` | Exact quadratic-root numerical smoke check. **Core**; this is not a general precision or numerical-stability certificate. |
| `InverseResidual` | `inverse-residual` | Exact vanished residual below a quadratic inverse cutoff. **Core**. |
| `LogarithmicInverseResidual` | `operations-logarithmic-inverse-residual` | Exact zero, vanishing and cutoff metadata for reciprocal-log inversion. **Latest**. |
| `PerturbativeInverse` | `inverse-perturbative-formula`, `inverse-perturbative-general-core`, `inverse-perturbative-zero-order`, `contracts-perturbative-variables` | Finite formula, nonidentity core, order-zero identity and invalid-variable contract. **Core**, with the explicit normalization reconciliation. |
| `PowerLogModel` | `families-single-index-coefficient`, `assumptions-inline-inverse-and-model-preserve-composite` | Direct model construction for logarithmic coefficients is **Core**; composite-assumption rejection is **Latest**. |
| `PowerLogRemainder` | `arithmetic-cancellation-preserves-remainder`, `contracts-input-remainder`, `operations-series-data-reconstruction` | Returned remainder and input-tail contracts are **Core**; explicit constructor equality after truncation is **Latest**. |
| `ReciprocalLogCompose` | `operations-reciprocal-log-compose` | Direct composition of reciprocal-log charts, exact three-block polynomial and derivative-order contract. **Operations**. |
| `ReciprocalLogDifferentiate` | `operations-reciprocal-log-differentiate` | Exact derivative blocks and all-fixed-derivative-orders contract. **Operations**. |
| `SeriesAdd` | `arithmetic-add`, `operations-explicit-series-binary-wrappers` | Infix addition is **Core**; direct scalar wrappers in both argument orders are **Latest**. |
| `SeriesCompose` | `operations-series-compose-transports-inner-error` | Direct composition transports the inner error instead of claiming the larger requested cutoff. **Operations**. |
| `SeriesDifferentiate` | `operations-series-derivative-contract` | Exact logarithmic derivative succeeds; differentiating a truncated series without derivative bounds fails. **Operations**. |
| `SeriesExp` | `operations-series-log-and-exp` | Direct exponential expansion with cubic terms and cutoff four. **Operations**. |
| `SeriesLog` | `operations-series-log-and-exp` | Direct logarithm includes its leading `Log[x]` and three corrections. **Operations**. |
| `SeriesMultiply` | `arithmetic-multiply`, `operations-explicit-series-binary-wrappers` | Infix multiplication is **Core**; direct scalar wrappers in both argument orders are **Latest**. |
| `SeriesNormalize` | `operations-series-normalize-composite` | Composite `Sin[s]+Log[1+s]+Exp[s]` normalizes to one series with the correct common cutoff. **Operations**. |
| `SeriesObservable` | `operations-series-observable` | Direct nonlinear sine observable through cubic order. **Operations**. |
| `SeriesPower` | `operations-series-power` | Negative power with leading-pole shift and transported remainder. **Operations**. |
| `SeriesRefine` | `arithmetic-refinement`, `arithmetic-refinement-retained-state`, `operations-newton-inverse-and-retained-refinement`, `operations-refinement-additional-blocks-request`, `operations-refinement-replays-product-recipe` | Retained Lagrange state and unchanged original object are **Core**. Retained Newton steps, exact residual, additional complete blocks and product-recipe replay with honest work-count metadata are **Refinement**. |
| `SeriesTruncate` | `arithmetic-truncation`, `operations-series-data-reconstruction` | Direct cutoff reduction is **Core**; explicit remainder data-head equality is **Latest**. |
| `SpecialInverseNumericalCheck` | `operations-special-numerical-exact-threshold` | Direct exact quadratic-threshold root smoke check; result remains explicitly uncertified. **Latest**. |

## Remaining input and option coverage

The following are concrete gaps in this portable suite, even where every
export in the relevant area has a representative fixture:

- **Refinement and algorithms.** Grouped Lagrange modes, retained Newton
  refinement for nonlinear observables or nontrivial coordinate charts,
  target/relative-error requests, exact-termination and resource-limited
  additional-block requests, and recipes for more general nested operations
  need their own cases. The tested quadratic Newton and product-replay paths
  do not cover all these modes.
- **Extended-scale operations.** Higher reciprocal-log levels, generalized
  logarithmic coefficient jets, several Fourier frequencies and resonances,
  nonlinear flat observables and products of two nontrivial flat series,
  and arithmetic across factored, Dirichlet, Gamma and Barnes envelopes
  require additional tests. The logarithmic residual API also has an explicit
  unsupported-residual contract for generalized coefficient jets.
- **Special inverse adapters.** The direct `AsymptoticSpecialInverse` fixture
  covers `"QuadraticThreshold"`. Its `"Erfc"`, `"LogGamma"`, `"Gamma"` and
  `"LambertThreshold"` adapters, chart options, and resource limits remain
  distinct targets. Testing `AsymptoticInverse[Gamma[x], ...]` does not cover
  all those public adapter paths.
- **Proof and rejection boundaries.** The suite checks affine-domain realness,
  selected complex and inexact inputs, ambiguous/disconnected branch behavior,
  and held inline assumptions. General nonlinear/disconnected domains,
  arbitrary symbolic assumptions, unsupported special-function parameters,
  and all resource-limited failure paths are not covered. Information already
  lost in an externally evaluated Mathics assumption cannot generally be
  reconstructed by the package's held inline-option adapter.
- **Numerical and certificate behavior.** General high-precision accuracy,
  nonprincipal ProductLog numerical branches, adaptive certificate refinement,
  relative tolerances and nonpolynomial elementary-tail certificates need
  dedicated accuracy and enclosure evidence. An exact-root smoke check does
  not validate these capabilities.
- **Runtime and presentation.** The portable suite covers clean loading,
  reloads, context isolation and selected evaluator primitives. Notebook
  front-end presentation, other Mathics releases, and all Wolfram language
  evaluation edge cases need separate validation.

Unresolved or conservatively rejected supported Wolfram inputs remain
compatibility work. They are not counted as successful Mathics functionality
merely because the failure is mathematically safe.
