# Asymptotic: technical audit and development roadmap

## Start here

Read `article/asymptotic-audit.pdf`. Editable LaTeX is in the same directory.
The report examines correctness, mathematical contracts, performance, API/UX,
testing, packaging, documentation, and future development. It compares the
repository with current official Wolfram Language documentation.

**Audited source:** VladimirReshetnikov/Asymptotic at
`75de8756175911cd8830704fd1a3406c1022f018` (September 9, 2026).
The declared package is AsymptoticInverse 1.8.0, requiring Wolfram Language 15.0+.
All source references are pinned. Later revisions may differ.

## Evidence and limitations

The source was inspected through repository tools. There was no complete local
clone in the audit runtime. Fifteen independent Python/SymPy/mpmath mathematical
checks and five patch text-transformation tests passed. Their logs are included.

No successful execution of the repository's Wolfram package or its test suite
was obtained. One native version probe succeeded, but package download/load and
follow-up probes returned connection errors. That probe is not a package test.
Read `evidence/native-execution-status.txt` and the article's evidence labels.

The Wolfram files below are supplied for native execution; they have NOT been
validated as a successful native run in this audit. Several regression tests
intentionally specify behavior that is expected to fail on the baseline.
The Python tests are not a substitute for package execution or a full native suite.

## Contents

- `article/`: master `.tex`, five section sources, conventional references, PDF.
- `code/independent_checks.py`: 15 executed mathematical/reference checks.
- `code/emit_patch_proposals.py`: guarded proposal emitter; input checkout unchanged.
- `code/test_patch_proposals.py`: five executed excerpt-transformation tests.
- `code/AuditRegressions.wlt`: nine proposed regressions and controls.
- `code/RunAudit.wls`: loads a local checkout and runs the proposed native tests.
- `code/ProbeNativeTail.wls`: records native elliptic series, old private importer,
  and public constructor separately; public failure is not presumed.
- `code/CompareBuiltins.wls`: 12 bounded paired native/package calls. Order arguments
  are not automatically equivalent; inspect branches, coefficients, and remainders
  before comparing timing. The harness is not a completed benchmark.
- `results/`: actual independent test outputs and PDF build log.
- `evidence/`: findings ledger, source URLs, coverage, snapshot, and execution status.

The original repository, Wolfram Engine, and font files are not included.

## Re-run independent checks

Recorded environment: Python 3.13.5, SymPy 1.14.0, mpmath 1.3.0.
The scripts use normal Python 3.10+ syntax. Install the declared Python dependencies
with your usual environment/package workflow; exact recorded versions are listed
in `requirements.txt`.

From this archive's root:

```sh
python code/independent_checks.py
python -m unittest discover -s code -p test_patch_proposals.py -v
```

`independent_checks.py` writes its result files under this archive's `results/`
directory. Preserve the original run files before rerunning when provenance matters.

## Generate review patches without changing the repository

Use a local checkout of the pinned revision. Choose a NEW output directory outside
that checkout. The emitter checks the LF-normalized Git blob identities of the
canonical main module and FlatSectors module before writing anything.

```sh
python code/emit_patch_proposals.py /path/to/Asymptotic /path/to/new-proposals
```

Default proposals:

1. Avoid native `SeriesData` trailing-zero padding and cap genuinely wide dense views.
2. Put the uncertain-real-radical guard in the shared `fwdPower` primitive.
3. Normalize rationally commensurate flat rates by a fundamental rate, with a degree cap.

The optional narrow native-tail mitigation is:

```sh
python code/emit_patch_proposals.py /path/to/Asymptotic /path/to/new-proposals \
  --conservative-native-tails
```

This changes only the identified empty-candidate case in the old native importer.
It does not certify arbitrary native series tails, fix the real-coefficient policy
(F04), or implement a complete shared native importer. `--dense-cap` changes the
100000-slot default for optional native views.

The emitter creates changed source copies, `proposals.patch`, and a patch manifest.
It never applies the patch. Its excerpt transformations were tested, but no complete
checkout was available to test the emitter end to end, and no generated Wolfram
patch was executed here. Source drift or a missing anchor fails closed.

Review and apply proposals only on a separate development branch. Run the proposed
regressions and the repository's full native suite, then regenerate the root standalone
file from canonical modules. The project documents these packaging checks:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

Those packaging checks are not a mathematical release gate by themselves.

## Run the native probes and proposed regressions

On a machine with a compatible Wolfram kernel, set the checkout root:

```sh
export ASYMPTOTIC_AUDIT_ROOT=/path/to/Asymptotic
wolframscript -file code/RunAudit.wls
wolframscript -file code/CompareBuiltins.wls
```

In PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_ROOT = "C:\path\to\Asymptotic"
wolframscript -file code/RunAudit.wls
wolframscript -file code/CompareBuiltins.wls
```

These scripts write `audit-native-report.wl`, `native-tail-probe.wl`, or
`builtin-comparison-results.wl` into the CURRENT working directory. Run in a dedicated
results directory or preserve prior files before repeating. RunAudit uses the documented
`TestReportObject["ReportSucceeded"]` property for its exit status.

The suite mixes controls and desired-behavior tests; failures on the original baseline
are expected. F04 remains a requested change after applying the default patches.
The short-coefficient-list F01 test is NOT proof of bounded temporary allocation:
native SeriesData canonicalization may already trim the returned list on the baseline.
The wide-interior-gap test is the important refusal case.

Before comparing performance, run isolated kernels, repeat samples, capture hardware
and source hashes, and normalize the actual requested error targets. Do not infer a
built-in failure from the absence of native results in this audit.

## Build the article

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic-audit.tex
```

All section files must remain beside the master. No external bibliography processor
is required. The generated PDF was rendered and visually reviewed in the audit.

## Licensing

Original audit code is supplied under MIT-0; see `LICENSE-AUDIT-CODE.txt`.
Upstream source excerpts retain their upstream terms, included in
`evidence/upstream-LICENSE.txt`. The article flags a discrepancy between that no-attribution
text and the repository's MIT identifiers; no upstream license has been changed.
