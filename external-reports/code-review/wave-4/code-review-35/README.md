# AsymptoticAnalysis: incremental review and Mathics compatibility

Repository: `VladimirReshetnikov/Asymptotic`  
Reviewed commit: `7d1bc832895cc90a9b2a978b7b7684acab908bd2`  
Commit time: September 10, 2026, 02:10:22 UTC (September 9, 19:10:22 PDT).

Start with **article/article.pdf**. Its self-contained LaTeX source is
**article/article.tex**. The article covers native Wolfram Language comparisons,
six incremental findings, Mathics contracts and coverage, repairs, exact proofs,
performance methodology, and prioritized development.

## Evidence boundary

No official Wolfram or Mathics package execution was completed in this review.
The actual, byte-identical upstream **Python runner** was executed against a
controlled mock external-kernel protocol peer. Independent exact Python models
were also executed. The Wolfram Language candidate code and public package
probes are supplied **unexecuted**. Source predictions are not represented as
observed package outputs.

Deduplication used the three-wave review indexes, maintained consolidated
implementation register, and complete attributed finding crosswalks. This is
not a claim that all 27 original articles were reread in full. The novelty
ledger identifies the new mechanism and adjacent older work for each finding.

## Findings

| ID | Finding | Evidence |
|---|---|---|
| N01 | An already detected source change is forgotten after restoration, allowing a successful final receipt. | Actual upstream Python runner and candidate executed with a mock peer. |
| N02 | `nan` and `inf` timeouts pass validation, reach exception paths, and appear as nonstandard numeric tokens in initial reports. | Original/candidate CLI experiments. |
| N03 | The Mathics coefficient adapter turns sparse input into a dense degree-sized coefficient list. | Source deduction and independent exact reference models; no large kernel allocation attempted. |
| N04 | The local `FirstPosition` obtains all positions; the inspected Mathics implementation lacks the obvious native bounded overload. | Adapter and upstream Mathics source; independent counting models. |
| N05 | Seven trial radii miss valid arbitrarily small affine neighborhoods. A rational constructive-radius algorithm closes this bounded gap. | Mathematical proof, exact Python checks, and unexecuted public probes. |
| N06 | The local `Limit` default selects a lower-sided limit rather than preserving the current Wolfram two-sided default. | Source/documentation comparison and exact sided witness. No wrong public constructor result established. |

## Contents

- `article/article.tex`, `article/article.pdf`: full report and bibliography.
- `upstream/run_mathics_tests.py`: exact reviewed upstream runner.
- `upstream/LICENSE`: upstream MIT No Attribution license.
- `code/patch_portable_runner.py`: source-identity-guarded candidate generator; refuses to overwrite its input.
- `code/portable_runner_candidate.patch`: focused N01/N02 unified diff.
- `code/run_mathics_tests_candidate.py`: generated candidate runner, derived from the upstream MIT-0 source.
- `code/ReviewPrimitives.wl`: separate, unexecuted `AsymptoticReview` context with bounded sparse extraction, rational affine radius, and conservative real-limit candidates. It does not override the production package or System functions.
- `tests/runner_experiments.py`: isolated mock-peer infrastructure experiments.
- `tests/exact_reference_checks.py`: independent exact reference models.
- `tests/ProbeNewReview.wl`: unexecuted fresh-kernel observation script.
- `evidence/runner_experiments.json`: 14 scenarios with raw diagnostics and original/candidate controls.
- `evidence/exact_reference_checks.json`: rational/integer reference results.
- `evidence/findings.json`, `evidence/novelty_ledger.csv`: findings and novelty boundaries.
- `evidence/source_inventory.csv`: pinned sources and actual inspection scope.

## Reproduce the executed checks

From this directory:

```sh
python -S tests/runner_experiments.py
python -S tests/exact_reference_checks.py
```

Only the Python standard library is needed. The runner fixture was executed on
Linux/Python 3.13.5 and uses a POSIX executable protocol peer; it has not been
validated on Windows. The scripts write their JSON results under `evidence/`.
They operate on disposable fixture repositories, not the user's checkout.

There are 14 infrastructure scenarios: original/candidate variants of three
source-change cases and four invalid-timeout arguments. “Assertions passed”
means the expected characterization was observed, not that the original runner
passed every case correctly. None of these counts is a Wolfram/Mathics test
pass count.

The exact reference checks include 325 bounded sparse/dense comparisons, 160
small-neighborhood cases, 600 random rational conjunctions (124 proved by the
candidate), 25 coordinate rescalings, inverse coefficients through degree 12,
and first-position counting models. The degree-billion sparse specimen does
not allocate a billion-entry array.

## Candidate runner integration

Apply only to the reviewed source or reconcile the patch manually with newer
changes. The generator checks the input's Git blob identity before changing it:

```sh
python -S code/patch_portable_runner.py \
  /path/to/checkout/validation/run_mathics_tests.py \
  /path/to/disposable/validation/run_mathics_tests.py \
  --diff /path/to/candidate.patch
```

The candidate must live in a repository-shaped `validation` directory beside
`MathicsTests.wl`, with the corresponding package sources. Do not run
`code/run_mathics_tests_candidate.py` directly from this archive and assume it
will find the full upstream suite: its root/suite discovery is inherited from
the repository runner. The mock experiments create the correct fixture layout.

The patch latches **observed** drift. It does not continuously monitor inputs,
freeze every package module, or detect changes wholly between observations.
The article gives the stronger frozen-source follow-up design.

## Pending Wolfram / Mathics probes

Use a fresh kernel. Set `ASYMPTOTIC_REVIEW_SOURCE` to an absolute path to the
pinned modular or standalone entry point. Optionally set
`ASYMPTOTIC_REVIEW_CANDIDATES` to the absolute path of `code/ReviewPrimitives.wl`.
Examples on a POSIX shell:

```sh
export ASYMPTOTIC_REVIEW_SOURCE=/path/to/checkout/src/Kernel/AsymptoticAnalysis.wl
export ASYMPTOTIC_REVIEW_CANDIDATES="$PWD/code/ReviewPrimitives.wl"
mathics --quiet --no-readline --file tests/ProbeNewReview.wl
# Or use the installed Wolfram kernel executable:
WolframKernel -noinit -script tests/ProbeNewReview.wl
```

The script prints observations; it is not a release acceptance suite. It streams
loading before package calls and keeps Mathics observation inputs separate to
avoid earlier progress output contaminating a later `Check` in the same input.
It uses bounded example degrees except for the separate candidate sparse parser,
which does not expand the degree-billion input. Record full messages, runtime
version, entry point, and whether original or candidate code was used.

The candidate primitives deliberately have narrow domains. In particular, the
sparse parser refuses unexpanded variable-dependent factors; the radius routine
accepts rational affine clauses, not arbitrary logic; and the limit helper
refuses unresolved or unequal sided results without claiming that every such
refusal proves nonexistence. Production integration remains pending.

## Build the article

The LaTeX source contains its bibliography and needs no external figures:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

It uses standard LaTeX packages including `lmodern`, `microtype`, `amsmath`,
`longtable`, `tabularx`, `listings`, `xurl`, and `hyperref`. An extra pass may be
needed after a change that alters the table of contents.
