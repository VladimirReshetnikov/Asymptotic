# Package tests and focused validation

This directory contains Wolfram `VerificationTest` files, generated-oracle
checks, a full regression runner, and separate campaign and benchmark scripts.
The [validation guide](../../validation/README.md) records accepted milestones,
source provenance, and the distinction between native execution, static checks,
numerical evidence, certificates, and PDF review.

The current development request is to **skip the full suite**. Use an explicit
selection of relevant tests, run one Wolfram kernel at a time, and record the
actual scope and result. Adding a test file does not establish that it passed.

## Run an existing focused harness

Run from the repository root, with `wolfram.exe` available on `PATH`:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path $env:TEMP 'asymptotic-assumption-replay-local.json'
wolfram.exe -noinit -script validation/CheckReviewAssumptionReplay.wl
if ($LASTEXITCODE -ne 0) { throw 'Focused validation failed' }
```

This example selects only [ReviewAssumptionReplay.wlt](ReviewAssumptionReplay.wlt).
Use another entry script when its explicit selection matches the change:

| Coverage | Entry script |
| --- | --- |
| Inverse coefficient model admission, ordinary coefficients, stored assumptions and native contracts | [CheckInverseCoefficientModel.wl](../../validation/CheckInverseCoefficientModel.wl) |
| Fourier coefficient termination, public residual budgets and convolution controls | [CheckFourierTermination.wl](../../validation/CheckFourierTermination.wl) |
| Principal-log normalization and symbolic-depth, core, flat-sector and assumption consumers | [CheckLogPowerNormalization.wl](../../validation/CheckLogPowerNormalization.wl) |
| Observable Taylor endpoints, sided constants and complete-argument reality, with calculus neighbors | [CheckObservableIngress.wl](../../validation/CheckObservableIngress.wl) |
| Merged-source normalization, native search, and package identity | [CheckMergedReviewFixes.wl](../../validation/CheckMergedReviewFixes.wl) |
| Compatible native-backend retries, held evaluation, and adjacent native contracts | [CheckNativeSearch.wl](../../validation/CheckNativeSearch.wl) |
| Equal-exponent collection and composition parameter scope, with arithmetic and scale neighbors | [CheckReviewNormalization.wl](../../validation/CheckReviewNormalization.wl) |
| Only the equal-exponent and composition-scope regressions | [CheckReviewScopeAndEquality.wl](../../validation/CheckReviewScopeAndEquality.wl) |
| Renamed package identity, native backends, inverse syntax and certificates | [CheckPackageRename.wl](../../validation/CheckPackageRename.wl) |
| Native formal-order import and export within the analytic representation | [CheckReviewNativeTails.wl](../../validation/CheckReviewNativeTails.wl) |
| Complete real coefficients and adjacent constructors | [CheckReviewRealCoefficients.wl](../../validation/CheckReviewRealCoefficients.wl) |
| Assumption capture and retained proof contexts | [CheckReviewAssumptions.wl](../../validation/CheckReviewAssumptions.wl) |
| Nonlinear remainder degrees and coefficient termination | [CheckReviewUnitArithmetic.wl](../../validation/CheckReviewUnitArithmetic.wl) |
| Fractional-power branch handling | [CheckReviewPowerBranches.wl](../../validation/CheckReviewPowerBranches.wl) |
| Automatic arithmetic, composite bounds, and formatting | [CheckSeriesArithmetic.wl](../../validation/CheckSeriesArithmetic.wl) |
| Result-head, coordinate, Fourier, and inverse-check regressions | [CheckGeneralizedSeries.wl](../../validation/CheckGeneralizedSeries.wl) |
| Wave-6 public-boundary repairs: coefficient option spellings, target-dependent `SourceShift`, numerical-check labels, numeric-constant coordinates, the Fourier residual cutoff, conditional observables and affine Dirichlet atoms, with their neighbouring suites | [CheckWave6Boundaries.wl](../../validation/CheckWave6Boundaries.wl) |

Read the selected entry script's `"Suites"` list before running it. The shared
[FocusedTests.wl](../../validation/FocusedTests.wl) does not discover other
test files. It loads the package once, runs the chosen files serially with a
per-file time limit, captures outcomes and source hashes, and checks that the
sources stayed unchanged. Its exit code is nonzero if validation or report
export fails. Unexpected messages appear in failed-test details.

`ASYMPTOTIC_VALIDATION_OUTPUT` selects a JSON file in an existing directory.
Without it, the entry script's `"Output"` name is used under `validation/`.
Use a fresh local destination to preserve committed evidence. The environment
override persists in the current PowerShell session; change or clear it before
another run when a different destination is needed.

## Define a smaller selection

For a change with no suitable existing harness, create a named entry script
under `validation/`, following this example. Keep its selection explicit and
describe exactly what it runs:

```wolfram
(* validation/CheckLocalFocus.wl *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[
  DirectoryName[DirectoryName[$InputFileName]], $InputFileName,
  <|"Suites" -> {"GeneralizedSeries.wlt", "NormalExpressions.wlt"},
    "Output" -> "local-focus-tests.json",
    "Timeout" -> 600,
    "Scope" -> "Two explicitly selected result-head and Normal regression files; the full package suite was not run."|>]];
