# Asymptotic 1.8.0 — repository audit

Prepared for Vladimir Reshetnikov, 9 September 2026.

## Read first

The article is `article/asymptotic_repository_audit.pdf`; its complete, self-contained LaTeX source is beside it. The review is pinned to:

- Repository: https://github.com/VladimirReshetnikov/Asymptotic
- Commit: `07a9781212beb2eeb9ff16aa625b50ac27974078`
- Package: 1.8.0
- Reviewed standalone: 573,940 bytes
- Standalone SHA-256: `b2aebac8176649ff53634816f17e92c8f0ccb397f7606a5ac819b6f157b6d7ed`
- Native audit kernel: `15.0.0 for Linux x86 (64-bit) (May 6, 2026)`

The article distinguishes four native-reproduced findings from source deductions, upstream validation records, and proposals. It compares the package with native Wolfram functionality without claiming that unsuccessful individual native calls establish universal impossibility.

**The supplied patch candidate does not fix the ambient-assumption defect F01. Neither the full original nor the full patched upstream Wolfram suite was run in this audit.**

## Contents

`article/` contains the PDF and LaTeX article. `code/` contains bounded Wolfram probes, a source-hash-gated Python hardening generator, desired-contract tests, and Python component tests. `evidence/` contains the recorded native results, patch-check results, Python test log, findings index, and build/layout QA. `SHA256SUMS.txt` identifies the shipped files.

The upstream repository, full upstream tests, fonts, and generated build intermediates are not included. Source snippets in the patch generator are anchors from the reviewed upstream code; see `LICENSES/`.

## What was actually executed

The connected native Wolfram evaluator successfully reproduced lost ambient-assumption metadata, a wrapped fractional-power real-branch bypass, eager dense cache allocation from two sparse terms, and a generic loop returning 50 blocks under `"MaxTerms" -> 10`. It also returned the polynomial, irrational-inverse, and Erfc comparison results recorded in `evidence/native_verified.json`.

Equivalent local patches were applied inside a native evaluation, and **five focused native checks succeeded**: refusal of the wrapped uncertain square root, enforcement of the loop budget, bounded dense-cache conversion while preserving the sparse expression, unchanged polynomial inversion, and early termination of the annihilated coefficient recurrence. See `evidence/native_patch_verified.json`. The patched standalone hash from that evaluation is `a3c5a870e93890884576f149cc31438b9294035406c4d647627e70953466f24b`.

**Eighteen Python component tests passed.** Ten check independent exact arithmetic facts and eight check patch mechanics on explicit source-anchor fixtures. They do not execute Wolfram Language or validate the full source. The eight desired-contract MUnit tests in `code/regressions.wlt` were not run as a suite. The packaged command-line wrappers were not separately run through a local `wolframscript`; successful native evaluations used equivalent expressions through the connector.

Intermittent service errors also occurred. They are not counted as mathematical failures, package timeouts, or evidence against an algorithm.

## Run the Python checks

Python 3.10 or later, standard library only:

```sh
python -m unittest discover -s code -p test_audit.py -v
```

## Reproduce the native observations

Use a fresh Wolfram Language 15.0+ kernel. The scripts download the pinned standalone, verify its SHA-256, and execute it. Loading any package executes code; review the repository/source first.

```sh
wolframscript -file code/reproduce.wl
wolframscript -file code/comparison.wl
wolframscript -file code/native_patch_check.wl
```

A previously downloaded original can be supplied to the first two scripts:

```sh
wolframscript -file code/reproduce.wl /path/to/AsymptoticInverse.wl
wolframscript -file code/comparison.wl /path/to/AsymptoticInverse.wl
```

`reproduce.wl` prints observed results rather than treating known baseline bugs as a passing correctness suite. Expensive probes have time/memory limits. Dense-grid tests stop at one million positions; no billion-position allocation is attempted. Measurements on a different kernel/platform will vary.

`native_patch_check.wl` retrieves the pinned source and applies four local changes in a temporary copy, checks the five focused controls, prints outcomes and candidate hash, then deletes that temporary copy. It does not change the upstream repository or the downloaded original. It still does not repair F01.

To run the eight desired-contract tests on a locally loaded source, evaluate in a fresh kernel with the working directory set to the extracted archive:

```wolfram
Get["/absolute/path/to/AsymptoticInverse.wl"];
Clear[x, y, z, a];
TestReport["code/regressions.wlt"]
```

Some tests are expected to fail on unmodified 1.8.0. The assumption test is still expected to fail with the limited hardening candidate. Do not interpret that candidate as a complete repair.

## Generate a review-only candidate and diff

First obtain the exact reviewed standalone or canonical modular entry. The generator checks the standalone SHA-256 or the modular entry's Git blob ID and refuses other revisions. It never edits the input and refuses to overwrite its output files.

```sh
python code/harden_source.py /path/to/AsymptoticInverse.wl --out-dir audit_patch
```

The new directory contains `AsymptoticInverse.audit.wl`, `hardening.patch`, and `patch_manifest.json`. The optional `--dense-limit` changes the maximum optional dense coefficient-cache span; the default is 100,000. The manifest reports whether the candidate byte hash matches the focused native candidate. A modified limit or modular entry naturally yields another hash.

```sh
wolframscript -file code/reproduce.wl audit_patch/AsymptoticInverse.audit.wl --allow-modified
```

`--allow-modified` is an explicit source-hash override for a reviewed local candidate, not a recommendation to load arbitrary code. The generator's modular candidate needs companion kernel files and is not itself a standalone package. Review/apply the modular diff in a separate checkout, retain module neighbors, then regenerate the root standalone using the upstream builder. Do not treat a patched root distribution as the maintained canonical source.

The local changes implement a shared uncertain-power guard, a bounded optional `SeriesData` cache, generic unit-loop depth/support guards, and termination of a homogeneous coefficient recurrence after exact annihilation. Global assumption context, operation-wide budgets, all scale-specific contracts, and full-suite release validation remain separate work.

## Build the article

A standard TeX Live installation with `pdflatex`, Latin Modern, `microtype`, AMS packages, `booktabs`, `longtable`, `tabularx`, `listings`, `enumitem`, `xurl`, and `hyperref` is sufficient. No external images, bibliography database, shell escape, or font files are needed.

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_repository_audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_repository_audit.tex
```

The supplied PDF was compiled and visually inspected. Local rebuilds can have different PDF hashes because of timestamps or TeX versions; that does not imply source changes.
