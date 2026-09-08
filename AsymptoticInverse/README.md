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

Version 1.4.0 is tested on Wolfram 15.0.1 for Windows and declares a minimum
kernel version of 15.0. The former untested `13.0+` claim has been removed.
An installed 14.3 engine could not start because it lacks a valid license;
that installation provides no compatibility evidence.

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

Exact logarithmic target transformations also cover general exponential phases:

```wolfram
AsymptoticInverse[x Exp[x^2 + x], {x, Infinity}, y, SeriesTermGoal -> 3]
(* With L = Log[y]: Sqrt[L] - 1/2 + (1/8 - Log[L]/4)/Sqrt[L] + O[1/L]. *)

AsymptoticInverse[Exp[-1/x], {x, 0}, y, SeriesTermGoal -> 3]
(* -1/Log[y], exactly, on 0 < y < 1. *)
```

Signed amplitudes, target offsets, translated source expressions and both source
infinities preserve their real branches. `x^x` is transformed to `x Log[x]`
and then uses the Lambert engine. Transformed results have `"Scale" ->
"Transformed"`: `"CoordinateSeries"` records the inner inverse and its cutoff
convention, and `"CoordinateSubstitution"` maps its target to the actual target.
`InverseResidual` checks the transformed forward model and labels this scope;
numerical checks solve the logarithmic equation to avoid unnecessarily large
forward values. `"ReferenceRoot"` is the numerical root; `"ExactInverse"`
remains a compatibility alias, without implying exact arithmetic or certification.

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
| `Method` | `"Lagrange"` | `"Lagrange"` (multi-index formula), `"Newton"` (iteration with increasing exact precision), `"GroupedLagrange"` (combine equal-weight contributions before differentiation, ordinary engine), or `"Lambert"` for recognized logarithmic/exponential cores. Lambert cores are also detected automatically. |
| `"Power"` | `1` | Expand `(x - x0)^r` (or `x^r` at infinity) instead of the inverse itself. |
| `"Truncation"` | `"Exponent"` | `"Depth"` truncates by total perturbation depth and admits symbolic exponents under `Assumptions`. |
| `"InputRemainder"` | `Automatic` | `{rho, k}` declares `R(u) = O[u^rho (1 + Abs[Log[u]])^k]` and `R'(u) = O[u^(rho - 1) (1 + Abs[Log[u]])^k]` for an omitted part of the forward function. `None` declares no additional omitted input; errors generated by automatic expansion remain tracked. Explicit remainders require ordinary exponent truncation. |
| `SeriesTermGoal` | `Automatic` | Number of nonzero blocks when no cutoff is given. |
| `"MaxTerms"` | `20000` | Budget for retained sparse-product pairs and distinct enumerated indices, including boundary indices; exceeding it returns a `Failure`. |

`AsymptoticExpansion` accepts `Assumptions`, `Direction`, `SeriesTermGoal` and
`"MaxTerms"`.

## Operations on expansion objects

Use explicit operations to keep the remainder attached to the calculation:

```wolfram
s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
SeriesLog[s, 4]                  (* Log[x] + x - x^2/2 + x^3/3 + O[x^4] *)
SeriesPower[s, -1, 3]            (* reciprocal, with transported precision *)
SeriesMultiply[s, s]
SeriesObservable[s, Sin[z], z, "Cutoff" -> 4]
SeriesRefine[AsymptoticInverse[x + x^2, {x, 0}, {y, 2}], 5]
```

`SeriesAdd`, `SeriesMultiply`, `SeriesPower`, `SeriesLog`, `SeriesExp`,
`SeriesCompose`, `SeriesObservable`, `SeriesTruncate`, `SeriesRefine`, and
`SeriesDifferentiate` share an explicit positive coordinate, exact offset and
prefactor, and a precision-tracked jet. Arithmetic requires compatible
coordinates. Exponentiation requires an absolute argument remainder tending
to zero and retains unbounded exponential prefactors exactly. Differentiating
a magnitude Big-O bound requires a matching derivative bound; provide
`"RemainderDerivativeOrder" -> n` only when that hypothesis is established.
Compatible ordinary inverse refinements retain coefficient blocks, polynomial
powers or Newton states. Other refinements replay the retained source or
operation recipe and report that strategy explicitly. Both routes preserve
declared input precision ceilings.
`"DeclaredInputRemainder"` distinguishes a user-declared error from the
automatically generated forward remainder, so analytic sources can be
expanded further during refinement.

## Retaining an exact inverse core

