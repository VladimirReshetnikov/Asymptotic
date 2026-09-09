# Original research and implementation reports

This directory preserves the nine reports that informed the unified
AsymptoticInverse package. They arrived as independent research and Wolfram
Language implementations on September 7, 2026. Each report includes its own
mathematical article, package, examples, and verification material.

Start with the [analysis and comparison](COMPARISON.md). It compares the
mathematics, cutoff conventions, coefficient engines, original validation
claims, and subsequent native observations. Its execution results describe
those report packages at the recorded milestone, not the current unified
package.

| Report | Submitted package and distinguishing scope |
| --- | --- |
| [01 · RealInverseAsymptotics](01-RealInverseAsymptotics/README.md) | Multi-index inversion with a supplied forward remainder and inverse observables. |
| [02 · RealInverseAsymptotics_1](02-RealInverseAsymptotics_1/README.md) | Multi-index and fixed-point constructions, explicit convergence estimates, and resummation. |
| [03 · RealInverseAsymptotics_1_1](03-RealInverseAsymptotics_1_1/README.md) | Exact logarithmic degree formulas and coefficient recurrences. |
| [04 · RealInverseAsymptotics_1](04-RealInverseAsymptotics_1/README.md) | Euler-operator construction without multi-index enumeration, composition, and residual checks. |
| [05 · RealInverseAsymptotics_2](05-RealInverseAsymptotics_2/README.md) | Inclusive cutoffs, supplied forward jets, and finite-smoothness inversion theory. |
| [06 · real-inverse-series](06-real-inverse-series/README.md) | Newton iteration in a jet algebra and perturbation about an invertible core. |
| [07 · RealLogPowerInverse](07-RealLogPowerInverse/README.md) | Unit leading power, inclusive cutoffs, and conditional quantitative error bounds. |
| [08 · PowerLogInverse research and package](08-PowerLogInverse_research_and_package/README.md) | Uniformizer cutoffs, Lambert cores, and flat perturbations. |
| [09 · power-log-inverse 1.0.0](09-power-log-inverse-1.0.0/README.md) | Exponent or depth truncation, symbolic exponents, and coefficient queries. |

Use each report's README for its load path, dependencies, notation, and
reproduction commands. The comparison identifies errors and limitations;
the packages have different public names and order conventions and are not
interchangeable with the maintained implementation. Load a historical
package in a separate kernel when reproducing its results.

For current work, use the [maintained package](../AsymptoticInverse/README.md),
[mathematical article](../article/README.md), and
[user guide](../AsymptoticInverse/Documentation/README.md). Later reviews of
the unified package are indexed separately under
[code-review/](../code-review/README.md); current fixes and outstanding
findings are tracked in the
[implementation register](../docs/development/CODE_REVIEW_STATUS.md).

Keep submitted source, PDFs, evidence, and attribution notices together.
Updates to the unified package belong in its maintained source and docs;
they do not rewrite these historical submissions.
