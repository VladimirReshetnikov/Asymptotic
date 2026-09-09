# Review and validation record

## Nonlinear input frontiers and coefficient termination

An input-limited nonlinear expansion now includes both the inherited error and
discarded Taylor products in its logarithmic remainder degree. The shared unit
precision helper uses the maximum degree of all retained argument blocks and
keeps its existing conservative bound when the requested cutoff lies below the
input frontier. It no longer drops generated logarithmic powers merely because
the caller requested more precision than the operand supplies. The unused
duplicate cutoff calculation in `pUnitSeries` was removed.

The homogeneous composition recurrence now stops as soon as its coefficient
polynomial is proved zero, before multiplying another power. This avoids false
resource failures for constant or terminating polynomial compositions. Required
products and existing input-validation order remain checked. An unrelated
generic coefficient generator may still resume after an isolated zero.

Against pinned kernel sources from `73aabf2`, the 31 new assertions record
**19 passed and 12 failed**: eight nonlinear-bound witnesses and four futile
product failures. After the changes, `CheckReviewUnitArithmetic.wl` records
**196 passed, zero failed**, across nine selected files, with unchanged source
hashes. Explicit Taylor/binomial oracles cover logarithmic frontiers, a genuine
irrational boundary collision, pure and inherited errors, symbolic coefficient
annihilation, required work budgets, Newton coefficients and residual checks.
The independent log-degree majorant remains conservative, rather than claiming
the sharp degree after cancellation.

The baseline and acceptance records are `review-unit-arithmetic-baseline.json`
and `review-unit-arithmetic-tests.json`. Standalone generation, 11 Python builder
tests, and documentation consistency checks passed. **The full package suite
was not run.**

## Shared fractional-power branch checks

The shared `fwdPower` primitive now rejects noninteger powers of a finite pure
remainder. This closes the bypass through nested sums, products, analytic
observables, and forward expansions after cancellation. The public
`SeriesPower` check and existing exponent-validation order remain in place.
Positive integer powers still propagate pure remainder bounds, and positive
fractional powers of an exact zero remain exact. Forward construction can retry
with more terms to establish a positive leading coefficient.

`review-power-branches-baseline.json` records **10 passed and six failed** for
the 16 new assertions against pinned kernel sources from
`73aabf26dfa6258253ed45f31603cb2731b474c7`; those six failures reproduce the branch
defect. `CheckReviewPowerBranches.wl` records **148 passed, zero failed** in six
selected files after the fix, with unchanged source hashes. It covers wrapped
fractional powers, cancellation, unknown symbolic signs, valid integer powers,
exact zero, and rejection of the nonreal square root of `Sin[x]-x`.

The positive control `Sqrt[x-Sin[x]]` checks the independently known leading
term and accepts a valid weaker remainder bound. Its next nonzero term has
power `7/2`; requesting cutoff `2` does not require a constructor to discover
that sharp frontier. The standalone build, 11 Python builder tests, and generated
guide/documentation checks passed. **The full package suite was not run.**

## Bounded native series export

Forward and inverse construction now share one native `SeriesData` exporter.
It retains the original rational denominator and remainder index while storing
coefficients only through the final retained exponent. More than 100,000 dense
slots between retained exponents produce `Missing["DenseSeriesDataLimit", ...]`
for the optional native view; sparse terms, the finite expression, and remainder
remain available. Empty inverse jets also retain their pure remainder correctly.
The existing coordinate, irrational-exponent, and exact-result guard order is
preserved. Logarithmic native-tail semantics are a separate review finding.

`CheckReviewNativeExport.wl` records **115 passed, zero failed**, in five selected
files, with unchanged source hashes. Its 13 new cases cover a billion-slot tail
under a 64 MB evaluation constraint, an excessive interior gap, both sides of
the dense limit, Laurent and rational lattices, empty jets, symbolic inverse
scaling, target translations, refinement, and guard precedence. The standalone
build, 11 Python builder tests, and documentation consistency checks passed.
**The full package suite was not run.**

`BenchmarkNativeExport.wl` compares pinned baseline
`73aabf26dfa6258253ed45f31603cb2731b474c7` with the changed sources in fresh Wolfram
15.0.1 kernels, with one warm-up and three measured runs. All five finite/native
results and remainders agree exactly. Reports retain source/harness hashes and
individual samples. Peaks are `MaxMemoryUsed` evaluation observations, not total
process memory or portable bounds.

| Fixture | Before / after median seconds | Before / after median peak bytes |
| --- | --- | --- |
| Forward native view, million-slot trailing gap | 0.01402 / 0.000114 | 24,010,048 / 10,520 |
| Inverse native view, million-slot trailing gap | 0.01465 / 0.000062 | 16,009,224 / 10,624 |
| Public fractional power with distant remainder | 0.01569 / 0.00237 | 24,054,088 / 73,336 |
| Public series with a wide retained gap | 0.00722 / 0.00308 | 5,654,608 / 87,512 |
| Ordinary polynomial inverse control | 0.00348 / 0.00438 | 131,240 / 131,248 |

The unchanged control was slower in this sample; these selected measurements
establish an allocation improvement for sparse native views, not a general
speedup. Reproduce with `wolfram.exe -noinit -script
validation/BenchmarkNativeExport.wl`; the usual `ASYMPTOTIC_BENCHMARK_ROOT` and
`ASYMPTOTIC_BENCHMARK_OUTPUT` environment variables select the baseline and report.

## Vendored ProveIt articles

The [article catalog](../vendor/proveit/README.md) contains 46 articles and two
reference companions, each with TeX and PDF, pinned to the published ProveIt
revision recorded in its [manifest](../vendor/proveit/manifest.json). All 42
regenerated PDFs and the associated source repairs were committed upstream
before the final snapshot. The other six PDFs passed the dependency freshness
checks without a rebuild. Archived roots are excluded.

`vendor_proveit_articles.py check --source-root C:/ProveIt` verifies copied
bytes against the pinned Git objects. `check_proveit_catalog.py --source-root
C:/ProveIt` checks the complete article inventory, selection evidence, reading
lists, links, freshness, and published build receipts. `build_proveit_pdfs.py
--list` reports any required builds; its build mode uses three serial LaTeX
passes. The [final verification record](../vendor/proveit/verification.json)
binds the audit results to the manifest and validation scripts.

