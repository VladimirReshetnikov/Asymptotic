# Incremental AsymptoticAnalysis audit: logarithmic certificate precision

Repository snapshot: `efa1aeec4845a9c35e140963a0333d0c9ec33b05` (September 10, 2026).
Read **article/report.pdf** or its complete source **article/report.tex**.

The report retains two newly identified, independently repairable losses of
relative accuracy in the shared exact-rational certificate kernel. They cause
avoidable refusals, not false certificates. A native comparison ran three public
witnesses through four full standalone source variants. The combined candidate
certified all three and contained the known exact root in every success.

## Evidence boundary

Native observations used Wolfram **15.0.0 Linux** through a remote evaluator.
Mathics3 was not executed. No complete upstream suite, modular build, generated
standalone parity check, or performance benchmark was run. Read
`evidence/scope.json`, `evidence/native-observations.json`, and
`evidence/native-matrix.json` before interpreting counts. The packaged WL/WLT
files are reproduction specifications; their equivalent core cases were probed,
but these files were not run as complete scripts or a complete MUnit suite.

## Contents

- `article/report.tex`, `article/report.pdf`: the article and self-contained LaTeX source.
- `code/reference_log.py`, `code/test_reference.py`: independently executable
  exact-rational models and 24 test methods; no Wolfram or Mathics dependency.
- `code/emit_candidate.py`: guarded, non-overwriting patch emitter. It accepts
  either the canonical certificate module or the standalone source.
- `code/PortableLogCases.wl`: three public witnesses plus primitive observations.
- `code/ReviewLogPrecision.wlt`: eight desired-contract native regressions.
- `code/LogRatioPrototype.wl`: optional, nonintegrated centered-residual extension.
- `evidence/`: selected native observations, exact work models, test output,
  scope, and novelty crosswalk. None is a checksum manifest.

## Run the independent checks

From `code/`, using Python 3.10 or later:

```sh
python -m pip install -r requirements.txt
python -m unittest -v test_reference
```

The model code uses exact `fractions.Fraction` arithmetic. mpmath supplies a
separate high-precision numerical oracle for containment controls; it is not used
to construct rational enclosures.

## Emit candidate copies

Keep the original source unchanged. For example:

```sh
python code/emit_candidate.py /path/to/repo/AsymptoticAnalysis.wl /tmp/AsymptoticAnalysis.audit.wl
```

`--mode reciprocal` applies F01 only; `--mode affine` applies F02 only; the default
`--mode both` applies both. The emitter refuses missing/duplicate anchors,
repeat application, an existing output, or in-place replacement. Its local tests
use synthetic fixtures. The same two edits were separately applied to the actual
pinned standalone text and executed in the native observations.

For integration, emit and review a candidate for
`src/Kernel/InverseCertificates.wl`, then regenerate the standalone through the
repository's documented build process in a staging checkout. No integration or
upstream modification has been made by this audit.

## Reproduce in a Wolfram or Mathics session

Use two separate input expressions and explicit paths:

```wl
Get["/tmp/AsymptoticAnalysis.audit.wl"];
Get["/path/to/this/audit/code/PortableLogCases.wl"];
```

The probe explicitly raises the iteration limit in a Mathics session, following
the repository's usage guidance. This is a supplied execution recipe, not a claim
of Mathics acceptance. Baseline: A, B, C refuse. Reciprocal-only: A succeeds.
Affine-only: B succeeds. Combined: A, B, C succeed. These expected outcomes are
natively observed in Wolfram, not observed in Mathics.

For native MUnit, load the candidate, then evaluate:

```wl
TestReport["/path/to/this/audit/code/ReviewLogPrecision.wlt"]
```

## Rebuild the article

From `article/`, run `pdflatex -interaction=nonstopmode -halt-on-error report.tex`
twice. The source uses standard TeX Live packages and has no external images,
fonts, bibliography files, shell-escape commands, or online build dependencies.
