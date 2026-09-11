# The ProveIt article examples against the package

This report tests the series and inverse-series examples of the vendored
ProveIt articles under `vendor/proveit/docs` against the package as it stands
at the commit that carries this file, records what reproduces and what does
not, and proposes the features that would close each gap. It complements the
[coverage matrix](VENDORED_ASYMPTOTICS.md), which maps the article families to
the implementation without executing them; this report executes concrete
examples.

**Evidence.** Every case below was run by
[ProbeProveItExamples.wl](../../validation/ProbeProveItExamples.wl) on Wolfram
15.0.1 for Windows (through the Wolfram MCP evaluator with an `Exit`-free
copy); the receipt is
[proveit-examples-probe.json](../../validation/proveit-examples-probe.json).
Where the article displays an expansion, the package output was checked
against it symbolically through the displayed order (`Check -> True`), or
numerically at a large argument against a high-precision root of the source
(`Check -> <relative error>`). A case that returns a `"Native"` result is a
formal native object without the package's analytic remainder, which for this
report counts as *not reproduced* unless the finite part is the article's
expansion. Mathics was not run for this report.

**Result in one line.** Of 59 cases, 40 return a result object and 19 are
refused. Of the 40, 19 reproduce the article's expansion and were checked
against it, 13 return the expected expansion where the article displays no
formula to check against, and 8 return a formal native object that is not the
package's own expansion (one of them, L2, is numerically wrong). The
reproduced set is the near-identity polynomial-logarithmic reversion calculus
and the Lambert, Gamma and Barnes inverses; the refused set is dominated by
three missing capabilities: inverses of Gamma-quotient and exponential-times-
oscillation sources, forward expansions on nested-logarithm and
reciprocal-logarithm scales, and sequence asymptotics whose large variable is
the order of a special function (Fubini, Bell, partitions) or the base of a
q-product near 1.

## Sources examined

- *Transseries: the polynomial-logarithmic calculus, series reversal at
  infinity, and the inversion of rapidly growing functions* (56,141 lines,
  72 `example` environments). Its reversion examples (Ex. 40–56), its
  algebra examples (Ex. 14, 17, 21, 23, 27, 38) and its eight inversion
  subjects (Gamma and Barnes G, hyperfactorial, double factorial,
  subfactorial, Fibonacci, Bell, Fubini, `x + W(x)`, plus rooted trees and
  partitions) supply most cases.
- *The Lambert W Function: A Real-Variable Guide with Proofs* (Puiseux
  expansion at the branch point, the unified complete real asymptotic
  expansion, the Taylor expansion at a regular point, and the transcendental
  equations chapter).
- *Combinatorial Transseries and Their Inverses* (the Gamma-quotient engine:
  Catalan and central binomial inverses; the harmonic inverse).
- *q-Series and Inverse q-Analogs* and *Gaussian Coefficient Calculus*
  (q-Pochhammer near `q = 0` and near `q = 1`, q-Gamma, Gaussian binomials).

The other 40 vendored articles (Fabius/Rvachev, Fourier decay, spectral,
information and representation frontiers) do not display power-log or
inverse series of the kind the package computes; their asymptotic statements
are endpoint, saddle or transform expansions of specific special functions and
are out of scope for this report, as the coverage matrix already records.

## Cases and verdicts

Verdict key: **Yes** reproduces the article (checked); **Yes (unchecked)**
returns the expected expansion, no article formula was available to compare;
**Formal** returns a native object that is not the article's expansion;
**No** refused. `Check` quotes the receipt.

### Near-identity reversion at infinity (transseries volume)

