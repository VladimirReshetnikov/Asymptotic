# Asymptotic: Beyond the Existing Reviews

Independent incremental repository review prepared for Vladimir Reshetnikov,
9 September 2026. Pinned commit:

    921387e5ba1239bfda96e63e64e89bf63d9c41e6

Start with `article/article.pdf`. Its source is `article/article.tex`.
The report compares the repository with documented Wolfram Language facilities,
separates additional findings from sharper treatments of known issues, gives
mathematical proofs, and proposes two small special-function extensions.

## Evidence status

The independent Python program ran: **107 checks passed, zero failed**.
These are exact-rational arithmetic and polynomial checks, not native package
tests or an emulator. See `evidence/python_checks.json`.

The connected Wolfram evaluator returned HTTP 502 service errors. **No Wolfram
Language test or benchmark was executed. No upstream patch was applied.**
All WL code is native-unrun and experimental. The full repository test suite,
standalone generation, and release builds were not performed. No complete
upstream checkout is included in this archive.

The non-duplication baseline was the full maintained status register, plus the
specified original sections of reviews 2 and 8. This is not a claim to have
reread all nine historical articles word for word. `evidence/findings.csv`
records the relationship of each contribution to that baseline.

## Files

- `article/`: LaTeX article and compiled PDF, with inline bibliography.
- `code/reference_checks.py`: independent mathematics and arithmetic oracle.
- `code/stage_certificate_patch.py`: stages N01/N02 source fixes and a unified
  diff, refusing an unexpected Git blob or overwriting the original source.
- `code/ClosedBoundaryPatch.wl`: experimental private pUnitSeries replacement
  for S01; load only after the package, in a disposable kernel.
- `code/regressions.wlt`: nine desired-contract native tests. N04 is an explicitly
  proposed API policy test; no supplied patch resolves that policy.
- `code/native_probe.wl`: raw observation script for the original/staged package.
- `code/native_comparison.wl`: bounded built-in/package comparison experiments.
- `evidence/`: actual Python results, transformation-fixture results, finding
  ledger, source coverage, and artifact manifest.

## Independent checks

From the bundle root, in an environment with Python and SymPy:

```sh
python -m pip install -r requirements.txt
python code/reference_checks.py --output evidence/python_checks_rerun.json
```

Tested here with SymPy 1.14.0. A failed check raises an exception; the script does
not report a package test count. The finite Zeta partial-sum checks complement,
not replace, the infinite-tail proof in the article.

## Native observations

Obtain a disposable clone and check out the pinned commit yourself. Load the
modular canonical source, not an old generated standalone when testing a
modular change. Example (replace the absolute path):

```sh
wolframscript -file code/native_probe.wl \
  /absolute/path/to/Asymptotic/AsymptoticInverse/Kernel/AsymptoticInverse.wl
```

The script reports `$Version`. Keep stdout, stderr, the commit ID, and whether
patches were loaded together. Observations that fail to match a prediction
should be investigated rather than discarded.

In a fresh Wolfram kernel, a test session can use:

```wl
Get["/absolute/path/to/Asymptotic/AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
Clear[x, y, ell];
Get["/absolute/path/to/bundle/code/ClosedBoundaryPatch.wl"];
TestReport["/absolute/path/to/bundle/code/regressions.wlt"]
```

Some tests are expected to fail on the unmodified pinned source. N01/N02 require
the staged certificate changes; the opt-in boundary file addresses S01 only.
N04 requires a separately chosen and implemented selector policy. A nine-test
report is not a substitute for the repository's full suite.

## Staging the certificate patch

```sh
python code/stage_certificate_patch.py /absolute/path/to/Asymptotic \
  --output-dir /absolute/path/to/separate-staging-directory
```

The input file must match Git blob
`c447755ab58f02aa8a80fa374329e00d6ff9641e` after CRLF normalization. The script
writes the modified module and `certificate-fixes.diff` into the separate output
directory. Review the diff; apply only to a disposable worktree before testing.
It does not regenerate the standalone or claim compatibility with later commits.
Synthetic-anchor checks of the transformation are recorded separately from the
107 mathematical checks.

N01 changes the source-domain Refine call to explicit `Assumptions -> ...`.
N02 doubles enclosure order, within the existing ceiling, on a successful but
insufficiently accurate movable-center attempt. This simple progress policy is
not an optimized scheduler. It also does not repair metadata already produced
under hidden assumptions in older result objects.

## Built-in comparison

After loading the package in a clean kernel:

```wl
Get["/absolute/path/to/bundle/code/native_comparison.wl"]
```

The harness uses a 120-second per-case timeout. Timing alone is not a comparison
of equivalent results: match branch, cutoff meaning, coefficient blocks, and
remainder before drawing performance conclusions. No measured native result is
included in this bundle.

## Rebuild the article

A normal TeX Live installation with the packages listed in the preamble suffices.
No external bibliography processor or font download is needed:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The article's external references are pinned source links or official Wolfram
and NIST documentation. No complete upstream source distribution is bundled.