Every rebuilt PDF passed structural and font checks. Targeted rendered-page
reviews cover repaired text loss and the final synchronization; minor layout
warnings remain in the logs. This validates artifact provenance and compilation,
not all mathematical claims or every rendered page. No Lean build or full
Wolfram package suite was run for the document work.

## Parameterized composition probes

Parameterized special-function composition now examines the argument jet
before proving the whole expression real. A nonconstant increment with an
infinite working cutoff is rejected at the same limit as `fwdAnalytic`;
an argument made constant by parameter assumptions still follows the full
construction path. Every successful finite result retains the original
real-domain and real-coefficient checks. The special-inverse numerical check
also drops an unused eager numerical conversion and three unused locals.

`CheckCompositionRefactoring.wl` selects six files and records **100 passed,
zero failed**, with unchanged source hashes, in
`composition-refactoring-tests.json`. Four new cases cover constant arguments
under assumptions, finite retries after an exact probe, logarithmic increments,
and rejected complex parameters/branches/centers. Existing numerical checks
cover reflected Erfc tails, LogGamma, very large exact exponential targets,
and Lambert thresholds. The standalone build, 11 Python builder tests and
documentation checks passed. **The full package suite was not run.**

The `Composition` benchmark compares immutable commit
`07a9781212beb2eeb9ff16aa625b50ac27974078` with these sources in fresh Wolfram
15.0.1 kernels. This baseline also predates the request-local logarithmic
builder, so one fixture measures that builder separately from exact-composition
checks. All seven finite outputs and remainders agree exactly. Each fixture
has one warm-up and three measurements; the reports retain all samples and
source/harness hashes.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Six nested logarithmic regions, without exact-composition checks | 0.01520 | 0.00773 |
| Nonconstant trigamma exact probe | 0.00345 | 0.00239 |
| Irrational Bessel order and argument | 0.08311 | 0.08009 |
| Finite trigamma composition | 0.03211 | 0.02811 |
| Incomplete Gamma with irrational shape and input | 0.11596 | 0.07590 |
| Hypergeometric function with a symbolic positive parameter | 0.05790 | 0.04217 |
| Inverse of a Bessel perturbation | 0.03912 | 0.02763 |

These selected local measurements are not general performance guarantees.
The logarithmic builder improvement does not change the previously observed
whole-constructor bottleneck in exact-composition checks.

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Composition'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckCompositionRefactoring.wl
```

## Request-local construction reuse

Generalized logarithmic term-goal searches now keep one lazy builder per
request. Normalized source data and complete multi-index coefficients are
reused between construction calls, including zero coefficients. Every cutoff
still builds its own index region, merges complete blocks and computes the
full boundary remainder. A final shrinking cutoff cannot retain an earlier
overshoot. New constructor calls and `SeriesRefine` start fresh builders.

Composite arithmetic reuses operand data only for literally identical
operands and skips a domain simplification only when its predicate is exactly
the one already checked in that invocation. Both independent input errors
and their product remain present. Different errors and new conditions still
undergo their original checks.

`CheckConstructionRefactoring.wl` selects eight files and records **135 passed,
zero failed** in `construction-refactoring-tests.json`, with unchanged source
hashes. This includes ten new checks for shrinking cutoffs, cancelled
resonances, independent constructor state, refinement, validation order,
error propagation and domain intersections. The standalone build, 11 Python
builder tests and documentation consistency checks also passed.
**The full package suite was not run.**

The `Construction` benchmark set compares immutable commit
`07a9781212beb2eeb9ff16aa625b50ac27974078` with these sources in fresh Wolfram
15.0.1 kernels. All eight finite expressions and remainders agree exactly.
Each fixture has one warm-up and three measured runs; source and harness
hashes are retained in `construction-benchmark-before.json` and
`construction-benchmark-after.json`.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Generalized logarithmic inverse, six blocks | 8.09769 | 8.08571 |
| Cancelled logarithmic resonance, five blocks | 6.14373 | 6.09454 |
| Identical Gamma inverse composite operands, addition | 0.00170 | 0.00093 |
| Identical Gamma inverse composite operands, multiplication | 0.00116 | 0.00085 |
| Exact scalar added to a Gamma inverse composite | 0.00153 | 0.00130 |

The public logarithmic times are essentially unchanged: bounded exact
composition checks dominate these examples. The cache avoids repeated
coefficient work, but these timings do not establish a public logarithmic
speedup. The three unchanged Lerch control fixtures also show the variability
of millisecond measurements. A separate exploratory moment recurrence was
slower for negative and algebraic geometric weights; it was not adopted.

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Construction'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckConstructionRefactoring.wl
```

## GeneralizedSeries and operation simplification (version 1.8.0)

The public result head is now `GeneralizedSeries`. Constructors, arithmetic,
refinement, residual checks, formatting and examples use the new symbol;
the old head is not exported as an alias. StandardForm and TraditionalForm
still hide the head, InputForm retains the full object, and `Normal` drops
the remainder. The Markdown and generated HTML guides describe the renamed
interface and the migration of explicit patterns and saved input. Historical
validation reports and archived development notes retain their original
names and source hashes.

This milestone also extracts the common outer-condition/parameter-assumption
split, gives ordinary real coordinates direct inverse rules, shares Fourier
weight grouping and frequency counting, prunes discarded Fourier product
pairs, and reuses the parsed elementary exponential product. Gamma and Barnes
residual checks share validation and reporting while keeping their independently
written phase formulas. Existing failure order and residual property order
are retained. Symbolic, nonreal and ambiguous coordinate inverses still use
the previous real-solver path.

The `Operations` benchmark set compares an immutable copy of commit
`916481a2745b69334a605cc499d7af6aa4bebb3d` with these sources in fresh Wolfram
15.0.1 kernels. Each fixture has one warm-up and three measured runs. All four
outputs agree exactly, including the public inverse's finite expression and
remainder; the reports preserve individual timings and source hashes.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| 100 ordinary translated-coordinate inversions | 0.12115 | 0.00418 |
| Fourier source merge with repeated frequencies | 0.19112 | 0.09396 |
| 200-by-200 Fourier product below weight 4 | 1.28634 | 0.00776 |
| Public Fourier inverse through target weight 4 | 0.02514 | 0.02325 |

