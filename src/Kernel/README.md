# Modular kernel implementation

This directory is the canonical source of the AsymptoticAnalysis package.
Load [AsymptoticAnalysis.wl](AsymptoticAnalysis.wl), which declares the public
context and loads its companion modules in order. The paclet entry point,
[init.m](init.m), delegates to that file. Companion modules share private
definitions and should not be loaded independently.

From the repository root:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
```

The [package README](../README.md) covers paclet and remote loading. Public
syntax, options, and result properties are documented in the
[user guide](../Documentation/UserGuide.md).

## Source map

| Entry points | Responsibility |
| --- | --- |
| [AsymptoticAnalysis.wl](AsymptoticAnalysis.wl) | Public declarations, real power-log models, equal-exponent collection, coefficient calculus, result construction, and module loading. |
| [NativeCompatibility.wl](NativeCompatibility.wl) | Held backend selection, compatible native-backend retries, the `AsymptoticExpand` alias, lossless native results, request and attempt metadata, and analytic-operation guards. |
| [InverseFunctionExpressions.wl](InverseFunctionExpressions.wl), [InverseFunctionSyntax.wl](InverseFunctionSyntax.wl), [InverseFunctionBranches.wl](InverseFunctionBranches.wl) | Held forward requests, inverse-function syntax, and real branch admission. |
| [SourceCoordinates.wl](SourceCoordinates.wl), [CoordinateInverse.wl](CoordinateInverse.wl) | Source charts and coordinate transport. |
| [CorePerturbation.wl](CorePerturbation.wl), [LambertInverse.wl](LambertInverse.wl), [GammaInverse.wl](GammaInverse.wl), [BarnesInverse.wl](BarnesInverse.wl) | Perturbative inverse construction and specialized cores. |
| [GammaForward.wl](GammaForward.wl), [BarnesForward.wl](BarnesForward.wl), [ExponentialForward.wl](ExponentialForward.wl) | Factored forward expansions, logarithms, products, ratios, and admitted powers. |
| [LogarithmicScales.wl](LogarithmicScales.wl), [FlatSectors.wl](FlatSectors.wl), [FourierCoefficients.wl](FourierCoefficients.wl) | Nested logarithmic scales, flat exponential sectors, and Fourier coefficient families. |
| [SpecialFunctionAdapters.wl](SpecialFunctionAdapters.wl), [NativeSpecialFunctions.wl](NativeSpecialFunctions.wl), [SpecialFunctionRealDomain.wl](SpecialFunctionRealDomain.wl) | Special-function admission, native-series import, and real-domain checks. |
| [ParameterizedSpecialFunctions.wl](ParameterizedSpecialFunctions.wl), [DirichletSpecialFunctions.wl](DirichletSpecialFunctions.wl) | Fixed-parameter special-function branches, Dirichlet scales, and explicit Zeta/Lerch tail bounds. |
| [SeriesOperations.wl](SeriesOperations.wl), [SeriesArithmetic.wl](SeriesArithmetic.wl), [SeriesEnvelopeArithmetic.wl](SeriesEnvelopeArithmetic.wl) | Explicit operations, composition parameter scope and source provenance, ordinary arithmetic dispatch, and composite remainder bounds. |
| [RefinementRequests.wl](RefinementRequests.wl), [RefinementState.wl](RefinementState.wl), [IncrementalInverse.wl](IncrementalInverse.wl) | Refinement requests, retained state, and incremental inverse work. |
| [InverseCertificates.wl](InverseCertificates.wl), [NumericalInverseChecks.wl](NumericalInverseChecks.wl) | Quantitative certificates and separate numerical diagnostics. |
| [MathicsCompatibility.wl](MathicsCompatibility.wl) and the `Mathics*.wl` companions | Interpreter-specific adapters loaded only on Mathics; see the compatibility map below. |

This map identifies starting points, not an exhaustive list of dependencies.
The entry point is authoritative for load order. The
[development index](../../docs/development/README.md) links the implementation
register and notes on assumptions, coefficient reality, and native remainders.
`Automatic` now selects native backends for native specifications/options and
selected representation failures. If the preferred backend fails or remains
unresolved, it tries the other backend when that backend supports all supplied
native option keys. Search reuses the prepared source and effective common
options, records ordered `NativeAttempts`, and preserves the preferred result
if neither backend completes. Explicit native selection remains a single
delegation. Successful package requests retain their existing conventions;
`"Package"` keeps the analytic engines and refuses native-only options.
The [nine-file native-search acceptance](../../validation/native-search-tests.json)
records **179 passed, zero failed tests** with unchanged source hashes, through
[CheckNativeSearch.wl](../../validation/CheckNativeSearch.wl). The earlier
[130/0 explicit-native](../../validation/native-compatibility-tests.json) and
[163/0 automatic-routing](../../validation/native-automatic-tests.json) records
belong to their historical source snapshots.
The [compatibility plan](../../docs/development/NATIVE_COMPATIBILITY.md)
records remaining coverage work and the limits of the automatic policy.
The [native result contract](../../docs/development/NATIVE_RESULT_CONTRACTS.md)
distinguishes formal orders from analytic remainders and explains held metadata.
The special-function importer remains a separate analytic conversion path.

The [equal-exponent notes](../../docs/development/EXPONENT_EQUALITY.md) explain
how provably equal exact weights are collected before truncation, boundary
degrees, and inverse enumeration. The
[composition-scope notes](../../docs/development/COMPOSITION_PARAMETER_SCOPE.md)
explain why fixed-parameter remainders need retained source and operation
provenance when composition introduces a varying parameter. Compatible exact
sources can be replayed; ordinary remainder transport does not assert a
uniform parameter bound.
[CheckReviewNormalization.wl](../../validation/CheckReviewNormalization.wl)
records [276 passed, zero failed tests](../../validation/review-normalization-tests.json)
across fifteen selected files, including arithmetic, inverse, Fourier,
logarithmic, assumption, and native-special neighbors. For just the two repair
files, use [CheckReviewScopeAndEquality.wl](../../validation/CheckReviewScopeAndEquality.wl).

## Mathics compatibility map

The entry point conditionally loads helpers in the isolated
``"AsymptoticAnalysis`Mathics`"`` context and companion overrides of
package-owned implementation definitions. The adapter context is removed
from the public context path after loading. The official Wolfram path skips
these adapters; they do not replace global `System` definitions. The
[compatibility guide](../../docs/Mathics/COMPATIBILITY.md) explains runtime
requirements, evaluation differences, and the scope of recorded tests.

| Implementation | Contract and reading path |
| --- | --- |
| [MathicsCompatibility.wl](MathicsCompatibility.wl), [MathicsCalls.wl](MathicsCalls.wl) | Scoped returns, association helpers, and held call evaluation; [runtime subtleties](../../docs/Mathics/COMPATIBILITY.md#compatibility-subtleties). |
| [MathicsLists.wl](MathicsLists.wl) | Package-private empty-list mapping repair that preserves argument effects and native behavior for other forms; [list semantics](../../docs/Mathics/LISTS.md). |
| [MathicsAssumptions.wl](MathicsAssumptions.wl), [MathicsSimplification.wl](MathicsSimplification.wl) | Conservative realness and sign reasoning; [assumption contracts](../../docs/Mathics/ASSUMPTIONS.md). |
| [MathicsAlgebra.wl](MathicsAlgebra.wl), [MathicsTaylor.wl](MathicsTaylor.wl), [MathicsCalculus.wl](MathicsCalculus.wl) | Bounded exact algebra, local Taylor work, and calculus adapters; [algebra contracts](../../docs/Mathics/ALGEBRA.md). |
| [MathicsInverseBranches.wl](MathicsInverseBranches.wl) | Callable evaluation and supported inverse-domain proofs; [callable contracts](../../docs/Mathics/CALLABLES.md). |
| [MathicsCoreFunctions.wl](MathicsCoreFunctions.wl), [MathicsSpecialFunctions.wl](MathicsSpecialFunctions.wl) | Package-owned support for selected exact cores and special functions. |
| [MathicsCertificate.wl](MathicsCertificate.wl), [MathicsRefinement.wl](MathicsRefinement.wl), [MathicsFormatting.wl](MathicsFormatting.wl), [MathicsTimeBudget.wl](MathicsTimeBudget.wl) | Interpreter-specific certificate, refinement, display, and simplification-budget handling. |

The [portable runner](../../validation/run_mathics_tests.py) executes selected
cases in fresh Mathics or Wolfram processes. Its results complement the
[focused Wolfram tests](../Tests/README.md); support in one runtime does not
establish identical evaluation or coverage in the other.

## Editing and validation

Edit modular sources and regenerate the repository-root
[standalone distribution](../../AsymptoticAnalysis.wl) in the same change:

```powershell
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

The standalone file is generated; changes made only there are overwritten by
the next build. The builder preserves source order and records normalized
source hashes. Choose relevant [focused tests](../Tests/README.md), keep the
guide and mathematical hypotheses consistent with the change, and record
validation scope as described in [validation/](../../validation/README.md).
The current development instruction is to skip the full package suite.
