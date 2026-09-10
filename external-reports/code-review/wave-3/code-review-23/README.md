# AsymptoticAnalysis: current-snapshot technical audit

**Repository:** VladimirReshetnikov/Asymptotic  
**Pinned revision:** `6687962f3c858a4f93623cfc496f33e35c6763d4`  
**Date:** September 9, 2026 (America/Los_Angeles)

Start with **`article/asymptotic-current-audit.pdf`**. Its complete editable source
is **`article/asymptotic-current-audit.tex`**. The article compares actual package
contracts with current official Wolfram documentation and screens its findings
against the consolidated register and the finding inventories of all eighteen
reports in `external-reports/code-review`.

## New findings and their evidence

* **N01 — branch-erasing logarithm rewrite:** the symbolic-depth parser rewrites
  `Log[u^k]` without proving `k` real. A mathematical counterexample has a real,
  eventually invertible source even though the intermediate logarithm is complex.
  The normalizer defect is source-proved; the proposed public/core Wolfram calls
  were not executed. A safe rejection patch and a winding-aware constructive
  alternative are developed in the article.
* **N02 — ignored backend defaults:** the facade advertises a `"Backend"` option
  but hard-codes `Automatic` when the caller omits it, bypassing `SetOptions`.
  This is a source-confirmed option-resolution omission; native behavior and the
  proposed Wolfram patch await execution.
* **N03 — incomplete standalone dependency gate:** the actual retrieved Python
  builder accepted eight non-bracket dependency-call variants on temporary source
  trees. The proposed conservative token check rejected all ten tested dependency
  forms and preserved inert text, unrelated symbols, and normal companion inlining.
  This does not claim that the current generated package contains hidden loads.
* **N04 — ambiguous native status:** the syntactic unresolved-call test also sees
  native calls inside held user data. This is a diagnostic design weakness; the
  supplied public characterization remains unexecuted and no numerical error is
  claimed.

The report does not recycle the previously recorded allocation, remainder-degree,
assumption-capture, generic resource-budget, refinement, or CI wish lists. Its
novelty crosswalk states the closest prior issue for each finding.

## What was executed

**Eleven Python tests passed.** Subcases include ten builder mutation forms,
four inert/unrelated-symbol controls, companion inlining, patch-anchor safeguards,
a principal-log counterexample, twenty exact-sequence formula evaluations,
and sixty numerical samples of the winding-aware inverse bound.

The upstream builder fixture was reconstructed from the connector-returned text;
its Git blob identity matched the returned source identity. The fixture itself,
not a reimplementation of the assembler, was executed. No full repository checkout
was obtained. Mathematical numerical checks use mpmath and are not interval
certificates or executions of the Wolfram package.

**No native Wolfram test, native benchmark, full upstream suite, or Wolfram patch
execution is claimed.** Both the available Wolfram context and evaluator requests
failed at the service/connection layer. Those failures are not attributed to the
repository. `results/native_status.json` records this boundary. The nine `.wlt`
tests specify desired behavior after the proposed N01/N02 repairs; several are
expected to fail on the unmodified baseline.

## Contents

`article/` contains the PDF and self-contained LaTeX article. `code/` contains
independent checks, nine native regression specifications, a fresh-kernel runner,
and fourteen native characterization/comparison cases. `fixtures/` contains only
the exact retrieved Python builder, not the upstream package. `patches/` contains
a dry-run-first edit tool for three narrowly scoped proposals. `results/` contains
actual Python results, explicit native status, the novelty ledger, and source
coverage/provenance. No checksum files or font files are included.

## Run the independent checks

Python 3.9 or later and mpmath:

```sh
python -m pip install -r code/requirements.txt
python code/independent_checks.py
```

This writes `results/independent_evidence.json`; shell redirection can capture the
unittest log. It creates only temporary miniature repository fixtures and never
runs their Wolfram-language content.

## Inspect the proposed patches

Use a local checkout at the exact revision above. The tool checks Git's recorded
HEAD, verifies each target against `git show`, requires unique text anchors, and
refuses to overwrite backups. It does not download anything or change the generated
standalone file.

```sh
python patches/apply_focused_patches.py /path/to/Asymptotic
python patches/apply_focused_patches.py /path/to/Asymptotic --only N03
```

The default is a dry run. Add `--apply` only after reviewing the diff. Test the
modular sources before using the upstream builder to regenerate the root package.
The tool deliberately refuses a checkout with locally modified target files or a
different HEAD; porting to a later revision requires manual review.

**Patch limits:** N01 guards the two identified depth-parser rewrites, not every
possible analytic-source admission rule. N02 repairs the canonical facade's
backend default; independent defaults on the short alias remain a policy decision.
N03 is a conservative source-token gate, not a proof of sandboxing or absence of
arbitrarily constructed dynamic I/O. N04 has a diagnostic redesign proposal, not
an applied code patch.

## Run native probes on your installation

Use fresh kernels and a local checkout. For PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_REPO = 'C:\src\Asymptotic'
wolframscript -file code/run_native.wls
wolframscript -file code/characterize_and_compare.wls
```

The first command executes only the nine supplied regression specifications. The
second records fourteen bounded native observations and their raw expressions,
messages, result kinds, and timings. Single timings are not benchmark conclusions.
Only explicitly aligned forward pairs have matching algebraic cutoffs; other pairs
compare coverage and require branch/order interpretation. Runtime output files
are created only when these scripts actually execute.

## Rebuild the article

A standard TeX installation with pdfLaTeX, New PX, amsmath/amsthm, geometry,
microtype, longtable, booktabs, listings, fancyhdr, titlesec, xurl, and hyperref:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-current-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-current-audit.tex
```

The supplied PDF was compiled and visually inspected. No repository write,
commit, pull request, or asynchronous work was performed.
