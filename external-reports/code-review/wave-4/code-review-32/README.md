# AsymptoticAnalysis: incremental review after wave 3

Start with **article/asymptotic-incremental-review.pdf**. The complete, self-contained LaTeX source is alongside it.

Reviewed repository: https://github.com/VladimirReshetnikov/Asymptotic

Pinned commit: `513917b5b387152256b14ac76d92dd30cd13a11d`.
Review date: September 9, 2026, America/Los_Angeles.

## Findings and evidence

The article compares the package with current official documentation for Series, SeriesData, InverseSeries, Asymptotic, AsymptoticSolve, and DiscreteAsymptotic. It uses the existing 27-review crosswalk to avoid presenting old work as new. Main additions:

- M01: distinguish Mathics ProductLog's exact SymPy conversion/order problem from its inherited numerical arity gate and the package's limited principal-branch workaround.
- M02: pass retained parameter assumptions into the Mathics polynomial real-domain proof.
- M03: replace seven absolute radius trials with a constructive positive-neighborhood certificate, without confusing eventual truth with truth on an already fixed interval.
- D-P06: avoid dense inner logarithmic coefficient polynomials inside otherwise sparse jets and Fourier modes. This sharpens an existing resource finding.
- D-V01: source endpoint equality does not establish which bytes the interpreter consumed. Reuse coherent snapshots; this sharpens an existing validation finding.
- L01/G01/T01: a latent Limit-default mismatch, a safe terminating-hypergeometric extension, and nonfinite-timeout input validation.

**Executed here:** 27 independent Python/SymPy/mpmath mathematical/reference tests, plus 8 synthetic patch/archive-helper tests. All passed. Raw console output and scoped JSON receipts are in `evidence/`.

**Not executed here:** AsymptoticAnalysis in Mathics or an official Wolfram kernel, the supplied WL prototypes, the public WL characterization probes, repository CI, and a full repository test suite. There was no available local kernel, container network access failed, and the remote Wolfram connection failed. Source and mathematical findings are not represented as observed package outputs or native performance benchmarks.

The independent swapped-Lambert numerical value is a **SymPy countermodel**, not an observed Mathics output. Public probes report completion and preserve output; they do not infer mathematical success from exit code zero. Candidate WL helpers are not installed into the repository or System context.

## Reproduce independent checks

Use Python 3.11 or newer with the dependencies in `requirements-reference.txt`. The recorded run used Python 3.13.5, SymPy 1.14.0, and mpmath 1.3.0.

```sh
python -m pip install -r requirements-reference.txt
python code/run_oracles.py
python code/test_tooling.py
```

These commands regenerate the JSON receipts. To capture fresh console records, redirect output explicitly, for example:

```sh
python code/run_oracles.py > evidence/oracle-console.txt 2>&1
python code/test_tooling.py > evidence/tooling-console.txt 2>&1
```

The reference algorithms are not a port of the package. The sparse extractor avoids a degree-indexed SymPy Poly in the huge-degree test. Its initial expansion is not budgeted; the article discusses this separate limit.

## Characterize the pinned package in installed kernels

Supply a local Git checkout containing the pinned commit and an interpreter already installed on the machine:

```sh
python code/run_probes.py --repo /path/to/Asymptotic \
  --mathics-python /path/to/mathics-env/bin/python \
  --entry modular --output evidence/mathics-characterization.json

python code/run_probes.py --repo /path/to/Asymptotic \
  --wolfram /path/to/WolframKernel \
  --entry standalone --output evidence/wolfram-characterization.json
```

On Windows, quote paths and use the appropriate Python/kernel executable. The official kernel executable must support `-noinit -script`; this is not a wolframscript-specific command line.

`--case` selects individual cases; `--timeout` sets a positive finite per-process limit. `--commit` deliberately changes the review target. The runner resolves the commit and uses `git archive`, so **uncommitted working-tree edits are not tested**. It refuses links/special files in the source archive, runs fresh processes, and does not modify the checkout.

The supplied `ReviewMathicsPrimitives.wl` is an unrun companion prototype. Load the package before loading this companion on Mathics. It is not an automatic patch and it does not implement general quantifier elimination or general polynomial symbolic sign determination.

## Candidate timeout patch

The patch generator prints a diff by default and refuses an unexpected source version:

```sh
python code/patch_timeout.py /path/to/Asymptotic/validation/run_mathics_tests.py
```

Only an explicit `--apply` writes the validated change. Its synthetic helper tests passed; repository integration and native runner behavior remain untested here.

## Build the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-review.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-review.tex
```

Run again if TeX requests an additional cross-reference pass. No images, external bibliography processor, shell escape, or proprietary fonts are needed. The distributed article is self-contained.

## Inventory

`evidence/novelty-ledger.csv` records finding ancestry and evidentiary limits. `evidence/sources.json` identifies inspected paths and upstream references. The archive intentionally contains no checksum files, TeX build intermediates, Python bytecode, repository checkout, or claimed native execution receipts.
