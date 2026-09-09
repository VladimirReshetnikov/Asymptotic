# Asymptotic 1.8.0 — technical review

**Reviewed repository:** VladimirReshetnikov/Asymptotic  
**Pinned commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Review date:** 9 September 2026

Start with **`article/asymptotic-review.pdf`**. Its editable LaTeX source is
`article/asymptotic-review.tex`; the bibliography is embedded in that source.
The report compares the package with Wolfram Language's documented built-ins,
analyzes the mathematical and implementation contracts, develops seven findings,
and proposes an implementation sequence and validation strategy. Appendix A
states the source-review coverage rather than claiming that every module and
proof in the repository received an equally deep review.

## Evidence and execution status

This was a source-level review, with independent executed mathematical checks.
The Wolfram connector could not connect, and no local Wolfram kernel or complete
executable checkout was available. **No native Wolfram test, benchmark, or patched
package execution is claimed.** Reproduction candidates are source-derived,
not captured kernel transcripts. Existing native validation counts quoted in
the article belong to the repository's own validation record.

The included independent run passed **262 mathematical checks**, including 250
deterministic randomized exact-polynomial cases. In 186 generated cases the old
nonlinear frontier rule understated the degree of the omitted logarithmic
polynomial; the proposed bound covered all 250. Six patch-helper unit tests
also passed. These checks do not execute the Wolfram package.

`results/native_status.json` explicitly records the unexecuted native work.
Native output files will be created only when the supplied runners are actually
run on your installation.

## Findings and supplied implementation scope

| ID | Finding | Supplied remedy |
|---|---|---|
| F01 | Nonlinear arithmetic can lose boundary logarithmic degree at an input precision ceiling. | Core precision-rule patch and four native regression candidates. |
| F02 | A fractional power of a pure remainder can bypass the real-branch check. | Conservative rejection unless exact zero; branch regressions. |
| F03 | Outbound `SeriesData` drops the explicit logarithmic remainder degree. | Refuse non-bound-preserving export; forward/inverse regressions. |
| F04 | Eager native export can allocate a huge dense rational-lattice vector. | Interim 100,000-entry cap; lazy-export design and bounded regression. |
| F05 | Derived refinement can return valid but insufficient precision. | Backward precision-demand design and a regression target; not patched. |
| F06 | Grouped/Newton methods can still pay the full multi-index enumeration cost. | Scheduling/frontier redesign and a regression target; not patched. |
| F07 | The flat parser rejects commensurate rates that do not divide the smallest rate. | Optional rational common-rate normalization patch and regression. |

The report distinguishes wrong error contracts, real-domain defects, resource
problems, insufficient refinement, and deliberately unsupported scope. It also
credits existing binary powering, Newton doubling, polynomial caches, Fourier
pruning, and exact certification rather than recommending them as missing.

## Contents

- `article/`: PDF, TeX, and the vector/raster figure used in the article.
- `code/verify_counterexamples.py`: exact symbolic checks, randomized finite
  polynomial tests, combinatorial cost calculations, and high-precision witnesses.
- `code/RegressionCandidates.wlt`: twelve native regression candidates describing
  corrected behavior. Baseline failures are expected; F05/F06 require further work.
- `code/RunNativeAudit.wl`: fresh-kernel native runner, source hashes, test report,
  nonempty-suite checks, output checks, and process exit status.
- `code/CompareBuiltins.wl`: sixteen native/package comparison fixtures, bounded
  evaluations, raw expressions, messages, source hashes, and timing samples.
  Matching integer orders do not imply matching asymptotic precision.
- `patches/apply_review_patches.py`: dry-run-first, pinned-blob-hash-guarded source
  patch applicator, backups, and optional F07 extension.
- `code/test_patch_tools.py`: six tests of patch replacement/hashing machinery.
- `results/`: actual independent results and explicit native execution status.
- `audit_manifest.json`: reviewed snapshot, coverage/evidence boundaries, and
  artifact validation details.
- `SHA256SUMS.txt`: checksums for the deliverable files other than the checksum
  file itself.

## Reproduce the independent checks

From this archive's root directory:

```powershell
python -m pip install -r code/requirements.txt
python code/verify_counterexamples.py
python -m unittest discover -s code -p test_patch_tools.py -v
```

The optional figure rebuild uses `python code/plot_witness.py` and requires
matplotlib in addition to the mathematical-check dependencies. The supplied
figure is already usable without running Python.

## Inspect or apply the proposed source patches

Use a local checkout of the pinned commit. The applicator is intentionally not
compatible with an arbitrary later revision. It verifies Git blob hashes of
canonical LF-normalized source text and refuses missing or duplicate anchors.
It does not fetch files, install anything, or edit the generated root package.

```powershell
$env:ASYMPTOTIC_REPO = 'C:\src\Asymptotic'

# Dry run: verify the expected files and print the proposed unified diff.
python patches/apply_review_patches.py $env:ASYMPTOTIC_REPO

# Include the optional F07 common-rate-lattice extension in the dry run.
python patches/apply_review_patches.py $env:ASYMPTOTIC_REPO --include-flat-lattice

# Only after inspecting the diff: write canonical sources with backups.
python patches/apply_review_patches.py $env:ASYMPTOTIC_REPO --include-flat-lattice --write

# Rebuild the generated standalone file using the repository's own builder.
Push-Location $env:ASYMPTOTIC_REPO
python validation/build_standalone.py
Pop-Location
```

The `.pre-audit.bak` backups are not overwritten. F01–F04 are patched; F07 is
optional; **F05 and F06 are not patched**. The branch rejection and fixed export
cap are conservative interim policies. Native validation is still required.

## Run native validation and comparisons

Keep the environment variable above set. Run each command in a fresh Wolfram
kernel; the runners reject a session where this package is already loaded.

```powershell
wolframscript -file code/RunNativeAudit.wl
wolframscript -file code/CompareBuiltins.wl
```

An alternative launcher is `wolfram.exe -noinit -script <script-path>`.
The native runner writes `results/native-audit-summary.json` and the detailed
MUnit report. The comparison runner writes `results/native-comparison.json`.
They record source hashes before and after execution; the recorded commit is
an explicitly labeled reference baseline, not a claim that locally modified
files are identical to it. Also run the repository's complete native suite.

Inspect returned expressions, branches, scales, and remainders before drawing
any speed comparison. An unresolved result is not a successful computation, and
an asymptotic term goal is not necessarily a polynomial degree.

## Rebuild the article

A standard TeX installation supplying pdfLaTeX, latexmk, New PX fonts, amsmath,
amsthm, tcolorbox, listings, geometry, microtype, xurl, and the other packages
named in the preamble is sufficient. No font files are bundled.

```powershell
Push-Location article
latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic-review.tex
Pop-Location
```

The included PDF was compiled and rendered for visual inspection. The source
is the primary editable article; the repository itself has not been changed.
