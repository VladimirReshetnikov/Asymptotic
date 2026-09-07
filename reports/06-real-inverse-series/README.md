# RealInverseSeries 1.0.0

Positive-real inverse asymptotics at zero, including logarithmic and irrational-power corrections. Prepared for Vladimir Reshetnikov's Mathematica Stack Exchange question 236367, September 7, 2026.

## Validation status

The article proves the coefficient formula, positive-branch selection, convergence for finite exact models, weighted remainder estimates, and forward-remainder transport. **79 independent exact-symbolic and 250-digit numerical checks passed in Python.** Their complete results are in `verification/verification-report.json`.

**The Wolfram package has not been executed in a native Wolfram kernel in this environment.** The connected evaluator returned HTTP 404 on both attempted calls, and no local kernel was available. The included **33 native regression tests are unexecuted**, not a claimed native test pass. Source structure was checked for balanced delimiters, strings, and nested comments; that is not a Wolfram parser or semantic test. Native execution is the next validation step before production use.

## Contents

- `article/real-inverse-series.pdf` and `.tex`: detailed article with complete proofs, examples, remainder contracts, verification record, references, and the full package listing.
- `Kernel/RealInverseSeries.wl`: package with Lagrange and Newton engines.
- `Examples/examples.wl`: executable examples.
- `Tests/RealInverseSeries.wlt`, `Tests/run-tests.wl`: native tests and runner.
- `verification/`: separate Python implementation, executed checks, results, and structural source checker.
- `build.sh`: rebuilds the article with three pdflatex passes.

Preserve this folder layout when rebuilding the article: its source includes the package listing and numerical table by relative paths.

## Quick start

In a Wolfram Language session, with an actual path to the extracted folder:

```wolfram
Get["/path/to/real-inverse-series/Kernel/RealInverseSeries.wl"];
Clear[x, y, z];

r1 = RealInverseSeries[x + x^2 (1 + Log[x]), {x, y}, 5];
r1["Expansion"]
r1["Remainder"]

r2 = RealInverseSeries[x + x^Sqrt[2], {x, z}, 4 Sqrt[2] - 3];
r2["Expansion"]
```

The first expansion is

```
y - y^2 (1 + Log[y])
  + y^3 (2 Log[y]^2 + 5 Log[y] + 3)
  - y^4 (5 Log[y]^3 + 41 Log[y]^2/2 + 27 Log[y] + 23/2)
```

with error `O(y^5 (1 + Abs[Log[y]])^4)` as `y -> 0+`.

The second is

```
z - z^Sqrt[2] + Sqrt[2] z^(2 Sqrt[2] - 1)
  - (6 - Sqrt[2])/2 z^(3 Sqrt[2] - 2)
```

with error `O(z^(4 Sqrt[2] - 3))`.

The third argument is a **strict power cutoff**, not a number of terms. All complete logarithmic blocks with output power less than the cutoff are retained. The first possible omitted power may exceed the requested cutoff when the support has a gap.

## Supported class

The input must be an exact finite expression

```
c x^p (1 + Sum[x^delta[j] P[j][Log[x]], {j, r}])
```

where `c > 0`, `p > 0`, each `delta[j] > 0`, and the `P[j]` are real polynomials in the logarithm. The parser accepts the equivalent expanded finite sum of power-log terms and detects its core. Exponents and cutoff must be **exact, finite, numeric real constants**. Exact algebraic exponents are the primary intended case; other constants are accepted only when all needed comparisons are certified exactly. No floating-point ordering fallback is used.

Symbolic coefficients are permitted when `Assumptions` proves their reality (and positivity of the core coefficient). Input and output symbols must be unassigned and distinct, and the forward expression must not depend on the output symbol.

The result is an `Association`, not `SeriesData`. `"Expansion"` is the ordinary expression. `"Remainder"` separately records a power, logarithmic degree, and nonnegative scale. `"Blocks"` stores pairs `{lambda, polynomial}` in the basis `(y/c)^lambda`, with the private log variable and its substitution exposed separately.

## Options and auxiliary functions

