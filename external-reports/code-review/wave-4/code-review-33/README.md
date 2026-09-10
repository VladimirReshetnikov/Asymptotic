# AsymptoticAnalysis: incremental audit and Mathics compatibility

**Reviewed repository:** VladimirReshetnikov/Asymptotic  
**Pinned commit:** `7d1bc832895cc90a9b2a978b7b7684acab908bd2`  
**Date:** September 9, 2026, Pacific daylight time  
**Mathics source reference:** 10.0.1, commit `f6a987e704313e37b2b46ed4fe0b61aab108b58a`

Start with **article/asymptotic-review.pdf**. The complete editable source is
**article/asymptotic-review.tex**.

## Results

The article compares the package with current official Wolfram documentation,
explains its mathematical representation and modular architecture, and assesses
the actual scope of its Mathics support. Its incremental finding set is screened
against the repository's consolidated register and wave-3 intake, with an explicit
novelty crosswalk. It does not claim all 27 historical articles were reread in full.

F01 identifies exact symbolic Lambert argument-order corruption, not merely the
already documented unsupported nonprincipal numerical path. F02 identifies a
public coefficient-query call site missed by the private-only empty-list Map
workaround. F03 identifies a selected-case acceptance path after a failed package
load. F04 concerns the scoped Limit adapter's default direction. F05 identifies
all-match traversal in a first-match helper and its symbolic-merge consumer.
Two additional advisories address dense coefficient conversion and interrupted
loading. Their public manifestations are not claimed as reproduced failures.

## What ran

**Seven independent Python tests passed.** These exercise an exact-rational
logarithm/Lambert reference algorithm, direct SymPy bridge-stage counterexamples,
a formal inverse-coefficient identity, invalid-input/resource handling, and an
operation-count model. Actual output is in `evidence/independent-checks.json`.

**No Wolfram or Mathics package execution occurred.** No full upstream acceptance
run or native timing benchmark is claimed. The article distinguishes source proofs,
independent executions, predicted public manifestations, and repository-reported
validation receipts. `evidence/runtime-status.json` records this boundary.

The kernel probes and focused source edits are **unrun proposals**, not completed
fixes. No repository files or remote resources were modified.

## Files

- `article/`: PDF and self-contained LaTeX article.
- `code/lambert_minus_one.py`: standard-library-only rational enclosure of the
  real branch W_-1(-q), q rational in (0,exp(-1)). All enclosure arithmetic is exact.
- `code/independent_checks.py`: executed independent tests (requires SymPy/mpmath).
- `code/run_probes.py`: fresh-kernel runner for five unrun review probes, supporting
  a Mathics Python environment or an official Wolfram kernel executable.
- `code/probes/load_returns_failed.wl`: deliberate invalid-source fixture for the
  upstream portable runner, not a package file.
- `patches/focused-proposals.md`: scoped changes for the empty-index validation,
  load gate, first-match helper, and the requirements of a bidirectional Lambert fix.
- `evidence/`: actual independent results, source/novelty ledger, and runtime status.

No checksum files, font files, generated auxiliary files, or repository snapshots
are included.

## Independent checks

```sh
python -m pip install -r code/requirements.txt
python code/independent_checks.py
python code/lambert_minus_one.py 1/10 --digits 35
```

`lambert_minus_one.py` itself uses only the Python standard library. The result is
a rational interval and strict rational endpoint sign bounds for a monotone
logarithmic equation. It is a reference oracle, not an integrated Mathics adapter
and not a proof-assistant-verified implementation.

## Kernel probes on a local installation

Use a local checkout at the pinned commit and the repository's own pinned Mathics
requirements. Each command below is a single line (also suitable for PowerShell).

```text
python code/run_probes.py --repo C:\src\Asymptotic --python C:\venv\Scripts\python.exe --entry modular
python code/run_probes.py --repo C:\src\Asymptotic --python C:\venv\Scripts\python.exe --entry standalone
python code/run_probes.py --repo C:\src\Asymptotic --wolfram WolframKernel.exe --entry modular
```

The default output is `evidence/local-probe-run.json`; it is created only when the
runner actually runs. A failing probe on an unmodified source may be the desired
characterization of an unfixed finding. Process or protocol failures are separate
from a mathematical/contract test failure.

The F03 load-failure fixture is for the UPSTREAM runner. From a checkout, with
Mathics in the current Python environment:

```text
python validation/run_mathics_tests.py --source C:\path\to\bundle\code\probes\load_returns_failed.wl --case primitive-check-is-unpolluted --output C:\temp\load-gate-probe.json
```

The selected primitive can pass before the proposed load gate. After the gate,
the run must be an error. This invocation has NOT been executed here.

## Rebuild the article

An installed TeX distribution with XeLaTeX, TeXGyrePagella, TeXGyreHeros, DejaVu
Sans Mono, and the packages declared in the source:

```sh
cd article
xelatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
xelatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
xelatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
```

A third pass can be needed for the table of contents and long-table widths.
Reference URLs point to the pinned repository and Mathics sources, or the current
official Wolfram/SymPy documentation. No font files are distributed.
