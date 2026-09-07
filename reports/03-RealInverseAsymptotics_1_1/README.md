# RealInverseAsymptotics 1.0.0

Positive-real asymptotic inversion at zero, prepared for Vladimir Reshetnikov,
7 September 2026. The article develops the theory; the Wolfram Language source
implements a finite exact power–logarithmic model class.

## Start here

Read `Article/real_inverse_asymptotics.pdf`. Its editable source is
`Article/real_inverse_asymptotics.tex`; the numerical table is a separate included
TeX fragment. The article is self-contained and does not require the linked
ProveIt repository to understand its proofs.

The two motivating functions are

- `x + x^2 (1 + Log[x])`;
- `x + x^Sqrt[2]`.

The package selects the positive branch tending to zero, rather than attempting
to repair the branch of a symbolic complex `InverseFunction` result.

## Verification status — read before use

**Executed:** `Verification/verify.py` completed 66 independent mathematical and
static checks, including exact coefficient recurrences, direct differentiation,
sparse composition, resonance and remainder checks, and numerical comparisons at
180 decimal digits. Actual results, software versions, and per-check names are in
`Verification/results.json` and `Verification/results.txt`.

**Not executed:** the Wolfram Language package and the 34 tests in
`Tests/RealInverseAsymptotics.wlt` have not been run in a native Wolfram kernel.
The available Wolfram service returned HTTP 404, and the preparation environment
had no local Wolfram kernel. Static delimiter checks and an independent Python
implementation do not establish the Wolfram program's runtime correctness.
The native tests and runner are supplied to make that distinction auditable.
No native test report has been fabricated or pre-populated.

The compatibility target is Wolfram Language 12.0 or later. This is not a claim
of executed cross-version testing. A suitable local kernel needs no network
service or third-party Wolfram add-on to load this source.

## Load and use

Run these commands with the extracted `RealInverseAsymptotics` directory as your
working directory, or replace the relative path with its full path:

```wolfram
Get["Kernel/RealInverseAsymptotics.wl"];
Clear[x, y, z];

r = RealInverseExpansion[x + x^2 (1 + Log[x]), {x, y}, 6];
r["Expression"]
r["RemainderScale"]
InverseResidual[r]["VanishingBelowCutoff"]

s = RealInverseExpansion[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3];
s["Expression"]
s["RemainderScale"]
```

The final argument is an **exclusive output-power cutoff**, not a correction
count. All blocks of exponent strictly less than that value are retained.
For example, the second call specifies the four terms requested in the question:

```text
z - z^sqrt(2) + sqrt(2) z^(2 sqrt(2)-1)
  - (6-sqrt(2))/2 z^(3 sqrt(2)-2)
```

Its remainder is O(z^(4 sqrt(2)-3)). In the logarithmic example, retaining only
`y - y^2 (1+Log[y])` has remainder O(y^3 (1+|Log[y]|)^2), **not** O(y^3).

A nonunit leading power is normalized automatically:

```wolfram
p = RealInverseExpansion[x^2 + x^3, {x, y}, 3];
p["Expression"]
(* y^(1/2) - y/2 + 5 y^(3/2)/8 - y^2 + 231 y^(5/2)/128 *)
InverseResidual[p]["Cutoff"]
(* 7/2: the residual cutoff must be transported through the leading power *)
```

The comments above specify mathematically derived expected results, not recorded
native-kernel outputs. More examples are in `Examples/examples.wl`.

## Supported exact model

The front end accepts finite sums of the form

```text
f(x) = a x^p + sum_j x^(p+eta_j) P_j(Log[x]),
a > 0, p > 0, eta_j > 0, with polynomial P_j.
```

Exponents and the cutoff must be exact real numerical constants whose ordering
Wolfram Language can establish. Rational, radical, and mixed irrational supports
are allowed. Symbolic coefficients are allowed when their reality, and the
positivity of the leading coefficient, follow from `Assumptions`. For example:

```wolfram
Clear[x, y, a, c];
r = RealInverseExpansion[a x + c x^2, {x, y}, 5,
  Assumptions -> a > 0 && Element[c, Reals]];
N[r["Expression"] /. {a -> 3, c -> -2, y -> 10^-8}, 80]
```

All inputs are treated as **exact functions**, not unknown-remainder asymptotic
jets. The article proves separately how a controlled forward remainder affects
the inverse. Do not silently discard the error in an input series and attribute
the model's entire inverse expansion to the original function.

