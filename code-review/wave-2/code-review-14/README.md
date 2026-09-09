# Asymptotic — incremental technical audit

**Pinned repository:** VladimirReshetnikov/Asymptotic  
**Commit:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6`  
**Version:** 1.8.0  
**Date:** 9 September 2026

Start with **article.pdf**; **article.tex** is the complete editable source.
The report compares the package with current official Wolfram documentation and
adds five specific findings beyond the repository's nine existing reviews and
87 consolidated numbered findings. The novelty crosswalk explains the closest
prior concerns and the new evidence rather than relabeling old findings.

## Findings

| ID | Contribution |
|---|---|
| N01 | An exact inner germ can capture a fixed outer parameter, invalidating the remainder and even the limiting finite part. |
| N02 | Intermediate dyadic interval rounding can prevent certification of a translated linear equation at every admitted precision, despite an exact root center. The module already handles affine domain predicates more carefully. |
| N03 | The ordinary numerical inverse checker can lose a small source displacement by working in a huge absolute source coordinate. |
| N04 | The Fourier constructor inherits SeriesTermGoal but does not read it, including malformed nondefault values. |
| N05 | Ordinary truncation drops already available quantitative Zeta/Lerch bounds, including when it removes no retained blocks. |

N01 is a correctness issue. N02 is an availability/precision defect, **not** an
unsound certificate. N03 is a numerical-conditioning issue; no exact native
failure tag is claimed. N04 is an API omission, and N05 is evidence loss rather
than a false finite approximation.

## What actually ran

- 25 independent Python mathematical-model tests passed, including 500 random
  directed-rounding cases, 500 affine translation cases, 16 parameter curves,
  42 Zeta tail cases, and 200 rational triangle-inequality cases.
- Five Python patch-emitter fixture tests passed.
- The PDF was compiled and its rendered pages inspected.
- The Wolfram files received a lexical delimiter/string/comment balance check.

**No native Wolfram package execution, native benchmark, patched native test,
or full upstream suite was completed.** The remote evaluator could not connect,
and no local kernel was available. The independent models are not a Wolfram
emulator and are not counted as package tests. Earlier reviews' native results
are not this audit's executions.

The source was inspected through pinned GitHub reads, not a complete local
checkout. The source manifest records substantive and selected-window reads.
The archive does not contain the upstream package distribution.

## Reproduce independent checks

Python 3.10+ and the standard library are sufficient:

```sh
python code/verify_independent.py
python code/test_patch_emitter.py
```

The actual successful logs and machine-readable results are in `evidence/`.

## Run native observations and prototype regressions

Use a fresh kernel and a local checkout of the pinned repository:

```powershell
$env:ASYMPTOTIC_REPO = 'C:\src\Asymptotic'
wolframscript -file code/run_native.wls
```

For a POSIX shell:

```sh
ASYMPTOTIC_REPO=/path/to/Asymptotic wolframscript -file code/run_native.wls
```

The runner records the actual local commit, kernel version, source hashes,
bounded baseline probes and ten prototype regressions. It does not download,
install or edit the repository. `evidence/native_observations.json` will be
created only when this native script is actually run; it is not pre-populated.
Inspect the raw results and any messages before relying on the prototypes.
This runner does not replace the upstream complete suite.

## Supplied implementation scope

`code/AuditExtensions.wl` contains nonmutating, native-unverified helpers:

- `ParameterSafeCompose`: a conservative direct-forward/explicit-scope guard,
  not a complete uniform-asymptotics implementation or a general scope analyzer.
- `BoundPreservingTruncate`: transports an existing explicit absolute bound by
  the triangle inequality, retaining its conditions. It does not infer a numeric
  constant from a Big-O scale or copy an unproved signed lower bound.
- `CheckedFourierInverse`: rejects unsupported non-Automatic term goals.
- `RationalAffineRange`: a restricted exact rational affine range evaluator,
  rejecting unsupported or nonlinear syntax.

N03 is addressed by a detailed redesign and probes, not a claimed complete
replacement for every numerical inverse-checking route.

## Emit the affine certificate patch

```sh
python patches/emit_affine_patch.py /path/to/Asymptotic > affine.diff
```

The emitter verifies the LF-normalized Git blob of the canonical certificate
module, validates unique source anchors, and prints a diff. It never writes to
the checkout. The emitted helper recognizes rational affine trees before
rounding; nonlinear and unsupported expressions use the existing fallback.

The emitter's transformation machinery was fixture-tested. Its complete pinned
source application and native patch behavior were **not** executed here. After
reviewing/applying a diff locally, rebuild the standalone with the repository's
own `validation/build_standalone.py` and perform native validation before use.

## Rebuild the article

A normal TeX distribution with pdfLaTeX, Latin Modern, amsmath, geometry,
booktabs, longtable, listings, microtype, xurl and hyperref is sufficient:

```sh
sh build.sh
```

On Windows, run `pdflatex -interaction=nonstopmode -halt-on-error article.tex`
three times from the archive directory. No separate font files are supplied.

`SHA256SUMS.txt` covers the final deliverable files except the checksum file
itself. The ZIP is an audit article and reproduction kit, not an upstream release
or a claim that all proposed Wolfram changes are production-ready.
