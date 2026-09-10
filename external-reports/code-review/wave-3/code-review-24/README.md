# AsymptoticAnalysis: incremental technical audit

**Reviewed revision:** `6687962f3c858a4f93623cfc496f33e35c6763d4`  
**Report date:** September 9, 2026 (Pacific time)  
**Successful native observations:** Wolfram Language 15.0.0, Linux x86-64.

Start with **article/audit.pdf**. The self-contained LaTeX source is **article/audit.tex**.

## Findings

N01: backend defaults set on the public entry do not control dispatch; the alias also has a default-ownership issue. N02: a computed `"Backend"` option key is rejected while a literal key or computed option container succeeds. N03: a reciprocal-square Lerch expansion unnecessarily loses ordered arithmetic despite a retained positive branch. F01: a separately reproduced Fourier-helper resource failure extends the earlier P03 homogeneous-recurrence finding; it is not claimed as discovery of that general principle.

The article compares the current package with `Series`, `SeriesData`, `InverseSeries`, `Asymptotic` and `AsymptoticSolve`. It includes a nonduplication crosswalk against the register of 123 entries in eighteen earlier reviews, mathematical derivations, fixes and bounded development proposals.

N01--N03 and F01 are local audit identifiers, not the maintained register's numbering.

## What was and was not executed

`evidence/native_observations.json` is a **manual transcription of selected successful tool results**, not a complete automatic kernel log. Native baseline observations support the four findings at their explicitly stated scopes. The canonical backend patch and Fourier patch were each exercised on separate temporary standalone distributions. A restricted positive quadratic-chart mechanism was exercised. The computed-key candidate received an isolated language-mechanism check, **not** a successful full-package patched run.

`code/independent_checks.py` ran locally: **21 test methods passed**. These are exact mathematics, an independent recurrence/cost model and synthetic textual-patch fixtures. They do not execute or emulate the Wolfram package.

The complete supplied observation runner, desired-contract test file, combined candidate and quadratic pilot installer lifecycle were **not** executed as integrated artifacts. Failed network/service calls are not characterized as package failures. No full-suite or all-platform acceptance result is claimed. No new false analytic remainder is claimed.

## Contents

- `article/`: PDF and self-contained LaTeX article.
- `code/stage_patches.py`: uniquely anchored, non-in-place staging of three separately selectable candidates.
- `code/QuadraticChartPilot.wl`: restricted domain-checked reciprocal-square pilot for disposable kernels.
- `code/run_observations.wl`: baseline/candidate observation runner.
- `code/desired_contracts.wlt`: desired-contract regression specifications; some intentionally fail on the baseline.
- `code/independent_checks.py`: executed exact-model and fixture checks.
- `code/corpus_screen.py`: network-enabled reproduction of the lexical review-corpus screen.
- `evidence/`: native observations, novelty record, source references and actual independent-check output.
- `licenses/`: upstream MIT-0 notice for source-derived excerpts.

The archive contains no checksum files, separate font files, upstream source checkout or copied historical report archive.

## Build the article

Run twice, from `article/`:

```sh
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
```

## Reproduce selected observations

Use a **fresh Wolfram kernel**. From the extracted archive root:

```wolfram
Get["code/run_observations.wl"]
```

The runner downloads the pinned standalone by default and writes `observations.json` in the current directory. Network access to GitHub is required. To use an existing local baseline or staged candidate:

```wolfram
$AuditPackagePath = "/absolute/path/AsymptoticAnalysis.wl";
$AuditOutputPath = "/absolute/path/candidate-observations.json";
Get["code/run_observations.wl"]
```

Keep baseline and candidate in different fresh kernels. This avoids stale definitions and option defaults. The runner records observations; it is not an aggregate release acceptance suite.

## Stage candidates

Supply an independently obtained copy of the pinned standalone. The original file is never modified:

```sh
python code/stage_patches.py \
  --source /path/to/pinned/AsymptoticAnalysis.wl \
  --output /tmp/AsymptoticAnalysis-candidate.wl \
  --patches backend-default fourier-termination \
  --diff /tmp/candidate.diff
```

The `backend-default` candidate repairs the **canonical selector only**; it does not resolve alias ownership for all exposed defaults. `computed-keys` is separately selectable and is less validated. The combined staged file has not been validated merely because its anchors matched.

For production integration, modify the canonical modular sources, regenerate the standalone with the repository's builder, then run the relevant native acceptance files. Do not treat edits to the generated standalone alone as a maintained upstream repair.

## Quadratic-chart pilot

In a disposable kernel, load the package first, then:

```wolfram
Get["code/QuadraticChartPilot.wl"];
AsymptoticAudit`InstallQuadraticChartPilot[];
(* Run the reciprocal-square witness or desired chart tests. *)
AsymptoticAudit`UninstallQuadraticChartPilot[];
```

The pilot modifies private DownValues and is not a public extension API. Do not make intervening changes to the saved function definitions before restoration. The positive mechanism was checked; the complete lifecycle and negative native branch require testing.

## Independent checks and corpus screen

```sh
python code/independent_checks.py --output evidence/model_checks.json
python code/corpus_screen.py --output /tmp/corpus-screen.json
```

The first command needs only Python's standard library and was executed in this audit. The second needs network access. Its lexical result cannot prove semantic novelty. The audit's successful corresponding Wolfram screen found no literal matches for its six stated terms in 45 non-standalone TeX files.

## Notices

This is an independent review, not a maintainer-endorsed release or verified replacement package. Source-derived snippets retain their upstream MIT No Attribution terms, copied under `licenses/`. Candidate code should be reviewed and tested before integration.
