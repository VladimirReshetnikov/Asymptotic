# AsymptoticInverse

A Wolfram Language package for **power–log asymptotic expansions** of functions
and of their **inverse functions on a real branch**.  Exponents may be any exact
real numbers (rational or irrational), logarithmic coefficients are
polynomials in the logarithm, endpoints may be finite or infinite, and every
result carries an explicit remainder class.

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];   (* or PacletDirectoryLoad *)

AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}]
(* PowerLogSeries[y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2) + O[y^4 (1 + Abs[Log[y]])^3]] *)

AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 4]
(* y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1) - (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2) + O[y^(4 Sqrt[2] - 3)] *)

AsymptoticExpansion[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, SeriesTermGoal -> 7]
(* x^2 + Sqrt[2] x^(3 - Sqrt[2]) + Sqrt[2] x^(2 - Sqrt[2]) + (1 - 1/Sqrt[2]) x^(4 - 2 Sqrt[2]) + ... + O[x^(7 - 5 Sqrt[2])] *)
```

The mathematics is explained in `../article/asymptotic-inverse.tex`.

Leading logarithmic and exponential cores are supported by the Lambert engine:

```wolfram
AsymptoticInverse[x Log[x], {x, 0}, y, SeriesTermGoal -> 3]
(* With eps = -y > 0, T = -Log[eps], L = Log[T]:
   (eps/T) (1 - L/T + (L^2 - L)/T^2) + logarithmic remainder. *)

AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 4]
(* With T = Log[y], L = Log[T]:
   T - L + L/T + L (L - 2)/(2 T^2) + logarithmic remainder. *)
```

These are finite asymptotic expansions of the real `ProductLog[-1, y]` and
`ProductLog[0, y]` reductions, with their logarithmic remainders recorded.

## Functions

| Function | Purpose |
| --- | --- |
| `AsymptoticInverse[f, {x, x0}, {y, cutoff}]` | Expansion of the real branch of the inverse of `f` near `x0` in powers of `y - y0` (or of `1/y`), with logarithms. |
| `AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]` | The same with the first `n` nonzero blocks. |
| `AsymptoticExpansion[f, {x, x0, cutoff}]`, `AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n]` | Forward expansion of `f` at `x0` in the same scale. |
| `PowerLogSeries[assoc]` | Result object; `Normal`, `s["Remainder"]`, `s["Terms"]`, `s["FrontierTerm"]`, `s["SeriesData"]`, `s["Properties"]`, `s[value]`. |
| `PowerLogRemainder[w, beta, k]` | Inert descriptor of `O[w^beta (1 + Abs[Log[w]])^k]`, `w -> 0+`. |
| `InverseResidual[s]`, `InverseResidual[s, h]` | Exact composition of the forward model with the truncated inverse; the normalized residual vanishes below the residual cutoff. |
| `InverseNumericalCheck[s, y1]` | High-precision comparison of the truncated inverse with a root found by `FindRoot`. |
| `PerturbativeInverse[phi, h, {x, y}, n]` | Lagrange–Bürmann formula generator for `F0(x) + h(x) == y` given the core inverse `phi`; `PerturbativeInverse[h, {x, y}, n]` for the identity core. |
| `InverseExpansionCoefficient[s, {k1, k2, ...}]` | The exact coefficient block attached to one multi-index. |
| `PowerLogModel[f, {x, x0}]` | The normalized forward model `y0 + a u^p (1 + Sum[u^delta_i B_i[Log[u]]])`. |

## Conventions

- **Expansion point and direction.** `x0` is an exact real number, `Infinity` or
  `-Infinity`.  For a finite `x0` the default is `Direction -> "FromAbove"`
  (`x > x0`); use `"FromBelow"` for `x < x0`.  The local variable `w` is
  `x - x0`, `x0 - x`, `1/x` or `-1/x`, and every expansion is a sum of blocks
  `w^beta P(Log[w])` with increasing real `beta`.
- **Cutoff.** The cutoff is an **exclusive exponent bound in the local variable
  of the result**: all complete blocks with exponent strictly less than the
  cutoff are retained.  For an inverse the local variable is `y - y0` when the
  limit `y0` of `f` is finite and `1/y` when it is infinite.  A cutoff is not a
  term count; use `SeriesTermGoal -> n` for `n` blocks.
  If the inverse terminates before that count, a bounded symbolic composition
  check can certify the computed candidate against the original function and
  return its exact finite expression with remainder zero. The certificate and
  requested/returned counts are recorded separately from forward-model exactness.
- **Lambert cutoff.** Recognized Lambert cores return
  `s["Scale"] == "Logarithmic"`. Their local variable is
  `s["LogarithmicVariable"] = 1/Abs[Log[Abs[z]]]`, with `z` the Lambert
  argument. The expression factors out `s["Prefactor"]`; the cutoff is an
  exclusive exponent bound in that logarithmic variable **inside the remaining
  unit bracket**. `SeriesTermGoal` counts nonzero blocks in that bracket.
- **Remainder.** `PowerLogRemainder[w, beta, k]` means `O[w^beta (1 + Abs[Log[w]])^k]`
  as `w -> 0+`.  For an exact finite input the exponent `beta` is the first
  omitted exponent of the support and `k` is the degree of the complete
  coefficient there (`"FrontierTerm"`). Cancelled frontier blocks are skipped
  in a bounded search; if that search exhausts its budget, the original valid
  bound is retained. When the forward function is expanded
  automatically, the forward remainder is transported to the inverse and the
  cutoff is capped accordingly (`"InputRemainder"`).
  Logarithmic-scale remainders are the absolute prefactor times
  `PowerLogRemainder[t, beta, k]`; `s["RemainderScaleExpression"]` supplies the
  corresponding numerical scale.
- **Branch.** The inverse is the branch that tends to `x0` from the requested
  side; with `u = (x - x0)` (or `1/x`) it satisfies `u ~ ((y - y0)/a)^(1/p)`
  where `a u^p` is the leading term of `f`.  Exponents are compared exactly
  (`RootReduce` for algebraic numbers, never numerically); floating-point input
  is rejected.
- **`SeriesData`.** When all exponents are rational and the expansion is in
  `y - y0` with `x0 = 0`, `s["SeriesData"]` returns an ordinary `SeriesData`
  object (logarithms appear inside its coefficients) that can be used with the
  built-in series arithmetic.  Note that its `O` term hides the logarithmic
  factor recorded in `s["Remainder"]`.

## Options of `AsymptoticInverse`

| Option | Default | Meaning |
| --- | --- | --- |
| `Assumptions` | `True` | Assumptions on symbolic parameters (reality, positivity of the leading coefficient, ordering of symbolic exponents). |
| `Direction` | `Automatic` | `"FromAbove"` or `"FromBelow"` for finite `x0`. |
| `Method` | `"Lagrange"` | `"Lagrange"` (multi-index formula), `"Newton"` (iteration in the power–log algebra), or `"Lambert"` for recognized logarithmic/exponential cores. Lambert cores are also detected automatically. |
| `"Power"` | `1` | Expand `(x - x0)^r` (or `x^r` at infinity) instead of the inverse itself. |
| `"Truncation"` | `"Exponent"` | `"Depth"` truncates by total perturbation depth and admits symbolic exponents under `Assumptions`. |
| `"InputRemainder"` | `Automatic` | `{rho, k}` declares `R(u) = O[u^rho (1 + Abs[Log[u]])^k]` and `R'(u) = O[u^(rho - 1) (1 + Abs[Log[u]])^k]` for an omitted part of the forward function. `None` declares no additional omitted input; errors generated by automatic expansion remain tracked. Explicit remainders require ordinary exponent truncation. |
| `SeriesTermGoal` | `Automatic` | Number of nonzero blocks when no cutoff is given. |
| `"MaxTerms"` | `20000` | Budget for retained sparse-product pairs and distinct enumerated indices, including boundary indices; exceeding it returns a `Failure`. |

