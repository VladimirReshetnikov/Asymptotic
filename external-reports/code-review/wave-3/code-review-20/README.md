# AsymptoticAnalysis: incremental repository review

Read `article/asymptotic-incremental-review.pdf`. Its self-contained LaTeX source is adjacent.

Reviewed repository: https://github.com/VladimirReshetnikov/Asymptotic

Pinned commit: `6687962f3c858a4f93623cfc496f33e35c6763d4`

Native audit runtime: **Wolfram Language 15.0.0, Linux x86-64 (May 6, 2026)**.

## Findings

The article reports three concrete native-confirmed runtime defects: ignored configured backend defaults, loss of metadata for a variable named `Method`, and automatic-route overprotection triggered by a fully applied identity function. Three narrow candidate groups were tested separately in modified complete standalones. It also reports a measured native-wrapper storage cost and a current README contradiction.

The novelty ledger identifies the precise deltas from the existing eighteen-review register. In particular, the storage measurement sharpens existing profiling recommendations rather than presenting them as new. The article does not reissue the old mathematical backlog as fresh findings.

## Evidence and limits

`evidence/native_observations.json` transcribes successful native connector observations. It is **not** an automated log of the packaged command-line scripts. The native package and three candidate groups were exercised through equivalent focused expressions.

The **combined five-edit candidate was not integration-tested**, the packaged fifteen-test desired-contract suite was not run as a complete suite, and the full upstream suite was not run. Candidate-group success is not release acceptance. Failed network/service attempts are not counted as package defects or built-in limitations.

Six independent Python mathematical tests and five patch-mechanics tests passed. Logs are included. The latter use explicit source-anchor fixtures, not a complete locally mounted upstream module. The native storage data are `ByteCount` observations, not peak memory or a leak; associated timings are cache-confounded and are not speed comparisons.

An initial exploratory `AsymptoticSolve` call used a bare dependent variable. It is excluded from capability conclusions. Corrected comparison attempts did not produce successful connector evidence. The article therefore does **not** claim that the built-in cannot invert the irrational-power example.

## Archive contents

- `article/`: PDF and buildable `.tex`.
- `code/characterize.wl`: baseline/candidate observation harness.
- `code/load_review.wl`: pinned download or explicitly selected local-source loader.
- `code/regressions.wlt`, `code/run_regressions.wl`: fifteen desired-contract tests and focused runner. Several should fail on the original baseline.
- `code/patch_rules.json`, `code/make_candidate.py`: narrow edits and a fail-closed generator for a pinned clean Git checkout. The checkout is not modified.
- `code/independent_oracles.py`: exact standard-library arithmetic over Q(sqrt(2)), forward support and generalized inverse-coefficient checks.
- `code/test_patch_mechanics.py`: five anchor-validation tests.
- `evidence/`: observations, source coverage, novelty mapping, executed Python logs and final QA.

The upstream repository and standalone package are not bundled.

## Run the independent checks

Python 3.10 or later, standard library only:

```sh
python code/independent_oracles.py
python -m unittest discover -s code -p test_patch_mechanics.py -v
```

## Native reproduction

Use a fresh Wolfram Language 15.0+ kernel. Loading downloaded or local WL code executes it; inspect the chosen source first.

```sh
wolframscript -file code/characterize.wl
wolframscript -file code/run_regressions.wl
```

Without an override the loader downloads the standalone at the pinned commit. To inspect a reviewed local baseline or candidate standalone:

```sh
export ASYMPTOTIC_AUDIT_SOURCE=/absolute/path/AsymptoticAnalysis.wl
wolframscript -file code/run_regressions.wl
```

PowerShell equivalent:

```powershell
$env:ASYMPTOTIC_AUDIT_SOURCE = 'C:\work\AsymptoticAnalysis.wl'
wolframscript -file code/run_regressions.wl
```

The loader records a local override but does not claim to verify that file's version. The scripts use fully qualified package symbols. Native output and timing may differ across kernels and machines.

## Produce a candidate module

Prepare a separate Git worktree at the reviewed commit, with a clean canonical target module. The generator refuses another commit, dirty target, missing or duplicated anchors, and an existing output directory.

```sh
python code/make_candidate.py /path/to/pinned/Asymptotic --out candidate
```

The new output directory contains `NativeCompatibility.wl`, a unified diff, and a provenance/status record. It does not change the checkout. Review/apply the diff in a separate worktree, regenerate the standalone with the upstream `validation/build_standalone.py`, and run the focused tests with that standalone.

The candidate has deliberate limits. N01 chooses independent `Backend` defaults for the two public entry points; it does not settle all alias/default-profile behavior. N02 repairs first-positional-specification metadata, not every argument-role decision in automatic dispatch. N03 narrows `Function` overprotection while retaining the existing inverse, conditional, explicit-direction and other restriction protections. No N04 optimization is implemented.

## Build the article

A standard TeX Live installation with the packages in the preamble is sufficient. No external bibliography database, external images, shell escape, or font-file distribution is needed.

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-review.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-review.tex
```

Run once more when LaTeX requests updated cross-references. The delivered PDF was compiled, rendered and visually inspected. Intermediate build files are not included.
