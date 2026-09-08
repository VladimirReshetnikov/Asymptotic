# Asymptotic expansions of inverse functions on a real branch

This repository studies asymptotic expansions of the real-valued branch of an
inverse function near a singular endpoint, together with the forward
expansions of functions whose asymptotics involve irrational exponents and
logarithms.  It grew out of two Mathematica Stack Exchange questions by
Vladimir Reshetnikov (see `docs/`):

- *How to get an asymptotic of the real-valued branch of the inverse function?*
  (question 236367): the inverse of `x + x^2 (1 + Log[x])` near `0+` has
  logarithmic coefficient blocks, and the inverse of `x + x^Sqrt[2]` has
  irrational exponents; the built-in `InverseFunction`, `Series`, `Asymptotic`
  and `InverseSeries` either fail or return a complex branch.
- *Asymptotic expansion for a function containing irrational exponents*:
  `Asymptotic[(1 + x + x^Sqrt[2])^Sqrt[2], x -> Infinity, SeriesTermGoal -> 7]`
  returns the input unchanged.

Both problems live in the same algebra of finite **power–log expansions**
`Sum[u^beta P_beta[Log[u]]]` with real exponents `beta` and polynomial
logarithmic coefficients, and both are solved by the package in this
repository.

The inverse engine also handles leading logarithmic and exponential cores,
including `x Log[x]` near `0` and `x Exp[x]` at infinity. It selects the real
Lambert-W branch and returns a finite expansion in inverse logarithms and
logarithms of logarithms, with a separate prefactor and remainder. See the
package README for the logarithmic cutoff convention.

The extended package also implements finite reciprocal/iterated logarithmic
hierarchies, perturbations of exact Lambert cores, finite flat exponential
sectors, Fourier coefficients, and special-function tail/threshold adapters.
Explicit series operations transport remainders, refinement retains reusable
computation state, and rational interval certificates support requested
absolute or relative accuracy. The article states each admitted family's
branch and error contract; these bounded algebras have distinct cutoff
meanings and do not claim a general transseries field.

## Layout

| Path | Content |
| --- | --- |
| `docs/mathematica.stackexchange.com/` | The two source questions (Markdown, PDF snapshot, URL). |
| `reports/01-…` to `reports/09-…` | Nine independently written research-and-implementation reports on question 236367, unpacked from the ZIP archives in which they arrived. Each contains a LaTeX article with PDF, a Wolfram Language package, native MUnit tests, examples and a Python verification record. See `reports/COMPARISON.md` for the analysis and native test results. |
| `AsymptoticInverse/` | The unified Wolfram Language package written for this repository: `Kernel/AsymptoticInverse.wl`, paclet metadata, tests, examples and a package README. |
| `article/` | The unified article *Asymptotic expansions of inverse functions on a real branch* (`asymptotic-inverse.tex` and the compiled PDF), which explains the theory behind the nine reports and the package: Lagrange–Bürmann reversion in the power–log algebra, the Euler-operator coefficient formula, branch selection, convergence, remainder estimates, transport of forward remainders, expansions at finite points and at infinity, powers and logarithms of the inverse, and the forward expansion engine. |
| `WOLFRAM-NOTES.md` | Findings about subtle Wolfram Language behaviour collected while working on this and earlier packages. |

## The package in one paragraph

`AsymptoticInverse[f, {x, x0}, {y, cutoff}]` returns the expansion of the real
branch of the inverse of `f` near `x0` (a real number, `Infinity` or
`-Infinity`) as a `PowerLogSeries` object: a finite expression in `y` plus an
inert remainder descriptor `PowerLogRemainder[w, beta, k]` standing for
`O[w^beta (1 + Abs[Log[w]])^k]`.  `AsymptoticExpansion[f, {x, x0, cutoff}]`
does the same for the forward asymptotics of `f`, including expressions such
as `(1 + x + x^Sqrt[2])^Sqrt[2]`.  Both accept `SeriesTermGoal -> n` instead of
a cutoff, keep every exponent exact (algebraic numbers are compared with
`RootReduce`, never numerically), record the first omitted block, and offer
independent checks (`InverseResidual`, `InverseNumericalCheck`).  See
`AsymptoticInverse/README.md` for the full interface.

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}]
(* y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2) + O[y^4 (1 + Abs[Log[y]])^3] *)

AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 4]
(* y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1) - (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2) + O[y^(4 Sqrt[2] - 3)] *)

AsymptoticExpansion[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, SeriesTermGoal -> 7]
```

## Reproducing

- Package tests: `wolfram -script AsymptoticInverse/Tests/RunTests.wl`
  (or `TestReport` on `AsymptoticInverse/Tests/AsymptoticInverse.wlt`).
- Article: run `pdflatex -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex`
  three times serially from `article/`; render the PDF to inspect its layout.
- Native test runs of the nine delivered packages: see `reports/COMPARISON.md`.

## License

MIT (see `LICENSE`).  The reports in `reports/` carry their own licenses
(MIT or MIT-0, with one article under CC BY 4.0), stated inside each report.
