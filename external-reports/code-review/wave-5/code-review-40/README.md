# AsymptoticAnalysis: two missed Abs contracts

Reviewed repository: VladimirReshetnikov/Asymptotic  
Pinned revision: `651f2029d0b2cd4da9e4dfdf1f4275a124d23b99`  
Review date: 10 September 2026

Read **article/article.pdf**. Its complete editable LaTeX source is **article/article.tex**.

## Principal findings

**ABS-01 — incorrect real values after a complex modulus shortcut.** The shared
`fwdAbs` primitive uses a real leading sign to preserve or negate an entire jet,
without establishing that its retained coefficients are real. Conjugate
perturbations can cancel after this invalid operation: the helper predicts the
exact constant 2 for `Abs[1+I u]+Abs[1-I u]`, while the actual expression is
`2 Sqrt[1+u^2]`. A logarithmic witness exposes an omitted reciprocal logarithm.
The public calls are source-traced predictions, not observed native outputs.

**ABS-02 — lost classical differentiability.** `SeriesObservable` can copy an
input derivative contract through an uncertain zero of `Abs`. For the inverse
`g` of the exact smooth source `f(x)=x+x^2 Sin[Log[x]]`, the initial estimates
`g-y=O(y^2)`, `g'-1=O(y)`, and `g''=O(1)` are valid. Nevertheless,
`Abs[g'(y)-1]` has infinitely many cusps approaching zero. Its magnitude bound
survives; its classical derivative capability does not.

The article cross-checks the consolidated registers for 36 previous review
packages and selected original ledgers. It does not claim every paragraph of
all original articles was read. A candidate found to match review 4 R01 was
excluded. Broader existing performance, API, and architecture proposals are not
republished as new recommendations.

## Evidence boundary

The independent Python suite passed **18 test methods, zero failures, zero
errors**, with Python 3.13.5 and SymPy 1.14.0. It verifies mathematical identities,
cusp constructions, the reference modulus algorithm, and exact-anchor patch
fixtures. It is **not** a run of the upstream Wolfram package.

The Wolfram service returned HTTP 502/upstream errors. **No native package
execution, native patch validation, or full-suite pass is claimed.** The nine
Wolfram regression tests and the characterization script are prospective and
were not run. No native observations or TestReport results are fabricated.

Source files were read through the GitHub connector at the pinned revision.
A complete local checkout was unavailable, so the patch has been tested against
its exact edit-anchor fixtures, not against a complete locally modified package.

## Files

- `article/article.tex`, `article/article.pdf`: proofs, source traces, scope,
  source references, focused repairs and development recommendations.
- `code/stage_patch.py`: a conservative, two-file patch generator. It refuses
  complex retained terms at the signed-real shortcut and lowers finite-tail
  derivative contracts for variable-dependent `Abs` observables.
- `code/modulus_jet.py`: a bounded, log-free exact Gaussian-rational reference
  implementation based on the squared modulus and a positive-root recurrence.
- `tests/test_independent.py`: independent checks actually run.
- `tests/AbsObservableDelta.wlt`: nine prospective candidate-policy/correctness
  regressions, to be run after loading the package in a fresh Wolfram kernel.
- `code/native_characterizations.wl`: bounded native characterization script.
- `evidence/`: findings, provenance, independent test receipt and actual test log.

## Run the independent checks

Python 3.10 or later and SymPy are required. The tested dependency is pinned in
`requirements.txt`. With dependencies installed, run from this directory:

```text
python tests/test_independent.py
```

This rewrites `evidence/independent_checks.json`; test progress is printed to the
terminal. The included `evidence/independent_checks.txt` records the authoring
run. Re-running the Python checks does not execute Wolfram code.

The reference algorithm accepts integer exponent keys and exact
Gaussian-rational coefficients. It does not implement fractional exponents,
logarithmic coefficients, arbitrary symbolic assumptions, or derivative
transport. Its output remainder is conservative even for an exact input
polynomial. See its docstrings and the article before using it as a prototype.

## Stage the conservative patch

Use a separate local checkout at the pinned revision, clean for the edited files:

```text
python code/stage_patch.py /path/to/pinned-checkout /path/to/new-external-staging
```

The destination must not exist and must be outside the input checkout. The
script checks the revision, edited-file status, and every exact anchor before
writing; it never modifies the input checkout. The destination contains only
changed `src/Kernel/AsymptoticAnalysis.wl` and `src/Kernel/SeriesOperations.wl`.
It is **not a complete package**. Review the diff, transfer the changes to a
separate complete checkout, and regenerate the root standalone using the
repository's existing `validation/build_standalone.py`.

The derivative downgrade is deliberately conservative: some safe positive-unit
cases will lose derivative capability until a finer per-node proof is added.
The patch addresses the reported public observable path, not every possible
caller of the internal evaluator. The modulus guard returns a structured
refusal rather than claiming to implement a general complex modulus expansion.

## Native characterizations and regressions — not yet run

In a fresh kernel, against a pinned local standalone or modular entry:

```text
wolframscript -file code/native_characterizations.wl /path/to/AsymptoticAnalysis.wl
```

For the candidate regression file, load the reviewed candidate package first:

```wl
Get["/path/to/candidate/AsymptoticAnalysis.wl"];
TestReport["/path/to/tests/AbsObservableDelta.wlt"]
```

Some tests encode the narrow candidate's refusal policy. A richer correct
modulus implementation can legitimately return the correct expansion instead;
update those policy assertions to match the new specified behavior. The tests
are focused checks, not a replacement for any upstream suite.

## Rebuild the article

A standard TeX Live installation with the packages used in the preamble:

```text
sh build.sh
```

No font files or checksum files are distributed. Commit identifiers are source
provenance, not checksum artifacts. The archive contains no upstream checkout.
