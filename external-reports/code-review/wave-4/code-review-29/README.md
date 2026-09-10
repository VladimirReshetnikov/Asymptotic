# AsymptoticAnalysis after the Mathics merge

Technical audit prepared for Vladimir Reshetnikov.

Repository: `VladimirReshetnikov/Asymptotic`  
Pinned commit: `7d1bc832895cc90a9b2a978b7b7684acab908bd2`  
Audit date: September 9, 2026 (America/Los_Angeles)

## Read first

`article/asymptotic-mathics-audit.pdf` is the compiled article. Its editable source is
`article/asymptotic-mathics-audit.tex`. The bibliography uses pinned repository
links and official Wolfram/NIST sources.

The review adds three reproduced portable-runner issues, a source-level
FirstPosition performance/semantic issue, a carefully scoped Limit adapter
observation, and two mathematical implementation proposals. Its novelty ledger
maps these against the existing review register rather than presenting old
findings as new.

No changes have been made to the upstream repository. The Python patch is a
candidate, not an accepted package change. No full Wolfram or Mathics test suite
was executed by this audit. One pinned-package Wolfram smoke test and native
Limit controls succeeded; further evaluator calls encountered service failures.

## Contents

- `article/`: article in LaTeX and PDF.
- `fixtures/run_mathics_tests.py`: byte-identical upstream runner used in tests.
- `fixtures/LICENSE-upstream.txt`: its upstream MIT No Attribution license.
- `patches/portable_runner.diff`: focused runner candidate, in ordinary git diff format.
- `patches/run_mathics_tests_candidate.py`: complete generated candidate.
- `code/make_harness_candidate.py`: regenerate candidate and diff; edits this bundle only.
- `code/test_harness.py`: six tests of original/candidate runner with fake kernels.
- `code/gamma_inverse_jet.py`: exact triangular and precision-doubling Gamma jets.
- `code/lambert_minus_one.py`: real W_-1 through the logarithmic branch-point excess.
- `code/test_mathematical_prototypes.py`: six exact/numerical tests.
- `code/native_smoke.wls`: reusable reconstruction of the successful native observations.
- `code/adapter_characterization.wl`: UNEXECUTED private-adapter regression specifications.
- `code/summarize_ci.py`: recalculate counts from the original retrieved CI receipts.
- `results/`: test output, independent numerical observations, novelty ledger,
  provenance, and six original GitHub Actions JSON receipts.

The retrieved CI receipts contain 69 successful completed records, covering 65
unique test IDs. Only two represented suites completed; the overall workflow
was cancelled. An interrupted receipt is not a passing suite. See the article's
CI table and `results/ci-summary.json` for exact denominators.

## Run the independent tests

Python 3.11+ is intended. Recorded local versions: Python 3.13.5, SymPy 1.14.0,
mpmath 1.3.0, Linux.

```text
python -m pip install -r code/requirements.txt
python code/make_harness_candidate.py
python code/test_harness.py
python code/test_mathematical_prototypes.py
python code/summarize_ci.py
```

The fake-executable process harness is POSIX-specific: use Linux or WSL for it.
It targets only subprocesses it creates. The mathematical tests are portable
Python and require neither Wolfram nor Mathics. Re-running tests replaces their
JSON files in this bundle; it does not alter a repository.

Six harness tests passed, including invalid timeouts `nan`, `inf`, `1e300`, finite
controls, dependency changes through `init.m`, explicit dependency roots, and a
real POSIX interruption of a fake child. These are runner tests, not mathematical
package acceptance. Windows interruption handling still needs separate testing.

Six mathematical tests passed. Gamma triangular and Newton coefficients agree
exactly through eighth order, with a separate fourth-order symbolic check and
numerical comparisons against the original log-Gamma equation. The W_-1 prototype
was tested at eight log-excess arguments including the branch point, 1e-60 and
1e6. It uses ordinary high-precision arithmetic, not directed rounding, and its
returned `certified` flag is deliberately false.

## Use the prototypes

From `code/`:

```python
from gamma_inverse_jet import newton
from lambert_minus_one import from_log_excess

coefficients, statistics = newton(8)
print([p.as_expr() for p in coefficients])

# Here z = -exp(-1-delta), and value = W_-1(z).
r = from_log_excess("1e-60", digits=70)
print(r.value)
print(r.correction)  # retain the tiny positive v in W_-1 = -1-v
print(r.certified)   # False: not an interval certificate
```

These are independent reference implementations. They do not implement the
repository's GeneralizedSeries schema or its full domain/remainder contract.
The Gamma prototype's cap is order 24, but correctness/benchmark execution here
reached order 8. No native speedup is claimed from its Python timings.

## Reproduce native observations

Set `ASYMPTOTIC_AUDIT_SOURCE` to a local pinned standalone `AsymptoticAnalysis.wl`
file and run `code/native_smoke.wls` in a fresh Wolfram kernel. The script does
not download anything. `results/native-observations.json` is a faithful manual
transcription of successful connector responses, not a raw exported log.

For `adapter_characterization.wl`, evaluate the package load before parsing the
subsequent test file. That file was NOT executed in this audit and does not
represent passing regressions.

## Rebuild the article

From `article/`:

```text
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-mathics-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-mathics-audit.tex
```

A third pass may be needed after changing tables or the table of contents.
Standard TeX Live packages including newpx, listings, xurl and hyperref are used.
No font files or checksum manifests are included. Original CI report fields
containing source identity information remain in the preserved test receipts.
