# AsymptoticAnalysis

A Wolfram Language package for real asymptotic expansions of functions and
their inverses. It handles real exponents, logarithmic coefficients, finite
and infinite endpoints, and selected logarithmic, exponential, flat, and
oscillatory scales. Analytic results carry an explicit remainder and real branch
information. Native backends preserve built-in formal and asymptotic results
with their own contracts, selected explicitly or by automatic routing.

The package and Wolfram context are now named `AsymptoticAnalysis`. Public
function names, including `AsymptoticInverse`, are unchanged. The
[loading guide](src/Documentation/UserGuide.md#loading-fixed-versions)
also explains how to load revisions from before the package rename.

The current development target is complete input coverage of the built-in
Wolfram `Series` and `Asymptotic` functions, including native-supported cases
outside the existing real expansion models. Native delegation, the
`AsymptoticExpand` alias, and automatic routing for native specifications,
options and selected representation failures are implemented. Successful
package calls keep their existing cutoff and block-count conventions; native
results record native order semantics. Complete coverage remains a development
target, with further routing and input-matrix work recorded in the
[native compatibility plan](docs/development/NATIVE_COMPATIBILITY.md), alongside
the required interfaces, result semantics, and validation boundaries.

## Documentation

| Document | Read it for |
| --- | --- |
| **[Mathematical article (PDF)](docs/article/asymptotic-inverse.pdf)** · [LaTeX source](docs/article/asymptotic-inverse.tex) | Definitions, theorems, proofs, mathematical examples, and the hypotheses behind each scale and error estimate. |
| **[User guide (HTML)](src/Documentation/UserGuide.html)** · [Markdown source](src/Documentation/UserGuide.md) | Loading the package, function syntax, options, worked inputs and outputs, branch selection, result properties, and possible issues. |
| **[Code review reports](external-reports/code-review/README.md)** | Eighteen reports in two waves: [reports 1–9](external-reports/code-review/wave-1/README.md) and [reports 10–18](external-reports/code-review/wave-2/README.md), with pinned revisions, mathematical and engineering findings, evidence, regression candidates, and proposed patches. |
| **[Vendored ProveIt articles](vendor/proveit/README.md)** | A revision-pinned TeX/PDF library on asymptotic expansions, transseries, q-analogs, combinatorial sequences, and their interpolated inverses, with topic reading lists and build provenance. |

The article is independent of software syntax. The guide follows the
organization of Wolfram Language reference documentation and explains the
package's supported interfaces. The [documentation index](docs/README.md)
also gives reading paths for contributors and the historical research material.

## Get started

Load the current `main` version directly from GitHub in a Wolfram kernel:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticAnalysis.wl"]];
```

This downloads the complete standalone package to a temporary file, then
loads it with normal `Get`. No installation or local checkout is required.
The GitHub URL points to the repository-root
[`AsymptoticAnalysis.wl`](AsymptoticAnalysis.wl). Moving the modular package
directory to `src/` does not change this standalone URL.
Downloading first avoids an observed Wolfram 15.0.1 issue that intermittently
truncated direct `Get` of the compressed package response.

For a fixed version, use the guide's
[commit-pinned loading form](src/Documentation/UserGuide.md#loading-fixed-versions).
The repository-root `AsymptoticAnalysis.wl` is also a complete single-file
package that you can download and load with local `Get` offline.

From a local checkout, load the modular entry point instead:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
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
[LogGamma, affine, powered, and reciprocal-target extensions](src/Documentation/UserGuide.md#inverse-gamma-and-loggamma).

The forward interface also covers admitted Bessel, Airy, error-integral,
fixed-parameter incomplete Gamma, zeta/polylogarithm, hypergeometric, and
elliptic expansions. Supported cases include finite singularities,
exponential factors, and oscillatory tails:

```wolfram
AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[Erfc[x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[EllipticK[1 - x], x -> 0, SeriesTermGoal -> 3]
```

The [special-function guide](src/Documentation/UserGuide.md#special-function-expansions)
explains real branches, fixed parameter assumptions, complete block counts
for separate carriers, and the distinction between exact identities and
exponentially small tails. These are endpoint-specific capabilities, not a
claim that every special function or simultaneous parameter limit is supported.

Analytic series objects normalize ordinary arithmetic and retain their remainders:

```wolfram
a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
a + b
a b
a/(1 + x)
b^(1/2)
SeriesNormalize[(1 + a)/(1 - a), "Cutoff" -> 4]
```

Constructors return [`GeneralizedSeries`](src/Documentation/UserGuide.md#GeneralizedSeries)
objects. StandardForm and TraditionalForm hide the head. For analytic results,
`Normal` extracts the finite expression. Keep the series object when doing further
arithmetic that needs its remainder. In the package path, `{x, 0, 5}`
uses an **exclusive power cutoff**; `SeriesTermGoal` requests complete
nonzero blocks. These are distinct from the native `Series` order convention.
Version 1.8.0 renames the former `PowerLogSeries`
head, so explicit patterns should now use `_GeneralizedSeries`. The
[arithmetic guide](src/Documentation/UserGuide.md#series-operations)
explains precision propagation, ordinary function operands, held normalization,
and composite error bounds for compatible expansions in different scales.

Select a built-in expansion engine explicitly when its input forms and order
semantics are wanted:

```wolfram
n = AsymptoticExpand[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
n["NativeResult"]
Normal[n]
AsymptoticExpansion[Gamma[x], {x, Infinity, 3}, "Backend" -> "Asymptotic"]
```

Native results preserve the backend output with `"Kind" -> "Native"`.
Their package remainder is `Missing["NativeContract"]`; a formal native order
does not establish an analytic error bound. `Normal` follows the stored native
result and need not be finite. Continue native operations on `"NativeResult"`.
See [Native Expansion Backends](src/Documentation/UserGuide.md#native-backend-expansions).

Version 1.8.0 declares Wolfram Language 15.0 or later. Native validation
records use Wolfram 15.0.1 for Windows; see the [validation record](validation/README.md)
for the exact scope of each run.

Mathics3 compatibility is also under active validation. See the
[Mathics compatibility guide](docs/Mathics/COMPATIBILITY.md) for installation,
tested features, interpreter settings, and remaining limitations.

## Repository

| Location | Content |
| --- | --- |
| [AsymptoticAnalysis.wl](AsymptoticAnalysis.wl) | Generated standalone package for loading from a URL download or single-file offline use. |
| [src/](src/README.md) | Package loading, [kernel source](src/Kernel/README.md), [examples](src/Examples/README.md), and [focused tests](src/Tests/README.md). |
| [docs/article/](docs/article/README.md) | Mathematical article and its build instructions. |
| [docs/](docs/README.md) | Reading paths and links between mathematical, user, and contributor documentation. |
| [docs/development/](docs/development/README.md) | Current review status, implementation plans, gotcha notes, and preserved historical engineering chapters. |
| [external-reports/](external-reports/README.md) | Nine original research proposals and eighteen later code reviews, with articles, evidence, comparisons, and provenance. |
| [vendor/](vendor/README.md) | Revision-pinned ProveIt articles on asymptotic expansions and inverses, with TeX, PDFs, topic reading lists, and upstream build provenance. |
| [validation/](validation/README.md) | Reproducible checks and historical validation evidence. |
| [docs/mathematica.stackexchange.com/](docs/mathematica.stackexchange.com/README.md) | The two motivating questions, original online sources, and saved snapshots. |
| [docs/WOLFRAM-NOTES.md](docs/WOLFRAM-NOTES.md) | Development notes on Wolfram Language behavior. |

When changing the kernel sources, regenerate the standalone file with
`python validation/build_standalone.py`. The
[development notes](docs/development/README.md#standalone-package) describe
the freshness check and focused loading validation.

Documentation build and review commands are in [docs/article/README.md](docs/article/README.md)
and [Documentation/README.md](src/Documentation/README.md).

## Development status

The [implementation register](docs/development/CODE_REVIEW_STATUS.md) maps
findings from both review waves to completed fixes, focused evidence, and
outstanding work. Begin there when choosing a repair; a supplied report or
patch describes its pinned snapshot, not necessarily today's behavior.

`AsymptoticExpand` is a held alias of `AsymptoticExpansion`. Both currently use
the package engines under `"Backend" -> Automatic`; `"Package"` explicitly
selects that same path. Explicit `"Series"` and `"Asymptotic"` modes are
implemented with [130 passing focused checks](validation/native-compatibility-tests.json)
across eight selected files, with no failures. The
[compatibility plan](docs/development/NATIVE_COMPATIBILITY.md) tracks required
automatic fallback and remaining coverage evidence. Existing analytic
special-function tests do not validate this new native result contract.

For a change, update the applicable source, guide, mathematical hypotheses,
and [development notes](docs/development/README.md). Run the relevant focused
checks and report their scope. The current instruction is to **skip the full
package suite**; historical test totals are not current full-suite acceptance.
