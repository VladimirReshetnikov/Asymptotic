# Asymptotic — correctness, contracts, and engineering audit

**Reviewed repository:** VladimirReshetnikov/Asymptotic  
**Pinned commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Package version:** 1.8.0  
**Review date:** 9 September 2026

Read `article/article.pdf`; its self-contained LaTeX source is `article/article.tex`.
The article compares the package with documented Wolfram Language facilities,
explains the mathematical contracts, provides a 16-entry findings registry,
and proposes a staged development plan. The coverage appendix distinguishes
source ranges actually inspected from modules only inventoried or assessed
through dispatch and public descriptions.

## Evidence boundary

This is a source audit with independent mathematical and Python-tool checks.
The native Wolfram connector returned HTTP 502 errors, and no local native
kernel was available. **The package, proposed Wolfram changes, native tests,
and native benchmark harness were not executed in this review.**

Executed here: 16 independent Python/SymPy mathematical checks and seven
Python audit-tool unit tests, all passing. Those are NOT Wolfram package tests.
The repository's latest focused record reports 305 passing native tests from
18 selected files; that result is quoted, not reproduced. That milestone
explicitly says the full package suite was not run.

The included code is not a fully patched or newly validated distribution.
No remote repository was changed. The full upstream repository is not included.

## Most actionable findings

A01: ordinary construction eagerly attempts dense `SeriesData` export.
Two retained sparse blocks can imply a billion coefficient slots; the span
is derived without allocating the billion-slot array.

A02: both classical exporters omit the rich remainder's logarithmic degree.
This is loss of the package's magnitude-bound metadata, not a claim that
native formal `SeriesData` conventions are inherently incorrect.

A03: the object coefficient wrapper puts an inherited `"Power"` before
explicit options. Resolve the policy: honor an explicit override or reject
it as conflicting; do not silently shadow it.

A04: generic operation replay uses a fixed precision margin. The product
`Exp[x] x^-100` illustrates why refining to output error exponent 5 needs
input exponential precision 105, not 7. The source-derived concern is an
unmet refinement goal, not fabricated coefficients or an invalid returned bound.

Additional findings cover canonicalization cost, resource-budget semantics,
native CI and empty-suite gates, scale-dependent cutoff meanings, unchecked
approximate evaluation, schema migration, documentation, and longer-term
analytic extensions. See `evidence/findings.csv` and the full article.

## Contents

- `article/`: LaTeX source and compiled PDF.
- `code/independent_checks.py`: executed independent mathematical checks.
- `code/AuditSupport.wl`: unexecuted proposed Wolfram helpers; no upstream overrides.
- `patches/make_export_patch.py`: source-pinned conservative A01/A02 patch generator.
- `tests/`: Python tool tests and unexecuted native regression suites/runner.
- `benchmarks/CompareBuiltins.wls`: unexecuted native timing/output harness.
- `evidence/`: actual independent results, status, findings, coverage and provenance.
- `UPSTREAM-LICENSE.txt`: upstream license for the included source excerpts.
- `LICENSE-AUDIT-CODE.txt`: license for newly supplied code.
- `SHA256SUMS`: checksums of delivered files other than the checksum list itself.

The excerpt `evidence/exporters_excerpt.wl` is NOT a complete loadable package.
It is an exact source fixture used by the Python patch-transformation tests.

## Reproduce the independent checks

Python 3.10 or later is appropriate for the supplied Python code; the actual
review used Python 3.13.5 and SymPy 1.14.0. Install the dependency in a virtual
environment using `python -m pip install -r requirements.txt`, then run from
this archive's root:

```sh
python code/independent_checks.py
python -m unittest discover -s tests -p 'test_python_tools.py' -v
```

The mathematical checker writes `evidence/independent_checks.json`.
The committed test log records the actual review run.
These tests do not parse or execute Wolfram semantics.

## Obtain a separate pinned upstream checkout

The archive's scripts do not fetch or evaluate remote code. In a separate
working directory with Git and network access, an explicit acquisition is:

