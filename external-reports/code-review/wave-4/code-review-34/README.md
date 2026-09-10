# AsymptoticAnalysis — incremental review and Mathics semantic audit

Reviewed revision: `7d1bc832895cc90a9b2a978b7b7684acab908bd2`  
Review date: September 9, 2026 (Pacific time).

Read **`article/asymptotic-review.pdf`**. Its complete editable source is
`article/asymptotic-review.tex`; the PDF is 32 pages. The report compares the
package with native Wolfram Language, explains six incremental finding groups,
assesses the Mathics adapter contracts, and develops an exact-rational reference
for the real minus-one Lambert branch.

## Findings

| ID | Main contribution | Evidence |
|---|---|---|
| R1 | ProductLog exact/reverse argument conversion and inherited numerical arity, beyond the already documented nonprincipal numerical limitation | Tagged source trace; independent SymPy/mpmath witnesses. Package characterization remains unexecuted. |
| R2 | The portable runner forgets a source change it already detected; its copied test suite is unchecked | Exact upstream runner executed against synthetic protocol processes; candidate repairs tested. |
| R3 | Invalid floating-point deadlines reach subprocess timing APIs | NaN, infinity, and huge finite values reproduced; candidate rejects before launch. |
| R4 | Workflow path filters omit direct command dependencies | Source-level dependency analysis and independent case-sensitive pattern checks. |
| R5 | Degree-sized densification in sparse coefficient/amplitude paths; all-match FirstPosition implementation | Structural cost analysis and sparse support counts, not Mathics timing benchmarks. |
| R6 | Private Limit adapter's omitted direction is left-sided, unlike native default | Source and mathematical counterexample; current public wrong-result reachability not established. |

Novelty was screened against the maintained 27-report / 167-entry register and
third-wave intake, not by claiming to reread every previous PDF. All 15 new
Mathics adapter modules were read; shared engines were inspected at the targeted
consumers listed in `evidence/source-coverage.json`. The new portability modules
and runner postdate the third-wave source snapshot. R1 and R5 explicitly identify
the additional insight relative to known limitations or earlier performance work.

## Execution scope

**22 Python unittest methods passed:** ten runner tests, nine independent
semantic/mathematical tests, and three synthetic-source staging tests.

These are **not 22 package tests**. No Wolfram or Mathics kernel successfully
executed the package during this review: an official evaluator connection failed,
and Mathics installation was unavailable in the isolated runtime. All WL probes
and the sparse WL helper are explicitly marked unexecuted. Historical repository
receipts remain historical evidence, not a current acceptance run.

The test runner children are intentionally identified synthetic Python protocol
processes. They test the real upstream Python runner's state and subprocess
handling, not the mathematical package. See the preserved observations and logs
under `evidence/`.

## Python reproduction

Use Python 3.10 or later. The supplied results were obtained with Python 3.13.5
on Linux, SymPy 1.14.0, and mpmath 1.3.0.

```sh
python -m pip install -r code/requirements.txt
python code/test_independent.py
python code/test_productlog_staging.py
python code/test_runner_audit.py
```

The subprocess reproduction currently targets POSIX/Linux (its synthetic launcher
uses an executable shebang). Run it under Linux or WSL for the recorded trace;
this is not a claim of a tested Windows synthetic harness. The upstream runner
itself includes Windows handling, which is unchanged by the focused candidate.
The other independent tests do not require POSIX process launch behavior.

To stage the runner repair into a separate file:

```sh
python code/stage_runner_patch.py \
  fixtures/run_mathics_tests_upstream.py \
  candidate/run_mathics_tests.py
```

The candidate expects the original repository validation layout when actually
used with a kernel. This staging command is for diff review; placing the runner
alone in `candidate/` is not a complete runnable package checkout.

`code/stage_productlog_patch.py SOURCE DESTINATION` stages candidate bridge methods
into a copy of Mathics's `expintegral.py`. The candidate has **not** been
integration-tested in Mathics. It does not implement all ProductLog behavior,
derivatives, or invalid-branch policy, and never modifies an installation itself.

## Exact-rational branch reference

From `code/`:

```python
from fractions import Fraction
from lambert_certificate import enclose_lambert_minus_one

c = enclose_lambert_minus_one(Fraction(1, 100), bits=40)
assert c.verify()
print(c.w_interval)                       # encloses W_{-1}(-1/100)
print(c.small_entropy_inverse_interval)   # small x: -x log(x) = 1/100
```

This implementation uses rational logarithm enclosures and exact bisection, not
floating-point special functions. The article proves the enclosure and branch
selection. It is an independent reference, not a package monkey patch or a
formally verified library. Requested bits specify absolute W-interval width.

## Remaining kernel characterizations

Set `ASYMPTOTIC_REVIEW_SOURCE` to the pinned package entry file and
`ASYMPTOTIC_REVIEW_CASE` to one of the Switch labels in `code/ProbeReview.wl`.
For example, in PowerShell from this archive root:

```powershell
$env:ASYMPTOTIC_REVIEW_SOURCE = (Resolve-Path ..\Asymptotic\src\Kernel\AsymptoticAnalysis.wl).Path
$env:ASYMPTOTIC_REVIEW_CASE = "core-real-branch"
python -m mathics --quiet --no-readline --file .\code\ProbeReview.wl
```

Run each case in a fresh process with an external timeout. The driver prints
observations rather than asserting an unobserved success. For standalone parity,
repeat with the repository-root `AsymptoticAnalysis.wl` entry file. An official
kernel can use its `-noinit -script` interface with the same driver.

## Files and licensing

`article/` contains the PDF, complete TeX source, and build script. `code/` contains
tests, candidates, the rational reference, and unexecuted kernel probes.
`fixtures/` contains the exact pinned upstream runner. `evidence/` contains
executed observations, logs, scope, novelty ledger, and source coverage.

The new article/code and the upstream runner fixture are supplied under the
MIT No Attribution terms described in `LICENSE.txt` and `NOTICE.md`.
No interpreter binaries, font files, full repository snapshot, or checksum files
are included. The runner's existing hashing code remains in its exact fixture.

Build the PDF using `bash article/build.sh` (pdfLaTeX with New PX text/math and
standard packages). The source is self-contained and does not download assets.
