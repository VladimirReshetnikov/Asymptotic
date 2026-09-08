# Review and validation record

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
counterexample shrinking remain campaign work.

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
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location) 'validation/test-results.json'
wolfram.exe -script AsymptoticInverse/Tests/RunTests.wl
```

`test-results.json` records the Wolfram kernel version and each test outcome.
The final combined run passed **130 tests with zero failures** on Wolfram
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

The package README states remaining input-class boundaries. In particular,
this is not a general engine for independently truncated exponential sectors,
and an exact symbolic composition certificate is distinct from a numerical
root check or a residual of a finite forward model.