The first three fixtures show approximately 29, 2 and 166 times improvements.
These local measurements do not establish a general public speedup. Reproduce
the selected operation fixtures with:

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Operations'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckGeneralizedSeries.wl
```

`ASYMPTOTIC_BENCHMARK_ROOT` selects an independent baseline checkout or source
copy; `ASYMPTOTIC_BENCHMARK_OUTPUT` selects the output path. The regression
runner explicitly selects 18 files, including four head-contract checks and
32 new coordinate, Fourier and residual checks. `generalized-series-tests.json`
records **305 passed, zero failed**, with all recorded source hashes unchanged
throughout the run. The 11 builder tests and the documentation checks also
passed: all 37 public symbols are documented, generated HTML matches the
source, and the mathematical article remains free of package syntax.
An isolated copy of the standalone file passed all seven acceptance checks
in a fresh kernel, including the renamed head, arithmetic, formatting,
`Normal`, and an explicit reload; the recorded source hashes stayed unchanged.
**The full package suite was not run.**

## Shared arithmetic refactor (commit 916481a)

The internal refactor shares Gamma/Barnes product parsing and branch proofs,
and the cancelled-frontier search used by inverse construction and refinement.
The inverse term-goal loop now consumes the boundary weight already recorded
in its computation state. Sparse multiplication finds its remainder-boundary
degree with a monotone scan instead of a Cartesian scan; merging normalizes
each weight and coefficient once. Native arithmetic skips absolute-majorant
work for exact-zero errors and reuses accepted truncations and error proofs.
Flat multiplication skips exact-zero sectors while retaining uncertain empty
jets, complete omitted-sector sums, and the original resource budget.

Eight focused validation entry scripts now use `FocusedTests.wl`. Their suite
selections, default output paths, and time limits are preserved. This reduces
the runners from 483 to 143 lines, including the helper: 340 lines removed.
The runner checks package loading, rejects empty suites, records source hashes
before loading, rejects changes during testing, and propagates report-export
failures. `focused-runner-tests.json` records eight passing synthetic checks,
including failing tests, timeouts, empty suites, source mutation, missing
files, empty selections, and a syntax error in the package loader.

`refactoring-tests.json` records **316 passing tests in 17 explicitly selected
files**, including 30 new regression tests. There were no failures, and all
recorded kernel, test, and runner source hashes remained unchanged throughout
the run. Coverage includes sparse arithmetic, complete inverse frontiers,
incremental refinement, native error bounds, flat-sector cancellation,
Gamma/Barnes branch conditions and exact identities, and formatting/`Normal`.
The 11 standalone-builder tests and documentation consistency checks also
passed. `refactoring-standalone-tests.json` records seven additional passing
checks in a fresh kernel loading only the generated file from an isolated
directory, including explicit reload, arithmetic, `Normal`, formatting, and
representative inverse/special-function calls. Both the generated file and
its acceptance script retained their recorded hashes. **The full package
suite was not run.**

`BenchmarkRefactoring.wl` ran unchanged in two fresh Wolfram 15.0.1 kernels,
against an immutable copy of commit `0ddac97340cc223abd36fdeceb325bdffbefc5ab`
and the refactored sources. Each fixture had one warm-up and three measured
runs. The two reports include all samples and source hashes; all seven
returned expressions and remainders agree exactly, with stable results
within each run. These are local measurements, not portable guarantees.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Sparse product with finite remainder | 0.4914 | 0.1540 |
| Merge irrational weights and logarithmic polynomials | 0.1303 | 0.0665 |
| Import a 40-coefficient native logarithmic series | 0.0980 | 0.0028 |
| Irrational inverse, five blocks | 8.3630 | 8.2714 |
| Gamma ratio, five correction blocks | 0.4563 | 0.4868 |
| Barnes G, five correction blocks | 3.3755 | 3.4171 |
| Exact summand plus native Erfc tail | 2.0874 | 3.5020 |

The helper fixtures improved by approximately 3.2, 2.0 and 35.5 times.
The public examples do not establish an overall speedup. The initially
slower Erfc result was investigated by alternating the original and
refactored package in one kernel. Median times for the four passes were
6.624, 6.768, 5.963 and 5.896 seconds, respectively, with identical results.
The overlap and variation do not establish a consistent slowdown either;
`refactoring-native-timing-followup.json` preserves these measurements.

To reproduce the selected regression checks and the current benchmark:

```powershell
wolfram.exe -noinit -script validation/CheckFocusedRunner.wl
wolfram.exe -noinit -script validation/CheckRefactoring.wl
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
python validation/check_documentation.py
```

`ASYMPTOTIC_BENCHMARK_ROOT` selects a separate baseline checkout or source
copy, and `ASYMPTOTIC_BENCHMARK_OUTPUT` selects the output report. The default
source is this checkout. Validation selects 17 regression files explicitly;
it does not discover or run the full package suite. The public interfaces,
mathematical article, and user guide are unchanged by this internal refactor.

## Standalone distribution (version 1.7.1)

Version 1.7.1 adds a standalone distribution at the repository root:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticInverse.wl"]]
```

The generated file contains all 38 canonical kernel sources, in their
original load order. The builder records per-source hashes, produces
deterministic UTF-8/LF output, and checks freshness without writes.
Eleven focused Python tests passed, covering ordering, dependencies,
lexical masking, deterministic output, stale artifacts, and failed builds.
The user guide HTML was rebuilt; documentation consistency and local-link
checks passed. This packaging change does not change the mathematical
article or require a new PDF build.

`standalone-loading-tests.json` records **45 successful native checks in
seven fresh Wolfram 15.0.1 kernels**. It covers isolated local, plain HTTP,
and gzip HTTP loads,
the modular kernel entry and `init.m`, `Needs`, explicit reloads, and a
missing HTTP file. The served directory contains only the standalone file;
the request log contains exactly one request per downloaded remote load, plus the expected
missing-file request. Kernels run with `-noinit`, startup-argument environment
variables cleared, and a pre-load check for existing package definitions.
Input hashes are recorded and verified unchanged throughout the run,
including all 38 canonical kernel sources and `init.m` used by the modular
loading cases, as well as the standalone file and validation harness.

