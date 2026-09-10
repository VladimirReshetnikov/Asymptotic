# AsymptoticAnalysis after eighteen reviews

A differential technical audit of VladimirReshetnikov/Asymptotic, pinned to
`6687962f3c858a4f93623cfc496f33e35c6763d4`.

Start with **article/audit.pdf** (25 pages). Its editable LaTeX source is
**article/audit.tex**. The review compares the current package with the official
Wolfram Language interfaces and concentrates on four new findings and two
substantive extensions of previously recorded issues.

## Principal findings

| ID | Finding | Evidence boundary |
|---|---|---|
| N01 | The held dispatcher ignores the advertised backend default when the caller omits an explicit selector. | Source-established; native regression unrun. |
| N02 | A recursive pure-function search mistakes an internal function or algebraic-root encoding for a callable-source contract. | Source-established classification; public probes unrun. |
| N03 | Structural option keys conflict with Wolfram's symbol/string/context option-name identity. | Source trace and official option contract; native regressions unrun. |
| D01 | Observable Taylor conversion omits the native endpoint check present in the forward path. | Mathematical wrong-remainder construction with a truthful short provider; native fixture unrun. |
| D02 | Refining an exact constant can unnecessarily request unavailable information from its uncertain ancestor. | Source trace and exact zero-demand argument; native regression unrun. |
| N04 | The README's final development-status paragraph contradicts implemented automatic routing. | Direct source/documentation comparison. |

D01 and D02 are **audit-local identifiers**, not the similarly named rows of
the repository's existing register. Their specific relationships to prior C06,
C16, C08, P07 and P08 are documented in the article and novelty ledger.

## Validation status

**48 independent Python test methods passed, with zero failures and zero errors.**
These exercise mathematical and contract models plus synthetic text-patch
fixtures. They are **not executions of the Wolfram package**. The native service
returned network/502 errors even for a minimal kernel probe. There was no
successful native baseline, patched package, regression-suite or benchmark run.
No native timing, memory advantage or package acceptance total is claimed.

The source was inspected through the connected GitHub service. This audit did
not obtain a complete local checkout. Exact patch anchors were compared with
the retrieved source ranges; automated patch tests used synthetic fixtures.
A real-checkout application and native integration check remain required.

The maintained crosswalk, both review indexes and selected directly relevant
original ledgers were read. This is not a claim to have independently verified
every sentence of all eighteen earlier articles. See evidence/review_scope.json.

## Archive contents

- `article/`: the article in PDF and LaTeX, with pinned source-line references and an embedded bibliography.
- `code/patch_snapshot.py`: candidate patch stager; twelve unique-anchor edits across three files, never applied to the input checkout.
- `code/native_regressions.wlt`, `fixtures.wl`: fifteen desired-behavior native test candidates, including positive controls and a separate short-provider precondition.
- `code/characterize.wls`, `benchmark_native.wls`: native observation and measurement harnesses, supplied but unrun.
- `code/audit_models.py`, `test_*.py`, `run_independent.py`: independent models, tests and evidence writer.
- `evidence/`: executed independent results, novelty/scope ledgers and explicit native-execution limits.

## Re-run the independent checks

Python 3.10+ and SymPy are required. The included environment record gives the
versions actually used. From this directory:

```sh
python -m pip install -r requirements.txt
python code/run_independent.py
```

The runner writes `evidence/independent_validation.json` and
`evidence/independent_checks.txt`. It returns a nonzero exit code on test failure.
The named methods, not their internal deterministic subcases, form the count of
48. An initial closing-delimiter typo in one synthetic assertion was corrected;
that change and the final execution are distinguished in the evidence history.

## Stage candidate changes against a real checkout

The repository must be at the audited commit, and the output directory must not
exist or be nested inside the input directory:

```sh
python code/patch_snapshot.py   --repo /path/to/Asymptotic   --out /path/to/asymptotic-audit-candidate
```

The stager checks the Git revision and every unique text anchor before creating
its output. `--no-git-check` is available only for an independently identified
archive; anchor validation remains mandatory. Inspect the generated differences
before use. The output contains the modular kernel and changed README, not a
complete release and not a regenerated standalone distribution. Native source
patches are candidates, not a drop-in accepted replacement.

The exact-derived fast path intentionally excludes native and nonordinary
representations and lower-cutoff requests that would remove retained blocks.
It validates the resource option first. The Taylor-order guard is deliberately
conservative and does not resolve the broader analyticity-admission obligation.
The backend-default patch resolves the canonical constructor's defaults; it does
not define an independently mutable default policy for the held alias.

## Native characterization and regressions

Run baseline and candidate in **separate fresh native kernels**:

```sh
wolframscript -file code/characterize.wls   /path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl baseline-native.json
wolframscript -file code/characterize.wls   /path/to/asymptotic-audit-candidate/src/Kernel/AsymptoticAnalysis.wl candidate-native.json
```

For the desired-behavior tests, load the selected modular entry and then use:

```wolfram
Get["/path/to/src/Kernel/AsymptoticAnalysis.wl"];
TestReport["/path/to/asymptotic_differential_audit/code/native_regressions.wlt"]
```

Several tests are expected to fail on the baseline. The D01 fixture-establishment
test must pass before its public-path observation can be interpreted. Review
messages, failures, aborts and timeouts, then run the upstream **focused** tests
for the affected components. These fifteen candidates are not an upstream
acceptance suite. No full package suite was run by this audit.

## Native measurements

The benchmark harness accepts an entry point, one of `NativeSeries`,
`ExplicitWrapper`, `AutomaticWrapper`, `ExactRefinement`, and an output path.
Check its header for the full invocation. Use a fresh process for every variant
and snapshot. End-of-batch memory differences are not peak memory. A quickly
failing baseline and a successfully refining candidate are not equivalent
successful workloads; do not present their timing ratio as a speedup.

## Build the article

A TeX distribution with pdfLaTeX, Latin Modern, microtype, amsmath, amsthm,
booktabs, longtable, tabularx, listings, xurl, hyperref and fancyhdr is required.
On a POSIX shell:

```sh
sh build.sh
```

The script compiles in a temporary directory and copies only the final PDF into
`article/`. Alternatively, run pdfLaTeX three times from `article/`; the
bibliography is embedded and does not require BibTeX. The included PDF was
compiled and visually inspected; changing fonts or TeX versions can change
pagination.

## Source and attribution

Repository source references are pinned to the audited commit. The patcher
contains limited upstream anchor text and replacement candidates; it does not
redistribute the entire upstream package. Preserve applicable upstream license
terms when integrating or distributing modified source. Existing external
reviews retain their own attribution and licenses; their articles and patches
are not copied into this archive.
