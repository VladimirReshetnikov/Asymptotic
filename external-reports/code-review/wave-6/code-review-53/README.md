# Asymptotic: range-aware certificate audit

Review date: 2026-09-10. Repository: VladimirReshetnikov/Asymptotic.
Pinned revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`.

Read `article/article.pdf` or edit `article/article.tex`.

## Findings

N01 identifies a loss of dependence in odd integer powers of intervals crossing
zero. For `x + x^4` on `[-1/4,1]`, the source arithmetic gives derivative enclosure
`[0,5]`, while the exact range is `[15/16,5]`. A range-aware endpoint candidate
retains a strictly positive bound.

N02 identifies an avoidable exponential-magnitude restriction for noninteger
rational powers. The bundle provides an exact-rational root-enclosure algorithm
and a square-root witness with power-of-two endpoints.

N03 identifies retries after arithmetic-independent failures. An exactly wrong
source-side interval is rechecked throughout the refinement budget even though
neither the interval nor the deciding comparison changes.

These are conservative refusal/performance findings, not alleged unsound
successful certificates. The maintained review registers, later intake
crosswalks and wave-5 index were used for exclusion. See
`evidence/novelty-and-scope.md` for the precise novelty boundary.

## Executed evidence

Run from the `code` directory:

```text
python -m unittest -v test_certificate_power_model
```

This uses Python 3.9+ and its standard library. The recorded run used Python
3.13.5. All 22 methods passed, including 3,036 admissible generated interval
cases, 7,800 integer-root cases, and 800 generated rational-root cases.

Optional independent numerical controls require mpmath (tested with 1.3.0):

```text
python check_special_identities.py
```

All 360 controls passed at 120 decimal working digits. They cover transcribed
Bessel, hypergeometric U, incomplete-gamma and Lerch formulas. Numerical controls
are not proof certificates or executions of the package.

The actual outputs are in `evidence/python-tests.txt`, `evidence/summary.json`,
and `evidence/special-function-controls.json`.

## Wolfram and Mathics characterization

**No Wolfram or Mathics package run succeeded during this review.** The WL files
are unexecuted characterization/candidate code. No native or Mathics acceptance
is implied by the Python results. Source coverage is listed in the article.

In a fresh target kernel, set the repository directory and load the probes:

```wl
auditRepository = "/absolute/path/to/Asymptotic";
Get["/absolute/path/to/bundle/code/ProbeCertificates.wl"];
```

On Windows, ordinary WL string escaping applies to backslashes; forward-slash
paths are convenient. Save the entire printed InputForm output and kernel
version. A failed public constructor must remain a constructor failure, not be
reported as a later certificate reproduction.

For the N01 candidate, load its file and install explicitly:

```wl
Get["/absolute/path/to/bundle/code/CandidateCertificatePowers.wl"];
AsymptoticAudit`InstallIntegerPowerCandidate[];
AsymptoticAnalysis`Private`certIntegerPower[{-1/4, 1}, 3, auditContext]
(* Candidate target: {-1/64,1}. *)

AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`certEnclose[
    1 + 4 auditX^3, auditX, {-1/4,1}, auditContext]]
(* Candidate target: {15/16,5}. *)
```

Evaluate the individual public certificate expressions from the probe file
using the already constructed objects. **Do not Get the whole probe file again
while the candidate is installed:** that script reloads the original package.
Package reload invalidates the interpretation of an in-memory overlay test.

The rational-power primitive is separate; loading it does not hook certEnclose:

```wl
AsymptoticAudit`NonnegativeRationalPowerInterval[
  {2^39998,2^40002}, 1/2, auditContext]
(* Candidate target: {2^19999,2^20001}. *)

AsymptoticAudit`RestoreIntegerPowerCandidate[];
```

`patches/retry_policy.fragment.wl` contains source-edit fragments, not a directly
loadable package. They classify only explicitly established arithmetic-invariant
failures. Do not apply a blanket terminal classification to all domain or
derivative-separation failures.

The candidate installer/restorer has not itself been executed in either target
kernel. Validate installation, restoration, resource refusals and unchanged
controls before integrating production changes. No System definitions are
intentionally changed by the candidate. No repository files were modified by
this review.

## Build the article

From `article`, using a TeX installation with the packages in its preamble:

```text
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

Another pass can be required after changing the table of contents or pagination.
The delivered PDF was compiled and visually inspected. The archive intentionally
omits auxiliary TeX files, Python bytecode, font files and checksum files.
