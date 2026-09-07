# RealInverseAsymptotics 1.0.0

Positive-real asymptotic inverses near zero, with exact irrational powers,
polynomial logarithmic coefficients, and explicit remainder scales.

## Start here

Read `article/real_inverse_asymptotics.pdf` for the complete theory, proofs,
coefficient formulas, worked examples, API contracts, and validation report.
The editable, self-contained LaTeX source is beside it.

In a fresh Wolfram Language kernel, set the directory to the extracted archive
root, or supply its absolute path to `Get`:

```wl
Get["RealInverseAsymptotics.wl"];
Clear[x, y, L];

r1 = RealInverseAsymptotic[
  x + x^2 (1 + Log[x]), {x, 0}, {y, 0, 5}];
r1["Expression"]
r1["RemainderScale"]

r2 = RealInverseAsymptotic[
  x + x^Sqrt[2], {x, 0}, {y, 0, 3 Sqrt[2] - 2}];
r2["Expression"]
r2["FirstOmittedPower"]
```

The last example retains exactly the four terms

    y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2]-1)
      - (6-Sqrt[2])/2 y^(3 Sqrt[2]-2).

The next power is `4 Sqrt[2]-3`. In the logarithmic example, truncation through
`y^5` has the proved remainder `O[y^6 (1+Abs[Log[y]])^5]`.

**The final number is a power cutoff, not a number of terms.** Every exponent
of `y` at or below that cutoff is included, with its complete logarithmic
polynomial. Remainders are returned as metadata, not misleading `SeriesData`.
Use `result["Expression"]`, not `Normal[result]`.

## Mathematical scope

The main engine accepts exact finite models

    f(x) = c x^alpha (1 + Sum[x^delta_j P_j(Log[x])]),

where `c>0`, `alpha>0`, `delta_j>0`, and each `P_j` is a polynomial with real
coefficients. The selected inverse satisfies `x>0` and
`x/(y/c)^(1/alpha) -> 1` as `y -> 0+`. The paper proves local existence,
uniqueness, convergence for sufficiently small positive arguments, and
logarithm-sensitive asymptotic remainder bounds for this class.

The implementation requires exact real **algebraic** exponents and cutoffs
(e.g. `Sqrt[2]`, not `1.41421356`); the mathematical theorem allows arbitrary
fixed positive real exponents. Coefficients must be exact and provably real.
Symbolic coefficients require appropriate `Assumptions`. Clear the input,
output, and logarithm-indeterminate symbols before use.

The direct model interface avoids expression-parser limitations:

```wl
r = InversePowerLogModel[3, 2,
  {{Sqrt[2]-1, 1+L}, {1, 2-L^2}}, L, {y, 0, 3/2}];
```

`PowerLogInverseCoefficient` gives one exact multi-index coefficient.
`InversePowerLogJet` handles an unknown source remainder, but returns
conditional bounds and refuses coefficient orders not determined by the jet.
`LagrangeInverseBlocks` supplies general derivative blocks, with an optional
conditional finite-smoothness theorem; it is not a universal transseries
solver. The article and `Examples/Examples.wl` cover oscillatory logarithmic
coefficients, flat exponentials, resonances, and nonunit leading powers.

If the first omitted block cancels, the reported bound is safe but may not be
optimal. No parameter-uniform claim is made as a positive weight tends to zero.

## Residuals and numerical evaluation

```wl
InverseResidual[r1]
EvaluateInverseAsymptotic[r1, 10^-8, WorkingPrecision -> 60]
```

Use exact or genuinely high-precision evaluation points; the numerical helper
rejects insufficient-precision input instead of padding it. Residuals of
source-jet results are refused because the actual source function is unknown.

`ResidualErrorBound[f,{x,a,b},y,u,m]` records the mean-value estimate
`Abs[f(u)-y]/m` together with its hypotheses. It does not automatically prove
the endpoint bracket, positive derivative lower bound, or C1 regularity.
A floating-point residual is not an interval certificate. The article proves
explicit global derivative bounds for the two functions in the question.

## Validation status — read before relying on the package

**93 independent mathematical, numerical, and source-structure checks passed.**
See `validation/results.json` for every check and the numerical tables.
The independent checks compare the coefficient formula with separately solved
ordinary perturbation-series equations, and use 120-digit numerical bisection.
They do not execute or emulate the Wolfram package.

**The 38 native Wolfram regression tests have NOT been executed here.**
No local Wolfram kernel was available, and the connected Wolfram service
returned HTTP 404. The included native suite is therefore an outstanding
runtime check, not an already passed certification. Structural delimiter
checks are not a substitute for parsing and evaluating the package natively.

Run the native suite from the extracted root in a Wolfram-enabled environment:

```sh
wolframscript -file Tests/RunTests.wl
```

Or evaluate `TestReport["Tests/RealInverseAsymptotics.wlt"]` in a notebook.
`Tests/RunTests.wl` prints the report and kernel version, and exits nonzero if
tests fail. The direct `Get` loader is the recommended loading route; optional
paclet metadata is supplied, with intended Wolfram Language 12.0+ compatibility
that has not been verified across versions.

Run the independent checks separately:

```sh
python -m pip install -r validation/requirements.txt
python validation/validate.py
```

Resource options `"MaxMultiIndices"` and `"MaxGenerators"` prevent unbounded
lattice enumeration. They are not bounds on every possible simplification or
polynomial-expansion cost. A failure returns a `Failure` object, never a
silently incomplete expansion. Malformed calls that do not match a documented
function signature may remain unevaluated, following ordinary WL dispatch.

## Build the article

With a standard LaTeX installation:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error real_inverse_asymptotics.tex
pdflatex -interaction=nonstopmode -halt-on-error real_inverse_asymptotics.tex
```

Rerun if LaTeX requests another cross-reference pass. No external bibliography
processor or figure download is needed. `numerical_table.tex` is an auxiliary
copy of the table data; the article also includes the table directly.

## Archive contents

- `article/`: compiled article, editable LaTeX, and numerical table data.
- `Kernel/` and root loader: Wolfram Language implementation.
- `Examples/` and `Tests/`: usage examples and native regression suite.
- `validation/`: independent Python checks and their recorded results.
- `SOURCES.md`, `LICENSE`, and `SHA256SUMS.txt`: provenance and distribution.

The original question and repository materials are cited, not redistributed.
No changes have been made to the user's repository or persistent file library.
