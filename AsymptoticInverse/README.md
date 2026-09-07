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
- **Remainder.** `PowerLogRemainder[w, beta, k]` means `O[w^beta (1 + Abs[Log[w]])^k]`
  as `w -> 0+`.  For an exact finite input the exponent `beta` is the first
  omitted exponent of the support and `k` is the degree of the complete
  coefficient there (`"FrontierTerm"`); when the coefficient cancels the
  bound remains valid but is not sharp.  When the forward function is expanded
  automatically, the forward remainder is transported to the inverse and the
  cutoff is capped accordingly (`"InputRemainder"`).
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
| `Method` | `"Lagrange"` | `"Lagrange"` (multi-index Euler-operator formula) or `"Newton"` (Newton iteration in the truncated power–log algebra). |
| `"Power"` | `1` | Expand `(x - x0)^r` (or `x^r` at infinity) instead of the inverse itself. |
| `"Truncation"` | `"Exponent"` | `"Depth"` truncates by total perturbation depth and admits symbolic exponents under `Assumptions`. |
| `"InputRemainder"` | `Automatic` | `None` treats the input as exact; `{rho, k}` declares `R(u) = O[u^rho (1 + Abs[Log[u]])^k]` and `R'(u) = O[u^(rho - 1) (1 + Abs[Log[u]])^k]` for an omitted part of the forward function. |
| `SeriesTermGoal` | `Automatic` | Number of nonzero blocks when no cutoff is given. |
| `"MaxTerms"` | `20000` | Resource budget for enumeration and sparse products; exceeding it returns a `Failure`. |

`AsymptoticExpansion` accepts `Assumptions`, `Direction`, `SeriesTermGoal` and
`"MaxTerms"`.

## Supported inputs

The forward engine expands expressions built from constants, the variable,
`Plus`, `Times`, real constant powers, `Log`, `Exp` (of bounded arguments),
and analytic functions of expressions that tend to a constant (`Sin`, `Cos`,
`ArcTan`, `BesselJ`, `Gamma` away from its poles, …); other subexpressions are
handled through `Series` when that succeeds.  The forward expansion must have
a leading block `a u^p` without a logarithm (`x Log[x]` near `0` is rejected;
its inverse lives in the Lambert-W scale and is outside this version).
Exponentially small or large terms (`Exp[-1/x]`), oscillatory coefficients
(`Sin[Log[x]]`) and nested logarithms are rejected with a descriptive
`Failure` rather than silently dropped.

## Files

- `Kernel/AsymptoticInverse.wl` — the package; `Kernel/init.m` — loader.
- `Tests/AsymptoticInverse.wlt`, `Tests/RunTests.wl` — 49 regression tests
  (`wolfram -script AsymptoticInverse/Tests/RunTests.wl`).
- `Examples/Examples.wl` — worked examples.
- `PacletInfo.wl` — paclet metadata (`PacletDirectoryLoad["AsymptoticInverse"]`).
