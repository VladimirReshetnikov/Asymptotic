# Asymptotic 1.8.0 — pinned-source audit

Reviewed repository: https://github.com/VladimirReshetnikov/Asymptotic
Commit: `07a9781212beb2eeb9ff16aa625b50ac27974078`
Review date: September 9, 2026.

Start with `article/article.pdf`. `article/article-standalone.tex` is a self-contained, independently compilable LaTeX copy. The editable source tree is `article/article.tex`,
`article/sections/*.tex`, and `article/sources.tex`. The article contains the
mathematical analysis, current official Wolfram comparison, 14 findings,
prioritized fixes, performance analysis, and development roadmap.

## Evidence boundary

**No native Wolfram kernel was successfully available during this review.**
The connected evaluator failed even on a version query. No package regression
or native/package benchmark was run for this audit.

Executed here:
- 42 independent Python/SymPy mathematical and allocation-planning checks.
- 6 patch-generator tests on synthetic fixtures.

Supplied but NOT executed:
- 15 Wolfram regression tests, including new corrected-behavior expectations.
- A native runner and a fresh-kernel benchmark harness.
- A proposed patch generator; it was not applied to a local repository checkout.

The repository's own 305-pass focused native validation is attributed in the
article and manifest. It is not our test run and is not a full-suite result.
The source-coverage ledger explicitly distinguishes inspected modules/ranges
from modules that were only inventoried or reached through documented interfaces.

## Main findings

A01: A nested observable can bypass the pure-remainder real-power branch guard.
A02: Eager native export allocates a dense rational lattice without a size cap.
A03: The native export loses explicit logarithmic remainder information. This
     limitation is already disclosed by the guide; the primary remainder is not
     claimed to be wrong. The patch proposes a deliberately stricter policy.
A04: Ambient assumptions can influence computations without being retained in
     the result. Fixing this requires context capture and isolation throughout
     the package, not only changing an option default.

A05–A14 cover release validation, resource budgets, cutoff semantics, schema
compatibility, certificate options, documentation integration, numeric evaluation,
operation closure, retained state, distribution, and license metadata.

## Reproduce the executed checks

Python 3.10+ is expected to suffice for the code; the recorded run used Python
3.13.5 and SymPy 1.14.0. Use an isolated environment when installing dependencies.

```sh
python -m pip install -r requirements.txt
python code/check_mathematics.py --output evidence/mathematical_checks.json
python -m unittest discover -s tests -p test_patch_planner.py -v
```

These checks do not emulate Wolfram evaluation. The billion-slot allocation
example is calculated as an integer count only; no enormous array is allocated.

## Generate a conservative source patch

Obtain a local checkout of the reviewed commit using your usual Git workflow.
The audit bundle does not contain a full repository checkout.

```sh
python code/propose_core_patch.py /path/to/Asymptotic > proposed_core.diff
```

The script verifies the LF-normalized canonical file against Git blob
`ea9eaf4a11130e922ac4fb3faae37fd8e8d29643` and unique source anchors. It fails
rather than guessing on another revision. By default it only prints a diff.
`--output /new/path/AsymptoticInverse.wl` writes a NEW proposed canonical file;
it refuses to overwrite. This file is not independently loadable without the
companion kernel modules.

The prototype addresses A01, A02 and A03 only. Its 20,000-slot cap is interim,
not full propagation of the request's resource budget. Its strict conversion
policy intentionally refuses some native exports that the existing guide allows.
It does not fix A04, implement lazy properties, or unify representation contracts.
Review and apply the diff in a separate branch, run native tests, and rebuild the
standalone distribution using the repository's own builder:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

Those last commands are run from the repository checkout, not the audit bundle.

## Native regression tests (future execution)

A local Wolfram Language 15.0+ kernel and local repository checkout are required.
Load the package before parsing the `.wlt` file. The supplied runner does this.
Run baseline and modified sources in separate fresh kernels and keep both reports.

POSIX shell, from this bundle:

```sh
export ASYMPTOTIC_AUDIT_ROOT=/path/to/Asymptotic
export ASYMPTOTIC_AUDIT_OUTPUT=/path/to/baseline_results.json
wolframscript -file code/run_audit.wls
```

PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_ROOT = 'C:\path\to\Asymptotic'
$env:ASYMPTOTIC_AUDIT_OUTPUT = 'C:\path\to\baseline_results.json'
wolframscript -file code/run_audit.wls
```

Set `ASYMPTOTIC_AUDIT_FULL_SUITE=1` to include all discovered repository `.wlt`
files. The runner records file hashes, kernel/platform, individual test details,
and whether sources changed. Empty or aborted suites fail. New A01/A02/A04 tests
may intentionally fail on the baseline. A03-strict is a proposed API-policy test,
not a claim that the existing authoritative remainder is incorrect.

## Native benchmarks (future execution)

Start one fresh kernel per case. The script performs one warm-up and three timed
samples, preserving the full outputs. Related native/package inputs are not
assumed equivalent; compare branches, complete blocks, carriers, and error
strength before interpreting speed ratios.

```sh
export ASYMPTOTIC_AUDIT_CASE=PackageQuadratic
export ASYMPTOTIC_AUDIT_OUTPUT=/path/to/benchmark_quadratic.json
wolframscript -file code/benchmark_audit.wls
```

Available cases are listed in `code/benchmark_audit.wls`. An invalid or absent
case name prints the list and exits without running a benchmark.

## Rebuild the article

A standard LaTeX installation is required. No custom font files are needed.

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The metadata/reference generator is `build_metadata.py`; running it recreates
`sources.tex` and the structured audit ledgers. The PDF layout has been rendered
and inspected. The QA report in `evidence/pdf_qa.json` is about the document,
not about the Wolfram implementation.

## Provenance and notices

`evidence/references.json` contains primary-source references. Every repository
reference is pinned to the reviewed commit. Official Wolfram/NIST/SPDX pages
were consulted as of the review date, not treated as executed benchmark results.
`SHA256SUMS` identifies files in this delivered bundle.

The root repository license is MIT No Attribution (MIT-0); its paclet metadata
says MIT, a discrepancy discussed under A14. The repository's actual license
text is reproduced in `UPSTREAM_LICENSE.txt` for the small code anchors used in
the patch planner. No entire upstream module or font file is bundled.

All proposed code is supplied for review and testing, without a correctness or
fitness warranty. The package's authorship is not attributed to this audit.
