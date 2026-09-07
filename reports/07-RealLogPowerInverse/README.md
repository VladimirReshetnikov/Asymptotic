# RealLogPowerInverse 1.0.0

A Wolfram Language implementation of positive-real asymptotic inversion at
zero for finite log-power germs

    f(x) = a x + Sum[x^(1+alpha_j) P_j(Log[x])],  a > 0, alpha_j > 0.

The detailed article is in `article/article.pdf`; its self-contained LaTeX
source is `article/article.tex`. It treats both examples in the original
question, proves an all-orders coefficient formula, proves convergence for
sufficiently small positive arguments, and provides logarithm-aware remainder
bounds and an explicit conditional tail majorant.

## Quick start

From the extracted archive root, in a Wolfram Language session:

```wolfram
Get["Kernel/RealLogPowerInverse.wl"];
Clear[x,y,L];

r1 = RealInverseExpansion[x+x^2(1+Log[x]), {x,y}, 5];
r1["Expression"]
r1["Remainder"]
InverseResidual[r1]["Vanishes"]

r2 = RealInverseExpansion[x+x^Sqrt[2], {x,y}, 1+6(Sqrt[2]-1)];
r2["Expression"]
InverseResidual[r2]["Vanishes"]
```

`B` is an **absolute exponent cutoff**, inclusive, not a number of terms.
An entire polynomial in `Log[y/a]` is retained with each exponent. The
logarithmic example through exponent 3 is

    y - y^2 (1+Log[y]) + y^3 (2 Log[y]^2+5 Log[y]+3).

The remainder after just the first two terms is `O(y^3 Log[y]^2)`, **not**
`O(y^3)`.

### Structured inputs and scaling

```wolfram
r = LogPowerInverseExpansion[
  {{Sqrt[2]-1,1+L},{1,2-L}}, {y,L}, 3,
  "LinearCoefficient" -> 2
];
```

This inverts `2 x + x^Sqrt[2](1+Log[x]) + x^2(2-Log[x])` on the local
positive branch. Input block polynomials are **not** already divided by the
linear coefficient. The package performs that normalization and substitutes
`t=y/a`, including `Log[y/a]`.

The expression front end simplifies only under `x>0`. It does not use
unrestricted `PowerExpand`. For the original Piecewise expression, normalize
it under that assumption first, or use `{{1,1+L}}` directly.

### Error metadata and explicit pointwise bounds

`r["Remainder"]` contains `"Power"`, `"LogPower"`, and `"Scale"`. These give
an asymptotic big-O scale with an unspecified constant and threshold; they are
not a native `SeriesData` object or a certified numerical tolerance.

```wolfram
b = InverseErrorBound[r1, 1/1000];
b["Condition"]
b["Bound"]
b["SelectedRootInterval"]
```

At the exact positive point supplied, this returns a **rigorous conditional
inequality** from a complex-disk majorant. The condition is `Q<1`; failure of
that sufficient condition does not prove divergence. The root is the unique
positive root in the returned interval, selected by continuation from the
linear equation in an auxiliary parameter. It agrees with the requested
inverse germ near zero. For generic inputs, global continuation beyond that
germ requires a separate branch argument. Both original examples are globally
strictly increasing on the positive axis, so their branch is unambiguous.

Floating-point evaluation of the bound is not outward-rounded interval
arithmetic. Use exact comparisons or validated intervals for a numerical
certificate. The optional disk-radius ratio is `"Radius" -> 1/2`.

## Contract and limitations

Excess exponents and cutoffs must be exact real algebraic numbers. Polynomial
coefficients and the linear coefficient must be exact, provably real numeric
constants; the linear coefficient must be positive. `Sqrt[2]-1` is accepted;
a decimal approximation, `Pi` as an exponent, or an unresolved symbolic
coefficient is not. The mathematical theorem is broader than this deliberately
decidable implementation contract.

All expansions approach zero through positive real values. The package does
not select all complex/global branches, accept arbitrary input remainders,
handle iterated or negative-power logarithms, or implement a universal
transseries engine. Clear symbols used as variables before calling it.

Treat the returned associations as immutable. `InverseResidual` checks the
structured correction blocks, not a separately hand-edited `"Expression"`.
Its `"NormalizedResidual"` represents `(f(g_B(y))-y)/y`; `"Residual"` represents
the unnormalized residual, truncated to the requested absolute power.

Resource guards: `"MaxMultiIndices" -> 100000` for construction and
`"MaxProducts" -> 1000000` for residual composition. These return `Failure`
when exceeded. They do not impose a wall-clock limit on symbolic algebra.

## Validation status — important

**Executed:** 19 grouped independent symbolic checks and 27 numerical cases,
using Python/SymPy/mpmath, plus static delimiter/string/comment checks of the
Wolfram source files. Exact direct composition and a separate fixed-point
calculation check the coefficient formula. See `validation/results.json`.

**Not executed:** the native Wolfram regression suite. The available Wolfram
evaluator failed with an unavailable-server/dependency error, and no local
kernel was present. Independent mathematical validation is not native Wolfram
runtime validation. The code is supplied as an implementation for review and
execution, not as a kernel-certified release.

The 34 native tests can be run with:

```wolfram
TestReport["Tests/RealLogPowerInverse.wlt"]
```

or, with a working command-line kernel:

```sh
wolframscript -file Tests/RunTests.wls
python validation/reference_validation.py
python validation/check_wolfram_source.py
```

The package uses long-established Wolfram Language constructs and declares a
12.0+ target in its metadata, but that version range was not runtime-tested.
The runner checks the current `ReportSucceeded` property, with a fail-closed
fallback for older report-count properties. Python verification requires
`sympy` and `mpmath`; they are not dependencies of the Wolfram package.

## Build the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The bibliography is embedded. Standard TeX packages are used, with no shell
escape, external bibliography program, downloaded fonts, or network access.

## Provenance

The user-supplied question archive was read. The public question is
https://mathematica.stackexchange.com/questions/236367/ .

The supplied ProveIt series-and-transseries materials were consulted through
their orientation/status README files and targeted search excerpts, pinned to
commit `24ce8bd743eaab64a91ce90725ea00f498d319d2`. The oversized consolidated
TeX volume could not be retrieved in full. This delivery is not a full audit
of that volume; the proofs supporting this implementation are self-contained.

The code is newly written. Cited third-party materials are not redistributed
or relicensed. See `LICENSE` and `VALIDATION.md`.
