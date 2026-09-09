# Modular kernel implementation

This directory is the canonical source of the AsymptoticInverse package.
Load [AsymptoticInverse.wl](AsymptoticInverse.wl), which declares the public
context and loads its companion modules in order. The paclet entry point,
[init.m](init.m), delegates to that file. Companion modules share private
definitions and should not be loaded independently.

From the repository root:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
```

The [package README](../README.md) covers paclet and remote loading. Public
syntax, options, and result properties are documented in the
[user guide](../Documentation/UserGuide.md).

## Source map

| Entry points | Responsibility |
| --- | --- |
| [AsymptoticInverse.wl](AsymptoticInverse.wl) | Public declarations, real power-log models, coefficient calculus, result construction, and module loading. |
| [NativeCompatibility.wl](NativeCompatibility.wl) | Held backend selection, the `AsymptoticExpand` alias, lossless native results, request metadata, and analytic-operation guards. |
| [InverseFunctionExpressions.wl](InverseFunctionExpressions.wl), [InverseFunctionSyntax.wl](InverseFunctionSyntax.wl), [InverseFunctionBranches.wl](InverseFunctionBranches.wl) | Held forward requests, inverse-function syntax, and real branch admission. |
| [SourceCoordinates.wl](SourceCoordinates.wl), [CoordinateInverse.wl](CoordinateInverse.wl) | Source charts and coordinate transport. |
| [CorePerturbation.wl](CorePerturbation.wl), [LambertInverse.wl](LambertInverse.wl), [GammaInverse.wl](GammaInverse.wl), [BarnesInverse.wl](BarnesInverse.wl) | Perturbative inverse construction and specialized cores. |
| [SpecialFunctionAdapters.wl](SpecialFunctionAdapters.wl), [NativeSpecialFunctions.wl](NativeSpecialFunctions.wl), [SpecialFunctionRealDomain.wl](SpecialFunctionRealDomain.wl) | Special-function admission, native-series import, and real-domain checks. |
| [SeriesOperations.wl](SeriesOperations.wl), [SeriesArithmetic.wl](SeriesArithmetic.wl), [SeriesEnvelopeArithmetic.wl](SeriesEnvelopeArithmetic.wl) | Explicit operations, ordinary arithmetic dispatch, and composite remainder bounds. |
| [RefinementRequests.wl](RefinementRequests.wl), [RefinementState.wl](RefinementState.wl), [IncrementalInverse.wl](IncrementalInverse.wl) | Refinement requests, retained state, and incremental inverse work. |
| [InverseCertificates.wl](InverseCertificates.wl), [NumericalInverseChecks.wl](NumericalInverseChecks.wl) | Quantitative certificates and separate numerical diagnostics. |

This map identifies starting points, not an exhaustive list of dependencies.
The entry point is authoritative for load order. The
[development index](../../docs/development/README.md) links the implementation
register and notes on assumptions, coefficient reality, and native remainders.
Explicit native delegation is implemented, with
[130 passed, zero failed focused checks](../../validation/native-compatibility-tests.json)
across eight selected files.
`Automatic` now selects native backends for native specifications/options and
selected representation failures; successful package requests retain their
existing conventions. `"Package"` keeps the analytic engines and refuses
native-only options. The [compatibility plan](../../docs/development/NATIVE_COMPATIBILITY.md)
records remaining coverage work and the limits of the automatic policy.
The [native result contract](../../docs/development/NATIVE_RESULT_CONTRACTS.md)
distinguishes formal orders from analytic remainders and explains held metadata.
The special-function importer remains a separate analytic conversion path.

## Editing and validation

Edit modular sources and regenerate the repository-root
[standalone distribution](../../AsymptoticInverse.wl) in the same change:

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