Acceptance examples check irrational inversion, certified exact termination,
Gamma ratios, Bessel asymptotics, automatic arithmetic, `Normal`, StandardForm
formatting, and Zeta expansion after an explicit reload. This is focused
loading validation; **the full package suite is skipped**.

The supported command retrieves the complete distribution with `URLDownload`
and loads the resulting temporary file with ordinary `Get`. This addresses
intermittent premature-EOF errors observed with direct cold HTTPS `Get` of
the large file, also reproduced by the local gzip fixture. Both explicit
HTTP stream selection and a literal wrapper in the large file still failed.
The checks verify context placement and string-stream cleanup after both
initial loading and reloading.

`github-loading-tests.json` records **21 successful checks in three fresh
kernels** against the real `main` standalone URL using `Get[URLDownload[...]]`.
`github-pinned-loading-tests.json` records **seven successful checks** against
the immutable standalone at `fd357dd2e022bfd8deceae5537fcd2a594c41938`.
Both records verify the published bytes against the local artifact before
and after native loading. No full package suite was run.

Across the three current records, **all 73 native checks passed in 11 fresh
kernels**, with zero failures and normal process exit. An earlier nested
HTTP convenience loader was withdrawn after two later native runs ended
abnormally, despite their seven mathematical checks passing. Its earlier
successful record and the subsequent failure observations are preserved
in the [validation archive](archive/README.md); they are not evidence for
a currently supported loading route.

To reproduce these checks:

```powershell
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
python validation/check_standalone_loading.py
python validation/check_documentation.py
```

After publishing, check the downloaded standalone form with:

```powershell
python validation/check_standalone_loading.py --url https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticInverse.wl --repeat 3 --output validation/github-loading-tests.json
```

The published-URL runner compares the remote file byte for byte with the
local build before and after native loading. Replacing `main` in the
standalone URL with a full commit hash selects an immutable revision for
the same downloaded-file check.

The special-function extension in version 1.7.0 is recorded in
`special-functions-tests.json` and `special-functions-validation.json`.
**All 220 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. Twelve files were explicitly selected; the full package suite
was skipped at the user's request. The runner records source hashes before
loading the package and verifies that every tested file remains unchanged
through the run.

The new checks cover finite and infinite special-function expansions,
fixed-parameter composition with irrational powers, exact identity lowering,
oscillatory absolute errors, independent coefficient formulas, conservative
logarithmic tail bounds, and public Zeta/Lerch dispatch and refinement.
Eight checks verify that `Normal` returns an ordinary finite expression,
including `0` for a pure remainder, without exposing remainder or provenance
objects. Selected Gamma, Barnes G, exponential, arithmetic, and formatting
regressions passed alongside the new files.

The broad importer preserves native structured remainders, proves the real
source branch before real projection, and computes enough omitted terms to
justify the returned frontier. Exact half-integer Bessel identities retain
both exponentials. The Zeta and Lerch expansions have independently derived
pointwise tail bounds under their recorded conditions. Other imported
Poincare results assert an asymptotic error class, without a pointwise
constant or an automatic derivative certificate.

`AsymptoticInverse/Examples/SpecialFunctions.wl` checks and prints five public
examples, including their ordinary `Normal` expressions. The native preview
is generated by `RenderSpecialFunctions.wl`. The separate user guide includes
function-family and endpoint scope, block conventions, branch conditions,
and examples. Its HTML is checked against the source and for broken links.
The mathematical article adds a fixed-measure moment theorem and its
special-function consequences. The 95-page PDF was built with three serial
strict passes, and every page was rendered; all contact sheets and the new
dense formula pages were visually inspected. Exact artifact hashes and
the final preview result are recorded in the validation manifest.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckSpecialFunctions.wl
wolfram.exe -script AsymptoticInverse/Examples/SpecialFunctions.wl
wolfram.exe -script validation/RenderSpecialFunctions.wl
python validation/build_user_guide.py
python validation/check_documentation.py
```

The article build and rendering commands are in `article/README.md`.

The automatic series arithmetic update is recorded in
`series-arithmetic-tests.json` and `series-arithmetic-validation.json`.
**All 137 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. Seven files were explicitly selected: automatic arithmetic,
composite arithmetic, composite functions, existing series operations,
formatting, Gamma inverse operations, and Barnes inverse regressions.
The full package suite was skipped at the user's request.

The checks cover ordinary operators, regular function operands, exact
coefficients, propagated precision, held normalization before cancellation,
adaptive working orders for new nonlinear operations, real branches,
separate error scales, contradictory domains, resource bounds, and existing
inverse and formatting behavior. Independent formulas check the retained
coefficients and error orders. `Normal` continues to return the ordinary
finite expression, dropping the remainder and the series metadata.

`AsymptoticInverse/Examples/Arithmetic.wl` ran successfully. The native
front-end renderer produced `series-arithmetic-preview.png`, which was
visually inspected for notation, grouping, remainder display, and clipping.
The renderer reported that ImageMetadataTools could not be installed, but
returned an image and exported the reviewed PNG successfully.

The Wolfram-style guide documents ordinary arithmetic, `SeriesNormalize`,
precision limits, and composite results. Its HTML was regenerated and
checked for links and source parity. The separate mathematical article
proves the error-envelope rules for arithmetic and supported functions.
The 88-page PDF was rebuilt with three serial LaTeX passes and every page
was rendered for layout inspection. The validation JSON records the final
artifact hashes and the scope of visual review.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckSeriesArithmetic.wl
wolfram.exe -script AsymptoticInverse/Examples/Arithmetic.wl
wolfram.exe -script validation/RenderSeriesArithmetic.wl
python validation/build_user_guide.py
python validation/check_documentation.py
```

The article build and rendering commands are in `article/README.md`.

The invisible `PowerLogSeries` display update is recorded in
`formatting-tests.json` and `formatting-validation.json`. **All 13 focused
tests passed**, with zero failures on Wolfram 15.0.1 for Windows. Only
`Formatting.wlt` was selected; the full package suite was skipped.

The tests check StandardForm and TraditionalForm interpretations, complete
association preservation, reconstructible InputForm text and boxes, explicit
read-only formatting, and independent visible grouping under powers,
products, reciprocals, negation, and function application. Fixtures include
ordinary, Barnes inverse, exponential, reciprocal-logarithmic, flat-sector,
and nested-logarithmic series. Raw held formatting leaves visible fields,
remainder coordinates, and hidden metadata unevaluated. `Normal` returns the
finite ordinary expression, including zero for a pure-remainder result.

