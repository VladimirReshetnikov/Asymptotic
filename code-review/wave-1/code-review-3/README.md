# AsymptoticInverse 1.8.0 — technical audit

**Audited commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Date:** 9 September 2026  
**Repository:** https://github.com/VladimirReshetnikov/Asymptotic

## Start here

`article/asymptotic-audit.pdf` is the complete article. Its standalone LaTeX source is `article/asymptotic-audit.tex`. The article separates reproduced defects, source-proved resource problems, documented restrictions, and proposed developments.

The immediate findings are:

- **F01:** nested fractional powers bypass the direct real-branch guard, including a conditional-realness check.
- **F02:** eager native `SeriesData` export requests an unbudgeted dense rational lattice, even for one sparse retained block.
- **F03:** native export loses a logarithmic remainder factor, so it is not a faithful analytical Big-O export.
- **F04:** ambient assumptions can be used but omitted from a reusable result's recorded hypotheses.
- **F05:** optimized inversion engines still inherit multi-index enumeration/frontier work, limiting their scalability.

The archive also discusses operation/scale compatibility, translated power-observable semantics, exact certificates, precision-preserving refinement, native special-function import, performance accounting, validation, and a development roadmap.

## What was actually executed

The pinned standalone was loaded successfully in **Wolfram Language 15.0.0 for Linux x86-64**. Its 573,940 bytes have SHA-256:

```
b2aebac8176649ff53634816f17e92c8f0ccb397f7606a5ac819b6f157b6d7ed
```

Selected baseline observations, native built-in comparisons, and four guard-logic spot checks completed. Their results are in `results/native_observations.json`. Some evaluator attempts returned HTTP 502; these did not produce evidence and are not reported as package failures.

**Neither the full upstream suite nor the complete supplied Wolfram regression file was executed.** The shipped patch has richer diagnostic text/data than the guard-logic spot-check variant. No full patched-suite pass is claimed.

The dense-allocation count is established from source plus exact arithmetic. A small unmodified native example showed that `SeriesData` subsequently trims the trailing zero entries. No billion-entry allocation was attempted on the baseline. The large-denominator native example was evaluated only after the allocation guard was inserted.

Independent Python checks and the Python artifact unit tests were executed; their results are included. They are not substitutes for native Wolfram tests.

## Contents

```
article/
  asymptotic-audit.tex            Complete, standalone LaTeX source
  asymptotic-audit.pdf            Compiled article
code/
  audit_regressions.wlt           Desired-contract native tests
  run_audit.wls                   Pinned loader / temporary patched runner
  comparison_probes.wl            Exact native/package comparison calls
  harden_patch.py                 Validated diff generator; optional apply
  patches.json                   Same exact patch anchors for the WL runner
  verify_math.py                  Independent exact calculations
  test_artifacts.py              Tests of the Python audit artifacts
results/
  native_observations.json        Transcribed successful native outputs and limits
  independent_checks.json        Actual independent-check output
  python-unit-tests.txt           Actual unit-test log
sources.json                     Pinned source map and official documentation
SHA256SUMS.txt                   Checksums of deliverable files
```

No upstream package distribution or font files are bundled.

## Build the PDF

A normal TeX Live or MiKTeX installation with pdfLaTeX and latexmk is sufficient:

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic-audit.tex
```

The document uses standard LaTeX packages and Latin Modern; it does not require downloaded proprietary fonts or external image files.

## Run the independent checks

From this archive's root:

```sh
python code/verify_math.py --output results/independent_checks.json
python -m unittest discover -s code -p 'test_*.py' -v
```

Python 3.9 or later is sufficient. No third-party Python packages are required.

## Run native regressions

Use fresh Wolfram kernels:

```sh
wolframscript -file code/run_audit.wls
wolframscript -file code/run_audit.wls --patched
```

The baseline command intentionally expects safer behavior than 1.8.0 currently supplies, so failures/nonzero exit status are expected for the reported defects. The patched command loads a temporary modified copy and does not modify an installed package or repository.

The runner downloads only the immutable pinned standalone URL and verifies its SHA-256 before evaluation. To use an already downloaded copy instead, set `ASYMPTOTIC_AUDIT_PACKAGE` to its path; it must have the same pinned hash. Example in PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_PACKAGE = 'C:\work\AsymptoticInverse.wl'
wolframscript -file code/run_audit.wls --patched
```

Reports are written to `results/regressions-baseline.json` or `results/regressions-patched.json`. The very large rational denominator case is included only in patched mode. Do not manually copy it into an unmodified-kernel test.

## Generate or apply the narrow source patch

On a local checkout of the audited revision:

```sh
python /path/to/audit/code/harden_patch.py /path/to/Asymptotic
```

This prints a unified diff without modifying anything. To apply:

```sh
python /path/to/audit/code/harden_patch.py /path/to/Asymptotic --apply
```

All expected anchors are checked before an edit. A non-overwriting, byte-preserving `.wl.pre-audit-hardening` backup is created. The updated canonical file is replaced atomically using a temporary file in the same directory. The script refuses an unknown source layout or a duplicate/missing anchor.

After applying, rebuild the generated standalone from the repository root:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

Then run affected and full native suites as appropriate before committing. The review does not modify GitHub and does not submit a pull request.

### Patch scope

This is a targeted hardening proposal, not a wholesale package replacement. The dense export cap is fixed at 100,000 slots rather than exposed as a new public option. Export remains eager, though bounded. Positive-degree logarithmic remainders decline native export rather than providing a more elaborate weakened-order conversion. The shared assumption splitter captures ambient assumptions, but all specialized independently exposed entry paths still deserve an audit. Those broader changes are described in the article rather than disguised as finished implementations.