| Case | Article statement | Request | Verdict | Check |
| --- | --- | --- | --- | --- |
| T1 | Ex. 40: inverse of `X + log X` through block 4 (Lambert polynomials) | `AsymptoticInverse[x + Log[x], {x, Infinity}, {y, 5}]` | Yes | True |
| T2 | Ex. 41: `X + a log X + b/X`, blocks `b0..b4` | `AsymptoticInverse[x + a Log[x] + b/x, ...]`, `a > 0` | Yes | True |
| T3 | Ex. 42/46: Catalan inverse of `X + c/X` | `AsymptoticInverse[x + c/x, {x, Infinity}, {y, 8}]` | Yes | True |
| T4 | Ex. 44: fully mixed perturbation through `t^3` | `AsymptoticInverse[x + 2 Log[x] + 1 + (3 Log[x] - 1)/x + (Log[x]^2 + 2)/x^2, ...]` | Yes | True |
| T5 | Ex. 48: `X + a log X + b` through `t^3` | `AsymptoticInverse[x + a Log[x] + b, ...]` | Yes | True |
| T6 | Ex. 49: `X^2 + X`, Puiseux inverse | `AsymptoticInverse[x^2 + x, {x, Infinity}, {y, 2}]` | Yes | True |
| T7 | Ex. 50: `X log X`, nested-logarithm inverse | `AsymptoticInverse[x Log[x], {x, Infinity}, {y, 3}]` | Yes | True |
| T8 | Ex. 54: `X^2 log X`, Puiseux-logarithmic inverse | `AsymptoticInverse[x^2 Log[x], {x, Infinity}, {y, 3}]` | Yes (equivalent scale) | relative error 4.6e-5 at `10^20` (article's three terms: 1.3e-5) |
| T9 | Ex. 55: `X + α log X + γ log log X`, depth-two reversion | `AsymptoticInverse[x + al Log[x] + ga Log[Log[x]], ...]` | Yes | True through `t^2` |
| T10 | Ex. 56: `X + X/log X`, inverse in the logarithmic chart | `AsymptoticInverse[x + x/Log[x], {x, Infinity}, {y, 4}]` | Yes | True through `λ^-3` |
| T11 | Ex. 51: `c X^ρ (log X)^σ` (`2 X^3 (log X)^2`) | `AsymptoticInverse[2 x^3 Log[x]^2, {x, Infinity}, {y, 2}]` | Yes (equivalent scale) | relative error 3.7e-3 at `10^30` (two terms) |

T8 and T11 expand on the scale `log(2Y)` and `log(Y) + log(9/8)` where the
article uses `log Y` with the shift carried by `log log` terms; both are
valid Poincaré expansions of the same inverse and agree numerically at the
stated orders. T9 is the depth-two case the article says is "not covered by
the template as stated"; the package's logarithmic-inverse route produces
the three Lagrange–Bürmann blocks exactly.

### Forward polynomial-logarithmic algebra (transseries volume)

| Case | Article statement | Request | Verdict | Check |
| --- | --- | --- | --- | --- |
| F3 | Ex. 17: reciprocal of `1 + (L+1)t + L^2 t^2 + (L-2) t^3` | `AsymptoticExpansion[1/(...), {x, Infinity, 4}]` | Yes (unchecked) | matches the hand product |
| F4 | Ex. 14: square root through four blocks | `AsymptoticExpansion[Sqrt[1 + 2 Log[x]/x + ...], {x, Infinity, 4}]` | Yes | True |
| F5 | Ex. 21: finite logarithm `log(1 + (L+1)t + L^2 t^2)` | `AsymptoticExpansion[Log[1 + ...], {x, Infinity, 4}]` | Yes (unchecked) | |
| F6 | Ex. 44 forward source (exact finite sum) | `AsymptoticExpansion[x + 2 Log[x] + 1 + ..., {x, Infinity, 4}]` | Yes (unchecked) | exact, remainder `Infinity` |
| F1 | Ex. 27/38: scale-changing composition `F(3X^2/L)`, `F = Y + log Y + 1/Y` | `AsymptoticExpansion[3 x^2/Log[x] + Log[3 x^2/Log[x]] + Log[x]/(3 x^2), {x, Infinity, 3}]` | Formal | native object, unexpanded |
| F2 | Ex. 23: `log(L^2 t^-3 (1 + (L+1)t))`, forced nested logarithm | `AsymptoticExpansion[Log[Log[x]^2 x^3 (1 + (Log[x] + 1)/x)], {x, Infinity, 3}]` | Formal | `Log[x^3 Log[x]^2]` left unexpanded beside a correct tail |
| N1 | Ex. 23/50: `log log X` on the forward side | `AsymptoticExpansion[Log[Log[x]], {x, Infinity, 2}]` | Formal | |
| N2 | Ex. 15/56: reciprocal logarithm as a coefficient | `AsymptoticExpansion[x/Log[x] + Log[x], {x, Infinity, 2}]` | Formal | |

### Lambert W (guide and the `x + W(x)` chapter)

| Case | Article statement | Request | Verdict | Check |
| --- | --- | --- | --- | --- |
| L1 | Thm. "Unified complete real asymptotic expansion", `W_0` at `+∞` | `AsymptoticExpansion[ProductLog[x], {x, Infinity, 3}]` | Yes | True |
| L2 | Same theorem, `W_{-1}(-x)`, `x → 0+` | `AsymptoticExpansion[ProductLog[-1, -x], {x, 0, 2}]` | Formal, with complex artifacts | value `-16.62647 - 0.00024 i` against `-16.62651` at `10^-6` |
| L3 | Chapter "Reversing `x + W(x)`", Thm. "All-orders expansion" | `AsymptoticInverse[x + ProductLog[x], {x, Infinity}, {y, 3}]` | No | `UnsupportedInput` |
| L4 | Thm. "Unified Puiseux expansion" at `-1/e` | `AsymptoticExpansion[ProductLog[-1/E + h], {h, 0, 2}]` | Yes | True |
| L5 | Ex. 3: Taylor expansion of `W_0` at 1 | `AsymptoticExpansion[ProductLog[1 + h], {h, 0, 3}]` | Yes | True |
| L6 | Part 0 "The Lambert core": inverse of `x e^x` | `AsymptoticInverse[x Exp[x], {x, Infinity}, {y, 3}]` | Yes (unchecked) | equals L1 |
| L7 | Thm. "All positive solutions of `x^x = A`" | `AsymptoticInverse[x^x, {x, Infinity}, {y, 2}]` | Yes (unchecked) | expansion of `log A / W(log A)` |
| L8 | "Inverting the prime-number scale": inverse of `x/log x` | `AsymptoticInverse[x/Log[x], {x, Infinity}, {y, 3}]` | Yes (unchecked) | expansion of `-y W_{-1}(-1/y)` |
| L9 | "A power times an exponential": inverse of `x^2 e^x` | `AsymptoticInverse[x^2 Exp[x], {x, Infinity}, {y, 2}]` | Yes (unchecked) | expansion of `2 W(√y/2)` |
| L10 | "A linear term plus a logarithm": inverse of `x - log x`, large branch | `AsymptoticInverse[x - Log[x], {x, Infinity}, {y, 3}]` | Yes (unchecked) | |
| W1 | forward source `x + W(x)` | `AsymptoticExpansion[x + ProductLog[x], {x, Infinity, 3}]` | Formal | native object carries the right finite part |

L2 is the one *incorrect* output of the report: the native route expands
`ProductLog[-1, -x]` through `Log[-x]` with a `-iπ` and an `Arg`/`Floor`
branch bookkeeping that leaves a spurious imaginary part; the article's real
expansion is `log x - log(-log x) + ...`. L3 fails because the package's
logarithmic-inverse route does not admit `ProductLog` inside the source even
though it expands `ProductLog` on the forward side (L1, W1).

### Rapidly growing functions and combinatorial sequences

| Case | Article statement | Request | Verdict | Check |
| --- | --- | --- | --- | --- |
| C1 | Thm. "All-orders expansion of `Γ_+^{-1}`" | `AsymptoticInverse[Gamma[x], {x, Infinity}, {y, 2}]` | Yes | relative error 7.7e-11 at `10^500` |
| C2 | Thm. "All-orders expansion of the Barnes inverse" | `AsymptoticInverse[BarnesG[x], {x, Infinity}, {y, 2}]` | Yes | relative error 5.7e-7 at `10^500` |
| C14 | Ex. 71/72: Stirling expansion of `Γ` | `AsymptoticExpansion[Gamma[x], {x, Infinity, 3}]` | Yes (unchecked) | |
| C3 | Thm. "Canonical inverse transseries" of the hyperfactorial `K` | `AsymptoticInverse[Hyperfactorial[x], ...]` | No | `UnsupportedInput` |
| C3b | its carrier `x^(x^2/2 + x/2 + 1/12) e^(-x^2/4)` | `AsymptoticInverse[..., {y, 1}]` | Yes (unchecked) | leading core `2 √(log y / log(2 log y / e))` |
| C4 | "The double factorial", branchwise inverse | `AsymptoticInverse[Factorial2[x], ...]` | No | `UnsupportedInput` |
| C4b | its even branch `2^(x/2) Γ(x/2 + 1)` | `AsymptoticInverse[2^(x/2) Gamma[x/2 + 1], ...]` | No | `UnsupportedInput` |
| C5 | "The subfactorial", median inverse | `AsymptoticInverse[Subfactorial[x], ...]` | No | `UnsupportedInput` |
| C5b | its carrier `Γ(x+1)/e` | `AsymptoticInverse[Gamma[x + 1]/E, ...]` | Yes (carrier only) | relative error 3.1e-8 at `10^50` |
| C6 | "A real-argument Fibonacci function" (Binet with cosine) | `AsymptoticInverse[(GoldenRatio^x - Cos[Pi x] GoldenRatio^(-x))/Sqrt[5], ...]` | No | `ExponentialScale` |
| C6b | its dominant exponential `φ^x/√5` | `AsymptoticInverse[GoldenRatio^x/Sqrt[5], ...]` | Yes (carrier only) | exact `log(√5 y)/log φ` |
| C7 | "The Bell numbers", all-orders saddle expansion | `AsymptoticExpansion[BellB[n], {n, Infinity, 2}]` | Formal | unevaluated `BellB[n]` |
| C8 | "The Fubini numbers", elementary-scale form (`PolyLog[-n, 1/2]/2`) | `AsymptoticExpansion[PolyLog[-n, 1/2]/2, {n, Infinity, 2}]` | No | `UnsupportedNativeCoefficient` |
| C8b | same in Lerch form `LerchPhi[1/2, -n, 1]/4` | `AsymptoticExpansion[LerchPhi[1/2, -n, 1]/4, ...]` | No | `UnsupportedNativeCoefficient` |
| C8c | Fubini inverse (index from the value) | `AsymptoticInverse[PolyLog[-n, 1/2]/2, {n, Infinity}, {y, 1}]` | No | `UnsupportedInput` |
| C10 | "The partition numbers", Rademacher sectors | `AsymptoticExpansion[PartitionsP[n], {n, Infinity, 1}]` | Formal | unevaluated `PartitionsP[n]` |
| C11 | Gamma-quotient engine: Catalan inverse | `AsymptoticInverse[CatalanNumber[x], ...]` | No | `UnsupportedInput` |
| C11b | Catalan as `Γ(2x+1)/(Γ(x+1) Γ(x+2))` | `AsymptoticInverse[Gamma[2 x + 1]/(Gamma[x + 1] Gamma[x + 2]), ...]` | No | `UnsupportedInput` |
| C11c | Catalan exponential-power carrier `4^x x^(-3/2)/√π` | `AsymptoticInverse[4^x x^(-3/2)/Sqrt[Pi], ...]` | Yes (carrier only) | `log(√π y)/log 4 + (3/(2 log 4)) log log ... ` |
| C12 | Harmonic inverse (exponential inversion of `H_x`) | `AsymptoticInverse[HarmonicNumber[x], ...]` | No | `InsufficientForwardOrder` |
| C12b | same from the explicit source `log x + γ + 1/(2x) - 1/(12x^2)` | `AsymptoticInverse[Log[x] + EulerGamma + ..., ...]` | No | `LogarithmicLimit` |
| C13 | Gamma-quotient engine: central binomial inverse | `AsymptoticInverse[Binomial[2 x, x], ...]` | No | `UnsupportedInput` |

Rooted trees (A000081) have no closed interpolation to request and are not
probed; the article derives them from the Otter singularity of an implicit
generating function, which is outside every current entry point.

### q-analogs

| Case | Article statement | Request | Verdict | Check |
| --- | --- | --- | --- | --- |
| Q2 | `(q; q)_∞` near `q = 0` (Euler pentagonal) | `AsymptoticExpansion[QPochhammer[q, q], {q, 0, 5}]` | Yes | True (`1 - q - q^2 + O(q^5)`) |
| Q6 | `(a; q)_∞` near `q = 0`, fixed `a` | `AsymptoticExpansion[QPochhammer[a, q], {q, 0, 3}]` | Yes (unchecked) | |
| Q1 | fixed-argument `q → 1` product `(1/2; e^-t)_∞` | `AsymptoticExpansion[QPochhammer[1/2, Exp[-t]], {t, 0, 2}]` | No | `UnresolvedNativeSeries` |
| Q7 | same with `u = 1 - q` | `AsymptoticExpansion[QPochhammer[1/2, 1 - u], {u, 0, 1}]` | No | `UnresolvedNativeSeries` |
| Q3 | q-Gamma at fixed `q`, large argument | `AsymptoticExpansion[QGamma[x, 1/2], {x, Infinity, 2}]` | No | `UnsupportedNativeCoefficient` |
| Q4 | q-Gamma inverse | `AsymptoticInverse[QGamma[x, 1/2], ...]` | No | `UnsupportedInput` |
| Q5 | fixed-base large-index Gaussian binomial | `AsymptoticExpansion[QBinomial[2 n, n, 1/2], {n, Infinity, 1}]` | No | `UnsupportedNativeCoefficient` |

## What the failures have in common

1. **Sources whose forward expansion is not a power-log series in the
   package's sense.** The Gamma-quotient sequences (Catalan, central
   binomial, double factorial through `Γ(x/2+1)`, `2^x Γ(x+1)`), the
   hyperfactorial and the q-Gamma have leading behaviour
   `exp(a x^p log x + ...)` times powers; the package's Gamma inverse
   admits `Γ(x)`, `Γ(x)^2` and `Γ(x/2+1)` but not a product with an
   exponential factor or a quotient with distinct arguments. The article
   handles all of them through one "exponential–power model"
   (`y = a x^p exp(...)` with a Lambert core), which the package has only
   as a `ProductLog` carrier for pure `x^p e^{qx}` sources (L9, C11c, C3b).