`formatting-preview.png` was generated by the native Wolfram front end and
visually inspected for notation, grouping, and clipping. Its renderer emitted
an environment message that ImageMetadataTools could not be installed; it
nevertheless returned an image and successfully exported the reviewed PNG.
The mathematical article is unchanged. The user guide's HTML was regenerated
and its links and source parity were checked.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckFormatting.wl
wolfram.exe -script validation/RenderFormatting.wl
python validation/check_documentation.py
```

The native `LogBarnesG` update is recorded in `log-barnes-g-tests.json`
and `log-barnes-g-validation.json`. **All 134 focused tests passed**,
with zero failures on Wolfram 15.0.1 for Windows. The full package suite
was skipped at the user's request. The runner selects 17 new native-log
tests and five adjacent Barnes, Gamma, and branch regression files.

The requested applied inverse now uses the existing Barnes coefficient
calculus with the unlogged target coordinate. Tests independently check
its three blocks and frontier, affine forms, powers, refinement, source
and target domains, formal residuals, and 60-digit numerical references
with known source roots 100 and 1000. The exact checking equation uses
native `LogBarnesG` for all positive Barnes inverse forms.

Forward checks cover the five-block expansion, shifted sparse corrections,
finite positive Taylor expansion, exact native/wrapped-log cancellation,
the Barnes recurrence, and exponentiation. Native constants remain intact
and cannot change the inverse family when used inside Gamma arguments.
Expansion of a varying `LogBarnesG` argument requires an eventually positive
argument; nonpositive tails are rejected before native generic series expansion.

The Wolfram-style user guide includes the literal native inverse and
forward syntax, logarithmic target domain, and numerical examples. Its
HTML was rebuilt, checked for local links, and visually reviewed at
desktop and mobile widths. The mathematical article already proves this
logarithmic inverse expansion; its source and previously reviewed PDF are
unchanged, and the PDF hash was verified.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckLogBarnesG.wl
python validation/check_documentation.py
```

The increasing Barnes G inverse update is recorded in
`barnes-g-inverse-tests.json` and `barnes-g-inverse-validation.json`.
**All 142 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. The full package suite was skipped at the user's request.
The runner explicitly selects the 24-test inverse Barnes file and five
adjacent inverse Gamma, branch, callable-expression, and Barnes forward files.

The new tests independently derive the first four source blocks, the next
frontier coefficient, and powered observables. They cover the literal
applied conditional inverse, affine and logarithmic targets, reciprocal
forward powers at a finite target, named and slot callables, exclusive
cutoffs, refinement, inherited power precision, branch restrictions,
formal residuals, and a 60-digit numerical reference at `BarnesG[100]`.
That exact target has source root 100 by the Barnes recurrence. The
three-block error is positive and agrees with its first omitted term.
The numerical comparison is explicitly not an interval certificate.
A regression also ensures that a Barnes-valued affine constant inside
Gamma or LogGamma does not change the inverse family.

The pure mathematical article proves monotonicity above three, derives
the Lambert balance and polynomial recurrence, and transports the finite
Barnes remainder to the inverse. The separate Wolfram-style guide gives
the requested syntax, related forms, operations, and limitations. The
87-page PDF was rebuilt with three serial LaTeX passes and every page was
rendered. Changed and new pages were visually reviewed; unchanged pages
20-82 were verified to have identical rendered bytes to the preceding
Barnes milestone. Desktop and mobile guide screenshots were inspected,
with no document overflow or broken local links.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckBarnesGInverse.wl
python validation/check_documentation.py
```

The native report records exact byte hashes of the tested kernel, tests,
and runner. The validation ledger also records the final PDF hash and
the scope of static, browser, and mathematical review.

The Barnes G update is recorded in `barnes-g-tests.json` and
`barnes-g-validation.json`. **All 94 focused tests passed**, with zero
failures on Wolfram 15.0.1 for Windows. The full package suite was skipped
at the user's request. The runner explicitly selects the 22-test Barnes
file and five adjacent Gamma and exponential regression files.

The Barnes tests use independent Bernoulli and exponential-recurrence
coefficients. They check the literal five-block expansion, the sparse
even corrections of `BarnesG[x + 1]`, logarithms, fixed and varying powers,
mixed Gamma products, exact recurrence cancellation, fractional and
symbolic common offsets, transported domain conditions, refinement, and
square-root and quadratic arguments. A finite Barnes logarithmic model
always retains its asymptotic tail; exact termination instead requires
an identity of the original functions.

The separate Wolfram-style user guide includes the requested expression
and related examples. Its HTML was rebuilt and checked at desktop and
mobile widths. The pure mathematical article derives the Barnes formula,
the argument shift, and its absolute and relative remainders. The final
83-page PDF was built with three serial LaTeX passes and every page was
rendered. All contact sheets and the Barnes pages were visually inspected.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckBarnesG.wl
python validation/check_documentation.py
```

The runner exports per-test outcomes and hashes of the tested kernel,
test, and runner files. Article build and render commands are in
[article/README.md](../article/README.md).

The logarithmic Gamma update is recorded in `gamma-logarithms-tests.json`
and `gamma-logarithms-validation.json`. **All 87 focused tests passed**, with
zero failures on Wolfram 15.0.1 for Windows. The full suite was skipped at
the user's request.
Its focused runner checks `GammaLogarithms.wlt` together with the existing
Gamma product, fixed-power, varying-power, related-function, and elementary
exponential suites. The new 18-test file uses independent Bernoulli and
Taylor coefficients for the requested `Log[Gamma[x]]` expansion, complete
block counts, first omitted terms, exact recurrence cancellation, finite
and infinite endpoints, real branches, symbolic powers, and refinement.
The full package suite is excluded from this runner.

