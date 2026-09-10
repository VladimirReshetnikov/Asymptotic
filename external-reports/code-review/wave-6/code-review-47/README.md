# Asymptotic — Incremental Technical Audit

Reviewed repository: VladimirReshetnikov/Asymptotic  
Pinned commit: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`  
Review date: 10 September 2026

## Start here

The article is `article/asymptotic_incremental_audit.pdf`; its complete source is
`article/asymptotic_incremental_audit.tex`. The article gives three scoped findings,
proofs/counterexamples, novelty boundaries, candidate repairs, and a focused
implementation and acceptance plan. It does not restate the existing general
review backlog.

| ID | Finding | Evidence boundary |
| --- | --- | --- |
| N01 | Duplicated work in the mutually recursive Mathics realness/sign provers | Retrieved source helpers executed in Wolfram 15.0.0 for nesting levels 0–6; larger counts and memoization are independently checked restricted models, not Mathics timings. |
| N02 | Python optimization removes documentation validity predicates | Actual upstream checker executed with deterministic fixture dependencies under normal and `-O` Python. |
| N03 | Commented TeX definitions can mask missing references; inactive text also creates false failures | Actual checker fixtures and five real two-pass `pdflatex` experiments. |

## Contents and status

`code/` contains a restricted proof-search model, a guarded documentation patch
generator, its emitted candidate, a unified patch, and local-path Wolfram Language
reproduction scripts. `upstream/` preserves the original documentation checker.
`tests/` contains standard-library-only fixtures and 19 test methods.
`evidence/` preserves observations, compiler logs, environment details, the test
transcript, and manually transcribed native connector inputs/results.
`findings.json` and `novelty-crosswalk.md` provide intake-ready summaries.

The repository was not modified. The documentation patch has been exercised with
fixtures, not with the live repository's real guide, link, encoding, Pandoc, and Git
integrations. The memoizing proof model is **not** a full production Mathics patch.

## Reproduce the local evidence

From this directory, using Python 3.10 or later:

```sh
python -S tests/run_evidence.py
python -S -m unittest discover -s tests -p 'test_*.py' -v
python -S code/proof_cost_model.py
```

The first command regenerates 56 documentation observations and 15 proof-model
observations. With `pdflatex` installed, it also regenerates five two-pass compiler
experiments. Without it, those compiler experiments are explicitly skipped and the
shipped compiler receipts remain unchanged. Receipt-consistency tests inspect the
recorded compiler output; they must not be mistaken for new compiler runs.

`-S` avoids site initialization; it does not disable assertions. The fixture
runner separately invokes normal and `-O` child processes for N02. No third-party
Python packages or network access are needed for these local checks. Several
fixtures intentionally provoke invalid documents; expected rejections are part of
the experiment, not failing acceptance tests. The actual compiler logs for the two
masked-key witnesses deliberately contain undefined-reference/citation warnings.

A direct demonstration:

```sh
python -S tests/documentation_fixture.py upstream/check_documentation.py comment_mask_reference
python -S -O tests/documentation_fixture.py upstream/check_documentation.py missing_reference
python -S tests/documentation_fixture.py code/check_documentation_candidate.py comment_mask_reference
```

The first two commands incorrectly accept their invalid fixtures. The candidate
correctly rejects the last fixture with exit code 1.

## Candidate integration

Review `code/documentation-candidate.patch` before applying it in an isolated
checkout of the pinned revision. It changes `validation/check_documentation.py`
and adds `validation/documentation_audit_guards.py`. Run the real documentation
command afterward with its actual dependencies. Do **not** install the fixture
providers in the repository.

The comment masker supports ordinary percent comments under standard TeX
catcodes. It is not a general parser for verbatim syntax, arbitrary catcodes,
macro-generated definitions, or recursively generated inputs. Raw source remains
in use for archive comparisons and the existing software-separation policy.

For CAS reproductions, start a fresh kernel, set `$AuditRepositoryRoot` to the
pinned checkout, then load `code/cas_controls.wl` or `code/cas_proof_counter.wl`.
The counter defaults to nesting levels 0–6; larger levels are opt-in through
`$AuditMaximumN`. Instrumentation should not share a kernel with concurrent work.
The shipped local-path scripts were not separately run in Mathics. Exact executed
native connector input is preserved in `evidence/wolfram-observations.md`.

## Rebuild the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_incremental_audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_incremental_audit.tex
```

A further pass may be needed after changing pagination or cross-references.
The source uses common TeX Live packages, including `lmodern`, `microtype`,
`mathtools`, `tabularx`, `listings`, `xurl`, and `hyperref`.

## Evidence limits

Seven selected pinned-package finite-expression controls passed in Wolfram
Language 15.0.0. Retrieved Mathics helpers were separately counted on that native
host. **Mathics itself and the full original package suite were not executed.**
The 19 Python methods, 56 fixture observations, 15 model observations, and five
compiler experiments are different evidence populations, not one package test
count. The 335,521-to-200 comparison counts model body evaluations, not elapsed
time. No new incorrect asymptotic formula is claimed.

Novelty screening used the pinned all-wave registers, crosswalks, fifth-wave
index and selected nearby report material. It was not a fresh cover-to-cover
rereading of every retained article. See `novelty-crosswalk.md` for the specific
mechanism distinctions.

No checksum files are included. See `upstream/README.md` for source provenance.
