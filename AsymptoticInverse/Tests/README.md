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
| Native formal-order import and export within the analytic representation | [CheckReviewNativeTails.wl](../../validation/CheckReviewNativeTails.wl) |
| Complete real coefficients and adjacent constructors | [CheckReviewRealCoefficients.wl](../../validation/CheckReviewRealCoefficients.wl) |
| Assumption capture and retained proof contexts | [CheckReviewAssumptions.wl](../../validation/CheckReviewAssumptions.wl) |
| Nonlinear remainder degrees and coefficient termination | [CheckReviewUnitArithmetic.wl](../../validation/CheckReviewUnitArithmetic.wl) |
| Fractional-power branch handling | [CheckReviewPowerBranches.wl](../../validation/CheckReviewPowerBranches.wl) |
| Automatic arithmetic, composite bounds, and formatting | [CheckSeriesArithmetic.wl](../../validation/CheckSeriesArithmetic.wl) |
| Result-head, coordinate, Fourier, and inverse-check regressions | [CheckGeneralizedSeries.wl](../../validation/CheckGeneralizedSeries.wl) |

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

Compatibility checks for explicit `"Backend" -> "Series"` and
`"Backend" -> "Asymptotic"` delegation run through
[CheckNativeCompatibility.wl](../../validation/CheckNativeCompatibility.wl).
The implemented backends have a
[130 passed, zero failed record](../../validation/native-compatibility-tests.json)
across eight selected files on Wolfram 15.0.1 for Windows, with sources unchanged.
The selected files cover native result metadata, argument/order/option behavior,
operation guards, and adjacent existing behavior. The earlier focused
harnesses listed above do not establish acceptance of this native result kind.

The [native compatibility plan](../../docs/development/NATIVE_COMPATIBILITY.md)
describes the implementation and contract boundaries. Automatic fallback
remains required work: `Automatic` currently selects the package engines.
This focused acceptance is separate from historical analytic-import evidence
and does not establish the complete input-superset objective.

The existing [NativeSpecialIngress.wlt](NativeSpecialIngress.wlt),
[ReviewNativeTailImport.wlt](ReviewNativeTailImport.wlt), and
[ReviewNativeTailExport.wlt](ReviewNativeTailExport.wlt) concern the current
analytic representation and its native import/export boundaries. Their saved
passing reports do not validate the new native result kind. A formal native
order must not silently become a proved analytic remainder or exactness claim.

## Full runner, generated campaigns, and benchmarks

[RunTests.wl](RunTests.wl) uses `FileNames["*.wlt", ...]` to run every test file
in this directory. It has no suite-selection argument. Do not use it as the focused command
for the present task. A deliberate full run uses:

```powershell
wolfram.exe -noinit -script AsymptoticInverse/Tests/RunTests.wl
```

Its optional `ASYMPTOTIC_VALIDATION_OUTPUT` export records the kernel, selected
filenames, counts, and per-test outcomes. Unlike the focused harness, it does
not record source hashes or impose a per-file time limit. Historical full-run
counts belong to the source and test set recorded at that milestone.

[RunGeneratedCampaign.wl](RunGeneratedCampaign.wl) is a separate deterministic
campaign with independent oracles and failure shrinking. Its command is
`wolfram.exe -noinit -script AsymptoticInverse/Tests/RunGeneratedCampaign.wl`.
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
