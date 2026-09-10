# AsymptoticAnalysis — incremental source and runtime audit

Reviewed repository: `VladimirReshetnikov/Asymptotic`  
Pinned revision: `efa1aeec4845a9c35e140963a0333d0c9ec33b05`  
Date: September 10, 2026

## Result

The article admits **one new root-cause finding, CG-01**, not a repeat of the
existing review backlog. Binary arithmetic duplicates already-aligned operational
conditions. With an independent zero series, repeated addition produces
`2^(n+1)-1` copies of `x>0`; with scalar zero, the measured sequence is
`3, 9, 27, 81`. The finite expression remains exactly `x`.

Removing only the second merge is insufficient: the scalar case still produces
`2, 4, 8, 16`. The stronger candidate performs structural, duplicate-free
conjunction at alignment and persists that combined condition once. Selected
Wolfram 15 observations retain one predicate through zero-addition and
unit-multiplication, preserve distinct parameter assumptions, and reject
contradictory domains.

Read `article/audit.pdf` or edit `article/audit.tex`. The review covers the source
path, proof of the growth recurrences, native observations, repair correctness,
portability obligations, predecessor crosswalk, and focused development plan.

## Evidence boundaries

The executed kernel reported:

```
15.0.0 for Linux x86 (64-bit) (May 6, 2026)
```

`evidence/native_observations.json` is an explicit transcription of successful
connector responses. It is not a full-suite log. The complete supplied Wolfram
probe scripts were assembled after selected equivalent probes ran; they have not
been executed as one program. The candidate's expressions were exercised by
source substitution in the pinned standalone; complete staged-file and modular
integration remain to be validated.

The independent Python run contains **26 passing unittest methods**. These check
Boolean/count models and guarded source fixtures, not an implementation of
Wolfram Language. No actual Mathics run, full upstream acceptance run, replicated
benchmark comparison, or patched 41-case observable screen is claimed.

The six review indexes and maintained register were screened, with selected
articles and predecessor passages inspected. This is not an exhaustive rereading
of every retained article. `evidence/novelty_ledger.json` distinguishes the new
operational-condition mechanism from the existing recipe/provenance item P07.

## Run the independent tests

Requirements: Python 3.9 or later, standard library only. Executed here on Python
3.13. No network calls or third-party dependencies are used by these tools.

```sh
cd code
python test_independent_models.py
```

The captured result is `evidence/independent-tests.txt`.

## Stage the candidate

Use an unchanged local copy of the pinned standalone or modular
`src/Kernel/SeriesOperations.wl`:

```sh
python code/patch_conditions.py \
  /path/to/pinned/AsymptoticAnalysis.wl \
  /path/to/staged/AsymptoticAnalysis-candidate.wl
```

The destination must differ from the source and must not already exist. The tool
checks both definition boundaries and exact source fragments. It refuses source
drift, a prior candidate helper, duplicate definitions, and reapplication. It
never edits the repository itself. It is a bounded source transformer, not a
general Wolfram Language parser.

`patch_conditions.py` imports `patch_merge_only.py`; keep both in the `code`
folder. **Do not treat `patch_merge_only.py` by itself as a complete repair.** It
is included to reproduce the insufficiency demonstrated in the article.

For upstream integration, modify the maintained modular source and regenerate
the distribution using the repository's own build process. Staging a standalone
candidate is intended for isolated validation, not for leaving generated and
modular sources inconsistent.

## Focused evaluator probes

In a fresh Wolfram or Mathics session:

```wl
$AuditPackage = "/absolute/path/to/AsymptoticAnalysis-candidate.wl";
$AuditMode = "Candidate";
Get["/absolute/path/to/bundle/code/run_condition_probes.wl"];
```

Use `"Baseline"` for unchanged source and `"MergeOnly"` for the intentionally
incomplete candidate. The runner returns an association with explicit IDs,
actual/expected values, and failure count. Some additional cells are source-
derived expectations, not claims that those cells were already measured.

To run the explicitly classified observable diagnostic in another fresh session:

```wl
$AuditPackage = "/absolute/path/to/AsymptoticAnalysis.wl";
Get["/absolute/path/to/bundle/code/run_observable_screen.wl"];
```

Unassessed results and unavailable oracles are not counted as passes. The earlier
unchanged-baseline observation was 41 eligible comparisons with no discrepancy;
it does not establish a portable fixed pass count for every interpreter.

## Rebuild the article

A LaTeX installation with `pdflatex`, `newtx`, `amsmath`, `amsthm`, `microtype`,
`booktabs`, `longtable`, `listings`, `hyperref`, `xurl`, and the standard packages
listed in the preamble is required.

```sh
./build_article.sh
```

On Windows, run `pdflatex -interaction=nonstopmode -halt-on-error audit.tex` three
times from `article`. The article is self-contained; no bibliography processor,
external images, shell escape, network access or font files in the bundle are
required. The supplied PDF was rendered and visually checked.

## Layout

- `article/`: TeX and PDF.
- `code/`: candidate staging, focused evaluator diagnostics and independent tests.
- `fixtures/`: transcribed upstream source excerpts for guarded-transform tests.
- `evidence/`: native transcriptions, execution scope, source coverage, novelty
  ledger, and captured Python test output.

The article and original audit code are provided under MIT No Attribution, as
are the upstream source excerpts; see `LICENSE` and `NOTICE.md`. No checksum files
are included.
