# Native expansion compatibility: review scope and implementation plan

The earlier compatibility objective introduced a target of subsuming the input
coverage of ``System`Series`` and ``System`Asymptotic`` with a different result
representation permitted. The current user objective is to implement the
recommendations in all three review waves and keep the documentation current.
The coverage matrix remains a design and comparison target; specific review
findings, including equivalent request forms and native result contracts,
drive the implementation work. It is not a claim of complete current coverage.
**Explicit native delegation and the held alias have focused acceptance.
Structural automatic routing and a narrow representation fallback are now
implemented; their current validation is recorded separately below.
The complete input-superset goal remains open.**

## Current boundary

The public function `AsymptoticExpansion` and its held alias `AsymptoticExpand`
share `"Backend" -> Automatic`. In
[NativeCompatibility.wl](../../src/Kernel/NativeCompatibility.wl),
explicit `"Series"` and `"Asymptotic"` modes delegate before real-coordinate
admission and return a distinct native result. `"Package"` selects only the
existing analytic engines. `Automatic` retains their successful results,
routes selected native forms and options directly, and permits a native
fallback for selected representation failures. The package path's
[held entry and ordinary engine](../../src/Kernel/AsymptoticAnalysis.wl)
accept one expansion variable and use an exclusive power cutoff. The
[forward dispatcher](../../src/Kernel/InverseFunctionExpressions.wl)
constructs a positive real local coordinate before selecting an engine.
Exact real input, admissible real coefficients and supported coefficient
scales are required by these paths. The
[structured special-function importer](../../src/Kernel/NativeSpecialFunctions.wl)
also requires a real-domain proof and a supported finite error representation.
Those analytic contracts remain in force for package results; the native
result kind preserves outputs outside those representations without
asserting an analytic remainder or a real-source proof.