`AsymptoticExpansion` accepts `Assumptions`, `Direction`, `SeriesTermGoal` and
`"MaxTerms"`.

## Supported inputs

The forward engine expands expressions built from constants, the variable,
`Plus`, `Times`, real constant powers, `Log`, `Exp` (of bounded arguments),
and analytic functions of expressions that tend to a constant (`Sin`, `Cos`,
`ArcTan`, `BesselJ`, `Gamma`, …). Laurent and Puiseux expansions of unary
functions also support poles and algebraic branch points, for example
`Cot[x^Sqrt[2]]` and `ArcCos[1 - x^Sqrt[2]]`. Absolute values are resolved using
the eventual sign of their leading block. Other subexpressions are handled
through `Series` when that succeeds. Cancellation automatically increases the
working order until a leading term can be identified.

The ordinary inverse engine uses a monomial leading block `a u^p`.
The Lambert engine supports affine-logarithm powers
`a u^p (b + c Log[u])^q` and arbitrary polynomial leading blocks
`u^p Q[Log[u]]` with nonzero real `p`, at finite endpoints and both source
infinities (using the positive local source coordinate `u`). It also supports cores
`a x^b Exp[c x^p]` at positive infinity, including scaled and powered variants
of the examples above. It selects the real Lambert branch and computes a
finite logarithmic expansion. Higher-power finite power–log corrections to a
logarithmic core, and finite power–log additions to a growing exponential
core, are covered at every fixed logarithmic order. Such results record
`"LeadingCoreOnly" -> True` and the omitted expression in
`"BeyondLogarithmicOrders"`; they do not resolve separate exponential sectors.
For a general leading polynomial, the lower logarithmic coefficients are
included in the logarithmic expansion itself; the package does not claim a
closed-form `ProductLog` inverse. `InverseResidual` composes the returned
truncated bracket, and `InverseNumericalCheck` compares against the original
forward function.

Pure logarithmic leading cores with zero algebraic power, exponential
arguments containing several distinct powers, translated exponential cores
at infinity, and general transseries with independently truncated exponential
sectors or reciprocal-logarithm corrections remain outside this version's
recognizers and coefficient algebras.
Exponentially small or large terms (`Exp[-1/x]`), oscillatory coefficients
(`Sin[Log[x]]`) and nested logarithms are rejected with a descriptive
`Failure` by the ordinary forward engine.

## Files

- `Kernel/AsymptoticInverse.wl`, `Kernel/LambertInverse.wl`,
  `Kernel/ExactTermination.wl` — the package;
  `Kernel/init.m` — loader.
- `Tests/*.wlt`, `Tests/RunTests.wl` — the regression suites
  (`wolfram -script AsymptoticInverse/Tests/RunTests.wl`).
- `Tests/BenchmarkPerformance.wl` — reproducible comparisons with the original
  sparse-product, integer-power, and enumeration algorithms.
- `Examples/Examples.wl` — worked examples.
- `PacletInfo.wl` — paclet metadata (`PacletDirectoryLoad["AsymptoticInverse"]`).
