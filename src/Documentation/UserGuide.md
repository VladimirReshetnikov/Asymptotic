# AsymptoticAnalysis User Guide

AsymptoticAnalysis computes asymptotic expansions of functions and selected real inverse functions. It supports exact real exponents, logarithmic coefficients, finite and infinite endpoints, and explicit remainder classes. Additional constructors handle logarithmic hierarchies, exponential sectors, oscillatory coefficients, and selected special functions.

**AsymptoticAnalysis must completely subsume Wolfram Language `Series`, `Asymptotic`, and `DiscreteAsymptotic`: every input successfully handled by any of them must also be handled correctly and successfully by this package.** The result representation may differ while preserving the mathematical result, requested order, conditions, and applicable contract. This is an open project requirement. The current implementation delegates to `Series` and `Asymptotic` in selected modes; `DiscreteAsymptotic` has no implemented backend. See [Known Deviations and Coverage Gaps](#native-coverage-gaps).

**Complete package compatibility with both the official Wolfram kernel and [Mathics3](https://mathics.org/) is a project goal.** Mathics support is under active development: the implemented adapters and recorded checks currently cover selected operations. See [Mathics3 Compatibility](#mathics-compatibility) for loading instructions and the current coverage boundary.

**Supporting all asymptotics documented in `vendor/proveit/docs` is also a project goal**, including q-analogs, inverses, and combinatorial sequences. The [consolidated coverage targets](../../docs/development/COVERAGE_TARGETS.md) and [vendored asymptotics register](../../docs/development/VENDORED_ASYMPTOTICS.md) distinguish required coverage from implementation and verified evidence. The presence of a mathematical result in a vendored article does not establish package support.

The package name and context changed from AsymptoticInverse to AsymptoticAnalysis. Public function names, including `AsymptoticInverse`, are unchanged.

Start a fresh kernel when switching from the old package to the renamed version. Update context-qualified references such as ``AsymptoticInverse`AsymptoticInverse`` to ``AsymptoticAnalysis`AsymptoticInverse``.

Explicit native backends and selected automatic routes preserve Wolfram Language `Series` and `Asymptotic` results in the same result head, with a separate formal or native asymptotic contract. See [Native Expansion Backends](#native-backend-expansions).

This guide describes the Wolfram Language interface. See the [mathematical article](../../docs/article/asymptotic-inverse.pdf) for definitions, results, and proofs.

## Getting Started

The package's declared Wolfram Language requirement is version 15.0 or later. For Mathics3, use the [runtime-specific instructions](#mathics-compatibility) below. The Wolfram Language instructions here load the current `main` version directly from GitHub:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticAnalysis.wl"]];
```

This loads the package into the current kernel without installation or a local checkout. Evaluate the command again in each new kernel session.

The URL selects the repository-root [standalone package](../../AsymptoticAnalysis.wl), which includes every companion module. The move of the modular package directory to `src/` leaves this URL unchanged. Use `src/Kernel/AsymptoticAnalysis.wl` with a [local checkout](#loading-a-local-checkout).

`URLDownload` saves the complete source to a temporary file, then normal `Get` loads that file. Downloading first avoids an observed Wolfram 15.0.1 issue that intermittently truncated direct `Get` of the compressed package response.

<a id="loading-fixed-versions"></a>
### Fixed Versions and Offline Loading

To select a fixed version, set `commit` to the full hash of a commit containing the **repository-root** `AsymptoticAnalysis.wl`:

```wolfram
commit = "FULL_COMMIT_HASH";
url = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/" <>
  commit <> "/AsymptoticAnalysis.wl";
Get[URLDownload[url]];
```

For a commit from before the package rename, including checkpoint `01b18ab`, the repository-root filename is `AsymptoticInverse.wl` and the context is ``"AsymptoticInverse`"``. Use `commit <> "/AsymptoticInverse.wl"` for such a revision. The new filename and context apply to renamed revisions; a pinned historical commit keeps its original files. The inverse constructor is named `AsymptoticInverse` in both versions.

The repository-root file contains every package module. Download it once for offline use:

```wolfram
Get["/absolute/path/to/AsymptoticAnalysis.wl"];
```

### Loading a Local Checkout

The file under `src/Kernel/` loads companion files from a local checkout. From that checkout's repository directory, load it with:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
```

Alternatively, register the local package directory and load its context:

```wolfram
PacletDirectoryLoad["src"];
Needs["AsymptoticAnalysis`"];
```

<a id="mathics-compatibility"></a>
### Mathics3 Compatibility

Mathics3 uses the same public package context and file entry points. **The target is complete compatibility; the current implementation and verified coverage are incomplete.** Existing adapters cover selected exact calculations, and the full scope of the Wolfram Language interface below has not been established on Mathics. Start with the [Mathics installation and compatibility guide](../../docs/Mathics/COMPATIBILITY.md), which identifies the pinned interpreter dependencies, checked examples, and remaining work.

From the repository root, load the modular source in the Mathics interpreter:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
```

Evaluate the load before entering package calls. In particular, do not combine the load and the first call in one command-line `--code` expression: Mathics can bind unknown package names to the global context while parsing that whole expression. A `.wl` script with separate input expressions supports the required loading order. The repository-root `AsymptoticAnalysis.wl` is the alternative standalone entry point.

The portable examples use a larger Mathics iteration budget, set explicitly in the session:

```wolfram
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];
```

This evaluator budget is separate from the package's `"MaxTerms"` limit. The package does not raise the session's global iteration limit automatically. Inspect results through `Normal[s]`, `s["Remainder"]`, and `InputForm[s]` when front-end formatting differs.

Mathics' currently implemented [assumption consequences](../../docs/Mathics/ASSUMPTIONS.md) and [inverse-branch proofs](../../docs/Mathics/CALLABLES.md) are bounded exact rules. A domain or sign that these rules cannot prove remains unresolved or produces a `Failure`. A native backend request uses the interpreter's actual `Series` or `Asymptotic` implementation; an inert built-in symbol does not provide that implementation. Package-local adapters leave the caller's native functions unchanged. These present limitations identify work toward the goal of complete compatibility.

### First Expansion

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
| Expand a function | [AsymptoticExpansion](#AsymptoticExpansion), [AsymptoticExpand](#AsymptoticExpand) |
| Preserve a built-in expansion result | [Native Expansion Backends](#native-backend-expansions) |
| Expand Bessel, Airy, elliptic, and other special functions | [Other Special Functions](#special-function-expansions) |
| Expand a selected inverse | [AsymptoticInverse](#AsymptoticInverse) |
| Expand the increasing Gamma or LogGamma inverse | [Inverse Gamma and LogGamma Functions](#inverse-gamma-and-loggamma) |
| Expand the increasing Barnes G inverse | [Inverse Barnes G Functions](#barnes-inverse-expansions) |
| Inspect results and models | [GeneralizedSeries](#GeneralizedSeries), [PowerLogRemainder](#PowerLogRemainder), [PowerLogModel](#PowerLogModel), [InverseExpansionCoefficient](#InverseExpansionCoefficient) |
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
| `AsymptoticExpansion[f, {x, x0, h}]` | Expansion at `x0`; a package result uses exclusive cutoff `h`, while an automatically selected native result uses native order. |
| `AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n]` | A package result retains `n` complete nonzero blocks; a native result uses its backend's term-goal convention. |
| `AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n]` | Equivalent rule form. |
| `AsymptoticExpansion[f, {x, x0, n}, "Backend" -> "Series"]` | Native `Series` result through native order `n`. |
| `AsymptoticExpansion[f, {x, x0, n}, "Backend" -> "Asymptotic"]` | Native `Asymptotic` result at its requested order. |
| `AsymptoticExpansion[f, {x, x0, nx}, {y, y0, ny}, "Backend" -> "Series"]` | Successive native expansions in the specified variable order. |

In the package expansion path, `f` can be an expression, a unary pure function, or an unapplied unary `InverseFunction`. A callable is applied to `x`. A bare symbol is treated as an expression: use `Log[x]` or `Log[#] &` to expand the logarithm. Explicit native modes use their selected built-in function's input forms.

The expansion variable `x` must be a symbol without a numeric value. A named constant such as `Pi`, `E` or `Degree` is refused with `Failure["InvalidVariable", ...]`, as native `Series` refuses it, instead of being treated as a formal coordinate.

An applied inverse can also occur inside a supported expression. See [Callable and Applied Inverse Functions](#inverse-function-expressions).

### Details and Options

`AsymptoticExpansion` accepts `Assumptions :> $Assumptions`, `Direction -> Automatic`, `SeriesTermGoal -> Automatic`, `"MaxTerms" -> 20000`, `"InverseFunctionBranches" -> Automatic`, and `"Backend" -> Automatic`. Explicit native modes accept their selected backend's options. See [Assumptions and Parameter Domains](#assumption-context).

| `"Backend"` setting | Meaning |
| --- | --- |
| `Automatic` | Preserve supported package expansions; route native request forms and native-specific options, or selected real-representation failures, to one native backend. |
| `"Package"` | Use the package engines and their analytic remainder contracts; refuse native-specific options and do not fall back. |
| `"Series"` | Delegate to built-in `Series` and retain its native result. |
| `"Asymptotic"` | Delegate to built-in `Asymptotic` and retain its native result. |

Ordinary expansions use an absolute cutoff in the positive local coordinate. Gamma and Barnes G products and admitted exponential products use a cutoff inside an exact prefactor. Structured forward special-function expansions apply cutoffs and term goals separately to their recorded carriers. The defining-sum expansions of `Zeta` and `LerchPhi` use the special coordinates described below. A direct inverse-function result retains its inverse constructor's cutoff convention. See [Coordinates and Cutoffs](#coordinates-and-cutoffs) and [Other Special Functions](#special-function-expansions).

The ordinary input class includes sums, products, exact real constant powers, logarithms, exponentials of bounded arguments, and supported Taylor, Laurent, or Puiseux function expansions. A branch or exponent ordering that cannot be established produces a `Failure`.

The package's real representations require coefficients provably real under the retained assumptions. Contributions at the same power are combined and simplified before this check. Constants and target offsets obey the same requirement. A native formal or complex result has a different contract. See [Real Coefficients](#real-coefficients) and [Native Expansion Backends](#native-backend-expansions).

<a id="AsymptoticExpand"></a>
## AsymptoticExpand

### Usage

`AsymptoticExpand[args]` is a held alias of `AsymptoticExpansion[args]`. It accepts the same call forms and options, including the same `"Backend" -> Automatic` default. The alias does not select native order semantics by itself.

```wolfram
AsymptoticExpand[Exp[x], {x, 0, 3}, "Backend" -> "Package"]
AsymptoticExpand[Exp[x], {x, 0, 3}, "Backend" -> "Series"]
```

The first request has exclusive package cutoff `3`; the second requests native `Series` order `3`. See [AsymptoticExpansion](#AsymptoticExpansion) for details and options.

<a id="native-backend-expansions"></a>
## Native Expansion Backends

Use an explicit native backend when a built-in's input and order conventions
are required. Read [Basic Examples](#native-basic-examples) for the loading
and inspection pattern, [Automatic Selection](#automatic-backend-routing)
for routing, and [Known Deviations and Coverage Gaps](#native-coverage-gaps)
for the remaining work toward complete built-in coverage.

<a id="native-coverage-gaps"></a>
### Known Deviations and Coverage Gaps

The target includes **every successful input** of [Series](https://reference.wolfram.com/language/ref/Series.html), [Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html), and [DiscreteAsymptotic](https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html), including their options, conditions, and supported expression forms. Returning a different result head is permitted. Losing a condition, changing the requested approximation, or wrapping unresolved work as if it succeeded does not meet the requirement.

**Complete coverage and correctness have not been established.** The following matrix summarizes known deviations and remaining verification gaps. The maintained [native compatibility plan](../../docs/development/NATIVE_COMPATIBILITY.md) records their implementation status and evidence; the [code-review register](../../docs/development/CODE_REVIEW_STATUS.md) tracks related correctness and API findings. Source inspection, a recorded counterexample, and a passing runtime check have different evidential scope.

| Area | Current deviation or gap |
| --- | --- |
| `DiscreteAsymptotic` | No native backend or automatic route is implemented. `"Backend" -> "DiscreteAsymptotic"` is not an accepted selector. The discrete sequence, sum, product, coefficient, and recurrence problems covered by that built-in are part of the required target; existing continuous asymptotics do not establish their coverage. |
| Automatic admission | Routing recognizes selected request shapes and a fixed list of package representation failures. Domain, inverse-branch, undecidable-order, resource, and other excluded failures can stop a request before a native engine that could handle it is tried. Explicit `"Series"` or `"Asymptotic"` selects the corresponding existing native path. |
| Protected source forms and options | Any nested `Function`, `InverseFunction`, or `ConditionalExpression`, existing series/remainder objects, or an explicit direction, branch, or resource option keeps Automatic on the package path. This also protects ordinary expressions containing applied functions or algebraic-root encodings, and excludes some conditioned complex native requests. More precise classification remains open. |
| Order and term goals | A successful package path retains its exclusive cutoff and nonzero-block count; native `Series` includes its requested order. Automatic can change between these conventions without translating the request. [Automatic Selection](#automatic-backend-routing) describes the currently admitted rule-form goals. Matching native order throughout the public interface remains unresolved. |
| Configured defaults and the alias | Omitted backend selection currently hardcodes `Automatic`; it does not honor a configured `"Backend"` default. Configured term goals can also bypass the intended route. `AsymptoticExpand` forwards to `AsymptoticExpansion`, while ownership of independently configured alias defaults remains unresolved. Pass the intended backend and term goal explicitly. |
| Option identity and argument roles | Computed option keys, equivalent string/symbol/context spellings, and variables named like options are not classified consistently. The same request can therefore receive different routing, diagnostics, or variable metadata. A shared option-resolution policy remains open. |
| Native candidate search | Search uses runtime option-list membership to select compatible candidates and stops at the first syntactically computed result. Those lists do not characterize every form a native engine can actually accept; preserving the preferred unresolved result when attempts fail is also not successful coverage. |
| Held, partial, and nonfinite outcomes | `"Computed"` means only that the stored expression contains none of the recognized abort, failure, or unevaluated native-call forms. Held native syntax can affect classification, and nested inactive or partly evaluated work needs a stronger completion policy. The status is not a correctness proof. |
| Evaluation and storage | Automatic preparation can evaluate the source under a different assumption context or in a different order from a direct native call. Native construction also eagerly computes `Normal[result]`, potentially expanding a compact result before that view is requested. General evaluation compatibility and demand-driven storage remain open. |
| Analytic import and later operations | Formal native coefficients do not establish an analytic tail theorem. Source-regularity admission and observable Taylor chart, endpoint, and one-sided-limit checks have open correctness audits. Package analytic arithmetic/refinement currently refuses native results; native operations must use `"NativeResult"`. |
| Mathics runtime coverage | Current adapters and feature-specific checks cover part of the package. Native requests depend on the interpreter's actual implementations. Complete compatibility with Mathics, including the required three-function coverage, remains a project goal; see [Mathics3 Compatibility](#mathics-compatibility). |
| Verification breadth | Focused differential suites cover selected native requests and preservation contracts. There is no exhaustive input catalog or validation of every native form, option combination, bound-variable arrangement, special function, or kernel version. Receipt counts apply to their recorded source snapshots and selections. |

The distinct native result contract below preserves formal or backend-specific information without inventing a package analytic remainder. That representation is allowed by the target; it does not resolve admission, order, correctness, or runtime coverage gaps. Known limitations must remain documented as they are repaired and newly discovered cases are added to the compatibility plan.

### Details and Options

Use `"Backend" -> "Series"` or `"Backend" -> "Asymptotic"` to send a request to the corresponding built-in engine. The native path preserves supported input structures and backend options without a package special-function whitelist or a preliminary positive-real coordinate requirement. Native behavior depends on the installed Wolfram Language version. A returned result does not add an independent branch proof or analytic error estimate.

An order specification retains the selected built-in function's meaning. In particular, native `Series[f, {x, x0, n}]` expands through order `n`, whereas the package's ordinary cutoff excludes exponent `n`. Native `SeriesTermGoal` also has the selected backend's meaning. See [Series](https://reference.wolfram.com/language/ref/Series.html) and [Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html).

Select native options appropriate to that engine, such as `Analytic` for `Series`, or `GenerateConditions` and `WorkingPrecision` for `Asymptotic`. Preserve any domain conditions needed by the problem; suppressing generated conditions does not prove that the result holds for every parameter value.

Native modes reject explicitly supplied `"MaxTerms"` and `"InverseFunctionBranches"` with `Failure["NativeOptionConflict", ...]`. These are package-specific contracts; use `"Backend" -> "Package"` when they are needed. Package mode returns `Failure["UnsupportedOption", ...]` for native-specific options rather than ignoring them.

<a id="automatic-backend-routing"></a>
### Automatic Selection

`Automatic` preserves a successful package result and its existing cutoff, block count, and analytic contract. It also recognizes native-specific options and request forms, including multiple specifications, symbolic or complex centers, order `Infinity`, lists, inactive expressions, and a rule-form leading-order request without `SeriesTermGoal`.

Otherwise the package engines are tried first. A selected representation limitation, such as inexact input, nonreal coefficients, or an unsupported coefficient scale, can produce a native fallback. Domain, inverse-branch, resource, and invalid-option failures are retained. A source containing `Function`, `InverseFunction`, `ConditionalExpression`, `GeneralizedSeries`, or `PowerLogRemainder`, or an explicitly supplied `Direction`, `"MaxTerms"`, or `"InverseFunctionBranches"`, keeps the package path. This conservative protection applies even when the explicitly supplied option has its default value.

Native-specific options determine which backends are compatible: `Series` is preferred when it accepts all such option keys, then `Asymptotic`. Conflicting option sets return `Failure["NativeOptionConflict", ...]`. Without those options, a triple specification or successive specifications prefer `Series`; a single order-`Infinity` request and ordinary rule forms prefer `Asymptotic`.

If the preferred native result is `"Unresolved"` or `"Failed"`, `Automatic` tries the other backend when it accepts all supplied option keys. Search stops on `"Computed"` or `"Aborted"`. If every attempted result is unresolved or failed, the preferred result is retained. An explicit native backend, or an option set accepted by only one backend, permits one attempt. The ordered `"NativeAttempts"` records show which automatic native calls were made.

```wolfram
Clear[x, y];
s = AsymptoticExpand[Exp[I x], {x, 0, 3}];
{s["NativeBackend"], s["BackendSelectionReason"],
 s["OrderConvention"], Normal[s]}

AsymptoticExpansion[Exp[x + y], {x, 0, 2}, {y, 0, 1}]
AsymptoticExpansion[Exp[x], {x, 0, 3}, Analytic -> False]
AsymptoticExpansion[Sin[x], x -> 0]
```

An automatic native result records `"OrderConvention" -> "Native"`. This is a change of representation and order semantics: native `Series` includes its requested order and its term goal can count zero coefficient positions. It does not promise the package's exclusive cutoff or nonzero-block count. Select `"Backend" -> "Package"` when those conventions must be enforced, or an explicit native backend when the native engine must be fixed. These routes extend coverage; they do not establish complete automatic coverage of every native input.

For this list request, the preferred native `Asymptotic` call leaves the zero term goal unresolved, and the compatible `Series` call supplies the result:

**Input**

```wolfram
s = Quiet[AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0,
  SeriesTermGoal -> 0]];
{s["NativeBackend"], Normal[s],
 ({#["Backend"], #["EvaluationStatus"]} & /@ s["NativeAttempts"])}
```

**Output**

```wolfram
{"Series", {1, x}, {{"Asymptotic", "Unresolved"}, {"Series", "Computed"}}}
```

This uses native term-goal semantics. Scalar rule requests also admit an
explicit `SeriesTermGoal -> Automatic` or a nonpositive integer. The native
`Series` result for `Exp[x]` at zero has finite part `1` with goal `0` or
`Automatic`, and an empty finite part with a negative goal. These results
retain their native remainder and exactness contracts.

```wolfram
s = Quiet[AsymptoticExpand[Exp[x], x -> 0, SeriesTermGoal -> 0]];
{s["NativeBackend"], Normal[s]}
(* {"Series", 1} *)
```

An explicit package analytic request such as
`AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 0, "Backend" -> "Package"]`
still returns `Failure["InvalidCutoff", ...]`. Explicit package direction,
branch and resource options remain binding. Triple specifications retain
their existing cutoff behavior; this rule-form admission does not reinterpret
a cutoff as a native order.

<a id="native-basic-examples"></a>
### Basic Examples

Preserve a series with complex coefficients and inspect both its native and normalized forms:

```wolfram
Clear[x];
s = AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
{s["NativeResult"], Normal[s], s["RemainderContract"]}
```

Request an asymptotic approximation directly from the native engine:

```wolfram
t = AsymptoticExpand[Gamma[x], {x, Infinity, 3},
  "Backend" -> "Asymptotic"];
{t["NativeResult"], t["Remainder"], t["Exact"]}
```

### Scope

Successive series preserve the order of the variable specifications. Native-supported symbolic centers, approximate coefficients, lists, inactive expressions, and generated conditions retain their backend semantics.

```wolfram
Clear[x, y, a, f];
AsymptoticExpansion[Exp[x + y], {x, 0, 2}, {y, 0, 1},
  "Backend" -> "Series"]
AsymptoticExpansion[Exp[x], {x, a, 2}, "Backend" -> "Series"]
AsymptoticExpansion[f[x], {x, 0, 2}, "Backend" -> "Series",
  Analytic -> False]
```

An assumption of analyticity used by a native calculation is not a separate proof of an analytic tail bound. Successive expansions do not imply uniform asymptotics on arbitrary simultaneous paths.

For example, for each fixed `a > 0`, `a/(a + x) == 1 + O[x]` as `x -> 0` with a bound constant allowed to depend on `a`. Its exact error is `-x/(a + x)`. Substituting `a -> x` into the original function gives `1/2`, so the fixed-parameter expansion cannot justify the conclusion `1 + O[x]` on that diagonal.

```wolfram
AsymptoticExpansion[a/(a + x), {x, 0, 0},
  "Backend" -> "Series", Assumptions -> a > 0]
```

### Properties & Relations

Native results have the following contract:

| Property | Meaning |
| --- | --- |
| `"Kind"`, `"Scale"` | `"Native"`. |
| `"NativeResult"` | Complete result returned by the selected built-in engine, including nested orders, conditions, or infinite expressions. |
| `"Expression"` | `Normal` applied to the native result during construction; this stored expression is returned by `Normal[s]`. |
| `"Remainder"` | `Missing["NativeContract"]`; no package analytic remainder is asserted. |
| `"Exact"` | `Missing["NotEstablished"]`; absence of a native `O` term is not an exactness proof. |
| `"RemainderContract"` | `"NativeFormalOrder"` for `Series`, or `"NativeAsymptotic"` for `Asymptotic`. |
| `"NativeBackend"` | `"Series"` or `"Asymptotic"`. |
| `"NativeRequest"` | Held call to the selected built-in function, with the wrapper's backend selector removed. |
| `"OriginalArguments"` | Original arguments retained inside `HoldComplete`. |
| `"ExpansionSpecifications"` | Recognized specification forms retained individually inside `HoldComplete`, in their supplied order. Literal explicit requests retain their syntax; automatic preparation can resolve expressions before these records are formed. |
| `"AmbientAssumptions"` | Ambient assumption value captured at native entry. |
| `"Assumptions"` | `Missing["NativeContract"]`; the wrapper does not independently reconstruct the backend's effective proof context. |
| `"NativeEvaluationStatus"` | Syntactic evaluation status: `"Computed"`, `"Unresolved"`, `"Failed"`, or `"Aborted"`; see the definitions below. |
| `"NativeAttempts"` | For automatic native results, ordered records with `"Backend"`, `"EvaluationStatus"`, and held `"Request"`. Explicit native delegation does not add this history. |
| `"NativeKernelVersion"`, `"NativeSystemID"` | Runtime that produced the native result. |
| `"BackendSelection"`, `"BackendSelectionReason"` | For automatic native results, `Automatic` and one of `"NativeOptions"`, `"NativeSpecification"`, or `"PackageRepresentation"`. |
| `"OrderConvention"` | `"Native"` for an automatically selected native result. |
| `"PackageFailure"` | The preceding package failure for a representation fallback; `None` when native routing occurred before a package attempt. |

Evaluation status is determined by inspecting the native result, in this order:

| Status | Condition |
| --- | --- |
| `"Aborted"` | The result contains `$Aborted`. |
| `"Failed"` | The result contains `$Failed` or a `Failure` expression. |
| `"Unresolved"` | An unevaluated native `Series` or `Asymptotic` call remains. |
| `"Computed"` | None of the preceding forms remains. |

These statuses do not establish an analytic remainder, exactness, or mathematical correctness. In particular, `"Computed"` does not change the missing analytic contract of a native result.

Literal explicit native calls keep their option expressions in the held request. The wrapper does not evaluate delayed native options again to fill metadata. A fallback after a package attempt instead reuses the prepared source and specifications, with the common assumptions and term-goal options materialized from that attempt. `"OriginalArguments"` retains the original input; `"NativeRequest"` records the selected call, and `"NativeAttempts"` records each automatic native call in order. `"AmbientAssumptions"` does not include an explicitly supplied `Assumptions` option; inspect the held request as well when reproducing a calculation.

When automatic native search has two compatible candidates, it resolves the effective explicitly supplied `Assumptions` and `SeriesTermGoal` values once and reuses them across attempts. The first occurrence of each option wins; unused delayed duplicates are not evaluated. Omitted options remain omitted so that native defaults apply. Explicit native calls and automatic requests restricted to a single backend retain native option evaluation behavior.

Automatic package preparation evaluates the source in the package's neutral proof context, where `$Assumptions` is `True`; captured assumptions are supplied separately to the engines. Literal explicit native calls release the source under the captured ambient context. Computed trailing argument or option containers are resolved before selecting the backend, while keeping the source held. The wrapper reuses the prepared source, specifications, and option containers across native attempts and after a package failure. This does not freeze user definitions or guarantee an identical ordering of arbitrary side effects across automatic preparation and a direct native call.

`Normal` does not guarantee a finite polynomial or finite sum. An infinite sum or another ordinary expression returned by a native calculation can remain in `Normal[s]`. For example, a native `Asymptotic` request can use order `Infinity`. See [Normal](https://reference.wolfram.com/language/ref/Normal.html).

```wolfram
u = AsymptoticExpansion[Exp[x], {x, 0, Infinity},
  "Backend" -> "Asymptotic"];
{u["NativeResult"], Normal[u]}
```

### Possible Issues

Package analytic arithmetic, truncation, and refinement do not infer error bounds from a native result; these operations return `Failure["NativeSeriesContract", ...]`. To continue using native formal-series operations, work with `s["NativeResult"]`:

```wolfram
SeriesCoefficient[s["NativeResult"], 3]
```

Use `Normal[s]` only when discarding the native series structure is intended. For a single identified variable, `s[value]` substitutes into the normalized expression; with several or unresolved variables it returns `Failure["NativeVariables", ...]`. Explicit substitution into `Normal[s]` is available in those cases and does not establish an error bound. Native results do not acquire the package's real-branch certification or uniform-parameter guarantees. An unevaluated native request is not evidence that an expansion was computed.

<a id="AsymptoticInverse"></a>
## AsymptoticInverse

### Usage

| Form | Result |
| --- | --- |
| `AsymptoticInverse[f, {x, x0}, {y, h}]` | Inverse approaching `x0` on the selected source side, with cutoff `h`. |
| `AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]` | First `n` complete nonzero inverse blocks. |
| `AsymptoticInverse[f, x, y, SeriesTermGoal -> n]` | Inverse approaching zero from above. |

The source symbol `x` and target symbol `y` must be distinct symbols without numeric values; a named constant such as `Pi` in either position returns `Failure["InvalidVariables", ...]`. The forward expression `f` must not contain `y`.

### Details and Options

| Option | Default | Meaning |
| --- | --- | --- |
| `Assumptions` | `$Assumptions` (delayed) | Parameter assumptions and source conditions valid eventually on the selected approach. An explicit option replaces the ambient assumptions. |
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

This section describes the package's analytic representations. Native results, whether selected explicitly or automatically, retain their backend's coordinates, domains, and order conventions; see [Native Expansion Backends](#native-backend-expansions).

### Positive Local Coordinates

Every ordinary expansion uses a positive coordinate tending to zero.

| Approach | Positive coordinate |
| --- | --- |
| `x -> x0`, from above | `x - x0` |
| `x -> x0`, from below | `x0 - x` |
| `x -> Infinity` | `1/x` |
| `x -> -Infinity` | `-1/x` |

An ordinary block has the form `w^beta P[Log[w]]`. All terms at the same exponent belong to one block, including the complete logarithmic polynomial. Provably equal exact exponents are combined even when they have different symbolic forms. Exact cancellation is performed before blocks are counted and before the logarithmic degree of a remainder is determined. See [Equal Exponents and Complete Blocks](#equal-exponent-blocks).

For an inverse, the target coordinate also includes the limiting value and selected sign. Use `s["RemainderVariable"]` to obtain the coordinate actually used; do not substitute `y` for it without checking the result.

<a id="choose-precision"></a>
### Choose a Cutoff or a Block Count

Use a cutoff when the power of the omitted error matters; use `SeriesTermGoal`
when the number of displayed nonzero blocks matters. Fix the backend explicitly
when comparing those conventions with a built-in order:

```wolfram
Clear[x];
powerCutoff = AsymptoticExpansion[Sin[x], {x, 0, 5},
  "Backend" -> "Package"];
twoBlocks = AsymptoticExpansion[Sin[x], {x, 0},
  SeriesTermGoal -> 2, "Backend" -> "Package"];
nativeOrder = AsymptoticExpansion[Sin[x], {x, 0, 5},
  "Backend" -> "Series"];
{Normal[powerCutoff], Normal[twoBlocks], Normal[nativeOrder]}
```

```wolfram
{x - x^3/6, x - x^3/6, x - x^3/6 + x^5/120}
```

The package cutoff excludes the `x^5` block and records
`powerCutoff["Remainder"]` as `PowerLogRemainder[x, 5, 0]`.
The two-block request happens to retain the same expression here; zeros at
even powers do not count as blocks. Native `Series` includes the requested
fifth order. Matching built-in order semantics across the complete public
interface is still part of the [coverage work](#native-coverage-gaps).

For an inverse or a specialized scale, first identify the coordinate and
prefactor. The number `5` need not mean a power of the original input variable;
the following table identifies the relevant precision parameter.

### Cutoff Meanings by Scale

| Result family | Meaning of the requested order |
| --- | --- |
| Native `Series` or `Asymptotic` result | Selected backend's native order convention; `Series` includes the requested order. No package analytic cutoff is inferred. |
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
| `Zeta[S]`, or an affine combination `alpha Zeta[S] + beta` with fixed exact real `alpha != 0` and `beta`, with a growing real affine argument `S` at a real infinity | Exclusive bound on `Log[n]` in the coordinate `Exp[-S]`; `SeriesTermGoal` counts the atom's terms and includes the constant term `n == 1`, which an affine constant may cancel. See [Zeta at Large Real Argument](#zeta-dirichlet-expansions). |
| `LerchPhi[z, s, a]`, or an affine combination of one such atom, with fixed admitted `z`, `s` and `a` tending to positive infinity | Exclusive absolute exponent bound in `1/a`; blocks have exponents `s + k`. See [LerchPhi at Large Third Argument](#lerch-large-argument-expansions). |
| Structured forward special-function expansion | Exclusive amplitude cutoff for each recorded exact carrier; term goals count its complete nonzero blocks separately. See [Other Special Functions](#special-function-expansions). |
| Special-function inverse adapter | Adapter-specific convention; see [AsymptoticSpecialInverse](#AsymptoticSpecialInverse). |

A cutoff is not a term count. For example, a sparse expansion can have its first omitted term strictly beyond the requested cutoff. `SeriesTermGoal -> n` counts complete nonzero blocks; an exact finite expansion can return fewer than `n` with zero remainder. A structured forward special-function result can contain several carriers, each with its own block count; its total number of returned blocks can therefore exceed `n`.

For Gamma, Barnes G, and elementary exponential products expanded through logarithmic normalization, the cutoff remains relative after cancellations between factors. This includes a balanced Gamma ratio. A structured special-function product whose exponential factors cancel can instead use ordinary absolute weights, as in `BesselI[0, x] BesselK[0, x]`. Ordinary elementary sources that are all bounded or merely logarithmically divergent also retain the ordinary absolute convention.

### Directions and Branches

At a finite source endpoint, `Direction -> Automatic` means `"FromAbove"`. At `Infinity` the approach is `"FromBelow"`; at `-Infinity` it is `"FromAbove"`.

`AsymptoticInverse` selects the local source branch approaching the supplied endpoint from the requested side. The endpoint and side are part of the problem, even when another branch has the same limiting target value.

For `AsymptoticExpansion`, `Direction` describes the approach of the expansion variable. When expanding an applied inverse, its source branch is a separate choice.

Conditions need only hold on a sufficiently small deleted neighborhood or sufficiently distant tail. For example, `0 < x < 1` is compatible with `x -> 0` from above. A condition that fails eventually on the requested approach is rejected.

<a id="assumption-context"></a>
## Assumptions and Parameter Domains

### Details

For package analytic representations, the nine constructors `AsymptoticExpansion`, `AsymptoticInverse`, `PowerLogModel`, `AsymptoticCoreInverse`, `AsymptoticExponentialCoreInverse`, `AsymptoticFlatInverse`, `AsymptoticFourierInverse`, `AsymptoticLogarithmicInverse`, and `AsymptoticSpecialInverse` use the default `Assumptions :> $Assumptions`. The default is resolved when a construction begins, so enclosing `Assuming` expressions supply its assumptions. An explicit `Assumptions` option replaces the ambient value. Use `Assumptions -> True` to construct without ambient assumptions.

`AsymptoticExpand` inherits this policy as an alias of `AsymptoticExpansion`. The approach-admission and saved-context rules below concern package analytic representations. Explicit native modes evaluate their held request under the captured ambient assumptions, leaving explicit native options to the backend. They retain the ambient value and held request without separately reevaluating options or adding a real-domain proof. See [Native Expansion Backends](#native-backend-expansions) for their distinct metadata.

The effective hypotheses are retained with the result and its models and internal representations. A delayed assumption option is resolved once for that construction. Subsequent calculations use the retained hypotheses rather than reevaluating the option.

`AsymptoticExpansion`, `AsymptoticInverse`, and `PowerLogModel` separate parameter-only clauses from clauses involving the source or expansion variable. The latter must hold eventually on the selected approach and are retained as domain conditions. Assumptions on an inverse's target variable are not parameter assumptions.

The other six constructors require parameter-only assumptions. They conservatively reject an assumption containing the source or target variable, including one inherited from `Assuming`. Specify the source approach with the constructor's endpoint, direction, and supported branch options; use an explicit parameter-only `Assumptions` option when the surrounding context also contains variable conditions.

### Basic Examples

Construct an inverse using the surrounding assumptions:

**Input**

```wolfram
Clear[x, y, a];
s = Assuming[a > 0,
  AsymptoticInverse[a x + x^2, {x, 0}, {y, 3}]];
{Normal[s], s["Assumptions"]}
```

**Output**

```wolfram
{y/a - y^2/a^3, a > 0}
```

An explicit option takes precedence over a conflicting ambient assumption:

**Input**

```wolfram
Normal[Assuming[a < 0,
  AsymptoticExpansion[Abs[a] + x, {x, 0, 2},
    Assumptions -> a > 0]]]
```

**Output**

```wolfram
a + x
```

Explicitly disable ambient assumptions:

**Input**

```wolfram
Normal[Assuming[a > 0,
  AsymptoticExpansion[Abs[a] + x, {x, 0, 2},
    Assumptions -> True]]]
```

**Output**

```wolfram
Abs[a] + x
```

### Operations on Existing Results

Arithmetic, observables, composition, refinement, coefficient queries, residual checks, and numerical checks use the assumptions retained by their operands. Combining two results combines their retained hypotheses. A later `Assuming` expression does not specialize an existing result or supply an additional sign or realness proof. These operations do not have a new `Assumptions` option.

Refine the saved inverse above in a different ambient context:

**Input**

```wolfram
t = Assuming[a < 0, SeriesRefine[s, 5]];
{Normal[t], t["Assumptions"]}
```

**Output**

```wolfram
{y/a - y^2/a^3 + 2 y^3/a^5 - 5 y^4/a^7, a > 0}
```

To use additional parameter hypotheses, supply them when constructing a new result. This also applies to symbols that occur only in a later regular operand. For example, multiplying a series by `b` requires `b` to be proved real under the series' retained assumptions; enclosing that multiplication in `Assuming[Element[b, Reals], ...]` does not add the missing hypothesis.

### Real Coefficients

Ordinary power-log expansions require real coefficients, including constant terms and inverse target limits. Symbolic coefficients need assumptions that establish their realness:

**Input**

```wolfram
Clear[a, x];
s = AsymptoticExpansion[a + Sin[a] x, {x, 0, 2},
  Assumptions -> Element[a, Reals]];
{Normal[s], s["Remainder"]}
```

**Output**

```wolfram
{a + Sin[a] x, 0}
```

Without the realness assumption, a coefficient `a` produces `Failure["UnprovedRealCoefficient", ...]` in strict `"Package"` mode. Automatic mode can instead retain a native formal result; that result does not assert real coefficients. A real argument alone does not make every function value real: `ArcSin[a]` needs a suitable interval assumption, such as `-1 < a < 1`, for a real analytic representation.

Contributions at equal powers are combined and simplified before their coefficients are checked. For example:

**Input**

```wolfram
Clear[a, b, x];
Normal[AsymptoticExpansion[x Log[-a] - x Log[-b] + x^2,
  {x, 0, 3}, Assumptions -> a > 0 && b > 0]]
```

**Output**

```wolfram
x (Log[a] - Log[b]) + x^2
```

The individual logarithms have imaginary parts that cancel. A surviving complex coefficient, as in `Log[-a] + x` under `a > 0` or `ArcSin[2 + x]` at zero, is rejected by `"Backend" -> "Package"`. An unprotected `Automatic` request can instead select a native representation. The package failure data distinguish `"Realness" -> "Nonreal"` from `"Realness" -> "Unproved"`; the latter means that the retained assumptions did not prove the required condition.

`SeriesObservable` applies the same check to the completed observable, using its operand's retained assumptions. Complex intermediate Taylor coefficients may cancel across an expression, as in `ArcSin[2 + z] + ArcCos[2 + z]`. General coefficient checking does not discard imaginary parts. The structured special-function method can project a native approximation to its real part only after independently proving the source real and transporting its absolute error bound.

Real finite coefficients alone do not prove that an arbitrary source function is real. Coefficient checks supplement the supported source and branch conditions.

### Scope

Parameters remain fixed in the limiting process. An expansion valid for each fixed `a > 0` does not assert a bound uniform as `a` tends to zero. Branch conditions, error constants, and the neighborhood where the estimate holds may depend on the parameters.

Ordinary Wolfram Language evaluation and symbol definitions remain in effect. Retaining assumptions does not freeze parameter values, function definitions, or explicit evaluation performed before a constructor is called. Keep source, target, and symbolic parameter names unassigned while using symbolic results. `Normal[s]` returns an ordinary expression; subsequent simplification of that expression follows the caller's evaluation context and does not update `s` or its remainder.

<a id="GeneralizedSeries"></a>
## GeneralizedSeries

### Usage

`GeneralizedSeries[association]` is the result representation returned by the constructors. Use constructors, supported arithmetic, and series operations to create and transform it.

`GeneralizedSeries` represents all supported scales, including power-log,
logarithmic, exponential, flat-sector, Fourier, and native results. Use
`MatchQ[s, _GeneralizedSeries]` to recognize a result.

Since version 1.8.0, `GeneralizedSeries` replaces the former `PowerLogSeries`
head. Explicit patterns and saved input using the former name must be updated.

| Form | Meaning |
| --- | --- |
| `Normal[s]` | The stored `"Expression"` without the package wrapper; a native result stores its construction-time normalization, which need not be finite. |
| `s["property"]` | A stored property, or `Missing["KeyAbsent", "property"]` when absent. |
| `s["Properties"]` | The keys stored in this particular result, rather than a universal list of supported fields. |
| `s[value]` | Evaluation of the approximation at a numerical value when a single expansion variable is identified; native multivariable results require explicit substitution. |

### Display and Evaluation

In `StandardForm` and `TraditionalForm`, an analytic series displays its finite expression and its `O[...]` remainder. A native result displays its stored native form without adding a package remainder. The `GeneralizedSeries` head is hidden in these forms. For example:

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

The underlying object still has head `GeneralizedSeries`. Copying the formatted object into Wolfram Language input preserves the full series, including its remainder and metadata. The formatted object is read-only; use constructors, supported arithmetic, or series operations to change it.

| Form | Display or result |
| --- | --- |
| `StandardForm[s]`, `TraditionalForm[s]` | Analytic expression and remainder, or the preserved native result, without the wrapper head. |
| `Head[s]` | `GeneralizedSeries`. |
| `InputForm[s]` | Full reconstructible `GeneralizedSeries[association]` representation, including metadata. |
| `OutputForm[s]` | Compact diagnostic representation. |
| `Normal[s]` | Stored approximation expression; the package wrapper and its separate analytic remainder metadata are omitted. Native normalization follows the backend result. |

For the example above, `Normal[s]` returns `y - y^2 + 2 y^3 - 5 y^4`. Arithmetic on `s` propagates its remainder:

```wolfram
s + s
s^2
SeriesNormalize[(1 + s)/(1 - s), "Cutoff" -> 4]
```

Ordinary arithmetic on `Normal[s]` uses only the normalized expression. Keep an analytic series object when further operations must include its uncertainty. Native formal calculations instead use `s["NativeResult"]`; package analytic operations do not infer an error theorem for that representation. See [Series Arithmetic and Normalization](#series-operations) for supported functions, branch requirements, and precision rules.

### Common Properties

| Property | Meaning |
| --- | --- |
| `"Expression"` | The same expression returned by `Normal`; native results need not be finite. |
| `"Remainder"` | Complete analytic remainder descriptor, including any absolute prefactor, or `Missing["NativeContract"]` for a native result. |
| `"RemainderVariable"` | Positive small coordinate. |
| `"RemainderPower"`, `"RemainderLogDegree"` | Recorded order and logarithmic degree. |
| `"RemainderScaleExpression"` | Explicit scale used for numerical comparison, when supplied by the result family. |
| `"AbsoluteRemainderBound"`, `"RemainderBoundConditions"` | Explicit forward error bound and its conditions, when supplied by a defining-sum constructor such as the large-argument `Zeta` or `LerchPhi` expansion. |
| `"FrontierTerm"` | Computed first omitted term, or an indication that it is unknown. |
| `"Terms"` | Displayed coefficient data. Read `"TermConvention"` for their interpretation. |
| `"Scale"` | Result scale, when explicitly recorded. |
| `"Prefactor"`, `"Offset"` | Exact factor and translation for a factored representation. |
| `"Cutoff"` | Requested or selected truncation boundary. |
| `"Function"`, `"Variable"`, `"ExpansionPoint"`, `"Direction"` | Retained expression and approach data, when supplied. |
| `"Assumptions"`, `"TargetDomain"`, `"SourceDomain"` | Retained assumptions and branch conditions. Available domains depend on the result family. |
| `"Exact"` | Exact finite expansion status for analytic results, when supplied; `Missing["NotEstablished"]` for native results. Zero analytic remainder is the operative exactness test. |
| `"ExactModel"` | Exactness of a stored model; it does not by itself say that the displayed inverse terminates. |
| `"SeriesData"` | A native `SeriesData` object when the coordinate, exponents, remainder degree, and retained coefficient span permit it; otherwise `Missing[...]`. |
| `"NativeResult"`, `"RemainderContract"` | Original backend result and its distinct contract for a result with `"Kind" -> "Native"`; see [Native Expansion Backends](#native-backend-expansions). |

Property availability varies by family. Inspect `s["Properties"]` before relying on specialized metadata. Do not edit the underlying association to change a branch or precision claim.

The [result-property reference](ResultReference.md) groups the actual fields
by representation and explains absent values, exactness, coordinates, and
native metadata. For example, an ordinary forward result can omit `"Scale"`,
and an ordinary inverse can record `"ExactModel"` without an `"Exact"` field.
Those absences do not by themselves mean that construction failed.

An arithmetic result with `"Scale" -> "Composite"` retains a finite expression and separate error scales. It has no single remainder exponent or cutoff. See [Composite Results](#composite-series-results).

<a id="native-series-remainder-view"></a>
#### Native SeriesData View

This optional view exports an existing analytic representation. It is separate from preserving a complete result obtained with `"Backend" -> "Series"`.

Native `SeriesData` records a rational power cutoff. The package's analytic remainder also records a logarithmic degree. For an otherwise eligible view, a positive remainder degree returns

```wolfram
Missing["LogarithmicRemainder",
  <|"RemainderPower" -> rho, "RemainderLogDegree" -> degree|>]
```

This prevents `O[w^rho (1 + Abs[Log[w]])^degree]` from being represented as an analytic `O[w^rho]` bound. Use the complete `s["Remainder"]` descriptor when continuing calculations.

**Input**

```wolfram
s = AsymptoticExpansion[x + x^2 Log[x], {x, 0, 2}];
{s["Remainder"], s["SeriesData"]}
```

**Output**

```wolfram
{PowerLogRemainder[x, 2, 1],
 Missing["LogarithmicRemainder",
   <|"RemainderPower" -> 2, "RemainderLogDegree" -> 1|>]}
```

Logarithms are still permitted in retained coefficients when the remainder degree is zero:

```wolfram
t = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
Head[t["SeriesData"]]
```

```wolfram
SeriesData
```

Here the retained expression is `x Log[x]` and the remainder is `PowerLogRemainder[x, 3, 0]`. Native logarithmic coefficients and the package's stricter remainder export policy serve different purposes. See the Wolfram Language documentation for [SeriesData](https://reference.wolfram.com/language/ref/SeriesData.html).

The optional native view stores coefficients only through the last retained
exponent. Its remainder index can be much larger without allocating trailing
zeros. If gaps between retained rational exponents would require more than
100,000 dense coefficient slots, `s["SeriesData"]` returns
`Missing["DenseSeriesDataLimit", <|"RequiredCoefficients" -> count, "Limit" -> 100000|>]`.
The sparse terms, `Normal[s]`, remainder, and supported series operations remain
available. This bound applies to the optional native view and is independent
of the `"MaxTerms"` construction option.

The native view also requires representable lattice indices. Write
`b = 2^($SystemWordLength - 1)`. Its denominator must be an integer from
`1` through `b - 1`, both endpoint indices must lie from `-b` through
`b - 1`, and their difference must lie from `0` through `b - 1`.
If any of these conditions fails, the property returns

```wolfram
Missing["NativeSeriesDataRange",
  <|"Indices" -> {nmin, nmax, den}, "OrderSpan" -> nmax - nmin,
    "AllowedIndexRange" -> {-b, b - 1},
    "MaximumDenominator" -> b - 1, "MaximumOrderSpan" -> b - 1|>]
```

These checks precede dense coefficient allocation and inverse coefficient
scaling. They apply even when only one coefficient is retained, and valid
individual endpoints do not guarantee a valid difference. The sparse
expansion, `Normal[s]`, and its remainder remain usable when this optional
view is unavailable.

For example, the following request retains the constant term and its exact
omitted order even though the native index is too large:

```wolfram
Clear[x];
large = 2^100;
s = AsymptoticExpansion[1 + x^large, {x, 0, large},
  "Backend" -> "Package"];
{Normal[s], s["Remainder"],
 MatchQ[s["SeriesData"], Missing["NativeSeriesDataRange", _Association]]}
(* {1, PowerLogRemainder[x, 2^100, 0], True} *)
```

The `Missing` property describes an export limit; the construction itself
still returned an analytic `GeneralizedSeries` result.

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

<a id="equal-exponent-blocks"></a>
#### Equal Exponents and Complete Blocks

The exact exponents `Sinh[1]^2` and `(Cosh[2] - 1)/2` are equal. Contributions at these exponents are collected before `SeriesTermGoal` counts nonzero blocks.

**Input**

```wolfram
With[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2},
  s = AsymptoticExpansion[x^a - x^b + x^2, {x, 0},
    SeriesTermGoal -> 1, "Backend" -> "Package"];
  {Normal[s], s["Remainder"], s["ReturnedTermCount"]}
]
```

**Output**

```wolfram
{x^2, 0, 1}
```

The entire logarithmic coefficient belongs to the same block. Its degree also contributes to the remainder of a product.

**Input**

```wolfram
With[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2},
  s = AsymptoticExpansion[
    1 + x^a + x^b Log[x]^3 + x^(2 a),
    {x, 0, 2 a}, "Backend" -> "Package"];
  t = SeriesMultiply[s, s];
  {t["RemainderLogDegree"], Length[t["Terms"]]}
]
```

**Output**

```wolfram
{6, 2}
```

Writing `a = Sinh[1]^2`, the retained expression is `1 + 2 x^a (1 + Log[x]^3)`. Its remainder has power `2 a` and logarithmic degree `6`, because squaring the complete coefficient produces a `Log[x]^6` term.

Distinct exact exponents remain distinct however small their difference. Equality is not inferred from numerical closeness. Equal-power collection also occurs before an ordinary inverse model selects its leading power and perturbation gaps.

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

<a id="special-function-expansions"></a>
#### Other Special Functions

`AsymptoticExpansion` expands additional Wolfram Language special functions at finite endpoints and real infinities. The result can contain ordinary powers and logarithms, an exact exponential factor, or bounded sine and cosine coefficients.

Expand a Bessel function at zero:

```wolfram
s = AsymptoticExpansion[BesselJ[0, x], x -> 0,
  SeriesTermGoal -> 5];
Normal[s]
```

```wolfram
1 - x^2/4 + x^4/64 - x^6/2304 + x^8/147456
```

The five nonzero blocks have exponents `0`, `2`, `4`, `6`, and `8`. The remainder is of order `x^10`.

The following table gives representative supported cases. Parameters are fixed during the limiting process unless they are explicitly part of the expansion argument. Admission depends on the parameter values, branch, and endpoint; a function name alone does not establish support for every limit.

| Family | Finite endpoints | Large arguments |
| --- | --- | --- |
| `BesselJ`, `BesselI`, `BesselK` | Taylor series, leading real powers, and logarithmic singularities | Growing and decaying modified Bessel factors; oscillatory `BesselJ` expansions |
| `AiryAi`, `AiryBi` | Regular expansions, including translated arguments | Exponential factors on the positive axis; oscillatory `AiryAi[-x]` as `x` tends to infinity |
| `Erf`, `Erfc`, `Erfi`, `DawsonF` | Regular expansions | Gaussian tails of `Erfc` and `Erfi`; the exponentially small correction to `Erf` |
| `FresnelC`, `FresnelS`, `SinIntegral`, `CosIntegral` | Regular or logarithmic expansions | Oscillatory algebraic tails, with their limiting constants retained |
| `ExpIntegralEi`, `ExpIntegralE` | Logarithmic and regular expansions on admitted real branches | Growing or decaying exponential factors |
| Incomplete `Gamma`, `GammaRegularized`, `PolyGamma` | Positive-argument expansions and admitted endpoint powers | Incomplete Gamma expansions with fixed shape and large positive argument |
| `Zeta`, `PolyLog` | The pole of `Zeta` and regular or logarithmic polylogarithm endpoints | A Dirichlet expansion of `Zeta[S]` for growing real affine `S`; the distinct Hurwitz-zeta expansion of `Zeta[2, x]`; the real branch of `PolyLog[2, -x]` |
| `LerchPhi` | Admitted regular argument expansions; a growing third argument can also occur at a finite endpoint | Reciprocal-third-argument expansion for fixed exact real numeric `z`, `s` with `-1 < z < 1` |
| Hypergeometric functions | Fixed-parameter expansions and supported terminating parameter cases | For example, the algebraic expansion of `HypergeometricU[3/2, 1/2, x]` |
| `EllipticK`, `EllipticE` | Expansions at parameter zero and the logarithmic threshold of `EllipticK[1 - x]` | Use an admitted change of argument to reach a finite parameter endpoint |

For complete Gamma and Barnes G products, use the interfaces described in the preceding subsections. The table does not assert uniform expansions when an order, shape, and argument grow together. In particular, fixed-order Bessel expansions do not establish a formula for `BesselJ[x, x]`. Similarly, `Zeta[2, x]` and `Zeta[x]` have different limiting variables and asymptotic scales.

##### Logarithmic and Algebraic Singularities

Expand a lower incomplete Gamma function from the positive side:

```wolfram
s = AsymptoticExpansion[Gamma[3/2, 0, x], x -> 0,
  SeriesTermGoal -> 3];
Normal[s]
```

```wolfram
2 x^(3/2)/3 - 2 x^(5/2)/5 + x^(7/2)/7
```

A complete polynomial in the logarithm counts as one block. For example:

```wolfram
s = AsymptoticExpansion[EllipticK[1 - x], x -> 0,
  SeriesTermGoal -> 3];
ell = Log[4] - Log[x]/2;
```

The finite part is equivalent to:

```wolfram
ell + x (ell - 1)/4 + 9 x^2 (ell - 7/6)/64
```

Its three blocks have powers `0`, `1`, and `2`; each logarithmic coefficient is retained in full. Wolfram Language uses the elliptic parameter `m`, whereas formulas expressed in terms of a modulus use `m == k^2`. Here the complementary modulus is `Sqrt[x]`. [DLMF 19.12](https://dlmf.nist.gov/19.12).

<a id="zeta-dirichlet-expansions"></a>
##### Zeta at Large Real Argument

Expand the Riemann zeta function as its real argument tends to positive infinity:

**Input**

```wolfram
s = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
Normal[s]
```

**Output**

```wolfram
1 + 2^-x + 3^-x
```

This expansion uses the positive coordinate `w = Exp[-x]`. Its terms are `w^Log[n]`, beginning with the constant `n == 1`. Thus three blocks have exponents `0`, `Log[2]`, and `Log[3]`; the first omitted block is `4^-x`. These terms come from the convergent defining Dirichlet series for `Zeta`, rather than a series in `1/x`. [DLMF 25.2.1](https://dlmf.nist.gov/25.2.E1).

An explicit cutoff is exclusive in this exponential coordinate:

```wolfram
s = AsymptoticExpansion[Zeta[x], {x, Infinity, Log[4]}];
{Normal[s], s["RemainderVariable"], s["RemainderPower"]}
```

```wolfram
{1 + 2^-x + 3^-x, Exp[-x], Log[4]}
```

A cutoff `h` retains precisely the integers with `Log[n] < h`. A cutoff of zero therefore retains no finite terms and has a nonzero order-one remainder. The number of terms grows exponentially with `h`; `SeriesTermGoal` gives direct control over the count, subject to `"MaxTerms"`. When both are given they stop independently, whichever comes first, as in every other constructor: `AsymptoticExpansion[Zeta[x], {x, Infinity, Log[4]}, SeriesTermGoal -> 1]` returns the constant `1` with first omitted integer `2`, and an active goal also caps the work a large cutoff would otherwise request, so `SeriesTermGoal -> 1` with the cutoff `10^6` succeeds under a small `"MaxTerms"`. The same rule applies to the `LerchPhi` blocks below.

The argument may be a real affine expression `S = a x + b` tending to positive infinity as `x` tends to either real infinity:

```wolfram
AsymptoticExpansion[Zeta[2 x + 3], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[Zeta[-3 x + 2], x -> -Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[Zeta[a x + b], x -> Infinity,
  SeriesTermGoal -> 3, Assumptions -> a > 0 && Element[b, Reals]]
```

The coordinate remains `Exp[-S]`, so the finite expression is `1 + 2^-S + 3^-S`. This defining-sum method requires an affine argument and a real infinite endpoint. Its domain includes `S > 1`; it does not admit an argument tending to negative infinity.

The result supplies explicit forward tail bounds. If `m = s["FirstOmittedInteger"]` and `S = s["SourceArgument"]`, the positive omitted tail satisfies

```wolfram
m^-S <= Zeta[S] - Normal[s] <= m^-S (1 + m/(S - 1))
```

under `s["RemainderBoundConditions"]`, including `S > 1`. The corresponding properties are `"RemainderLowerBound"` and `"AbsoluteRemainderBound"`. For three blocks of `Zeta[x]`, the upper bound is `4^-x (1 + 4/(x - 1))`. These are analytic bounds for the forward defining sum; they do not constitute a numerical interval certificate or an inverse-error certificate. `SeriesTruncate[s, Log[3]]` keeps `1 + 2^-x` and transports the upper bound to `4^-x (1 + 4/(x - 1)) + 3^-x`; see [SeriesTruncate](#SeriesTruncate). Sums, products, scalar multiples and shifts of such expansions transport the bound as well: for finite parts `e1`, `e2` with bounds `B1`, `B2`, a sum is bounded by `B1 + B2` and a product by `Abs[e1] B2 + Abs[e2] B1 + B1 B2`, each plus the absolute value of the exact part of the finite expressions discarded by the result's cutoff, which the result records as `"ArithmeticDiscardedPart"` with a `"TransportedThroughArithmetic"` contract under the conjunction of the operand conditions. The signed lower bound and the Lerch constant form are not transported through arithmetic.

An affine combination of one such atom with fixed exact real coefficients is expanded with the atom: `Zeta[x] - 1` retains `2^-x + 3^-x + ...` with the same remainder, cutoff and first omitted integer as `Zeta[x]`, and `-2 Zeta[x] + 3` scales every retained coefficient and the absolute bound by the affine coefficient. The result records `"AffineCoefficients" -> {alpha, beta}` and `"SpecialFunctionAtom"`. `SeriesTermGoal` still counts the atom's terms, so `SeriesTermGoal -> 3` for `Zeta[x] - 1` returns the two nonconstant terms `2^-x + 3^-x`. The signed lower bound `"RemainderLowerBound"` is kept only for a positive coefficient; an affine constant lying above an explicit cutoff is charged to `"AbsoluteRemainderBound"` instead of being displayed. Products with the variable, two different atoms, and variable coefficients are outside this method.

<a id="lerch-large-argument-expansions"></a>
##### LerchPhi at Large Third Argument

Expand Lerch's transcendent with its first two parameters fixed:

**Input**

```wolfram
s = AsymptoticExpansion[LerchPhi[1/2, 2, x], x -> Infinity,
  SeriesTermGoal -> 3];
Normal[s]
```

**Output**

```wolfram
2/x^2 - 4/x^3 + 18/x^4
```

For `LerchPhi[z, s, a]`, this method requires fixed exact real numeric values of `z` and `s`, with `-1 < z < 1`, and a third argument proved to tend to positive infinity. The parameter `s` may be negative or noninteger. Symbolic `z`, symbolic `s`, the endpoints `z == -1` and `z == 1`, and varying first or second parameters are outside this method's scope. No uniformity as these parameters vary is asserted.

The coordinate is `w = 1/a`. Its absolute block exponents are `s + k`, and the coefficients are

```wolfram
(-1)^k Pochhammer[s, k] M[k]/k!
```

where `M[0] = 1/(1 - z)` and `M[k] = PolyLog[-k, z]` for positive integers `k`. These moments arise from the convergent geometric-weight defining sum. The resulting expansion in `1/a` is generally a Poincare expansion; its convergence is not asserted. [DLMF 25.14.1](https://dlmf.nist.gov/25.14.E1).

An exclusive cutoff of four retains only the blocks at exponents two and three:

```wolfram
s = AsymptoticExpansion[LerchPhi[1/2, 2, x], {x, Infinity, 4}];
Normal[s]
```

```wolfram
2/x^2 - 4/x^3
```

The argument and its coordinate are preserved under scaling or translation. A large third argument can also occur at a finite endpoint:

```wolfram
AsymptoticExpansion[LerchPhi[1/2, 2, 2 x + 1], x -> Infinity,
  SeriesTermGoal -> 3]
AsymptoticExpansion[LerchPhi[1/2, 2, 1/x], x -> 0,
  SeriesTermGoal -> 3]
```

The first call uses `1/(2 x + 1)` and has finite part `2/(2 x + 1)^2 - 4/(2 x + 1)^3 + 18/(2 x + 1)^4`. The second uses `x` and has finite part `2 x^2 - 4 x^3 + 18 x^4`.

For an omitted moment, `"RemainderBoundConstant"` gives an explicit constant `C`, and `"AbsoluteRemainderBound"` is `C a^-rho`, where `rho` is the first omitted absolute exponent. The bound is valid under `"RemainderBoundConditions"`, which includes `a >= 1`. Negative `z` uses moments of `Abs[z]` in the bound, even though its expansion coefficients use the signed value of `z`.

```wolfram
s = AsymptoticExpansion[LerchPhi[1/2, 2, x], x -> Infinity,
  SeriesTermGoal -> 3];
{s["FrontierTerm"], s["AbsoluteRemainderBound"],
  s["RemainderBoundConditions"]}
```

The first omitted term is `-104/x^5`; the absolute error bound is `104/x^5` for `x >= 1`. The expansion itself is on the domain `x > 0`. The explicit bound does not establish bounds for derivatives or inverse expansions.

When `z == 0`, the source is exactly `a^-s`. When `s` is a nonpositive integer, its expansion in `a` is a finite polynomial. For example:

```wolfram
s = AsymptoticExpansion[LerchPhi[1/2, -2, x], x -> Infinity,
  SeriesTermGoal -> 5];
{Normal[s], s["Remainder"]}
```

```wolfram
{2 x^2 + 4 x + 6, 0}
```

An exact finite source has zero remainder only when all its nonzero blocks are retained. A smaller term goal or cutoff still records the omitted polynomial terms as an error. Some exact parameter cases simplify to elementary expressions before expansion and consequently have the ordinary result properties.

##### Exponential Factors and Products

Expand a decaying modified Bessel function:

```wolfram
s = AsymptoticExpansion[BesselK[0, x], x -> Infinity,
  SeriesTermGoal -> 3];
```

The finite part is equivalent to:

```wolfram
Sqrt[Pi/(2 x)] Exp[-x] (1 - 1/(8 x) + 9/(128 x^2))
```

The exact factor carries the exponential and leading algebraic dependence. The requested blocks describe the remaining amplitude. Positive scaling and translation are supported when the resulting branch and expansion can be established:

```wolfram
AsymptoticExpansion[Erfc[2 x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[AiryAi[1 + x], {x, 0, 3}]
```

Expand a product after cancellation of its exponential factors:

```wolfram
s = AsymptoticExpansion[BesselI[0, x] BesselK[0, x],
  x -> Infinity, SeriesTermGoal -> 3];
```

The finite part is equivalent to:

```wolfram
(1 + 1/(8 x^2) + 27/(128 x^4))/(2 x)
```

The three nonzero terms have absolute powers `x^-1`, `x^-3`, and `x^-5`. Odd powers inside the displayed bracket cancel. [DLMF 10.40.6](https://dlmf.nist.gov/10.40.E6).

##### Oscillatory Expansions

Expand an oscillatory Bessel function on the positive axis:

```wolfram
s = AsymptoticExpansion[BesselJ[0, x], x -> Infinity,
  SeriesTermGoal -> 3];
theta = x - Pi/4;
```

The finite part is equivalent to:

```wolfram
Sqrt[2/(Pi x)] (Cos[theta] + Sin[theta]/(8 x) -
  9 Cos[theta]/(128 x^2))
```

The remainder describes an absolute error. Zeros of the sine or cosine coefficient do not provide a nonzero leading term for division or a relative-error estimate.

```wolfram
AsymptoticExpansion[AiryAi[-x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[FresnelC[x], x -> Infinity, SeriesTermGoal -> 3]
AsymptoticExpansion[SinIntegral[x], x -> Infinity, SeriesTermGoal -> 3]
```

##### Block Counts and Cutoffs

A structured special-function expansion can contain several exact factors, called carriers. A carrier has an amplitude in powers of the positive local coordinate, with complete logarithmic polynomials and bounded oscillations in its coefficients.

`SeriesTermGoal -> n` applies separately to the nonzero amplitude blocks associated with each distinct carrier. It does not impose one global ordering on different exponentials. An exact finite contribution can have fewer than `n` blocks.

The limiting constant in `Erf[x]` and its Gaussian tail have different carriers. A request for three blocks can therefore retain the constant and three Gaussian correction blocks. In `SinIntegral[x]`, the constant and the algebraic oscillatory tail share a carrier; three blocks retain the constant and the first two oscillatory corrections.

An explicit cutoff is exclusive in each recorded amplitude coordinate. With an exponential or oscillatory carrier, the leading algebraic power may be included in that carrier. An ordinary expansion with no such factor uses the absolute power of the local coordinate. Inspect `s["NativeSectors"]` for the carriers, amplitude blocks, and cutoffs of a structured special-function result. Arithmetic that subsequently produces a composite result follows the separate [composite error rules](#composite-series-results).

A native power cutoff does not specify the logarithmic degree of an unresolved tail. For an admitted expansion whose asymptotic theorem gives a finite logarithmic degree, the package can use a conservative power bound. If the native cutoff is `rho` and its exponent spacing is `1/q`, the bound uses power `rho - 1/(2 q)` and logarithmic degree zero. A computed complete omitted block can give a sharper bound only when the remaining unresolved tail has a strictly higher power. Retained coefficient degrees alone do not establish a tail bound.

The cutoff selects retained blocks; the resulting analytic error can have a smaller power. Inspect the returned remainder rather than interpreting the requested cutoff as a log-free error bound:

```wolfram
s = AsymptoticExpansion[EllipticK[1 - x^2]/x^3, {x, 0, 3}];
{Normal[s], s["RemainderPower"], s["RemainderLogDegree"]}
```

The logarithmic tail in this example cannot be assigned `PowerLogRemainder[x, 3, 0]`. Additional computed terms may sharpen a conservative bound. An unevaluated native tail, without an applicable asymptotic theorem, does not establish a finite logarithmic degree or a zero error.

##### Fixed Parameters and Irrational Arguments

At finite argument endpoints, supported functions with fixed parameters can be composed with real powers and other admitted small arguments:

```wolfram
AsymptoticExpansion[BesselJ[Sqrt[2], x^Sqrt[2]], {x, 0, 5}]
AsymptoticExpansion[PolyGamma[1, 1 + x^Sqrt[2]], {x, 0, 5}]
AsymptoticExpansion[Gamma[3/2, 0, x^Sqrt[2]], {x, 0, 5}]
AsymptoticExpansion[Hypergeometric0F1[b, x^Sqrt[2]],
  {x, 0, 5}, Assumptions -> b > 0]
```

The finite-argument composition method requires one varying function argument; the other parameters remain fixed. Supply assumptions that establish the real branch and exclude parameter poles. A symbolic parameter assumption does not by itself make a varying exponent orderable in every series class.

The same finite-argument expansions can supply the forward coefficients needed by an admitted inverse constructor:

```wolfram
AsymptoticInverse[Erf[x], {x, 0}, y, SeriesTermGoal -> 3]
AsymptoticInverse[BesselJ[1, x], {x, 0}, y, SeriesTermGoal -> 3]
AsymptoticInverse[x + BesselJ[0, x^Sqrt[2]] - 1,
  {x, 0}, {y, 4}]
```

The inverse still requires its own endpoint, leading-term, and branch conditions. Forward expansion support does not define an inverse branch automatically.

##### Exact Identities, Refinement, and Numerical Evaluation

Exact special-function identities are preserved before truncation. For example, `BesselK[1/2, x]` has one exact exponential factor, while `BesselI[1/2, x]` contains both positive and negative exponentials. A terminating dominant expansion alone does not justify dropping the second exponential or declaring zero error.

```wolfram
k = AsymptoticExpansion[BesselK[1/2, x], x -> Infinity,
  SeriesTermGoal -> 3];
k["Remainder"]
```

```wolfram
0
```

Use `Normal` to obtain the ordinary finite expression. `SeriesRefine` reconstructs a forward expansion from its original source at a new cutoff:

```wolfram
s = AsymptoticExpansion[BesselJ[0, x], {x, 0, 4}];
Normal[s]
SeriesRefine[s, 8]
s + s
```

Arithmetic retains the operand errors. When no common ordered coefficient scale is available, compatible results can use separate composite error envelopes. A result with oscillatory coefficients does not acquire a valid reciprocal merely because its displayed leading coefficient is sometimes nonzero.

Evaluate a finite approximation and compare its error to the recorded remainder scale:

```wolfram
s = AsymptoticExpansion[Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
With[{xx = 20},
  N[Abs[Erfc[xx] - (Normal[s] /. x -> xx)]/
    (s["RemainderScaleExpression"] /. x -> xx), 40]]
```

This is a numerical sample. A Poincare remainder specifies an asymptotic error class with an unspecified constant; it is not a pointwise numerical certificate. The [Zeta](#zeta-dirichlet-expansions) and [LerchPhi](#lerch-large-argument-expansions) defining-sum methods additionally supply explicit forward bounds under their recorded conditions. Convergence, derivative bounds, and certified inverse-error bounds require their own stated hypotheses.

##### Branches and Unsupported Cases

The requested real branch must be established on the chosen approach. For example, noninteger-order `BesselJ` at a negative argument, `BesselK` on its negative-axis cut, and `EllipticK[1 + x]` for small positive `x` are not admitted as real expansions:

```wolfram
AsymptoticExpansion[BesselJ[Sqrt[2], -x], x -> 0,
  SeriesTermGoal -> 3, "Backend" -> "Package"]
AsymptoticExpansion[BesselK[0, -x], x -> Infinity,
  SeriesTermGoal -> 3, "Backend" -> "Package"]
AsymptoticExpansion[EllipticK[1 + x], x -> 0,
  SeriesTermGoal -> 3, "Backend" -> "Package"]
```

An unevaluated native expansion, a parameter pole, or a coefficient outside the supported real power-log and bounded-oscillation classes can return `Failure` in the package analytic path. A native result retained by another route has its native contract; it does not supply the missing real-domain or analytic-tail proof. The fact that a function has numerical values does not establish an admissible analytic expansion at every endpoint.

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

An inner `ConditionalExpression` restricts the original source. An outer condition restricts the expansion variable through its clauses that mention that variable; its parameter-only clauses, such as `a > 0` in `ConditionalExpression[x + a x^2, a > 0]`, are parameter assumptions, exactly as in the `Assumptions` option. Native evaluation of an inverse to `ArcSin`, a radical, or another closed form retains that closed form's branch.

If an unevaluated inverse operator admits more than one source branch, supply an explicit selection:

```wolfram
operator = InverseFunction[Function[t, t^2 + t^4 (1 + Log[t^2])]];
branches = Association[
  operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
s = AsymptoticExpansion[operator[y], {y, 0, 2},
  "InverseFunctionBranches" -> branches];
```

The key is the inverse operator without its target argument. Every selection must satisfy the retained source condition and requested limiting target. A branch option cannot change a native closed form that has already replaced the operator.

Automatic branch selection also needs evidence that its candidate search is complete or that the selected branch is unique. A single candidate in a finite search is insufficient by itself. For a supported connected real source domain, a strict derivative sign can establish uniqueness. Mathics supplies this proof only for the bounded polynomial and affine-domain cases described in its [callable guide](../../docs/Mathics/CALLABLES.md); its treatment of an unevaluated inverse can therefore differ from Wolfram's earlier conversion to a closed form.

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

Assumptions must justify the relevant signs, real branches, and exponent comparisons. Constructor defaults capture the surrounding `Assuming` context; explicit options replace it. Later operations use the hypotheses retained in the result. See [Assumptions and Parameter Domains](#assumption-context). Approximate data are not made exact by adding assumptions.

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

<a id="log-power-normalization"></a>
##### Logarithms of Symbolic Powers

The finite power-log model uses `Log[u^k] == k Log[u]` only when `u` is the
positive local coordinate and the retained assumptions prove `k` real.
The scaled form `Log[c u^k] == Log[c] + k Log[u]` also requires `c > 0`.
Negative real exponents are permitted; an unspecified exponent is not
implicitly real. For example, supply the real-parameter hypothesis explicitly:

```wolfram
AsymptoticInverse[x + x^2 Log[x^a]^2, {x, 0}, {y, 1},
  "Truncation" -> "Depth", Assumptions -> Element[a, Reals]]
```

The same rule applies recursively to positive bases. For example,
`Log[(1/u)^a]` becomes `-a Log[u]` when `a` is proved real, including after
changing a source coordinate at infinity. Every constant factor must be
proved positive and every exponent used in the normalization must be proved
real; a real outer exponent alone does not justify an unproved inner power.

Under this hypothesis the source is `x + a^2 x^2 Log[x]^2`. The assumption
`a^2 == -1` does not justify the same normalization. Although the original
source is then real for positive `x`, its squared principal logarithm is a
bounded periodic function of `Log[x]`. Replacing it by `-Log[x]^2` changes
both the function and its inverse asymptotics. Such an unproved
normalization returns `Failure["UnsupportedInput", ...]` in symbolic-depth
inversion. Use a supported source representation or retain a separate native
result where applicable.

These conditions also apply when this finite parser is used by exact-core
and flat-sector constructors. They do not restrict explicit native backends
to real inputs. A periodic-coefficient inverse constructor is a separate
development proposal. Targeted native before/after probes and 207 passing
focused tests cover the guarded normalization and selected consumers. The
[normalization notes](../../docs/development/LOG_POWER_NORMALIZATION.md)
record the mathematical contract and validation status.

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

Arithmetic on a `GeneralizedSeries` transports its remainder together with its finite expression. Operands must have compatible variables, endpoints, approach sides, and real branch conditions. Requested precision is limited by the available operand precision.

These operations apply to the package's analytic representations. Native results return `Failure["NativeSeriesContract", ...]` for analytic arithmetic, truncation, or refinement; use their `"NativeResult"` property for native formal operations.

A nonlinear operation can increase the logarithmic degree of the remainder
even when its power is limited by the operand:

```wolfram
s = AsymptoticExpansion[x Log[x] + x^3, {x, 0, 2}];
r = SeriesLog[1 + s, 4];
{Normal[r], r["Remainder"]}
```

The finite expression is `x Log[x] - x^2 Log[x]^2/2`, with remainder
`PowerLogRemainder[x, 3, 3]`. The discarded cubic logarithmic term contributes
to the error at power `3`, alongside the operand's original remainder.
Logarithmic degrees are conservative bounds and need not be the smallest
possible degree after cancellation.

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

The unary forms `Sin[s]`, `Cos[s]`, `Tan[s]`, `Sinh[s]`, `Cosh[s]`, `Tanh[s]`, `ArcSin[s]`, `ArcCos[s]`, and `ArcTan[s]` use the regular observable calculus when the argument tends to an admissible finite real value. `Abs[s]`, `Log[s]`, and `Exp[s]` use their corresponding sign, branch, and remainder rules. The modulus uses the eventual sign of the leading block only when every retained coefficient is provably real under the assumptions; a jet with nonreal coefficients, such as `Abs[1 + a x]` under `a^2 == -1`, is squared against its coefficientwise conjugate on the real coordinate and the positive root is taken, so `Abs[1 + a x] + Abs[1 - a x] - 2` expands to `x^2 (Abs[a]^2 - Re[a]^2) + O[x^4]` rather than to `0`. A nonconstant logarithmic leading block with nonreal coefficients leaves the power-log scale and is refused. A modulus of a nonzero remainder keeps only the magnitude bound and reports `"RemainderDerivativeOrder" -> 0`. When no ordered expansion is available, `Abs`, `Sin`, `Cos`, `Log`, and `Exp` can instead return the [composite bounds](#composite-series-results) described below. This does not assert an ordered expansion at every pole, branch point, or infinite argument.

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

When an arithmetic operation or a supported unary function cannot use one ordered coefficient scale, compatible operands can produce a result with `"Scale" -> "Composite"`. Its finite expression is retained, and its remainder keeps the separate input error scales. The operands must have the same expansion variable, endpoint, and real approach side, with compatible domains. The endpoint and side are derived from each operand's complete target chart: a stored `"SeriesApproach"` first, then the recorded target limit, with the retained target domain deciding the side before any isolated target scale or coefficient sign, so the reflected `Erfc` adapter approaches `2` from below and a negative quadratic curvature approaches its vertex value from below; a flat chart with a pole core tends to a signed infinity rather than to its finite offset.

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
| `Abs[s]` | None: the complex modulus is globally 1-Lipschitz. | `Abs[e] + O[R]`. |
| `Sin[s]`, `Cos[s]` | `e` is eventually real and, when the remainder is nonzero, `R -> 0`; a real finite part does not prove that the omitted error is real, so a non-vanishing envelope returns `Failure["UnprovedRealRemainder", ...]`. | `Sin[e] + O[R]` or `Cos[e] + O[R]`. |

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

`SeriesPower[s, r]` takes a power using the same dispatch and remainder rules as `s^r`. A fixed exponent must be an exact real numeric value. Supported varying exponents use the real logarithm and exponential calculus. `SeriesPower[s, r, h]` supplies an explicit cutoff. Noninteger and varying powers require the appropriate positive-base branch. Reciprocal powers can reduce absolute precision. The zeroth power is the constant `1` only where the base is nonzero: it requires a retained leading term whose coefficient is provably nonzero on the parameter domain, so `a x + x^2` with merely real `a` returns `Failure["UnprovedNonvanishing", ...]` while `a > 0` or `a != 0` gives `1`, and a pure remainder returns `Failure["IndeterminatePower", ...]`. On a Gamma or Barnes inverse the requested cutoff is recorded on the constant result.

A pure remainder does not establish the sign needed for a noninteger power.
This also applies to powers nested inside an observable: for example,
`SeriesObservable[s, 1 + Sqrt[z], z]` returns `Failure["UnknownLeadingTerm", ...]`
when `s` retains only an unknown remainder. Refine the operand to retain its
leading term before applying the observable. An exact zero and a pure remainder
are different inputs; positive fractional powers of an exact zero remain exact.

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

`SeriesCompose[outer, inner]` substitutes the inner expansion into the outer expansion. It transports both remainders and checks the inner limit, source side, and parameter conditions. The variables may differ; a fixed outer parameter that becomes the inner expansion variable requires a new joint expansion.

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

For each fixed `a > 0`, the expansion of `x/(a + x)` at `x = 0` starts with `x/a`, with an error bounded by a constant depending on `a` times `x^2`. That bound cannot be specialized directly to the path `x = a`. `SeriesCompose` uses the complete retained forward source and exact inner expression to expand the composed function in the new regime:

**Input**

```wolfram
Clear[x, a];
outer = AsymptoticExpansion[x/(a + x), {x, 0, 2},
  Assumptions -> a > 0, "Backend" -> "Package"];
inner = AsymptoticExpansion[a, {a, 0, 4}, "Backend" -> "Package"];
Normal[SeriesCompose[outer, inner]]
```

**Output**

```wolfram
1/2
```

This source replay requires a complete `"Forward"` outer source and an exact `"Forward"` inner expression. It checks both domains and the original parameter assumptions along the joint approach, using the strict package constructor. The result retains a new forward source for `SeriesRefine`; it does not assert that the original outer remainder was uniform in the moving parameter.

Parameter dependencies are checked in the retained source and operation operands as well as the visible terms. A parameter can occur only in discarded terms. If the required joint replay is unavailable, composition returns `Failure["ParameterCapture", ...]`; insufficient retained scope returns `Failure["MissingParameterScope", ...]`. A truncated inner expansion is not silently replaced by its original exact source. A strict replay can return a more specific constructor failure when its source or conditions are unsupported.

An exact outer expression can still transport uncertainty from the inner expansion. For example, the exact identity `x/a`, composed with `a + O(a^2)`, gives `1 + O(a)`. Its parameter and branch conditions must hold along the new approach. See [Parameter scope in composition](../../docs/development/COMPOSITION_PARAMETER_SCOPE.md) for the supported replay forms and mathematical contract.

<a id="SeriesObservable"></a>
### SeriesObservable

`SeriesObservable[s, expr, z]` substitutes the expansion into the placeholder `z` in a supported real expression. It accepts `"InverseFunctionBranches" -> Automatic` in addition to the common operation options. An outer `ConditionalExpression[expr, condition]` is admitted when the condition is proved on the precision-tracked input germ; the condition is peeled before the route is chosen, so `ConditionalExpression[Exp[z], z > 0]` reaches the same exact exponential route as `Exp[z]`, and the result records `"ObservableCondition"` and replays the conditional observable on refinement. A membership predicate such as `Element[expr, Reals]` in the condition is proved only when the argument's jet is exact: the finite coefficients of a truncated jet do not establish reality, since a cancelled complex Taylor tail can make an everywhere-false condition look true at a low cutoff, so such a condition on an inexact argument is refused.

**Input**

```wolfram
s = AsymptoticExpansion[x + x^2, {x, 0, 5}];
Normal[SeriesObservable[s, Sin[z], z, "Cutoff" -> 4]]
```

**Output**

```wolfram
x + x^2 - x^3/6
```

For a general unary observable at a finite limiting argument, the returned
Taylor series must use the requested local variable and center and establish
all coefficients consumed by the operation. A shorter returned series does
not make its unknown coefficients zero. The requested output cutoff cannot
override the available Taylor order or the input remainder.

When the input is proved to approach the limiting argument from one side,
the observable uses that sided Taylor expansion, including its constant term.
The sided limit can differ from the value at the endpoint.

**Input**

```wolfram
left = AsymptoticExpansion[1 - x, {x, 0, 2}, "Backend" -> "Package"];
Normal[SeriesObservable[left, FractionalPart[z], z]]
```

**Output**

```wolfram
1 - x
```

An exact constant input uses the point value:

```wolfram
point = AsymptoticExpansion[1, {x, 0, 2}, "Backend" -> "Package"];
r = SeriesObservable[point, FractionalPart[z], z];
{Normal[r], r["Remainder"]}
```

```wolfram
{0, 0}
```

If truncation loses the approach side, the retained source is not silently
refined. The observable must have compatible Taylor coefficients on both
sides and the same limiting point value through the order used. Otherwise
the operation returns `Failure["UnprovedObservableApproach", ...]`.

```wolfram
coarse = AsymptoticExpansion[1 - x, {x, 0, 1}, "Backend" -> "Package"];
MatchQ[SeriesObservable[coarse, FractionalPart[z], z],
  Failure["UnprovedObservableApproach", _Association]]
```

```wolfram
True
```

| Failure | Meaning |
| --- | --- |
| `"InvalidObservableNativeChart"` | A returned Taylor object uses a different variable or expansion center. |
| `"InsufficientObservableNativeOrder"` | The returned exclusive order does not establish every coefficient needed for this operation. |
| `"UnprovedObservableApproach"` | The input has no proved approach side and the required sided and point-value contracts cannot be reconciled. |
| `"UnprovedObservableArgument"` | An inner argument is not proved real on the input approach required by the real-sided Taylor expansion. |

These checks preserve available Taylor information and approach conditions.
Realness is checked on the complete inner argument, including terms omitted
from its finite approximation. Temporary complex output coefficients may
still cancel in the completed observable. For example, `ArcSin[2+z] + ArcCos[2+z]`
has real input arguments and simplifies to a real constant. In contrast,
`a Re[a z]` under `a^2 == -1` requires a complex input path for `Re` and is
refused by this real-sided method.
They do not establish analyticity for arbitrary user-defined functions or
custom native series handlers. See the
[observable Taylor notes](../../docs/development/OBSERVABLE_INGRESS.md) for
the error-order convention, admission limits, and recorded validation scope.

<a id="SeriesTruncate"></a>
### SeriesTruncate

`SeriesTruncate[s, h]` discards complete blocks at or above the exclusive cutoff `h`. Its only option is `"MaxTerms" -> 20000`. Raising a truncation cutoff cannot restore discarded coefficients.

A quantitative forward tail bound survives truncation. When `s` carries `"AbsoluteRemainderBound"` and `"RemainderBoundConditions"`, as the large-argument `Zeta` and `LerchPhi` expansions do, the truncated result's `"AbsoluteRemainderBound"` is the original bound plus `Abs` of the discarded finite part, which is recorded as `"TruncationDiscardedPart"`, under the unchanged conditions. The `"ForwardRemainderContract"` of the result has `"Type" -> "TransportedThroughTruncation"` and retains the original contract. The signed `"RemainderLowerBound"`, the Lerch `"RemainderBoundConstant"`, and `"FirstOmittedInteger"` describe only the original tail and are dropped unless the truncation discards nothing, in which case every bound field is kept unchanged. Bare big-O results gain no bound. Arithmetic on a truncated result still drops these fields.

<a id="SeriesRefine"></a>
### SeriesRefine

| Form | Result |
| --- | --- |
| `SeriesRefine[s, h]` | New cutoff for a supported result. An ordinary inverse with `"Truncation" -> "Depth"` uses an integer perturbation depth. |
| `SeriesRefine[s, <|"AdditionalBlocks" -> n|>]` | Additional complete nonzero blocks of an ordinary exponent-truncated inverse. |
| `SeriesRefine[s, <|"Target" -> y1, "TargetError" -> eps, "Interval" -> {lo, hi}|>]` | Numerical root certificate association. |
| `SeriesRefine[s, <|"Target" -> y1, "RelativeError" -> tau, "Interval" -> {lo, hi}|>]` | Numerical certificate with a relative root-accuracy request. |

A cutoff request retargets the result: `SeriesRefine[s, h]` with `h` below the current cutoff returns the valid coarser view at `h` while retaining the larger computation cache, so a later request for more terms does no new coefficient work, and a request at the current cutoff likewise recomputes nothing. This is a deliberate retargeting, not an error and not a wrong formula; use `SeriesTruncate[s, h]` to discard blocks without touching the retained state, and compare `s["Cutoff"]` with the request when a no-op is intended.

Options are `"MaxTerms" -> 20000` and `"MaxRefinements" -> 128`. A tolerance request also accepts the options of [InverseCertificate](#InverseCertificate) as association keys. Do not mix `"AdditionalBlocks"` with a numerical request.

Refinement preserves the original function, assumptions, selected branch, and declared input precision. It ignores later ambient `$Assumptions`, including when replaying a constructor or an operation recipe; see [Assumptions and Parameter Domains](#assumption-context). Exact terminating results can stop before an additional-block goal. A numerical request returns a certificate for the source root; it does not replace the symbolic remainder with a numerical tolerance.

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

`SeriesDifferentiate[s]` differentiates once; `SeriesDifferentiate[s, n]` differentiates `n` times. Options are `"Cutoff" -> Automatic`, `"MaxTerms" -> 20000`, and `"RemainderDerivativeOrder" -> Automatic`. `SeriesDifferentiate[s, 0]` is `s` itself; with `"Cutoff" -> h` it is `SeriesTruncate[s, h]`, so a supplied cutoff is honoured rather than ignored.

A value-only Big-O remainder does not establish a derivative remainder. Supply `"RemainderDerivativeOrder" -> n` only when the corresponding derivative bounds are known. Exact expressions and specialized analytic remainder contracts can supply the required information automatically.

## Applications

<a id="InverseResidual"></a>
### InverseResidual

`InverseResidual[s]` returns a report association checking composition of the retained forward model with the finite inverse. The report includes the normalized residual, cutoff, and scope. `InverseResidual[s, h]` supplies a relative residual cutoff in the recorded uniformizing coordinate. The option is `"MaxTerms" -> 200000`. The ordinary normalization is `(f(g(y)) - y0)/(a z^p) - 1`, where `y0` is the finite target offset reported as `"TargetOffset"` (zero at an infinite target, where the label reads `f(g(y))/(a z^p) - 1`) and `z` is the uniformizer of `y - y0`.

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

`InverseNumericalCheck[s, y1]` returns an association comparing the finite expansion with the requested source observable of a numerical root of the retained original equation on its selected branch. Its option is `WorkingPrecision -> 50`.

```wolfram
s = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
check = InverseNumericalCheck[s, 1/100, WorkingPrecision -> 60];
check["ReferenceRoot"]
check["ReferenceObservable"]
check["Error"]
```

`"ReferenceRoot"` is the numerical source root. `"ReferenceObservable"` is the source observable requested by `"Power"`. `"Error"` compares that observable with the finite approximation. `"ExactInverse"` is a compatibility alias for the numerical reference root.

A root on the selected source side need not lie on the inverse branch incident to the endpoint: the finite approximation can itself be an exact root of another monotone component, so an equation residual of zero would hide a nonzero branch error. For an exact numeric polynomial source the checker isolates the endpoint-incident component `(0, u1)`, with `u1` the least positive critical point of the local equation or `Infinity`, takes the unique equation root inside it, and reports `"EndpointComponent"` and `"BranchComponentVerified" -> True`; it returns `Failure["OutsideBranch", ...]` with `"Reason" -> "NoRootInEndpointComponent"` when the equation has no root there. For `x + 8 x^2 - 16 x^3` at target `1/2` the approximation `1/2` is a root of the other component and the selected branch value is `1/4`, which is what the check now returns, with `"Error" -> 1/4`. A nonpolynomial or parameter-dependent source keeps the solver's root and reports `"BranchComponentVerified" -> False`.

The ordinary checker solves in the local source coordinate `x = SourceOffset + SourceSide u`, with `u > 0` on the selected side; at an infinite endpoint the offset is `0`. The exact endpoint is substituted symbolically before any numerical evaluation, so a small displacement at a huge source origin, such as `(x - 10^100) + (x - 10^100)^2` at `x -> 10^100`, is solved, tested against the branch and compared at full working precision. `"LocalRoot"` is always the positive displacement `u` at the recovered root. `"LocalApproximation"` approximates `u` for `"Power" -> 1` and the signed observable `(SourceSide u)^p` otherwise; `"LocalReferenceObservable"` is that observable at the recovered root, and `"ObservablePower"` records `p`. `"Error"`, `"ForwardResidual"` and `"RootResidual"` are computed locally. `"ReferenceRoot"`, `"Approximation"` and `"ApproximationSourceRoot"` reconstruct absolute source values with enough extra digits to show the displacement, so their `Precision` can exceed `WorkingPrecision` at a large offset. With a zero offset every field agrees with the direct computation.

Use exact targets or targets with sufficient input precision. Exact target offsets are subtracted before numerical evaluation. The operation also supports the admitted transformed, logarithmic, Fourier, flat, core, and special inverse families. Its output is numerical evidence, not an interval certificate.

`WorkingPrecision` is a requested solver setting. The
[ordinary checker](../Kernel/NumericalInverseChecks.wl) checks the input target's
precision and the recovered source branch, but does not verify the achieved
`Precision` or `Accuracy` of the reference root.

In Mathics 10.0.1, the
[root-finder implementation](https://github.com/Mathics3/mathics-core/blob/10.0.1/mathics/builtin/numbers/calculus.py#L606-L620)
does not list `WorkingPrecision` and evaluates the seed through `eval_N`, whose
[default precision is machine precision](https://github.com/Mathics3/mathics-core/blob/10.0.1/mathics/eval/nevaluator.py#L24-L42).
Increasing the request or applying `N[root, digits]` afterward does not recover
digits lost by that solver path. The package's Mathics-only adapter now rejects
unavailable reference-root precision with
`Failure["MathicsNumericalPrecisionUnavailable", ...]` and checks the precision
of delegated roots. A seed that denotes an exact integer or rational, such as
`1/2` or `1/3`, is accepted exactly only when direct substitution proves the
exact polynomial equation; no other seed is rounded to a nearby rational. The ordinary
official-kernel checker retains its behavior described above.

The recorded Mathics
[`numerical-exact-quadratic-inverse` smoke check](../../validation/mathics-modular-tests.json)
establishes its exact-root example, not general high-precision accuracy.
See [Mathics numerical contracts](../../docs/Mathics/NUMERICAL.md) for the
supported examples and remaining precision limits, and
[Mathics coverage](../../docs/Mathics/API-COVERAGE.md) for the broader tested scope.

<a id="InverseCertificate"></a>
### InverseCertificate

`InverseCertificate[s, y1, "Interval" -> {lo, hi}]` attempts to certify a unique real source root in a verification interval. Successful output is an association with a rational center, rational root enclosure, and certified error bounds. Rational affine subexpressions of the equation are evaluated exactly before interval rounding, so a large translation of the source coordinate does not consume certificate precision; other subexpressions use outward rational enclosures. The evaluator supports rational constants, sums, products, integer powers, rational powers of a nonnegative base, real powers of a positive base, `Exp` and `Log`. An integer power of an interval is the range of the endpoint powers, so an odd power across zero keeps its sign structure and a derivative such as `1 + 4 x^3` on `{-1/4, 1}` is enclosed by `{15/16, 5}` rather than `{0, 5}`. A rational power `p/q` uses exact dyadic `q`-th roots instead of `Exp[(p/q) Log[base]]`, so an algebraic root of a huge base does not consume the exponential magnitude budget.

| Option | Default | Meaning |
| --- | --- | --- |
| `"Interval"` | `Automatic` | Required verification interval with ordered exact rational endpoints. Leaving the default `Automatic` returns `Failure["InvalidInterval", ...]` whose `"Reason"` is `"IntervalNotSupplied"`; no interval is inferred from asymptotic constants. Unordered, inexact, or irrational endpoints return the same tag with `"Reason" -> "MalformedInterval"`. |
| `"Center"` | `Automatic` | Initial or fixed rational approximation. An explicitly supplied center remains fixed. |
| `"TargetError"` | `Automatic` | Positive exact rational absolute error goal for the returned center. |
| `"RelativeError"` | `Automatic` | Positive exact rational relative error goal using a proved root-magnitude bound. |
| `WorkingPrecision` | `50` | Precision used in choosing numerical seeds and in planning an automatic initial enclosure order. |
| `"EnclosureOrder"` | `Automatic` | Initial order used for elementary-function enclosures; an explicit value must be an integer from `2` through `2000`. |
| `"MaxRefinements"` | `6` | Maximum retries after the initial certificate attempt. |
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

`c["Center"]` and `c["RootEnclosure"]` give the actual rational approximation and enclosure. For `c["RootEnclosure"] == {a, b}`, `c["CertifiedErrorBound"]` is `Max[Abs[a - c["Center"]], Abs[b - c["Center"]]]`. It bounds the distance from the specified center to every point in the sharpened enclosure. `"ResidualRadius"` separately records the residual absolute bound divided by the derivative lower bound; interval intersections can make the reported error smaller than this radius.

When both tolerances are given, the accuracy request is `Abs[center - root] <= Max[eps, tau Abs[root]]`. Acceptance uses exact bounds: `"CertifiedErrorBound" <= "SufficientAbsoluteTolerance"`, where the sufficient tolerance is `Max[eps, tau m]` and `m` is a proved lower bound on the root magnitude. An omitted absolute tolerance contributes zero when a relative tolerance is requested. The relative bound is `"CertifiedErrorBound"/m` when `m > 0`; otherwise `"CertifiedRelativeErrorBound"` is `Missing["RootNotSeparatedFromZero"]`. When the enclosure proves the root is zero, a relative-only request returns `Failure["RelativeAccuracyAtZero", ...]`; supply a positive absolute fallback.

#### Accuracy and Refinement

With `"EnclosureOrder" -> Automatic`, the initial order uses `WorkingPrecision` and a digit estimate from both exact rational tolerances, capped at `2000`. Failed enclosure attempts and retries with a fixed center raise the order up to this cap. With a movable center, a valid but insufficient certificate can trigger higher order when residual uncertainty materially limits the new root enclosure, or when both interval width and center-error progress stall. Otherwise, interval contraction continues at the current order. Reaching the cap still permits remaining interval refinements. These choices allocate work; only the exact enclosure inequalities establish accuracy.

```wolfram
c = InverseCertificate[s, 1/10, "Interval" -> {1/20, 1/5},
  "RelativeError" -> 10^-30, "MaxRefinements" -> 6];
{c["AccuracyGoalReached"], c["EnclosureOrder"],
 c["CertifiedRelativeErrorBound"]}
```

| Property | Meaning |
| --- | --- |
| `"AccuracyGoalReached"` | Whether the proved bounds satisfy the requested tolerance. A certificate of a unique root alone does not establish this. |
| `"ProvedRootMagnitudeLowerBound"` | Lower bound used to obtain a relative error estimate. |
| `"SufficientAbsoluteTolerance"` | Exact absolute bound sufficient for the combined tolerance request. |
| `"EnclosureOrder"` | Order used for this certificate. |
| `"EnclosureOrderLimitReached"` | Whether the order reached `2000`; this does not identify the cause of an accuracy failure. |
| `"History"` | Attempt records, including orders, outcomes, enclosure widths, residual radii, and achieved error bounds when available. |
| `"AccuracyComparisonKey"` | Exact comparison tuple: error divided by the sufficient tolerance, absolute error, and root-enclosure width. |

When several valid attempts are available, the best certificate is selected lexicographically by `"AccuracyComparisonKey"`; equal keys retain the earlier certificate. The first component is `Infinity` when the sufficient tolerance is zero and `0` when no accuracy goal was requested. `"BestCertificateCriterion"` names these three comparisons.

A failure that no arithmetic precision can repair — a verification interval on the wrong side of a rational or infinite expansion point, or an equation outside the evaluator's supported operations — ends the refinement at once with `"StoppingReason" -> "NonRefinableArithmeticFailure"` and `"ArithmeticRetryable" -> False` instead of being retried at every doubled order. An exhausted retry budget returns `Failure["AccuracyNotReached", ...]` if a valid certificate was found, retaining it as `"BestCertificate"`. Its `"EnclosureOrder"` can differ from the final attempted order. The failure records `"StoppingReason" -> "RefinementBudgetExhausted"`, `"FinalEnclosureOrder"`, `"EnclosureOrderLimit"`, and the retry counts. These distinguish the retry budget from the order cap. A fixed center with a proved positive accuracy floor can return `Failure["AccuracyFloor", ...]`, containing both `"BestCertificate"` and the `"AccuracyFloorCertificate"` that proves the obstruction.

The certificate concerns the stored explicit equation within the supplied interval. It does not establish a global inverse branch or enclose unspecified terms represented only by an input remainder. All retained source conditions must hold throughout the closed verification interval. A strict source condition therefore also constrains its endpoints.

The numerical-root limitation above does not replace the certificate's
separate proof obligation. In the
[certificate implementation](../Kernel/InverseCertificates.wl), numerical
seeds and `WorkingPrecision` plan the computation; successful error bounds
come from exact rational enclosures and explicit inequalities. Mathics evidence
currently includes an exact rational quadratic-root certificate and a
fixed-center `AccuracyFloor` case in the
[recorded portable checks](../../validation/mathics-modular-tests.json).
Those cases do not establish all adaptive, relative-tolerance, or
nonpolynomial elementary-tail paths. Their coverage remains listed separately
in the [Mathics API inventory](../../docs/Mathics/API-COVERAGE.md).

<a id="PowerLogModel"></a>
### PowerLogModel

`PowerLogModel[f, {x, x0}]` returns an association describing a finite normalized forward model. `PowerLogModel[f, x]` uses `x0 = 0`. Options are `Assumptions :> $Assumptions`, `Direction -> Automatic`, and `"MaxTerms" -> 20000`. The model retains its effective parameter assumptions in `"Assumptions"` and its source conditions separately. An input requiring an infinite forward expansion is outside this model constructor's scope.

Inspect `"LeadingPower"`, `"LeadingCoefficient"`, `"Gaps"`, `"Polynomials"`, and `"LogVariable"` to identify the correction variables used by a coefficient request.

The model separates two quantities that the legacy `"Limit"` field conflated. `"ModelOffset"` (also still returned as `"Limit"`) is the baseline extracted by normalization: the constant term when the leading power is positive, and `0` for a pole, where a finite constant stays in the correction rows. `"TargetLimit"` is the analytic limit of the source on the admitted approach: the baseline when the leading power is positive, `Infinity` or `-Infinity` for a pole with a provably positive or negative leading coefficient, and `Missing["Unresolved", "LeadingSign"]` when that sign is unproved. For `1/x + 7` at `x -> 0` the offset is `0`, the Laurent constant is `7`, and the target limit is `Infinity`: three different quantities. An inverse object's own `"Limit"` is the target endpoint.

<a id="InverseExpansionCoefficient"></a>
### InverseExpansionCoefficient

`InverseExpansionCoefficient[s, {k1, k2, ...}]` returns an association describing the exact contribution of one ordinary inverse multi-index. A `PowerLogModel` association may replace `s`; for that form, `"Power" -> 1` selects the observable. For a result object, the option defaults to the object's stored `"Power"`, and an explicit `"Power"` takes precedence over it; both are observable powers of the source displacement, and at an infinite endpoint both are converted to the internal uniformizer convention in the same way, so `InverseExpansionCoefficient[s, k, "Power" -> 2]` agrees with the coefficient of the same inverse constructed with `"Power" -> 2`.

The result must retain an ordinary inverse coefficient model. Forward expansions, derived results without that model, exact-core expansions, and Fourier inverses return `Failure["UnsupportedCoefficientModel", ...]` without emitting messages. The query does not construct an inverse model from a forward expansion. Native results retain their `"NativeSeriesContract"` refusal; logarithmic-scale inverses retain `"Unsupported"` and expose their coefficients through `"Terms"`.

The coefficient query inherits the model's assumptions and ignores later ambient assumptions:

```wolfram
Clear[x, a];
model = Assuming[Element[a, Reals],
  PowerLogModel[x + Abs[a] x^2, {x, 0}]];
coefficient = Assuming[a > 0,
  InverseExpansionCoefficient[model, {1}]];
coefficient["Coefficient"]
(* -Abs[a] *)
```

Give one nonnegative integer per model gap. A model with no gaps accepts the empty multi-index `{}`. A wrong dimension or a negative or noninteger entry returns `Failure["InvalidMultiIndex", ...]`. Returned fields include `"Weight"`, `"Exponent"`, `"Coefficient"`, `"UniformizerExponent"`, and the inherited `"Assumptions"`. A multi-index contribution is not necessarily a complete displayed block: several contributions can have the same weight.

`"Coefficient"` describes the positive local coordinate. For a result object the query also returns the chart needed to read it as part of the represented observable: `"SourceOrientation"` is `-1` for a source approached from below or tending to `-Infinity` and `1` otherwise, `"ObservableCoefficient"` is `SourceOrientation^Power` times the local coefficient, `"AdditiveOffset"` is the finite source endpoint for power `1` and `0` otherwise, and `"ContributionExpression"` is the contribution in the target variable. The observable is the additive offset, added once per expansion, plus the sum of the contribution expressions over the retained multi-indices. For `AsymptoticInverse[x, {x, 0}, {y, 2}, Direction -> "FromBelow"]` the local coefficient is `1` while the contribution is `y`; for an even power the orientation factor is `1` and the two coefficients agree.

<a id="PerturbativeInverse"></a>
### PerturbativeInverse

`PerturbativeInverse[phi, h, {x, y}, n]` generates perturbation formulas using an exact inverse core `phi`. `PerturbativeInverse[h, {x, y}, n]` uses the identity core. It has no options. The core must be an expression in the target `y` alone and the perturbation must not contain `y`; a core containing the source symbol `x` is refused with `Failure["InvalidVariables", ...]` rather than producing a formula in which the eliminated symbol survives.

This function returns a formula. It does not attach asymptotic ordering or a remainder contract. Use an exact-core constructor when the supported problem requires those properties.

<a id="AsymptoticCoreInverse"></a>
## AsymptoticCoreInverse

`AsymptoticCoreInverse[core, perturbation, {x, x0}, {y, n}]` retains an exact inverse of `core` and computes corrections through inclusive marker degree `n`.

The core and perturbation must be supported finite power-log expressions. The core must have nonzero leading source power, and every perturbation power must be strictly higher. Automatic cores include monomials, affine logarithmic powers, and supported divergent power-plus-log expressions. Each component is validated separately: neither may contain the target variable, even when a target-dependent offset would cancel in their sum, because the remainder scales are derived for fixed core and perturbation data; `AsymptoticCoreInverse[x - Re[y], Re[y] + 1/x, {x, Infinity}, {y, 2}]` is refused with `Failure["InvalidVariables", ...]`.

| Option | Default |
| --- | --- |
| `Assumptions` | `$Assumptions` (delayed) |
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

Options are `Assumptions :> $Assumptions`, `Direction -> Automatic`, `"SourceShift" -> Automatic`, `"CoreInverse" -> Automatic`, `"CoreCheckTimeConstraint" -> 3`, `"InputRemainder" -> None`, and `"MaxTerms" -> 20000`.

`"SourceShift"` selects the source translation at a source infinity. It must be a fixed exact real parameter that depends on neither the source nor the target variable: the remainder scales are derived for a fixed chart, and a shift varying with the target would cancel out of every displayed coefficient while changing the remainder scale, so such a request returns `Failure["TargetDependentSourceShift", ...]`. A fixed shift changes the remainder scale only by a constant factor. `"CoreInverse"` must be independent of the source variable only. A declared pair `{rho, k}` here means `O[v^-rho (1 + Log[v])^k]` with corresponding derivative control. Its transported error remains a separate first-sector precision limit.

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

Options are `Assumptions :> $Assumptions`, `Direction -> Automatic`, `"Power" -> 1`, and `"MaxTerms" -> 20000`.

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

The complete omitted-sector bound of a product is selected by exponential grade. Every omitted contribution, whether a discarded coefficient product, an input tail times a coefficient, or the product of both tails, lives in a sector above the retained depth `N`; a later sector is negligible relative to an earlier one for fixed data, so only the candidates of least sector are combined by power-log dominance, and that sector is reported as `"SectorTailGrade"` while `"SectorRemainder"` keeps the schema's sector `N + 1`. Retained sectors and the first omitted sector use full coefficient products, so exact cancellations there are found; deeper omitted pairs contribute envelopes only. For the depth-`N` inverse of `x + Exp[-1/x]` squared, the tail power is `1 - 2 N` instead of the `-4 N` obtained by combining every candidate's algebraic pair first. Sums, scalar products, polynomial observables and derivatives propagate the grade.

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

`FourierInverseResidual[s]` checks the finite Fourier equation at its stored relative source-weight cutoff. `FourierInverseResidual[s, h]` supplies another relative cutoff. Its option is `"MaxTerms" -> 20000`, which may also be given without a cutoff, as in `FourierInverseResidual[s, "MaxTerms" -> 7]`; an option is never read as the cutoff.

Check a polynomial source using an explicit residual-work budget:

```wolfram
s = AsymptoticFourierInverse[
  x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7];
check = FourierInverseResidual[s, Automatic, "MaxTerms" -> 7];
{check["ZeroBelowCutoff"], check["ResidualBlocks"], check["RelativeCutoff"]}
```

```wolfram
{True, {}, 6}
```

The composition stops when every remaining source weight is outside the
exclusive cutoff or its complete Fourier coefficient is identically zero.
Products needed for retained contributions still obey the resource limits.
An integer exponent alone does not imply termination when a coefficient
contains a nonzero frequency or a logarithmic amplitude.

`"ZeroBelowCutoff" -> True` checks the stored finite forward equation below
the reported relative cutoff. Unspecified `"InputRemainder"` terms are not
composed, and this result is not a numerical root certificate. See the
[Fourier termination notes](../../docs/development/FOURIER_TERMINATION.md)
for the before/after characterization and validation scope.

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
| `Assumptions` | `$Assumptions` (delayed) | Parameter assumptions; an explicit option replaces the ambient value. |
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
| `Normal[s]` | The approximation expression; native normalization can preserve infinite expressions. |
| `s["Remainder"]` | An analytic remainder class with its coordinate and prefactor, or `Missing["NativeContract"]`. |
| `s["NativeResult"]` | The full native result, when present; it does not establish a package analytic bound. |
| `s["Remainder"] === 0` | An established exact finite result for the admitted equation and branch. |
| `s["ExactModel"]` | Exactness of the retained forward model; the displayed inverse can still have a nonzero tail. |
| `InverseResidual[s]` | Composition at a stated order for the equation named by its scope. |
| `InverseNumericalCheck[s, y1]` | Agreement with a numerical solution at one target. |
| `InverseCertificate[s, y1, ...]` | A proved local root enclosure when `"Certified" -> True` is returned. |

`SeriesTruncate` changes the displayed cutoff using existing information. `SeriesRefine` obtains more justified information from the retained source or operation. A higher cutoff alone does not improve an unknown input remainder.

These precision operations require a supported analytic representation; they do not upgrade a native formal order to an analytic estimate.

### Inverse Expressions and Inverting an Inverse

`AsymptoticExpansion[InverseFunction[F][y], ...]` expands the selected inverse of `F`. `AsymptoticInverse[InverseFunction[F][x], ...]` inverts that already inverted expression and can recover `F` on compatible branches.

A composite such as `1 + InverseFunction[F][y]` is an expression containing an inverse. Its numerical or residual interpretation must not be confused with the defining equation for `F` itself. Direct inverse results retain their source branch; composite results retain inverse-occurrence information separately.

### Remainder-Aware Operations

`SeriesCompose` and `SeriesObservable` include uncertainty from their inputs. A singular derivative can reduce available absolute precision. `SeriesExp` needs a vanishing absolute argument error even when its output grows rapidly. `SeriesDifferentiate` needs derivative information in addition to a value bound.

For positive Gamma prefactors, `SeriesLog` returns the additive logarithmic expansion, while direct Gamma normalization returns a multiplicative correction bracket. Their cutoff conventions should be read in the coordinate of the returned operation.

## Possible Issues

| Issue | Action |
| --- | --- |
| Approximate exponent or coefficient in a package analytic path | Use the intended exact value, such as `Sqrt[2]` or `5/2`, or select an explicit native backend when native approximate semantics are intended. |
| Unproved parameter sign or realness | Supply sufficient `Assumptions`; do not assume that a parameter is implicitly real. |
| A later `Assuming` does not enable an operation | Construct the operand with the required hypotheses. Operations on existing results use retained assumptions only. |
| An explicit assumption option appears to ignore `Assuming` | The explicit option replaces the ambient value. Include every required hypothesis in that option. |
| A specialized constructor rejects ambient assumptions | Its assumptions must concern parameters only. Supply an explicit parameter-only option and select the source approach with endpoint and branch options. |
| Ambiguous inverse branch | Restrict the source domain or supply `"InverseFunctionBranches"` for an unevaluated inverse operator. |
| Incompatible source or target condition | Select an approach on which the condition holds eventually. |
| Unexpected number of terms | Check whether the request is a cutoff, block goal, or marker/sector depth. Exact cancellations can remove blocks. |
| Native and package requests retain different orders | Native `Series` includes its requested order; ordinary package cutoff excludes it. Inspect `"Kind"` and, for a native result, `"NativeBackend"`. |
| Automatic returns a native result | Inspect `"BackendSelectionReason"`, `"NativeBackend"`, `"NativeAttempts"`, and `"OrderConvention"`. Native order and term goals can differ from package cutoff and block goals. |
| A native result is unresolved or failed | Inspect `"NativeResult"`, `"NativeEvaluationStatus"`, and the automatic `"NativeAttempts"`. Explicit backend selection and backend-specific options can restrict the call to one engine. |
| Native evaluation is aborted | Automatic search stops at `"Aborted"`; it does not retry the other engine. |
| A native-specific option is rejected by Package mode | Select a compatible native backend or unprotected Automatic request; the package engine does not silently ignore those options. |
| A native result has a missing remainder or exactness status | Inspect `"NativeResult"` and `"RemainderContract"`; missing analytic evidence is not a zero remainder. |
| A native result rejects package arithmetic or refinement | Use native operations on `"NativeResult"`, retaining their native semantics. |
| Unexpected power of the remainder | Inspect `"RemainderVariable"`, `"Prefactor"`, and `"TermConvention"`. Sparse support or transported input errors can change the first omitted power. |
| Refinement stops at an input error | Supply stronger justified input information in a new construction. |
| `SeriesCompose` returns `"ParameterCapture"` | A formerly fixed outer parameter is varying. Joint replay currently needs a complete forward outer source and exact forward inner expression; a pointwise outer remainder alone cannot justify that substitution. |
| `SeriesCompose` returns `"MissingParameterScope"` | Retain the original constructor or operation provenance. Visible coefficients alone do not identify every parameter of a discarded error. |
| `SeriesCompose` returns `"IncompatibleCompositionParameters"` | Choose a joint approach on which the original parameter assumptions hold eventually. |
| Derivative operation fails | Establish the necessary derivative remainder contract; a value Big-O is insufficient. |
| Certificate fails near an interval boundary | Check poles, endpoint signs, strict source conditions, and the interval's containment in the selected branch. |
| `"SeriesData"` is missing | Inspect the reason. A positive logarithmic remainder degree, irrational exponents, separate error scales, or native index and coefficient-allocation limits can prevent the optional view. Use the sparse result and its complete remainder; see [Native SeriesData View](#native-series-remainder-view). |
| A composite result rejects `"Cutoff"` | Truncate or refine supported operands in their own scales, then combine them again. |
| A quotient loses precision or fails | Check the denominator's leading term and relative remainder; normalization cannot infer a nonzero function from a pure remainder. |
| Resource limit | Reduce the order or expression complexity, or raise the relevant budget. A partial result does not establish omitted coefficients. |
| A Mathics call remains unevaluated after loading | Load the package in a separate input expression before parsing its calls, and check the [Mathics compatibility guide](../../docs/Mathics/COMPATIBILITY.md) for the selected operation's scope. |
| Mathics reaches its iteration limit | Apply the explicit session setting in [Mathics3 Compatibility](#mathics-compatibility). Evaluator iterations, package term limits, and elapsed-time limits are separate budgets. |

Ordinary power-log coefficients are polynomials in a single logarithm. Arbitrary nested logarithms, unrelated exponential-sector sums, and arbitrary oscillatory coefficients require a compatible specialized family for an ordered expansion. Arithmetic can retain compatible existing expansions as a composite bound without asserting closure in a single coefficient scale.

The ordinary factor `Log[x]` in `Log[x] Exp[x]` or `Log[x] Gamma[x]` produces the unsupported combined logarithmic source `Log[Log[x]]` in direct normalization. The existence of a formal factored expression alone does not guarantee that the direct constructor can expand it.

Finite Poincare expansions do not assert convergence. Numerical agreement at a large argument does not turn an asymptotic frontier into a pointwise bound. Unknown source predicates and unsupported certificate operations are not silently discarded.

Use `FailureQ[result]` to check a result before querying its properties. Failure data can include the unproved condition, unsupported scale, available precision, or best expansion.

## See Also

Wolfram Language: [Series](https://reference.wolfram.com/language/ref/Series.html), [Asymptotic](https://reference.wolfram.com/language/ref/Asymptotic.html), [DiscreteAsymptotic](https://reference.wolfram.com/language/ref/DiscreteAsymptotic.html), [InverseFunction](https://reference.wolfram.com/language/ref/InverseFunction.html), [Function](https://reference.wolfram.com/language/ref/Function.html), [ConditionalExpression](https://reference.wolfram.com/language/ref/ConditionalExpression.html), [ProductLog](https://reference.wolfram.com/language/ref/ProductLog.html), [LogBarnesG](https://reference.wolfram.com/language/ref/LogBarnesG.html), [Normal](https://reference.wolfram.com/language/ref/Normal.html).

## Related Guides

- [Mathematical article](../../docs/article/asymptotic-inverse.pdf): mathematical definitions, results, and proofs.
- [Executable examples](../Examples/Examples.wl): additional package expressions.
- [Mathics compatibility](../../docs/Mathics/COMPATIBILITY.md): installation, bounded runtime contracts, and feature-specific validation.
- [Package entry point](../README.md): loading and documentation links.
- [Wolfram Language asymptotic computations](https://reference.wolfram.com/language/guide/Asymptotics.html): related built-in functionality.
