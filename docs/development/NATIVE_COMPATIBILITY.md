# Native expansion compatibility: required coverage and implementation plan

The accepted goal is for the package's expansion functionality to completely
subsume the input coverage of ``System`Series`` and ``System`Asymptotic``, while
allowing a different result representation. This includes their less familiar
inputs and options, not only the examples in the current user guide.
**Explicit native delegation and the held alias are implemented, with
focused acceptance recorded. Automatic native fallback remains required work.
This plan does not claim that the complete goal has been achieved.**

## Current boundary

The public function `AsymptoticExpansion` and its held alias `AsymptoticExpand`
share `"Backend" -> Automatic`. In
[NativeCompatibility.wl](../../AsymptoticInverse/Kernel/NativeCompatibility.wl),
explicit `"Series"` and `"Asymptotic"` modes delegate before real-coordinate
admission and return a distinct native result. Both `Automatic` and `"Package"`
currently select the existing package path. That path's
[held entry and ordinary engine](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl)
accept one expansion variable and use an exclusive power cutoff. The
[forward dispatcher](../../AsymptoticInverse/Kernel/InverseFunctionExpressions.wl)
constructs a positive real local coordinate before selecting an engine.
Exact real input, admissible real coefficients and supported coefficient
scales are required by these paths. The
[structured special-function importer](../../AsymptoticInverse/Kernel/NativeSpecialFunctions.wl)
also requires a real-domain proof and a supported finite error representation.
Those analytic contracts remain in force for package results; the explicit
native result kind preserves outputs outside those representations.

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

These explicit interfaces are implemented. Automatic mode currently preserves
the existing package path; adding native coverage there remains required work.
`NativeBackend` identifies the selected native convention. The alias alone
does not turn an exclusive cutoff into native order.

## Required coverage matrix

Every row describes the full acceptance target. Structural explicit delegation
is implemented; the matrix is not a claim that every row has passed testing
or is reachable through Automatic mode.

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
recognized syntactic `ExpansionSpecifications`, `AmbientAssumptions`, backend,
kernel version and evaluation status. Native option expressions are not
reevaluated to build an effective-option snapshot; `Assumptions` is
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
`NativeEvaluationStatus` distinguishes remaining native calls from computed
expressions without claiming analytic validity. Analytic operations decline
native results with `NativeSeriesContract`. Numerical application requires one
identified variable; other cases return `NativeVariables`. See the detailed
[native result contracts](NATIVE_RESULT_CONTRACTS.md).

## Evaluation and real-branch safeguards

Explicit native handling precedes `localCoordinate`, `validateInput` and real
coefficient checks. Literal requests remain held until release to the native
head. Computed option containers can require ordinary argument evaluation to
discover the selector; original arguments remain held in metadata. The native
call runs under captured ambient assumptions, while explicit native options
are left to the backend. Held specifications are syntactic records, not
evaluated snapshots or independently retained analytic proof predicates.

Explicit native modes reject package-only `"MaxTerms"` and
`"InverseFunctionBranches"` options with `NativeOptionConflict`. They do not
silently discard those contracts. Automatic fallback still needs to
distinguish representation limits from malformed requests, explicit resource
limits and incompatible inverse branches. Native diagnostics must not be
confused with a proof that a returned expression is invalid.

C07 tests become representation-specific: the ordinary real engine must still
reject nonreal coefficients, while a native formal or complex result may be
admitted by the expanded public interface. It must not acquire a real-source
assertion or enter real Lipschitz error rules. The separately justified
special-function real projection remains governed by
[the real-coefficient contract](REAL_COEFFICIENTS.md).

## Implementation stages and evidence

1. **Implemented; focused verified:** held native request parser,
   explicit backend selection and delegation before real-coordinate admission.
   Validate native order, options, computed containers and evaluation effects.
2. **Implemented; focused verified:** preserved native result, display,
   `Normal`, metadata and analytic-operation guards, without sparse-to-dense export.
3. **Required and pending:** automatic routing and fallback with branch,
   option and diagnostic preservation. Analytic promotion needs its own proof.
4. **Partial evidence recorded:** focused differential tests across the matrix, including
   unknown-function options, mixed complex/approximate data, multiple variables,
   conditions, infinite order, inactive transforms and existing package examples.
5. **Source documentation updated; artifact builds pending:** public interfaces
   and contracts. Record generated artifacts separately from native acceptance.
   Extend native operations only where their semantics are defined.

The target invariant is structural: on the same kernel, with corresponding
effective arguments, options and evaluation context, every successfully
computed native result has a lossless package representation. Finite tests
provide evidence for routing and preservation; they cannot establish universal
coverage. Record the exact native requests, versions, outputs and evidence
limits in the [validation record](../../validation/README.md). The
[explicit-mode acceptance record](../../validation/native-compatibility-tests.json)
reports 130 passed and zero failed across eight files, with unchanged sources
on Wolfram 15.0.1 Windows. Existing analytic ingress/export tests alone do not
establish acceptance of the new native result kind, and this focused matrix
does not prove complete input-superset coverage.
