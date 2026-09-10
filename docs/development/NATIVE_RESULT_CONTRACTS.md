# Native expansion result contracts

This note records the explicit native-backend contract implemented in
[NativeCompatibility.wl](../../src/Kernel/NativeCompatibility.wl).
[Focused acceptance](../../validation/native-compatibility-tests.json) records
130 passed, zero failed across eight selected files on Wolfram 15.0.1 for
Windows, with sources unchanged. This is explicit-mode evidence, not proof
that complete automatic coverage has been achieved.
Automatic fallback policy is tracked separately in the [compatibility plan](NATIVE_COMPATIBILITY.md);
the complete `Series`/`Asymptotic` input-superset objective remains the accepted
scope, and finite examples alone cannot establish it.

## Interface and order

`AsymptoticExpand` is a held alias of `AsymptoticExpansion`, with the same
`"Backend" -> Automatic` default. Successful package requests retain the real
analytic contract and existing order convention. Native specifications/options
and selected representation failures can instead produce a Native result,
explicitly recording `OrderConvention -> "Native"`.
`"Backend" -> "Package"` retains the package engines and declines native
fallback. Explicit `"Series"` and `"Asymptotic"` modes select the corresponding
System function, independently of that function's `Method` option.

The package's ordinary `{x, x0, h}` is an exclusive cutoff. Native `Series`
includes its requested order. Preserve the selected engine's order and
`SeriesTermGoal` semantics instead of translating by a universal `+1` or `-1`:
fractional powers, logarithms, infinity, and successive specifications need
the actual backend convention. See the official
[Series](https://reference.wolfram.com/language/ref/Series.html) and
[Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html) references.

## Representation boundary

| Field | Native result value or meaning |
| --- | --- |
| `Kind`, `Scale` | `"Native"`. |
| `NativeResult` | Complete returned backend expression. |
| `Expression` | `Normal[NativeResult]`. |
| `Remainder` | `Missing["NativeContract"]`. |
| `Exact` | `Missing["NotEstablished"]`. |
| `RemainderContract` | `"NativeFormalOrder"` or `"NativeAsymptotic"`. |
| `OriginalArguments` | Original public arguments inside `HoldComplete`. |
| `NativeRequest` | Held selected System call after removal of the backend selector. |
| `ExpansionSpecifications` | Individually held recognized syntactic specification forms, in order. |
| `AmbientAssumptions` | Actual assumption value at native entry. |
| `Assumptions` | `Missing["NativeContract"]`. |
| `NativeEvaluationStatus` | `"Computed"` if no native Series/Asymptotic call remains, otherwise `"Unresolved"`. |
| `NativeBackend`, `NativeKernelVersion`, `NativeSystemID` | Selected backend and producing runtime. |
| `BackendSelection`, `BackendSelectionReason`, `OrderConvention` | Automatic native results record `Automatic`, their routing reason, and `"Native"` order semantics. |
| `PackageFailure` | The representation failure leading to automatic fallback, or `None` for direct native routing. |

Preserve nested `SeriesData`, lists, conditions, ordinary expressions, and
infinite sums. Native `Asymptotic` may return a finite expression without
an `O` term; that is not evidence of exactness. Native `SeriesData` records
formal order, not a proved finite logarithmic error degree, real-valued
source, derivative estimate, or uniform parameter domain. Its preservation
does not invoke the sparse-to-dense optional analytic exporter. See
[native remainder contracts](NATIVE_SERIES_REMAINDERS.md) and the official
[SeriesData reference](https://reference.wolfram.com/language/ref/SeriesData.html).

`Normal` removes the native structures it normally handles. It must not be
documented as invariably producing a finite polynomial or finite sum: an
infinite ordinary expression can remain. Display the stored native result
without adding `Missing` as a mathematical remainder. Copying preserves the
full wrapper and metadata. See the official
[Normal reference](https://reference.wolfram.com/language/ref/Normal.html).

## Input, evaluation, and branches

Explicit native dispatch precedes the package's positive-real coordinate and
coefficient admission. It forwards native-supported request structures and
options without a special-function whitelist. Complex coefficients, symbolic
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
`Assumptions` option, and `ExpansionSpecifications` is not a snapshot of
evaluated endpoint or order values. Do not infer the analytic
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

Native delegation adds no independent real-branch proof. Explicit package-only
`"MaxTerms"` and `"InverseFunctionBranches"` options return
`Failure["NativeOptionConflict", ...]`; their restrictions are not discarded.
The native backend receives source conditions and native options. Do not
interpret missing generated conditions as unconditional validity. An unresolved native call
must not be described as a successfully computed expansion. Automatic fallback
keeps callable/inverse and conditional source requests, existing package
series/remainders, and explicit direction, branch and resource options on the
package path. Its narrow failure classifier excludes malformed requests,
domain/branch failures and resource exhaustion. No automatic second-backend
search or complete coverage theorem is claimed; see the compatibility plan.

## Parameter dependence and analytic operations

For each fixed `a > 0`, `a/(a + x)` has constant approximation `1` as `x -> 0+`,
with exact error `-x/(a + x)` bounded by `x/a`. On the diagonal `a = x` its
value is `1/2`. Neither a fixed-parameter expansion nor successive formal
expansions supply the uniform estimate needed to justify that substitution.
The pure mathematical account is in
[the scale chapter](../article/sections/02-scale.tex), subsection
`sec:formal-successive-jets`.

Package analytic arithmetic, truncation, and refinement return
`Failure["NativeSeriesContract", ...]` for native results until a suitable
analytic contract is independently supplied. Native calculations can continue
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

Continue differential checks against the selected native head, including order
semantics, complex and approximate coefficients, symbolic centers, successive
variables, conditions, unknown-function options, inactive expressions, and
infinite results. Check held evaluation and option effects independently from
algebraic output equivalence. Verify native operation refusal, lossless stored
results, and preservation of all existing analytic contracts. Report only the
cases actually run and link their results in the
[validation record](../../validation/README.md); no full-suite run is implied.
