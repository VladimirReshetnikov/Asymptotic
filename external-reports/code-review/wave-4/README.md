# Code review reports: wave 4

These eight retained incremental review packages, numbered 28–31 and 33–36,
examine the Mathics compatibility layer, validation infrastructure, numerical
contracts, and bounded mathematical extensions of AsymptoticAnalysis. Report
[32](code-review-32.md) was [retired](../README.md#retired-review-packages): its
timeout finding is implemented and every other entry restates a work item that
retained packages already carry. Together with the other waves, the collection now contains
**35 retained reviews across five waves**. The supplied packages arrived in
[8cb9b7f](https://github.com/VladimirReshetnikov/Asymptotic/commit/8cb9b7f16b005e368a360308ec3b78919ef7c465).

Reports 28, 29, and 33–36 review
[7d1bc83](https://github.com/VladimirReshetnikov/Asymptotic/tree/7d1bc832895cc90a9b2a978b7b7684acab908bd2).
Reports 30 and 31 review the later
[513917b](https://github.com/VladimirReshetnikov/Asymptotic/tree/513917b5b387152256b14ac76d92dd30cd13a11d).
Their novelty comparisons use the previous 27 reports and maintained registers;
each author states the extent of that comparison. They do not collectively
establish that every earlier article was reread or every package behavior tested.

The [maintained wave-4 intake](../../../docs/development/WAVE_4_INTAKE.md)
maps all **64 report-local ledger entries** supplied by this wave, including
explicitly numbered advisories and extension proposals: 10, 7, 6, 6, 8, 7, 6, 6,
and 8 entries for reports 28–36 respectively, of which report 32's eight are now
carried by the intake and by its [tombstone](code-review-32.md). Combined with the earlier 167 entries from
waves 1–3, this gives 231 attributed report entries before overlapping
findings are grouped. These counts do not measure distinct current defects
or completed repairs.
Consult the [implementation register](../../../docs/development/CODE_REVIEW_STATUS.md)
for current decisions, overlap, accepted policy, and focused validation.
This index records the supplied reports' scope; the intake distinguishes
their historical observations and proposed witnesses from current-source
mechanics and implementation evidence.

| Package | Article | Main focus | Supplied evidence and limits |
| --- | --- | --- | --- |
| [28 · Differential technical audit](code-review-28/README.md) | [PDF](code-review-28/article.pdf) · [TeX](code-review-28/article.tex) | Numerical precision, nonprincipal Lambert cores, Limit and FirstPosition contracts, runner resource/provenance limits, and exact local/PFQ extensions. | [25 independent Python tests](code-review-28/evidence/independent-checks.json), including exact certificates and synthetic process/Git snapshot fixtures. [No Wolfram or Mathics package execution](code-review-28/evidence/review-scope.json); the WL characterizations and integration are unrun. |
| [29 · After the Mathics merge](code-review-29/README.md) | [PDF](code-review-29/article/asymptotic-mathics-audit.pdf) · [TeX](code-review-29/article/asymptotic-mathics-audit.tex) | Runner deadlines, init.m dependency coverage, interrupted-case records, helper contracts, Gamma inverse Newton iteration, and a stable real Lambert evaluator. | [One pinned-package Wolfram smoke test and native Limit controls](code-review-29/results/native-observations.json); six Python harness and six mathematical methods passed separately. The [retrieved CI summary](code-review-29/results/ci-summary.json) contains 69 successful records/65 unique IDs from a cancelled workflow, with only two represented suites complete. No fresh Mathics package or native candidate run. |
| [30 · After the third review wave](code-review-30/README.md) | [PDF](code-review-30/article.pdf) · [TeX](code-review-30/article.tex) | Forgotten source drift, relocated module dependencies, Lambert capability, sparse coefficients/search, Limit defaults, and bounded Taylor families. | [Seven synthetic-peer tests of the exact runner and a narrow sticky-state repair](code-review-30/evidence/runner_experiments.json), [independent mathematical oracles](code-review-30/evidence/mathematical_oracles.json), and synthetic Git staging. No fresh Wolfram/Mathics package execution; WL candidates and public witnesses are unrun. |
| [31 · Incremental audit and Mathics assessment](code-review-31/README.md) | [PDF](code-review-31/article/asymptotic-review.pdf) · [TeX](code-review-31/article/asymptotic-review.tex) | Python virtual-environment identity, bounded deadlines/output, first-match work, Limit defaults, and empty-list lookup paths. | [20 Python unittest methods and independent exact checks](code-review-31/evidence/scope.json), including an [actual POSIX virtual-environment witness](code-review-31/evidence/venv_identity.json). No fresh Wolfram/Mathics package run; source-fragment patch tests do not validate a complete candidate checkout. |
| [33 · Incremental audit and Mathics compatibility](code-review-33/README.md) | [PDF](code-review-33/article/asymptotic-review.pdf) · [TeX](code-review-33/article/asymptotic-review.tex) | Exact Lambert conversion, empty-index coefficient queries, load-failure admission, Limit defaults, first-match traversal, dense conversion, and interrupted loading. | [Seven independent Python tests](code-review-33/evidence/independent-checks.json). [No Wolfram or Mathics package execution](code-review-33/evidence/runtime-status.json); proposed source fixes and the selected-case load-failure witness are unrun. |
| [34 · Incremental review and Mathics semantic audit](code-review-34/README.md) | [PDF](code-review-34/article/asymptotic-review.pdf) · [TeX](code-review-34/article/asymptotic-review.tex) | Exact/reverse ProductLog conversion and arity, drift/copy integrity, deadlines, CI triggers, sparse amplitude costs, and a rational Lambert branch oracle. | [22 Python methods: ten runner, nine independent, three staging](code-review-34/evidence/validation-scope.json). [Runner observations use synthetic protocol children](code-review-34/evidence/runner-observations.json); no Wolfram/Mathics package execution or actual Mathics bridge integration. |
| [35 · Incremental review and Mathics compatibility](code-review-35/README.md) | [PDF](code-review-35/article/article.pdf) · [TeX](code-review-35/article/article.tex) | Runner drift/deadlines, sparse coefficients, FirstPosition, exact affine deleted neighborhoods, and Limit contracts. | [14 runner scenarios](code-review-35/evidence/runner_experiments.json) and [independent exact models](code-review-35/evidence/exact_reference_checks.json), including 325 sparse comparisons and small-radius/rescaling families. No Wolfram/Mathics package or WL candidate execution; scenario and model counts are separate populations. |
| [36 · Incremental code review and Mathics engineering audit](code-review-36/README.md) | [PDF](code-review-36/article.pdf) · [TeX](code-review-36/article.tex) | Rational-polynomial local signs, association frontier costs, sparse/search adapters, CI inventory completeness, terminating PFQ, and rewrite installation contracts. | [20 reference and nine synthetic inventory methods](code-review-36/results/evidence_scope.json). [One native primitive-only query](code-review-36/results/native_probe.txt) established no FirstPosition effect difference for that witness. No package/Mathics execution, complete-checkout inventory check, or WL helper execution. |

The successful native observations in reports 29 and 36 used Wolfram Language
15.0.0 on Linux. Report 29 records a package smoke test; report 36 records only
a primitive query. None of these reviews freshly executed the package in
Mathics, and none ran a full package suite. Retrieved historical CI receipts,
source deductions, exact mathematical checks, ordinary numerical samples,
synthetic process tests, and runtime package observations retain their separate
evidence meanings. Their counts must not be added into a package acceptance total.

Several findings overlap across reports, and some current source already differs
from the pins. Candidate repairs also differ in scope: latching detected drift
does not freeze every executed input, a finite timeout check may still admit an
unsupported huge deadline, and a sparse collector can still expand its input
without a bound. An included desired-contract test or prototype is not an
accepted implementation. The maintained intake records these distinctions and
the further checks needed before integration.

The eight retained package directories, including their READMEs, articles,
code, evidence, historical links, and notices, remain preserved unchanged. Their own READMEs
describe reproduction commands and platform limits. Some commands regenerate
evidence, so reproduce in a separate copy when preserving the submitted
record. Candidate patches may require their original pinned source layout. POSIX process supervisors
do not establish Windows process-tree behavior. Source excerpts and original
review material may have different licenses; see, for example,
[29's upstream license](code-review-29/fixtures/LICENSE-upstream.txt),
[30's license](code-review-30/LICENSE), [34's notice](code-review-34/NOTICE.md),
and [35's upstream license](code-review-35/upstream/LICENSE).
This index does not establish a common license or imply that supplied programs
have been executed during intake.

For maintained runtime evidence, consult the
[Mathics compatibility guide](../../../docs/Mathics/COMPATIBILITY.md),
[portable API inventory](../../../docs/Mathics/API-COVERAGE.md), and
[validation record](../../../validation/README.md).

Return to the [review index](../README.md) or the
[development workflow](../../../docs/development/README.md).
