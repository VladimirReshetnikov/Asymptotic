# Native expansion result contracts

**The required goal is complete subsumption of `Series`, `Asymptotic`, and
`DiscreteAsymptotic`: every input successfully handled by any of these
built-ins must be handled correctly and successfully by the package, with a
different result representation permitted. Current coverage is incomplete.**
The [compatibility plan and known deviations](NATIVE_COMPATIBILITY.md)
define that requirement, the admission gaps, and the acceptance obligations.

This note describes the native result contract currently implemented in
[NativeCompatibility.wl](../../src/Kernel/NativeCompatibility.wl) for the
`Series` and `Asymptotic` backends, including automatic search. There is no
implemented `DiscreteAsymptotic` backend, discrete-domain routing, or discrete
result contract yet. The following fields therefore describe the existing
two native backends, not promised behavior of an unimplemented third one.
Preserving a backend failure or unresolved request for inspection does not
count as successfully handling its input.

## Interface and order

`AsymptoticExpand` is a held alias of `AsymptoticExpansion`; their initially
declared backend default is `Automatic`. The current dispatcher also hardcodes
`Automatic` when no backend is supplied, so configured canonical or alias
defaults are not a reliable backend-selection mechanism (W3-01 in the
[wave-3 intake](WAVE_3_INTAKE.md)). Successful package requests retain the real
analytic contract and existing order convention. Native specifications/options
and selected representation failures can instead produce a Native result,
explicitly recording `OrderConvention -> "Native"`.
`"Backend" -> "Package"` retains the package engines and declines native
fallback. Explicit `"Series"` and `"Asymptotic"` modes select the corresponding
System function, independently of that function's `Method` option.
The backend selector accepts only `Automatic`, `"Package"`, `"Series"`, and
`"Asymptotic"`; supplying `"DiscreteAsymptotic"` currently returns
`Failure["InvalidBackend", ...]`.

