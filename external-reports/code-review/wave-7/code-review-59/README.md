# Asymptotic: componentwise validation and standalone parsing

Open **article/review.pdf** for the article; **article/review.tex** is its complete
LaTeX source. Reviewed repository: `VladimirReshetnikov/Asymptotic`, snapshot
`efa1aeec4845a9c35e140963a0333d0c9ec33b05` (10 September 2026).

## Two retained incremental findings

**N01 — validation after cancellation.** `AsymptoticCoreInverse` validates
`core + perturbation`, then reasons about the components separately. A target-
dependent offset can disappear in the sum. The source-predicted squared witness
uses `x + Abs[y]/2` and `-Abs[y]/2`, source endpoint `Infinity`, depth 1, and
`"Power" -> 2`: its finite expression is `3 y^2/4` on the positive ray and its
assigned envelope is 1, although the exact inverse observable is `y^2`.
The error `y^2/4` is not O(1). The article also proves the whole integer-power
family and a sublinear logarithmic-offset family, and explains the coefficient-
realness gate. This public result was NOT executed; Mathics may instead reject
it at its narrower realness prover.

**N02 — missing association nesting in the Mathics bootstrap splitter.** The
transcribed Python helper splits an internal association semicolon into separate
unmatched chunks. A delimiter-stack prototype fixes that case. No current
shipped adapter triggering this syntax and no current package load failure are
claimed.

The novelty ledger compares these sites against the six wave indexes and the
maintained register/intake summaries, with targeted earlier reports. It does not
claim a word-for-word comparison of every archived article.

## Evidence

**33 independent unittest methods passed**, with no failures, errors or skips:
13 exact-model methods, 15 bootstrap/lexer methods, and five patch-emitter methods.
Subcases and sample grids are not added to that test count. See
`evidence/independent-results.json` and `evidence/test-output.txt`.

No successful Wolfram or Mathics package execution took place. No local checkout,
upstream test-suite run, actual upstream builder run, patched package load, or
package benchmark was obtained. GitHub connector reads supplied commit-pinned
source. Runtime service and local network/installation routes failed. See
`evidence/scope.json` for the exact boundary.

`code/bootstrap_reference.py` is a manual transcription of two upstream helper
bodies, NOT a byte-verified downloaded file. The candidate lexer is a limited
source preprocessor, NOT a complete Wolfram Language parser.

## Reproduce the independent checks

Requirements: Python 3.10 or later and SymPy. The recorded run used Python 3.13.5
and SymPy 1.14.0. No network or interpreter subprocess is used by these tests.

```sh
python code/run_independent.py
```

This rewrites only the included independent receipts and sample CSV in `evidence/`.
It does not modify a repository or invoke Wolfram/Mathics.

## Candidate repairs

`patches/core-component-guard.patch` contains the narrow two-line N01 change.
Prefer emitting a context-bearing diff against a local inspected source:

```sh
python code/emit_core_guard_patch.py \
  /path/to/Asymptotic/src/Kernel/CorePerturbation.wl
```

The emitter refuses missing/duplicate/already-patched anchors and never changes
its input. It was tested against synthetic fixtures, not a checkout. Integrate
the change into the canonical source and rebuild the standalone through the
repository's existing builder; do not maintain a separate edited standalone fork.

`code/bootstrap_fixed.py` contains the N02 delimiter-stack prototype. Integrate
its logic into the actual builder and run the repository's existing tests plus
the new fixtures before adopting it. The prototype supports ordinary grouping
and three association-delimiter spellings, retains the semicolon-terminated
statement convention, and does not establish arbitrary-WL parsing support.

## Unexecuted runtime specifications

After loading a chosen package entry into a fresh Wolfram or Mathics kernel,
load `code/ProbeCoreComponents.wl` to record baseline behavior and proof gates.
The twelve tests in `code/ReviewCoreComponents.wlt` specify the repaired contract;
run them with Wolfram `TestReport` after loading the repaired package.

`code/ProbeBootstrapSyntax.wl` is a separate held-parse probe and requires no
package. None of these WL/WLT files was run in this audit. Their lexical balance
check is not parser or evaluator acceptance.

## Build the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
```

Repeat if cross-reference warnings request it. The supplied PDF was compiled and
rendered for layout inspection. Standard LaTeX packages suffice; no external
figures or font files are required.

The archive includes no checksum files, TeX auxiliary files, repository mirror,
interpreter installation, Python bytecode, or bundled fonts. The upstream fixture
license and provenance are in `licenses/UPSTREAM-NOTICE.md`.
