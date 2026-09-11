# Native expansion compatibility: full coverage requirement and known deviations

**The accepted requirement is to completely subsume Wolfram Language
`Series`, `Asymptotic`, and `DiscreteAsymptotic`: every input successfully
handled by any of these built-ins must be handled correctly and successfully
by the package. A different result representation is permitted.** This covers
all supported argument forms, options, orders, domains, conditions, parameter
settings, and expression families, including less familiar cases. Preserving
an unresolved call, returning a failure, silently changing the requested
semantics, or attaching an unjustified analytic bound does not meet that
requirement.

This requirement remains active alongside implementation of all three review
waves. The matrix below is the acceptance target, and the deviation register
records known obstacles and differences. Recording a limitation does not
remove it from the required scope.
**Explicit native delegation and the held alias have focused acceptance.
Structural automatic routing and a narrow representation fallback are now
implemented; their current validation is recorded separately below.
The complete three-function input-superset goal remains open. There is no
implemented `DiscreteAsymptotic` backend or discrete-domain routing.**

## Known deviations and unresolved coverage

This register combines inspected production behavior with the
[wave-3 intake](WAVE_3_INTAKE.md) and named bounded validation records. Review
findings marked source-inspected are not new runtime reproductions; their
public examples retain the evidence limits stated in the intake. The table
distinguishes present semantic differences from defects and unverified
coverage. It must be updated when an implementation or acceptance result
changes an item.

