# AsymptoticAnalysis: differential code audit

**Start with `article/audit.pdf`.** The full editable source is `article/audit.tex`.

Reviewed repository: VladimirReshetnikov/Asymptotic  
Pinned revision: `8e859961d7d37f008b826f3a8cad406460271614`  
Review date: 10 September 2026

## Findings

**F01 — incorrect sign-based modulus rewrite.** `fwdAbs` can preserve complex retained subleading coefficients merely because the leading coefficient is positive. In the exact family `Abs[1+a x]+Abs[1-a x]-2`, with `a^2==-1` and real positive `x`, the inspected rewrite sequence cancels to exact zero; the true expression is `2 Sqrt[1+x^2]-2`, with leading term `x^2`. The candidate patch requires real retained coefficients before the shortcut. It does not implement a general complex-modulus expansion.

**F02 — parameter-sensitive zeroth power.** An ordinary nonempty symbolic jet is accepted at exponent zero without proving nonvanishing over its retained parameter domain. The family `a x`, with only `a` real, includes an identically zero specialization. The candidate follows the package's current conservative exact-zero convention and requires a sufficient nonvanishing proof, without requiring a sign choice.

**F03 — ignored Gamma/Barnes cutoff.** The shared zeroth-power fast path validates an explicit cutoff but passes the literal value one into the constant constructor. The candidate forwards the request and distinguishes exact source information from a possibly truncated finite view. This is a projection/API defect, not an incorrect constant-function value.

## Evidence limits

The findings are **source-derived**, with exact independent mathematical countermodels. Public Wolfram outputs are **predicted, not observed**. The Wolfram service could not connect even for basic runtime probes. No Wolfram package test, WLT suite, candidate Wolfram patch, full upstream suite, or native benchmark was executed here. A local complete executable checkout was not obtained.

The independent Python authoring run passed **22 named checks**. They check exact Gaussian-rational algebra, binomial coefficients, finite logical/cutoff models, and narrow text transformations on **small synthetic fixtures**. They are not a Wolfram emulator, a repository test run, or proof that the candidate emitter was exercised on a real checkout.

The exclusion baseline was the maintained finding register, four-wave archive index and wave crosswalks, plus selected original records from reviews 2, 4, 22, and 25. The article distinguishes its exact deltas from nearby prior obligations. It does not claim to have reread all 36 full archived articles or proved absolute novelty by exhaustive search.

## Reproduce independent checks

Python 3.9 or newer, standard library only:

```sh
python code/independent_checks.py
```

This rewrites `evidence/independent_results.json` with the new run's result. The included JSON contains the actual authoring-run results and explicit native-execution flags.

## Inspect a candidate patch

Use a clean **scratch** Git checkout of the pinned revision. The emitter reads only the three canonical modular files, validates the revision and tracked-worktree cleanliness, requires unique exact edit anchors, and **never applies changes**:

```sh
python code/emit_candidate_patch.py /path/to/Asymptotic \
  --output /path/outside/checkout/asymptotic-delta.patch
```

The output file must be new and outside the checkout. Omit `--output` to print a unified diff. Missing/duplicate anchors, already-patched input, and unexpected source symlinks are refused. The tracked-worktree check ignores untracked files and is not a filesystem freeze. The tool performs no network requests.

Review the emitted diff before applying it to a disposable working copy. Regenerate the standalone distribution with the repository's existing builder:

```sh
cd /path/to/scratch/Asymptotic
python validation/build_standalone.py
```

Do not patch modular files and then accidentally test an unchanged generated root package. The emitter's real-checkout success route and the candidate's native runtime behavior remain unvalidated by this audit.

## Native characterization and regression candidates (unrun)

Target: a fresh Wolfram 15+ kernel.

```sh
wolframscript -file code/Characterize.wl /path/to/AsymptoticAnalysis.wl
wolframscript -file code/RunRegressions.wl /path/to/AsymptoticAnalysis.wl
```

`Characterize.wl` prints eight actual observations only when run; there are no purported native output transcripts in the archive. Run it on the baseline first.

`Regressions.wlt` contains **14 desired-contract tests** for the narrow patch: six F01, four F02, four F03. Several should fail on the unmodified baseline. The public F01 tests expect the candidate's precise refusal rather than an unimplemented modulus expansion.

The convenience regression driver requires a clean package load, a mandatory constructor smoke result, exactly fourteen result records, and the documented current `TestReportObject` properties `Results` and `ReportSucceeded`. It returns 0 for success, 1 for test failure, and 2 for setup/report incompatibility. **The driver itself has not been run in Wolfram.** It refuses unsupported report properties; it does not silently reinterpret them.

Manual native route:

```wl
Get["/absolute/path/to/AsymptoticAnalysis.wl"];
TestReport["/absolute/path/to/code/Regressions.wlt"]
```

Inspect every result and runtime message. The focused suite is not the full upstream release suite.

## Build the article

A standard TeX installation with pdfLaTeX, Latin Modern, amsmath, microtype, booktabs, longtable, tabularx, listings, fancyhdr, hyperref, and xurl:

```sh
sh article/build.sh
```

The included PDF was compiled and rendered for layout inspection. No font files are distributed.

## Contents and licensing

`article/` contains the PDF, TeX, and build script. `code/` contains the original audit utilities and Wolfram candidates. `evidence/` records findings, novelty boundaries, source inspection, actual independent results, and execution limitations.

Original audit code may be used, modified, and redistributed under the MIT No Attribution terms supplied in `UPSTREAM-LICENSE.txt`; upstream source excerpts retain the upstream license recorded there. The article is provided for the requested review and may be used and modified with the project.

No checksum files, repository mirror, native benchmark results, font files, or LaTeX build intermediates are included.
