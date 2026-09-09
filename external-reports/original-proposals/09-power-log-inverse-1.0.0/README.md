# PowerLogInverse 1.0.0

Positive-real inverse expansions at `y -> 0+` for exact finite power-log models

    f(x) = a x^p (1 + Sum[x^delta_j P_j(Log[x])])

with `a > 0`, `p > 0`, `delta_j > 0`, and real polynomial `P_j`. Gaps may be
exact irrational numbers. The package uses an all-orders Euler-operator
coefficient formula, not Taylor differentiation of an undefined inverse at 0.

## Load and use

Unzip the archive. In a Wolfram notebook, load the file by its full path:

```wl
Get[".../power-log-inverse/Kernel/PowerLogInverse.wl"];
Clear[x, y];
PowerLogInverse[x + x^2 (1 + Log[x]), {x, y, 5}]
PowerLogInverse[x + x^Sqrt[2], {x, y, 4 Sqrt[2] - 3}]
```

The cutoff is **strict**: retain every complete logarithmic block whose
exponent of **y** is smaller than the last argument. It is not a term count.
To keep the remainder and branch information:

```wl
d = PowerLogInverseData[x + x^2 (1 + Log[x]), {x, y, 5}];
d["Expression"]
d["Remainder"]
```

For the first example, the remainder has scale `y^5 (1 + Abs[Log[y]])^4`.
It is not in general `O[y]^5` in the strict analytic meaning of Big-O.

For symbolic gaps, total perturbation depth can be more convenient:

```wl
PowerLogInverse[x + x^alpha, {x, y, 5},
  "Truncation" -> "Depth", Assumptions -> alpha > 1]
```

With multiple gaps, depth truncation need not contain every term up to the
largest exponent printed. Its remainder metadata accounts for this.

Explicit normalized models and individual coefficients:

```wl
Clear[ell];
m = PowerLogModel[1, 1, {{1, 1 + ell}}, ell];
PowerLogCoefficient[m, {6}]
PowerLogInverse[m, {y, 8}]
```

Options to the inversion functions are `Assumptions`, `"Truncation"`,
`"InversePower"` (positive, default 1), and `"MaxTerms"` (default 10000).
The latter limits visited multiindices including the boundary; it is not a
bound on symbolic arithmetic cost. A resource failure never returns an
unlabelled partial expansion.

## Contents

- `Article/power-log-inverse.tex` and `.pdf`: self-contained theory, complete
  proofs, explicit examples, convergence and remainder estimates, API manual.
- `Kernel/PowerLogInverse.wl`: package; `Kernel/init.m`: optional loader.
- `Examples/Examples.wl`: runnable examples; `NearIdentityReference.wl`: the
  minimal educational routine from Appendix A.
- `Tests/PowerLogInverse.wlt`, `Tests/RunTests.wl`: 35 native regression cases.
- `Verification/verify.py`: independent mathematical verification program.
- `Verification/verification-results.json`, `verification-report.txt`: actual
  results of 155 successful checks, with 100-digit numerical experiments.
- `Verification/STATUS.md`: exact distinction between executed and unexecuted
  checks. Native Wolfram execution was unavailable, so the package and MUnit
  suite must still be checked in a native kernel.
- `SOURCES.md`: sources consulted and access limitations.

## Scope and safety of interpretation

All results are local to the positive branch with `g(y)/(y/a)^(1/p) -> 1`.
Parameters are fixed, not tending to a singular limit along with y. Supply
consistent assumptions proving that coefficients/exponents are real and that
the leading coefficient, leading power, and gaps are positive.

The parser accepts finite sums of explicit powers of x times polynomials in
`Log[x]`. It deliberately rejects leading logarithmic factors, negative or
fractional powers of `Log[x]`, exponentials involving x, oscillations, and
branch-dependent transformations such as `Log[x^2]`. These need another core
or a separately justified forward truncation. It does not silently apply
`PowerExpand`, rationalize decimal exponents, or numerically order unresolved
symbolic weights. All such cases return descriptive `Failure` objects.

## Reproduction

```sh
python Verification/verify.py
python Verification/static_check.py
wolframscript -file Tests/RunTests.wl
cd Article
pdflatex -interaction=nonstopmode -halt-on-error power-log-inverse.tex
pdflatex -interaction=nonstopmode -halt-on-error power-log-inverse.tex
```

The verification program requires Python 3.10+ with SymPy and mpmath; exact
versions used are in `Verification/requirements.txt`. The lexical audit uses
only the Python standard library. These two commands do not
execute the Wolfram package. The PDF uses standard TeX Live packages and does
not require network access or external bibliography processing.

Software is provided under the MIT license in `LICENSE`; this newly written
article is included under CC BY 4.0 as stated in `ARTICLE-LICENSE.md`.
