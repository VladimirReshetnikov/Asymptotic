# AsymptoticInverse 1.8.0 — source audit and development proposals

**Audited repository:** VladimirReshetnikov/Asymptotic  
**Pinned commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Audit date:** September 9, 2026

Read **article.pdf** for the full review. The editable article source is
**article.tex**, with its rendered reference list in **references.tex** and a
machine-readable bibliography in **references.bib**.

## Findings

| ID | Finding | Nature of evidence |
|---|---|---|
| F01 | Eager dense `SeriesData` allocation defeats sparse input size. | Inspected source and exact dimension calculations. |
| F02 | Tiny-cutoff integer powers attempt a full exact expansion. | Inspected source; independent bounded-power implementation. |
| F03 | Newton/grouped routes still enumerate the Lagrange multi-index region. | Inspected control flow; exact 20,475-index versus 142-weight example. |
| F04 | Forward realness checks are inconsistent with the real-only contract. | Traced source paths; native behavior probes supplied. |
| F05 | Fixed-margin recipe refinement can miss a reachable requested precision. | Inspected source and mathematical precision transport. |
| F06 | The native-series bridge loses logarithmic remainder information. | Inspected source, existing documentation caveat, mathematical example. |

Each finding is qualified in the article. In particular, F04 is a domain/contract
issue, not a demonstrated wrong complex coefficient; F05 can return a correct but
weaker remainder; and F06 is already acknowledged by the upstream guide.

## What was and was not executed

**Executed:** 25 independent Python tests passed: 20 mathematical/resource-model
tests (one containing 100 deterministic randomized subcases) and five tests of the
proposed edit script against small source fixtures. See `results/python_tests.txt`
and `results/independent_evidence.json`.

**Not executed:** the Wolfram Language package, any upstream Wolfram tests, the
supplied native characterization script, and the proposed Wolfram regressions.
The available Wolfram service could not connect and its evaluator request returned
HTTP 502. No native kernel version or native benchmark was obtained.

**Source access:** pinned GitHub connector reads, not a complete local checkout.
The source manifest records inspected paths and windows; this archive does not
include a full upstream snapshot. Several specialized families were reviewed
through documentation and architecture rather than exhaustively line by line.

**Patch status:** `proposals/apply_bridge_hardening.py` is a proposal for F01/F06
only. It was fixture-tested but was not applied to a complete downloaded upstream
source file or compiled in Wolfram. It does not implement the F02–F05 redesigns.

## Rebuild the article

Use a LaTeX installation providing `pdflatex`, `latexmk`, and the packages named
in `article.tex` (including Latin Modern, microtype, amsmath, longtable, listings,
xurl, and hyperref).

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error article.tex
```

The document reads `references.tex` directly, so BibTeX is not required for this
build. `references.bib` is supplied for reference management; update both reference
files when editing citations. The optional Makefile provides `make`, `make test`,
`make evidence`, and `make clean` targets.

## Rerun the independent checks

Python 3.10 or later; no third-party Python packages are required for the models.
From the archive root:

```sh
python -m unittest discover -s code -p 'test_*.py' -v
python code/generate_evidence.py
```

The second command regenerates `results/independent_evidence.json`. Its timings,
where present in the unittest log, are Python test-run timings, not Wolfram
performance measurements. `code/audit_models.py` implements restricted exact
rational-weight polynomial models, not a full replacement for AsymptoticInverse.

## Obtain the pinned upstream distribution

With network access:

```sh
python code/download_pinned.py
```

This creates `source/AsymptoticInverse.wl` only after verifying its expected Git
blob. It refuses to overwrite a different existing file and never executes the
downloaded code. This downloader was not executed in the audit environment.
Review any source before loading it into a Wolfram kernel. A Git blob identifier
is a content identifier; distribution provenance and the trusted expected value
remain part of the trust decision.

## Characterize behavior in a native Wolfram kernel

Use a fresh kernel and a verified standalone file, or a complete checkout at the
pinned commit. Set the environment variable to an absolute local path.

Unix-like shell:

```sh
export ASYMPTOTIC_AUDIT_PACKAGE="$PWD/source/AsymptoticInverse.wl"
export ASYMPTOTIC_AUDIT_OUTPUT="$PWD/results/native-characterization.json"
wolframscript -file code/native_characterization.wl
```

PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_PACKAGE = (Resolve-Path .\source\AsymptoticInverse.wl).Path
$env:ASYMPTOTIC_AUDIT_OUTPUT = Join-Path $PWD 'results\native-characterization.json'
wolframscript -file .\code\native_characterization.wl
```

The 14 probes record results rather than enforce desired behavior. Each probe has
a 20-second and 256 MiB additional-allocation guard. These limits can themselves
produce a recorded audit failure; they are not package test conclusions. Package
loading precedes those per-probe limits. The record includes the actual kernel
version, system ID, entry-file SHA-256, and expected audit commit. The expected
commit field is not a verified claim about an arbitrary path supplied by a user.
A modular entry's hash does not cover companion files; use a pinned checkout.

## Review the bridge-hardening proposal

Use a local checkout of the pinned repository. The script checks the canonical
core's Git blob and exact replacement preconditions. By default it only prints a
diff and changes no file:

```sh
python proposals/apply_bridge_hardening.py --repo /path/to/Asymptotic
```

After reviewing the diff, `--write` intentionally changes the canonical core.
This is a local file operation, not a GitHub write. The default dense coefficient
limit is 100,000; `--max-native-coefficients` controls the proposed limit.

Regenerate the standalone distribution with the upstream builder, then run native
regressions and the complete upstream suite before release. Do not edit the
generated standalone file as the primary implementation.

The separate desired-behavior suite runs with:

```sh
wolframscript -file code/run_proposed_regressions.wl
```

It reads `ASYMPTOTIC_AUDIT_PACKAGE`. Several of its eight tests should fail on the
original implementation and will still fail after only the bridge patch. It is
not the full upstream suite. Its process exits 0 on all passed tests, 1 on test
failures, and 2 on loading/runner/noncompletion/empty-suite failure. Native runners
are supplied unexecuted and require validation in the target Wolfram version.

## Archive layout

- `article.tex`, `article.pdf`, `references.tex`, `references.bib`: review.
- `code/`: models, tests, evidence generator, native probes, pinned downloader.
- `proposals/`: opt-in, hash-guarded source-hardening proposal.
- `results/`: Python results, source manifest, and PDF quality checks.
- `SHA256SUMS.txt`: checksums of distributed files, excluding itself.

No font files or full upstream package are redistributed in this archive.
