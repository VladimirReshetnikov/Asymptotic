# Asymptotic — incremental Wolfram 15 / Mathics3 audit

Reviewed commit: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`  
Review date: September 10, 2026

Start with **article.pdf**. The article contains three newly reproduced API defects, source-level explanations, focused fixes, an exclusion comparison with earlier reviews, runtime evidence, and remaining integration obligations.

## Contents

- `article.tex`, `article.pdf`: the article source and compiled 20-page PDF.
- `code/reproduce.wl`: observations for the public witnesses and focused controls.
- `code/run_controls.wl`: the 42-case numerical diagnostic screen.
- `code/candidate_patch.py`: stages four candidate edits in three canonical files, together with a unified diff. It does not modify the input checkout.
- `code/test_candidate_patch.py`: six synthetic-fragment unit tests for the staging utility.
- `code/novelty_scan.py`: offline lexical review-archive scanner; matches require manual interpretation.
- `evidence/native_observations.json`: curated transcriptions of returned native observations and their status.
- `evidence/review_scope.json`: completed exclusion-source and full-text-screen scope.
- `evidence/test_status.md`: what was and was not executed.

## Reproduce the public calls

Use a **fresh kernel** for each package version. Set the path to a local standalone package (or the modular entry point in its complete source tree), then run:

```wolfram
$AuditPackage = "/absolute/path/to/AsymptoticAnalysis.wl";
Get["/absolute/path/to/code/reproduce.wl"];
```

The script also accepts the environment variable `ASYMPTOTIC_PACKAGE`. It prints observations, stores them in `$AuditResults`, and optionally exports plain text when `$AuditOutput` is a string path. The 42-case screen is in `run_controls.wl` and uses the same package-path convention.

These scripts do not download the package. Obtain the pinned source separately. A source checkout can be created with ordinary Git tooling and checked out at the commit printed above. The audit environment did not execute the complete repository test suite.

## Stage the candidate changes

Python 3.10 or newer, standard library only:

```text
python code/candidate_patch.py /path/to/pinned-checkout /path/to/new-staging-dir
```

The output directory must not already exist and must be outside the input checkout. The tool checks `git rev-parse HEAD` by default and requires every exact source anchor to occur once. `--allow-unverified-revision` permits a source archive without Git metadata, or an explicitly accepted different revision, but does not relax anchor checking.

The staged directory contains **changed fragments, not a complete runnable package**. Inspect `candidate.patch`; apply it only to a disposable checkout first. Regenerate the standalone artifact with the repository's `validation/build_standalone.py`, then execute the existing validation and the new focused tests. The audit tested equivalent temporary standalone edits, not this complete rebuild workflow.

N1's minimal patch covers the common source chart and the ordinary inverse constructor. It is not a universal variable-admission implementation across every specialized constructor and native-dispatch path. N3's patch fixes specialized dispatch after the existing condition proof; it does not eliminate the preceding requirement that the input flatten into the ordinary representation. No completed native refinement-replay result is claimed.

## Local utility tests and further exclusion screening

```text
python -m unittest discover -s code -p "test_candidate_patch.py" -v
python code/novelty_scan.py /path/to/checkout --output additional-screen.json
```

The six Python tests passed locally on synthetic fragments. They do not validate the repository's Wolfram syntax or its Mathics runtime. The scanner reads `.tex` and `.md` files under `external-reports/code-review`, never modifies the checkout, and refuses to overwrite an existing output file. Lexical absence does not prove semantic novelty.

## Evidence boundary

Wolfram Language **15.0.0 for Linux x86 (64-bit), May 6, 2026** was directly executed through the connected evaluator. All three baseline failures were reproduced. Focused candidate checks for N2/N3 and, separately, the final N1 guards returned the expected results. The 42-case arithmetic screen returned 41 nonexact cases and one exact case with no flags under its documented heuristic.

**Mathics3 package execution was not performed.** Compatibility conclusions are source-level assessments, and Mathics acceptance tests are supplied but unexecuted. A combined all-edits integration batch and a refinement-replay attempt did not produce a usable completed service result. They are not included in passing counts.

The evidence files are curated transcriptions and summaries, not unedited complete session logs. Transport failures are not counted as repository failures. Numerical samples are not interval certificates. No full replacement package or release certification is supplied.

## Rebuild the article

Run `pdflatex -interaction=nonstopmode -halt-on-error article.tex` twice (a third run can settle references after layout changes). The article uses standard TeX packages and has no external figure assets. The delivered PDF was rendered and visually inspected. No checksum files or font files are included.
