# AsymptoticInverse after nine reviews

A source-pinned delta audit of VladimirReshetnikov/Asymptotic, with a comparison
against native Wolfram Language operations.

**Audited commit:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6`  
**Native evaluator:** Wolfram Language 15.0.0 for Linux x86 (64-bit), May 6, 2026  
**Standalone successfully loaded:** 574,894 bytes

Read `article/audit.pdf`. The editable, self-contained LaTeX source is
`article/audit.tex`.

## Findings and attribution

| Identifier | Contribution | Classification |
|---|---|---|
| N01 | A relative-only inverse-certificate accuracy request stagnates at a fixed arithmetic enclosure order; absolute and explicit-order controls succeed. | Additional defect, not a false certificate. |
| N02 | `SeriesRefine` with a lower cutoff coarsens the returned approximation on both forward and inverse paths. | Additional API-policy observation, not invalid asymptotic mathematics. |
| Delta C07 | Exact nonreal constants are accepted by some public paths and rejected by another; concrete native acceptance matrix supplied. | Stronger evidence for an existing review concern. |
| Delta C04 | Native confirmation of the known nonlinear logarithmic-frontier defect; executed independent closed-frontier prototype. | Existing defect, implementation/evidence delta, not rediscovery. |

`evidence/novelty_ledger.json` records the baseline, targeted searches and exclusions.
The report does not reissue the existing broad feature roadmap.

## Evidence and validation

The distinction between observations and candidates is important:

* `evidence/native_observations.json` transcribes successful individual native
  evaluator results. It is not a raw complete kernel-session log. Failed remote
  service calls are not counted as mathematical outcomes.
* The independent Python prototype passed 13 test methods, including 40
  deterministic randomized comparisons against a separate polynomial oracle.
  `evidence/python_test_log.txt` contains the actual run output.
* The repository-wide native suite was **not** run. The complete new Wolfram
  reproduction runner and `DesiredBehavior.wlt` were not executed as aggregate runs.
* The external certificate adapter and source patch generator are experimental
  candidates. The complete candidates were **not natively validated**. The
  original package's explicit `"EnclosureOrder" -> 150` control did succeed.

See `evidence/patch_validation.json` for the artifact-level status.

## Run the independent prototype tests

Tested with Python 3.13.5 and SymPy 1.14.0:

```sh
python -m pip install -r requirements.txt
python -m unittest discover -s tests -p 'test_*.py' -v
```

`code/closed_frontier.py` uses exact `fractions.Fraction` weights and SymPy
polynomial coefficients. It is a deliberately limited prototype, not a port of
the entire Wolfram package. It assumes the supplied Taylor coefficients describe
an analytic function near zero. The article states and proves its error rule.

## Reproduce in a native Wolfram installation

With an audited standalone already available:

```sh
wolframscript -file code/reproduce.wl /path/to/AsymptoticInverse.wl
```

With no package argument, the runner downloads the pinned public standalone. It
writes `audit-native-results.json` in the current working directory and records
the actual package hash and kernel version. Supplying a different package version
is useful for regression comparisons but does not reproduce the pinned snapshot.
Each mathematical case has a 30-second evaluation limit. The download occurs
before those per-case limits.

To execute the proposed desired-behavior checks in a clean kernel:

```wl
Get["/path/to/AsymptoticInverse.wl"];
Clear[x, y, z, a];
TestReport["tests/DesiredBehavior.wlt"]
```

These tests specify intended repaired behavior. They intentionally do not all
pass against the audited original package. The N02 test expresses a proposed
monotonic-refinement policy rather than a mathematical theorem about the old API.

## Certificate workaround candidate

The external adapter leaves the original package's definitions unchanged:

```wl
Get["/path/to/AsymptoticInverse.wl"];
Get["code/AccuracyAwareCertificate.wl"];
s = AsymptoticInverse`AsymptoticInverse[x^2, {x, Infinity}, {y, 1}];
AsymptoticAudit`AccuracyAwareInverseCertificate[s, 2,
  "Interval" -> {1, 2}, "RelativeError" -> 10^-120,
  "MaxRefinements" -> 3, "RefineExpansion" -> False]
```

This complete adapter is an unvalidated candidate, not a promised drop-in fix.
It delegates every mathematical certificate to the original implementation and
only retries `AccuracyNotReached` failures with higher initial enclosure order.

## Generate an experimental source patch

```sh
python code/patch_certificate.py /path/to/Asymptotic \
  --output /path/outside/checkout/certificate-candidate
```

The generator checks pinned Git blob identities and unique source anchors. It
requires an empty or absent output directory outside the checkout. It writes
patched copies of the module and standalone, plus hashes; it does not modify the
repository or Git state. Integrate the module change in a development checkout,
rebuild the standalone using the repository's generator, and run the native suite
before considering the change validated.

## Rebuild the article

Run `./build.sh` on a POSIX system, or `./build.ps1` in PowerShell. Equivalently:

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error audit.tex
```

A TeX installation with NewPX, listings, tcolorbox, and the other packages named
in the preamble is required. No font files are distributed in this archive.

`CHECKSUMS.sha256` records the packaged files. Build intermediates, Python caches,
rendered inspection images, and the complete upstream repository are excluded.