```wolfram
s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 2}];
s["CoreInverse"]               (* retained lower Lambert branch *)
s["MarkerTerms"]               (* complete perturbation coefficients *)
s["Remainder"]
```

`AsymptoticCoreInverse[core, perturbation, {x,x0}, {y,n}]` retains the exact
core inverse and computes through perturbation marker degree `n`. Automatic
cores include monomials and affine-logarithm powers; `"CoreInverse" -> phi`
supplies another exact inverse whose branch identity must be verified.
The admitted core is a finite power-log expression with nonzero leading
source power, and every perturbation has a strictly higher source power.
The article proves an asymptotic bound for the complete marker tail. Its
constants are existential, separately identified from the first omitted term.
An optional `"InputRemainder" -> {rho,k}` is transported with its declared
derivative contract. Equal-power logarithmically small corrections and
general exponential exact cores still need separate contracts.

## Rigorous numerical root enclosures

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
c = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5},
  "TargetError" -> 1/10^12];
c["RootEnclosure"]             (* exact rational endpoints *)
c["CertifiedErrorBound"]       (* error of c["Center"] *)
```

`InverseCertificate` proves continuity, a derivative interval separated from
zero, and containment of a residual-based root bracket. Its arithmetic uses
exact rational endpoints, outward dyadic rounding, and proved exponential
and logarithm series tails. `WorkingPrecision` only selects the initial
rational center; a successful `FindRoot` is not used as proof. Adaptive
`"TargetError"` requests an absolute error for the returned center, which may
change during refinement. An explicit rational `"Center"` remains fixed and
can produce a proved `Failure["AccuracyFloor", ...]`.

The certificate encloses a unique root in the supplied interval on the
selected source side. It does not establish a global inverse branch. Its
scope is the stored explicit forward expression; an unspecified input
remainder is not certified by evaluating that expression. Unsupported
elementary operations, a pole, an unproved sign or an exhausted refinement
budget return a descriptive failure with the best available evidence.

`"RelativeError" -> tau` requests a relative error using a proved lower
bound for the root magnitude. When combined with `"TargetError" -> epsilon`,
the goal is `Abs[center-root] <= Max[epsilon, tau Abs[root]]`. A zero root
requires the explicit absolute fallback. The returned center's relative
error bound uses the enclosing interval, not its decimal approximation.

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

Pure logarithmic source dependence is handled by the exact chart
`u = Exp[-h]` in the positive local source distance. Polynomial and supported
real powers of logarithms become ordinary inverse problems in `h`; the
source is reconstructed by exponentiation only when the transported
absolute argument error tends to zero. Exact repeated charts can retain
an exact inverse such as `Exp[-Exp[y]]`. Finite sums of exponentials at either
source infinity use `u = Exp[-side x]`; arbitrary exact real rates become
ordinary real powers, so rational commensurability is unnecessary.

```wolfram
AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, {y, 1}]
(* Exp[-Sqrt[y]-1/2] (1 - 1/(8 Sqrt[y])) + O[Exp[-Sqrt[y]-1/2]/y] *)
AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}]
(* -Log[y] + y - 3 y^2/2 + 10 y^3/3 + O[y^4] *)
```

The source result retains `"CoordinateSeries"`, `"ReconstructedSeries"`,
`"SourceCoordinateExpression"`, and `"SourceTransformExpression"`, alongside
the original function and branch. Its residual checks the displayed
reconstruction, including the reconstruction's own truncation. A residual
whose ordering needs a larger coefficient algebra is returned as an exact
expression with the order claim marked uncomputed. Explicit declared input
remainders require a separate source-chart transport contract.

The extended constructors below supply bounded reciprocal-logarithmic,
flat-sector and Fourier algebras. They keep their different cutoff meanings
explicit; arbitrary transseries and incomparable phase families remain
outside the admitted classes.
The logarithmic target route accepts a single exponential product with an
eventually signed power-log amplitude and a phase with a negative leading
power in the positive local source coordinate. It includes phases containing
several powers and polynomial logarithms.
Exponentially small or large terms (`Exp[-1/x]`), oscillatory coefficients
(`Sin[Log[x]]`) and nested logarithms are rejected with a descriptive
`Failure` by the ordinary forward engine.

## Finite logarithmic hierarchies, sectors, and special functions

```wolfram
AsymptoticInverse[x + x/Log[x], {x, 0}, {y, 5}]
AsymptoticInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, {y, 4}]
AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 4}]
AsymptoticExponentialCoreInverse[x Exp[x], x^2, {x, Infinity}, {y, 2}]
AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 3}]
AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}]
AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}]
AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 2}]
```

Reciprocal-logarithmic units and leading iterated-log monomials use an
exclusive cutoff in the recorded inverse logarithm. Higher source-power
corrections with generalized logarithmic coefficients use the ordinary
power cutoff. `"LogarithmicLevels"` bounds the finite positive hierarchy
(default three, maximum eight). Omitted higher power sectors remain
separate from the logarithmic tail. Ordinary polynomial-log inputs retain
the established method dispatch.

`SeriesTermGoal -> n` counts complete nonzero blocks in each of these three
families, searching past cancellations. Generalized coefficient cutoffs may
be negative when they still exceed the leading target power, including
during refinement. Logarithmic unit cutoffs remain positive. A bounded
search reports `ResourceLimit` with its best expansion if it cannot reach
the count; a zero finite coefficient prefix is never an exactness certificate.

`SeriesCompose` and `SeriesDifferentiate` also operate on exact reciprocal-log
units with a positive monomial carrier. They rechart affine logarithmic
scales, transport both composition errors, and retain an analytic derivative
contract. For example, if `s` is the inverse of `x + x/Log[x]` at zero,
`SeriesCompose[s, s]` computes its self-composition and
`SeriesDifferentiate[s]` its derivative. The specialized operations
`ReciprocalLogCompose` and `ReciprocalLogDifferentiate` expose the same
bounded calculus. Translated endpoints and models with omitted higher-power
sectors require additional contracts and are rejected by these operations.

```wolfram
a = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {z, 4}];
b = AsymptoticLogarithmicInverse[x + 2 x/Log[x], {x, 0}, {y, 4}];
c = ReciprocalLogCompose[a, b];   (* also SeriesCompose[a, b] *)
d = ReciprocalLogDifferentiate[c];
SeriesRefine[d, 6]
```

`AsymptoticExponentialCoreInverse` retains an exact Lambert or elementary
inverse of a growing exponential core and computes complete perturbation
sectors. For `x Exp[x] + x^2`, its first correction is
`ProductLog[y] - ProductLog[y]^3/((1 + ProductLog[y]) y)`.
It supports affine source translations, both source infinities, finite
reciprocal source charts, signed target scaling and offsets. A declared
polynomial input error has a matching derivative contract and remains a
separate first-sector accuracy ceiling.

`AsymptoticFlatInverse` uses an exact shifted monomial zero sector and
positive commensurable exponential phases with finite power-log
amplitudes. Its integer sector depth is inclusive. For `x + Exp[-1/x]`,
the first three sectors are `y - E + E^2/y^2 + (1/y^3 - 3/(2 y^4)) E^3`,
where `E = Exp[-1/y]`. The full omitted sector tail has a proved asymptotic
majorant; its constants and threshold are existential, not numerical
certificates.

`FlatSeriesTruncate`, `FlatSeriesMultiply`, `FlatSeriesObservable` and
`FlatSeriesDifferentiate` provide arithmetic within this finite sector
algebra. Multiplication requires the same target chart and phase;
observables are polynomials. Truncation keeps the exact zero sector and
separately records inner power-log errors and the omitted exponential
sector. Differentiation uses the inverse's analytic remainder contract;
it does not infer a derivative bound from an arbitrary value-only Big-O.

```wolfram
s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}];
t = FlatSeriesTruncate[s, 3];
FlatSeriesMultiply[t, 1/y]
FlatSeriesObservable[s, 2 z^2 - 3 z + 7, z, "InnerCutoff" -> 4]
FlatSeriesDifferentiate[t]
```

Here `2` is the inclusive exponential-sector depth, while `3` and
`"InnerCutoff" -> 4` are exclusive powers in the positive monomial core
coordinate. Raising a truncation cutoff cannot recover discarded coefficients.

`AsymptoticFourierInverse` uses finite exact real frequencies in the
logarithm, convolves them under multiplication, and enforces a separate
`"MaxFrequencies"` budget. Remainders use nonoscillatory envelopes. A
leading oscillatory coefficient without an eventual nonzero sign remains
unsupported. `InverseResidual` handles the finite Fourier equation and
normalized logarithmic-unit equations; generalized logarithmic coefficient
residuals report `UnsupportedResidual` rather than an unproved order.

The special-function adapters cover `"Erfc"`, `"LogGamma"`, `"Gamma"`,
`"LambertThreshold"`, and `"QuadraticThreshold"`. The tail adapters have
explicit Poincare forward value and derivative remainder contracts; they
do not claim convergence of the original forward asymptotic series.
Threshold adapters keep the requested real branch in a ramified local
coordinate. Adapters are selected explicitly; no unproved automatic
switching threshold is used.

## Refinement requests and numerical evidence

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
SeriesRefine[s, 6]
SeriesRefine[s, <|"AdditionalBlocks" -> 3|>]
SeriesRefine[s, <|"Target" -> 1/100, "TargetError" -> 10^-30,
  "Interval" -> {1/200, 1/50}|>]
```

