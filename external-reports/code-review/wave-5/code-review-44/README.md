# Asymptotic — incremental repository audit

Reviewed repository: VladimirReshetnikov/Asymptotic  
Pinned commit: `8e859961d7d37f008b826f3a8cad406460271614`  
Date: 10 September 2026

Start with `article/asymptotic-review.pdf`. Its editable source is
`article/asymptotic-review.tex`.

## Findings and scope

The article develops four additional tooling findings: test-contract identity
in historical reconciliation, POSIX access-permission loss when publishing PDFs,
last-pass-only TeX recorder provenance, and lost shared-ledger updates between
independently launched builders. It separately treats build-environment
freshness as a policy improvement and a native trigonometric phase-error
question as unresolved at the public API boundary.

The source inspection also covered inversion, exact certificates, Fourier
coefficients, special-function identities and remainder bounds, native import,
and Mathics adaptations. No new public mathematical wrong-answer defect is
claimed. No Wolfram or Mathics package run was available.

Novelty screening used the repository's maintained four-wave indexes and
consolidated finding/intake registers. It was not an exhaustive rereading of
all 36 original reports. The article distinguishes each reported mechanism
from nearby already-recorded topics and does not restate the old backlog.

## Reproduce the focused tests

Python 3.11 or later:

```sh
python -m unittest discover -s tests -v
```

The recorded run passed all 22 methods. The POSIX-only methods skip on other
platforms. One test uses three actual `pdflatex` passes and skips if that tool
is absent. A run with skips is not the same evidence as the recorded run.
No network, repository access, Wolfram license, or Mathics installation is
required. All mutable test files are created in temporary directories.

These are extracted-function tests and independent fixtures, not a test run of
the complete repository. Tests whose names describe the upstream defect pass
when they reproduce that defect. Other methods exercise candidate guards.
The raw output and the evidence populations are in `evidence/`.

## Candidate code

`code/review_guards.py` contains tested building blocks, not an integrated
repository patch:

- `require_same_test_contract`: conservative suite/runner/package identity;
  upstream ingestion must first preserve the proposed runner field.
- `atomic_publish_posix_mode`: POSIX regular-file permission preservation;
  not Windows ACL, ownership, or arbitrary metadata preservation.
- `merge_pass_recorders`: three observations collected immediately after
  individual passes; cannot reconstruct lost earlier recorder data.
- `commit_receipt`: cooperative POSIX locking, fresh-read merge, and per-article
  compare-and-swap. Publication of the actual PDF must be integrated under the
  same policy; this function alone is not a PDF-plus-ledger transaction.

Integrate T01's schema change before enabling its strict guard. For T02, retain
all existing source/receipt/destination validation around the replacement. For
T03, move recorder capture into the actual pass loop. For T04, either enforce a
single writer for the vendor tree or integrate locked publication, including
failure paths and the actual PDF update. No candidate changes were pushed to
the repository.

## Build the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
```

The source uses standard LaTeX packages, including Latin Modern, microtype,
amsmath, listings, xurl, hyperref, and fancyhdr. No external images or fonts are
required in the archive.

## Files

The article and its source are in `article/`; candidate guards are in `code/`;
characterizations and regression methods are in `tests/`; the carefully scoped
transcribed source fragments are in `fixtures/`. `evidence/` contains the raw
focused-test output, evidence scope, and novelty crosswalk. There are no
checksum files or complete repository copies in this archive.
