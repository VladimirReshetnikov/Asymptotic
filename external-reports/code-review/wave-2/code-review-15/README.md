# Asymptotic — additional audit at 921387e

Read **article/article.pdf**. Its editable LaTeX master is **article/article.tex**;
all section sources and references are in the same directory.

**Repository:** VladimirReshetnikov/Asymptotic  
**Pinned snapshot:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6`  
**Audit date:** 9 September 2026  
**Declared package:** AsymptoticInverse 1.8.0, Wolfram Language 15.0+

## Additional findings

| ID | Finding | Consequence |
|---|---|---|
| F01 | Composite fallback substitutes an offset or affine scale for the actual target-chart endpoint/orientation. | Wrong target germ for flat pole targets, negative Erfc tails, and downward quadratic thresholds. |
| F02 | Successful automatic-center certificate attempts need not increase arithmetic precision even when accuracy is unmet; the retained root interval also proves a tighter error than the reported radius. | Avoidable accuracy stagnation and unused proof information. |
| F03 | Flat multiplication discards exponential grades before selecting the dominant omitted error, while computing coefficient products in discarded sectors. | A supported depth-N inverse square loses 2N+1 algebraic orders in its tail bound. |
| F04 | Gamma/Barnes noninteger power replay tests source sign instead of the sign of the already represented observable. | Positive even-power observables on a negative source branch are conservatively rejected. |

The anti-duplication baseline was the repository's consolidated review-status
register, review index, and the detailed summaries accompanying reviews 6–9.
Not every page of all nine prior articles was read. The article's novelty ledger
explains the concrete additions to related existing topics. Already-fixed dense
native-series allocation and shared uncertain-power guards are not re-reported.

## Evidence boundary

**Executed:** 20 independent Python model tests passed. These include exact target
geometry, rational outward interval arithmetic, root containment, flat coefficients,
and graded tails. One test contains 500 deterministic randomized rounding cases.
`evidence/python_tests.txt` is the actual test log. `independent_results.json`
contains the full model results.

**Not executed:** the upstream Wolfram package, its native suite, the supplied
Wolfram helper package, native regressions, and native comparison probes.
The available Wolfram service repeatedly returned HTTP 502, including for a
version-only request. No native execution result or performance benchmark is
claimed. The proposed Wolfram code has only a basic text-delimiter sanity check,
not a native parse/compile test.

Source inspection used pinned GitHub reads; no complete local checkout was
obtained. Seventeen implementation modules were inspected directly, some in
selected windows. The manifest records coverage and available blob identifiers.

F02 and F03 are not claims of false root certificates or understated error bounds:
they concern accuracy control and unnecessarily weak bounds. F04 is a conservative
feature restriction, not an existing wrong-result bug.

## Archive layout

- `article/`: master TeX, six section files, references, PDF.
- `code/audit_models.py`: restricted independent mathematical models.
- `code/generate_evidence.py`: regenerates model results.
- `code/Characterize.wls`: nine bounded native characterization probes.
- `code/CompareBuiltins.wls`: twelve paired native/package calls, not a benchmark.
- `code/RunNativeTests.wls`, `code/NativeCommon.wl`: native runner support.
- `code/check_wolfram_delimiters.py`: basic comment/string/bracket sanity checker.
- `tests/test_models.py`: the 20 executed model tests.
- `tests/DesiredContracts.wlt`: eight desired upstream contracts, expected to
  include baseline failures and the future F04 capability.
- `tests/ProposalContracts.wlt`: seven focused helper tests, unexecuted natively.
- `proposals/AuditSupport.wl`: namespaced, revision-specific proposed helpers.
- `evidence/`: source/novelty ledgers, model results, execution status, PDF QA.
- `LICENSE-AUDIT.txt`: MIT No Attribution terms for original audit materials.
- `SHA256SUMS.txt`: checksums of the delivered files, excluding itself.

No full upstream package, native Wolfram engine, or font files are distributed.
No remote repository was changed.

## Run independent checks

Python 3.10+; standard library only. The recorded run used Python 3.13.5.
From this archive's root:

```sh
python -m unittest discover -s tests -p 'test_models.py' -v
python code/generate_evidence.py
python code/check_wolfram_delimiters.py
```

The second and third commands overwrite their generated evidence files. Preserve
the delivered evidence first when run provenance matters. These tools do not
execute Wolfram Language. The certificate model is specifically for x² = 2,
not a general implementation of the package's certificate evaluator.

## Native characterization

Use a fresh compatible Wolfram kernel and a reviewed local checkout at the pinned
commit. Supply either its standalone file or its modular kernel entry. The scripts
do not download source or execute remote code automatically.

POSIX shell:

```sh
export ASYMPTOTIC_AUDIT_PACKAGE=/absolute/path/AsymptoticInverse.wl
wolframscript -file code/Characterize.wls
wolframscript -file code/CompareBuiltins.wls
```

PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_PACKAGE = (Resolve-Path 'C:\path\AsymptoticInverse.wl').Path
wolframscript -file code/Characterize.wls
wolframscript -file code/CompareBuiltins.wls
```