Approximate real numbers are rejected: construct exact expressions first and
substitute numerical values afterward. Only literal `Log[x]` and polynomial
powers of that logarithm are recognized. Leading logarithms, inverse logarithms,
unexpanded `Sin[x]`, nested logarithms, and unrestricted symbolic exponents are
not automatic front-end inputs. The parser never calls `PowerExpand` and does not
use decimal approximations to decide exact exponent order.

The real-domain and branch contract is `y > 0` with parameter assumptions true,
and `x/(y/a)^(1/p) -> 1` as `y -> 0+`. The returned expression is not wrapped in
`ConditionalExpression`; do not use it as a branch-independent complex formula.

## Main result and checking API

`RealInverseExpansion` returns an association with:

- `"Expression"`, the finite approximation;
- `"Blocks"`, exact pairs `{exponent, polynomialInLogCoordinate}` in `t=y/a`;
- `"RemainderScale"`, `"RemainderExponent"`, and `"RemainderLogDegree"`;
- `"Cutoff"`, `"LeadingInversePower"`, `"ScaledVariable"`, `"Model"`,
  `"Assumptions"`, `"Branch"`, `"Exact"`, and enumeration counts.

`LogCoordinate` is a protected indeterminate representing `Log[y/a]`. Equal
exponents are merged, including resonances from different multi-indices.
The remainder scale is a proved asymptotic big-O scale for the exact model;
no numerical constant or explicit universal convergence threshold is asserted.
A pure monomial has an exact result and a zero remainder scale.

```wolfram
InverseResidual[r]
InverseResidual[r, explicitResidualCutoff]
InverseResidual[r, Automatic, "MaxCompositionOrder" -> 128]
```

The residual routine independently composes `r["Blocks"]` with the stored forward
model. It checks the normalized residual `f(X)/a-t`, with default residual cutoff
`r["Cutoff"] + 1 - r["LeadingInversePower"]`. A zero returned residual means that
all coefficients **below that cutoff** vanish, not that the finite approximation
is an exact inverse. Editing only `r["Expression"]` does not alter the blocks being
checked. The deliberate-corruption native test illustrates this distinction.

A broader derivative-form helper is also provided:

```wolfram
LagrangeInverseTruncation[h, {x, t}, n]
LagrangeInverseTruncation[h, {x, t}, n, "OutputPower" -> q]
```

Here `h` is the correction in `x+h(x)`, not the whole forward function. The helper
returns the Lagrange derivative formula through perturbation degree `n`, optionally
for the qth power of the inverse. It can accept symbolic exponents and broader
expressions, but does **not** certify analytic hypotheses or a remainder.

## Resource limits and errors

Defaults for `RealInverseExpansion` are `"MaxMultiIndices" -> 100000` and
`"MaxTotalOrder" -> 64`. The residual composition limit is 128. Resource caps may
be raised explicitly. Unsupported input, unproved signs or ordering, and exceeded
limits return a `Failure` instead of a guessed support or silent truncation.

The implementation prioritizes transparency over high-order performance.
List-based resonance grouping can require quadratically many exact comparisons;
large coefficient degrees and many generators can be expensive. The mathematical
finite-cutoff algorithm is general within its class, but this source is not a
full optimized logarithmic-exponential transseries engine.

## Reproduce the checks

From the extracted root directory:

```sh
python Verification/verify.py
wolframscript -file Tests/run.wls
```

The Python script uses SymPy and mpmath. The recorded versions are Python 3.13.5,
SymPy 1.14.0, and mpmath 1.3.0; its implementation targets Python 3.10 or later.
It rewrites the independent result files after a successful run. It does not
execute Wolfram Language.

The native runner prints `$Version`, the test report, and pass/fail counts. It
writes `Tests/wolfram-test-report.txt` only when actually run. That file is absent
from this archive by design. Inspect the report in addition to the exit code.

## Rebuild the article

```sh
cd Article
sh build.sh
```

Equivalently, run `pdflatex -interaction=nonstopmode -halt-on-error
real_inverse_asymptotics.tex` three times. A TeX Live installation with the
packages in the source preamble is required, including newtx, amsmath, amsthm,
mathtools, listings, and hyperref. No font files or external source papers are
redistributed.

`MANIFEST.sha256` records all delivered files other than the manifest itself.
Rerunning scripts or rebuilding the PDF can change their hashes.