```sh
git clone https://github.com/VladimirReshetnikov/Asymptotic.git
cd Asymptotic
git checkout --detach 07a9781212beb2eeb9ff16aa625b50ac27974078
```

Keep that checkout separate from the audit archive. The modular kernel is
canonical; the root `AsymptoticInverse.wl` is generated from it.
The upstream paclet declares Wolfram 15.0+.

## Review the conservative patch

Default mode prints a unified diff and changes nothing:

```sh
python patches/make_export_patch.py /path/to/Asymptotic/AsymptoticInverse/Kernel/AsymptoticInverse.wl
```

The script checks the expected Git blob identifier after LF normalization.
It refuses changed source, missing expected definitions, or a repeated patch.
Only after reviewing the diff, use `--in-place` to create a backup and
atomically replace that canonical core file:

```sh
python patches/make_export_patch.py /path/to/Asymptotic/AsymptoticInverse/Kernel/AsymptoticInverse.wl --in-place
```

This patch adds a fixed 200,000-slot dense guard and a conservative refusal
of logarithmic-tail export. It does not implement lazy export, fix A03/A04,
or constitute a native-validated release. From the upstream repository root,
regenerate the standalone file and run its builder checks:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

Then run native regression tests for both the modular and standalone versions.

## Native suites: supplied, not executed

`Baseline.wlt` checks intended baseline behavior. `Support.wlt` exercises the
proposed namespaced helpers. `ProposedContracts.wlt` encodes desired A01–A04
behavior and is **not a claimed passing suite for unmodified upstream**.
The A03 test chooses explicit-option precedence; rejecting a conflicting
option is a different defensible policy discussed in the article.

In a POSIX shell:

```sh
export ASYMPTOTIC_PACKAGE=/path/to/Asymptotic/AsymptoticInverse.wl
wolframscript -file tests/RunAudit.wls
export ASYMPTOTIC_AUDIT_SUITE=Proposed
wolframscript -file tests/RunAudit.wls
```

In PowerShell:

```powershell
$env:ASYMPTOTIC_PACKAGE = 'C:\path\to\Asymptotic\AsymptoticInverse.wl'
wolframscript -file tests/RunAudit.wls
$env:ASYMPTOTIC_AUDIT_SUITE = 'Proposed'
wolframscript -file tests/RunAudit.wls
```

The default selection is Baseline plus Support. `All` includes all three suites.
The runner writes `evidence/native-audit-results.json` only when executed.
Its source-file hash identifies the selected entry point; it is not an
all-module attestation for a modular checkout. It records the actual kernel
version and platform and rejects an empty executed suite.

The helper `InverseCoefficientForPower` works on ordinary power–log inverse
models only. It resolves a source-observable power before the internal
source-infinity sign conversion. `RequiredProductPrecision` supplies necessary
power demands, not a complete logarithmic/composite precision planner.

## Native comparison benchmark: supplied, not executed

With `ASYMPTOTIC_PACKAGE` set:

```sh
wolframscript -file benchmarks/CompareBuiltins.wls
```

Optional `ASYMPTOTIC_BENCHMARK_REPEATS` is an integer from 1 to 20 (default 3).
The harness writes `evidence/builtin-benchmarks.json` only when run.
It includes per-evaluation memory/time limits and records outputs, messages,
operation-cold timing, warm timings, result sizes and extraction time.
Clearing the symbolic cache is not a fresh-process cold start. Match branches,
retained terms and achieved remainder contracts before calculating speedups;
equal integer order arguments do not ensure an equal comparison.

## Build the article

Install a LaTeX distribution containing Latin Modern, microtype, geometry,
AMS math packages, booktabs, longtable, listings, enumitem, xurl, hyperref,
and fancyhdr. No upstream checkout is required to build the document.
Run `sh build.sh`, or:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

No font files are distributed in this archive. Bibliography links point to
the pinned upstream source and official Wolfram documentation.