| Area | Current deviation or limit | Evidence and required work |
| --- | --- | --- |
| Discrete asymptotics | The dispatcher accepts only `Automatic`, `"Package"`, `"Series"`, and `"Asymptotic"`. `"DiscreteAsymptotic"` is not an implemented backend value; there is no discrete-domain route or discrete compatibility acceptance record. An integer-sequence limit is not supplied merely by applying a continuous engine at infinity. | [Dispatcher and backend construction](../../src/Kernel/NativeCompatibility.wl); add discrete argument, integer-domain, option, result, and differential coverage. |
| Cutoffs and term goals | Successful package calls retain an exclusive power cutoff and complete nonzero-block goals. Native requests retain their selected order/term-goal conventions. The same triple can therefore retain different boundary terms depending on routing. Positive scalar rule goals can still use package block semantics. | [Naming and order decision](#naming-and-order-decision); the representation allowance does not by itself justify different mathematical precision semantics. |
| Configured defaults and alias defaults | Omitted backend selection is hardcoded to `Automatic`; configured canonical/alias backend defaults are not reliably honored. Rule-form classification can inspect the presence of a goal before its effective configured value. | W3-01 in [wave-3 intake](WAVE_3_INTAKE.md); define coherent default ownership and verify configured versus explicit calls. The explicit scalar rule-goal repair does not close this item. |
| Equivalent option forms and positional roles | Computed keys and equivalent symbol/string/context spellings are classified inconsistently. Some unknown symbolic suffix options escape validation; a positional variable named `Method` can lose specification metadata. | W3-02; resolve roles and option identity once, preserve delayed values and duplicate precedence, and test variable renaming. W3-15 records repeated option-tree traversal as a related performance issue. |
| Functions inside ordinary expressions | Recursive `Function` detection can treat applied functions or internal algebraic-root syntax as a protected callable source, preventing native routing. | W3-03; distinguish the source's actual callable role from nested function syntax. The reported `Root` witness still needs an independent current reproduction. |
| Conditional sources | Original `ConditionalExpression` syntax always protects the package path, excluding some native-supported conditioned complex expressions. | W3-09 and [baseline characterization](../../validation/native-search-baseline.json); preserve the complete condition while admitting a native route for ordinary conditioned expressions. |
| Direction and package-only constraints | An explicit `Direction`, even its default value, protects the package path. Selected runtime `Series` direction requests succeed despite `Direction` being absent from its option list. Explicit package budgets and inverse-branch selectors also prevent native fallback and are rejected in native mode. | [Candidate probe](../../validation/native-search-candidates-probe.json) and source; distinguish native-supported direction requests from additional package contracts without silently dropping either. |
| Fallback reachability and backend eligibility | Only a fixed set of representation failures triggers fallback. Ordering, branch/domain, validation, and resource failures do not generally search another backend. Backend eligibility relies on option-list membership, which is not a complete characterization of accepted runtime requests. | [Implemented routing](#implemented-automatic-routing); characterize each native-success/package-failure pair before changing protection or failure policy. No universal admission argument is established. |
| Evaluation context and timing | Computed trailing arguments are prepared before the held source; an automatic package attempt evaluates the source under a neutral proof context. Retrying reuses prepared values. These paths do not guarantee the same side-effect ordering as a direct native call, and held metadata does not freeze symbol definitions. | [Evaluation safeguards](#evaluation-and-real-branch-safeguards); compare effective defaults, assumptions, delayed options, source evaluation counts, and computed-container forms independently of algebraic output. |
| Computed versus complete output | Native status is syntactic. Held native syntax can be classified as unresolved, while a result without an active native head can retain unexpanded inactive work. Search stops at the first `Computed` status; this does not prove completeness or correctness for the requested order. | W3-05; retain raw outcomes while distinguishing held syntax, partial results, failure, abort, and legitimate nonfinite values. |
| Eager normalized expression | Native construction computes and stores `Normal[result]` immediately. Sparse native output can be expanded before the user requests an ordinary expression. | W3-04; historical storage measurements and current source inspection support a demand-driven design obligation, not a current benchmark claim. |
| Native wrapper operations | Package analytic arithmetic, truncation, and refinement refuse native results with `NativeSeriesContract`; numerical application requires one recognized variable. Continue native operations on `NativeResult`. These are current wrapper capability differences. | [Result contracts](NATIVE_RESULT_CONTRACTS.md); extend capabilities only with explicit semantics and preserved native information. Fix W3-02's variable recognition independently. |
| Native-to-analytic coefficient import | Generic observable import can consume an insufficient or mismatched native Taylor result, fill unknown coefficients with zero, or replace a sided constant at a discontinuity with the point value. A successful package result is not automatically evidence that this admission is sound. | W3-06 and C06/C13/C16 in the [review register](CODE_REVIEW_STATUS.md); establish endpoint, lattice, side, and regularity checks with truthful provider fixtures and focused public cases. |
| Branch-sensitive logarithm rewriting | Symbolic inverse parsing can rewrite logarithms of powers without proving the exponent real. The resulting polynomial-logarithmic model can misrepresent a periodic amplitude. | W3-10; the mechanism is source-inspected and mathematical countermodels are supplied, but the public witness remains unrun. Prove the required real-exponent hypothesis before rewriting. |
| Analytic evidence and result shape | Native payloads can be formal series, conditions, lists, or infinite expressions. Their package remainder and exactness are missing rather than independently proved. Output preservation alone does not establish a real branch, derivative control, or uniform parameter bound. | [Native result semantics](#native-result-semantics); this is an explicit contract distinction. Never manufacture an analytic theorem to make the representation resemble a package result. |

Additional correctness, refinement, coordinate, and resource findings for the
package's own analytic extensions remain in the complete
[review register](CODE_REVIEW_STATUS.md) and [wave-3 intake](WAVE_3_INTAKE.md).
Those documents are part of the known-work inventory; this compatibility
table does not declare the remaining package behavior defect-free. The full
input space of any of the three built-ins has not been validated, and the
absence of a listed counterexample is not evidence of complete support.

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
[Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html),
[DiscreteAsymptotic](https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html), and
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
`LogarithmicLeadingPower`, `ExponentialScale`, `UnsupportedNumber`,
`InfiniteSeries`, and `UnsupportedSourceHead` (a source applying a function
head outside the built-in contexts, whose regularity the package cannot
know; see [source admission](SOURCE_ADMISSION.md)). Invalid options, inverse-branch failures, domain failures,
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
| Native `DiscreteAsymptotic` requests | Accept the built-in's rule-form integer limit at infinity, explicit order, and supported term goals, preserving its discrete-domain meaning. This is required scope, with no implemented discrete backend yet. |
| Centers and coefficients | Preserve native-supported symbolic centers, real and complex finite/infinite approaches, symbolic parameters, exact constants and approximate numbers. |
| Source structure | Cover lists and nested results, implicit functions, unevaluated integrals, inactive integral transforms, differential-equation expressions and `DifferentialRoot` inputs. |
| Discrete source structure | Cover every native-supported sequence, sum, product, generating-function coefficient, summation transform, and difference-equation input, including `SeriesCoefficient`, `RSolveValue`, and `DifferenceRoot` forms. Preserve integer-domain and bound-index roles. |
| Functions and scales | Preserve every successfully computed native result, including branches, piecewise expressions, logarithmic and exponential factors, oscillation and q-functions; do not impose a special-function whitelist. |
| Unknown functions | Pass `Series`'s `Analytic` setting, including its default `True`, without turning assumed analyticity into an independently proved tail theorem. |
| Native `Series` options | Preserve `Analytic`, `Assumptions` and `SeriesTermGoal`, with their selected native semantics. |
| Native `Asymptotic` options | Preserve `AccuracyGoal`, `Assumptions`, `GenerateConditions`, `GeneratedParameters`, `Method`, `PerformanceGoal`, `PrecisionGoal`, `SeriesTermGoal` and `WorkingPrecision`. |
| Native `DiscreteAsymptotic` options | Preserve the same documented option names as `Asymptotic`, with the discrete backend's own defaults and semantics; verify runtime options on the target kernel. |
| Domains and conditions | Retain complex-region and parameter assumptions, generated conditions and conditional output; absent generated conditions do not prove unconditional validity. |
| Existing extensions | Retain callable and selected inverse-function support, irrational scales and rigorous analytic remainders already provided by the package. Explicit branch requests remain binding. |

Successive multivariable series must not be relabeled as a uniform expansion
on arbitrary simultaneous parameter paths. Preserve the specification order,
the roles of fixed parameters and bound variables, and all returned conditions.
Likewise, an asymptotic statement along integer values must retain that domain;
a continuous interpolation or a numerical substitution does not establish the
same statement. The discrete forms and source families in the matrix follow
the official [DiscreteAsymptotic reference](https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html).

## Native result semantics

The implemented native result kind preserves the complete returned payload in
`NativeResult`, with `OriginalArguments` and the selected `NativeRequest`
stored in held forms. The payload itself is not wrapped in `HoldComplete`.
The wrapper records recognized `ExpansionSpecifications`, `AmbientAssumptions`, backend,
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

Those historical probes exposed scalar native goals rejected by package
validation; the explicit scalar rule cases were subsequently repaired by the
[116/0 rule-goal acceptance](../../validation/native-rule-goal-tests.json).
Configured defaults and equivalent option forms remain open, as do explicit
`Direction` and conditional complex inputs. Runtime `Series` accepted the probed Direction
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

The acceptance invariant requires both availability and correctness: on the
same kernel, with corresponding effective arguments, options, domains, and
evaluation context, every successful `Series`, `Asymptotic`, or
`DiscreteAsymptotic` request must produce a successful package expansion with
the requested mathematical semantics. A lossless representation of the native
answer is one permitted implementation. Merely constructing a wrapper or
observing a syntactic `Computed` status is insufficient. Finite tests provide
evidence for routing and preservation; they cannot establish universal
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
