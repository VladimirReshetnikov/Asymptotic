# AsymptoticAnalysis after the third review wave

Review of VladimirReshetnikov/Asymptotic at commit
`513917b5b387152256b14ac76d92dd30cd13a11d`.
Review date: September 9, 2026, America/Los_Angeles.
The commit timestamp is September 10, 2026, 02:16 UTC (September 9, 19:16 PDT).

Start with **article.pdf**. **article.tex** is its complete editable source.
The article compares Wolfram built-ins fairly, screens new findings against the
existing review registers, evaluates the Mathics adapters, and gives explicit
fixes, mathematical derivations, evidence boundaries and acceptance conditions.

## Evidence boundaries

**Executed:** the actual pinned upstream Python runner with seven controlled,
protocol-only fake-kernel fixtures; a sticky invalidation patch for that runner;
independent exact rational and SymPy/mpmath mathematical oracles; immutable Git
source staging in a synthetic local repository.

**Not executed:** any fresh Wolfram or Mathics evaluation of the Asymptotic
package, the full package suite, or the supplied Wolfram Language prototypes.
The Wolfram execution service was unavailable and no usable Mathics interpreter
was available. The report does not turn those unavailable tests into passes.

There are **two reproduced validation-runner defects**, source-level Mathics
risk/resource findings, and a constructive Taylor extension. Do not interpret
these as six newly reproduced mathematical package bugs. In particular the
lower-Lambert public call is a source-traced candidate, not a recorded Mathics
package result. The documented upstream ProductLog issue is not claimed as new.

## Files

- `article.tex`, `article.pdf`: complete review and primary references.
- `code/reproduce_runner.py`: seven tests of the exact pinned Python runner.
- `code/runner_sticky_flag.patch`: tested narrow repair for F1 only.
- `code/stage_git_sources.py`: stages the known WL layout from immutable Git
  objects, not the working tree; refuses to overwrite an existing destination.
- `code/reproduce_staging.py`: reruns the synthetic immutable-staging fixture.
- `code/exact_oracles.py`: exact rational enclosures for exp(x)/x on x>1,
  hypergeometric coefficients and uniform tails, and independent backend controls.
- `code/TargetedProbes.wl`: **UNEXECUTED** characterizations of package/helper
  behavior. Not a self-certifying acceptance suite.
- `code/CandidateAdapters.wl`: **UNEXECUTED** sparse collector and numerical
  capability guard in their own context. Not installed into System or the package.
- `evidence/*.json`: actual observations, source index and finding-status ledger.
- `upstream-excerpts/run_mathics_tests.py`: exact pinned runner used by fixtures.
- `upstream-excerpts/LICENSE`: original upstream MIT No Attribution license.

No checksum files are included. The retained upstream runner uses source digests
internally; temporary full reports produced by its fixtures are removed. The
supplied selected observations are not checksum manifests.

## Run the executed experiments

Python 3.11+ is appropriate for the infrastructure code. The recorded mathematical
run used Python 3.13.5, SymPy 1.14.0 and mpmath 1.3.0. To reproduce that dependency
pair in a local environment:

```sh
python -m pip install -r requirements.txt
python code/reproduce_runner.py
python code/reproduce_staging.py
python code/exact_oracles.py
```

The runner fixture requires Linux, macOS or WSL because its fake executable uses
a POSIX shebang. It starts **no genuine Wolfram or Mathics kernel**. The staging
fixture needs Git. The oracle script makes all enclosure decisions with rational
arithmetic; floating-point values are cross-checks, not certificate decisions.
These commands overwrite their corresponding observation JSON files.

The sticky patch stops an observed source mismatch from becoming valid again.
It does **not** repair omitted dependencies, preserve every first-mismatch detail,
or detect an unobserved change-and-restore between snapshots. Read F1/F2 before
using it as an evidence-integrity fix.

## Stage actual repository sources

A local checkout must contain the exact requested commit:

```sh
python code/stage_git_sources.py /path/to/Asymptotic \
  513917b5b387152256b14ac76d92dd30cd13a11d \
  /path/to/new-snapshot --mode modular
```

The entry is `new-snapshot/Kernel/AsymptoticAnalysis.wl`. Standalone mode selects
the generated root entry. This is a known-layout staging utility, not a general
dependency resolver or a security sandbox. It modifies no repository files and
performs no network actions.

## Run the unexecuted WL probes

Set `ASYMPTOTIC_AUDIT_SOURCE` to a pinned entry and stream the probe file in an
actual interpreter, with an external process timeout and complete output capture.
Use a new process for baseline and candidate work. Do not pre-parse `Get` and
unknown package names together in one command string. The probe file does not
automatically load `CandidateAdapters.wl`.

A safe unsupported-numerical-capability refusal is different from full support,
and also different from a wrong complex value for an intended real inverse.
The article explains the expected distinctions. No high-precision printed
value is a certificate merely because many digits are present.

## Build the article

A standard TeX installation with pdfLaTeX and the packages named in the preamble
is sufficient. Run from this directory:

```sh
make article.pdf
```

The bibliography is embedded in the TeX source; BibTeX and network access are not
required. `make clean` removes intermediate TeX files, not the PDF or evidence.

## Licensing and provenance

The copied upstream runner retains its original license alongside it. The new
review text and accompanying original code are made available under the MIT No
Attribution license in this archive's `LICENSE`. This does not replace licenses
of external primary sources linked by the article.

No patch was applied to the user's GitHub repository. No full repository archive,
font files, or checksum files are included.
