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

From a Wolfram kernel whose working directory is the repository root:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];

s = AsymptoticExpansion[
  InverseFunction[x |-> ConditionalExpression[x + x^Sqrt[2], x > 0]],
  x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
s["Remainder"]

g = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[g]
```

Version 1.5.0 declares Wolfram Language 15.0 or later. Native validation
records use Wolfram 15.0.1 for Windows; see the [validation record](validation/README.md)
for the exact scope of each run.

## Repository

| Location | Content |
| --- | --- |
| [AsymptoticInverse/](AsymptoticInverse/) | Package, paclet metadata, examples, and focused test files. |
| [article/](article/) | Mathematical article and its build instructions. |
| [docs/development/](docs/development/) | Engineering roadmap and preserved operational chapters from the former combined article. |
| [validation/](validation/README.md) | Reproducible checks and historical validation evidence. |
| [reports/COMPARISON.md](reports/COMPARISON.md) | Analysis of the nine original research and implementation reports; their submitted artifacts remain in `reports/`. |
| [docs/mathematica.stackexchange.com/](docs/mathematica.stackexchange.com/) | The two motivating questions and source snapshots. |
| [WOLFRAM-NOTES.md](WOLFRAM-NOTES.md) | Development notes on Wolfram Language behavior. |

Documentation build and review commands are in [article/README.md](article/README.md)
and [Documentation/README.md](AsymptoticInverse/Documentation/README.md).