2. **Oscillatory exponentially small corrections.** Fibonacci with its
   `cos(πx) φ^{-x}` term, the subfactorial's `(-1)^n`-type median
   corrections, and the double factorial's parity branches need the
   exponential-plus-Fourier sector machinery that the package has only for
   finite endpoints (`AsymptoticFlatInverse`, `FourierInverseCoefficient`).
3. **Nested logarithms and reciprocal logarithms on the forward side.**
   `log log x`, `x / log x` and the composition `F(3X^2/L)` are refused or
   left as formal native objects, while the inverse routes already produce
   `log log y` coefficients (T7–T11). The forward calculus is one
   logarithmic depth short of the inverse calculus.
4. **Sequence asymptotics in the order or the base.** Fubini
   (`PolyLog[-n, 1/2]`, `LerchPhi[1/2, -n, 1]`), Bell and partitions have
   their large variable in the order of a special function or under a
   saddle; the q-products near `q = 1` have it in the base. None of these is
   a power-log expansion of a built-in in its argument, which is the only
   regime the special-function adapters implement.
5. **Nonprincipal Lambert branches near zero.** L2 is the single wrong
   output: the native route's complex logarithm leaks into a real
   expansion.

## Proposed features, in priority order

Each item names the cases it would close, the article theorem that supplies
the algorithm, and what already exists in the package to build on.

