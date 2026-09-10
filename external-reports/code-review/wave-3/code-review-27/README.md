# AsymptoticAnalysis after the eighteen reviews

Pinned review of `VladimirReshetnikov/Asymptotic` at
`6687962f3c858a4f93623cfc496f33e35c6763d4`, dated September 9, 2026 (Pacific time).

Read **article/asymptotic-audit.pdf** or its self-contained TeX source.
The article compares the repository's analytic and native contracts with built-in
Wolfram Language, develops three new concrete dispatch witnesses, measures a
quadratic parser recurrence, and identifies one current README contradiction.
The novelty ledger explains how these differ from the existing review register.

## What actually ran

Successful observations used Wolfram Language **15.0.0 on Linux x86-64** and a
commit-pinned standalone downloaded inside that kernel. Three primary baseline
witnesses and selected equivalent source-edit controls were observed. Private
predicate instrumentation confirmed the parser counts 14, 44, 152, 560 at list
nesting depths 4, 8, 16, 32. See `evidence/native_observations.json` for the inputs,
returned values, and qualifications. These are transcriptions, not a complete
raw kernel log. An exploratory unrestricted inverse produced a multivalued
warning and is not claimed as an inverse-branch acceptance test.

Locally, **13 Python patch-fixture test methods passed**. The independent exact
oracles checked **50 inverse-coefficient identities** and **65 parser-recurrence
cases**. These populations are separate from native package observations.

The complete supplied 17-test `NovelRegressions.wlt` and `RunAudit.wl` were NOT
successfully executed as programs during this audit. An attempted selected
upstream native test report returned a connector error, not a test report. No
full upstream suite, cross-platform acceptance, or general performance ranking
is claimed.

## Candidate scope

`code/patch_native_dispatch.py` stages three bounded edits into a **new** file:
primary backend-default lookup, option-key normalization before selection, and
narrower callable-role classification. Its helpers preserve held option values
and existing inverse/condition/resource protections. Equivalent edits were
exercised on temporary standalone files in the native evaluator; the distributed
Python stager itself was tested on transcribed source-excerpt fixtures.

The candidate **does not settle independent mutable defaults on the alias**
`AsymptoticExpand`; it lets the alias inherit the primary function's effective
Backend default. It also **does not repair the quadratic parser** or the older
mathematical findings already in the repository's register. Complete focused
native validation is required before integration.

## Run locally

Python 3.9+ and its standard library suffice for the Python tools. For native
checks use a Wolfram kernel compatible with the repository (declared target 15+).
Each output must be a new path. The following commands work as single lines in
PowerShell or a POSIX shell after substituting real paths:

```text
python code/patch_native_dispatch.py /path/to/AsymptoticAnalysis.wl /path/to/new-candidate.wl --diff /path/to/new-candidate.diff
wolframscript -file code/RunAudit.wl /path/to/new-candidate.wl /path/to/new-native-results.json
python -m unittest discover -s code -p "test_*.py" -v
python code/independent_oracles.py --output new-oracle-results.json
```

The patcher refuses missing/duplicate anchors, in-place edits, and overwriting
an existing output. Use `--fix defaults`, `--fix option-keys`, or
`--fix callable-role` to stage selected edits. Source anchors do not authenticate
a complete snapshot: verify the input revision before running it.

For maintenance, edit the canonical modular `src/Kernel/NativeCompatibility.wl`
and regenerate the standalone with the repository's existing builder. Do not
load the isolated companion module as a complete package. The root standalone
is convenient for temporary candidate tests but is not the canonical maintenance
source. Run the repository's focused native-automatic/contract/inverse-syntax
checks before integrating a candidate; this archive does not request a full suite.

`ProfileOptionNesting.wl` is evaluated **after** loading a package. It counts
predicate entries and restores the original downvalues. It is not a timing
benchmark. `README-status-replacement.md` supplies the documentation proposal.

## Build the article

From `article/`:

```text
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-audit.tex
```

A third pass may be needed after changing tables or references. Standard TeX
Live packages, including newtx, listings, tcolorbox, and xurl, are used. No font
files are distributed. No checksum files are included.

## Evidence map

`evidence/novelty_ledger.json` maps each new item to neighboring pre-existing
register obligations without reclaiming the broad compatibility goal as new.
`evidence/scope.json` records read and execution scope.
`evidence/python_patch_tests.txt` contains the executed fixture-test log.
`evidence/independent_oracles.json` contains the executed independent model cases.
`evidence/artifact_validation.json` records the final article/build checks.

The upstream license text and a notice distinguish upstream source fragments
from newly supplied audit material.
