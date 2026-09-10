# AsymptoticAnalysis — incremental audit and Mathics assessment

Reviewed repository: https://github.com/VladimirReshetnikov/Asymptotic

Reviewed commit: `513917b5b387152256b14ac76d92dd30cd13a11d`.

Start with `article/asymptotic-review.pdf`. The editable source is
`article/asymptotic-review.tex`; it is self-contained and uses standard LaTeX
packages. Run `./build.sh` to rebuild the PDF.

## Results and evidence boundaries

N1: the portable runner resolves an existing Python executable path through
symlinks, which can escape a POSIX virtual environment. An actual environment-only
import witness reproduces the mechanism. The proposed fix preserves the invocation
path while making it absolute.

N2: the runner's nonpositive-timeout guard admits NaN, infinity, and extremely
large finite values. Real Python subprocess boundary failures were reproduced.
The candidate requires a finite value in `(0, 86400]` seconds. The one-day maximum
is an explicitly proposed CLI policy, not an existing repository requirement.

N3: the new Mathics FirstPosition adapter collects all positions. A symbolic
jetMerge consumer can make unnecessary equality-proof queries. Evidence here is
source analysis and an independent operation-count model, not Mathics timing.

N4: the new runner's captured diagnostics have no byte ceiling. A tested POSIX
prototype enforces output and time budgets. No real package out-of-memory event
was observed; this is a resource-boundary finding.

A1 and A2 are UNEXECUTED adapter audit candidates: the default limit-side policy,
and empty-list lookup paths outside the private-context Map workaround. Neither
is presented as a confirmed wrong public asymptotic formula or public crash.

The novelty screen used the consolidated crosswalks for 27 prior reviews and the
29-commit comparison from their latest baseline `6687962` to the pinned revision.
The relevant Mathics files and runner were added in that interval. This is not a
claim to have reread every full prior article. See `evidence/novelty_ledger.csv`.

## Executed checks

Twenty Python unittest methods passed on Python 3.13.5 / Linux. They cover path and
timeout helpers, source-fragment patch mechanics, and the bounded-process
prototype. Independent checks also cover exact affine signs, hypergeometric
coefficients, monomial order transport, and Stirling cutoff arithmetic.

**No fresh Wolfram or Mathics package execution succeeded in this review.** The
remote Wolfram evaluator connection failed, and no local Mathics/Wolfram runtime
was available. Upstream native validation is attributed separately in the article.
The package's full test suite was not run. The staged patch was NOT accepted
against a complete candidate checkout.

Run from this archive root:

```sh
python -m unittest discover -s code -p 'test_*.py' -v
python code/run_independent_checks.py --output evidence/reproduced_checks.json
```

The tests use the Python standard library only. POSIX subprocess tests are skipped
on other operating systems. The independent virtual-environment witness and the
bounded driver target POSIX; no Windows compatibility is asserted for them.

## Stage the narrow launcher fixes

```sh
python code/apply_runner_patch.py /path/to/Asymptotic \
  --output /tmp/asymptotic-patched-runner.py
```

The tool checks exact inspected source fragments and fails closed when they are
missing or duplicated. It writes a candidate plus a unified diff, never editing
the checkout in place. Transformation mechanics were tested on source-fragment
fixtures, not on a complete downloaded checkout.

Review and apply the resulting diff to a separate candidate checkout, then use
that checkout's normal validation command. Do not simply run the staged file from
`/tmp`: the repository runner resolves its companion suite relative to itself.

## Collect the unexecuted interpreter characterizations

Install/use the repository's pinned runtime, then on POSIX run, for example:

```sh
python code/run_runtime_probes.py \
  --source /path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl \
  --python /path/to/mathics-env/bin/python \
  --case first-position-count \
  --output evidence/mathics-characterizations.json
```

Omit `--case` to run all characterizations. Use `--wolfram /path/to/WolframKernel`
instead of `--python` for an official kernel. Repeat with the standalone entry
point when relevant. Use `--help` for timeout and output-budget controls.

**A complete characterization frame is NOT a mathematical acceptance pass.** The
scripts print results for inspection. They do not freeze a whole source checkout
or replace the repository's full provenance/acceptance machinery.

`code/first_position_candidate.wl` is an unexecuted, non-mutating prototype for a
flat-list first-match fast path. `code/bounded_process.py` is a tested POSIX
process-capture prototype, not a portable drop-in replacement or a security
sandbox; Windows requires separately tested process-tree handling.

## Contents

- `article/`: editable LaTeX and rendered PDF.
- `code/`: fixes, patch stager, unit tests, independent checks, characterization tools.
- `evidence/`: raw local results, source/scope map, and novelty ledger.
- `build.sh`: isolated LaTeX build that leaves auxiliary files outside the article directory.

No checksum files, interpreter environments, or font files are included.
