# Asymptotic — incremental source review at 8e859961d7d3

Read `article/review.pdf` or build `article/review.tex`.

## Retained additional item

**N01: exact-rational source seeds are outside the new Mathics exact-integer
root exception.** For an exact inverse such as `x = y`, the guarded numerical
check is predicted to refuse `y = 1/2` at the default working precision even
though substitution proves the root exactly. This is a conservative coverage
limitation, not a demonstrated wrong mathematical result. It follows the
precision-safety repair discussed under W4-02; it does not repeat a claim that
the new guard is absent.

The novelty screen used the maintained inventory for the 36 existing review
packages, the wave intakes, and relevant original material. It did not consist
of reading every page of every historical report. Other candidates were not
retained when already covered, contract-compliant, or insufficiently supported.

## Evidence boundary

30 independent Python unittest methods passed, with zero failures/errors.
Deterministic nested families are separately listed in the JSON receipt.
These are tests of a small rational-polynomial reference implementation, not
execution of the repository. No Wolfram or Mathics package run succeeded in
this review environment. The WL overlay and public probes are **unexecuted**.
The report makes no package speedup or native acceptance claim.

## Independent checks

From this directory, using Python 3.10 or later:

```sh
python code/run_reference_tests.py
```

Only the Python standard library is needed. The command rewrites the independent
receipts in `evidence/`; copy the delivered receipts elsewhere before rerunning
when preserving a comparison between environments.

`code/exact_seed_reference.py` checks exact polynomial equality at an exact
rational candidate with explicit input/work limits. Its JSON witnesses prove
point equality only, not uniqueness, branch identity, or package execution.
The module's Python binary-float conversion is not a WL `Rationalize` emulator.

## Unexecuted WL experiments

Use fresh baseline and candidate processes, not one session with both versions.
In a fresh kernel, set:

```wl
$AuditPackagePath = "/absolute/path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl";
$AuditPatchPath = None;
Get["/absolute/path/to/this/bundle/code/Probe.wl"];
```

Repeat in a separate Mathics process with `$AuditPatchPath` set to the absolute
path of `code/ExactSeedCandidate.wl`. The overlay is Mathics-only, modifies one
package-private helper, and leaves `System`FindRoot` untouched. It is an
experimental candidate, not a validated production hotfix. Re-loading the
package may replace the overlay. Do not use it to certify live research results
before the required integration tests pass.

`code/public_regressions.wlt` supplies desired public contracts. It assumes the
package is already loaded and needs a runner supporting that test format.
`code/Probe.wl` prints raw observations and intentionally does not claim acceptance
merely because it reaches the end.

## Article build

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
```

The delivered PDF was compiled, rendered, and visually checked. Source URLs in
the article use the immutable reviewed commit. No repository writes were made.

## Contents

- `article/`: compiled article and LaTeX source.
- `code/`: independent checker/tests, WL candidate, raw probe and MUnit specification.
- `evidence/`: independent execution records, exact equality examples, novelty ledger,
  source-coverage/evidence limits, and document preflight.
- `licenses/`: original source license and notice for the companion material.
