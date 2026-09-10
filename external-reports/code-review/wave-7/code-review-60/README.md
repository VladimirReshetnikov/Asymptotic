# AsymptoticAnalysis — core-component validation audit

Open **article/review.pdf**. The complete editable article is
**article/review.tex**.

Repository: `VladimirReshetnikov/Asymptotic`  
Pinned revision: `efa1aeec4845a9c35e140963a0333d0c9ec33b05`  
Review date: 10 September 2026.

## Principal result

One new correctness finding is retained after mechanism-level comparison with
the six-wave review indexes, maintained register/intakes, and targeted nearest
original reports. This is not a word-for-word rereading of every prior article.

`AsymptoticCoreInverse` validates `core + perturbation`, then consumes the two
components separately. Cancelling target occurrences in the sum can therefore
bypass its fixed-data premise. Two public Wolfram 15.0.0 calls for `x+1/x=y`
return false analytic remainder scales:

```wl
AsymptoticAnalysis`AsymptoticCoreInverse[
  x-Re[y], Re[y]+1/x, {x,Infinity}, {y,2}]

AsymptoticAnalysis`AsymptoticCoreInverse[
  1/x-Re[y], Re[y]+x, {x,0}, {y,2}]
```

On the positive real target ray, their claimed errors are O(y^-2) and O(y^-4),
while both true errors are Theta(y^-1). The article gives exact quadratic
inverses, all-depth Catalan coefficient formulas, and the distinction between
marker convergence and asymptotic power order.

## What was actually tested

The two wrong-result witnesses were reproduced through public calls in Wolfram
15.0.0 Linux. A temporary patched standalone copy exhibited the expected
outcomes for five public requests. A separate 17-input native forward screen
had zero coefficient differences through powers below four.

The independent standard-library Python suite ran **30 test methods, all
passing**: 22 rational mathematical checks and eight patch-utility fixtures.
These tests do not execute the package. Exact root/error interval endpoints
are included independently of the package's own remainder claims.

**No Mathics run and no full repository test-suite run were performed.**
The complete 12-case MUnit file and 4-case portable file were not run as files;
selected matching requests were executed inline. Successful native outputs
are manually transcribed in `evidence/native-observations.json`; failed
service calls supply no results. No repository was modified.

## Run the independent checks

Python 3.10+; no third-party dependencies:

```sh
python code/run_checks.py
```

This rewrites the companion test transcript, summary, rational enclosures and
sample CSV under `evidence/`. It does not download or execute Wolfram code.

## Prepare the patch without editing the checkout

```sh
python code/patch_core_validation.py /path/to/Asymptotic/src/Kernel/CorePerturbation.wl
```

The default output is a unified diff. `--output /new/path/patched.wl` creates a
new file exclusively; the original and existing destinations are never
overwritten. Missing/duplicate anchors and already-patched inputs are refused.
The utility does not verify the Git revision. Inspect and integrate the diff
into the canonical module, then regenerate the standalone using the repository
builder (`python validation/build_standalone.py` from the repository root).

The tuple-based `FreeQ` check is the essential repair. The accompanying general
input-validation change aligns validation with the consumed tuple and can
slightly change leaf-budget accounting. Legitimate target dependence in the
`"CoreInverse"` option remains allowed.

## Package probes

Load the chosen package entry in a fresh kernel first, then evaluate separately:

```wl
Get["/path/to/AsymptoticAnalysis.wl"];
Get["/path/to/audit/code/ProbeComponents.wl"];
```

For the patched Wolfram package:

```wl
TestReport["/path/to/audit/code/ReviewComponents.wlt"]
```

For the no-MUnit probe, including future Mathics acceptance:

```wl
Get["/path/to/audit/code/PortableComponents.wl"];
```

Use the repository's maintained Mathics loading and iteration-budget
instructions. None of these companion probes performs a network download or
edits package definitions.

## Rebuild the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
```

Repeat if LaTeX requests another cross-reference pass. Standard LaTeX packages
are used; no external font or figure files are needed.

## Evidence map

`evidence/scope.json` and `source-inventory.csv` delimit the inspected source.
`novelty-ledger.csv` distinguishes N01 from the earlier SourceShift,
source-variable, parameter-capture, and option-identity findings.
`native-observations.json` records successful native output projections.
`independent-tests.json` and `.txt` record the independent test run.
`exact-enclosures.json` retains exact fractions; `numerical-samples.csv` gives
rounded decimal summaries, not directed decimal certificates.

Candidate code is not a complete replacement package or a global compatibility
certification. The ZIP intentionally contains no checksum files, repository
mirror, bundled libraries, font files, caches, or TeX auxiliary build products.