Compatible ordinary inverse refinements retain complete Lagrange blocks or
continue an exact-precision Newton state. `"RefinementStatistics"` records
reuse, new coefficient evaluations and new Newton steps. Automatic
forward-model expansion replays the source when more input terms are
needed; a declared input remainder remains a hard precision cap.
Logarithmic refinements replay the original logarithmic source.
Additional-block requests stop at a certified finite inverse and retain
the best expansion if a resource or input-precision bound intervenes.

A tolerance request returns a numerical certificate association, including
its rational center and root enclosure. It preserves the original symbolic
expansion and does not replace its Big-O with a numeric error. Certificates
can establish existence by contained residual brackets or by exact
endpoint signs and continuity, followed by signed-derivative interval
refinement.

The common `InverseNumericalCheck` supports the extended inverse kinds and
power observables. `"ReferenceRoot"` is the numerical source root;
`"ReferenceObservable"` is its requested power or finite source-distance
power. `"ExactInverse"` remains a legacy alias for the numerical root.
Errors compare the correct observable. Exact target offsets are subtracted
before decimal evaluation, and original source/target charts are used for
stable comparisons. This operation supplies numerical evidence, never an
interval certificate.

`Tests/BenchmarkRefinement.wl` compares fresh construction and incremental
refinement across rational/irrational gaps, resonances, high log degrees
and a deep one-gap Catalan oracle. It records equality, time, retained
sizes and evaluation memory. Reuse is beneficial on several expensive
coefficient fixtures but is slower and uses more memory on some small
ones; no universal speed claim is made.

