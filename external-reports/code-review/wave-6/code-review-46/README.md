# AsymptoticAnalysis incremental audit — 10 September 2026

Open **article/review.pdf** for the report. Its complete LaTeX source is
**article/review.tex**.

Reviewed revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1` of
`VladimirReshetnikov/Asymptotic`.

## Principal new finding

`AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, {y, 1},
"SourceShift" -> -Abs[y]]` succeeds in the tested Wolfram 15.0.0 kernel.
Under `y > 2`, its finite expression is `Log[y]-1/y`, but its remainder scale
is `Exp[-2 y]/y^2`. The exact inverse is `Log[y-1]`, and the true error is
asymptotic to `1/(2 y^2)`. The article proves the mismatch at every fixed sector
depth for an exact exponential family.

The one-line repair separates the dependency rules for `SourceShift` and
`CoreInverse`: the former must exclude both source and target, while the latter
must exclude only the source. The corresponding replacement was tested on a
temporary downloaded standalone copy; the repository was not modified.

## Evidence, without pooled acceptance counts

The native baseline is one bad public request and one unshifted control, with
expression and remainder projections. The patched native evidence is seven
result-head classifications in Wolfram 15.0.0 Linux, not a full regression suite.
Successful connector results are manually transcribed in
`evidence/native_observations.json`; failed service calls contribute no results.

Twenty independent Python test methods passed: twelve mathematical checks and
eight patch-utility fixture checks. These do not execute the WL package.
The complete supplied twelve-case MUnit file and portable smoke file were not
executed as files during the audit. **No Mathics run or full repository test
suite was executed.** The article and scope record preserve these limits.

Novelty was checked against the maintained status register, wave-3/wave-4
intakes, and wave-5 index. The nearest recorded mechanisms and the distinction
are in `evidence/novelty_ledger.csv`. This is not a claim to have read every line
of all archived report bodies or every repository source file.

## Patch and probes

`code/source-shift-guard.diff` contains the minimal canonical-source change.
To emit the same change against an inspected local file:

```sh
python code/patch_source_shift.py /path/to/Asymptotic/src/Kernel/ExponentialCorePerturbation.wl
```

`--output /new/path/patched.wl` creates a **separate**, previously nonexistent
file. No option overwrites the original source. A missing/duplicate anchor or
an already-present replacement causes refusal. Inspect the diff and integrate
it into the canonical module, then use the repository's maintained standalone
generation process. Do not maintain a separate manual generated-file fork.

Load a chosen package entry in a fresh kernel, then run an observation probe:

```wl
Get["/path/to/AsymptoticAnalysis.wl"];
Get["/path/to/asymptotic_audit/code/ProbeSourceShift.wl"];
```

For a patched Wolfram package:

```wl
TestReport["/path/to/asymptotic_audit/code/ReviewSourceShift.wlt"]
```

For the smaller no-MUnit smoke, `Get` `code/PortableSourceShift.wl` after loading
the package. It is intended for testing both runtimes; Mathics execution remains
pending. The scripts contain no automatic network downloads or package edits.

## Independent mathematical checks

The code requires Python, SymPy and mpmath. Versions actually used are recorded
in `evidence/independent_tests.json`.

```sh
cd code
python -m unittest discover -s . -p 'test_*.py' -v
```

`reference.py` is a narrow independent oracle, not a replacement for the package.
It computes exact rational tail enclosures for `a Exp[c x]+delta` on the stated
positive domain, and specializes the inspected coefficient recurrence.

## Rebuild the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
# Repeat if LaTeX requests another cross-reference pass.
```

The report uses standard LaTeX packages and no external figure or font files.
The ZIP contains no checksum files, repository mirror, auxiliary TeX build files,
or bundled dependencies. The revision identifier records the source baseline.
