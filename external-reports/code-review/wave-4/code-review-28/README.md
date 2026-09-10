# AsymptoticAnalysis: differential technical audit

Reviewed repository: https://github.com/VladimirReshetnikov/Asymptotic

Pinned commit: `7d1bc832895cc90a9b2a978b7b7684acab908bd2`.
The commit timestamp is September 10, 2026 at 02:10:22 UTC, corresponding to
September 9, 2026 at 19:10:22 in America/Los_Angeles.

Read `article.pdf` or edit `article.tex`. The article compares the package with
Wolfram built-ins, examines its Mathics 10.0.1 compatibility layer, and separates
new findings from the maintained inventory of earlier reviews.

## Evidence and scope

**25 independent Python tests passed. No Mathics or official Wolfram package
execution was performed in this session.** Runtime access attempts were
unsuccessful. Existing repository test receipts are attributed to their own
source revisions in the article, not presented as new test runs.

The independent tests cover exact logarithm bounds, rational inverse
certificates, certificate mutation rejection, affine deleted-neighborhood
proofs, terminating hypergeometric coefficients, timeout validation, capped
process output, process timeout, UTF-8, exit codes, launch failure, an edit/revert
countermodel, and Git-object snapshots unaffected by working-tree edits.

The Wolfram-language programs are **unexecuted characterizations**, not passing
regressions or a validated patch. A completed probe only means that the selected
program produced its completion marker. Interpret the returned value according
to the article and the primary language contracts.

## Contents

- `article.tex`, `article.pdf`: the technical article and editable source.
- `code/certified_entropy_inverse.py`: exact rational certificates for the small
  inverse of `-x log(x)` for rational targets `0 < y <= 1/4`.
- `code/exact_portability_prototypes.py`: rational affine eventual-radius
  synthesis and finite terminating generalized hypergeometric coefficients.
- `code/bounded_process.py`: a bounded-output **POSIX-only** process supervisor.
- `code/run_audit_probes.py`: fresh-kernel driver using package blobs read from
  a pinned Git commit, not a mutable working tree.
- `code/PortabilityProbes.wl`: eight runtime characterization probes.
- `code/audit_checks.py`: the executed independent test suite.
- `evidence/`: actual independent execution evidence, the exact certificate,
  mpmath countermodel, and novelty/source-scope records.
- `build.sh`: rebuilds the PDF using a local LaTeX installation.

These are reference prototypes, not a replacement distribution of the package.
No repository file was edited. The archive does not include third-party source
copies or checksum files.

## Independent test run

Python 3.11 or later is recommended; the recorded run used Python 3.13.5 on
Linux. The test suite needs Git and mpmath 1.3.0. The exact certificate and
coefficient algorithms themselves use only the Python standard library.

```sh
python -m pip install mpmath==1.3.0
cd code
python audit_checks.py
```

The tests update `evidence/independent-checks.json`. To record a fresh transcript,
redirect stdout/stderr to a separately named file rather than confusing a new
run with the evidence shipped here.

## Exact inverse certificate

```sh
python code/certified_entropy_inverse.py 1/100 --bits 80 --output certificate.json
```

The width request applies to the **source x interval**, not the Lambert W
interval. Both widths are reported. The verifier independently rechecks branch
bounds, endpoint residual signs, and source width using rational arithmetic.
It is not a general hostile-JSON importer or a proof-assistant formalization.
Explicit iteration/order caps can cause refusal; no unproved sign is used.

## Mathics or Wolfram characterizations

Obtain a local checkout containing the reviewed commit and install the desired
runtime independently. The driver does not fetch or install anything.
On POSIX:

```sh
python code/run_audit_probes.py /path/to/Asymptotic \
  --mathics-python /path/to/venv/bin/python \
  --entry modular --output mathics-probes.json

python code/run_audit_probes.py /path/to/Asymptotic \
  --wolfram /path/to/WolframKernel \
  --entry standalone --output wolfram-probes.json
```

`--wolfram` expects a kernel executable, not `wolframscript`. The probe supervisor
is not a Windows implementation. A Windows port must separately validate its
owned-process-tree termination and pipe handling.

Use `--case` to select a probe:

```
root-precision
public-numerical-precision
core-negative-lambert
limit-default
first-position-options
first-position-predicate-count
affine-small-radius
terminating-pfq
```

The modular snapshot includes regular `.wl` blobs under `src/Kernel` from the
selected commit. The standalone snapshot uses its committed root entry. The
synthetic Git test verifies these snapshot mechanisms, not real package loading.
Read-only mode bits prevent ordinary accidental writes, not malicious same-user
modification. This is a reproducibility mechanism, not a security sandbox.

## PDF build

A TeX Live installation providing the packages listed in `article.tex` is needed.
Run `./build.sh` from the extracted directory. No network service is required.