`Tests/RunGeneratedCampaign.wl` runs a seeded independent-marker oracle
campaign, preserving source hashes, complete inputs, actual outcomes and
bounded counterexample shrinking. Environment variables select the seed,
case count, time budgets and a new evidence directory. Existing campaign
evidence is never overwritten.

## Files

- `Kernel/AsymptoticInverse.wl`, `Kernel/LambertInverse.wl`,
  `Kernel/ExactTermination.wl` — the package;
  `Kernel/init.m` — loader.
- `Tests/*.wlt`, `Tests/RunTests.wl` — the regression suites
  (`wolfram -script AsymptoticInverse/Tests/RunTests.wl`).
- `Kernel/CoordinateInverse.wl`, `Kernel/IncrementalInverse.wl` — coordinate
  transformations and reusable exact-weight computation states.
- `Kernel/SeriesOperations.wl`, `Kernel/CorePerturbation.wl`,
  `Kernel/InverseCertificates.wl`, `Kernel/SourceCoordinates.wl` — explicit
  calculus, exact-core marker expansions, exact rational root certificates,
  and source-chart reconstruction.
- `Kernel/LogarithmicScales.wl`, `Kernel/ReciprocalLogOperations.wl`,
  `Kernel/FlatSectors.wl`, `Kernel/FlatSectorOperations.wl`,
  `Kernel/FourierCoefficients.wl` — finite logarithmic, flat-sector and Fourier
  inverse families and their admitted operations.
- `Kernel/ExponentialCorePerturbation.wl`, `Kernel/SpecialFunctionAdapters.wl`
  — growing exact-core perturbation sectors and special-function reductions.
- `Kernel/RefinementState.wl`, `Kernel/RefinementRequests.wl`,
  `Kernel/NumericalInverseChecks.wl` — retained computation, structured
  requests, and original-equation numerical evidence.
- `Tests/BenchmarkRefinement.wl`, `Tests/RunGeneratedCampaign.wl` — refinement
  comparisons and reproducible generated campaigns with bounded shrinking.
- `Tests/BenchmarkPerformance.wl` — reproducible comparisons with the original
  sparse-product, integer-power, and enumeration algorithms.
- `Examples/Examples.wl` — worked examples.
- `PacletInfo.wl` — paclet metadata (`PacletDirectoryLoad["AsymptoticInverse"]`).