The shared logarithmic source is normalized before ordinary expansion.
Gamma arguments and powers are checked before applying real logarithmic
identities. The original expression and target conditions remain available
for refinement. Ordinary forward results now also report
`RequestedTermGoal` and `ReturnedTermCount`. The separate user guide
includes the literal request, supported logarithmic extensions, and the
absolute cutoff convention; its standalone HTML and links were checked.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckGammaLogarithms.wl
python validation/check_documentation.py
```

The runner exports per-test outcomes and hashes of the tested source files.
Earlier records below retain the scope and source revision of their own
milestones.

The inverse-Gamma extension is recorded in `gamma-inverse-tests.json` and
`gamma-inverse-validation.json`. **All 134 focused regression tests passed**
on Wolfram 15.0.1 for Windows, in six explicitly selected files: the two
new inverse-Gamma suites, inverse-function branches and expressions,
special-function regressions, and Gamma products. The full package suite
was **not run**, as requested.

The new cases check independent coefficients and the first omitted block,
affine and signed target transformations, reciprocal Gamma at a finite
target, exact real source powers, branch ambiguity, source and target
conditions through refinement, transported `SeriesPower` precision, formal
finite-Stirling residuals, and a 100-digit numerical comparison at
`Exp[10000]`. Numerical comparisons use the original `LogGamma` equation;
they are not interval certificates. The executable runner records every
test outcome and SHA-256 hashes of the tested kernel and test files.

The separate guide now includes an inverse-Gamma reference section and
six additional documentation checks. Its current 32-check result is in
`gamma-inverse-documentation-tests.json`; the earlier 26-check result is
preserved in `documentation-tests.json`. The mathematical article adds
the coefficient recurrence, finite-order proof, and first omitted error
constant. The final article has 82 pages; every page was rendered, and
contact sheets and selected full pages were visually inspected. The HTML
guide was checked at desktop and mobile widths.

`gamma-inverse-documentation-initial-tests.json` preserves the first
documentation run: 31 checks passed and one reported an unexpected message
while rejecting an invalid target for `-1/Gamma[x]`. The real target
inequality is now checked without first forming a logarithm outside its
domain, eliminating the complex-comparison warning.

To reproduce just this milestone from the repository root:

```powershell
wolfram.exe -script validation/CheckGammaInverse.wl
$env:ASYMPTOTIC_VALIDATION_OUTPUT = "$PWD/validation/gamma-inverse-documentation-tests.json"
wolfram.exe -script validation/CheckDocumentation.wl
Remove-Item Env:ASYMPTOTIC_VALIDATION_OUTPUT
python validation/check_documentation.py
```

These runners use explicit test lists. `CheckGammaInverse.wl` also accepts
`ASYMPTOTIC_VALIDATION_OUTPUT` for an alternate report destination. The
following records describe their original historical milestones.

The documentation split is recorded in `documentation-split.json` and
`documentation-tests.json`. The mathematical article was rebuilt with three
serial LaTeX passes and reviewed as rendered pages. The separate user guide
has a reproducible standalone HTML build, public API anchors, and checked
local links. The record includes the final source and artifact hashes and
the precise visual review scope.

**All 26 focused documentation checks passed**, with zero failures on
Wolfram 15.0.1 for Windows. They check the displayed expressions and relevant
remainders or properties for ordinary and irrational inverses, Gamma products
and varying powers, elementary growth, series operations, precision limits,
certification, and the specialized inverse families. The runner checks the
guide against all 36 native public symbols. It runs only its explicitly
listed examples and does not discover package regression files.

The full package suite was **not run**, as requested. The documentation
change only updates usage strings in executable package sources; the
algorithms are unchanged. Historical test records below retain their original
revision and scope.

To reproduce documentation checks from the repository root:

```powershell
python validation/build_user_guide.py --check
python validation/check_documentation.py
wolfram.exe -script validation/CheckDocumentation.wl
```

The native runner exports `validation/documentation-tests.json` by default;
set `ASYMPTOTIC_VALIDATION_OUTPUT` to use another destination. Each example
has a 60-second limit. PDF build and render commands are documented in
[article/README.md](../article/README.md).

The final exact-recovery follow-up is recorded in
`growth-exact-recovery-tests.json`: **57 focused tests passed in four suites,
with zero failures**, on Wolfram 15.0.1 for Windows. This record preserves
the completed runner's aggregate suite outcomes and tested-source hashes;
individual test outcomes were not exported by that focused runner.
The subsequent full-suite rerun was cancelled at the user's request.
The earlier successful 845-test full run below covers the preceding
milestone, not this final source revision.

The follow-up keeps a valid logarithmic expansion when an optional exact-jet
probe encounters an unsupported representation. The added independent
regression checks cancellation in `x^-5 (1+x)^(1/x^2) Exp[-1/x]` near zero,
its relative cutoff and absolute remainder, and refinement to the next
correction. An unsuccessful optional probe cannot establish exactness or
discard the already computed approximation.

To reproduce just these focused tests in a Wolfram kernel from the root:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
TestReport[FileNames[{
  "ExponentialForward.wlt", "GammaProducts.wlt",
  "GammaRelatedFunctions.wlt", "GammaVaryingPowers.wlt"
}, "AsymptoticInverse/Tests"], ProgressReporting -> False]
```

The Gamma-product and elementary-growth update is recorded in
`gamma-products-and-growth-tests.json`. Its final native run passes
**845 tests in 38 suites, with zero failures**, on Wolfram 15.0.1 for Windows.
Its 56 new regressions cover the
requested `Gamma[3 x]/Gamma[x]` ratio, products, reciprocal and varying real
powers, factorials, binomial coefficients, complete beta functions, rising
factorials, and elementary exponential prefactors. Exact correction tables
come from independent Bernoulli-logarithm and exponential-convolution
oracles. A 100-digit normalized evaluation at `x = 1000` checks the requested
ratio against its independently derived first omitted term; it is numerical
asymptotic evidence, not an interval certificate or pointwise error bound.

The same tests check relative cutoffs and nonzero block counts, signed
absolute remainders, source- and domain-preserving refinement, finite Gamma
factors, and realness that holds only eventually. Exact recurrence and
polynomial identities terminate with zero remainder by recovering an exact
jet from the original logarithmic identity. Cancellation in a finite
Stirling approximation does not establish exactness. Optional symbolic
prefactor simplification is bounded and can retain an equivalent exact form.

