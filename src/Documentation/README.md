# Package user guide

Read the **[rendered user guide](UserGuide.html)** or its
**[Markdown source](UserGuide.md)**. The guide is organized around Wolfram
Language usage forms, Details and Options, Examples, Applications,
Properties & Relations, Possible Issues, See Also, and Related Guides.
It documents this custom package and is not an official Wolfram reference page.

**The package must completely subsume Wolfram Language `Series`, `Asymptotic`,
and `DiscreteAsymptotic`: every input successfully handled by any of them
must also be handled correctly and successfully by AsymptoticAnalysis.**
The result representation may differ. This requirement is not yet met:
current native delegation covers `Series` and `Asymptotic`, and no
`DiscreteAsymptotic` backend is implemented. Read the
[known deviations and coverage gaps](UserGuide.md#native-coverage-gaps) and
the [implementation plan](../../docs/development/NATIVE_COMPATIBILITY.md).

**Complete package compatibility with both the official Wolfram kernel and
[Mathics3](https://mathics.org/) is a project goal.** Mathics support is under
active development; its current adapters and recorded validation cover
selected operations. The [Mathics compatibility guide](../../docs/Mathics/COMPATIBILITY.md)
separates the complete target from current coverage and remaining work.

**All asymptotics documented in `vendor/proveit/docs` are also in the required
coverage target**, including q-analogs, inverses, and combinatorial sequences.
See the [consolidated targets](../../docs/development/COVERAGE_TARGETS.md) and
[vendored asymptotics register](../../docs/development/VENDORED_ASYMPTOTICS.md)
for the distinction between mathematical source material, implementation,
and verified package coverage.

The separate **[mathematical article](../../docs/article/asymptotic-inverse.pdf)**
contains definitions, theorems, and proofs; its
[LaTeX source](../../docs/article/asymptotic-inverse.tex) is maintained separately.

## Find a topic

| Topic | Guide sections |
| --- | --- |
| Load from GitHub, a fixed commit, or a local checkout | [Getting Started](UserGuide.md#getting-started), [Fixed Versions and Offline Loading](UserGuide.md#loading-fixed-versions) |
| Use the Mathics3 compatibility path | [Mathics3 Compatibility](UserGuide.md#mathics-compatibility), [Installation and Runtime Contracts](../../docs/Mathics/COMPATIBILITY.md) |
| Select the public API | [Function Overview](UserGuide.md#function-overview), [AsymptoticExpansion](UserGuide.md#AsymptoticExpansion), [AsymptoticInverse](UserGuide.md#AsymptoticInverse) |
| Choose package or native order semantics | [Native Expansion Backends](UserGuide.md#native-backend-expansions), [Automatic Selection](UserGuide.md#automatic-backend-routing) |
| Check the complete coverage target and known deviations | [Known Deviations and Coverage Gaps](UserGuide.md#native-coverage-gaps), [Native Compatibility Plan](../../docs/development/NATIVE_COMPATIBILITY.md) |
| Read an expansion and its remainder | [GeneralizedSeries](UserGuide.md#GeneralizedSeries), [Coordinates and Cutoffs](UserGuide.md#coordinates-and-cutoffs) |
| Inspect properties across result families | [Result properties reference](ResultReference.md): stored keys, family-specific metadata, native results, and missing values |
| Work with parameters and real branches | [Assumptions and Parameter Domains](UserGuide.md#assumption-context), [Real Coefficients](UserGuide.md#real-coefficients) |
| Calculate with results or request more terms | [Series Arithmetic and Normalization](UserGuide.md#series-operations), [SeriesRefine](UserGuide.md#SeriesRefine) |
| Expand special functions and selected inverses | [Other Special Functions](UserGuide.md#special-function-expansions), [Inverse Gamma and LogGamma](UserGuide.md#inverse-gamma-and-loggamma), [Inverse Barnes G](UserGuide.md#barnes-inverse-expansions) |
| Check an inverse | [InverseResidual](UserGuide.md#InverseResidual), [InverseNumericalCheck](UserGuide.md#InverseNumericalCheck), [InverseCertificate](UserGuide.md#InverseCertificate) |
| Understand a refusal or precision limit | [Possible Issues](UserGuide.md#possible-issues) |

Successful expansion constructors return `GeneralizedSeries` objects; rejected
requests return a `Failure`. For analytic
representations, `Normal[s]` extracts the finite expression and `s["Remainder"]`
retains the omitted-order information. For [native results](UserGuide.md#native-backend-expansions),
`Normal` follows the stored native result's normalization and can retain an
infinite sum; native order alone does not establish an analytic remainder.
The available operations and cutoff meaning depend on the result's
scale. Numerical comparisons and supported interval certificates are separate
from its symbolic asymptotic remainder.
The [result properties reference](ResultReference.md) distinguishes common
accessors from the actual constructor-specific fields, including properties
that are deliberately absent or contain `Missing` values.

The optional [native `SeriesData` view](UserGuide.md#native-series-remainder-view)
exports an existing analytic result when its remainder and index range permit
it. A missing view does not invalidate the sparse expansion. This export is
distinct from preserving a built-in backend result in `"NativeResult"`.

The [package README](../README.md) provides a shorter introduction and loading
commands. The [example index](../Examples/README.md) links executable Wolfram
Language usage; the guide is the reference for admitted real domains and
options. The [kernel module guide](../Kernel/README.md) and
[test guide](../Tests/README.md) provide implementation and validation navigation.
The public symbol index describes the implemented package API.

## Rebuild

With Python and Pandoc on PATH, run from the repository root:

```powershell
python validation/build_user_guide.py
python validation/build_user_guide.py --check
```

The canonical sources are [UserGuide.md](UserGuide.md) and
[ResultReference.md](ResultReference.md); the builder generates
[UserGuide.html](UserGuide.html) and [ResultReference.html](ResultReference.html).
Both HTML pages embed [UserGuide.css](UserGuide.css) and require no external
assets or JavaScript. The builder checks unique anchors and local links,
including links between the generated pages, and verifies the user guide's
reference coverage for every public symbol declared by the package. Open the
HTML pages in a browser and inspect both wide and narrow layouts after changes.
Commit Markdown, CSS, and generated HTML together.

Focused native documentation examples are checked separately by
[CheckDocumentation.wl](../../validation/CheckDocumentation.wl); this is not
the full package test suite.
See the [validation record](../../validation/README.md) for recorded results.
