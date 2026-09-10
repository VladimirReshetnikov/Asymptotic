# Asymptotic: incremental code review and Mathics engineering audit

Reviewed source: `VladimirReshetnikov/Asymptotic` at
`7d1bc832895cc90a9b2a978b7b7684acab908bd2`.

Read `article.pdf` (editable source: `article.tex`). The review distinguishes
source-established issues, exact reference-model results, unexecuted public
witnesses, and proposed extensions. It does not claim a full repository or
Mathics execution, nor that all 27 previous review articles were read in full.
Deduplication uses the repository's consolidated finding registers.

## Contents

- `code/reference_checks.py`: exact rational sign-certificate producer/checker,
  terminating hypergeometric polynomials, frontier operation counts, and
  synthetic CI/timeout checks. Standard library, Python 3.11+.
- `code/ci_inventory.py` and `code/test_ci_inventory.py`: fail-closed portable
  test inventory and CI partition checker, with lexical/mutation tests.
- `code/ProposedMathicsHelpers.wl`: isolated candidate WL translation of two
  mathematical helpers. Not executed; not automatically installed or patched.
- `code/ReviewProbes.wl`: unexecuted public and private characterization probes,
  with fresh-kernel instructions at the top.
- `patches/finite-timeout.patch`: minimal proposed finite-timeout validation
  change. Run `git apply --check` on the pinned checkout before applying.
- `results/`: actual independent test logs and exact operation counts, one
  limited native evaluator observation, evidence scope, and novelty ledger.

## Reproduce the executed checks

From this directory:

```sh
python code/reference_checks.py
python -m unittest discover -s code -p 'test_ci_inventory.py' -v
```

These commands do not require Wolfram, Mathics, the network, or a repo checkout.
They test the supplied prototypes/models, not the Asymptotic package.

Against a local repository checkout:

```sh
python code/ci_inventory.py /path/to/Asymptotic
```

This last integration check was not run here because a local source checkout
was unavailable. It accepts the literal workflow layout at the reviewed commit;
it deliberately fails on unsupported dynamic inventory/workflow forms.

## Build the PDF

```sh
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

Uses a standard LaTeX installation with amsmath, amssymb, amsthm, booktabs,
longtable, tabularx, xcolor, listings, geometry, microtype, hyperref, and fancyhdr.
No shell escape, external figures, or downloaded fonts are required.

## Scope and safe use

The proposed helpers are bounded research prototypes, not a drop-in replacement
for the package's proof engine. Polynomial eventual sign is not global
monotonicity or branch uniqueness. The PFQ routine refuses every nonpositive
integer lower parameter rather than guessing a limiting convention. Exact
operation counts are not interpreter timing measurements. Candidate patches
must pass focused native and Mathics regressions before integration.

No checksum files are included.
