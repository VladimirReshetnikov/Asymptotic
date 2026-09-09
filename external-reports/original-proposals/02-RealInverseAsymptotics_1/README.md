# RealInverseAsymptotics 1.0.0

**Positive-real asymptotic inversion of finite power–logarithmic sums.**

This archive contains a 26-page article with self-contained proofs and its
LaTeX source, a Wolfram Language reference package, worked examples, native
MUnit tests, and an independently executed Python validation program.
The two original examples are the inverses at `y -> 0+` of
`x + x^2 (1 + Log[x])` and `x + x^Sqrt[2]`.

## Readiness and validation

The independent Python implementation passed **104 exact symbolic assertions**
and performed **11 high-precision numerical comparisons**. These validate the
mathematical formulas and finite-jet algorithms; they do **not** execute the
Wolfram source or test its public parser. The **95 native MUnit tests have not
been run**: the remote Wolfram evaluator returned HTTP 404 and there was no
local Wolfram kernel. See `validation/REPORT.md` and `validation/results.json`.
The Wolfram package is a reference implementation, not a claim of native-tested
or production-certified software.

## Quick start in Wolfram Language

Extract the ZIP, then set `root` to the extracted project directory:

```wl
root = "path/to/RealInverseAsymptotics";
Get[FileNameJoin[{root, "Kernel", "RealInverseAsymptotics.wl"}]];
Clear[x, y];

r = RealInverseSeries[x + x^2 (1 + Log[x]), {x, 0}, y, 5];
r["Expression"]
r["Remainder"]
r["FrontierExpression"]

r2 = RealInverseSeries[x + x^Sqrt[2], {x, 0}, y, 4 Sqrt[2] - 3];
r2["Expression"]
```

The fourth argument is a **strict target-variable power cutoff**: cutoff `5`
retains all terms `y^r P[Log[y]]` with `r < 5`, not five terms. Entire
logarithmic polynomials at a retained exponent are kept.

For the first call, the mathematical expression is

```
y - (1 + Log[y]) y^2
  + (1 + Log[y]) (3 + 2 Log[y]) y^3
  - (1 + Log[y]) (10 Log[y]^2 + 31 Log[y] + 23) y^4/2
```

with error `O(y^5 (1 + Abs[Log[y]])^4)`. The package may display an algebraically
equivalent expanded or factored expression. `PowerLogRemainder[t,r,d]` is inert
metadata meaning `O(t^r (1 + Abs[Log[t]])^d)`, not a `SeriesData` object and not
an implementation of arithmetic on error terms.

`Get[FileNameJoin[{root,"Examples","Examples.wl"}]]` evaluates more examples.

## Supported model and branch

The explicit API is

```wl
InversePowerLog[a, p, {{delta1, P1[ell]}, ...}, ell, y, cutoff]
```

where amplitudes are supplied as actual polynomial expressions, for example:

```wl
Clear[ell, y];
InversePowerLog[2, 3, {{1/2, 1 + ell}}, ell, y, 5/6]
```

It represents

```
f(x) = a x^p (1 + Sum[x^delta_i P_i(Log[x])])
```

with `a > 0`, `p > 0`, all `delta_i > 0`, and real polynomial amplitudes.
The selected branch has `x > 0` and `x/(y/a)^(1/p) -> 1`. Powers and logarithms
are interpreted on the positive real axis. No equation solver is asked to
choose a branch at the singular endpoint.

The implementation requires **exact real algebraic exponents and cutoffs**.
It never orders exponents using floating-point approximations. Coefficients
must be exact and provably real; symbolic real parameters are supported under
`Assumptions`. Floating-point input is rejected rather than silently rationalized.
The direct expression parser accepts finite sums of monomials times
polynomials in `Log[x]`. Leading logarithms, nested logarithms, negative log
powers, exponential sectors, and nonalgebraic exponents need a different
normalization or implementation and return a structured failure where they
enter the supported signatures. The article discusses these extensions.

A finite input is treated as an **exact function**, not as an unknown function
with an unstated remainder. The article proves how to transfer a separately
supplied forward error through inversion; the current API does not accept
or certify that additional error automatically.

