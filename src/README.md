# AsymptoticAnalysis

**The package must completely subsume Wolfram's `Series`, `Asymptotic`, and
`DiscreteAsymptotic`, correctly and successfully handling every input that
any of them handles.** The result representation may differ. Complete
coverage is not yet established: native `Series` and `Asymptotic` delegation
and selected automatic routing exist, but `DiscreteAsymptotic` delegation
is not yet implemented. The
[compatibility plan](../docs/development/NATIVE_COMPATIBILITY.md) and
[native backend guide](Documentation/UserGuide.md#native-backend-expansions)
record implemented behavior and known deviations from this requirement.

**Complete Mathics3 compatibility, alongside support for the official Wolfram
kernel, is a project goal.** Mathics support is under active development, with
focused checks for core operations and selected special-function paths.
Complete compatibility is not yet established; the
[compatibility guide](../docs/Mathics/COMPATIBILITY.md) records current
coverage, interpreter settings, and remaining work.

**The package must successfully compute all asymptotics developed in
`vendor/proveit/docs`, including q-analogs, their inverses, and combinatorial
sequences.** Existing power-log, logarithmic, Gamma/Barnes, Fourier, and flat
engines are building blocks toward this goal; complete article coverage is
not yet established. See the
[vendored coverage matrix](../docs/development/VENDORED_ASYMPTOTICS.md) for
the family-by-family status and the
[coverage register](../docs/development/COVERAGE_TARGETS.md) for all three
project requirements.

The package was renamed from AsymptoticInverse. Its context is
``"AsymptoticAnalysis`"``; public functions such as `AsymptoticInverse` retain
their names. See [fixed-version loading](Documentation/UserGuide.md#loading-fixed-versions)
when using a commit from before the rename.

This `src/` directory contains the modular package. The directory name does
not change the package context or the repository-root standalone filename
`AsymptoticAnalysis.wl`.

Real asymptotic expansions of functions and selected inverse branches in Wolfram
Language, with exact exponents, logarithmic coefficients, and retained remainders.
Native backends, selected explicitly or by automatic routing, also preserve
built-in `Series` and `Asymptotic` results under a distinct formal or native
asymptotic contract.

- **[User guide](Documentation/UserGuide.html)** — syntax, options, worked
  examples, result properties, supported scales, and possible issues.
  [Read the Markdown version](Documentation/UserGuide.md).
- **[Mathematical article](../docs/article/asymptotic-inverse.pdf)** — definitions,
  theorems, proofs, branch selection, and error estimates.
  [Read the LaTeX source](../docs/article/asymptotic-inverse.tex).

## Loading

Load the current `main` package directly from GitHub:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticAnalysis.wl"]];
```

This downloads the complete standalone package to a temporary file, then
loads it with normal `Get`; no installation or checkout is needed.
The remote URL uses the repository-root
[`AsymptoticAnalysis.wl`](../AsymptoticAnalysis.wl), which includes all companion
modules. Use the `src/Kernel/` entry point below with a local checkout.
Downloading first avoids an observed Wolfram 15.0.1 issue that intermittently
truncated direct `Get` of the compressed package response.

For a fixed version, use the guide's
[commit-pinned form](Documentation/UserGuide.md#loading-fixed-versions).
You can also download the repository-root `AsymptoticAnalysis.wl` and load that
complete single-file package with local `Get` offline.

From the repository root of a local checkout, use the modular entry point:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
```

Or register the local paclet directory and load its context:

```wolfram
PacletDirectoryLoad["/absolute/path/to/src"];
Needs["AsymptoticAnalysis`"];
```

The [paclet metadata](PacletInfo.wl) declares version 1.8.0 and Wolfram Language
15.0 or later. The [loading validation](../validation/README.md) records the
tested distribution paths and native runtime versions.

For Mathics3, follow the separate
[compatibility guide](../docs/Mathics/COMPATIBILITY.md) for the tested interpreter
environment, loading sequence, iteration budget, and supported features. Its
portable regression results and the Wolfram acceptance records describe
different runtimes and selections.

## Choose an interface

| Task | Entry point and guide |
| --- | --- |
| Expand a function or a supported callable inverse | [`AsymptoticExpansion`](Documentation/UserGuide.md#AsymptoticExpansion), held alias [`AsymptoticExpand`](Documentation/UserGuide.md#AsymptoticExpand) |
| Select a built-in backend or inspect automatic routing | [Native expansion backends](Documentation/UserGuide.md#native-backend-expansions) |
| Select an inverse by its source endpoint and side | [`AsymptoticInverse`](Documentation/UserGuide.md#AsymptoticInverse) |
| Add, multiply, compose, or apply an observable | [Series arithmetic](Documentation/UserGuide.md#series-operations) |
| Change the retained order | [`SeriesTruncate`](Documentation/UserGuide.md#SeriesTruncate), [`SeriesRefine`](Documentation/UserGuide.md#SeriesRefine) |
| Inspect a normalized model or one inverse coefficient | [`PowerLogModel`](Documentation/UserGuide.md#PowerLogModel), [`InverseExpansionCoefficient`](Documentation/UserGuide.md#InverseExpansionCoefficient) |
| Check a supported inverse | [`InverseResidual`](Documentation/UserGuide.md#InverseResidual), [`InverseNumericalCheck`](Documentation/UserGuide.md#InverseNumericalCheck), [`InverseCertificate`](Documentation/UserGuide.md#InverseCertificate) |

The [function overview](Documentation/UserGuide.md#function-overview) also links
the specialized constructors for exact inverse cores, logarithmic hierarchies,
flat exponential sectors, Fourier coefficients, and special-function adapters.

## First expansion

```wolfram
Clear[x, y];
s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
Normal[s]
(* y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2) *)
s["Remainder"]
(* PowerLogRemainder[y, 4, 3] *)
```

Ordinary arithmetic preserves the series remainder:

```wolfram
s + y^2
s/(1 + y)
s^2
SeriesNormalize[(s + y^2)/(1 + y), "Cutoff" -> 3]
```

See [Series Arithmetic and Normalization](Documentation/UserGuide.md#series-operations)
for regular function operands, available precision, and composite error bounds.

## Reading a result

Successful expansion constructors return a
[`GeneralizedSeries`](Documentation/UserGuide.md#GeneralizedSeries). `Normal[s]`
returns its ordinary finite expression for an analytic result and drops the
remainder. Keep an analytic `s` for further series operations. Use `s["Properties"]` to list its metadata, then
inspect `s["Remainder"]` and the coordinate properties supplied for its scale,
such as `s["RemainderVariable"]`.
Standard and Traditional forms display the expression and remainder without the
object head; `InputForm[s]` retains the complete object. Evaluating `s[value]`
substitutes into the finite expression.

An ordinary cutoff is an **exclusive exponent bound**, while `SeriesTermGoal`
counts complete nonzero blocks. Factored and specialized scales have their own
order conventions; see [Coordinates and Cutoffs](Documentation/UserGuide.md#coordinates-and-cutoffs).
The optional `s["SeriesData"]` view can be `Missing` when a native representation
would lose remainder information or require excessive allocation. The sparse
result and its remainder remain available.

An explicitly selected or automatically routed native result stores
`"Kind" -> "Native"`, its complete
`"NativeResult"`, and `"Remainder" -> Missing["NativeContract"]`. `Normal`
normalizes that native expression and may retain infinite sums. Native formal
operations use `s["NativeResult"]`; package analytic operations cannot infer a
remainder theorem from the native result.

Residual algebra, numerical comparison, and interval certification provide
different evidence. An asymptotic remainder has an unspecified constant and is
not itself a numerical error enclosure; consult the individual checking APIs
in the table above.

## Current scope

For package analytic representations, use exact input such as `Sqrt[2]` and
`1/10`, and leave expansion variables unassigned. The package selects real branches at finite endpoints and real
infinities. Parameter signs and coefficient realness must follow from the
retained assumptions. Constructor defaults capture the enclosing `Assuming`
context; an explicit `Assumptions` option replaces it. See
[Assumptions and Parameter Domains](Documentation/UserGuide.md#assumption-context)
and [Real Coefficients](Documentation/UserGuide.md#real-coefficients).

Forward expansions include supported Gamma and Barnes G products, ratios,
logarithms and powers, as well as elementary exponential products:

```wolfram
AsymptoticExpansion[Gamma[3 x]/Gamma[x], x -> Infinity,
  SeriesTermGoal -> 5]
AsymptoticExpansion[Log[Gamma[x]], x -> Infinity,
  SeriesTermGoal -> 5]
```

Selected increasing [Gamma and LogGamma inverses](Documentation/UserGuide.md#inverse-gamma-and-loggamma)
and [Barnes G and LogBarnesG inverses](Documentation/UserGuide.md#barnes-inverse-expansions)
retain an exact Lambert core. Their affine forms, observable powers, and
operations have the branch restrictions listed in the guide.

The same forward interface handles admitted finite-point and large-argument
expansions of Bessel, Airy, error-integral, incomplete Gamma, zeta/polylogarithm,
hypergeometric, and elliptic functions:

```wolfram
s = AsymptoticExpansion[BesselK[0, x], x -> Infinity,
  SeriesTermGoal -> 3];
Normal[s]
s["Remainder"]
```

The series object retains separate error scales when oscillations or distinct
exponential factors occur. See [Other Special Functions](Documentation/UserGuide.md#special-function-expansions)
for supported endpoint examples, real-branch and fixed-parameter conditions,
carrier-specific cutoffs, and exact versus exponentially small contributions.

Analytic support depends on the function, endpoint, scale, and proved branch.
With `"Backend" -> "Package"`, an unsupported request returns a diagnostic
`Failure`. `Automatic` can route selected representation failures to a native
backend; native results retain unresolved output when the backend does not
complete. The guide's
[possible issues](Documentation/UserGuide.md#possible-issues) explain domain,
precision, and resource restrictions. Start with the
[example index](Examples/README.md) for executable Wolfram Language usage.
The [kernel module guide](Kernel/README.md) and [test guide](Tests/README.md)
describe the implementation and focused tests; the
[validation record](../validation/README.md) distinguishes recorded test and
artifact evidence.

## Native backends and automatic routing

```wolfram
s = AsymptoticExpand[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
{s["NativeResult"], Normal[s], s["RemainderContract"]}
AsymptoticExpansion[Gamma[x], {x, Infinity, 3}, "Backend" -> "Asymptotic"]
```

These explicit modes use their native input forms and order conventions;
native `Series` includes the requested order. Explicit selection makes one
native call. `Automatic` routes admitted native specifications/options and
selected representation failures to compatible native backends. If the
preferred backend fails or leaves an unresolved call, it tries the other
compatible backend and records the ordered attempts in `"NativeAttempts"`.
Successful package calls retain their existing conventions;
`"Package"` keeps the analytic contract and disables native routing. The
[compatibility plan](../docs/development/NATIVE_COMPATIBILITY.md) records the
remaining work toward complete native input coverage.
See the [native result contract](../docs/development/NATIVE_RESULT_CONTRACTS.md)
for held request metadata, option conflicts, and analytic-operation boundaries.
The [focused test guide](Tests/README.md#focused-native-backend-acceptance)
links the relevant runners and saved results, each tied to its own source
snapshot; a historical passing total does not validate later source changes.
