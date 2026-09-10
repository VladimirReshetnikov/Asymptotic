# Code review reports: wave 4

These nine incremental review packages, numbered 28–36, examine the Mathics
compatibility layer, validation infrastructure, and selected mathematical
extensions after the third review wave. They target two September 9, 2026
Pacific-time source snapshots:

- Reports **28, 29, and 33–36** review
  [`7d1bc832895cc90a9b2a978b7b7684acab908bd2`](https://github.com/VladimirReshetnikov/Asymptotic/tree/7d1bc832895cc90a9b2a978b7b7684acab908bd2).
- Reports **30–32** review
  [`513917b5b387152256b14ac76d92dd30cd13a11d`](https://github.com/VladimirReshetnikov/Asymptotic/tree/513917b5b387152256b14ac76d92dd30cd13a11d).

Their novelty ledgers compare findings with the existing 27-report registers
and selected earlier work; they do not claim that every earlier article was
reread in full. The [implementation register](../../../docs/development/CODE_REVIEW_STATUS.md)
tracks current decisions and verified fixes. This index records the supplied
reports' scope, not whether each finding still applies to the latest source.
The [wave-4 intake](../../../docs/development/WAVE_4_INTAKE.md) maps all 64
report-local ledger entries to grouped obligations with explicit evidence scope.

| Package | Article | Main focus | Supplied evidence and limits |
| --- | --- | --- | --- |
| [28 · Differential technical audit](code-review-28/README.md) | [PDF](code-review-28/article.pdf) · [TeX](code-review-28/article.tex) | Numerical precision, retained Lambert-core specialization, Limit and FirstPosition contracts, runner time/output limits, immutable source staging, and exact affine/PFQ extensions. | [25 independent Python tests](code-review-28/evidence/independent-checks.json), including rational certificates and synthetic processes. [No Mathics or official Wolfram package execution](code-review-28/evidence/review-scope.json); WL probes and adapters are unexecuted proposals. |
| [29 · After the Mathics merge](code-review-29/README.md) | [PDF](code-review-29/article/asymptotic-mathics-audit.pdf) · [TeX](code-review-29/article/asymptotic-mathics-audit.tex) | Runner timeout, source-dependency and interruption handling; FirstPosition and Limit; exact Gamma jets and lower-Lambert numerics. | [Six runner-fixture tests](code-review-29/results/harness-tests.json) and [six mathematical tests](code-review-29/results/mathematical-tests.json). [One pinned-package Wolfram smoke test and native Limit controls](code-review-29/results/native-observations.json) are recorded as connector transcriptions. No full suite or Mathics package run; retrieved cancelled-workflow evidence is separate. |
| [30 · After the third review wave](code-review-30/README.md) | [PDF](code-review-30/article.pdf) · [TeX](code-review-30/article.tex) | Persistent source-change detection, deadline validation, immutable source staging, sparse adapters, lower-Lambert guards, and terminating hypergeometric extensions. | [Seven actual-runner tests with simulated kernel protocols](code-review-30/evidence/runner_experiments.json), [independent exact oracles](code-review-30/evidence/mathematical_oracles.json), and a [synthetic staging check](code-review-30/evidence/staging_experiment.json). No fresh Wolfram or Mathics package execution; the narrow runner repair does not establish complete candidate acceptance. |
| [31 · Incremental audit and Mathics assessment](code-review-31/README.md) | [PDF](code-review-31/article/asymptotic-review.pdf) · [TeX](code-review-31/article/asymptotic-review.tex) | Virtual-environment executable identity, nonfinite deadlines, all-match traversal, diagnostic output bounds, and Limit/empty-list helper contracts. | [20 Python unit-test methods and scoped independent checks](code-review-31/evidence/scope.json), including a [virtual-environment witness](code-review-31/evidence/venv_identity.json). No successful fresh package execution in either kernel; staged patch mechanics were checked on source-fragment fixtures, not a complete candidate checkout. |
| [32 · Incremental review after wave 3](code-review-32/README.md) | [PDF](code-review-32/article/asymptotic-incremental-review.pdf) · [TeX](code-review-32/article/asymptotic-incremental-review.tex) | ProductLog argument conversion, parameter assumptions, constructive local radii, sparse logarithmic coefficients, source provenance, and finite PFQ extensions. | [27 independent mathematical/reference tests](code-review-32/evidence/oracle-results.json) and [eight synthetic tooling tests](code-review-32/evidence/tooling-results.json). No Mathics or Wolfram package run; the swapped-Lambert numerical witness is a SymPy countermodel, not an observed Mathics result. |
| [33 · Incremental audit and Mathics compatibility](code-review-33/README.md) | [PDF](code-review-33/article/asymptotic-review.pdf) · [TeX](code-review-33/article/asymptotic-review.tex) | Exact Lambert conversion, public empty-index coefficient queries, failed-load acceptance, Limit defaults, FirstPosition cost, and a rational lower-Lambert reference. | [Seven independent Python tests](code-review-33/evidence/independent-checks.json). [No Wolfram or Mathics package execution](code-review-33/evidence/runtime-status.json); public manifestations, WL probes, and source edits remain proposals. The rational enclosure is a reference implementation, not an integrated adapter. |
| [34 · Incremental review and Mathics semantic audit](code-review-34/README.md) | [PDF](code-review-34/article/asymptotic-review.pdf) · [TeX](code-review-34/article/asymptotic-review.tex) | ProductLog bridges, persistent source-change detection, deadline validation, workflow path coverage, sparse costs, Limit defaults, and exact rational Lambert certificates. | [22 Python methods](code-review-34/evidence/validation-scope.json): ten runner tests, nine independent checks, and three staging tests. No successful package execution in either kernel; runner children are synthetic protocol processes and the bridge candidate was not integration-tested in Mathics. |
| [35 · Incremental review and Mathics compatibility](code-review-35/README.md) | [PDF](code-review-35/article/article.pdf) · [TeX](code-review-35/article/article.tex) | Source-change persistence, nonfinite deadlines, sparse coefficient extraction, FirstPosition cost, constructive affine neighborhoods, and Limit defaults. | [14 original/candidate infrastructure scenarios](code-review-35/evidence/runner_experiments.json) and [exact reference checks](code-review-35/evidence/exact_reference_checks.json). Expected characterization assertions are not package passes. No completed Wolfram or Mathics package run; WL helpers and public probes remain unexecuted. |
| [36 · Incremental code review and Mathics engineering audit](code-review-36/README.md) | [PDF](code-review-36/article.pdf) · [TeX](code-review-36/article.tex) | Constructive polynomial neighborhoods, retained-frontier scans, sparse extraction, FirstPosition, complete CI inventories, finite deadlines, and terminating PFQ extensions. | [20 reference tests and nine inventory-checker tests](code-review-36/results/evidence_scope.json). [One native primitive query](code-review-36/results/native_probe.txt) ran without loading the package and did not establish the proposed callback distinction. No Mathics/package execution or complete-checkout CI inventory run. |

## Interpret the evidence

Most executable evidence in this wave concerns independent mathematical
models or Python infrastructure. A simulated kernel protocol can reproduce a
runner defect without evaluating Wolfram Language. POSIX process fixtures
and candidate supervisors do not establish Windows behavior. Source-based
allocation or operation-count arguments are not interpreter timing or
peak-memory measurements.

Report 29 also preserves six retrieved GitHub Actions receipts from a
cancelled workflow. Its [CI summary](code-review-29/results/ci-summary.json)
records 69 successful completed observations covering 65 unique test IDs;
only two represented suites completed. These are historical observations
with their own denominators, not a successful workflow or current acceptance.
Report 36's native observation did not load AsymptoticAnalysis. None of the
nine reports establishes a full current-package acceptance run.

The reports overlap on source-snapshot integrity, deadline validation,
FirstPosition, sparse coefficient extraction, and local-domain proof methods.
Keep each finding's claimed mechanism, public reachability, and proposed
repair distinct. In particular, a safe rejected input remains a compatibility
gap, and a successfully tested Python reference is not an implemented Mathics
algorithm. For maintained runtime evidence, use the
[Mathics compatibility guide](../../../docs/Mathics/COMPATIBILITY.md),
[portable API inventory](../../../docs/Mathics/API-COVERAGE.md), and
[validation record](../../../validation/README.md).

## Provenance and reproduction

The nine supplied directories contain **180 payload files**. Their READMEs,
articles, evidence, code, licenses, and historical source references are
preserved unchanged. This maintained index provides navigation; it does not
certify every mathematical argument or claim the supplied programs were
executed in the current checkout.

Follow each package README for dependencies, source staging, kernel probes,
and article builds. Some commands regenerate evidence files, so reproduce in
a separate copy when preserving the submitted record. Candidate patches can
expect the original repository layout and pinned source fragments; they are
not necessarily runnable directly from this archive.

Licensing is package-specific. For example, report 29 separates its
[audit-code license](code-review-29/LICENSE-audit-code.txt) from the
[upstream runner license](code-review-29/fixtures/LICENSE-upstream.txt),
and report 34 supplies a [license](code-review-34/LICENSE.txt) and
[attribution notice](code-review-34/NOTICE.md). Consult the supplied notices
before reusing a source excerpt or candidate implementation.

Return to the [four-wave index](../README.md) or the
[development workflow](../../../docs/development/README.md).