`gamma-products-and-growth-initial-tests.json` preserves the first complete
run: 843 tests passed and two failed. The Laurent reciprocal regression
exposed an overly broad normalization rule. The corrected rule requires
an elementary logarithmic source to grow faster than `Log[u]`, preserving
ordinary power-law cutoffs for `1/(Exp[x^5] - 1)` near zero. The generated
three-irrational-gap case hit its existing 30-second per-case limit;
all 19 generated-oracle tests passed on the targeted rerun with that limit
unchanged. The 25 review regressions and 16 exponential tests also passed
in that targeted run.

To reproduce the full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-products-and-growth-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved records include the baseline commit and SHA-256 hashes of the
tested kernel and test sources, added after each run. Earlier milestone
records below are preserved.

The Gamma-power update is recorded in `gamma-powers-tests.json`. Its final
native run passes **789 tests in 34 suites, with zero failures**, on Wolfram
15.0.1 for Windows. The 12 new regressions cover the exact requested
`Gamma[x]^2` expression, independently derived correction coefficients and
frontier, the full absolute remainder, reciprocals, rational and irrational
powers, scaled arguments, domain-preserving refinement, and finite-point
behavior. An exact irrational exponent cancels the degree-three correction;
the term goal correctly skips it. A 100-digit normalized numerical comparison
at `x = 1000` verifies the square at the independent first-omitted scale.

The tail construction uses `r LogGamma[arg]` for fixed exact real numeric
`r`, retaining the powered original expression and logarithmic provenance.
Unsupported tail exponents do not intercept regular finite-point expansions.
To reproduce the full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-powers-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved JSON additionally records the baseline commit and SHA-256 hashes
of the changed kernel and test sources, added after the successful run.

The Gamma forward-expansion update is recorded in `gamma-forward-tests.json`.
Its final native run passes **777 tests in 33 suites, with zero failures**, on
Wolfram 15.0.1 for Windows. The 18 new regressions verify the requested
five-term expansion against independent Stirling coefficients, the full
prefactor-scaled remainder and frontier, a 100-digit normalized numerical
comparison at `x = 1000`, positive growing argument substitutions, finite
endpoints, relative cutoffs, domain-preserving refinement, and compatible
series operations. Invalid budgets, cutoffs, and source approaches are
also covered. The full suite includes the earlier callable-input regressions.

The implementation expands `LogGamma` using the existing forward engine,
then uses its explicit series exponential to transport the remainder and
extract the exact prefactor. The result records a Poincare expansion and
does not assert convergence or an unproved derivative remainder contract.
The numerical comparison is evidence of asymptotic accuracy, not an
interval certificate or pointwise error bound.

To reproduce the Gamma update's full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-forward-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved JSON additionally records the baseline commit and SHA-256 hashes
of the changed kernel and test sources, added after the successful run.

The callable-input update is recorded in `callable-expansion-tests.json`.
Its final native run passes **759 tests in 32 suites, with zero failures**, on
Wolfram 15.0.1 for Windows. The 17 new regressions cover rule coordinates,
unapplied inverse and pure functions, native inverse simplification, lexical
scoping, option forwarding, arity failures, conditional wrappers, and source
conditions retained through refinement. The requested five-term inverse of
`x + x^Sqrt[2]` at infinity is checked against independently derived Lagrange
coefficients, its exact reciprocal-coordinate remainder, and a vanishing
formal composition residual. The JSON also records the baseline commit and
SHA-256 hashes of the changed source and test files.

To reproduce this run from the repository root:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\callable-expansion-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The runner exports test outcomes; the baseline and changed-source hashes in
the saved record were added after the successful run.

Version **1.5.0**, the fourth extension milestone, is recorded in
`milestone-4-tests.json` and `milestone-4-artifacts.json`. The suite covers
applied `InverseFunction` expressions, both original conditional examples,
lexical and selected-argument callable forms, exact varying affine output
families, nested and critical-point composition, native `ProductLog` branches,
symbolic real offsets, algebraic coefficients, and condition-preserving
refinement. Numerical checks and interval certificates retain source domains;
closed rational endpoint comparisons use exact affine bounds before interval
rounding. Tests use explicit coefficient formulas, original-equation residuals,
independently known source roots and certified rational containment.
The final native run passes **742 tests in 31 suites, with zero failures**, on
Wolfram 15.0.1 for Windows.

The milestone also admits expansion-variable assumptions after proving them
on the selected deleted neighborhood. A former test requiring their blanket
rejection is replaced by acceptance with a retained domain and rejection of
an incompatible approach. Unknown input remainders cannot prove equality in
an observable condition, and an excluded inverse endpoint is not silently
filled by continuity.

Observable comparisons distinguish the input placeholder from the original
expansion variable. An expression involving that original variable is expanded
in its own recorded coordinate instead of being mistaken for a constant
coefficient. N-ary `Unequal` checks every pair. These rules prevent a truncated
`Sin[y] = y + O[y^3]` input from falsely proving inequality with `y`.

The artifact register records the tested source hashes and both rebuilt PDF
hashes. Each document received three serial strict LaTeX passes and complete
page rendering; the visual-review scope is recorded separately. Only Wolfram
15.0.1 is validated. The earlier standalone generated campaign and performance
benchmark remain historical evidence and were not rerun for this milestone.
No new quantitative performance claim is made for the per-call syntax and
branch caches.

The original review started from commit `1716eb8`. The native baseline contained
49 passing tests. The historical records below describe version 1.1.0.

The first extension milestone, version 1.2.0, is recorded separately in
`milestone-1-tests.json`, `incremental-benchmark.json`, and
`milestone-1-artifacts.json`. Its eight delivered suites pass 161 tests on
Wolfram 15.0.1, including all 130 previous regressions and 31 new coordinate
and incremental-engine tests. `Tests/BenchmarkIncremental.wl` reproduces three
exactly equal comparisons. Term-goal coefficient evaluations fall from 95 to
31; the measured term-goal and Newton cases improve, while the small grouped
public-method case is slower. Historical snapshots are retained as evidence
of their original milestone, not as hashes of the current source tree.

The second extension milestone, version 1.3.0, is recorded in
`milestone-2-tests.json` and `milestone-2-artifacts.json`. All **311 tests in
13 shipping suites pass** on Wolfram 15.0.1. The new suites cover explicit
calculus, exact-core marker corrections, rigorous rational certificates,
source charts, and 46 independent generated inverse oracles. Certificate
tests include absolute and relative accuracy, zero-root fallback, both
Lambert branches, a near-turning-point bracket and exact-core seeds.
The combined run is a regression run, not a performance comparison with
earlier, smaller suites. Refinement regressions distinguish automatic
forward truncation from a binding declared input error.