1. **Fubini, Bell and other sequence asymptotics with the large variable in
   the order (C7, C8, C8b, C8c).** Requested explicitly: the package should
   construct direct and inverse asymptotics of the Fubini numbers from
   `PolyLog[-n, 1/2]/2` or `LerchPhi[1/2, -n, 1]/4`. The article's
   Corollary "Elementary-scale form" gives the exact pole lattice
   `F_n ~ (n!/(2 (log 2)^{n+1})) Σ_k e^{-n Λ_k} Σ_j C_{j,k} n^{-j}` with
   Stirling coefficients `c_j` and `Λ_k = Log(ζ_k/ρ)`; the real principal
   sector is the `k = 0` term, and the `k ≠ 0` terms are exponentially
   small oscillatory sectors (`Λ_k` complex). Implementation: a
   `PolyLog[-n, z]` / `LerchPhi[z, -n, a]` adapter for `n → ∞` with
   `0 < z < 1` that returns `n! (log 1/z)^{-n-1}` times a Stirling-type
   Poincaré series (the package's Gamma forward machinery supplies `n!`
   and the `c_j`), plus the inverse through the existing Gamma-inverse
   core (`n!` inverse with a `(log 1/z)^{-n}` factor is the `2^x Γ(x+1)`
   shape of item 2). Bell numbers need the saddle `r = W(n)` from the
   Theorem "All-orders saddle expansion"; its `c_m(r)` are finite explicit
   sums that the package's `ProductLog` forward jets can carry.