## Main API

- `RealInverseSeries[f, {x,0}, y, cutoff]`: parse and invert an expression.
- `InversePowerLog[a,p,corrections,ell,y,cutoff]`: explicit normalized model.
- `PowerLogNormalForm[f,x]`: inspect the parser's normalized representation.
- `RealInverseResidual[result,bound]`: normalized composition residual jet.
- `PurePowerInverseCoefficient[alpha,n]`: exact coefficient for `x+x^alpha`.

Options on inversion:

```wl
Assumptions -> True
"ObservablePower" -> 1
"Method" -> "Lagrange"          (* alternative: "FixedPoint" *)
"MaxMultiIndices" -> 100000
"MaxTotalDegree" -> 1000
```

`"ObservablePower" -> q` constructs the expansion of `g(y)^q` directly,
including exact real algebraic negative and fractional `q`. The cutoff must
exceed its leading target power `q/p`. `RealInverseResidual` is only for `q=1`.

Important result fields are `"Expression"`, `"Terms"`, `"Remainder"`,
`"RemainderPower"`, `"RemainderLogDegree"`, `"FrontierWeight"`,
`"FrontierPolynomial"`, `"FrontierExpression"`, and `"IsExact"`.
`"Terms"` uses powers of **t = (y/a)^(1/p)**, with amplitudes in the result's
`"LogVariable"`; it is not a list of target-variable powers. The
`"RemainderPower"` field is a target-variable power. Exact monomial results
have no `"FrontierExpression"` field.

The frontier is the first **semigroup exponent bucket** omitted by the cutoff.
Its combined polynomial can vanish by cancellation. The package then gives
a conservative bound; it does not relabel that bucket as the first nonzero
term.

For the logarithmic result `r` above:

```wl
rFixed = RealInverseSeries[x + x^2 (1 + Log[x]), {x,0}, y, 5,
  "Method" -> "FixedPoint"];
FullSimplify[r["Expression"] - rFixed["Expression"], y > 0]
RealInverseResidual[r, 4]["AllZero"]
```

The residual bound is **relative normalized t-power**. It computes the jet of
`f(G)/(a t^p)-1`, not a numerical error certificate. Here the expected outputs
are `0` and `True`; native execution of these calls is not part of the recorded
validation.

## Reproduce the checks

From the extracted project directory, in an environment with the dependencies:

```text
python -m pip install -r validation/requirements.txt
python validation/validate.py
python validation/static-check.py
wolframscript -file Tests/RunTests.wls
```

Alternatively, in a Wolfram notebook:

```wl
TestReport[FileNameJoin[{root,"Tests","RealInverseAsymptotics.wlt"}]]
```

`validate.py` rewrites `validation/results.json`. SymPy 1.14.0 and mpmath 1.3.0
were used for the supplied record. The static scan only checks delimiters,
strings, nested comments, and test identifiers; it is not a Wolfram interpreter.

## Rebuild the article

```text
cd article
pdflatex -interaction=nonstopmode -halt-on-error real-inverse-asymptotics.tex
pdflatex -interaction=nonstopmode -halt-on-error real-inverse-asymptotics.tex
pdflatex -interaction=nonstopmode -halt-on-error real-inverse-asymptotics.tex
```

The bibliography is embedded in the `.tex`; `numeric-table.tex` is a local
included source. Libertinus is used when installed, with a Latin Modern fallback.
No font files or external repository files are needed from this archive.

## Provenance

The motivating question and the relevant sections of the supplied ProveIt
notes are cited in the article. This implementation specializes
Lagrange–Bürmann inversion to a finite positive-real power–logarithmic algebra;
it does not claim a new general Lagrange inversion theorem or a complete
transseries engine. The coefficient formulas, real-branch proof, convergence
proof, remainder frontier, algorithms, and limitations are stated in the article.

## License

Original text, code, and tests in this archive are provided under MIT No
Attribution (`LICENSE`). Referenced third-party material retains its own terms;
this archive does not redistribute the source papers or the uploaded question.
