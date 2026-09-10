# AsymptoticAnalysis: incremental native-boundary audit

This archive reviews `VladimirReshetnikov/Asymptotic` at commit
`6687962f3c858a4f93623cfc496f33e35c6763d4` (package version 1.8.0).

Read `article/asymptotic_native_boundary_audit.pdf` or build its self-contained
LaTeX source. The article includes a capability comparison, prior-review
exclusion crosswalk, three reproduced interface defects, source-level causes,
a bounded repair candidate, a native-wrapper size measurement, and an
integration/acceptance plan. It does not repeat the earlier mathematical
findings as new discoveries.

## Evidence

The independent runtime was Wolfram Language 15.0.0 for Linux x86 (64-bit),
May 6, 2026. The pinned unmodified standalone passed 90 tests across four
existing native-interface files. Native optimizer message-text warnings were
emitted; the test report still returned zero failures.

The candidate corrected five focused probes (configured backend, configured
term goal, alias backend default, string assumption spelling, and an expansion
variable named `Method`). It also passed 68 existing tests in
`NativeAutomatic.wlt` and `NativeCompatibility.wlt`. A completed acceptance
report for the other two existing files has not yet been recorded here.
The complete supplied 25-case `NativeBoundaryRegressions.wlt` file was not
executed in this session. No full-suite or universal native-coverage claim is
made. `evidence/observations.json` separates all these observations.

Native and wrapper expression sizes were successfully measured at orders
100 and 1000 for `1/(1-x)`, with exact native-result and normalized-expression
agreement. These are `ByteCount` observations, **not peak-memory or runtime
measurements**. No speedup is claimed.

## Reproduce the baseline

Use a fresh Wolfram kernel. Only load code from a trusted, inspected source.
The loader downloads the pinned standalone as text and then loads the local
copy. To work offline, set `$AuditPackageFile` to an existing inspected
standalone before loading the helper.

```wolfram
Get["/path/to/archive/code/load_pinned.wl"];
Get["/path/to/archive/code/characterize_boundary.wl"]
Get["/path/to/archive/code/run_existing_native.wl"]
```

`characterize_boundary.wl` reports observations rather than a pass/fail claim.
The acceptance regressions below express repaired behavior, so several are
expected to fail on the unmodified baseline:

```wolfram
TestReport["/path/to/archive/code/NativeBoundaryRegressions.wlt"]
```

Set `$AuditRepository` to a local repository checkout before running
`run_existing_native.wl` to read its four test files offline. Otherwise the
helper fetches the pinned versions. Its returned association includes the
native `TestReportObject` as well as the success/failure counts.

## Inspect and apply the candidate

The patcher requires Python 3.10+ and a local Git checkout. It does not access
the network or modify a remote repository. Dry-run is the default.

```bash
python code/patch_native_boundary.py /path/to/Asymptotic
python code/patch_native_boundary.py /path/to/Asymptotic --apply
cd /path/to/Asymptotic
python validation/build_standalone.py
```

The patcher checks HEAD and all exact source anchors before writing. Its
`--allow-other-revision` flag relaxes the HEAD check only; anchor checks still
apply. Reconcile other revisions manually rather than assuming compatibility.
After applying it, load the regenerated local standalone in a **fresh** kernel
and run the focused regressions plus the four existing native test files.

The `native_boundary_patch.json` file is authoritative for the transformation.
`native_boundary_helpers.wl` is a readable excerpt, not a complete independently
loadable fix. The candidate was exercised through equivalent replacements in
the native module embedded in the pinned standalone; the exact local checkout
build and the complete acceptance matrix remain integration work.

An in-memory transformer is also included:

```wolfram
Get["/path/to/archive/code/apply_patch_in_memory.wl"];
original = Import["/path/to/original/AsymptoticAnalysis.wl", "Text"];
patched = AuditPatchedStandalone[original, $AuditPatchSpecification];
If[StringQ[patched], Export["/path/to/PatchedAsymptoticAnalysis.wl", patched, "Text"]]
```

This does not edit the repository. Load the exported candidate in a fresh
kernel; do not use it as a replacement for regenerating the canonical source
when integrating the fix.

## Transformation checks and profiling

```bash
python code/test_patch_transform.py
```

Six Python tests pass. They check fail-closed source transformations and
helper/specification consistency, not Wolfram semantics.

```wolfram
Get["/path/to/archive/code/benchmark_native.wl"]
```

The benchmark helper reports expression sizes and optional observed timings.
Record the kernel and whether caches were warm. It is not a peak-memory
profiler. The committed evidence contains only the successful size experiment,
not timing output from this helper.

## Rebuild the article

A normal TeX Live installation with `pdflatex`, `lmodern`, `microtype`,
`geometry`, `listings`, `booktabs`, `longtable`, `xurl`, and `hyperref` suffices.

```bash
bash build.sh
```

The article uses no external image or font files. No checksum files or LaTeX
auxiliary build files are included in the delivered archive. The original
repository has not been changed or pushed by this review.
