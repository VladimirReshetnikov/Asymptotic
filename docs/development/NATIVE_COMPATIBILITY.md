# Native expansion compatibility: required coverage and implementation plan

The accepted goal is for the package's expansion functionality to completely
subsume the input coverage of ``System`Series`` and ``System`Asymptotic``, while
allowing a different result representation. This includes their less familiar
inputs and options, not only the examples in the current user guide.
**The compatibility layer described here is pending. This plan does not claim
that the goal has been achieved or that its proposed tests have run.**

## Current boundary

The public function is currently `AsymptoticExpansion`. Its
[held entry and ordinary engine](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl)
accept one expansion variable and use an exclusive power cutoff. The
[forward dispatcher](../../AsymptoticInverse/Kernel/InverseFunctionExpressions.wl)
constructs a positive real local coordinate before selecting an engine.
Exact real input, admissible real coefficients and supported coefficient
scales are required by these paths. The
[structured special-function importer](../../AsymptoticInverse/Kernel/NativeSpecialFunctions.wl)
also requires a real-domain proof and a supported finite error representation.
Those contracts are useful, but cannot represent all native inputs or outputs.

The official references are [Series](https://reference.wolfram.com/language/ref/Series.html),
[Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html), and
[SeriesData](https://reference.wolfram.com/language/ref/SeriesData.html).
The matrix below follows those interfaces and examples. Runtime option lists
and evaluation attributes must also be checked on the installed kernel;
compatibility evidence must name that kernel version.

## Proposed naming and order decision

Retain `AsymptoticExpansion` as the implementation entry point. Support the
requested spelling `AsymptoticExpand` through a held alias, without renaming
the existing API or its stored recipes. This alias remains to be implemented.

The existing `{x, x0, n}` means retain powers strictly below `n`; native
`Series` requests terms through its order `n`. An alias cannot reconcile
that semantic collision. The proposed decision is an explicit backend
selector, separate from native `Method`, whose native modes preserve the
selected backend's order convention:

```wolfram
AsymptoticExpansion[expr, specs, "Backend" -> "Series", nativeOptions]
AsymptoticExpansion[expr, spec, "Backend" -> "Asymptotic", nativeOptions]
```

These are proposed interfaces, not current syntax. Automatic mode should
preserve existing package conventions and add native coverage where the
proved real representation is unavailable. Store the backend and order
convention so that cutoff, term count and native order cannot be confused.

## Required coverage matrix

Every row is a pending compatibility requirement; it is not a support claim.

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

Introduce a distinct native result kind before attempting conversion to a
real power-log representation. Preserve the complete `NativeResult`, original
held request, ordered specifications, resolved options and assumptions,
backend, kernel version and evaluation status. A native result can contain
nested `SeriesData`, ordinary expressions, lists, `ConditionalExpression`,
`Piecewise` or infinite sums; these shapes must not themselves cause rejection.

A `SeriesData` remainder is a native formal-order descriptor. Its presence
does not prove a finite logarithmic error degree, source reality or derivative
control. A finite expression returned by `Asymptotic` must not receive
`"Remainder" -> 0` or `"Exact" -> True` simply because no `O` term is present.
Record the backend's contract separately from an independently established
analytic envelope. See [native remainder contracts](NATIVE_SERIES_REMAINDERS.md).

Display the native result without adding an unavailable remainder to it.
Copying must retain the full object; `Normal` should use the corresponding
native normalization. Preserve an unresolved native call as unresolved,
rather than claiming that an expansion was computed. Only a justified
conversion may attach the existing real-series arithmetic, refinement or
certificate contracts. Single-variable numerical substitution must not be
applied blindly to a multivariable native object.

## Evaluation and real-branch safeguards

Place native request handling before `localCoordinate`, `validateInput` and
the real coefficient checks. Let the selected native head receive the original
expression with its own evaluation semantics; do not eagerly evaluate an
integral or solver expression once to probe it and again during fallback.
Preserve inactive heads, scoped variables, nested option lists and delayed
options. Capture effective assumptions and retain the
[stored-context policy](ASSUMPTION_CONTEXT.md) without adding positivity
conditions or silently changing the parameter domain.

Fallback must distinguish representation limits from malformed requests,
explicit resource limits and incompatible user-selected inverse branches.
It must not silently drop options or choose a different inverse branch.
Record native diagnostics without treating every warning as a failed result.

C07 tests become representation-specific: the ordinary real engine must still
reject nonreal coefficients, while a native formal or complex result may be
admitted by the expanded public interface. It must not acquire a real-source
assertion or enter real Lipschitz error rules. The separately justified
special-function real projection remains governed by
[the real-coefficient contract](REAL_COEFFICIENTS.md).

## Implementation stages and evidence

1. Add the held native request parser, explicit backend selection and union
   of supported request forms before real-coordinate admission. Validate
   order conventions and native option forwarding independently.
2. Add the lossless native result kind, display and `Normal` behavior. Do not
   rebuild a returned native series through the bounded sparse-to-dense exporter.
3. Add automatic routing and fallback, with explicit branch and diagnostic
   handling. Keep analytic promotion conditional on its own proof obligations.
4. Test a focused differential matrix covering every row above, including
   unknown-function options, mixed complex/approximate data, multiple variables,
   conditions, infinite order, inactive transforms and existing package examples.
5. Document the resulting public interfaces and evidence. Extend operations
   on native results only where their formal or analytic semantics are defined.

The target invariant is structural: on the same kernel, with corresponding
effective arguments, options and evaluation context, every successfully
computed native result has a lossless package representation. Finite tests
provide evidence for routing and preservation; they cannot establish universal
coverage. Record the exact native requests, versions, outputs and evidence
limits in the [validation record](../../validation/README.md). These stages remain pending until implementation and acceptance evidence are recorded.
