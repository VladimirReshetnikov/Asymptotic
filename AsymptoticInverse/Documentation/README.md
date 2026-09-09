# Package user guide

Read the **[rendered user guide](UserGuide.html)** or its
**[Markdown source](UserGuide.md)**. The guide is organized around Wolfram
Language usage forms, Details and Options, Examples, Applications,
Properties & Relations, Possible Issues, See Also, and Related Guides.
It documents this custom package and is not an official Wolfram reference page.

The separate **[mathematical article](../../article/asymptotic-inverse.pdf)**
contains definitions, theorems, and proofs; its
[LaTeX source](../../article/asymptotic-inverse.tex) is maintained separately.

## Find a topic

| Topic | Guide sections |
| --- | --- |
| Load from GitHub, a fixed commit, or a local checkout | [Getting Started](UserGuide.md#getting-started), [Fixed Versions and Offline Loading](UserGuide.md#loading-fixed-versions) |
| Select the public API | [Function Overview](UserGuide.md#function-overview), [AsymptoticExpansion](UserGuide.md#AsymptoticExpansion), [AsymptoticInverse](UserGuide.md#AsymptoticInverse) |
| Read an expansion and its remainder | [GeneralizedSeries](UserGuide.md#GeneralizedSeries), [Coordinates and Cutoffs](UserGuide.md#coordinates-and-cutoffs) |
| Work with parameters and real branches | [Assumptions and Parameter Domains](UserGuide.md#assumption-context), [Real Coefficients](UserGuide.md#real-coefficients) |
| Calculate with results or request more terms | [Series Arithmetic and Normalization](UserGuide.md#series-operations), [SeriesRefine](UserGuide.md#SeriesRefine) |
| Expand special functions and selected inverses | [Other Special Functions](UserGuide.md#special-function-expansions), [Inverse Gamma and LogGamma](UserGuide.md#inverse-gamma-and-loggamma), [Inverse Barnes G](UserGuide.md#barnes-inverse-expansions) |
| Check an inverse | [InverseResidual](UserGuide.md#InverseResidual), [InverseNumericalCheck](UserGuide.md#InverseNumericalCheck), [InverseCertificate](UserGuide.md#InverseCertificate) |
| Understand a refusal or precision limit | [Possible Issues](UserGuide.md#possible-issues) |

Expansion constructors return `GeneralizedSeries` objects. `Normal[s]` extracts
the ordinary finite expression; `s["Remainder"]` retains the omitted-order
information. The available operations and cutoff meaning depend on the result's
scale. Numerical comparisons and supported interval certificates are separate
from its symbolic asymptotic remainder.

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

The canonical source is [UserGuide.md](UserGuide.md); the HTML is generated from
it. The HTML embeds [UserGuide.css](UserGuide.css) and requires no external
assets or JavaScript. The builder checks unique anchors, local link
destinations, and reference coverage for every public symbol declared by
the package. Open the HTML in a browser and inspect both wide and narrow
layouts after changes. Commit Markdown, CSS, and generated HTML together.

Focused native documentation examples are checked separately by
[CheckDocumentation.wl](../../validation/CheckDocumentation.wl); this is not
the full package test suite.
See the [validation record](../../validation/README.md) for recorded results.
