# AsymptoticAnalysis: incremental technical audit

Repository: `VladimirReshetnikov/Asymptotic`  
Reviewed revision: `8e859961d7d37f008b826f3a8cad406460271614`  
Review date: 10 September 2026

Read **article/audit.pdf**; its full LaTeX source is **article/audit.tex**.

## Main result

**ABS-01** identifies an unsound absolute-value shortcut: a positive real leading
coefficient is treated as proving that the entire finite approximation is real.
A symbolic complex parameter can then cancel after the invalid nonlinear rewrite,
leaving a real but incorrect result with zero remainder.

The public witnesses use `a^2 == -1`, not a literal `I` in the source expression:
the latter would be rejected by the package's input screen. The article gives the
complete source trace and independent mathematical counterexamples. This is one
finding with several witnesses, not several duplicate finding counts.

The archive also provides a conservative guard candidate, a proved and executed
independent complex-modulus jet model, and a Hermitian convolution prototype.
The novelty ledger compares these specific contributions with the maintained
prior-review inventories and selected nearby original reports.

## Evidence status

**115 independent mathematical/model and synthetic patch-fixture checks passed;
zero failed.** The run used Python 3.13.5 and SymPy 1.14.0. The full case list and
model product counts are in `evidence/independent_results.json`.

**No Wolfram or Mathics package execution succeeded during this review.** The
Wolfram service returned connection/502 failures, and a local Mathics install
was unavailable. Public behavior is source-predicted; the eight Wolfram
regression tests and the exact package patch remain unvalidated in a native
kernel. No full upstream suite or native performance benchmark was run.

The source was read through the GitHub connector. There was no local full clone.
Patch automation was tested on the transcribed function and synthetic text
fixtures, not on a complete local checkout. The inspection inventory records
which of twenty kernel modules were read completely or partially.

## Run the independent checks

Python 3.9+ and SymPy are required. From this archive's root:

```sh
python code/independent_checks.py --output evidence/independent_results.json
```

The dependency range is in `code/requirements.txt`. The delivered JSON is an
actual authoring-run record, not a Wolfram TestReport.

## Characterize the baseline in Wolfram

Load a local copy of the pinned package in a fresh process:

```sh
wolframscript -file code/characterize.wl /checkout/Asymptotic/AsymptoticAnalysis.wl
```

The script prints the selected entry, kernel version, seed result, observable
results and independent identities. It does not hide a failed seed construction.

## Emit and evaluate the candidate patch

The emitter reads a source file and writes a unified diff. It never edits the
checkout. It refuses missing, duplicated, modified and already-patched anchors:

```sh
python code/abs_guard_patch.py \
  /checkout/Asymptotic/src/Kernel/AsymptoticAnalysis.wl > abs-guard.patch
```

Inspect the diff and apply it to a scratch checkout. Regenerate its standalone
using the repository's own builder before testing that entry:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
wolframscript -file /path/to/review/code/run_focused.wl \
  /checkout/Asymptotic/AsymptoticAnalysis.wl
```

The eight tests describe the conservative candidate: complex retained jets are
refused before the false sign rewrite. They are not a full modulus implementation.
A later richer implementation should return correct coefficients and replace the
two expected-refusal tests accordingly.

## Reference model

`code/modulus_jet.py` is an independent sparse exact model with rational exponents
and polynomial logarithmic coefficients. It supports complex numeric coefficients,
a real-coordinate modulus construction, conservative magnitude remainder transport,
and a separate paired Hermitian convolution. It deliberately omits symbolic
parameter proof search, derivative contracts, general complex sectors and the
rest of the upstream package.

The paired convolution gives identical exact polynomials in the executed cases.
At support 64 it enumerates 2080 coefficient products instead of 4096. This is a
model operation count, not a measured Wolfram or Mathics speedup.

## Build the article

With an installed TeX distribution containing NewTX and the listed LaTeX packages:

```sh
sh article/build.sh
```

No checksum files or font files are included. Source commit identifiers are
provenance. The upstream repository was not modified.
