# AsymptoticAnalysis — defining-sum integration audit

Prepared for Vladimir Reshetnikov, 10 September 2026.

Reviewed repository: `VladimirReshetnikov/Asymptotic`

Pinned commit: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`

## Read first

`article/review.pdf` is the rendered article; `article/review.tex` is its self-contained LaTeX source. It identifies two incremental findings after comparison with the retained review indexes, status register, and targeted article-text scans:

- **N01:** The Package constructor accepts bare Zeta and Lerch atoms but refuses their simple affine translations. Separate public arithmetic calls demonstrate an existing workaround.
- **N02:** An explicit cutoff disables `SeriesTermGoal` in the two defining-sum constructors. Zeta additionally rejects a cheap one-term request because its cutoff-only preflight considers unnecessary work.

The article distinguishes these coverage/request-contract defects from mathematically false asymptotic formulas. It also develops a separate integer-indexed Dirichlet algebra prototype, including proofs for coefficient-majorant transport and reciprocals.

## What was executed

Selected baseline calls and five focused controls for the three-edit N02 candidate executed in **Wolfram Language 15.0.0 for Linux x86 (64-bit), May 6, 2026**. The candidate experiment modified a temporary imported standalone; a rebuilt canonical distribution was not tested.

All **32 independent Python test methods passed**: 28 arithmetic/majorant methods and four synthetic patch-anchor fixture methods. Prototype convolution timings are Python timings only, not measurements of the Wolfram package or Mathics.

**No Mathics runtime was available.** The Mathics assessment is source-based. The complete packaged `RunProbes.wl` and the full `AffineDirichletExpansion.wl` helper were not successfully executed here. The helper's underlying public arithmetic controls succeeded separately. No full upstream test suite was run.

`evidence/native-observations.json` is an explicitly labelled manual transcription of selected connector responses, not an unedited native log or a release-acceptance receipt. Other evidence files retain their individual populations and limitations.

## Independent Python checks

Python 3.9 or later; only standard-library modules are used. Tests were actually run with Python 3.13.5.

From this directory:

```console
python -m unittest discover -s tests -v
python code/benchmark_dirichlet.py
```

The benchmark prints JSON to standard output and does not overwrite the retained observations. Tests cover divisor-count and Möbius oracles, exact random convolution/reciprocal identities, unknown-prefix handling, input validation, growth majorants, immutability, budgets, and synthetic patch anchors.

`code/dirichlet_jet.py` is an independent reference implementation, not an installed extension of `GeneralizedSeries`. Its general constructor **declares** an infinite coefficient bound and checks only the known prefix; it cannot infer an infinite theorem from finite data. The Zeta and finite-polynomial factories establish their bounds by construction. The article proves the transport rules used by arithmetic.

## Stage the N02 candidate

Use a local checkout at the reviewed revision and an output directory that does not already contain staged artifacts:

```console
python code/patch_dirichlet_goals.py /path/to/Asymptotic /path/to/stage
```

The utility checks all three exact anchors before writing. It stages:

```text
stage/src/Kernel/DirichletSpecialFunctions.wl
stage/dirichlet-goals.patch
```

It does not edit the input module in place, download anything, or silently overwrite existing staged files. Anchor matching is a drift guard, not a whole-repository version verification. Apply the change in a disposable checkout, use the upstream standalone builder, and test the rebuilt result separately. The successful native candidate observations do not establish that integration step.

## Local Wolfram / Mathics probe driver

In a fresh kernel, set local paths and load the driver:

```wl
AuditPackagePath = "/path/to/Asymptotic/AsymptoticAnalysis.wl";
AuditOutputPath = "/path/to/baseline-observations.wl";
Get["/path/to/asymptotic-review/code/RunProbes.wl"];
```

On Windows, forward slashes may be used in absolute paths, for example `C:/src/Asymptotic/AsymptoticAnalysis.wl`.

`AuditOutputPath` is optional; when supplied, its parent directory must exist. Use a different path for each run because `Export` can overwrite that observation file. The driver does not modify the repository or download source. It prints plain records and applies a per-probe time limit; it is not a pass/fail acceptance gate. Run the baseline and candidate in separate fresh processes. The complete driver remains unverified on both hosts in this review, even though separately issued native calls produced the included observations.

## Affine-lifting prototype

Load the upstream package first, then `code/AffineDirichletExpansion.wl`. The added symbol is `AsymptoticAudit\`AffineDirichletExpansion`.

```wl
AsymptoticAudit`AffineDirichletExpansion[
  Zeta[x] - 1, {x, Infinity, Log[3]}]
```

This helper admits exactly one varying Zeta/Lerch atom with rational constant affine coefficients and an explicit cutoff in that atom's coordinate. It deliberately does not expose `SeriesTermGoal`; constant cancellation requires a separate final-block counting policy. It uses existing package arithmetic, changes no upstream definitions, and carries an asymptotic remainder rather than promising preservation of the atom's quantitative bound metadata. It is an implementation sketch whose complete execution still needs validation.

## Rebuild the article

A LaTeX installation with `pdflatex`, NewTX fonts, `amsmath`, `amsthm`, `mathtools`, `geometry`, `microtype`, `booktabs`, `longtable`, `tabularx`, `xcolor`, `listings`, `enumitem`, `fancyhdr`, `xurl`, `tcolorbox`, `titlesec`, and `hyperref` is sufficient. No separate bibliography tool is required.

```console
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
```

The distributed PDF was rendered and visually checked. Font files, generated LaTeX auxiliary files, Python bytecode, and checksum files are not included.