`Tests/GeneratedInverseOracles.wlt` records seed 236367 and the generator
method. Forty quadratic cases compare against an independent radical inverse
expanded by the native Taylor-series implementation; six irrational-gap
cases use independent first-coefficient formulas. Case IDs include the
generated parameters. Failed test exports retain expected and actual output
and messages for reproduction. Wider generated families and automatic
counterexample shrinking were deferred in that milestone and are delivered
by the third milestone below.

The third extension milestone, version **1.4.0**, is recorded in
`milestone-3-tests.json`, `refinement-benchmark.json`, `generated-campaign.json`
and `milestone-3-artifacts.json`. It includes the earlier suites plus finite
logarithmic hierarchies, exact growing exponential-core sectors, flat-sector
and reciprocal-log operations, Fourier coefficients, special-function
adapters, retained refinement states and structured requests. Acceptance
suites add coordinate and calculus edge cases, several absolute and relative
certificate tolerances, invalid intervals and insufficient-precision recovery.
Tests compare against independent marker substitutions, exact inverse
formulas and original-equation numerical oracles as appropriate. Passing
tests complement the article's stated mathematical contracts. The final
native run passes **602 tests in 25 suites, with zero failures**, on
Wolfram 15.0.1. The standalone campaign passes all 32 cases, and all nine
benchmark comparisons satisfy their acceptance checks.

The final audit repaired a certificate retry that increased arithmetic order
without resolving invalid bracket geometry. Exact endpoint signs now provide
an alternative existence argument, and a proved same-sign interval exits
immediately. Other regressions preserve reflected Erfc signs, special-adapter
options during refinement, affine Lambert threshold limits, exact small
target differences, observable-dependent numerical errors and explicit replay
statistics. Logarithmic term goals count nonzero blocks despite cancellation.

The nine-case refinement benchmark checks exact equality at every requested
cutoff and the retained-state invariants; the deep one-gap case also uses an
independent Catalan oracle through cutoff 64. In the recorded single sample,
the high-logarithmic-degree Lagrange fixture is about 4.6 times faster.
Two smaller fixtures are slower and most retain more memory. Timings and
evaluation memory peaks are empirical, not portable guarantees or total
process-memory bounds. Polynomial-power cache counters describe their
specific reused work, not the cost of the complete computation.

The standalone campaign uses seed 236369 and 32 cases covering two cycles of
16 bounded families. `generated-campaign.json` preserves the manifest, full
inputs, each expected/actual result and its captured message file. The runner
also preserves completed shrink attempts when failures occur. Shrinking is
exercised by deterministic injected failures in the regression suite; a
passing campaign does not itself demonstrate the failure path. The source
hashes and actual native kernel version are part of the preserved manifest.

The installed 14.3 engine failed its startup probe with exit code 62 and
`No valid password found`; no package test ran on that engine. The paclet
minimum is now 15.0, replacing the former untested 13.0 declaration.
Only 15.0.1 is validated; successful 15.0.1 tests do not establish a result
for an older engine or a future version.

The review corrected observable-dependent transport of forward remainders,
negative-target remainder coordinates, source-side frontier signs, logarithmic
degrees lost at precision boundaries, hidden leading terms after cancellation,
exact-input and branch validation, symbolic depth handling, and finite inverse
termination. The article's convergence class, closure proof, semigroup-tail
argument, signed endpoint formulas, radius claims, and several displayed
coefficients were corrected alongside the implementation.

The new Lambert engine computes finite asymptotic expansions with explicit
relative logarithmic remainders. It handles both `x Log[x]` near zero and
`x Exp[x]` at infinity, as well as affine-logarithm powers, arbitrary polynomial
leading logarithmic blocks with nonzero algebraic power, source infinities,
growing and decaying exponential cores, and specified higher-power
perturbations. Numerical checks use the original forward expression.
General polynomial logarithmic cores do not claim an exact ProductLog inverse.

## Native regression tests

Run from the repository root:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path $env:TEMP 'asymptotic-local-tests.json'
wolfram.exe -script AsymptoticInverse/Tests/RunTests.wl
```

The optional output records the Wolfram kernel version and each test outcome.
The historical 1.1.0 combined run in `test-results.json` passed
**130 tests with zero failures** on Wolfram
15.0.1 for Microsoft Windows (64-bit). Its approximately 99-second total
includes symbolic and numerical Lambert tests; it is not a benchmark against
the original, smaller suite. Two original expectations were intentionally
updated: a logarithmic core is now supported, and a cancelled inverse frontier
is skipped when the next nonzero block is found.

## Performance

`benchmark-snapshot.json` records original-commit versus updated-algorithm
measurements made during this review. All four computed results agreed.
The three targeted fixtures improved by approximately 105–110 times. The
weighted-region fixture became approximately 1.75 times slower while gaining
bounded boundary allocation and accurate budget enforcement. These results
are fixture-specific and machine-dependent.

The reference algorithms are preserved for reproducibility:

```powershell
wolfram.exe -script AsymptoticInverse/Tests/BenchmarkPerformance.wl
```

## Article

The final TeX is built with three serial strict passes:

```powershell
Push-Location article
1..3 | ForEach-Object {
    pdflatex.exe -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex
    if ($LASTEXITCODE -ne 0) { throw 'LaTeX build failed' }
}
Pop-Location
python validation/inspect_pdf.py article/asymptotic-inverse.pdf TEMP_RENDER_DIRECTORY
```

`inspect_pdf.py` uses Poppler, Pillow, and pdfplumber to render every page,
generate contact sheets, and inspect text geometry. `article-validation.json`
records the historical review PDF; each milestone artifact manifest records
its own PDF hash, page count, build diagnostics, and completed visual review.
Geometry checks supplement visual inspection; they do not establish
mathematical correctness. The local Fabius research sources were read as
references and were not modified.

The package README states remaining input-class boundaries. The finite flat
algebra has separate inner and exponential-sector truncations within its
proved commensurable phase family. Arbitrary phase families, general nonlinear
sector composition and unrestricted transseries remain outside that scope.
An exact symbolic composition certificate is distinct from a numerical root
check or a residual of a finite forward model.
