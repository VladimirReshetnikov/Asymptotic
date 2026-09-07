# RealInverseAsymptotics 1.0.0

Real-branch asymptotic reversion at zero, with exact irrational powers and polynomial logarithmic coefficients. Prepared for Vladimir Reshetnikov, 7 September 2026.

## Start here

Read `article/real_inverse_asymptotics.pdf`. Its complete LaTeX source and table inputs are in the same directory. The report supplies proofs, all-order formulas, branch selection, convergence, error bounds, implementation details, and the precise limits of the implementation.

**Verification status:** the mathematical algorithms were independently checked using SymPy and mpmath. The Wolfram Language source was reviewed and checked for balanced lexical structure, but it was **not executed in a Wolfram kernel**: the connected evaluator returned HTTP 404, and no local kernel was available. The 36 native MUnit tests are supplied, not reported as passed. Read `verification/STATUS.md` before relying on the implementation.

## Load and use

From the extracted bundle directory, or after replacing the path with an absolute path:

```wolfram
Get["Kernel/RealInverseAsymptotics.wl"];
ClearAll[x, y];

r = RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}];
Normal[r]
r["Remainder"]
InverseResidual[r]["ZeroBelowCutoff"]
```

The intended expression is

```wolfram
y - y^2 (1 + Log[y])
  + y^3 (2 Log[y]^2 + 5 Log[y] + 3)
  - y^4 (5 Log[y]^3 + 41 Log[y]^2/2 + 27 Log[y] + 23/2)
  + y^5 (14 Log[y]^4 + 241 Log[y]^3/3 + 335 Log[y]^2/2
          + 151 Log[y] + 299/6)
```

The remainder descriptor is `PowerLogRemainder[y,6,5]`, meaning
`O[y^6 (1+Abs[Log[y]])^5]` as `y -> 0+`. It is an inert descriptor, not `SeriesData`, and has no automatic order arithmetic. `Normal[r]` discards the metadata.

The irrational example uses an exclusive cutoff:

```wolfram
r = RealInverseAsymptotic[x + x^Sqrt[2], {x, 0},
      {y, 4 Sqrt[2] - 3}];
Normal[r]
r["Remainder"]
```

Its expected result is

```wolfram
y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1)
  - (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2)
```

with remainder `PowerLogRemainder[y,4 Sqrt[2]-3,0]`.
These are derived expected outputs, not a transcript of a native-kernel run.

## Supported class

The main function takes an exact finite expression

```
f(x) = a x^p (1 + Sum[x^delta_i B_i(Log[x]), i])
```

where `a>0`, `p>0`, each `delta_i>0`, and each `B_i` is a polynomial. The smallest nonzero logarithmic block must be a constant times `x^p`. The parser accepts expanded sums such as `3 x^2 + 3 x^3 (1+Log[x])` and automatically extracts the leading monomial.

The theory covers fixed positive real exponents. The implementation deliberately restricts all exponents and the cutoff to **exact real algebraic constants**, so comparison and collision detection never depend on numerical approximations. Coefficients must be exact and real; fixed symbolic coefficients are allowed when `Assumptions` proves their reality and the leading coefficient's positivity. Source and target symbols must be distinct and unassigned, and the forward expression must not contain the target. Assumptions concern fixed parameters only, not the asymptotic variables.

The branch is always `x>0, y->0+, x/(y/a)^(1/p)->1`.
The cutoff `q` is **exclusive**: retain complete logarithmic blocks of target power strictly less than `q`. It must exceed the leading inverse power `1/p`.

The implementation does not directly accept symbolic or transcendental exponents, inexact data, unexpanded analytic factors, a leading logarithm, negative logarithmic powers, iterated logarithms, exponential sectors, or complex branches. It is not a universal transseries system. The article explains how different dominant coordinates would extend the theory.

## Public interface

- `RealInverseAsymptotic[f,{x,0},{y,q},opts]`: construct an `InverseExpansion` object.
- `Normal[r]`: finite expression; `r["Remainder"]`, `r["Branch"]`, and other fields retain interpretation and precision.
- `InverseResidual[r]`: independently compose the finite forward model with the truncated inverse. Its normalized residual is `f(G(y))/y - 1`.
- `InverseResidual[r,h]`: do the same at a positive relative cutoff `h` in `z=(y/a)^(1/p)`. The unnormalized forward-residual cutoff is `1+h/p`. A larger cutoff can reveal the first omitted residual.
- `PerturbativeInverse[h,{x},{y,n},eps]`: the polynomial through marker degree `n` solving `u+eps h(u)=y` at `eps=0`. Marker order alone is not an asymptotic order in `y`.

