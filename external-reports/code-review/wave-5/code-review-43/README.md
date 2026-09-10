# Asymptotic — focused source-review deltas

Review date: 10 September 2026.
Repository: VladimirReshetnikov/Asymptotic.
Pinned commit: `8e859961d7d37f008b826f3a8cad406460271614`.

Read `article/article.pdf`; the complete editable source is `article/article.tex`.
The report covers three narrowly scoped API/validation findings and one
polynomial branch-proof extension. It does not claim a newly reproduced
wrong expansion on valid mathematical input.

## Findings

| ID | Scope | Evidence |
|---|---|---|
| F01 | Inverse coefficient reconstruction lacks explicit source orientation | Source mechanism and independent exact coordinate models; new package probes unexecuted |
| F02 | A public model's `Limit` may be its normalization offset | Source mechanism and exact leading-term analysis; new package probes unexecuted |
| F03 | A core inverse can retain the eliminated source symbol | Both native/Mathics definitions inspected; independent formula model; proposed structural guard |
| E01 | Strict global polynomial monotonicity with isolated stationary points | Exact proof, implemented certificate producer/checker, independent tests; not installed in Asymptotic |

The novelty ledger distinguishes these claims from nearby existing register
items. Deduplication used the maintained 36-report index, consolidated
crosswalks and proposal groups, and targeted original ledgers; it was not a
word-for-word comparison of every earlier PDF.

## Actual execution status

One commit-pinned package smoke succeeded in Wolfram Language 15.0.0.
Subsequent execution-service calls failed, so none of the new integration
probes was executed. The native-smoke evidence is a manual transcription
of the returned tool values, not a machine-verified package acceptance receipt.

The independent Python suite ran **35 tests, all passing**, on Python 3.13.5
with SymPy 1.14.0. These are models and companion-prototype tests, not the
repository's Wolfram or Mathics tests. Historical repository receipts are not
combined with this count.

## Run the independent code

From this directory:

```text
python -m pip install -r code/requirements.txt
python code/test_review.py
python code/polynomial_certificate.py verify evidence/quintic-monotonicity-certificate.json
```

The verifier itself uses only the Python standard library. SymPy is needed by
the optional producer and by the independent symbolic models. Certificate
inputs are exact rational coefficient lists in ascending powers; expression
strings are never evaluated as code. The prototype admits degree at most 64
and is not a process-level resource sandbox.

The quintic certificate proves strict increase on the whole real line even
though its derivative has two real zeros. It asserts neither a positive
uniform derivative lower bound nor an inverse-error bound.

## Native companion and patch preparation

`code/ReviewDeltas.wl` defines additive helpers in the `AsymptoticReview` context and does
not override the package. Its ordinary-inverse helper deliberately excludes
native, Gamma/Barnes, composite, and depth-truncated objects.

In a fresh Wolfram kernel, supply a local checkout of the pinned package:

```text
wolframscript -file code/native_probes.wl /absolute/path/AsymptoticAnalysis.wl
```

The runner records observations, not a predetermined acceptance total. It
records the expected commit but cannot verify provenance from a path alone.

To emit the F03 candidate patch without modifying your checkout:

```text
python code/prepare_validation_patch.py /absolute/path/to/Asymptotic > validation.patch
```

The generator checks exact old fragments in both canonical definitions before
emitting a diff. After accepting the change, use the repository's existing
standalone builder. The guard adopts the current structural `FreeQ` policy;
a broader contract admitting unevaluated binders requires scope-aware analysis.

## Rebuild the article

A TeX Live installation with `newpx`, `microtype`, `listings`, `xurl`, and the
usual AMS/table packages is sufficient. From `article`, run:

```text
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

`evidence/findings.json` and `evidence/novelty-ledger.csv` contain the
claim-specific classification and non-overlap rationale. The independent test
transcript, execution summaries, exact quintic certificate, and PDF build
record are kept in the same directory.