2. **The exponential–power inverse model (C4b, C11, C11b, C13, Q4, and the
   Gamma quotients generally).** Article Part 0, Theorems "Exact solution of
   the dominant block", "All-orders reversion around the Lambert core" and
   "Reversion about an arbitrary core": a source `y = a x^p exp(b x^q (log x)^s + ...)`
   is inverted by a Lambert core plus triangular reversion. The package
   already has the core for `x^p e^{qx}` and for `Γ(x)`; the missing step is
   the reduction of a product or quotient of Gamma factors with affine
   arguments, and of `c^x` prefactors, to that model (the article's
   "parameter dictionary" and the combinatorial volume's
   `gammaLogCoefficient` recipe give the coefficients directly). This
   closes Catalan, central binomial, the double factorial's even branch and
   `2^x Γ(x+1)`; the hyperfactorial (C3) needs the same model with `p = 2`
   and the Theorem "Canonical inverse transseries".
3. **Inverses of logarithm-leading sources (C12, C12b).** A source whose
   leading block is `log x` (harmonic numbers, digamma) has an exponential
   inverse `x = e^{y - γ} - 1/2 + ...`; the combinatorial volume's chapter
   "Harmonic functions: exponential and endpoint-Puiseux inversion" gives the
   coefficients (`harmonicInverseCoefficient` in its Wolfram recipes). The
   package refuses these as `LogarithmicLimit`; the exponential-core inverse
   already handles the converse direction, so the new route is the
   exponential of a near-identity reversion in the variable `e^y`.
