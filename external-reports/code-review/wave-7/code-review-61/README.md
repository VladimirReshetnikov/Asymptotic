# Asymptotic: exact predicates and Hermitian coefficient arithmetic

Reviewed revision: `efa1aeec4845a9c35e140963a0333d0c9ec33b05`  
Review date: 10 September 2026

Start with `article/asymptotic-review.pdf`. The editable source is
`article/asymptotic-review.tex`.

## Results and evidence

**N01 — a reproduced public correctness failure.** The shared
`inverseFunctionConditionOnJet` helper uses the finite coefficients of an
approximation as an exact `Element[..., Reals]` proof. A cancelled exponential
Taylor tail makes an everywhere-false condition look true at a low cutoff;
`SeriesObservable` then returns `1`, zero remainder, and `Exact -> True`.
Five low/high-cutoff pairs were observed on Wolfram 15.0.0. Focused checks of
the candidate exactness guard reject all five low-cutoff cases and preserve
exact polynomial and exact-zero controls.

**H01 — a concrete performance proposal, not a measured package speedup.**
The exact Hermitian half-spectrum prototype computes the same Fourier-polynomial
products as a separate full-spectrum Cartesian implementation while avoiding
conjugate duplicate polynomial products. One matched operation-count check
performs 18 polynomial multiplications instead of 35. Frequencies and coefficients
are exact in Q(sqrt(2)) and Q(sqrt(2))[i]. This is not a replacement for the
package's arbitrary exact-real frequencies, assumptions, resource budgets, or
public result types.

The combined independent Python run passes **12 test methods**: eight algebra
methods and four patch-anchor fixture methods. The algebra methods include
80 deterministic randomized convolution subcases, 12 Euler/Leibniz subcases,
and four full-reference Lagrange depths. These are not native package test counts.

All six existing review indexes, substantial status-register content, and selected
nearest original discussions were read. All 72 retained-review TeX files were
successfully scanned for the specific helper/predicate and half-spectrum terms.
That lexical scan is not a claim of complete semantic rereading. The nearest
mechanism comparisons and scan limits are in `evidence/prior-review-scan.json`.

## Execution boundaries

Wolfram observations used the pinned standalone downloaded as text and loaded
from a temporary file. Candidate-guard checks modified that standalone text at
one unique anchor. **A full modular rebuild, the complete upstream suite, and
the complete distributed WL regression file were not run. Mathics3 was not
executed.** Mathics analysis is source-level. No native Fourier performance
measurement is claimed. Failed network/connector calls are not package failures.

`evidence/native-observations.json` is a manual transcription of successful
connector responses, not an upstream TestReport. `evidence/coverage.json` records
which areas were inspected and what was not established.

## Independent tests

Python 3.10 or later; standard library only:

```sh
python -m unittest discover -s tests -p "test_*.py" -v
```

Actual outputs are in `evidence/python-tests.txt` (Fourier-only) and
`evidence/python-all-tests.txt` (combined). The run recorded in the article used
Python 3.13.5. No environment setup or third-party package installation is
needed for these independent tests.

## Stage the N01 guard

Use a disposable checkout at the reviewed revision. The tool never edits that
checkout. Its output directory must not already exist and must be outside it:

```sh
python code/patch_predicate.py \
  --repository /absolute/path/to/Asymptotic \
  --output /absolute/path/to/predicate-patch
```

In PowerShell, put this command on one line or use PowerShell continuation
syntax. The staging tool requires git, checks the exact revision and unchanged
relevant source, and refuses an absent, ambiguous, or already modified anchor.
The full checkout staging path was not executed locally; its text transform
was tested on fixtures and its source anchor was checked in the native
standalone experiment.

Review the emitted `predicate-realness.patch`. In the disposable checkout:

```sh
git apply /absolute/path/to/predicate-patch/predicate-realness.patch
python validation/build_standalone.py
python validation/build_standalone.py --check
```

The guard is deliberately conservative: finite real-looking coefficients do
not establish realness of a discarded tail. Some genuinely real non-polynomial
conditions may require separate semantic proofs to become admissible again.
This is a candidate narrow repair, not a complete real-domain inference engine.

## Public regression specifications

In a fresh Wolfram-language evaluator, after the package has been loaded:

```wl
Get["/absolute/path/to/Asymptotic/AsymptoticAnalysis.wl"];
Get["/absolute/path/to/bundle/tests/PredicateRealness.wl"]
```

The file prints and returns an association and does not terminate the kernel.
It tests desired behavior, so the unpatched baseline is expected to fail the
false-condition assertions. `code/observe_predicate.wl` instead records the
public baseline outputs without treating them as expected behavior.

Neither complete file has a prefilled native acceptance result. Run the actual
package on both intended evaluators and retain the loaded revision and evaluator
version with the observations.

## Article build

From `article/`, with a TeX installation providing the packages used in the
source:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic-review.tex
```

The article is self-contained; it needs no external figures or separate font
files. `evidence/pdf-preflight.json` records the delivered PDF's page count and
text-boundary check. The rendered pages were also visually inspected.