```

Then invoke that file with `wolfram.exe -noinit -script
validation/CheckLocalFocus.wl`. This is a template; `CheckLocalFocus.wl` is not
a shipped runner. The shared harness records the entry script's hash along
with the tests and kernel sources. Preserve the script with a saved acceptance
report so its selection can be reproduced.

Tests should check the mathematical or public contract: independent
coefficients, original-equation residuals, branch and domain preservation,
valid remainder bounds, and meaningful failure cases. Internal helper tests
can isolate a defect, but their passing results do not replace public-path
checks. Use stable, descriptive `TestID` values so a failed assertion can be
located without relying on the file's current test count.

## Focused native-backend acceptance

[CheckNativeSearch.wl](../../validation/CheckNativeSearch.wl) records
[179 passed, zero failed tests](../../validation/native-search-tests.json)
across nine selected files on Wolfram 15.0.1 for Windows, with source hashes
unchanged during the run. Its 16 [NativeSearch.wlt](NativeSearch.wlt) cases
check successful second-backend selection, stopping after a first success,
retaining the preferred unresolved result, explicit-native delegation, and
once-only source and common-option evaluation. They also check unused delayed
duplicates, nested option containers, native-exclusive options, and the ordered
`NativeAttempts` metadata. Neighboring suites cover automatic routing,
presentation, result contracts, assumptions, real coefficients, and inverse
syntax. Protected directions and branch conditions remain separate coverage
work; this acceptance does not establish the complete input-superset objective.

The historical [130/0 explicit-native record](../../validation/native-compatibility-tests.json)
and [163/0 automatic-routing record](../../validation/native-automatic-tests.json)
describe earlier source snapshots. Their runners,
[CheckNativeCompatibility.wl](../../validation/CheckNativeCompatibility.wl) and
[CheckNativeAutomatic.wl](../../validation/CheckNativeAutomatic.wl), remain useful
smaller selections. Those saved counts and hashes do not validate subsequent
source changes.

The [native compatibility plan](../../docs/development/NATIVE_COMPATIBILITY.md)
describes the implementation and contract boundaries.
Native-backend acceptance is separate from the analytic import/export checks:
a preserved native result does not acquire an independently proved remainder.

[CheckReviewCertificateAccuracy.wl](../../validation/CheckReviewCertificateAccuracy.wl)
selects report 18 N01 / C19's relative-accuracy, retry, sharp-bound, best-result,
and budget/cap regressions, plus the existing exact certificate acceptance
files. Its square-root tests use rational endpoint squares as the oracle;
the synthetic controller-selection fixture is explicitly distinguished from
the interval engine's mathematical proof tests.

The existing [NativeSpecialIngress.wlt](NativeSpecialIngress.wlt),
[ReviewNativeTailImport.wlt](ReviewNativeTailImport.wlt), and
[ReviewNativeTailExport.wlt](ReviewNativeTailExport.wlt) concern the current
analytic representation and its native import/export boundaries. Their saved
passing reports do not validate the new native result kind. A formal native
order must not silently become a proved analytic remainder or exactness claim.

## Equal exponents and composition scope

[CheckReviewNormalization.wl](../../validation/CheckReviewNormalization.wl)
records [276 passed, zero failed tests](../../validation/review-normalization-tests.json)
across fifteen selected files, with source hashes unchanged during the run.
The selection includes 23 [equal-exponent cases](ReviewExponentEquality.wlt)
and 20 [composition-scope cases](ReviewCompositionScope.wlt), plus ordinary and
inverse arithmetic, Fourier and logarithmic operations, assumptions, real
coefficients, and native-special ingress.

[CheckReviewScopeAndEquality.wl](../../validation/CheckReviewScopeAndEquality.wl)
selects just those two regression files for a narrower run. The
[equal-exponent notes](../../docs/development/EXPONENT_EQUALITY.md) explain
collection before truncation and remainder calculations. The
[composition-scope notes](../../docs/development/COMPOSITION_PARAMETER_SCOPE.md)
explain fixed parameters, retained source and operation provenance, exact
source replay, and refusals when a transported remainder lacks a uniform bound.
These focused runs do not replace the full package suite.

## Portable Mathics and Wolfram cases

The portable suite lives in [validation/MathicsTests.wl](../../validation/MathicsTests.wl),
separately from this directory's MUnit files. Its
[Python runner](../../validation/run_mathics_tests.py) selects named cases
or groups and starts one fresh interpreter process per case. First inspect
the available selection without starting a kernel:

```powershell
python validation/run_mathics_tests.py --list
```

After installing the environment described in the
[Mathics compatibility guide](../../docs/Mathics/COMPATIBILITY.md), a focused
run can use a case pattern and a fresh output destination:

```powershell
$portableOutput = Join-Path $env:TEMP ('asymptotic-portable-' + [guid]::NewGuid().ToString() + '.json')
python validation/run_mathics_tests.py --python .venv/mathics/Scripts/python.exe --case 'inverse-*' --timeout 300 --output $portableOutput
if ($LASTEXITCODE -ne 0) { throw 'Portable validation failed' }
```

Use `--wolfram wolfram.exe` in place of `--python ...` for the official
kernel, and `--source AsymptoticAnalysis.wl` to select the standalone instead
of the default modular source. `--case` and `--group` can be repeated. The
runner records source hashes, kernel identity, complete case output, and
process-enforced time limits; crashes and protocol failures cannot count as
passing cases. Selected inverse-callable tests explicitly distinguish the
two runtimes' pre-evaluation contracts. Portable acceptance is separate from
the focused MUnit records and from a full package-suite run.

## Full runner, generated campaigns, and benchmarks

[RunTests.wl](RunTests.wl) uses `FileNames["*.wlt", ...]` to run every test file
in this directory. It has no suite-selection argument. Do not use it as the focused command
for the present task. A deliberate full run uses:

```powershell
wolfram.exe -noinit -script src/Tests/RunTests.wl
```

Each discovered file is reported separately. The runner exits nonzero when
no `.wlt` file is discovered, the package fails to load, a file produces no
report object or executes no test, any test fails, or a requested export
cannot be written; an empty run is not a pass. Its optional
`ASYMPTOTIC_VALIDATION_OUTPUT` export records the kernel, discovered
filenames, executed-test count, rejected files, per-file summaries, and
per-test outcomes. Unlike the focused harness, it does not record source
hashes or impose a per-file time limit. The
[gate fixture check](../../validation/check_run_tests_gate.py) exercises these
exits with synthetic files in a temporary tree. Historical full-run
counts belong to the source and test set recorded at that milestone.

[RunGeneratedCampaign.wl](RunGeneratedCampaign.wl) is a separate deterministic
campaign with independent oracles and failure shrinking. Its command is
`wolfram.exe -noinit -script src/Tests/RunGeneratedCampaign.wl`.
The `ASYMPTOTIC_CAMPAIGN_` environment variables `SEED`, `CASES`, `CASE_SECONDS`,
`SHRINK_ATTEMPTS`, `SHRINK_SECONDS`, and `OUTPUT` control its bounds and output
directory. The current defaults are seed 236369, 24 cases, 30 seconds per
case, 24 shrink attempts, and a 60-second shrinking limit. This campaign is
separate from both selected regression files and full-suite acceptance.

[BenchmarkPerformance.wl](BenchmarkPerformance.wl),
[BenchmarkIncremental.wl](BenchmarkIncremental.wl), and
[BenchmarkRefinement.wl](BenchmarkRefinement.wl) are performance experiments,
not substitutes for regression checks. Report their fixture, kernel, source
snapshot, equality checks, and measured samples when making a performance
claim. The [validation record](../../validation/README.md) describes the saved
benchmark evidence and its limits.
