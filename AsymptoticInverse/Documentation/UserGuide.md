# AsymptoticInverse User Guide

AsymptoticInverse computes asymptotic expansions of functions and selected real inverse functions. It supports exact real exponents, logarithmic coefficients, finite and infinite endpoints, and explicit remainder classes. Additional constructors handle logarithmic hierarchies, exponential sectors, oscillatory coefficients, and selected special functions.

This guide describes the Wolfram Language interface. See the [mathematical article](../../article/asymptotic-inverse.pdf) for definitions, results, and proofs.

## Getting Started

The package requires Wolfram Language 15.0 or later. From the repository directory, load the kernel file:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
```

Alternatively, register the package directory and load its context:

```wolfram
PacletDirectoryLoad["AsymptoticInverse"];
Needs["AsymptoticInverse`"];
```

Use exact input such as `Sqrt[2]` and `1/10`. Leave the source and target symbols unassigned.

**Input**

```wolfram
Clear[x, y];
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{y - y^2 + 2 y^3 - 5 y^4, PowerLogRemainder[y, 5, 0]}
```

`Normal[s]` gives the finite approximation. Keep `s` when you need its remainder, branch information, or further series operations.

Outputs below are written in algebraically equivalent factored forms where this makes the expansion easier to read.

## Function Overview

| Task | Functions |
| --- | --- |
| Expand a function | [AsymptoticExpansion](#AsymptoticExpansion) |
| Expand a selected inverse | [AsymptoticInverse](#AsymptoticInverse) |
| Expand the increasing Gamma or LogGamma inverse | [Inverse Gamma and LogGamma Functions](#inverse-gamma-and-loggamma) |
| Expand the increasing Barnes G inverse | [Inverse Barnes G Functions](#barnes-inverse-expansions) |
| Inspect results and models | [PowerLogSeries](#PowerLogSeries), [PowerLogRemainder](#PowerLogRemainder), [PowerLogModel](#PowerLogModel), [InverseExpansionCoefficient](#InverseExpansionCoefficient) |
| Perform series arithmetic | [Ordinary Arithmetic](#ordinary-series-arithmetic), [SeriesNormalize](#SeriesNormalize), [SeriesAdd](#SeriesAdd), [SeriesMultiply](#SeriesMultiply), [SeriesPower](#SeriesPower), [SeriesLog](#SeriesLog), [SeriesExp](#SeriesExp) |
| Compose or apply a function | [SeriesCompose](#SeriesCompose), [SeriesObservable](#SeriesObservable) |
| Change the retained order | [SeriesTruncate](#SeriesTruncate), [SeriesRefine](#SeriesRefine) |
| Differentiate an expansion | [SeriesDifferentiate](#SeriesDifferentiate) |
| Check an inverse | [InverseResidual](#InverseResidual), [InverseNumericalCheck](#InverseNumericalCheck), [InverseCertificate](#InverseCertificate) |
| Retain an exact inverse core | [AsymptoticCoreInverse](#AsymptoticCoreInverse), [AsymptoticExponentialCoreInverse](#AsymptoticExponentialCoreInverse) |
| Generate perturbation formulas | [PerturbativeInverse](#PerturbativeInverse) |
| Use logarithmic hierarchies | [AsymptoticLogarithmicInverse](#AsymptoticLogarithmicInverse), [LogarithmicInverseResidual](#LogarithmicInverseResidual), [ReciprocalLogCompose](#ReciprocalLogCompose), [ReciprocalLogDifferentiate](#ReciprocalLogDifferentiate) |
| Use flat exponential sectors | [AsymptoticFlatInverse](#AsymptoticFlatInverse), [FlatSeriesTruncate](#FlatSeriesTruncate), [FlatSeriesMultiply](#FlatSeriesMultiply), [FlatSeriesObservable](#FlatSeriesObservable), [FlatSeriesDifferentiate](#FlatSeriesDifferentiate) |
| Use oscillatory logarithmic coefficients | [AsymptoticFourierInverse](#AsymptoticFourierInverse), [FourierInverseResidual](#FourierInverseResidual), [FourierInverseCoefficient](#FourierInverseCoefficient) |
| Use special-function inverse adapters | [AsymptoticSpecialInverse](#AsymptoticSpecialInverse), [SpecialInverseNumericalCheck](#SpecialInverseNumericalCheck) |

<a id="AsymptoticExpansion"></a>
## AsymptoticExpansion

### Usage

| Form | Result |
| --- | --- |
| `AsymptoticExpansion[f, {x, x0, h}]` | Expansion at `x0` with exclusive cutoff `h`. |
| `AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n]` | First `n` complete nonzero blocks. |
| `AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n]` | Equivalent rule form. |

`f` can be an expression, a unary pure function, or an unapplied unary `InverseFunction`. A callable is applied to `x`. A bare symbol is treated as an expression: use `Log[x]` or `Log[#] &` to expand the logarithm.

An applied inverse can also occur inside a supported expression. See [Callable and Applied Inverse Functions](#inverse-function-expressions).

### Details and Options

`AsymptoticExpansion` accepts `Assumptions -> True`, `Direction -> Automatic`, `SeriesTermGoal -> Automatic`, `"MaxTerms" -> 20000`, and `"InverseFunctionBranches" -> Automatic`.

Ordinary expansions use an absolute cutoff in the positive local coordinate. Gamma and Barnes G products and admitted exponential products use a cutoff inside an exact prefactor. A direct inverse-function result retains its inverse constructor's cutoff convention. See [Coordinates and Cutoffs](#coordinates-and-cutoffs).

The ordinary input class includes sums, products, exact real constant powers, logarithms, exponentials of bounded arguments, and supported Taylor, Laurent, or Puiseux function expansions. A branch or exponent ordering that cannot be established produces a `Failure`.

<a id="AsymptoticInverse"></a>
## AsymptoticInverse

### Usage

| Form | Result |
| --- | --- |
| `AsymptoticInverse[f, {x, x0}, {y, h}]` | Inverse approaching `x0` on the selected source side, with cutoff `h`. |
| `AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]` | First `n` complete nonzero inverse blocks. |
| `AsymptoticInverse[f, x, y, SeriesTermGoal -> n]` | Inverse approaching zero from above. |

The source symbol `x` and target symbol `y` must be distinct. The forward expression `f` must not contain `y`.

### Details and Options

| Option | Default | Meaning |
| --- | --- | --- |
| `Assumptions` | `True` | Parameter assumptions and source conditions valid eventually on the selected approach. |
| `Direction` | `Automatic` | Source approach; see [Directions and Branches](#directions-and-branches). |
| `Method` | `"Lagrange"` | Ordinary methods are `"Lagrange"`, `"Newton"`, and `"GroupedLagrange"`. Recognized Lambert problems also admit `"Lambert"` and are detected automatically. |
| `"Power"` | `1` | Inverse observable. For `r != 1`, returns the expansion of `(x - x0)^r` at a finite source endpoint or `x^r` at infinity. For `r == 1`, returns the original source variable, including its translation. |
| `"InputRemainder"` | `Automatic` | Additional unknown forward error. A pair `{rho, k}` declares both its value order and matching first-derivative order. `None` adds no declared error. Automatically generated expansion errors are still retained. |
| `"Truncation"` | `"Exponent"` | `"Exponent"` uses an exclusive exponent cutoff. `"Depth"` uses inclusive total perturbation depth. |
| `SeriesTermGoal` | `Automatic` | Nonzero complete-block count when no explicit cutoff is supplied. |
| `"MaxTerms"` | `20000` | Resource budget for exact expansion operations. |
| `"InverseFunctionBranches"` | `Automatic` | Explicit local branch selections for unevaluated inverse operators within the input. |

`"Power"` must be a nonzero exact real number. A negative source side requires an integer observable power. The method applies within its supported scale; selecting an ordinary method does not turn an unsupported logarithmic or sector problem into an ordinary expansion.

`"InputRemainder" -> {rho, k}` describes an omitted term in the positive source coordinate `u` with value order `u^rho (1 + Abs[Log[u]])^k` and derivative order `u^(rho - 1) (1 + Abs[Log[u]])^k`. This declaration can cap the inverse precision. It requires ordinary exponent truncation.

<a id="coordinates-and-cutoffs"></a>
## Details and Options: Coordinates and Cutoffs

### Positive Local Coordinates

Every ordinary expansion uses a positive coordinate tending to zero.

| Approach | Positive coordinate |
| --- | --- |
| `x -> x0`, from above | `x - x0` |
| `x -> x0`, from below | `x0 - x` |
| `x -> Infinity` | `1/x` |
| `x -> -Infinity` | `-1/x` |

An ordinary block has the form `w^beta P[Log[w]]`. All terms at the same exponent belong to one block, including the complete logarithmic polynomial. Exact cancellation is performed before blocks are counted.

For an inverse, the target coordinate also includes the limiting value and selected sign. Use `s["RemainderVariable"]` to obtain the coordinate actually used; do not substitute `y` for it without checking the result.

### Cutoff Meanings by Scale

| Result family | Meaning of the requested order |
| --- | --- |
| Ordinary power-log expansion | Exclusive exponent bound in the recorded positive local coordinate. |
| Factored Gamma, Barnes G, or elementary exponential expansion | Exclusive exponent bound inside the correction bracket multiplying `s["Prefactor"]`. |
| `LogGamma`, `LogBarnesG`, or a supported real logarithm of a Gamma or Barnes G product | Ordinary exclusive exponent bound in the positive local coordinate; complete logarithmic polynomials count as blocks. |
| Lambert expansion | Exclusive inverse-logarithmic exponent inside its prefactor; inspect `"LogarithmicVariable"`. |
| Increasing Gamma or LogGamma inverse | Exclusive exponent of `1/s["CoreInverse"]`; each coefficient is a complete polynomial in `1/Log[s["CoreInverse"]]`. |
| Increasing Barnes G inverse or logarithmic Barnes inverse | Exclusive exponent of `1/s["CoreInverse"]`; each coefficient is a complete polynomial in `1/(Log[s["CoreInverse"]] - 1)`. |
| Transformed source or target | Convention of `s["CoordinateSeries"]`, followed by its recorded substitution and reconstruction. |
| Reciprocal-logarithmic unit or leading logarithmic monomial | Positive exclusive cutoff in the recorded inverse-logarithmic coordinate. |
| Generalized logarithmic coefficients | Exclusive target-power cutoff above the leading observable power; this cutoff may be negative. |
| `"Truncation" -> "Depth"` | Inclusive total perturbation depth. |
| Exact-core perturbation | Inclusive marker degree. |
| Flat inverse | Inclusive exponential-sector degree. Inner coefficient cutoffs are separate and exclusive. |
| Fourier inverse | Exclusive target-power cutoff; frequencies have a separate resource budget. |
| Special-function adapter | Adapter-specific convention; see [AsymptoticSpecialInverse](#AsymptoticSpecialInverse). |

A cutoff is not a term count. For example, a sparse expansion can have its first omitted term strictly beyond the requested cutoff. `SeriesTermGoal -> n` counts complete nonzero blocks; an exact finite expansion can return fewer than `n` with zero remainder.

For a normalized product, the cutoff remains relative after cancellations between factors. This includes a balanced Gamma ratio and a product whose growing and decaying factors cancel. Ordinary elementary sources that are all bounded or merely logarithmically divergent retain the ordinary absolute convention.

### Directions and Branches

At a finite source endpoint, `Direction -> Automatic` means `"FromAbove"`. At `Infinity` the approach is `"FromBelow"`; at `-Infinity` it is `"FromAbove"`.

`AsymptoticInverse` selects the local source branch approaching the supplied endpoint from the requested side. The endpoint and side are part of the problem, even when another branch has the same limiting target value.

For `AsymptoticExpansion`, `Direction` describes the approach of the expansion variable. When expanding an applied inverse, its source branch is a separate choice.

Conditions need only hold on a sufficiently small deleted neighborhood or sufficiently distant tail. For example, `0 < x < 1` is compatible with `x -> 0` from above. A condition that fails eventually on the requested approach is rejected.

<a id="PowerLogSeries"></a>
## PowerLogSeries

### Usage

`PowerLogSeries[association]` is the result representation returned by the constructors. Use constructors, supported arithmetic, and series operations to create and transform it.

| Form | Meaning |
| --- | --- |
| `Normal[s]` | Finite expression, without its remainder. |
| `s["property"]` | A stored property. |
| `s["Properties"]` | Available property names. |
| `s[value]` | Evaluation of the finite expression at a numerical value. |

### Display and Evaluation

In `StandardForm` and `TraditionalForm`, a series displays its finite expression and its `O[...]` remainder. The `PowerLogSeries` head is hidden in these forms. For example:

**Input**

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
s
```

**Formatted Output**

```wolfram
y - y^2 + 2 y^3 - 5 y^4 + O[y^5]
```

An exact result displays only its finite expression. A result with zero finite expression and a nonzero remainder displays only the remainder; an exact zero displays `0`.

The underlying object still has head `PowerLogSeries`. Copying the formatted object into Wolfram Language input preserves the full series, including its remainder and metadata. The formatted object is read-only; use constructors, supported arithmetic, or series operations to change it.

| Form | Display or result |
| --- | --- |
| `StandardForm[s]`, `TraditionalForm[s]` | Finite expression and asymptotic remainder, without the wrapper head. |
| `Head[s]` | `PowerLogSeries`. |
| `InputForm[s]` | Full reconstructible `PowerLogSeries[association]` representation, including metadata. |
| `OutputForm[s]` | Compact diagnostic representation. |
| `Normal[s]` | Ordinary Wolfram Language expression, with the remainder and series metadata dropped. |

For the example above, `Normal[s]` returns `y - y^2 + 2 y^3 - 5 y^4`. Arithmetic on `s` propagates its remainder:

```wolfram
s + s
s^2
SeriesNormalize[(1 + s)/(1 - s), "Cutoff" -> 4]
```

Ordinary arithmetic on `Normal[s]` uses only the finite expression. Keep the series object when further operations must include its uncertainty. See [Series Arithmetic and Normalization](#series-operations) for supported functions, branch requirements, and precision rules.

### Common Properties

| Property | Meaning |
| --- | --- |
| `"Expression"` | The same finite expression returned by `Normal`. |
| `"Remainder"` | Complete remainder descriptor, including any absolute prefactor. |
| `"RemainderVariable"` | Positive small coordinate. |
| `"RemainderPower"`, `"RemainderLogDegree"` | Recorded order and logarithmic degree. |
| `"RemainderScaleExpression"` | Explicit scale used for numerical comparison, when supplied by the result family. |
| `"FrontierTerm"` | Computed first omitted term, or an indication that it is unknown. |
| `"Terms"` | Displayed coefficient data. Read `"TermConvention"` for their interpretation. |
| `"Scale"` | Result scale, when explicitly recorded. |
| `"Prefactor"`, `"Offset"` | Exact factor and translation for a factored representation. |
| `"Cutoff"` | Requested or selected truncation boundary. |
| `"Function"`, `"Variable"`, `"ExpansionPoint"`, `"Direction"` | Retained expression and approach data, when supplied. |
| `"Assumptions"`, `"TargetDomain"`, `"SourceDomain"` | Retained assumptions and branch conditions. Available domains depend on the result family. |
| `"Exact"` | Exact finite expansion status, when supplied. Zero remainder is the operative exactness test. |
| `"ExactModel"` | Exactness of a stored model; it does not by itself say that the displayed inverse terminates. |
| `"SeriesData"` | A native `SeriesData` object when the coordinate and exponents permit it; otherwise `Missing[...]`. |

Property availability varies by family. Inspect `s["Properties"]` before relying on specialized metadata. Do not edit the underlying association to change a branch or precision claim.

An arithmetic result with `"Scale" -> "Composite"` retains a finite expression and separate error scales. It has no single remainder exponent or cutoff. See [Composite Results](#composite-series-results).

Native `SeriesData` uses rational exponents and may hide the logarithmic degree inside its `O` term. Keep `s["Remainder"]` when the logarithmic envelope matters.

<a id="PowerLogRemainder"></a>
## PowerLogRemainder

`PowerLogRemainder[w, beta, k]` denotes `O[w^beta (1 + Abs[Log[w]])^k]` as `w -> 0+`. It is an inert asymptotic descriptor.

A factored result has an absolute remainder of the form

```wolfram
Abs[prefactor] PowerLogRemainder[w, beta, k]
```

The descriptor does not contain a numerical error constant or a numerical threshold. `"FrontierTerm"` and `"RemainderScaleExpression"` also do not provide pointwise error certificates. A zero remainder records an established exact finite expression within the constructor's stated model and branch.

## Examples

### Basic Examples

<a id="example-forward-irrational"></a>
#### Forward Expansion with an Irrational Exponent

**Input**

```wolfram
s = AsymptoticExpansion[Cot[x^Sqrt[2]], {x, 0, 5}];
Normal[s]
```

**Output**

```wolfram
x^-Sqrt[2] - x^Sqrt[2]/3 - x^(3 Sqrt[2])/45
```

The cutoff refers to powers of `x`, not the number of terms in the trigonometric expansion.

<a id="example-logarithmic-inverse"></a>
#### Inverse with Logarithmic Coefficients

**Input**

```wolfram
s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
Normal[s]
```

**Output**

```wolfram
y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2)
```

<a id="example-callable-inverse"></a>
#### Unapplied Inverse Function at Infinity

**Input**

```wolfram
s = AsymptoticExpansion[
  InverseFunction[x |-> ConditionalExpression[x + x^Sqrt[2], x > 0]],
  x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
x^(1/Sqrt[2]) - x^(Sqrt[2] - 1)/Sqrt[2]
  + (3 - Sqrt[2])/4 x^(3/Sqrt[2] - 2)
  + (6 - 5 Sqrt[2])/6 x^(2 Sqrt[2] - 3)
  + (235 - 162 Sqrt[2])/96 x^(5/Sqrt[2] - 4)
```

**Input**

```wolfram
s["Remainder"]
```

**Output**

```wolfram
PowerLogRemainder[1/x, 5 - 3 Sqrt[2], 0]
```

### Scope

<a id="gamma-and-exponential-growth"></a>
#### Gamma Products, Ratios, and Powers

Gamma products are supported when all variable Gamma arguments are eventually positive, at least one tends to infinity, and their combined logarithmic expansion is supported. Other positive Gamma arguments may have finite limits.

Fixed, symbolic, and varying powers must be exact and eventually real. Supply assumptions for symbolic parameters. Examples include `Gamma[x]^2`, `Gamma[x]^-2`, `Gamma[x]^Sqrt[2]`, `Gamma[x]^r` with `Assumptions -> Element[r, Reals]`, and `Gamma[x]^x`.

**Input**

```wolfram
s = AsymptoticExpansion[Gamma[x]^2, x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
2 Pi Exp[-2 x] x^(2 x - 1)
  (1 + 1/(6 x) + 1/(72 x^2) - 31/(6480 x^3) - 139/(155520 x^4))
```

**Input**

```wolfram
s = AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
3^(3 x - 1/2) x^(2 x) Exp[-2 x]
  (1 - 1/(18 x) + 1/(648 x^2) + 463/(174960 x^3)
     - 1867/(12597120 x^4))
```

**Input**

```wolfram
{s["RemainderPower"], s["ReturnedTermCount"], s["LogarithmicFunction"]}
```

**Output**

```wolfram
{5, 5, LogGamma[3 x] - LogGamma[x]}
```

The absolute remainder is the positive prefactor times `PowerLogRemainder[1/x, 5, 0]`. The displayed coefficients form a Poincare asymptotic expansion; convergence is not asserted.

**Input**

```wolfram
s = AsymptoticExpansion[Gamma[x]^x, x -> Infinity, SeriesTermGoal -> 3];
Normal[s]
```

**Output**

```wolfram
Exp[1/12] (Sqrt[2 Pi] x^(x - 1/2) Exp[-x])^x
  (1 - 1/(360 x^2) + 1447/(1814400 x^4))
```

Here the remainder power inside the prefactor is `6`; the three retained blocks have powers `0`, `2`, and `4`.

Exact recurrence cancellations can terminate before the requested count:

**Input**

```wolfram
s = AsymptoticExpansion[Gamma[x + 1]/Gamma[x], x -> Infinity,
  SeriesTermGoal -> 5];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{x, 0}
```

The following complete special functions use the same Gamma-product interface:

| Input | Associated Gamma expression |
| --- | --- |
| `Factorial[z]` | `Gamma[z + 1]` |
| `Binomial[n, k]` | `Gamma[n + 1]/(Gamma[k + 1] Gamma[n - k + 1])` |
| `Beta[a, b]` | `Gamma[a] Gamma[b]/Gamma[a + b]` |
| `Pochhammer[a, n]` | `Gamma[a + n]/Gamma[a]` |

The positivity and logarithmic-source requirements apply to the resulting factors. The original function is retained for refinement. Incomplete Gamma, incomplete Beta, and double factorials are outside this conversion.

For expansion of inverse functions on the increasing Gamma tail, see [Inverse Gamma and LogGamma Functions](#inverse-gamma-and-loggamma).

**Input**

```wolfram
s = AsymptoticExpansion[Binomial[2 x, x], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
4^x/Sqrt[Pi x]
  (1 - 1/(8 x) + 1/(128 x^2) + 5/(1024 x^3) - 21/(32768 x^4))
```

<a id="gamma-logarithms"></a>
#### Logarithms of Gamma Functions

Expand the real logarithm of Gamma directly:

**Input**

```wolfram
s = AsymptoticExpansion[Log[Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
x (Log[x] - 1) + (Log[2 Pi] - Log[x])/2
  + 1/(12 x) - 1/(360 x^3) + 1/(1260 x^5)
```

The five blocks have exponents `-1`, `0`, `1`, `3`, and `5` in the positive coordinate `1/x`. The complete polynomial in `Log[x]` at each exponent counts as one block. The remainder is `PowerLogRemainder[1/x, 7, 0]`, an absolute error of order `x^-7`.

`LogGamma[x]` gives the same expansion on this real branch. Supported logarithms of Gamma products, ratios, fixed or varying real powers, and the Gamma-related functions listed above use the same interface:

```wolfram
AsymptoticExpansion[LogGamma[x], x -> Infinity, SeriesTermGoal -> 5]
AsymptoticExpansion[Log[Gamma[x]^2], x -> Infinity, SeriesTermGoal -> 5]
AsymptoticExpansion[Log[Gamma[3 x]/Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 5]
AsymptoticExpansion[Log[Gamma[x]^x], x -> Infinity, SeriesTermGoal -> 5]
AsymptoticExpansion[Log[Binomial[2 x, x]], x -> Infinity,
  SeriesTermGoal -> 5]
```

Every variable Gamma argument must be eventually positive for this real logarithmic normalization. Gamma powers must be exact and eventually real, and any remaining ordinary multiplicative factor must be eventually positive. The resulting additive logarithmic expression must have a supported power-log expansion. Supply `Assumptions` when these properties depend on symbolic parameters. The logarithmic input does not require a Gamma factor to grow at the selected endpoint.

Exact Gamma recurrences can reduce the result to fewer blocks than requested:

**Input**

```wolfram
s = AsymptoticExpansion[Log[Gamma[x + 1]/Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 5];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{Log[x], 0}
```

An explicit cutoff uses the ordinary positive coordinate. The original source expression is retained for refinement:

```wolfram
s = AsymptoticExpansion[Log[Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 3];
SeriesRefine[s, 7]
```

Cutoff `7` retains all complete blocks strictly below exponent `7`, including the five blocks displayed above.

<a id="barnes-g-expansions"></a>
#### Barnes G Functions

Expand Barnes G at positive infinity:

**Input**

```wolfram
s = AsymptoticExpansion[BarnesG[x], x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
Exp[1/12] (2 Pi)^((x - 1)/2) Exp[x - 3 x^2/4]
  x^(x^2/2 - x + 5/12)/Glaisher
  (1 - 1/(12 x) - 1/(1440 x^2) + 157/(51840 x^3)
     + 65911/(87091200 x^4))
```

The five blocks have correction exponents `0`, `1`, `2`, `3`, and `4` in `1/x`. The absolute remainder is the positive prefactor times `PowerLogRemainder[1/x, 5, 0]`. `Glaisher` is Glaisher's constant, with `1/12 - Log[Glaisher] == Zeta'[-1]`. The logarithmic asymptotic formula uses the shifted argument of `BarnesG[z + 1]`. [DLMF 5.17.5](https://dlmf.nist.gov/5.17.E5), [DLMF 5.17.7](https://dlmf.nist.gov/5.17.E7).

Shifting the argument changes the correction blocks. For `BarnesG[x + 1]` they occur at even powers of `1/x`:

**Input**

```wolfram
s = AsymptoticExpansion[BarnesG[x + 1], x -> Infinity,
  SeriesTermGoal -> 3];
Normal[s]
```

**Output**

```wolfram
Exp[1/12] (2 Pi)^(x/2) Exp[-3 x^2/4]
  x^(x^2/2 - 1/12)/Glaisher
  (1 - 1/(240 x^2) + 269/(268800 x^4))
```

Here the relative remainder has power `6`. A five-block goal retains exponents `0`, `2`, `4`, `6`, and `8`, with relative remainder power `10`.

The real logarithm has an ordinary additive expansion:

**Input**

```wolfram
s = AsymptoticExpansion[Log[BarnesG[x]], x -> Infinity,
  SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
x^2 (Log[x]/2 - 3/4) + x (1 + Log[2 Pi]/2 - Log[x])
  + 5 Log[x]/12 - Log[2 Pi]/2 + 1/12 - Log[Glaisher]
  - 1/(12 x) - 1/(240 x^2)
```

These five complete logarithmic blocks have exponents `-2`, `-1`, `0`, `1`, and `2` in `1/x`; the absolute remainder is `PowerLogRemainder[1/x, 3, 0]`.

The package also accepts Wolfram Language's built-in [LogBarnesG](https://reference.wolfram.com/language/ref/LogBarnesG.html). On the admitted positive real arguments, `LogBarnesG[x]` and `Log[BarnesG[x]]` give the same expansion and remainder. The native function supports arbitrary-precision numerical evaluation:

```wolfram
AsymptoticExpansion[LogBarnesG[x], x -> Infinity, SeriesTermGoal -> 5]
N[LogBarnesG[1000], 60]
```

The same product interface admits fixed and varying real powers, positive scaled and shifted arguments, reciprocal coordinates, and mixed Gamma/Barnes products when their combined logarithmic expansion is supported:

```wolfram
AsymptoticExpansion[BarnesG[x]^2, x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[BarnesG[x]^x, x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[BarnesG[2 x + 3], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[BarnesG[1 + 1/x], x -> 0, SeriesTermGoal -> 3]
AsymptoticExpansion[BarnesG[x] Gamma[x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[Log[BarnesG[x]/Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 5]
```

Gamma and Barnes arguments must be eventually positive. Growing Barnes arguments must have a pure-power leading term. Powers must be exact and eventually real; supply `Assumptions` for symbolic parameters. A real logarithm additionally requires its ordinary multiplicative factor to be eventually positive. For a factored product, the properties `"BarnesFactors"` and `"GammaFactors"` record the factors involved, and `"ExpansionNature" -> "Poincare"` identifies the finite asymptotic expansion.

Shifted factors can simplify through the exact Barnes recurrence `BarnesG[x + 1] == Gamma[x] BarnesG[x]`. For example:

**Input**

```wolfram
s = AsymptoticExpansion[BarnesG[x + 1]/(Gamma[x] BarnesG[x]),
  x -> Infinity, SeriesTermGoal -> 5];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{1, 0}
```

`SeriesRefine` retains the original source expression and obtains additional correction blocks at the requested cutoff. Its cutoff is relative to the prefactor for a Barnes product and absolute in the local coordinate for its logarithm. The displayed asymptotic series does not assert convergence or provide a pointwise numerical error certificate.

For expansion of the increasing inverse on the source branch above three, see [Inverse Barnes G Functions](#barnes-inverse-expansions).

#### Elementary Exponential Products

Multiplicative exponentials and varying powers of positive bases can retain exact growing or decaying prefactors. At least one individual logarithmic source must grow faster in magnitude than the logarithm of the local coordinate. The combined logarithmic expansion must be supported.

**Input**

```wolfram
s = AsymptoticExpansion[Exp[x + 1/x], x -> Infinity, SeriesTermGoal -> 5];
Normal[s]
```

**Output**

```wolfram
Exp[x] (1 + 1/x + 1/(2 x^2) + 1/(6 x^3) + 1/(24 x^4))
```

`Exp[-x + 1/x]` has the same correction bracket and a decaying prefactor. An ordinary multiplicative factor must have a proved eventual nonzero real sign. The approximation retains its sign; its absolute remainder uses the magnitude of its prefactor.

`x^x` is an exact one-term factored result. `x^(x + 1/x)` has correction terms `Log[x]^k/(k! x^k)`. Shifted domains such as `Exp[Sqrt[x - 1] + 1/x]` need to be real only eventually.

`Exp[x]` at zero, `(1 + 1/x)^x` at infinity, and `1/(Exp[x^5] - 1)` at zero retain ordinary absolute cutoff semantics. A product admitted through individually large sources retains relative cutoffs even when those sources cancel. For example, `x^-5 (1 + x)^(1/x^2) Exp[-1/x]` at zero has prefactor `Exp[-1/2] x^-5`; cutoff two retains the bracket `1 + x/3` and has absolute remainder `O[x^-3]`.

#### Lambert and Exact Coordinate Transformations

Leading logarithmic and exponential inverse problems are selected automatically when supported.

**Input**

```wolfram
s = AsymptoticInverse[x Exp[x], {x, Infinity}, y, SeriesTermGoal -> 3];
Normal[s]
```

**Output**

```wolfram
Log[y] - Log[Log[y]] + Log[Log[y]]/Log[y]
```

This result uses the principal real Lambert branch. The inverse of `x Log[x]` at zero uses the lower real Lambert branch and approaches target zero from below. Inspect `"LambertBranch"`, `"LogarithmicVariable"`, `"Prefactor"`, and `"TargetDomain"` on a Lambert result.

Supported logarithmic cores include `a u^p (b + c Log[u])^q` and `u^p Q[Log[u]]`, where `u` is the positive source coordinate, `p` is nonzero, and `Q` is a polynomial. Exact parameters and sufficient real-branch assumptions are required. These families admit finite endpoints and both source infinities. Growing exponential cores include `a x^b Exp[c x^p]` at positive infinity. A general logarithmic polynomial need not have a closed-form `ProductLog` inverse.

```wolfram
AsymptoticInverse[x (Log[x]^2 + Log[x] + 1), {x, 0}, y,
  SeriesTermGoal -> 3]
AsymptoticInverse[x Log[x] + x^2, {x, 0}, y,
  SeriesTermGoal -> 3]
```

Higher source-power corrections to a logarithmic core, and finite power-log additions to a growing exponential core, can be smaller than every fixed logarithmic order. Such results record `"LeadingCoreOnly" -> True` and the omitted expression in `"BeyondLogarithmicOrders"`. Their logarithmic expansion does not resolve the separate exponential sectors. Numerical checks still compare with the original forward function.

Exact target transformations also handle inputs such as `x Exp[x^2 + x]`. Transformed results retain `"CoordinateSeries"` and `"CoordinateSubstitution"`.

Pure logarithmic source dependence uses an exact exponential source coordinate. Polynomial expressions and supported real powers of logarithms then reduce to an ordinary inverse problem. Source reconstruction by exponentiation requires an absolute argument error tending to zero. Exact repeated transformations can retain exact nested-exponential inverses, such as `Exp[-Exp[y]]`. Finite sums of exponentials at either source infinity admit exact real rates without a rational commensurability requirement.

```wolfram
AsymptoticInverse[Log[x]^2 + Log[x], {x, 0}, {y, 1}]
AsymptoticInverse[Exp[-x] + Exp[-2 x], {x, Infinity}, {y, 4}]
```

Source-coordinate results retain `"ReconstructedSeries"`, `"SourceCoordinateExpression"`, and `"SourceTransformExpression"`. Their residual checks the displayed reconstruction, including its truncation. An exact residual expression can be returned without an order claim when its ordering requires a larger coefficient algebra. Explicit declared input remainders require a separate source-coordinate transport contract.

**Input**

```wolfram
s = AsymptoticInverse[Exp[-1/x], {x, 0}, y, SeriesTermGoal -> 3];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{-1/Log[y], 0}
```

The real target branch is `0 < y < 1`.

<a id="inverse-function-expressions"></a>
#### Callable and Applied Inverse Functions

Use a source condition to identify an inverse branch:

```wolfram
AsymptoticExpansion[
  InverseFunction[Function[t,
    ConditionalExpression[t + t^2 (1 + Log[t]), t > 0]]][y],
  {y, 0, 4}]
```

Named parameters, named parameter lists, and slots follow ordinary `Function` scoping. A defined function symbol is accepted when its application produces a supported scalar body.

An inner `ConditionalExpression` restricts the original source. An outer condition restricts the expansion variable. Parameter-only assumptions remain parameter assumptions. Native evaluation of an inverse to `ArcSin`, a radical, or another closed form retains that closed form's branch.

If an unevaluated inverse operator admits more than one source branch, supply an explicit selection:

```wolfram
operator = InverseFunction[Function[t, t^2 + t^4 (1 + Log[t^2])]];
branches = Association[
  operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
s = AsymptoticExpansion[operator[y], {y, 0, 2},
  "InverseFunctionBranches" -> branches];
```

The key is the inverse operator without its target argument. Every selection must satisfy the retained source condition and requested limiting target. A branch option cannot change a native closed form that has already replaced the operator.

`InverseFunction[F, k, n][a1, ..., an]` solves for argument `k` of the scalar function `F`, using `ak` as the target. Other arguments remain parameters. Varying parameters are supported when the body has an established decomposition `A(x) F0(t) + B(x)` with nonzero `A(x)` eventually. Their variation is retained during composition.

Inverse nodes can occur in sums, products, powers, supported observables, and other inverse calls. Generic composition requires a compatible enclosing power-log coordinate. A direct node retains its inverse scale. `ProductLog[0, y]` and `ProductLog[-1, y]` have direct real-branch support when their argument is the expansion variable.

A fixed power of a direct Gamma or LogGamma inverse on a source branch at infinity retains the specialized inverse scale. See [Powers and Series Operations](#gamma-inverse-operations) for the supported forms and precision rules.

### Options

#### Selecting a Source Side

**Input**

```wolfram
s = AsymptoticInverse[x^2, {x, 0}, {y, 2}, Direction -> "FromBelow"];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{-Sqrt[y], 0}
```

#### Declaring Parameter Assumptions

```wolfram
AsymptoticExpansion[Gamma[a x], x -> Infinity,
  Assumptions -> a > 0, SeriesTermGoal -> 3]

AsymptoticExpansion[Gamma[x]^r, x -> Infinity,
  Assumptions -> Element[r, Reals], SeriesTermGoal -> 3]
```

Assumptions must justify the relevant signs, real branches, and exponent comparisons. Approximate data are not made exact by adding assumptions.

#### Symbolic Perturbation Depth

`"Truncation" -> "Depth"` retains all perturbation contributions through an inclusive integer depth and admits symbolic powers under sufficient assumptions. It uses `Method -> "Lagrange"`. It does not impose an ordering by numerical exponent.

**Input**

```wolfram
s = AsymptoticInverse[x + a x^(1 + p), {x, 0}, {y, 2},
  "Truncation" -> "Depth", Assumptions -> p > 0 && Element[a, Reals]];
Normal[s]
```

**Output**

```wolfram
y - a y^(1 + p) + a^2 (1 + p) y^(1 + 2 p)
```

#### Declared Input Precision

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3},
  "InputRemainder" -> {3, 0}];
SeriesRefine[s, 8]
```

The declaration limits the available inverse precision. Refinement beyond that limit returns `Failure["InsufficientInputOrder", ...]`. To change the mathematical input, construct a new expansion with the stronger justified input information.

<a id="inverse-gamma-and-loggamma"></a>
## Inverse Gamma and LogGamma Functions

### Basic Examples

Expand the real inverse of `Gamma` on the increasing source branch above two:

**Input**

```wolfram
s = AsymptoticExpansion[
  InverseFunction[
    x |-> ConditionalExpression[Gamma[x], x > 2]][z],
  z -> Infinity, SeriesTermGoal -> 5];
Normal[s]
```

The result retains the exact dominant inverse

```wolfram
X = Log[z]/ProductLog[Log[z]/E];
```

Here `ProductLog` uses its principal real branch. With `q = 1/Log[X]` and `c = Log[2 Pi]`, the five complete blocks have the form

```wolfram
X + a0 + a1/X + a2/X^2 + a3/X^3
```

The coefficient polynomials are

```wolfram
a0 = (1 - c q)/2;
a1 = q/24 - c^2 q^3/8;
a2 = c q^2 (1 + q - c^2 q^2 - 3 c^2 q^3)/48;
a3 = -q ((a0 - 1/2) a2 + a1^2/2
  + (-a0^2/2 + a0/2 - 1/12) a1
  + a0^2 (a0 - 1)^2/12 - 1/360);
```

Each polynomial is retained in full at its power of `1/X`. For example, the two summands of `a0` together count as one block. `SeriesTermGoal -> 5` counts the leading core and four correction blocks.

**Input**

```wolfram
{s["ReturnedTermCount"], s["RemainderPower"],
 s["RemainderInverseLogPower"]}
```

**Output**

```wolfram
{5, 4, 2}
```

In terms of `X`, the remainder descriptor is `PowerLogRemainder[1/X, 4, 0]/Log[X]^2`, corresponding to an absolute error of order `1/(X^4 Log[X]^2)`. The result is a finite Poincare asymptotic expansion. Its remainder descriptor does not specify a numerical error constant or a pointwise bound.

Use `AsymptoticInverse` to specify the source endpoint directly:

```wolfram
g = AsymptoticInverse[Gamma[x], {x, Infinity}, z,
  SeriesTermGoal -> 5];

lg = AsymptoticInverse[LogGamma[x], {x, Infinity}, z,
  SeriesTermGoal -> 5];
```

For `LogGamma`, the exact core is `z/ProductLog[z/E]`. The same coefficient polynomials apply with this core substituted for `X`.

### Details and Options

`AsymptoticInverse` selects the increasing tail through its source endpoint. In an `InverseFunction` expression, the condition `x > 2` identifies that branch. The weaker condition `x > 0` leaves two possible source limits for `Gamma[x] -> Infinity`: zero from above and positive infinity. Supply the stronger condition or an explicit `"InverseFunctionBranches"` selection.

An explicit cutoff is an exclusive exponent bound in `1/X`. For the source-point inverse, cutoff `4` retains the five blocks with exponents `-1`, `0`, `1`, `2`, and `3`:

```wolfram
AsymptoticInverse[Gamma[x], {x, Infinity}, {z, 4}]
```

| Property | Meaning for this result family |
| --- | --- |
| `"Kind"`, `"Scale"` | Both are `"GammaInverse"`. |
| `"CoreInverse"` | Exact Lambert core `X`. |
| `"CoreLogExpression"` | `Log[X]`. |
| `"Terms"` | Pairs `{beta, polynomial}` representing `X^-beta` times a polynomial in `"CoefficientVariable"`. |
| `"CoefficientSubstitution"` | Substitution of `1/Log[X]` for the coefficient variable. |
| `"CoefficientFrontier"`, `"FrontierTerm"` | First omitted complete polynomial block, before and after substitution. |
| `"RemainderInverseLogPower"` | Reciprocal-logarithmic power in the complete remainder descriptor. |
| `"TargetCoordinateExpression"` | Target of the equivalent `LogGamma` equation. |

The constructor uses `"Truncation" -> "Exponent"` and selects ordered Stirling reversion automatically. A declared additive `"InputRemainder"` is not supported by this constructor; `Automatic` and `None` are accepted. The Gamma and LogGamma forms of [AsymptoticSpecialInverse](#AsymptoticSpecialInverse) remain separate constructors with inclusive perturbation-marker depth. Their integer order does not count the complete blocks displayed here.

### Scope

Affine source arguments and fixed real nonzero powers of Gamma are supported, together with affine target transformations:

```wolfram
AsymptoticInverse[Gamma[2 x + 3], {x, Infinity}, z,
  SeriesTermGoal -> 3]

AsymptoticInverse[7 - 2 Gamma[x]^2, {x, Infinity}, z,
  SeriesTermGoal -> 3]

AsymptoticInverse[Gamma[3 - 2 x], {x, -Infinity}, z,
  SeriesTermGoal -> 3]
```

For `d + a Gamma[alpha x + beta]^r`, set `Y = Log[(z - d)/a]/r`. The Gamma argument approaches positive infinity and the original source is reconstructed from that argument by subtracting `beta` and dividing by `alpha`. The retained real target domain requires `(z - d)/a > 0` and `Y > 0`. Fixed parameters must have proved real values and the required nonzero signs; provide `Assumptions` for symbolic parameters.

A negative Gamma power can send an infinite source to a finite target. For example:

```wolfram
negativeReciprocal = AsymptoticInverse[-1/Gamma[x], {x, Infinity}, z,
  SeriesTermGoal -> 5];
```

Here `z` approaches zero from below, and the logarithmic target is `Y = -Log[-z]`. Affine LogGamma expressions are also admitted: `d + a LogGamma[alpha x + beta]` uses `Y = (z - d)/a` on the tail where `Y -> Infinity`.

<a id="gamma-inverse-operations"></a>
### Powers and Series Operations

Use `"Power"` to expand a fixed power of the source inverse:

```wolfram
square = AsymptoticInverse[Gamma[x], {x, Infinity}, z,
  "Power" -> 2, SeriesTermGoal -> 5];

reciprocal = AsymptoticInverse[Gamma[x], {x, Infinity}, z,
  "Power" -> -1, SeriesTermGoal -> 5];
```

The Gamma power inside the forward expression specifies the equation being inverted. The option `"Power"` specifies the observable of its source root. An observable power must be a nonzero exact real number; a source tending to negative infinity requires an integer power.

A fixed outer power of a direct applied inverse is also supported:

```wolfram
AsymptoticExpansion[
  InverseFunction[
    x |-> ConditionalExpression[Gamma[x], x > 2]][z]^2,
  z -> Infinity, SeriesTermGoal -> 5]
```

This direct power form applies to the admitted Gamma and LogGamma families at source infinity and uses the same complete-block convention.

Use the retained source to change the order or take a power of an existing result:

```wolfram
short = SeriesTruncate[g, 2];
long = SeriesRefine[short, 5];
powered = SeriesPower[g, 2];
```

`SeriesTruncate` discards complete blocks at or above its exclusive core-power cutoff. `SeriesRefine[s, h]` recomputes the expansion from its source equation at cutoff `h`, preserving the selected branch. The `"AdditionalBlocks"` association form is limited to ordinary power-log inverses; request a larger cutoff or call the Gamma constructor again with `SeriesTermGoal`.

`SeriesPower` transports the operand's remainder. An explicit larger cutoff cannot improve the precision supplied by that operand. Its result can be refined from the retained source equation. Noninteger powers require a positive source branch; only integer exponents are admitted on a negative source branch.

Addition and multiplication of compatible results are supported through ordinary arithmetic, `SeriesAdd`, and `SeriesMultiply`. When an operation cannot use a common ordered coefficient scale, it returns a [composite result](#composite-series-results), retaining separate error bounds. Such a result has no single core-power cutoff. The specialized power operation above retains the Gamma inverse scale.

`Log`, `Exp`, `Abs`, `Sin`, and `Cos` can return composite bounds when their real-branch and error conditions are established; `SeriesLog` and `SeriesExp` use the same fallback. These operations retain a finite function of the approximation and a transported bound, without asserting an ordered Gamma inverse expansion for that function. See [Composite Results](#composite-series-results).

Generic `SeriesCompose`, `SeriesObservable`, and `SeriesDifferentiate` do not accept this inverse coefficient scale. Composite results do not acquire inverse-checking or refinement support merely by retaining their operands. Arithmetic on `Normal[s]` drops the remainder.

### Residual and Numerical Checks

Check the cancellation in the normalized finite Stirling equation:

```wolfram
residual = InverseResidual[g];
residual["ZeroBelowCutoff"]
```

The normalized residual is `(LogGamma[approximation] - Log[z])/(X Log[X])` for the unshifted Gamma example. `InverseResidual[g, h]` uses an exclusive positive cutoff in powers of `1/X` for this normalized equation. Read `"Scope"`, `"ModelRemainderScaleExpression"`, and `"ExactEquationResidualExpression"` for the distinction between its computed finite-model residual and the original equation. `"ZeroBelowCutoff" -> True` establishes cancellation at the requested finite order; the finite Stirling model still has its recorded remainder. This helper requires the source-point observable `"Power" -> 1`.

Compare with a numerical solution of the original logarithmic Gamma equation:

```wolfram
check = InverseNumericalCheck[g, Exp[10000], WorkingPrecision -> 100];
{check["ReferenceRoot"], check["ReferenceObservable"],
 check["Error"], check["Ratio"]}
```

The calculation uses the equivalent `LogGamma` equation and verifies the retained source and target conditions. Powered observables are supported: `"ReferenceRoot"` is the source root, while `"ReferenceObservable"` is its requested power. `"Ratio"` divides the absolute approximation error by the recorded remainder scale. Supply an exact target or at least the requested working precision, and resolve fixed parameters numerically.

The returned numerical check has `"Certified" -> False`. `InverseCertificate` and certificate-based tolerance refinement are not supported for this inverse-Gamma result family.

<a id="barnes-inverse-expansions"></a>
## Inverse Barnes G Functions

### Basic Examples

Expand the inverse of Barnes G on its increasing real source branch above three:

**Input**

```wolfram
s = AsymptoticExpansion[
  InverseFunction[
    x |-> ConditionalExpression[BarnesG[x], x > 3]][z],
  z -> Infinity, SeriesTermGoal -> 3];
Normal[s]
```

The exact dominant inverse and its coefficient coordinate are

```wolfram
X = Sqrt[4 Log[z]/ProductLog[4 Log[z]/E^3]];
q = 1/(Log[X] - 1);
```

`ProductLog` uses the principal real branch. With `c = Log[2 Pi]` and `a = Log[Glaisher]`, the finite approximation has three complete blocks:

```wolfram
X + (1 - c q/2) + (1/12 + a q + c^2 q^2/8 - c^2 q^3/8)/X
```

The blocks have exponents `-1`, `0`, and `1` in `1/X`. Each retains its entire polynomial in `q`; the constant translation by one belongs to the second block. The remainder descriptor is `PowerLogRemainder[1/X, 2, 0]/(Log[X] - 1)^3`, corresponding to an absolute error of order `1/(X^2 (Log[X] - 1)^3)`.

Specify the source endpoint directly, or invert the real logarithm of Barnes G:

```wolfram
g = AsymptoticInverse[BarnesG[x], {x, Infinity}, z,
  SeriesTermGoal -> 3];

lg = AsymptoticInverse[LogBarnesG[x], {x, Infinity}, z,
  SeriesTermGoal -> 3];
```

For the logarithmic forward function, `LogBarnesG[x]` and `Log[BarnesG[x]]` are admitted equivalent forms on the positive real branch. Their logarithmic target coordinate is `Y = z`, and their dominant inverse is `Sqrt[4 z/ProductLog[4 z/E^3]]`. The same coefficient polynomials apply with this core in place of `X`.

<a id="log-barnes-inverse"></a>
Expand a directly applied inverse of the native logarithm:

```wolfram
sl = AsymptoticExpansion[
  InverseFunction[
    x |-> ConditionalExpression[LogBarnesG[x], x > 3]][z],
  z -> Infinity, SeriesTermGoal -> 3];
Normal[sl]
```

Its three complete blocks have the form displayed above with

```wolfram
X = Sqrt[4 z/ProductLog[4 z/E^3]];
q = 1/(Log[X] - 1);
```

The result retains `"Scale" -> "BarnesGInverse"` and the remainder `PowerLogRemainder[1/X, 2, 0]/(Log[X] - 1)^3`. The original native source expression and its branch are retained for refinement.

### Details and Options

The condition `x > 3` selects an interval on which Barnes G is strictly increasing, with target `z > 1`. For `LogBarnesG` on the same source interval, the target is `z > 0`. Conditions attached to a callable inverse must establish the admitted source branch. Additional source and target conditions are preserved during refinement and checked by the numerical helper.

With a broader source condition, select the endpoint explicitly:

```wolfram
inv = InverseFunction[t |-> ConditionalExpression[BarnesG[t], t > 0]];
AsymptoticExpansion[inv[z], z -> Infinity, SeriesTermGoal -> 3,
  "InverseFunctionBranches" -> <|
    inv -> <|"SourcePoint" -> Infinity, "Direction" -> "FromBelow"|>|>]
```

This selects the source tail above three. The branch record retains the original condition separately and verifies that it holds eventually at the selected endpoint.

| Property | Meaning for this result family |
| --- | --- |
| `"Kind"`, `"Scale"` | Both are `"BarnesGInverse"`. |
| `"CoreInverse"` | Exact Lambert core `X`. |
| `"CoreLogExpression"` | `Log[X] - 1`. |
| `"CoefficientSubstitution"` | Substitution of `1/(Log[X] - 1)` for the coefficient variable. |
| `"Terms"`, `"CoefficientFrontier"` | Complete retained and first omitted polynomial blocks in the coefficient variable. |
| `"RemainderPower"`, `"RemainderInverseLogPower"` | For the three-block request above, `2` and `3`. |
| `"TargetCoordinateExpression"` | Target of the equivalent real `LogBarnesG[...]` equation. |

The cutoff is exclusive in powers of `1/X`: cutoff `2` retains the three blocks displayed above. `SeriesTermGoal` counts complete nonzero blocks after cancellation. The inverse expansion is justified at each fixed order by a finite Barnes logarithmic model; it does not assert convergence or a pointwise error constant.

### Scope

Affine source arguments, fixed real nonzero Barnes powers, and affine target changes use the same constructor:

```wolfram
AsymptoticInverse[BarnesG[2 x + 3], {x, Infinity}, z,
  SeriesTermGoal -> 3]

AsymptoticInverse[7 - 2 BarnesG[x]^2, {x, Infinity}, z,
  SeriesTermGoal -> 3]

AsymptoticInverse[BarnesG[3 - 2 x], {x, -Infinity}, z,
  SeriesTermGoal -> 3]

AsymptoticInverse[-1/BarnesG[x], {x, Infinity}, z,
  SeriesTermGoal -> 3]
```

For `d + a BarnesG[alpha x + beta]^r`, the logarithmic target is `Y = Log[(z - d)/a]/r`, with `(z - d)/a > 0`, `Y > 0`, and source condition `alpha x + beta > 3`. The original source is reconstructed from the Barnes argument by subtracting `beta` and dividing by `alpha`. Fixed parameters must have proved real values and the required nonzero signs; use `Assumptions` for symbolic parameters.

The last example approaches target zero from below and uses `Y = -Log[-z]`. Affine logarithmic forward expressions `d + a LogBarnesG[alpha x + beta]`, or their admitted `Log[BarnesG[...]]` form, use `Y = (z - d)/a`.

### Powers, Refinement, and Checks

The option `"Power"` expands a fixed power of the original source root:

```wolfram
AsymptoticInverse[BarnesG[x], {x, Infinity}, z,
  "Power" -> -1, SeriesTermGoal -> 3]

short = SeriesTruncate[g, 1];
long = SeriesRefine[short, 3];
powered = SeriesPower[g, 2];

AsymptoticExpansion[
  InverseFunction[t |-> ConditionalExpression[BarnesG[t], t > 3]][z]^2,
  z -> Infinity, SeriesTermGoal -> 3]
```

An observable power must be a nonzero exact real number, and a negative source branch requires an integer power. `SeriesPower` propagates the operand remainder; a larger requested cutoff cannot restore precision lost in that operand. Cutoff-based `SeriesRefine` can obtain more information from the retained source equation. The `"AdditionalBlocks"` request form is limited to ordinary power-log inverses.

`SeriesPower[g, 0]` returns the exact constant one while retaining the target-domain condition.

Check the source-point inverse with a formal residual or a numerical reference:

```wolfram
residual = InverseResidual[g];
residual["ZeroBelowCutoff"]

check = InverseNumericalCheck[g, Exp[1000], WorkingPrecision -> 60];
{check["ReferenceRoot"], check["ReferenceObservable"], check["Error"]}
```

The formal residual uses the finite logarithmic Barnes model, normalized by `X^2 (Log[X] - 1)`. Read its `"Scope"` and separate model remainder. This helper requires `"Power" -> 1`; cancellation below its stated cutoff does not make the truncated model exact.

The numerical check solves the original logarithmic Barnes equation on the retained real branch and also supports powered source observables. It evaluates the exact logarithmic phase with native `LogBarnesG` on the positive Barnes branch. Supply an exact target or sufficient input precision and resolve fixed parameters numerically. Its `"Certified"` property is `False`.

A native logarithmic target permits a comparison with a known source value:

```wolfram
checkLog = InverseNumericalCheck[lg, LogBarnesG[1000],
  WorkingPrecision -> 60];
{checkLog["ReferenceRoot"], checkLog["Error"]}
```

Addition and multiplication of compatible results are supported through ordinary arithmetic, `SeriesAdd`, and `SeriesMultiply`. Operations without a common ordered coefficient scale return a [composite result](#composite-series-results), preserving separate errors. The specialized power operation above retains the Barnes inverse scale.

`Log`, `Exp`, `Abs`, `Sin`, and `Cos` can return composite bounds under their real-branch and error conditions; `SeriesLog` and `SeriesExp` use the same fallback. See [Composite Results](#composite-series-results). Generic composition, arbitrary observables, and differentiation remain unsupported for this inverse coefficient scale. Composite results do not acquire inverse residual, numerical-check, or refinement support merely by retaining their operands. Interval certification and certificate-based tolerance refinement are also unsupported. Arithmetic on `Normal[s]` drops the remainder.

<a id="series-operations"></a>
## Series Arithmetic and Normalization

Arithmetic on a `PowerLogSeries` transports its remainder together with its finite expression. Operands must have compatible variables, endpoints, approach sides, and real branch conditions. Requested precision is limited by the available operand precision.

| Task | Use |
| --- | --- |
| Combine expansions with the available precision | Ordinary `+`, `-`, `*`, `/`, and supported real powers. |
| Normalize a compound expression with a final cutoff | `SeriesNormalize[expr, "Cutoff" -> h]`. |
| Apply one operation with explicit options | `SeriesAdd`, `SeriesMultiply`, `SeriesPower`, `SeriesLog`, or `SeriesExp`. |
| Discard known blocks | `SeriesTruncate[s, h]`. |
| Obtain more coefficients from a supported retained source | `SeriesRefine[s, h]`. |
| Work with the finite expression alone | `Normal[s]`. |

<a id="ordinary-series-arithmetic"></a>
### Ordinary Arithmetic

| Form | Operation |
| --- | --- |
| `s + t`, `s - t` | Addition or subtraction, including both operand remainders. |
| `s t` | Multiplication, including the products of finite parts and errors. |
| `s/t` | A reciprocal and a product, with the required nonzero denominator branch. |
| `s^r` | A fixed exact real numeric power. Noninteger powers require a proved positive branch. |
| `s^e`, `a^s` | A supported varying power, using the real logarithm and exponential calculus. |

**Input**

```wolfram
s = AsymptoticExpansion[Exp[x], {x, 0, 5}];
t = AsymptoticExpansion[Sin[x], {x, 0, 5}];
{s + t, s - t, s t, s/t, s^(1/2)}
```

Varying exponents are handled through `Exp[exponent Log[base]]` when the positive-base branch and each intermediate remainder condition can be established. The exponent may depend on the expansion variable or itself be a series. Fixed exact real numeric powers use the direct power rules.

```wolfram
2^t
s^x
SeriesNormalize[s^t, "Cutoff" -> 4]
```

A regular Wolfram Language expression may replace either arithmetic operand. It can depend on the expansion variable. On a common ordered scale, its expansion is computed in the recorded local coordinate with enough precision for the operation; it is not treated as a constant coefficient.

```wolfram
s + Sin[x]
s/(1 + x)
SeriesAdd[s, Sin[x]]
SeriesMultiply[s, 1 + x]
```

The unary forms `Sin[s]`, `Cos[s]`, `Tan[s]`, `Sinh[s]`, `Cosh[s]`, `Tanh[s]`, `ArcSin[s]`, `ArcCos[s]`, and `ArcTan[s]` use the regular observable calculus when the argument tends to an admissible finite real value. `Abs[s]`, `Log[s]`, and `Exp[s]` use their corresponding sign, branch, and remainder rules. When no ordered expansion is available, `Abs`, `Sin`, `Cos`, `Log`, and `Exp` can instead return the [composite bounds](#composite-series-results) described below. This does not assert an ordered expansion at every pole, branch point, or infinite argument.

```wolfram
Sin[t]
Exp[t]
Log[s]
```

<a id="SeriesNormalize"></a>
### SeriesNormalize

| Form | Result |
| --- | --- |
| `SeriesNormalize[expr]` | Normalize supported arithmetic and functions containing series objects, retaining their errors. |
| `SeriesNormalize[expr, "Cutoff" -> h]` | Apply the exclusive cutoff `h` to the normalized result in its recorded scale. |
| `SeriesNormalize[s]` | Return an already normalized series unchanged. |

Options are `"Cutoff" -> Automatic` and `"MaxTerms" -> 20000`. An explicit cutoff must be an exact real number. It applies to the final result; intermediate operands are not independently truncated at that cutoff. Normalization can increase the working order of newly formed regular and nonlinear expressions when cancellation or a later reciprocal needs more terms. It does not call `SeriesRefine` on the supplied series, improve an unknown operand remainder, or recover coefficients discarded before the call.

**Input**

```wolfram
s = AsymptoticExpansion[Exp[x], {x, 0, 5}];
t = AsymptoticExpansion[Sin[x], {x, 0, 5}];
SeriesNormalize[(s + Sin[x])/(1 + x), "Cutoff" -> 4]
SeriesNormalize[Exp[t] + Log[s], "Cutoff" -> 4]
```

`SeriesNormalize` has attribute `HoldAllComplete`. It resolves stored symbol values, including delayed aliases, while keeping their expression structure held for normalization. A denominator is therefore checked before native cancellation can remove it from the supplied expression. For example:

```wolfram
ratio := (s + Sin[x])/(1 + x);
SeriesNormalize[ratio, "Cutoff" -> 4]
```

An ordinary immediate assignment has already evaluated its right-hand side. The normalizer can use that stored value, but cannot recover terms or syntax removed during the assignment. Expressions without series objects retain ordinary Wolfram Language evaluation.

Cancellation inside a newly formed expression can require a larger intermediate order:

```wolfram
u = AsymptoticExpansion[x, {x, 0, 3}];
SeriesNormalize[1/(Exp[u] - 1 - u), "Cutoff" -> 3]
```

Here `u` is exact. The normalizer can compute more terms of the exponential and its reciprocal without refining `u`. With an uncertain input, the propagated input remainder still limits the result.

An explicit cutoff is unavailable for a composite result, because its errors may use different coordinates. Truncate the operands in their own scales before combining them when that is the intended loss of information.

<a id="composite-series-results"></a>
### Composite Results

When an arithmetic operation or a supported unary function cannot use one ordered coefficient scale, compatible operands can produce a result with `"Scale" -> "Composite"`. Its finite expression is retained, and its remainder keeps the separate input error scales. The operands must have the same expansion variable, endpoint, and real approach side, with compatible domains.

For example, Gamma and Barnes inverse expansions can be combined on their common positive target approach:

```wolfram
g = AsymptoticInverse[Gamma[x], {x, Infinity}, z,
  SeriesTermGoal -> 5];
b = AsymptoticInverse[BarnesG[x], {x, Infinity}, z,
  SeriesTermGoal -> 3];
c = g + b;
{c["Scale"], Normal[c], c["Remainder"]}
```

If the finite approximations are `a` and `b`, with respective errors `O[R]` and `O[S]`, their sum has error `O[R + S]` and their product has error `O[Abs[a] S + Abs[b] R + R S]`. Canceling terms in the finite expression does not cancel these unknown errors.

Positive integer powers use the finite binomial error bound, without requiring a nonzero finite approximation or a small relative error. In particular, squaring a pure remainder `O[R]` gives a pure remainder `O[R^2]`. A reciprocal requires an eventually nonzero approximation with an error proved smaller than that approximation; a pure remainder cannot supply a denominator. Noninteger powers also require a proved positive branch. A fractional power of a pure remainder is declined because its value bound alone does not establish that branch.

The following unary operations use conservative bounds for a real represented function `e + O[R]`, where `R` is the nonnegative error scale:

| Operation | Required condition | Finite expression and error |
| --- | --- | --- |
| `Log[s]`, `SeriesLog[s]` | `e > 0` eventually and `R/Abs[e] -> 0`. | `Log[e] + O[R/Abs[e]]`. |
| `Exp[s]`, `SeriesExp[s]` | `e` is eventually real and `R -> 0`. | `Exp[e] + O[Exp[e] R]`. |
| `Abs[s]` | Real branch. | `Abs[e] + O[R]`. |
| `Sin[s]`, `Cos[s]` | Real branch. | `Sin[e] + O[R]` or `Cos[e] + O[R]`. |

The `Abs`, `Sin`, and `Cos` bounds use their real Lipschitz inequalities and do not require a finite limiting argument or a vanishing error. They need not identify a leading asymptotic term. The logarithm uses a vanishing relative error; the exponential requires a vanishing absolute error. An explicit cutoff remains unavailable for these composite results.

Read `"RemainderScaleExpression"` for the resulting asymptotic bound and `"TargetDomain"` for its retained domain. This is an asymptotic assertion with an unspecified constant, not a pointwise numerical certificate. A composite result has no single exponent cutoff, native `SeriesData`, or general refinement, composition, differentiation, or inverse-checking contract. More information can be obtained by refining supported source operands and combining them again.

### Precision and Evaluation Order

Division, negative powers, and multiplication by a singular factor can reduce absolute precision. Requesting a final cutoff does not create missing input coefficients. If subtraction leaves only a remainder, more source terms may be needed before its sign or reciprocal can be determined.

The order of truncation matters. Truncating `x^2 + x^3` at cutoff `2` discards both known terms. Dividing that truncated result by `x` cannot recover them. Dividing the original expression by `x` before truncating at cutoff `2` retains the term `x`. Use `SeriesNormalize` to apply one final cutoff to the compound expression.

Equal finite expressions do not establish equal represented functions. An expansion of `Sin[x]` through order `O[x^3]` and the exact expression `x` have the same finite part, but their difference still has an unknown `O[x^3]` tail at that precision. Series operations use conservative error transport; repeated operands do not guarantee cancellation of their recorded remainders.

Ordinary Wolfram Language arithmetic may simplify identities before a series operation sees them. Such simplification does not prove an eventual nonzero branch or restore discarded precision. Use the held `SeriesNormalize` form to check a supplied quotient before cancellation. See the Wolfram Language documentation for [Times](https://reference.wolfram.com/language/ref/Times.html) and [HoldAllComplete](https://reference.wolfram.com/language/ref/HoldAllComplete.html).

Most explicit operations below accept `"Cutoff" -> Automatic` and `"MaxTerms" -> 20000`.

<a id="SeriesAdd"></a>
### SeriesAdd

`SeriesAdd[s, t]` adds compatible expansions. An exact real scalar or a supported regular expression in the expansion variable may replace either operand. It uses the same operand promotion and composite fallback as ordinary addition. An explicit cutoff is supported only when the result has an ordered scale.

<a id="SeriesMultiply"></a>
### SeriesMultiply

`SeriesMultiply[s, t]` multiplies compatible expansions. An exact real scalar or a supported regular expression in the expansion variable may replace either operand. It uses the same operand promotion and composite fallback as ordinary multiplication, including uncertainty from both operands. An explicit cutoff is supported only when the result has an ordered scale.

<a id="SeriesPower"></a>
### SeriesPower

`SeriesPower[s, r]` takes a power using the same dispatch and remainder rules as `s^r`. A fixed exponent must be an exact real numeric value. Supported varying exponents use the real logarithm and exponential calculus. `SeriesPower[s, r, h]` supplies an explicit cutoff. Noninteger and varying powers require the appropriate positive-base branch. Reciprocal powers can reduce absolute precision.

An admissible power of a composite result retains a composite error bound. Such a result does not support an explicit cutoff.

The constructor's specialized Gamma power normalization has its own symbolic-parameter and varying-power admission rules; success there does not guarantee that the same form follows from an existing series at its available precision.

For Gamma and LogGamma inverse results, powers retain the specialized coefficient scale and propagate the operand remainder. See [Powers and Series Operations](#gamma-inverse-operations).

<a id="SeriesLog"></a>
### SeriesLog

`SeriesLog[s]` takes an eventually positive real logarithm, using the same dispatch as `Log[s]`. `SeriesLog[s, h]` supplies a cutoff for an ordered result. The logarithm of an exact prefactor is included in the result. A composite fallback requires the error to be proved smaller than the positive finite approximation and does not accept an explicit cutoff.

**Input**

```wolfram
s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
Normal[SeriesLog[s, 4]]
```

**Output**

```wolfram
Log[x] + x - x^2/2 + x^3/3
```

<a id="SeriesExp"></a>
### SeriesExp

`SeriesExp[s]` exponentiates an expansion, using the same dispatch as `Exp[s]`. `SeriesExp[s, h]` supplies a cutoff for an ordered result. The absolute remainder of the argument must tend to zero. Nonvanishing terms in an ordered argument are retained in an exact prefactor. A composite fallback retains `Exp[Normal[s]]` and multiplies the input error scale by that factor; it does not accept an explicit cutoff.

**Input**

```wolfram
s = AsymptoticExpansion[1/x + Log[x] + x, {x, 0, 5}];
Normal[SeriesExp[s, 4]]
```

**Output**

```wolfram
x Exp[1/x] (1 + x + x^2/2 + x^3/6)
```

<a id="SeriesCompose"></a>
### SeriesCompose

`SeriesCompose[outer, inner]` substitutes the inner expansion into the outer expansion. It transports both remainders and checks the inner limit and source side. The variables may differ.

**Input**

```wolfram
outer = AsymptoticExpansion[Sin[x], {x, 0, 5}];
inner = AsymptoticExpansion[y^2 + y^3, {y, 0, 7}];
Normal[SeriesCompose[outer, inner, "Cutoff" -> 8]]
```

**Output**

```wolfram
y^2 + y^3 - y^6/6 - y^7/2
```

<a id="SeriesObservable"></a>
### SeriesObservable

`SeriesObservable[s, expr, z]` substitutes the expansion into the placeholder `z` in a supported real expression. It accepts `"InverseFunctionBranches" -> Automatic` in addition to the common operation options.

**Input**

```wolfram
s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
Normal[SeriesObservable[s, Sin[z], z, "Cutoff" -> 4]]
```

**Output**

```wolfram
x + x^2 - x^3/6
```

<a id="SeriesTruncate"></a>
### SeriesTruncate

`SeriesTruncate[s, h]` discards complete blocks at or above the exclusive cutoff `h`. Its only option is `"MaxTerms" -> 20000`. Raising a truncation cutoff cannot restore discarded coefficients.

<a id="SeriesRefine"></a>
### SeriesRefine

| Form | Result |
| --- | --- |
| `SeriesRefine[s, h]` | New cutoff for a supported result. An ordinary inverse with `"Truncation" -> "Depth"` uses an integer perturbation depth. |
| `SeriesRefine[s, <|"AdditionalBlocks" -> n|>]` | Additional complete nonzero blocks of an ordinary exponent-truncated inverse. |
| `SeriesRefine[s, <|"Target" -> y1, "TargetError" -> eps, "Interval" -> {lo, hi}|>]` | Numerical root certificate association. |
| `SeriesRefine[s, <|"Target" -> y1, "RelativeError" -> tau, "Interval" -> {lo, hi}|>]` | Numerical certificate with a relative root-accuracy request. |

Options are `"MaxTerms" -> 20000` and `"MaxRefinements" -> 128`. A tolerance request also accepts the options of [InverseCertificate](#InverseCertificate) as association keys. Do not mix `"AdditionalBlocks"` with a numerical request.

Refinement preserves the original function, assumptions, selected branch, and declared input precision. Exact terminating results can stop before an additional-block goal. A numerical request returns a certificate for the source root; it does not replace the symbolic remainder with a numerical tolerance.

Special-function adapters replay their own order convention. For standalone exact-core, exponential-core, flat, and Fourier constructors, request additional terms by calling the corresponding constructor again; general `SeriesRefine` support is not asserted for every specialized result.

**Input**

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 2}];
Normal[SeriesRefine[s, 5]]
```

**Output**

```wolfram
y - y^2 + 2 y^3 - 5 y^4
```

A failed additional-block request can include `"BestExpansion"` in its failure data. The properties `"GoalReached"` and `"ExactTermination"` in `"RefinementRequest"` distinguish satisfying the count from reaching an exact finite result.

<a id="SeriesDifferentiate"></a>
### SeriesDifferentiate

`SeriesDifferentiate[s]` differentiates once; `SeriesDifferentiate[s, n]` differentiates `n` times. Options are `"Cutoff" -> Automatic`, `"MaxTerms" -> 20000`, and `"RemainderDerivativeOrder" -> Automatic`.

A value-only Big-O remainder does not establish a derivative remainder. Supply `"RemainderDerivativeOrder" -> n` only when the corresponding derivative bounds are known. Exact expressions and specialized analytic remainder contracts can supply the required information automatically.

## Applications

<a id="InverseResidual"></a>
### InverseResidual

`InverseResidual[s]` checks composition of the retained forward model with the finite inverse. `InverseResidual[s, h]` supplies a relative residual cutoff in the recorded uniformizing coordinate. The option is `"MaxTerms" -> 200000`.

**Input**

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
InverseResidual[s]["ZeroBelowCutoff"]
```

**Output**

```wolfram
True
```

Read the returned `"Scope"` when checking a transformed, logarithmic, Fourier, or other specialized result. A residual calculation checks the named equation and truncation. It does not evaluate unknown terms represented only by a declared input remainder.

<a id="InverseNumericalCheck"></a>
### InverseNumericalCheck

`InverseNumericalCheck[s, y1]` compares the finite inverse with a numerical root of the retained original equation on its selected branch. Its option is `WorkingPrecision -> 50`.

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
check = InverseNumericalCheck[s, 1/100, WorkingPrecision -> 60];
check["ReferenceRoot"]
check["ReferenceObservable"]
check["Error"]
```

`"ReferenceRoot"` is the numerical source root. `"ReferenceObservable"` is the source observable requested by `"Power"`. `"Error"` compares that observable with the finite approximation. `"ExactInverse"` is a compatibility alias for the numerical reference root.

Use exact targets or targets with sufficient input precision. Exact target offsets are subtracted before numerical evaluation. The operation also supports the admitted transformed, logarithmic, Fourier, flat, core, and special inverse families. Its output is numerical evidence, not an interval certificate.

<a id="InverseCertificate"></a>
### InverseCertificate

`InverseCertificate[s, y1, "Interval" -> {lo, hi}]` attempts to certify a unique real source root in a verification interval. Successful output is an association with a rational center, rational root enclosure, and certified error bounds.

| Option | Default | Meaning |
| --- | --- | --- |
| `"Interval"` | `Automatic` | Verification interval. Supply exact rational endpoints for an explicit request. |
| `"Center"` | `Automatic` | Initial or fixed rational approximation. An explicitly supplied center remains fixed. |
| `"TargetError"` | `Automatic` | Absolute error goal for the returned center. |
| `"RelativeError"` | `Automatic` | Relative error goal using a proved root-magnitude bound. |
| `WorkingPrecision` | `50` | Precision used in choosing numerical seeds. |
| `"EnclosureOrder"` | `Automatic` | Order used for elementary-function enclosures. |
| `"MaxRefinements"` | `6` | Maximum certificate refinement steps. |
| `"RefineExpansion"` | `True` | Allow expansion refinement when selecting a center. |
| `"ExponentMagnitudeLimit"` | `10000` | Bound on exponential arguments handled by the enclosure arithmetic. |

**Input**

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
c = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5},
  "TargetError" -> 10^-12];
{c["Certified"], c["CertifiedErrorBound"] <= 10^-12}
```

**Output**

```wolfram
{True, True}
```

`c["Center"]` and `c["RootEnclosure"]` give the actual rational approximation and enclosure. When both tolerances are given, the accuracy request is `Abs[center - root] <= Max[eps, tau Abs[root]]`. A zero root needs an absolute fallback. A fixed center that cannot meet the requested accuracy can return `Failure["AccuracyFloor", ...]`.

The certificate concerns the stored explicit equation within the supplied interval. It does not establish a global inverse branch or enclose unspecified terms represented only by an input remainder. All retained source conditions must hold throughout the closed verification interval. A strict source condition therefore also constrains its endpoints.

<a id="PowerLogModel"></a>
### PowerLogModel

`PowerLogModel[f, {x, x0}]` returns an association describing a finite normalized forward model. `PowerLogModel[f, x]` uses `x0 = 0`. Options are `Assumptions -> True`, `Direction -> Automatic`, and `"MaxTerms" -> 20000`. An input requiring an infinite forward expansion is outside this model constructor's scope.

Inspect `"LeadingPower"`, `"LeadingCoefficient"`, `"Gaps"`, `"Polynomials"`, and `"LogVariable"` to identify the correction variables used by a coefficient request.

<a id="InverseExpansionCoefficient"></a>
### InverseExpansionCoefficient

`InverseExpansionCoefficient[s, {k1, k2, ...}]` returns the exact block associated with an ordinary inverse multi-index. A `PowerLogModel` association may replace `s`; for that form, `"Power" -> 1` selects the observable.

Give one nonnegative integer per model gap. Returned fields include `"Weight"`, `"Exponent"`, `"Coefficient"`, and `"UniformizerExponent"`. A multi-index contribution is not necessarily a complete displayed block: several contributions can have the same weight. Lambert expansions expose their coefficients through `"Terms"` instead.

<a id="PerturbativeInverse"></a>
### PerturbativeInverse

`PerturbativeInverse[phi, h, {x, y}, n]` generates perturbation formulas using an exact inverse core `phi`. `PerturbativeInverse[h, {x, y}, n]` uses the identity core. It has no options.

This function returns a formula. It does not attach asymptotic ordering or a remainder contract. Use an exact-core constructor when the supported problem requires those properties.

<a id="AsymptoticCoreInverse"></a>
## AsymptoticCoreInverse

`AsymptoticCoreInverse[core, perturbation, {x, x0}, {y, n}]` retains an exact inverse of `core` and computes corrections through inclusive marker degree `n`.

The core and perturbation must be supported finite power-log expressions. The core must have nonzero leading source power, and every perturbation power must be strictly higher. Automatic cores include monomials, affine logarithmic powers, and supported divergent power-plus-log expressions.

| Option | Default |
| --- | --- |
| `Assumptions` | `True` |
| `Direction` | `Automatic` |
| `"Power"` | `1` |
| `"CoreInverse"` | `Automatic` |
| `"InputRemainder"` | `None` |
| `"MaxTerms"` | `20000` |
| `"CoreCheckTimeConstraint"` | `3` |
| `"SourceRadius"` | `1/E` |

`"CoreInverse" -> phi` supplies another exact core inverse whose branch identity must be established. `"CoreCheckTimeConstraint"` bounds this check. `"SourceRadius"` restricts the source neighborhood used for the core contract. `"Power"` follows the ordinary inverse observable convention. A declared input remainder needs matching derivative control.

**Input**

```wolfram
s = AsymptoticCoreInverse[x, x^2, {x, 0}, {y, 2}];
{Normal[s], s["FirstOmittedMarkerTerm"]}
```

**Output**

```wolfram
{y - y^2 + 2 y^3, -5 y^4}
```

For a logarithmic core, inspect `"CoreInverse"`, `"MarkerTerms"`, and `"Remainder"`:

```wolfram
s = AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 2}];
s["CoreInverse"]
s["MarkerTerms"]
```

Marker terms are complete perturbation corrections rather than exponent-sorted power-log blocks. The full tail contract and the first omitted marker term are separate properties. Their asymptotic constants are not numerical error certificates.

<a id="AsymptoticExponentialCoreInverse"></a>
## AsymptoticExponentialCoreInverse

`AsymptoticExponentialCoreInverse[core, perturbation, {x, x0}, {y, n}]` retains an exact inverse of a growing exponential core and computes complete corrections through inclusive exponential degree `n`.

The supported core has the form `a v^b Exp[c v^p] + offset`, with positive `c`, `p`, and `v -> Infinity`. The perturbation is a finite power-log expression. Source infinity, translations, and finite reciprocal source coordinates are admitted.

Options are `Assumptions -> True`, `Direction -> Automatic`, `"SourceShift" -> Automatic`, `"CoreInverse" -> Automatic`, `"CoreCheckTimeConstraint" -> 3`, `"InputRemainder" -> None`, and `"MaxTerms" -> 20000`.

`"SourceShift"` selects the source translation. A declared pair `{rho, k}` here means `O[v^-rho (1 + Log[v])^k]` with corresponding derivative control. Its transported error remains a separate first-sector precision limit.

**Input**

```wolfram
s = AsymptoticExponentialCoreInverse[x Exp[x], x^2,
  {x, Infinity}, {y, 1}];
Normal[s]
```

**Output**

```wolfram
ProductLog[y] - ProductLog[y]^3/((1 + ProductLog[y]) y)
```

<a id="AsymptoticLogarithmicInverse"></a>
## AsymptoticLogarithmicInverse

`AsymptoticLogarithmicInverse[f, {x, x0}, {y, h}]` expands a supported finite logarithmic hierarchy. The form with target `y` and `SeriesTermGoal -> n` requests complete nonzero blocks.

Reciprocal-logarithmic units and leading logarithmic monomials use a positive exclusive cutoff in their inverse-logarithmic coordinate. Higher source-power corrections with generalized logarithmic coefficients use the ordinary target-power cutoff. Inspect `"Scale"`, `"Cutoff"`, and the recorded logarithmic coordinates.

The options are `Assumptions`, `Direction`, `Method`, `"Power"`, `"InputRemainder"`, `"Truncation"`, `SeriesTermGoal`, and `"MaxTerms"`, with the ordinary inverse defaults, plus `"LogarithmicLevels" -> 3`. The maximum supported hierarchy depth is eight. The chosen family still determines which options and cutoffs are applicable.

```wolfram
a = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {y, 4}];
b = AsymptoticLogarithmicInverse[x Log[Log[x]], {x, Infinity}, {y, 4}];
c = AsymptoticInverse[x + x^2 Sqrt[-Log[x]], {x, 0}, {y, 4}];
```

The common inverse constructor selects admitted reciprocal and generalized logarithmic families automatically. Ordinary polynomial-logarithmic inputs retain their ordinary method. Omitted higher source-power sectors remain separate from the logarithmic tail.

<a id="LogarithmicInverseResidual"></a>
### LogarithmicInverseResidual

`LogarithmicInverseResidual[s]` checks the normalized equation of a supported logarithmic-unit inverse. It has no options. The association contains `"ZeroBelowCutoff"` and identifies its `"Scope"`.

Generalized logarithmic coefficient results return `Failure["UnsupportedResidual", ...]` for this operation. Their displayed coefficients and retained original equation remain available for independent calculation.

<a id="ReciprocalLogCompose"></a>
### ReciprocalLogCompose

`ReciprocalLogCompose[outer, inner]` composes supported reciprocal-logarithmic inverse expansions with positive monomial prefactors. The inner result must approach the outer target endpoint with a positive constant unit. Options are `"Cutoff" -> Automatic` and `"MaxTerms" -> 20000`.

<a id="ReciprocalLogDifferentiate"></a>
### ReciprocalLogDifferentiate

`ReciprocalLogDifferentiate[s]` differentiates once; `ReciprocalLogDifferentiate[s, n]` differentiates `n` times. Options are `"Cutoff" -> Automatic` and `"MaxTerms" -> 20000`.

These operations require the supported exact reciprocal-logarithmic model. Translated endpoints, omitted higher-power sectors, and declared unknown errors require additional contracts and are rejected. `SeriesCompose` and `SeriesDifferentiate` also select this specialized calculus when applicable.

```wolfram
outer = AsymptoticLogarithmicInverse[x + x/Log[x], {x, 0}, {z, 4}];
inner = AsymptoticLogarithmicInverse[x + 2 x/Log[x], {x, 0}, {y, 4}];
s = ReciprocalLogCompose[outer, inner];
d = ReciprocalLogDifferentiate[s];
SeriesRefine[d, 6]
```

<a id="AsymptoticFlatInverse"></a>
## AsymptoticFlatInverse

`AsymptoticFlatInverse[f, {x, x0}, {y, n}]` inverts an exact shifted monomial core with finite flat exponential corrections. It retains complete exponential sectors through inclusive integer degree `n`.

The exponential phases must be positive and commensurable within the supported phase family. Their amplitudes are finite power-log expressions. The zero sector remains exact.

Options are `Assumptions -> True`, `Direction -> Automatic`, `"Power" -> 1`, and `"MaxTerms" -> 20000`.

**Input**

```wolfram
s = AsymptoticFlatInverse[x + Exp[-1/x], {x, 0}, {y, 3}];
Normal[s]
```

**Output**

```wolfram
y - Exp[-1/y] + Exp[-2/y]/y^2
  + (1/y^3 - 3/(2 y^4)) Exp[-3/y]
```

Inspect `"SectorDepth"`, `"Sectors"`, `"FirstOmittedSector"`, and `"Remainder"`. The omitted complete sector tail has an asymptotic bound. Its constants and threshold are existential, not supplied numerical certificates.

<a id="FlatSeriesTruncate"></a>
### FlatSeriesTruncate

`FlatSeriesTruncate[s, h]` truncates every positive sector at exclusive inner power `h`. It preserves the exact zero sector. Its option is `"MaxTerms" -> 20000`.

<a id="FlatSeriesMultiply"></a>
### FlatSeriesMultiply

`FlatSeriesMultiply[s, t]` multiplies expansions in the same monomial target coordinate and phase. An exact finite power-log scalar may replace either operand. Options are `"InnerCutoff" -> Automatic` and `"MaxTerms" -> 20000`.

<a id="FlatSeriesObservable"></a>
### FlatSeriesObservable

`FlatSeriesObservable[s, polynomial, z]` substitutes `s` into the polynomial's placeholder `z`. Polynomial coefficients may be finite real power-log expressions in the common coordinate. Options are `"InnerCutoff" -> Automatic`, `"MaxTerms" -> 20000`, and `"MaxPolynomialDegree" -> 32`.

<a id="FlatSeriesDifferentiate"></a>
### FlatSeriesDifferentiate

`FlatSeriesDifferentiate[s]` differentiates once; `FlatSeriesDifferentiate[s, n]` differentiates `n` times with respect to the target, including the exponential factors. Options are `"InnerCutoff" -> Automatic` and `"MaxTerms" -> 20000`.

Nonzero remainders require the retained analytic flat-inverse derivative contract. Inner coefficient errors and the omitted exponential tail remain separate.

```wolfram
s = AsymptoticFlatInverse[x + x^2 Exp[-1/x], {x, 0}, {y, 2}];
t = FlatSeriesTruncate[s, 3];
FlatSeriesMultiply[t, 1/y]
FlatSeriesObservable[s, 2 z^2 - 3 z + 7, z, "InnerCutoff" -> 4]
FlatSeriesDifferentiate[t]
```

In this example, `2` is a sector degree, while `3` and `4` are inner power cutoffs. Increasing an inner truncation cutoff cannot restore previously discarded coefficients.

<a id="AsymptoticFourierInverse"></a>
## AsymptoticFourierInverse

`AsymptoticFourierInverse[f, {x, x0}, {y, h}]` inverts a monomial leading core whose higher-power corrections have finite Fourier-polynomial coefficients in the logarithm.

Frequencies must be exact real numbers. Frequency sums generated during multiplication are retained and merged. The target-power cutoff is exclusive, and the remainder uses a nonoscillatory envelope.

Options are the ordinary inverse options `Assumptions`, `Direction`, `Method`, `"Power"`, `"InputRemainder"`, `"Truncation"`, `SeriesTermGoal`, and `"MaxTerms"`, with the same defaults, plus `"MaxFrequencies" -> 256`. The public constructor requires the explicit `{y, h}` form, `Method -> "Lagrange"`, and `"Truncation" -> "Exponent"`. `Assumptions` must concern parameters only. `"MaxFrequencies"` is a hard resource budget, not a frequency truncation.

**Input**

```wolfram
s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}];
Normal[s]
```

**Output**

```wolfram
y - y^2 Sin[Log[y]]
  + y^3 Sin[Log[y]] (2 Sin[Log[y]] + Cos[Log[y]])
```

A leading oscillatory coefficient without an eventual nonzero sign is outside this constructor's scope.

<a id="FourierInverseResidual"></a>
### FourierInverseResidual

`FourierInverseResidual[s]` checks the finite Fourier equation at its stored relative source-weight cutoff. `FourierInverseResidual[s, h]` supplies another relative cutoff. Its option is `"MaxTerms" -> 20000`.

<a id="FourierInverseCoefficient"></a>
### FourierInverseCoefficient

`FourierInverseCoefficient[s, {k1, k2, ...}]` gives an exact multi-index contribution as Fourier modes and as a real trigonometric expression. It has no options. The returned association includes `"Weight"`, `"Modes"`, `"Expression"`, and `"LogVariable"`.

<a id="AsymptoticSpecialInverse"></a>
## AsymptoticSpecialInverse

`AsymptoticSpecialInverse[family, {x, x0}, {y, h}]` uses an explicitly selected special-function inverse adapter.

| Family | Source endpoint | Order convention |
| --- | --- | --- |
| `"Erfc"` | `Infinity` | Power cutoff in the logarithmic target coordinate. |
| `"LogGamma"` | `Infinity` | Inclusive integer marker depth around a retained exact core. |
| `"Gamma"` | `Infinity` | Inclusive integer marker depth after logarithmic target normalization. |
| `"LambertThreshold"` | `-1` | Exclusive local target-power cutoff greater than `1/2`. |
| `"QuadraticThreshold"` | Exact finite vertex | Exclusive local target-power cutoff greater than `1/2`. |

The Gamma tail adapters use the increasing real source branch above two. They do not automatically switch to a near-minimum representation. Tail adapters retain finite Poincare forward models with separate value and derivative remainder contracts.

For a term goal that counts complete polynomials at successive powers of the reciprocal Lambert core, use the direct [Gamma and LogGamma inverse forms](#inverse-gamma-and-loggamma). The explicit adapters in this section retain their perturbation-marker order convention.

| Option | Default | Meaning |
| --- | --- | --- |
| `Assumptions` | `True` | Parameter assumptions. |
| `Direction` | `Automatic` | Selected source side. |
| `"ModelTerms"` | `Automatic` | Number of terms in the finite asymptotic forward model. |
| `"TargetOffset"` | `0` | Exact affine target offset. |
| `"TargetScale"` | `1` | Exact nonzero real affine target scale. |
| `"QuadraticCoefficient"` | `1` | Coefficient of the quadratic threshold model. |
| `"LambertBranch"` | `Automatic` | Real Lambert threshold branch, `0` or `-1`. |
| `"MaxTerms"` | `20000` | Resource budget. |

```wolfram
AsymptoticSpecialInverse["Erfc", {x, Infinity}, {y, 2}]
AsymptoticSpecialInverse["LogGamma", {x, Infinity}, {y, 2}]
AsymptoticSpecialInverse["Gamma", {x, Infinity}, {y, 2}]
AsymptoticSpecialInverse["LambertThreshold", {x, -1}, {y, 5/2},
  "LambertBranch" -> -1]
```

The last example selects the source side below `-1`. A conflicting explicit `Direction` is rejected.

**Input**

```wolfram
s = AsymptoticSpecialInverse["QuadraticThreshold", {x, 3}, {y, 2},
  "TargetOffset" -> 7, "TargetScale" -> -2, "QuadraticCoefficient" -> 3];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{3 + Sqrt[(7 - y)/6], 0}
```

The selected target domain is `y < 7`. Inspect `"AdapterCutoffMeaning"` when supplied, `"ForwardRemainderContract"`, and the retained coordinate properties for the adapter's precision scope.

<a id="SpecialInverseNumericalCheck"></a>
### SpecialInverseNumericalCheck

`SpecialInverseNumericalCheck[s, y1]` compares an adapter result with its original special-function equation. Its option is `WorkingPrecision -> 60`. Gamma and complementary-error-function tails use logarithmic equations for stable comparison.

```wolfram
s = AsymptoticSpecialInverse["Gamma", {x, Infinity}, {y, 2}];
check = SpecialInverseNumericalCheck[s, Exp[10000], WorkingPrecision -> 60];
check["ReferenceRoot"]
check["Error"]
```

This is a numerical comparison, not an interval certificate. Supply an exact target or sufficient input precision and remain within the retained target domain.

## Properties & Relations

### Expression, Expansion, and Model

| Item | What it establishes |
| --- | --- |
| `Normal[s]` | The finite expression being used as the approximation. |
| `s["Remainder"]` | An asymptotic remainder class, with its recorded coordinate and prefactor. |
| `s["Remainder"] === 0` | An established exact finite result for the admitted equation and branch. |
| `s["ExactModel"]` | Exactness of the retained forward model; the displayed inverse can still have a nonzero tail. |
| `InverseResidual[s]` | Composition at a stated order for the equation named by its scope. |
| `InverseNumericalCheck[s, y1]` | Agreement with a numerical solution at one target. |
| `InverseCertificate[s, y1, ...]` | A proved local root enclosure when `"Certified" -> True` is returned. |

`SeriesTruncate` changes the displayed cutoff using existing information. `SeriesRefine` obtains more justified information from the retained source or operation. A higher cutoff alone does not improve an unknown input remainder.

### Inverse Expressions and Inverting an Inverse

`AsymptoticExpansion[InverseFunction[F][y], ...]` expands the selected inverse of `F`. `AsymptoticInverse[InverseFunction[F][x], ...]` inverts that already inverted expression and can recover `F` on compatible branches.

A composite such as `1 + InverseFunction[F][y]` is an expression containing an inverse. Its numerical or residual interpretation must not be confused with the defining equation for `F` itself. Direct inverse results retain their source branch; composite results retain inverse-occurrence information separately.

### Remainder-Aware Operations

`SeriesCompose` and `SeriesObservable` include uncertainty from their inputs. A singular derivative can reduce available absolute precision. `SeriesExp` needs a vanishing absolute argument error even when its output grows rapidly. `SeriesDifferentiate` needs derivative information in addition to a value bound.

For positive Gamma prefactors, `SeriesLog` returns the additive logarithmic expansion, while direct Gamma normalization returns a multiplicative correction bracket. Their cutoff conventions should be read in the coordinate of the returned operation.

## Possible Issues

| Issue | Action |
| --- | --- |
| Approximate exponent or coefficient | Replace decimals by the intended exact value, such as `Sqrt[2]` or `5/2`. |
| Unproved parameter sign or realness | Supply sufficient `Assumptions`; do not assume that a parameter is implicitly real. |
| Ambiguous inverse branch | Restrict the source domain or supply `"InverseFunctionBranches"` for an unevaluated inverse operator. |
| Incompatible source or target condition | Select an approach on which the condition holds eventually. |
| Unexpected number of terms | Check whether the request is a cutoff, block goal, or marker/sector depth. Exact cancellations can remove blocks. |
| Unexpected power of the remainder | Inspect `"RemainderVariable"`, `"Prefactor"`, and `"TermConvention"`. Sparse support or transported input errors can change the first omitted power. |
| Refinement stops at an input error | Supply stronger justified input information in a new construction. |
| Derivative operation fails | Establish the necessary derivative remainder contract; a value Big-O is insufficient. |
| Certificate fails near an interval boundary | Check poles, endpoint signs, strict source conditions, and the interval's containment in the selected branch. |
| `"SeriesData"` is missing | Use supported series arithmetic and the recorded remainder; the result may have irrational exponents or separate error scales. |
| A composite result rejects `"Cutoff"` | Truncate or refine supported operands in their own scales, then combine them again. |
| A quotient loses precision or fails | Check the denominator's leading term and relative remainder; normalization cannot infer a nonzero function from a pure remainder. |
| Resource limit | Reduce the order or expression complexity, or raise the relevant budget. A partial result does not establish omitted coefficients. |

Ordinary power-log coefficients are polynomials in a single logarithm. Arbitrary nested logarithms, unrelated exponential-sector sums, and arbitrary oscillatory coefficients require a compatible specialized family for an ordered expansion. Arithmetic can retain compatible existing expansions as a composite bound without asserting closure in a single coefficient scale.

The ordinary factor `Log[x]` in `Log[x] Exp[x]` or `Log[x] Gamma[x]` produces the unsupported combined logarithmic source `Log[Log[x]]` in direct normalization. The existence of a formal factored expression alone does not guarantee that the direct constructor can expand it.

Finite Poincare expansions do not assert convergence. Numerical agreement at a large argument does not turn an asymptotic frontier into a pointwise bound. Unknown source predicates and unsupported certificate operations are not silently discarded.

Use `FailureQ[result]` to check a result before querying its properties. Failure data can include the unproved condition, unsupported scale, available precision, or best expansion.

## See Also

Wolfram Language: [Series](https://reference.wolfram.com/language/ref/Series.html), [Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html), [InverseFunction](https://reference.wolfram.com/language/ref/InverseFunction.html), [Function](https://reference.wolfram.com/language/ref/Function.html), [ConditionalExpression](https://reference.wolfram.com/language/ref/ConditionalExpression.html), [ProductLog](https://reference.wolfram.com/language/ref/ProductLog.html), [LogBarnesG](https://reference.wolfram.com/language/ref/LogBarnesG.html), [Normal](https://reference.wolfram.com/language/ref/Normal.html).

## Related Guides

- [Mathematical article](../../article/asymptotic-inverse.pdf): mathematical definitions, results, and proofs.
- [Executable examples](../Examples/Examples.wl): additional package expressions.
- [Package entry point](../README.md): loading and documentation links.
- [Wolfram Language asymptotic computations](https://reference.wolfram.com/language/guide/Asymptotics.html): related built-in functionality.
