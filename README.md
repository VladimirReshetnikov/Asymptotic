# AsymptoticInverse

A Wolfram Language package for real asymptotic expansions of functions and
their inverses. It handles real exponents, logarithmic coefficients, finite
and infinite endpoints, and selected logarithmic, exponential, flat, and
oscillatory scales. Results carry an explicit remainder and real branch
information.

## Documentation

| Document | Read it for |
| --- | --- |
| **[Mathematical article (PDF)](article/asymptotic-inverse.pdf)** · [LaTeX source](article/asymptotic-inverse.tex) | Definitions, theorems, proofs, mathematical examples, and the hypotheses behind each scale and error estimate. |
| **[User guide (HTML)](AsymptoticInverse/Documentation/UserGuide.html)** · [Markdown source](AsymptoticInverse/Documentation/UserGuide.md) | Loading the package, function syntax, options, worked inputs and outputs, branch selection, result properties, and possible issues. |

The article is independent of software syntax. The guide follows the
organization of Wolfram Language reference documentation and explains the
package's supported interfaces.

## Get started

Load the current `main` version directly from GitHub in a Wolfram kernel:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticInverse.wl"]];
```

This downloads the complete standalone package to a temporary file, then
loads it with normal `Get`. No installation or local checkout is required.
Downloading first avoids an observed Wolfram 15.0.1 issue that intermittently
truncated direct `Get` of the compressed package response.

For a fixed version, use the guide's
[commit-pinned loading form](AsymptoticInverse/Documentation/UserGuide.md#loading-fixed-versions).
The repository-root `AsymptoticInverse.wl` is also a complete single-file
package that you can download and load with local `Get` offline.

From a local checkout, load the modular entry point instead:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
```

Then compute an expansion:

```wolfram
s = AsymptoticExpansion[
  InverseFunction[x |-> ConditionalExpression[x + x^Sqrt[2], x > 0]],
  x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
s["Remainder"]

g = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[g]

ig = AsymptoticExpansion[
  InverseFunction[x |-> ConditionalExpression[Gamma[x], x > 2]][z],
  z -> Infinity, SeriesTermGoal -> 5];
Normal[ig]
```

The increasing Gamma inverse retains an exact Lambert core and expands in
complete polynomial reciprocal-logarithmic blocks at successive inverse
powers of that core. The guide covers its
[LogGamma, affine, powered, and reciprocal-target extensions](AsymptoticInverse/Documentation/UserGuide.md#inverse-gamma-and-loggamma).

The forward interface also covers admitted Bessel, Airy, error-integral,
fixed-parameter incomplete Gamma, zeta/polylogarithm, hypergeometric, and
elliptic expansions. Supported cases include finite singularities,
exponential factors, and oscillatory tails:

```wolfram
AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[Erfc[x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[EllipticK[1 - x], x -> 0, SeriesTermGoal -> 3]
```

The [special-function guide](AsymptoticInverse/Documentation/UserGuide.md#special-function-expansions)
explains real branches, fixed parameter assumptions, complete block counts
for separate carriers, and the distinction between exact identities and
exponentially small tails. These are endpoint-specific capabilities, not a
claim that every special function or simultaneous parameter limit is supported.

Series objects normalize ordinary arithmetic and retain their remainders:

```wolfram
a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
a + b
a b
a/(1 + x)
b^(1/2)
SeriesNormalize[(1 + a)/(1 - a), "Cutoff" -> 4]
```

`Normal` extracts only the finite expression. The
[arithmetic guide](AsymptoticInverse/Documentation/UserGuide.md#series-operations)
explains precision propagation, ordinary function operands, held normalization,
and composite error bounds for compatible expansions in different scales.

Version 1.7.1 declares Wolfram Language 15.0 or later. Native validation
records use Wolfram 15.0.1 for Windows; see the [validation record](validation/README.md)
for the exact scope of each run.

## Repository

| Location | Content |
| --- | --- |
| [AsymptoticInverse.wl](AsymptoticInverse.wl) | Generated standalone package for loading from a URL download or single-file offline use. |
| [AsymptoticInverse/](AsymptoticInverse/) | Package, paclet metadata, examples, and focused test files. |
| [article/](article/) | Mathematical article and its build instructions. |
| [docs/development/](docs/development/) | Engineering roadmap and preserved operational chapters from the former combined article. |
| [validation/](validation/README.md) | Reproducible checks and historical validation evidence. |
| [reports/COMPARISON.md](reports/COMPARISON.md) | Analysis of the nine original research and implementation reports; their submitted artifacts remain in `reports/`. |
| [docs/mathematica.stackexchange.com/](docs/mathematica.stackexchange.com/) | The two motivating questions and source snapshots. |
| [WOLFRAM-NOTES.md](WOLFRAM-NOTES.md) | Development notes on Wolfram Language behavior. |

When changing the kernel sources, regenerate the standalone file with
`python validation/build_standalone.py`. The
[development notes](docs/development/README.md#standalone-package) describe
the freshness check and focused loading validation.

Documentation build and review commands are in [article/README.md](article/README.md)
and [Documentation/README.md](AsymptoticInverse/Documentation/README.md).
