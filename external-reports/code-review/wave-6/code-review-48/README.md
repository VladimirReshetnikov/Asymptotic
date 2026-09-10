# AsymptoticAnalysis after the fifth review wave

Start with **`article/asymptotic-differential-audit.pdf`** (20 pages).
The editable source is `article/asymptotic-differential-audit.tex`.

Reviewed repository: **VladimirReshetnikov/Asymptotic**  
Pinned revision: **`8cee870994f506b501bae3ea6bd4a3a7edb895c1`**  
Review date: **10 September 2026**

## New contributions

**N1 — coefficient-option type corruption.** In Wolfram 15, a public coefficient
query with `Power -> 2` returns a successful association whose exponent is
`1 + "Power"` and coefficient is `-"Power"`. The recently added C09 selection
code combines name-equivalent `FilterRules` matching with literal string
replacement. Mixed symbol/string options also violate first-option precedence.
The candidate uses `OptionValue` with the stored power as an omitted default.
Nested and delayed string options **worked on the Wolfram baseline**; they are
controls, not Wolfram defects.

**N2 — Mathics logarithm recovery loses exact positivity.** The new fallback
uses machine `N` merely to determine the sign of an exact rational factor.
The inspected Mathics conversion maps, for example, `10^-400` to machine zero,
blocking a valid logarithm split. The exact host conversion and mathematical
oracle were executed; the Mathics interpreter and public recovery path were
not. The candidate preserves exact integer/rational signs.

**N3 — incorrect local numerical-field semantics.** Native powered-observable
examples return `LocalRoot = 2`, while `LocalApproximation` is `4` or `-8`.
The current label says both are powers of the same positive local coordinate.
The calculations in these examples are correct. The candidate corrects the
label and adds `LocalReferenceObservable` and `ObservablePower` without
changing existing numeric fields.

**P1 — quadratic temporary flat-tail candidates.** The new, mathematically
correct grade selector materializes a quadratic candidate population. The
article derives the exact count and supplies a comparison-preserving two-pass
reference design. No production Wolfram scheduler patch or timing speedup is
claimed. The first omitted coefficient must still be combined exactly before
it is bounded.

The novelty ledger explains the deltas from C09, C21, C23, and prior Mathics
reviews. The exclusion pass covered all five wave indexes, the relevant
implementation-register entries, and selected original reports—not every
appendix of every retained article.

## Executed evidence

The native kernel reported **Wolfram Language 15.0.0 for Linux x86 (64-bit)
(May 6, 2026)**. The commit-pinned generated standalone was downloaded and
loaded in that kernel.

- **45/45 unmodified-package inverse comparisons** passed across five
  polynomial sources, three observable powers, and three inversion methods.
  These compare finite expressions, not analytic remainder contracts.
- **10/10 option candidate checks** and **8/8 numerical-metadata candidate
  checks** passed in separate staged-standalone runs.
- **39/39 independent Python test methods** passed: exact mathematics,
  source-equivalent host conversion, reference algorithms, and synthetic Git
  patch fixtures. Subcases are not counted as additional named tests.

These counts are separate evidence populations. No Mathics package run, full
upstream suite, complete local real checkout, combined modular acceptance run,
or end-to-end performance benchmark was performed. Native JSON records are
manual transcriptions of connector responses, not authenticated kernel logs.
One earlier harness `AssociateTo` error is explicitly recorded and excluded
from the clean acceptance counts.

## Reproduce independent checks

Python **3.10 or newer** is required. Authoring versions were Python 3.13.5,
SymPy 1.14.0, and mpmath 1.3.0.

```sh
python -m pip install -r code/requirements.txt
python code/independent_checks.py
```

The second command rewrites `evidence/independent-results.json`. Use a copy of
the archive to preserve the original evidence. The tests make no network
requests and do not invoke Wolfram or Mathics.

## Emit and inspect a candidate patch

Use a disposable, tracked-clean Git checkout at the pinned revision:

```sh
python code/emit_candidate_patch.py /path/to/pinned/Asymptotic \
  --output /path/outside/checkout/audit-candidate.patch
```

The emitter **does not apply changes**. It refuses a different revision, dirty
tracked state, missing/duplicate anchors, an existing output file, and an
output inside the checkout. The CLI was fixture-tested, not run on a complete
local real checkout. All four literal anchors were separately matched once
in the real pinned standalone. The same option and metadata replacements
were then natively tested; the Mathics-only replacement remains unexecuted.

After inspecting the diff, apply it to a scratch checkout and regenerate the
standalone using the repository's builder:

```sh
python validation/build_standalone.py
```

Do not edit modular files and accidentally test an old generated root package.
The patch changes only the three files implicated by N1–N3. It does not include
P1's scheduling optimization.

## Native reproducer

In a fresh Wolfram kernel:

```wl
Get["/path/to/audit/code/NativeReview.wl"];
AuditNativeReview["/path/to/checkout/AsymptoticAnalysis.wl", "Baseline"]
```

After patching and rebuilding, use `"Candidate"`. The mode labels the run; it
does not patch or otherwise alter the package. The function returns observations,
ten desired option checks, eight desired metadata checks, and the 45-case
matrix. Some desired checks intentionally fail on the baseline. Inspect all
returned records and messages, not just an aggregate Boolean.

Equivalent expressions were run through the Wolfram connector. This complete
convenience file was not itself executed as a local or remote file during
authoring. It does not overwrite the included evidence.

## Mathics probes — unrun

In Mathics3 10.0.1, load and call:

```wl
Get["/path/to/audit/code/MathicsProbes.wl"];
AuditMathicsProbes["/path/to/checkout/AsymptoticAnalysis.wl"]
```

These distinguish primitive option behavior, public coefficient results,
exact rational signs, first numerical evaluation, and recovery evaluation.
The logarithm fallback is relevant only when the first evaluation contains
`Indeterminate`; do not infer an observed public failure from a helper alone.
These probes do not claim high-precision `FindRoot` acceptance.

## Build the article

A TeX Live installation with pdfLaTeX, Latin Modern, microtype, geometry,
amsmath, amssymb, amsthm, booktabs, tabularx, longtable, xcolor, listings,
enumitem, fancyhdr, titlesec, xurl, and hyperref:

```sh
sh article/build.sh
```

The included PDF was compiled and visually inspected. Build intermediates,
font files, interpreter packages, and checksum files are not distributed.

## License

Original audit code is supplied under MIT No Attribution terms in
`LICENSE-AUDIT.txt`. Upstream source excerpts retain the upstream terms in
`UPSTREAM-LICENSE.txt`. The article may be used, edited, and redistributed
with the project under the same permissive terms.
