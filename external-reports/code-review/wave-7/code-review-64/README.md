# AsymptoticAnalysis after six review waves

**Reviewed commit:** `efa1aeec4845a9c35e140963a0333d0c9ec33b05` (10 September 2026).

Read `article/article.pdf` or its self-contained LaTeX source, `article/article.tex`.
The article contains one new source-established correctness finding and one
specific algorithmic development contribution, screened against the six review
indexes, maintained register, and relevant original overlap passages. It does
not claim an exhaustive reread of all 45 retained articles.

## Main result

`AsymptoticCoreInverse` checks target independence on `core + perturbation`,
then uses the operands separately. Target-dependent terms can cancel at the
check and enter a fixed-data remainder theorem. The article proves an all-depth
false remainder and a second failure with a genuinely vanishing marker ratio.
`code/emit_core_patch.py` emits a narrowly scoped proposed fix.

The separate Lerch prototype returns exact rational Gauss/Radau bounds for
`LerchPhi[q,1,a]`, using two explicit Meixner recurrences. It includes a positive
denominator proof, signed errors, individual error caps, and nested intervals.
This is a higher-order rational construction, not a repeated request for the
mean-variance bounds or Eulerian moment table already described in reports 49/50.

## What ran

The final independent Python run has **24 unittest methods, 0 failures, 0 errors**.
Its 144 defining-sum containment cases and other subcase counts belong to those
methods, not to an additional package acceptance total. Exact defining-sum and
moment oracles are independent of the production recurrence. The first-pass
oracle-resolution failure and its correction are preserved in `evidence/`.

Selected recurrence and predicate calculations ran in a remote **Wolfram 15.0.0
Linux** kernel. Four rational-enclosure examples also agreed with native Lerch
comparisons. These are isolated calculations, not complete package execution.

**Not run:** the original or patched complete package, the MUnit regression file,
the complete supplied WL wrapper file, an upstream test suite, or any Mathics
session. There was no local checkout. The public N01 outcome is source-predicted;
the Abs-based witness may meet a different realness admission boundary in Mathics.
The patch emitter was exercised against synthetic source-anchor fixtures only.
See `evidence/scope.json`, `native-observations.json`, and `novelty-ledger.json`.

## Run the independent code

Python 3.10 or newer; no third-party packages required:

```sh
python tests/run_tests.py
python code/lerch_rational.py 1/2 10 4
python code/emit_core_patch.py /path/to/Asymptotic --output core-operands.patch
```

The emitter does not edit the repository. It fails closed if either source anchor
is absent or duplicated. Apply and validate its output in a separate checkout,
then rebuild the standalone using that repository's maintained procedure.
Running the tests regenerates the final Python evidence files; preserve the
supplied records before doing so when retaining the historical observations.

In a Wolfram or Mathics session, the portable prototype can be loaded with:

```wl
Get["/path/to/archive/code/LerchRationalBounds.wl"];
ReviewLerch`LerchRationalBounds[1/2,10,4]
```

For the **unrun** package integration probe:

```wl
Get["/path/to/Asymptotic/AsymptoticAnalysis.wl"];
Get["/path/to/archive/tests/ProbeCoreOperandScope.wl"];
```

`tests/CoreOperandScope.wlt` is an unrun Wolfram MUnit desired-contract file;
its moving-operand rejection tests are expected to fail on an affected baseline.
It is not a Mathics test receipt.

## Build the article

Run `./build.sh` with a standard LaTeX installation providing `pdflatex` and the
packages used by the source. The script builds three times in a temporary directory
and copies only the PDF into `article/`. No network access or font files from this
archive are required. The source is also directly compilable with three pdflatex
passes. No checksum files are included.

## Licensing

Original report text and original code are supplied under MIT-0; see `LICENSE`.
Short upstream code excerpts and source anchors retain their upstream license.
The repository and commit-pinned provenance are identified in the article. No
complete upstream repository, third-party font files, or dependency wheels are
redistributed.