The official references are [Series](https://reference.wolfram.com/language/ref/Series.html),
[Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html), and
[SeriesData](https://reference.wolfram.com/language/ref/SeriesData.html).
The matrix below follows those interfaces and examples. Runtime option lists
and evaluation attributes must also be checked on the installed kernel;
compatibility evidence must name that kernel version.

## Naming and order decision

`AsymptoticExpansion` remains the implementation entry point. The requested
spelling `AsymptoticExpand` is a held alias with the same defaults, without
renaming the existing API or its stored recipes.

The existing `{x, x0, n}` means retain powers strictly below `n`; native
`Series` requests terms through its order `n`. An alias cannot reconcile
that semantic collision. The implemented explicit backend
selector is separate from native `Method`; its native modes preserve the
selected backend's order convention:

```wolfram
AsymptoticExpansion[expr, specs, "Backend" -> "Series", nativeOptions]
AsymptoticExpansion[expr, spec, "Backend" -> "Asymptotic", nativeOptions]
```

Automatic native results record `OrderConvention -> "Native"` and the selected
`NativeBackend`. Neither the exclusive cutoff nor a complete nonzero-block
goal is translated into native semantics. In particular, a fallback can
include the order excluded by a package request. Choose `"Package"` to require
the analytic cutoff and block-count conventions; choose an explicit native
backend to fix its order and option semantics. The alias alone changes none
of these rules.

## Implemented automatic routing

Routing first preserves explicit package contracts: source callables,
`InverseFunction`, `ConditionalExpression`, `GeneralizedSeries` and
`PowerLogRemainder`, or an explicit `Direction`, `"MaxTerms"` or
`"InverseFunctionBranches"`, keep the package path. Supplying a default option
value explicitly still activates this protection. Package mode rejects
native-only option keys with `UnsupportedOption` instead of ignoring them.

Otherwise, native-only option keys select `Series` when its runtime options
contain all such keys, then `Asymptotic` when its options do. No compatible
backend produces `NativeOptionConflict`. Structural routes include multiple
specifications, symbolic or complex centers, non-real order specifications,
lists, inactive expressions and rule-form leading requests without a term
goal. Without native-only options, a single triple with order `Infinity`
selects `Asymptotic`; other triples and multiple specifications select `Series`;
rule forms select `Asymptotic`.

Remaining inputs try the package engine. Only the following failures permit
fallback: `InexactInput`, `UnprovedRealCoefficient`, `UnsupportedInput`,
`UnsupportedCoefficient`, `SymbolicExponent`, `ComplexExponent`,
`LogarithmicLeadingPower`, `ExponentialScale`, `UnsupportedNumber`, and
`InfiniteSeries`. Invalid options, inverse-branch failures, domain failures,
undecidable ordering and resource failures are not general fallback triggers.

Native results record `BackendSelection -> Automatic`, a reason of
`"NativeOptions"`, `"NativeSpecification"` or `"PackageRepresentation"`, and
`PackageFailure` (the original failure or `None` for direct routing).
The preferred backend is tried first. If it leaves an unresolved native call
or returns a failure, the other backend is tried when its runtime options
accept all supplied option keys. Search stops at a computed result or an
abort. When neither backend computes a result, the preferred result is kept.
`NativeAttempts` records the ordered backend names, evaluation statuses, and
actual held requests. Explicit backend selections never search another engine.

On Wolfram 15.0.1 Windows, `Asymptotic` leaves the following request unresolved,
whereas `Series` returns a list whose normal form is `{1, x}`:

```wolfram
AsymptoticExpand[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0]
```

This native-shaped request now selects `Series` after trying `Asymptotic`.
The same native difference occurs with term goal `-1`. These are native
term-goal semantics, not a reinterpretation of a package block count.
Scalar rule requests with an explicit nonpositive integer term goal or
`SeriesTermGoal -> Automatic` now enter the same native search. On this
kernel, `Series[Exp[x], x -> 0, SeriesTermGoal -> 0]` and an explicit
`Automatic` goal retain `1`; negative goals have an empty finite part.
The complete native result is preserved in each case. Common delayed options
are reused after their effective values have been read, so admission does not
reexecute them. Explicit package mode and package direction/branch/resource
constraints retain their validation. Triple cutoffs are unchanged.

The [116/0 focused record](../../validation/native-rule-goal-tests.json)
contains 15 new rule-goal cases plus search, dispatch, explicit native and
assumption controls. Configured default goals, alias defaults, and equivalent
option spellings remain separate wave-3 request-resolution obligations.

## Required coverage matrix

Every row describes the full acceptance target. Structural delegation and
selected automatic routes are implemented; the matrix is not a claim that
every row has passed testing or is reachable through Automatic mode.

| Area | Required behavior |
| --- | --- |
| Native `Series` requests | Accept explicit integer order, including negative orders, rule-form leading terms, and successive specifications for several variables. Preserve their order. |
| Native `Asymptotic` requests | Accept rule-form leading approximation, explicit order and order `Infinity`, including complete power-series representations. |
| Centers and coefficients | Preserve native-supported symbolic centers, real and complex finite/infinite approaches, symbolic parameters, exact constants and approximate numbers. |
| Source structure | Cover lists and nested results, implicit functions, unevaluated integrals, inactive integral transforms, differential-equation expressions and `DifferentialRoot` inputs. |
| Functions and scales | Preserve every successfully computed native result, including branches, piecewise expressions, logarithmic and exponential factors, oscillation and q-functions; do not impose a special-function whitelist. |
| Unknown functions | Pass `Series`'s `Analytic` setting, including its default `True`, without turning assumed analyticity into an independently proved tail theorem. |
| Native `Series` options | Preserve `Analytic`, `Assumptions` and `SeriesTermGoal`, with their selected native semantics. |
| Native `Asymptotic` options | Preserve `AccuracyGoal`, `Assumptions`, `GenerateConditions`, `GeneratedParameters`, `Method`, `PerformanceGoal`, `PrecisionGoal`, `SeriesTermGoal` and `WorkingPrecision`. |
| Domains and conditions | Retain complex-region and parameter assumptions, generated conditions and conditional output; absent generated conditions do not prove unconditional validity. |
| Existing extensions | Retain callable and selected inverse-function support, irrational scales and rigorous analytic remainders already provided by the package. Explicit branch requests remain binding. |

Successive multivariable series must not be relabeled as a uniform expansion
on arbitrary simultaneous parameter paths. Preserve the specification order,
the roles of fixed parameters and bound variables, and all returned conditions.

## Native result semantics

The implemented native result kind preserves the complete `NativeResult`,
`OriginalArguments`, and selected `NativeRequest` inside held forms. It records
recognized `ExpansionSpecifications`, `AmbientAssumptions`, backend,
kernel version and evaluation status. Literal explicit requests retain
syntactic specifications; preparation may resolve automatic specifications.
Native option expressions are not reevaluated to build a metadata snapshot;
common options consumed by a package attempt are materialized for fallback.
The native result's `Assumptions` is
`Missing["NativeContract"]`. A native result can contain
nested `SeriesData`, ordinary expressions, lists, `ConditionalExpression`,
`Piecewise` or infinite sums; these shapes must not themselves cause rejection.

A `SeriesData` remainder is a native formal-order descriptor. Its presence
does not prove a finite logarithmic error degree, source reality or derivative
control. A finite expression returned by `Asymptotic` must not receive
`"Remainder" -> 0` or `"Exact" -> True` simply because no `O` term is present.
Record the backend's contract separately from an independently established
analytic envelope. See [native remainder contracts](NATIVE_SERIES_REMAINDERS.md).

The result displays its native expression without an invented remainder, and
`Normal` applies native normalization; infinite expressions can remain.
`NativeEvaluationStatus` distinguishes `Computed`, `Unresolved`, `Failed`, and
`Aborted` results syntactically. Absence of a remaining native call is not a
proof that every nested inactive expression was expanded, nor a proof of
analytic validity. Analytic operations decline
native results with `NativeSeriesContract`. Numerical application requires one
identified variable; other cases return `NativeVariables`. See the detailed
[native result contracts](NATIVE_RESULT_CONTRACTS.md).

## Evaluation and real-branch safeguards

Explicit native handling precedes `localCoordinate`, `validateInput` and real
coefficient checks. Literal requests remain held until release to the native
head under the captured ambient assumptions. Computed trailing arguments and
option containers are resolved first to discover the backend, while the source
remains held for that backend. This ordering need not match arbitrary side
effects in a direct native call.

Automatic requests requiring package preparation evaluate their source under
the neutral package proof context, `$Assumptions = True`; hypotheses are
supplied separately. Literal native-only option routing can bypass that
preparation. On representation failure, the wrapper reuses the prepared source
and specifications instead of replaying the original source program. Effective
`Assumptions` and an explicitly requested `SeriesTermGoal` are supplied as
immediate rules; delayed common options are not consumed again for fallback.
Other native defaults remain those of the selected backend.

When two backends are eligible, the search also materializes explicitly
supplied common `Assumptions` and `SeriesTermGoal` options once before the
first native attempt. First-option precedence is retained; unused duplicate
delayed values are not executed. The prepared source and specifications are
reused across attempts. An option exclusive to one native backend limits the
search to that engine and preserves its existing evaluation path. Diagnostics
from an unresolved first attempt can still be emitted when a later attempt
succeeds; suppressing messages is separate from inspecting the recorded result.

`OriginalArguments` records the original held input, while `NativeRequest`
records the actual delegated call. `AmbientAssumptions` does not absorb an
explicit assumption option. These records do not freeze symbol definitions,
prevent ordinary further evaluation of surviving expressions, or establish
identical side-effect ordering between preparation and a direct native call.

Explicit native modes reject package-only `"MaxTerms"` and
`"InverseFunctionBranches"` options with `NativeOptionConflict`. They do not
silently discard those contracts. Automatic routing conservatively keeps
the package path for the protected cases listed above. Native diagnostics
must not be confused with a proof that a returned expression is invalid.

C07 tests become representation-specific: the ordinary real engine must still
reject nonreal coefficients, while a native formal or complex result may be
admitted by the expanded public interface. It must not acquire a real-source
assertion or enter real Lipschitz error rules. The separately justified
special-function real projection remains governed by
[the real-coefficient contract](REAL_COEFFICIENTS.md).

## Implementation stages and evidence

The [current nine-file native-search acceptance](../../validation/native-search-tests.json)
passes **179 tests, zero failures**, including 16 new search cases, on Wolfram
15.0.1 Windows with unchanged sources. The
[runner](../../validation/CheckNativeSearch.wl) exercises actual second-backend
success, both preference orders, unresolved-output retention, explicit and
native-exclusive routes, delayed-option and source evaluation counts, and
adjacent native/analytic/inverse contracts.

The [baseline differential characterization](../../validation/native-search-baseline.json)
records 47 observations against commit `6687962`; the
[native-only candidate probe](../../validation/native-search-candidates-probe.json)
records 32 built-in calls without loading the package. These are bounded
observations, not acceptance suites. The baseline independently checks R17 N4:
native `Series` and `Asymptotic` compute the selected `x^x` and Zeta expressions,
and native `InverseSeries` computes the selected quadratic inverse. The
package's retained analytic remainder and cutoff conventions are separate
from those finite-expression comparisons.

The same probes expose remaining automatic admission gaps: scalar native
term goals rejected by package validation, explicit `Direction`, and
conditional complex inputs. Runtime `Series` accepted the probed Direction
values even though `Direction` was absent from its documented option list;
option-list membership alone does not prove runtime rejection. Inactive
nested results also require a stronger completeness criterion than the
absence of outer `Series`/`Asymptotic` heads. These observations inform the
next coverage work; the full input-superset goal remains open.

The earlier acceptance and artifact records listed below predate the package rename
to AsymptoticAnalysis. The 163/0 automatic record is preserved at checkpoint
`01b18ab`; its original paths, context and source hashes remain historical
evidence. These records do not establish acceptance of the renamed files.

1. **Implemented; focused verified:** held native request parser,
   explicit backend selection and delegation before real-coordinate admission.
   Validate native order, options, computed containers and evaluation effects.
2. **Implemented; focused verified:** preserved native result, display,
   `Normal`, metadata and analytic-operation guards, without sparse-to-dense export.
3. **Implemented; focused verified:** structural and option-based
   automatic routing, narrow fallback, source reuse, explicit package-contract
   protection and native order metadata. Remaining automatic coverage,
   and evaluation compatibility require further work. Compatible second-backend
   search is implemented with separate focused evidence below. Analytic
   promotion needs its own proof.
4. **Partial evidence recorded:** focused differential tests across the matrix, including
   unknown-function options, mixed complex/approximate data, multiple variables,
   conditions, infinite order, inactive transforms and existing package examples.
5. **Documentation and distribution artifacts rebuilt:** public interfaces
   and contracts, with a separate [artifact receipt](../../validation/automatic-certificate-artifacts.json).
   Extend native operations only where their semantics are defined.

The target invariant is structural: on the same kernel, with corresponding
effective arguments, options and evaluation context, every successfully
computed native result has a lossless package representation. Finite tests
provide evidence for routing and preservation; they cannot establish universal
coverage. Record the exact native requests, versions, outputs and evidence
limits in the [validation record](../../validation/README.md). The
[explicit-mode acceptance record](../../validation/native-compatibility-tests.json)
reports 130 passed and zero failed across eight files, with unchanged sources
on Wolfram 15.0.1 Windows. It predates automatic routing and does not validate
that new path. Existing analytic ingress/export tests alone do not establish
acceptance of the native result kind, and no finite matrix proves complete
input-superset coverage.

The subsequent [automatic acceptance](../../validation/native-automatic-tests.json)
passes 163 tests across eight selected files with unchanged sources, including
35 automatic-routing cases and the adjacent explicit-native, assumption,
real-coefficient and inverse-callable checks. It establishes those cases,
not full coverage. The first-pass record preserves two dispatch bugs and two
incorrect fixture assumptions that were corrected before this acceptance.
