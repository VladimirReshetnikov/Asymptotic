# AsymptoticAnalysis: incremental technical audit

**Start with `article.pdf`.** The complete editable source is `article.tex`.
Prepared for Vladimir Reshetnikov on 10 September 2026.

Reviewed repository: VladimirReshetnikov/Asymptotic  
Pinned revision: `efa1aeec4845a9c35e140963a0333d0c9ec33b05`

## Results

**N01 — high:** public Wolfram 15 calls produce mathematically false sine and
cosine remainder bounds after an omitted complex source term is amplified.
The article proves the failure exactly. A conservative candidate rejects the
unsafe fallback while preserving tested ordinary and modulus controls.

**N02 — medium:** repeated self-addition of a one-block expansion triples the
number of stored assumptions and domain predicates at every step. A structural
idempotence candidate removes that growth in the tested native sequence.

**E01 — development:** a proved positive Euler-difference enclosure for
`LerchPhi[-q,s,a]`, including `q=1`. Independent Python and Wolfram Language
reference implementations are included. This is not installed in the package.

The nearest prior reports and precise mechanism differences are listed in
`novelty-crosswalk.md`; the article does not restate the old general backlog.

## What ran

Public baseline and in-memory candidate observations succeeded in **Wolfram
15.0.0 for Linux x86 (64-bit)**. Their inputs and manually transcribed outputs
are under `evidence/`. The independent Wolfram reference also passed 64 exact
parameter combinations. The file-based wrappers and two-test WLT file were
not separately run as complete suites.

**17 Python test methods passed**, including a 700-case rational Lerch grid,
84 comparisons with an independently enclosed logarithmic reference, 45
alternating-interval overlap checks, and six patch-emitter fixture tests.
Those populations are not an upstream package-suite count. The emitter
fixtures are synthetic; no complete local upstream checkout was available.

**Mathics itself and the full upstream suite were not run.** Shared source is
not evidence of identical evaluator behavior. No native timing speedup, full
release acceptance, or repository modification is claimed.

## Run independent checks

Python 3.10 or later, standard library only, from this directory:

```sh
python -S -m unittest discover -s tests -p 'test_*.py' -v
```

The tests regenerate their two mathematical result JSON files. They do not
access a network, install the package, or rewrite the patch manifest.

An exact example:

```python
import sys
from fractions import Fraction
sys.path.insert(0, "code")
from negative_lerch import lerch_negative_interval
b = lerch_negative_interval(Fraction(9, 10), 2, 100, 8)
print(b.lower, b.upper, b.width)
```

The theorem allows real `s>0`; the exact-rational reference intentionally
requires positive integer `s`, rational `a>0`, rational `0<=q<=1`, and a
bounded nonnegative integer order. Approximate inputs are rejected.

## Emit candidate source changes

Use a separate local checkout of the pinned revision:

```sh
python patches/emit_candidate_patch.py /path/to/Asymptotic > candidate.patch
```

The emitter reads canonical `src/Kernel` files, verifies Git HEAD, requires
one occurrence of each exact source anchor, and prints a unified diff. It
never applies the patch or writes to the checkout. `--finding N01` or
`--finding N02` emits only that finding. `--allow-other-revision` explicitly
skips the Git pin check but does not waive anchor checks. Review the source
and patch before use; a matching anchor is not a complete compatibility proof.
LF source anchors are intentional; a CRLF-only checkout may need a reviewed
line-ending normalization before they match.

After applying reviewed changes in a disposable worktree, regenerate the
standalone using the upstream builder:

```sh
python validation/build_standalone.py
```

Then run focused native acceptance and the project's required integration
validation. This audit's successful in-memory standalone experiment is not
an installed-build or full-suite acceptance record.

## Native package observations

Use a fresh kernel. In a POSIX shell:

```sh
ASYMPTOTIC_REPO=/path/to/Asymptotic wolframscript -file tests/run_native.wls
```

Or PowerShell:

```powershell
$env:ASYMPTOTIC_REPO = 'C:\src\Asymptotic'
wolframscript -file tests/run_native.wls
```

The wrapper prints observations; its zero exit code does not mean all
findings have been fixed. It does not verify the checkout pin, so confirm
`git rev-parse HEAD` before running. The patch emitter does verify it.

For the candidate's two focused desired-contract tests:

```wl
Get["/path/to/patched/AsymptoticAnalysis.wl"];
TestReport["/path/to/this/archive/tests/patch_acceptance.wlt"]
```

For the independent reference:

```wl
Get["/path/to/this/archive/code/NegativeLerchInterval.wl"];
Get["/path/to/this/archive/tests/reference_wl.wl"];
```

No Mathics command-line wrapper or Mathics success is asserted. Its first
acceptance task is to run the same held, exact public requests and classify
admission, failure, and result metadata on the actual selected Mathics version.

## Build the article

With pdfLaTeX and common TeX Live packages installed:

```sh
sh build.sh
```

No shell escape, network, external bibliography database, or distributed
font files are needed. The PDF contains embedded fonts. The delivered ZIP
excludes LaTeX intermediates, Python caches, and checksum files.

## Contents

`patches/` contains guarded review-only source edits; `code/` contains the
independent Lerch references; `tests/` contains executed Python tests and
native reproduction/acceptance scripts; `evidence/` contains actual test
records, exact mathematical data, and native connector transcriptions.
`findings.json` is a compact intake record. The article includes proofs,
source traces, limitations, priorities, and the cross-runtime acceptance plan.
