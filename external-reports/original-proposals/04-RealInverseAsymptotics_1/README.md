# RealInverseAsymptotics 1.0.0

Asymptotic inversion of the **positive real branch at zero**, with exact
irrational exponents and polynomial-logarithmic coefficients. This is a
finite power-logarithmic inversion package, not a universal exp-log solver.

## Quick start

```wl
Get["/path/to/RealInverseAsymptotics/Kernel/RealInverseAsymptotics.wl"];
Clear[x, y];

r = RealInverseAsymptotic[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
r["Expression"]
(* y - y^2 (1+Log[y]) + y^3 (3+5 Log[y]+2 Log[y]^2) *)
r["Remainder"]
(* PowerLogO[y, 4, 3] *)
CheckInverseAsymptotic[r]
(* Expected: an Association with "Passed" -> True. *)

r = RealInverseAsymptotic[x + x^Sqrt[2], {x, 0}, {y, 4 Sqrt[2]-3}];
r["Expression"]
(* y-y^Sqrt[2]+Sqrt[2] y^(2 Sqrt[2]-1)
   -(6-Sqrt[2])/2 y^(3 Sqrt[2]-2) *)
```

The displayed outputs are mathematically checked expected results. They are
not transcripts from a Wolfram kernel; see **Validation status** below.

## Mathematical contract

Input is a finite, exact expression of the form

    f(x) = a x^alpha (1 + Sum[x^delta_j P_j(Log[x]), j])

with `a > 0`, `alpha > 0`, `delta_j > 0` and real polynomial coefficients.
The result selects the branch `g(y)/(y/a)^(1/alpha) -> 1` as `y -> 0+`.
The article proves local existence, uniqueness, a universal Euler-Lagrange
coefficient formula, convergence for this finite class, and the returned
log-aware asymptotic remainder bound.

`cutoff` is an **exclusive exponent bound in y**, not a term count:
all blocks `y^q P(Log[y])` with `q < cutoff` are retained.
The first omitted possible power can be strictly greater than `cutoff`.
`PowerLogO[y,rho,k]` means `O(y^rho (1+Abs[Log[y]])^k)` at `0+`.
It is an inert annotation, not `SeriesData`, and has no arithmetic rules.

`"BoundaryTerm"` contains the complete coefficient at the first possible
omitted exponent. If that coefficient cancels, the returned power remains
conservative; a zero boundary term does **not** mean the inverse is exact.
`"Exact" -> True` is returned only for an untruncated pure leading monomial.

## Public API

- `RealInverseAsymptotic[f, {x,0}, {y,cutoff}, opts]`: inverse and metadata.
- `PowerLogCompose[f, x, g, {y,cutoff}, opts]`: independent truncated composition.
- `CheckInverseAsymptotic[result, opts]`: a separate binomial/logarithm
  composition check of the inverse coefficients.
- `PowerLogO[y,rho,k]`: inert remainder annotation.

The inverse result contains `"Expression"`, sorted `"Terms"`,
`"Remainder"`, `"RemainderPower"`, `"RemainderLogDegree"`,
`"RemainderScale"`, `"BoundaryTerm"`, `"LeadingTerm"`, source data,
branch metadata, assumptions, and a finite perturbation-order bound.
The exact-boundary metadata refers to the supplied finite source expression.

Options are `Assumptions :> $Assumptions`, `"MaxOrder" -> 256`, and
`"MaxTerms" -> 20000`. A temporary product budget is four times `MaxTerms`.
Exceeding a budget returns `Failure`, never a silently incomplete result.
No numerical approximation is used to order or merge exponents.

## Input restrictions and normalization

Use unassigned, distinct source and target symbols. Input must not contain
the target variable. Exponents and cutoffs must be exact, numerically
specified real constants; `Sqrt[2]` is supported, but an unspecialized `p`
is rejected even with `Assumptions -> p > 1`. Exact transcendental constants
are admitted only when their required comparisons can be proved.
Symbolic coefficients are allowed when their reality and the positivity
of the leading coefficient follow from `Assumptions`.

All machine or arbitrary-precision real literals are rejected, including
coefficients and cutoffs. This avoids silently changing an irrational
exponent or using approximate equality to merge terms. Rationalize data
explicitly outside the package when that is mathematically appropriate.

The parser accepts sums `x^q P(Log[x])`, after ordinary `Expand`. Normalize
`Log[2 x]` to `Log[2]+Log[x]` on the positive domain before calling it.
It does not use `PowerExpand`. A leading factor such as `Log[x]`, negative
powers of `Log[x]`, iterated logarithms, oscillatory terms, essential
exponentials, arbitrary implicit equations, and nonzero basepoints are
outside this implementation. Coordinate changes can be performed first.

A finite asymptotic source jet is NOT automatically an exact source
function. The article proves how to transfer a separately known input
remainder into an inverse error budget. Do not request inverse coefficients
beyond that budget or trust the boundary coefficient there.

## Tests and validation status

**The Wolfram Language package was not executed in a proprietary Wolfram
kernel in this session.** The available Wolfram connector returned a tool
availability error, no local Wolfram kernel was installed, and an attempted
Mathics installation was unavailable. Therefore Wolfram runtime compatibility
and the MUnit suite's pass count are not claimed.

The archive includes **35 Wolfram MUnit tests** in
`Tests/RealInverseAsymptotics.wlt`. Run them with:

```text
wolframscript -file Tests/RunTests.wls
```

or inside Mathematica:

```wl
TestReport["/path/to/RealInverseAsymptotics/Tests/RealInverseAsymptotics.wlt"]
```

Independent execution of `validation/validate.py` completed **58 checks**
with SymPy 1.14.0 and mpmath 1.3.0. These include closed-form coefficients,
independent binomial/logarithm composition, a triangular coefficient solve,
nine broader classes of source germs, cancellations, and 100-digit numerical
inversion. The complete results and numerical data are included. This is
validation of the mathematics and an independently coded algorithm, not a
substitute for executing the WL package. Numerical values are not interval
certificates. A separate static delimiter check is also included.

```text
python -m pip install -r validation/requirements.txt
python validation/validate.py
python validation/check_wl_delimiters.py
```

The package uses standard Wolfram Language constructs available in modern
versions; it has no external Wolfram dependencies. The MUnit tests are the
intended first runtime compatibility check.

## Files and rebuilding the article

- `article/real_inverse_asymptotics.tex` and `.pdf`: self-contained article.
- `Kernel/RealInverseAsymptotics.wl`: implementation; `init.m`: loader.
- `Examples/Examples.wl`: runnable examples and the compact unit formula.
- `Tests/`: Wolfram regression suite and command-line runner.
- `validation/`: independently executed validation, reports, and raw data.
- `LICENSE`: MIT No Attribution.

The TeX source is self-contained apart from ordinary LaTeX packages.
From `article/`, run `latexmk -pdf real_inverse_asymptotics.tex`.