`r["Terms"]` contains pairs `{beta,C}` representing `(y/a)^beta C`, **not** `y^beta C`; its coefficients already contain the substitution `Log[y/a]/p`. Additional fields include `LeadingCoefficient`, `LeadingPower`, `RelativeCutoff`, `RemainderPower`, `RemainderLogDegree`, `InputInterpretation`, `MultiIndexCount`, and `BoundaryCount`.

Options:

```wolfram
Assumptions -> True
InputRemainder -> None
MaxMultiIndices -> 20000
```

The resource limit bounds traversal, boundary candidates, and sparse products; it is not a global time limit. Resource exhaustion returns `Failure`, not a misleading partial expansion. Other unsupported inputs also return `Failure`.

## Forward series and precision

`InputRemainder -> None` treats the supplied finite expression as the exact function. To represent a forward jet, use `InputRemainder -> {rho,k}`. This records caller-supplied hypotheses

```
R(x)  = O[x^rho     (1+Abs[Log[x]])^k]
R'(x) = O[x^(rho-1) (1+Abs[Log[x]])^k].
```

The bounds are not proved automatically. `rho` must exceed all supplied forward powers, and `k` must be a nonnegative integer. The inverse uncertainty has power `(rho-p+1)/p`. Requests exceeding this precision are rejected.

For example:

```wolfram
jet = Normal[Series[Exp[x] - 1, {x, 0, 4}]] + x^Sqrt[2];
r = RealInverseAsymptotic[jet, {x, 0}, {y, 5},
      InputRemainder -> {5, 0}];
```

Taylor's theorem supplies both required remainder bounds in this example.

## Tests and reproduction

Run the independent mathematical checks with Python 3.10 or later:

```sh
python -m pip install -r verification/requirements.txt
python verification/verify.py
```

The recorded run used Python 3.13.5, SymPy 1.14.0, and mpmath 1.3.0, with 150 decimal digits. It reports 18 checks and 24 numerical rows. It also checks lexical delimiters in all shipped Wolfram source, test, loader, and runner files. It is **not a Wolfram Language interpreter**.

Run the supplied native suite in your Wolfram installation:

```sh
wolframscript -file Tests/run-tests.wls
```

Or use `TestReport["Tests/RealInverseAsymptotics.wlt"]` in a notebook after setting the working directory. The examples are in `Examples/examples.wl`. No particular Mathematica version is certified by this release.

Rebuild the PDF with pdfLaTeX (the bibliography is embedded):

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error real_inverse_asymptotics.tex
pdflatex -interaction=nonstopmode -halt-on-error real_inverse_asymptotics.tex
pdflatex -interaction=nonstopmode -halt-on-error real_inverse_asymptotics.tex
```

All manuscript inputs are shipped, with no dependency on the GitHub checkout or a private style file. `verification/generate_tables.py` regenerates the two numerical table inputs from the JSON record. `SHA256SUMS.txt` records release file checksums.

## Mathematical contribution

The report gives a finite differential-operator formula indexed by a locally finite positive exponent semigroup, a proof of actual convergence for each exact finite model near the positive endpoint, a finite-boundary logarithmic remainder law, and a precision transport theorem. It combines coincident exponent blocks exactly and handles nonunit leading powers.

A key correction for the first example: after `y-y^2(1+Log[y])`, the error is **not** `O[y^3]`. Its leading term is `y^3(2 Log[y]^2+5 Log[y]+3)`, so a valid bound is `O[y^3(1+Abs[Log[y]])^2]`.

Classical Lagrange inversion is not claimed as a new theorem. The specialized construction and implementation are tied to the user's question and the cited ProveIt companion material. The report states which repository sections were inspected and does not claim to have read the inaccessible multi-megabyte canonical volume in full.

## License

Original package code and accompanying original report/verification materials are supplied under the MIT license in `LICENSE`. References remain the property of their respective authors. No third-party source articles or font files are included. This bundle does not modify the user's repository or library.
