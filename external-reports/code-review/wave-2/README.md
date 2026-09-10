# Code review reports: wave 2

These nine incremental review packages, numbered 10–18, examine
AsymptoticInverse 1.8.0 at the
[921387e snapshot](https://github.com/VladimirReshetnikov/Asymptotic/tree/921387e5ba1239bfda96e63e64e89bf63d9c41e6).
All are dated September 9, 2026. They compare additional findings and sharper
evidence with the [nine wave-1 reviews](../wave-1/README.md) and the maintained
finding register as it stood at that snapshot. Their novelty ledgers describe
the extent of that comparison; it is not a claim that every reviewer reread
or independently verified every earlier article.

Findings, candidate patches and proposed extensions refer to the pinned
revision. Their inclusion does not establish that a finding still applies,
or that a proposed fix is implemented and verified in the current checkout.
The [implementation status](../../../docs/development/CODE_REVIEW_STATUS.md)
tracks findings, accepted repairs, focused validation and deferred decisions.
The execution column below summarizes each supplied package's own records.

| Package | Article | Main focus | Recorded execution |
| --- | --- | --- | --- |
| [10 · Focused delta audit](code-review-10/README.md) | [PDF](code-review-10/article/asymptotic_delta_audit.pdf) · [TeX](code-review-10/article/asymptotic_delta_audit.tex) | False source-domain certificates under ambient assumptions; flat multiplication charging inactive coefficient pairs; a restricted affine-domain proof checker. | [Ten focused native checks of a temporary patched standalone; separate independent mathematics and Python fixture checks.](code-review-10/evidence/execution_scope.json) |
| [11 · Additional contract audit](code-review-11/README.md) | [PDF](code-review-11/article/asymptotic-contract-audit.pdf) · [TeX](code-review-11/article/asymptotic-contract-audit.tex) | Certificate assumption leakage, fixed-parameter capture in composition, hidden analyticity of opaque functions, and inconsistent real-coefficient admission. | [Four findings reproduced in selected native observations; the proposed patch was not successfully integration-tested.](code-review-11/evidence/native-observations.json) Independent mathematical and patch-fixture checks are recorded separately. |
| [12 · Incremental audit after nine reviews](code-review-12/README.md) | [PDF](code-review-12/article/asymptotic_incremental_audit.pdf) · [TeX](code-review-12/article/asymptotic_incremental_audit.tex) | False source-domain certificates, a false trigonometric error bound from a nonreal coefficient, and native series indices exceeding the representable range. | [Focused native baseline observations and individual patch mechanisms; no combined candidate suite.](code-review-12/evidence/native_observations.json) [Twenty-three independent Python checks.](code-review-12/evidence/artifact_checks.json) |
| [13 · Semantic weights and technical audit](code-review-13/README.md) | [PDF](code-review-13/article/asymptotic-incremental-audit.pdf) · [TeX](code-review-13/article/asymptotic-incremental-audit.tex) | Mathematically equal exponents grouped under different keys, encoded nonreal constants and target limits, and unresolved numerical inverse errors. | [Selected native cases, including three before/after grouping controls, plus independent degree and exact-error oracles and patch fixtures.](code-review-13/manifest.json) The complete hotfix installer and numerical wrapper were unrun. |
| [14 · Incremental technical audit](code-review-14/README.md) | [PDF](code-review-14/article.pdf) · [TeX](code-review-14/article.tex) | Parameter capture, affine interval-rounding failures, numerical loss of small source displacements, ignored Fourier term goals, and loss of explicit Zeta/Lerch bounds on truncation. | [Twenty-five independent mathematical-model tests](code-review-14/evidence/independent_results.json) and five patch-emitter fixtures; [native package and prototype execution unavailable.](code-review-14/evidence/native_status.json) |
| [15 · Target geometry and graded tails](code-review-15/README.md) | [PDF](code-review-15/article/article.pdf) · [TeX](code-review-15/article/article.tex) | Composite target endpoints and orientation, certificate accuracy progress, exponential grading of flat-product errors, and powered Gamma/Barnes observables on negative source branches. | [Twenty independent Python model tests](code-review-15/evidence/python_tests.txt); [no successful native package, helper or benchmark execution.](code-review-15/evidence/native_execution_status.txt) |
| [16 · Beyond the existing reviews](code-review-16/README.md) | [PDF](code-review-16/article/article.pdf) · [TeX](code-review-16/article/article.tex) | Certificate domain and precision control, cutoff/term-goal policy, inclusive boundary convolution, and proposed Zeta/Lerch derivative-tail contracts. | [One hundred seven independent arithmetic and polynomial checks](code-review-16/evidence/python_checks.json), with [separate synthetic patch-staging checks](code-review-16/evidence/staging_checks.json); [native tests unrun.](code-review-16/evidence/build_checks.json) |
| [17 · Differential audit](code-review-17/README.md) | [PDF](code-review-17/article/asymptotic_delta_audit.pdf) · [TeX](code-review-17/article/asymptotic_delta_audit.tex) | False source-domain certificates, weak flat-product tails after grade erasure, unresolved tiny inverse errors, and explicit fixed-order Zeta derivative-tail bounds. | [Focused native certificate and flat-tail fixes, numerical observations and built-in comparisons.](code-review-17/evidence/native_observations.json) Independent bound-model, derivative-bound numerical and patch-fixture checks are separate populations. |
| [18 · AsymptoticInverse after nine reviews](code-review-18/README.md) | [PDF](code-review-18/article/audit.pdf) · [TeX](code-review-18/article/audit.tex) | Relative-only certificate accuracy stagnation, lower-cutoff refinement policy, and stronger historical evidence for real-coefficient admission and nonlinear logarithmic frontiers. | [Selected native witnesses, controls and built-in comparisons.](code-review-18/evidence/native_observations.json) [Thirteen Python prototype methods, including forty deterministic independent-oracle subcases, passed.](code-review-18/evidence/python_validation.json) The complete native runner, desired-behavior suite, certificate adapter and source patch were not natively validated. |

Each package README provides its reproduction commands, article build
instructions, dependencies, candidate-patch scope and execution limits.
Supplied regression files and benchmark harnesses are specifications, not
evidence that those complete programs ran. Some desired-contract tests are
expected to fail on the reviewed baseline. Candidate helpers may address
only part of a finding or propose a new API policy.

Reports 10–13, 17 and 18 record selected native observations using Wolfram Language
15.0.0 on Linux x86-64. Their observation files describe transcriptions of
successful connector responses, not full upstream test logs. Reports 14–16
record independent model or fixture checks without successful native package
execution. None of these packages records a full upstream-suite run, and
their counts must not be combined into a package acceptance total. Network
and service failures are distinguished from package failures. Source and
artifact checks, native examples, mathematical proofs, numerical samples and
interval certificates retain their separate evidence meanings.

Keep the supplied source, evidence and notices together. Package-specific
attribution and licensing information includes
[11's source notice](code-review-11/licenses/NOTICE.md),
[13's notice and audit-code license](code-review-13/NOTICE.md),
[15's audit license](code-review-15/LICENSE-AUDIT.txt) and
[upstream license copy](code-review-15/evidence/upstream-LICENSE.txt), and
[17's code and patch license](code-review-17/LICENSE).
These notices distinguish newly supplied audit material from upstream excerpts;
they do not create a common license for all nine packages. Consult each
package's README and source notices for its exact scope. The original
package files, including their READMEs and historical paths, are preserved
without editing; this wave index provides the current repository routes.

Report 18 was added later from upstream commit
`84650f3521cfcc89ae832f5bad3554f65faaab31`, with nineteen supplied files. Its
audited source remains `921387e`, so its observations precede current repairs.
Its [novelty ledger](code-review-18/evidence/novelty_ledger.json) has two new
items and two attributed deltas to earlier findings. Its README mentions
`CHECKSUMS.sha256`, which is absent from the supplied nineteen-file package;
no replacement manifest or common license has been invented.

The separate [report-18 intake characterization](../../../validation/review-18-intake.json)
records seven bounded observations on Wolfram 15.0.1 Windows. It reproduces
relative-certificate stagnation and lower-cutoff coarsening, distinguishes
strict real admission from native formal output, and checks a degree-two
nonlinear frontier control. This predates the C19 repair and is not an
acceptance suite. The subsequent [58/0 certificate acceptance](../../../validation/review-certificate-accuracy-tests.json)
verifies relative planning, selective arithmetic retries, sharp error bounds,
best-result retention and budget/cap semantics. Lower-cutoff refinement remains
the D10 policy item; current status is maintained in the register.