The scripts write new JSON evidence files and refuse to overwrite existing native
results. They record the actual kernel version, platform, and entry-file SHA-256.
The expected commit field is not proof of the identity of an arbitrary supplied
file; for a modular entry, its hash does not cover companion modules. Use a pinned
complete checkout for reproducibility.

Each ordinary probe has a 45-second time limit and a 512 MiB additional-allocation
limit. Package loading has separate 90-second/1 GiB limits. Audit limit outcomes
are recorded separately from package `Failure` values. Native comparison calls
are not necessarily equivalent in order, retained terms, branch, or achieved
remainder; normalize these before comparing timings.

## Proposed helpers

Load `proposals/AuditSupport.wl` after loading the upstream package. It adds no
upstream overrides. Its exported names are in `AsymptoticAudit\``:

`ExpectedTargetApproach[s]` derives geometry for the three reviewed chart families.
`AttachExpectedApproach[s]` returns a new object containing that explicit approach.
This is not a global producer patch or complete saved-object migration.

`TightenCertificate[c]` uses an already certified root enclosure to improve the
reported center-error bounds. It does not construct a new certificate, repair the
refinement controller, or certify an unspecified input remainder.

`FlatSeriesMultiplyGraded[s,t]` is a proposed alternative flat product. It preserves
exponential grades during tail dominance and avoids exact coefficient products
above the retained diagonal. It reuses private upstream helpers, is specific to
the audited revision, and needs native testing. Its envelope-only treatment can
forgo cancellations that a full discarded polynomial convolution would discover;
this tradeoff is explained in the article. Its custom operation recipe has no new
replay/refinement implementation in this archive.

No reflected Gamma/Barnes adapter for F04 is implemented in this archive.

## Run native tests

```sh
export ASYMPTOTIC_AUDIT_SUITE=Proposal
wolframscript -file code/RunNativeTests.wls
export ASYMPTOTIC_AUDIT_SUITE=Desired
wolframscript -file code/RunNativeTests.wls
```

In PowerShell set `$env:ASYMPTOTIC_AUDIT_SUITE = 'Proposal'` or `'Desired'`.
The default is Proposal. Exit 0 means a completed successful nonempty suite;
1 means test failures; 2 means loading/runner/noncompletion/empty-suite failure.
The entire suite has a 600-second time limit and 1 GiB allocation limit.
The desired-contract suite is not expected to pass unchanged upstream, and the
limited helper package does not implement all desired upstream changes.

The wrappers, MUnit suites, and helpers have not been accepted by a native parser
in this audit. A successful text-delimiter check is not equivalent validation.

## Build the article

With a LaTeX distribution providing the packages named in `article/article.tex`:

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error article.tex
```

A bibliography processor is not required: `references.tex` is included directly.
The PDF was compiled and rendered for visual checking. PDF binary hashes may
change on a rebuild because of timestamps or TeX versions.
