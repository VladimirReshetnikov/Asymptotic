# Asymptotic repository audit

**Reviewed commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Review date:** 9 September 2026  
**Baseline:** AsymptoticInverse 1.8.0; repository requirement Wolfram Language 15.0+.

Read `article.pdf` or build `article.tex`. The report includes the feature comparison,
source-level findings, mathematical proofs/witnesses, performance analysis,
API proposals, review coverage, and a prioritized roadmap.

## Evidence status

The GitHub connector supplied the reviewed source. A native Wolfram evaluator was
attempted and unavailable. The complete repository could not be downloaded into
the container. **No Wolfram package test or benchmark was executed by this audit.**
The patch was not applied to a full local checkout or validated in a Wolfram kernel.

`evidence/independent-checks.json` and `evidence/python-tests.log` contain actual
executed Python/SymPy results. They verify independent mathematics and patch-tool
behavior, not package execution. Historical upstream counts and timings in the
article are labelled as repository-reported evidence.

The three proposed changes are:

- **A01:** enforce real fractional-power branch requirements for an unknown pure
  remainder in the shared `fwdPower` routine, including nested observables.
- **A02:** prevent eager native `SeriesData` conversion from allocating an enormous
  dense exponent lattice; retain the sparse result with an unavailable native view.
- **A03:** terminate a polynomial composition coefficient recurrence once its
  coefficient is identically zero.

A02's fixed 20,000-slot limit is a conservative stopgap. It does not implement the
full configurable/lazy-export architecture proposed in the report. Other findings
and unconfirmed probes have not been folded into this patch.

## Build the article

From this directory:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error article.tex
```

Standard TeX packages are used; no external figures or font files are needed.

## Reproduce the executed Python checks

Python 3.10+ is sufficient for the tooling; the recorded run used Python 3.13.5 and
SymPy 1.14.0. A fresh virtual environment is recommended.

```sh
python -m pip install -r code/requirements.txt
python code/independent_checks.py --output evidence/independent-checks.json
python -m unittest discover -s tests -p 'test_python_artifacts.py' -v
```

The planner computes the 100,150,056-slot witness **without allocating the array**.
The patch unit tests use small source-anchor fixtures; they do not claim complete
source-file integration. Source-hash verification is mandatory in the real patch
command below.

## Generate and review the patch

Obtain a disposable checkout of the exact reviewed revision:

```sh
git clone https://github.com/VladimirReshetnikov/Asymptotic.git
git -C Asymptotic checkout 07a9781212beb2eeb9ff16aa625b50ac27974078
```

Then, from this audit bundle, use absolute paths:

```sh
python code/patch_core.py --repository /absolute/path/to/Asymptotic \
  --output /absolute/path/to/new-audit-patch-directory
```

The output directory must not exist and must be outside the checkout. The generator
checks the canonical core's Git blob hash
`ea9eaf4a11130e922ac4fb3faae37fd8e8d29643` after LF normalization, and requires exact,
unambiguous edit anchors. It refuses a different source version instead of guessing.
It emits a diff, a proposed modified **modular core file**, and a patch manifest.
That modular file is not a new standalone package; it still needs companion modules.

Review the diff. In the disposable checkout:

```sh
git apply /absolute/path/to/new-audit-patch-directory/core-audit.patch
python validation/build_standalone.py
python validation/build_standalone.py --check
```

Run the audit tests, then the repository's complete native semantic suite using its
own validation instructions. Record all module hashes for modular loading; hashing
only the entry file is not enough to identify its companions. Do not release the
patch based only on this report or the audit subset.

## Run the native Wolfram regression specifications

These commands require an installed, usable native Wolfram kernel. They were **not
run** in the audit environment. `run_native.wl` exits its process; do not `Get` it in
an interactive notebook kernel that contains unsaved work.

POSIX shell (baseline audit subset):

```sh
export ASYMPTOTIC_AUDIT_PACKAGE=/absolute/path/to/Asymptotic/AsymptoticInverse.wl
wolframscript -file code/run_native.wl
```

PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_PACKAGE = 'C:\absolute\path\Asymptotic\AsymptoticInverse.wl'
wolframscript -file code/run_native.wl
```

The two nested A01 specifications are expected, from source tracing, to fail on the
reviewed unpatched revision. The other tests are controls. No actual native test
counts are prefilled in this bundle.

Only **after patching and rebuilding** enable the high-denominator tests:

```sh
export ASYMPTOTIC_AUDIT_PATCHED=1
wolframscript -file code/run_native.wl
```

PowerShell equivalent:

```powershell
$env:ASYMPTOTIC_AUDIT_PATCHED = '1'
wolframscript -file code/run_native.wl
```

The runner checks that the loaded file contains the A02 marker before adding
`tests/PatchedOnly.wlt`. Those tests also use `MemoryConstrained`. Do not run their
large allocations directly on the unpatched source. Results are written to
`evidence/native-tests.json` and `evidence/native-tests.wl` when the runner is used.
They are intentionally absent from the delivered bundle.

## Probes and benchmarks

`code/inspection_probes.wl` is intended for a fresh kernel after loading the package.
It reports unresolved scalar-domain consistency questions, an intentionally malformed
raw object, and bounded provenance-growth observations. It does not assert that
malformed objects are supported inputs or that every discrepancy is a public bug.

```sh
wolframscript -file code/benchmark_native.wl
```

The benchmark uses the same package environment variable. It writes diagnostic
native timings only when run. Match retained coefficients, branch, scale, error,
and output work before comparing times. It explicitly does **not** mark semantic
equivalence as verified. Later workloads in the same process are not fresh-process
cold measurements. The benchmark never invokes the enormous unpatched allocation.

## Files and integrity

`evidence/source-manifest.json` identifies the source snapshot and review scope.
`evidence/findings.json` distinguishes confirmed source findings, structural risks,
and unconfirmed proof obligations. `SHA256SUMS` covers all distributed files except
itself. The original third-party repository and its fonts are not redistributed.
The PDF naturally embeds the fonts needed to render the document.
