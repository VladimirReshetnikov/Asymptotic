# Code review reports: wave 1

These seven retained review packages examine AsymptoticInverse 1.8.0 and document
their source coverage, findings, evidence, and development proposals. Reviews 1
and 4–6, 8 and 9 use the [07a9781 snapshot](https://github.com/VladimirReshetnikov/Asymptotic/tree/07a9781212beb2eeb9ff16aa625b50ac27974078);
review 7 uses [75de875](https://github.com/VladimirReshetnikov/Asymptotic/tree/75de8756175911cd8830704fd1a3406c1022f018).
All are dated September 9, 2026. Reviews [2](code-review-2.md) and
[3](code-review-3.md) were [retired](../README.md#retired-review-packages) after
their defect findings were implemented and their remaining entries were found to
duplicate retained packages; their tombstones record the full disposition.

Findings and proposed patches refer to those pinned snapshots. Their inclusion here does not establish that a finding still applies, or that a proposed fix is implemented and verified in the current checkout. The execution column summarizes each package's own records.

The maintained [implementation status](../../../docs/development/CODE_REVIEW_STATUS.md) consolidates the findings across these packages and links completed fixes to their focused validation, while tracking pending work and design decisions.

| Package | Article | Main focus | Recorded execution |
| --- | --- | --- | --- |
| [1 · Pinned-source audit](code-review-1/README.md) | [PDF](code-review-1/article/article.pdf) · [TeX](code-review-1/article/article.tex) | Real-branch guards, dense native export, logarithmic remainders, assumption capture, and an engineering roadmap. | [Independent mathematical and patch-fixture checks; native package unrun.](code-review-1/evidence/review_manifest.json) |
| [4 · Repository audit](code-review-4/README.md) | [PDF](code-review-4/article.pdf) · [TeX](code-review-4/article.tex) | Shared fractional-power guards, sparse-to-dense allocation, and termination after an exact zero coefficient. | [Independent mathematical and patch-tool checks; native package unrun.](code-review-4/evidence/build-verification.json) |
| [5 · Engineering and mathematical audit](code-review-5/README.md) | [PDF](code-review-5/article/asymptotic-audit.pdf) · [TeX](code-review-5/article/asymptotic-audit.tex) | Refinement precision, enumeration costs, residual labels, factorization budgets, and primitive flat-rate lattices. | [Independent mathematical and audit-tool checks; native package unrun.](code-review-5/evidence/snapshot.json) |
| [6 · Correctness, contracts, and engineering audit](code-review-6/README.md) | [PDF](code-review-6/article/article.pdf) · [TeX](code-review-6/article/article.tex) | Export contracts, explicit option precedence, backward precision planning, and resource-budget semantics. | [Independent mathematical and Python-tool checks; native package unrun.](code-review-6/evidence/review_manifest.json) |
| [7 · Technical audit and development roadmap](code-review-7/README.md) | [PDF](code-review-7/article/asymptotic-audit.pdf) · [TeX](code-review-7/article/asymptotic-audit.tex) | Native-tail import, real-coefficient policy, dense views, shared branch guards, and rational flat-rate normalization. | [Independent Python checks; native version probe only, without successful package execution.](code-review-7/evidence/snapshot.json) |
| [8 · Repository audit](code-review-8/README.md) | [PDF](code-review-8/article/asymptotic_repository_audit.pdf) · [TeX](code-review-8/article/asymptotic_repository_audit.tex) | Assumption metadata, sparse cache allocation, loop budgets, and recurrence termination. | [Native observations and five focused patch checks, plus Python component tests.](code-review-8/evidence/audit_metadata.json) |
| [9 · Source audit and development proposals](code-review-9/README.md) | [PDF](code-review-9/article.pdf) · [TeX](code-review-9/article.tex) | Native-series bridge, bounded integer powers, support planning, realness, and refinement precision. | [Independent Python mathematical/resource models and patch fixtures; native package unrun.](code-review-9/README.md#what-was-and-was-not-executed) |

Each package README gives its reproduction commands, dependencies, article build instructions, patch scope, and execution limits. Package-contained `evidence/` and `results/` files distinguish recorded runs from supplied regression specifications and benchmark harnesses. Some proposed tests deliberately describe behavior that fails on the reviewed baseline. The focused native work in review 8 does not amount to a full original or patched upstream-suite run.

Licensing and attribution are documented per package. Keep the supplied notices with the relevant code and excerpts: [1](code-review-1/UPSTREAM_LICENSE.txt), [4](code-review-4/NOTICE.md), [5](code-review-5/LICENSE), [6](code-review-6/LICENSE-AUDIT-CODE.txt), [7](code-review-7/LICENSE-AUDIT-CODE.txt), [8](code-review-8/LICENSES/AUDIT_CODE.txt), and [9](code-review-9/NOTICE.txt). Some packages distinguish original audit code from upstream source excerpts; consult their READMEs and accompanying license files for that scope.