The package's ordinary `{x, x0, h}` is an exclusive cutoff. Native `Series`
includes its requested order. Preserve the selected engine's order and
`SeriesTermGoal` semantics instead of translating by a universal `+1` or `-1`:
fractional powers, logarithms, infinity, and successive specifications need
the actual backend convention. See the official
[Series](https://reference.wolfram.com/language/ref/Series.html) and
[Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html) references.
The required [DiscreteAsymptotic](https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html)
coverage concerns an integer limit at infinity, which must not be represented
as an established continuous-domain result.

## Representation boundary

| Field | Native result value or meaning |
| --- | --- |
| `Kind`, `Scale` | `"Native"`. |
| `NativeResult` | Complete returned backend expression. |
| `Expression` | `Normal[NativeResult]`, computed eagerly during construction. |
| `Remainder` | `Missing["NativeContract"]`. |
| `Exact` | `Missing["NotEstablished"]`. |
| `RemainderContract` | `"NativeFormalOrder"` or `"NativeAsymptotic"`. |
| `OriginalArguments` | Original public arguments inside `HoldComplete`. |
| `NativeRequest` | Actual held selected System call after selector removal and any route-specific argument/option preparation. |
| `ExpansionSpecifications` | Individually held recognized specification forms, in order. Literal routes preserve syntax; preparation may resolve values. Recognition has the positional-name limitations in W3-02. |
| `AmbientAssumptions` | Actual assumption value at native entry. |
| `Assumptions` | `Missing["NativeContract"]`. |
| `NativeEvaluationStatus` | `"Computed"`, `"Unresolved"`, `"Failed"`, or `"Aborted"`, determined syntactically from the native output. |
| `NativeBackend`, `NativeKernelVersion`, `NativeSystemID` | Selected backend and producing runtime. |
| `BackendSelection`, `BackendSelectionReason`, `OrderConvention` | Automatic native results record `Automatic`, their routing reason, and `"Native"` order semantics. |
| `PackageFailure` | The representation failure leading to automatic fallback, or `None` for direct native routing. |
| `NativeAttempts` | Automatic-only ordered records of each attempted backend, evaluation status, and actual held request. |

Preserve nested `SeriesData`, lists, conditions, ordinary expressions, and
infinite sums. Native `Asymptotic` may return a finite expression without
an `O` term; that is not evidence of exactness. Native `SeriesData` records
formal order, not a proved finite logarithmic error degree, real-valued
source, derivative estimate, or uniform parameter domain. Its preservation
does not invoke the sparse-to-dense optional analytic exporter. See
[native remainder contracts](NATIVE_SERIES_REMAINDERS.md) and the official
[SeriesData reference](https://reference.wolfram.com/language/ref/SeriesData.html).

This separation from the analytic exporter does not make native construction
lazy: the current `normal = Normal[result]` step can itself expand a large
sparse result. W3-04 tracks demand-driven access to `Expression` and `Normal`,
including evaluation timing and restoration behavior. No lazy-view capability
or construction-memory bound is established by the current contract.

`Normal` removes the native structures it normally handles. It must not be
documented as invariably producing a finite polynomial or finite sum: an
infinite ordinary expression can remain. Display the stored native result
without adding `Missing` as a mathematical remainder. Copying preserves the
full wrapper and metadata. See the official
[Normal reference](https://reference.wolfram.com/language/ref/Normal.html).

## Input, evaluation, and branches

Explicit native dispatch precedes the package's positive-real coordinate and
coefficient admission. It forwards native-supported request structures and
options without a special-function whitelist. Equivalent option spellings,
computed keys, and option-like positional variable names remain unresolved
request-classification work (W3-02); this description does not claim full
equivalence for every accepted native syntax. Complex coefficients, symbolic
centers, approximate input, inactive expressions, or several variables must
not be rejected merely because the analytic real representation cannot encode
them. Preserve the order of successive specifications and their binding roles.

The dispatcher preserves literal calls under `HoldComplete` until release to
the selected System head. Computed trailing containers are resolved before
the source, which stays held until the selected backend establishes its
evaluation context. This preparation is not a promise to preserve arbitrary
side-effect ordering of a direct native call. `OriginalArguments` retains the
preparation input. Selector discovery traverses option containers, not rules
inside the source or another option's value.

The native call runs under the ambient assumptions captured at entry. Native
option expressions, including delayed options, stay in the held request and
are left to native evaluation on direct native routes. They are not evaluated again to populate
metadata. `AmbientAssumptions` is not the effective value of an explicit
`Assumptions` option, and `ExpansionSpecifications` is not a general snapshot
of effective endpoint or order values: literal and prepared routes differ.
Only the request metadata is held; the returned `NativeResult` payload itself
is not enclosed in `HoldComplete`. Do not infer the analytic
[stored-context policy](ASSUMPTION_CONTEXT.md) from these syntactic records.
Ordinary Wolfram definitions remain in effect. Evidence must identify the
kernel, original request, relevant definitions, and returned result.

An automatic package attempt evaluates its source in the package's neutral
proof context and materializes common options once. On a representation
failure, the native request reuses those evaluated source/specification and
option values. It does not replay the original source program or delayed
common-option callbacks. Ordinary evaluation inside either engine can still
invoke user definitions. The native call itself restores the captured ambient
context; this does not undo evaluation already performed for the package attempt.

When both backends accept the supplied option keys, automatic search reuses
the prepared request after an unresolved or failed first attempt. Explicit
common `Assumptions` and `SeriesTermGoal` values are materialized once, with
first-option precedence and without executing unused duplicate delayed values.
Search stops at a computed result or an abort and otherwise keeps the preferred
result when both attempts fail. A native-exclusive option limits search to its
compatible engine; explicit backend selection likewise never changes engines.
Surviving native subexpressions can still evaluate under ordinary Wolfram rules.

Native delegation adds no independent real-branch proof. Explicit package-only
`"MaxTerms"` and `"InverseFunctionBranches"` options return
`Failure["NativeOptionConflict", ...]`; their restrictions are not discarded.
The native backend receives source conditions and native options. Do not
interpret missing generated conditions as unconditional validity. An unresolved native call
must not be described as a successfully computed expansion. Automatic fallback
keeps callable/inverse and conditional source requests, existing package
series/remainders, and explicit direction, branch and resource options on the
package path. Its recursive `Function` search also protects some ordinary
expressions containing function syntax, even when they are not callable
sources (W3-03). Conditional-source protection excludes some otherwise
native-supported complex requests (W3-09). These are known coverage obstacles,
not exceptions to the full-subsumption requirement. Its narrow failure
classifier excludes malformed requests,
domain/branch failures and resource exhaustion. Compatible second-backend
search closes one availability gap; a complete coverage theorem remains open.
In particular, `Computed` does not certify expansion of every nested inactive
expression. Conversely, native syntax inside a held expression can be marked
`Unresolved` without being active unfinished work. The classifier detects
nested failures and aborts, but does not independently check the correctness,
requested order, or domain of the result; W3-05 tracks that distinction.
See the [complete compatibility deviation register](NATIVE_COMPATIBILITY.md#known-deviations-and-unresolved-coverage).

## Parameter dependence and analytic operations

For each fixed `a > 0`, `a/(a + x)` has constant approximation `1` as `x -> 0+`,
with exact error `-x/(a + x)` bounded by `x/a`. On the diagonal `a = x` its
value is `1/2`. Neither a fixed-parameter expansion nor successive formal
expansions supply the uniform estimate needed to justify that substitution.
The pure mathematical account is in
[the scale chapter](../article/sections/02-scale.tex), subsection
`sec:formal-successive-jets`.

Package analytic arithmetic, truncation, and refinement return
`Failure["NativeSeriesContract", ...]` for native results: those operations
require an independently justified analytic contract, which native payload
preservation does not supply. Native calculations can continue
on `s["NativeResult"]`; operations on `Normal[s]` discard native series
information as specified by `Normal`. Native numerical application substitutes
into `Expression` only when one variable is identified; multiple or unresolved
variables return `Failure["NativeVariables", ...]`. This evaluation does not
supply a positive-real domain or an analytic certificate.

The [C07 coefficient rule](REAL_COEFFICIENTS.md) remains mandatory for analytic
real representations. A complex native result is permissible without becoming
a real-source assertion or entering real Lipschitz error propagation. Tests
must check the representation and its contract, not require every formerly
rejected complex public input to remain rejected by the expanded interface.

## Acceptance evidence and remaining coverage

The [rule-goal acceptance](../../validation/native-rule-goal-tests.json)
records 116 passes and zero failures across five selected files, including
15 cases added for scalar rule requests with explicit `Automatic` or
nonpositive integer native goals. The [116/0 runner](../../validation/CheckNativeRuleGoals.wl)
also selects adjacent search, dispatch, explicit-native, and assumption cases.
That bounded repair preserves triple cutoffs and explicit package constraints;
it does not settle configured defaults, equivalent keys, or conditional
source routing. The [compatibility plan](NATIVE_COMPATIBILITY.md)
separately records prior automatic-search and explicit-mode milestones.

The [focused entry script](../../validation/CheckNativeCompatibility.wl)
selects native compatibility, contract and presentation cases plus adjacent
result, normalization, arithmetic, assumption and real-coefficient regressions.
Its [final record](../../validation/native-compatibility-tests.json) reports
130 successes and no failures for the recorded pre-rename source snapshot.
Its original package paths and context remain in the evidence; they do not
validate the later AsymptoticAnalysis rename. The
[first-pass record](../../validation/native-compatibility-first-pass.json)
preserves two fixture failures corrected before acceptance; the
[validation account](../../validation/README.md#explicit-native-expansion-backends)
distinguishes those from the additional metadata correction and new tests.

Continue differential checks against each required native head, including order
semantics, complex and approximate coefficients, symbolic centers, successive
variables, conditions, unknown-function options, inactive expressions, and
infinite results. Check held evaluation and option effects independently from
algebraic output equivalence. Add the currently missing `DiscreteAsymptotic`
input, option, integer-domain, and result coverage. Verify native operation
refusal, lossless stored
results, and preservation of all existing analytic contracts. Report only the
cases actually run and link their results in the
[validation record](../../validation/README.md); no full-suite run is implied.
