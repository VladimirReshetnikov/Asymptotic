# Fixed charts, exact cores, and rational moments

Differential review of VladimirReshetnikov/Asymptotic, 10 September 2026.
Pinned repository commit: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`.

Start with **article/article.pdf**. The editable, self-contained source is
**article/article.tex**. No external bibliography file or image asset is needed.

## Results and evidence boundary

**F1** identifies a missing fixed-chart guard in `AsymptoticExponentialCoreInverse`.
A target-dependent `SourceShift` makes the inferred remainder exponentially too
small for the inverse of `Exp[x]+1`, even though the displayed finite coefficients
remain correct. The report proves this for every finite retained sector depth.
The public witness is source-predicted, not kernel-reproduced.

**E1** proposes opt-in absorption of a constant perturbation into the recognized
core's target offset. **E2** supplies exact rational moment algorithms for the
existing Lerch expansion. These are development opportunities, not additional
wrong-result bugs or claims of novel special-function identities.

The exclusion screen used the maintained review registers and crosswalks for
waves 1–4, the wave-5 index (including retired reports), and targeted original
material. This was not a word-for-word comparison of every earlier PDF.

**Actual execution:** 32 independent Python unittest methods passed; no failures,
errors, or skips. These exercise exact models, an independently checked rational
prototype, numerical samples, and patch-fragment fixtures. They do **not** execute
the repository. The supplied eight Wolfram desired-contract tests, characterization
script, and WL prototypes were **not run**. A limited lexical check is not a parser
or a kernel. Wolfram service calls failed; Mathics was unavailable. No full local
checkout was obtained. No package or dual-runtime acceptance is claimed.

## Files

- `code/review_math.py`: exact rational moment tables, coefficient and bound
  helpers, logarithmic-tail bounds, and independent shift models.
- `code/test_review.py`, `code/run_evidence.py`: independent tests and evidence
  generator. Only the numerical checks need `mpmath`.
- `code/prepare_shift_patch.py`: non-mutating, fragment-guarded candidate diff
  generator for F1. Its fixtures use synthetic fragments, not a full checkout.
- `code/ReviewAdditions.wl`: additive prototypes in their own context; no upstream
  or `System` definitions are replaced. Rational moment degree is capped at 256.
- `code/ReviewRegressions.wlt`: eight unexecuted desired-contract tests.
- `code/characterize_shift.wl`: unexecuted baseline observation script.
- `evidence/`: independent results, numerical examples, prototype timings, scoped
  findings, novelty ledger, source map, and artifact build/inspection records.

## Reproduce the independent checks

From this directory, with Python and mpmath installed:

```sh
python -m pip install -r code/requirements.txt
python code/run_evidence.py
python code/check_wl_lexical.py
```

The first script rewrites its own evidence files. Timing results are machine-
dependent Python measurements, not a comparison with Wolfram or Mathics.

## Prepare and examine the candidate fix

Given a local checkout of the pinned repository:

```sh
python code/prepare_shift_patch.py /absolute/path/to/Asymptotic > shift.patch
```

The script refuses a missing, ambiguous, or already-patched anchor and does not
modify the checkout. Inspect the diff before applying it. After an accepted source
change, regenerate the standalone using the repository's existing
`validation/build_standalone.py` workflow. No claim is made that a patch was applied
or an upstream package rebuilt in this review.

In a fresh Wolfram kernel, load the actual patched package and this helper file,
then evaluate the tests. Replace the two directory strings with local paths:

```wolfram
Get["/absolute/path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl"];
Get["/absolute/path/to/review/code/ReviewAdditions.wl"];
TestReport["/absolute/path/to/review/code/ReviewRegressions.wlt"]
```

For baseline observations, load the unpatched package in a different fresh kernel
and `Get` the characterization script. Do not mix patched and unpatched definitions
in one session. Mathics needs its own actual run; no assumption is made that its
MUnit/TestReport coverage matches Wolfram's. The scalar test expressions can be
adapted to the repository's already-existing portable test runner.

`AbsorbConstantExponentialPerturbation` is deliberately opt-in. It supports a
perturbation independent of both source and target and immediate option rules.
Delayed or nested option trees are explicitly outside this prototype's contract.
It forwards unknown input-remainder information rather than claiming exactness.

## Rebuild the article

Use a TeX installation with `newpx`, `microtype`, `listings`, `xurl`, `booktabs`,
`longtable`, and the usual AMS packages:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The distribution excludes checksum files, fonts, caches, and intermediate TeX files.