4. **Oscillatory exponentially small inverse sectors (C5, C6, C4).** The
   article's "single-frequency sector factorization" (subfactorial), the
   "Lagrange–Good form of the outer inverse" (Fibonacci) and the "periodic
   interpolation and its oscillatory inverse" (double factorial) all reduce
   to a dominant exponential carrier plus finitely many `e^{iθx}` or
   `(-1)^x` corrections. The package's flat-sector and Fourier constructors
   supply the coefficient algebra at finite endpoints; the work is a
   transport of that algebra to the `x → ∞` exponential scale with the
   carrier inverse of item 2 or the exact `log(√5 y)/log φ` of C6b as the
   base.
5. **Nested logarithms and the iterated logarithmic field on the forward
   side (F1, F2, N1, N2, W1).** The forward jet calculus stops at
   polynomial coefficients in one `log`; the inverse routes already produce
   `log log y` and `1/(1 + log y)` scales (T7–T11, L7–L9). Extending the
   forward power-log ring to depth two (coefficients polynomial in `log`
   and `log log`, with the article's Chapter "Scale-changing composition
   and deeper logarithms") would expand `log log x`, `x/log x`, the
   composition `F(3X^2/L)` and `x + W(x)` as analytic objects instead of
   formal native ones, and would let L3 (the inverse of `x + W(x)`) go
   through the existing logarithmic-inverse route.
6. **q-products and q-special functions (Q1, Q3, Q5, Q7).** The q-series
   monograph's fixed-argument `q → 1` theorem (`(a; e^{-t})_∞ ~ exp(-Li_2(a)/t)`
   times a Bernoulli/polylogarithm series with a uniform remainder) and the
   fixed-`q` large-argument theorems are self-contained coefficient
   generators; the package has none of them. The coverage matrix lists the
   regimes; the first to implement is the fixed-argument `q → 1` product,
   which is a single dilogarithmic leading scale plus a power series in
   `t`.
7. **Real nonprincipal Lambert branches near zero (L2).** Route
   `ProductLog[-1, -x]` for `x → 0+` through the same logarithmic
   expansion as `ProductLog[x]` at infinity with `L_1 = log x`,
   `L_2 = log(-log x)`, on the real branch, instead of the native
   complex-logarithm fallback; the guide's unified theorem states the
   coefficients (`P_n(L_2)` with unsigned Stirling numbers), and the
   package already implements them for `W_0`.

Items 1–3 are the ones that turn article theorems with explicit
coefficient generators into public computations with the least new theory;
items 4–6 need new scale machinery; item 7 is a repair.

## Reproducing the probe

```bash
wolfram -noinit -script validation/ProbeProveItExamples.wl
```

The script needs the modular kernel and writes
`validation/proveit-examples-probe.json`; each record carries the request, the
outcome, the finite part, the remainder and the check. It asserts nothing and
is not part of the focused acceptance runs.

Return to the [development index](README.md).
