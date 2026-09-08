# Review and validation record

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
