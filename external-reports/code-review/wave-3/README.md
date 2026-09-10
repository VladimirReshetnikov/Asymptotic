# Code review reports: wave 3

These nine incremental review packages, numbered 19–27, examine
AsymptoticAnalysis at the
[6687962 snapshot](https://github.com/VladimirReshetnikov/Asymptotic/tree/6687962f3c858a4f93623cfc496f33e35c6763d4).
All are dated September 9, 2026. Their novelty ledgers compare the findings
with the earlier eighteen reports and maintained register at that snapshot;
the scope of each comparison is stated by its author.

The [maintained wave-3 intake](../../../docs/development/WAVE_3_INTAKE.md)
maps all 44 attributed ledger entries and consolidates implementation and
design proposals. The [implementation register](../../../docs/development/CODE_REVIEW_STATUS.md)
tracks current fixes, pending work, and focused validation. The earlier
123 entries plus this wave's 44 make 167 identified report entries before
deduplication, not 167 distinct current defects.

| Package | Article | Main focus | Supplied evidence and limits |
| --- | --- | --- | --- |
| [19 · Native-boundary audit](code-review-19/README.md) | [PDF](code-review-19/article/audit.pdf) · [TeX](code-review-19/article/audit.tex) | Configured backend defaults, computed option keys, unknown options, eager dense native views, and outcome diagnostics. | [Thirteen grouped native observations and two separately exercised patch mechanisms.](code-review-19/evidence/native_observations.json) Twelve Python methods are separate evidence; the combined candidate, outcome prototype, and complete native runner were unrun. |
| [20 · Incremental repository review](code-review-20/README.md) | [PDF](code-review-20/article/asymptotic-incremental-review.pdf) · [TeX](code-review-20/article/asymptotic-incremental-review.tex) | Backend defaults, option-named expansion variables, applied-function routing, native storage costs, and README status. | [Selected native witnesses and three candidate groups tested separately.](code-review-20/evidence/native_observations.json) The combined candidate and complete desired-contract suite were unrun; storage observations are not peak-memory or speed measurements. |
| [21 · Differential technical audit](code-review-21/README.md) | [PDF](code-review-21/article/audit.pdf) · [TeX](code-review-21/article/audit.tex) | Default ownership, callable classification, option-name equivalence, native observable precision, and refinement of exact derived constants. | [Forty-eight independent Python model and synthetic patch-fixture methods.](code-review-21/evidence/independent_validation.json) [No successful native baseline, patch, regression, or benchmark run.](code-review-21/evidence/native_execution_status.json) |
| [22 · Precision-boundary audit](code-review-22/README.md) | [PDF](code-review-22/article/audit.pdf) · [TeX](code-review-22/article/audit.tex) | Returned native Taylor order, inverse coefficient-model capability, conditional-source routing, and outcome diagnostics. | [Nine hundred forty exact-model and synthetic fixture checks.](code-review-22/evidence/independent_results.json) [Native package and candidate execution unavailable.](code-review-22/evidence/execution_scope.json) Proposed helper/policy tests are separate from the Taylor guard. |
| [23 · Current-snapshot technical audit](code-review-23/README.md) | [PDF](code-review-23/article/asymptotic-current-audit.pdf) · [TeX](code-review-23/article/asymptotic-current-audit.tex) | Complex logarithm rewrites in symbolic-depth parsing, backend defaults, standalone dependency detection, and held-data outcome classification. | [Eleven Python tests, including actual retrieved-builder fixtures and independent principal-log checks.](code-review-23/results/independent_evidence.json) [No native Wolfram execution.](code-review-23/results/native_status.json) Winding-aware numerical samples are not interval certificates. |
| [24 · Incremental technical audit](code-review-24/README.md) | [PDF](code-review-24/article/audit.pdf) · [TeX](code-review-24/article/audit.tex) | Backend defaults, computed keys, reciprocal-square Lerch charts, and Fourier recurrence termination. | [Selected native witnesses, separate backend/Fourier patch checks, and a restricted positive quadratic-chart mechanism.](code-review-24/evidence/native_observations.json) The computed-key candidate, combined suite, and pilot lifecycle were not fully tested; 21 Python methods are separate evidence. |
| [25 · Incremental technical review](code-review-25/README.md) | [PDF](code-review-25/article/article.pdf) · [TeX](code-review-25/article/article.tex) | FractionalPart sided constants, shortened native Taylor oracles, configured defaults, zero-order cutoff policy, unknown options, and eager Normal. | [Native baseline witnesses and three selected mechanism controls.](code-review-25/evidence/native_observations.json) Fourteen Python methods passed separately; the full WLT files and exact staged modular patch were unrun. The continuity candidate is not a complete analyticity proof. |
| [26 · Incremental native-boundary audit](code-review-26/README.md) | [PDF](code-review-26/article/asymptotic_native_boundary_audit.pdf) · [TeX](code-review-26/article/asymptotic_native_boundary_audit.tex) | Constructor/alias defaults, option spelling, positional specification roles, and native projection costs. | [Ninety existing baseline tests; five candidate probes and 68 existing candidate tests.](code-review-26/evidence/observations.json) The supplied 25-case file and remaining candidate files were unrun. ByteCount measurements are not runtime or peak-memory evidence. |
| [27 · After the eighteen reviews](code-review-27/README.md) | [PDF](code-review-27/article/asymptotic-audit.pdf) · [TeX](code-review-27/article/asymptotic-audit.tex) | Backend defaults, computed selector keys, applied Function classification, quadratic option-tree validation, and README routing status. | [Selected native witnesses, candidate mechanisms, and four measured parser-entry counts.](code-review-27/evidence/native_observations.json) Thirteen Python fixture methods and independent coefficient/recurrence checks are separate populations; the complete 17-test native file was unrun. |

Reports 19, 20, and 24–27 record successful Wolfram Language 15.0.0 Linux
observations. Their observation records are transcriptions of selected
connector responses, not current-repository acceptance logs. Reports 21–23
record independent checks without successful native Wolfram execution.
No report records a full upstream-suite run. Service failures, source
inspection, exact mathematical checks, numerical samples, native observations,
and candidate tests retain their separate evidence meanings. Do not add these
counts together as a package acceptance total.

Candidate patches can overlap or choose different API policies, particularly
for mutable alias defaults, native outcome classification, and eager versus
lazy normalization. An included regression file may describe desired behavior
and intentionally fail on its baseline. Consult the intake and current register
before adopting a candidate; inclusion is not implementation or verification.

The nine supplied directories contain 166 payload files. Their READMEs,
articles, evidence, code, historical paths, and package-specific licensing
notices are preserved unchanged. Each package README gives reproduction and
build instructions. Source excerpts and new audit material can have different
licenses; for example, see [19's audit license](code-review-19/LICENSE-AUDIT.txt),
[23's notice](code-review-23/NOTICE.md),
[24's upstream notice](code-review-24/licenses/UPSTREAM-MIT-0.txt), and
[27's notice](code-review-27/NOTICE.md). This index does not establish a common
license or claim that all supplied programs have been executed.

Return to the [three-wave index](../README.md) or the
[development workflow](../../../docs/development/README.md).