```wolfram
Options[RealInverseSeries]
(* Assumptions -> True, Method -> "Lagrange",
   "InputRemainder" -> None, "MaxIndices" -> 10000,
   "VerifyResidual" -> True *)

rNewton = RealInverseSeries[x + x^2 (1 + Log[x]), {x, y}, 5,
  Method -> "Newton"];

InverseResidual[r1]       (* zero below the appropriate forward cutoff *)
InverseResidual[r1, 6]    (* inspect the first omitted residual terms *)

PerturbativeInverse[y, x^2 (1 + Log[x]), {x, y, eps}, 2]
```

`PerturbativeInverse[phi,h,{x,y,eps},n]` implements the degree-n auxiliary-parameter Lagrange formula for `F0(x) + eps h(x) = y`, given a specified local inverse `phi(y)` of `F0`. It does not prove that an arbitrary supplied `phi` is the desired branch. Substitution `eps -> 1` needs its own convergence or remainder argument outside the principal supported class.

`"FormalResidualZero" -> True` means exact cancellation in the finite jet algebra of the supplied model. It is not a numerical interval certificate. Every result explicitly records `"NumericalIntervalCertificate" -> False`.

## Forward expansions with unknown remainders

```wolfram
RealInverseSeries[x + x^2 Log[x] - x^3/6, {x, y}, 5,
  "InputRemainder" -> {5, 0}]
```

This can model `Sin[x] + x^2 Log[x]`, because its omitted forward term is `O(x^5)` and its derivative is `O(x^4)`.

The option `"InputRemainder" -> {beta,k}` is the user's assertion of **both** bounds

```
r(x)  = O(x^beta     (1 + |log x|)^k),
r'(x) = O(x^(beta-1) (1 + |log x|)^k),    beta > p.
```

The package does not prove these bounds. It rejects inverse cutoffs above `(beta - p + 1)/p` and combines the input-induced inverse error with the finite model's truncation error. A forward value estimate alone need not ensure invertibility.

## Unsupported inputs and limitations

The package returns `Failure` for inexact input, undecidable exponent ordering, symbolic exponents, nonpositive cores, logarithmic leading cores, negative or nested logarithmic powers, unnormalized analytic functions, flat exponential terms, and resource-limit violations. It does not silently drop unsupported terms.

Examples intentionally rejected:

```wolfram
RealInverseSeries[x + x^1.5, {x, y}, 3]
RealInverseSeries[-x Log[x], {x, y}, 3]
RealInverseSeries[x + Exp[-1/x], {x, y}, 3]
```

This is not a general-purpose transseries system or a global inverse-function solver. Claims are for a fixed model on a sufficiently small positive interval. No uniformity is asserted when exponent gaps tend to zero or symbolic coefficients vary without bounds. Result associations do not have overloaded arithmetic; using only their `"Expansion"` fields discards the remainder information.

The implementation favors transparent sparse lists and exact simplification over large-order performance. `"MaxIndices"` limits the finite multi-index enumeration, not every possible intermediate expression-size cost.

## Run the native tests

From the extracted project root:

```text
wolframscript -file Tests/run-tests.wl
```

Or load the package and evaluate `TestReport` on the `.wlt` path. The runner writes `verification/native-test-report.txt` **only when actually run** and includes the actual kernel version. No such report is shipped in this archive.

## Reproduce the independent checks

```text
python -m pip install -r verification/requirements.txt
python verification/verify.py
python verification/static-wl-check.py
```

The recorded environment was Python 3.13.5, SymPy 1.14.0, mpmath 1.3.0. The main verification regenerates its JSON report and `article/numerical-table.tex`. Its numerical computations use 250-digit ordinary multiprecision arithmetic, not interval arithmetic. They are not an execution of the Wolfram package.

## Rebuild the article

On a system with pdflatex and the TeX packages listed in the preamble:

```text
sh build.sh
```

On Windows, run the three pdflatex commands in article section 15.3 from the `article` directory. The PDF contains the same source file distributed under `Kernel`, included via `lstinputlisting`.

## Sources and provenance

The article cites the user's question, the relevant companion inversion chapters and README in the supplied ProveIt repository, classical Lagrange inversion sources, DLMF, and current official Wolfram documentation. It distinguishes the material actually consulted from the repository's larger corpus. No Lean formalization or external peer review is claimed. See the article bibliography and `SOURCE-NOTES.md` for source identifiers.

The MIT license applies to the original material in this distribution. External works are cited, not relicensed or redistributed.
