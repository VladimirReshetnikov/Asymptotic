# Wave 4: findings, proposals, and implementation scope

All nine [wave-4 reports](../../external-reports/code-review/wave-4/README.md),
numbered 28–36, are included in the active implementation scope. They add
**64 identified entries**: 10, 7, 6, 6, 8, 7, 6, 6, and 8 respectively.
Together with 167 entries from the earlier waves, the review library contains
**231 attributed entries in 36 reports**. Overlaps are consolidated below;
these totals are not counts of distinct current defects. Unnumbered proposals
remain in scope and are mapped separately.

This intake contributes to the [coverage targets](COVERAGE_TARGETS.md): full
official-Wolfram and Mathics compatibility, every input successfully handled
by `Series`, `Asymptotic`, or `DiscreteAsymptotic`, and the asymptotics in the
vendored ProveIt articles. Those goals remain incomplete. The
[main register](CODE_REVIEW_STATUS.md), [wave-3 intake](WAVE_3_INTAKE.md),
[Mathics plan](../Mathics/COMPATIBILITY.md), and
[vendored coverage map](VENDORED_ASYMPTOTICS.md) retain the earlier obligations.

## Provenance and evidence

Reports 28, 29, and 33–36 examine
[`7d1bc832895cc90a9b2a978b7b7684acab908bd2`](https://github.com/VladimirReshetnikov/Asymptotic/tree/7d1bc832895cc90a9b2a978b7b7684acab908bd2).
Reports 30–32 examine
[`513917b5b387152256b14ac76d92dd30cd13a11d`](https://github.com/VladimirReshetnikov/Asymptotic/tree/513917b5b387152256b14ac76d92dd30cd13a11d).
Their **180 supplied files**, including nine TeX and nine PDF articles,
arrived in
[`8cb9b7f16b005e368a360308ec3b78919ef7c465`](https://github.com/VladimirReshetnikov/Asymptotic/commit/8cb9b7f16b005e368a360308ec3b78919ef7c465).
The [payload audit](../../validation/wave4-payload-provenance.json) compares
every supplied byte with its arrival Git blob and records all hashes. The
payloads, candidate programs, notices and original evidence remain unchanged.

Three independent intake lanes read every README, complete TeX article,
finding ledger and relevant evidence/candidate code, then compared the
mechanisms with current production sources through `725a547`. No supplied
program was executed during intake. **Source inspected** below establishes
that a mechanism is present; it does not establish that a proposed public
witness reaches it or returns an incorrect mathematical result.

Most reports contain independent Python mathematics and synthetic runner
experiments. Report 29 additionally records one pinned-package Wolfram smoke
and native `Limit` controls as a manual connector transcription; its retrieved
cancelled CI run has 69 successful completed records, 65 distinct IDs and only
two complete suites. Report 36 records a native primitive query, without
loading the package. **None records a fresh Mathics package run.** Prior native
preservation receipts quoted by a report remain prior evidence. Independent
test counts, fetched CI artifacts, unrun WL probes, exact certificates and
current package acceptance are not combined into one passing total. The full
package suite remains skipped.

## Consolidated work

`W4-*` identifiers are maintained work items; report-local IDs are retained in
the complete crosswalk below. A corrected source comment or previous related
repair does not settle a new mathematical or runtime obligation.

| Item | Finding and current disposition | Implementation and focused acceptance obligations |
| --- | --- | --- |
| W4-01 | **Pending — high-priority semantic characterization.** Raw nonprincipal `ProductLog` crosses exact, symbolic, reverse-conversion, stored-value and numerical boundaries in Mathics. Current principal-branch normalization and documented numerical limitations do not close those routes. Related: D05, X05/X06. | Characterize both construction and specialization of entropy and exponential exact cores, literal principal-branch forms, differentiation and arbitrary precision. Test original equations and branch intervals with an independent oracle. Repair argument/reverse conversion and numerical arity together, or guard the unsupported operation before it can evaluate unsafely. A late `s[value]` guard cannot repair an already changed core or external use of `Normal[s]`. Swapped SymPy/mpmath examples in the reports are countermodels, not observed Mathics package outputs. |
| W4-02 | **Pending — source inspected.** Numerical inverse checks request high working precision without checking achieved root precision/accuracy on the Mathics solver path. Earlier admission may already refuse safely; no current public low-precision result is established. Related: D05, distinct from C21 translated coordinates. | Compare requested 20/50/100 digits with achieved precision, true error and residual on well-scaled roots, including exact roots and solver failures. Do not manufacture accuracy with `SetPrecision`. Numerical approximation, interval certification and capability refusal need distinct records. |
| W4-03 | **Pending — conservative coverage.** Seven dyadic trial radii miss arbitrarily small valid neighborhoods; polynomial domain inference omits retained assumptions. General fallbacks can still prove some spellings. Related: C05/C16, X07. | Add exact affine and then polynomial eventual-sign certificates with a proved positive radius; combine conjunctions and relational chains correctly. Propagate a smaller radius into any later fixed-neighborhood theorem. Distinguish unproved from false, symbolic pointwise radii from uniform bounds, and coefficient reality from monotonicity. Thread retained assumptions into domain proof without accepting unknown, nonreal or source-dependent coefficients. |
| W4-04 | **Pending — source inspected, public consequences unrun.** Safe empty-list mapping rewrites cover private definitions but miss compatibility helpers and public `InverseExpansionCoefficient` validation. Related: V02; W3-08 model admission is separate. | Audit `Lookup`, key operations and zero-dimensional multi-indices. Test reuse of caller inputs and returned empty lists inside subsequent numeric lists. Add narrow empty fast paths after required dimension/type checks; avoid global System or blanket context rewrites. |
| W4-05 | **Pending — latent helper contract.** Private Mathics `Limit` maps omitted/Automatic finite direction to one side. Inspected finite proof consumers pass a side explicitly; no public wrong expansion is established. Related: D06; W3-06 is separate. | Implement conservative two-sided agreement or require explicit approach at every admitted consumer. Preserve unequal, unknown and unresolved sides, both infinite endpoints, assumptions and explicit-side controls. Replacing left by right does not implement a two-sided limit. |
| W4-06 | **Pending — grammar and performance.** `FirstPosition` gathers all matches and can consume a third-slot `Heads` option as its default. Symbolic jet merging remains a consumer despite C14's exact-weight grouping repair. Related: P08. | Classify defaults/options correctly, preserve held lazy defaults, and specialize first-level list search to stop early. Verify first/middle/last/missing and head/level controls and actual merged coefficients. Mathics 10.0.1 does not support the proposed extra count argument to `Position`; do not assume that one-line repair works. Predicate counts are separate from runtime speedups. |
| W4-07 | **Pending — resource dimension.** Sparse coefficient extraction, polynomial realness, Fourier amplitudes/envelopes and some valuations still allocate degree-sized lists. W3-13 stopping, optional native export repairs and W3-04 eager `Normal` concern different allocations. Related: P06/P08. | Inventory and share sparse support operations, while bounding expansion before allocation. Compare fixed occupied support at increasing degree, cancellation, zero polynomials, coefficient ordering, realness, conjugacy and envelopes. Compact `x^D` and dense `(1+x)^D` need different bounds; never drop retained amplitudes to meet a cap. |
| W4-08 | **Pending — proved provider extensions.** Hypergeometric rank admission precedes recognition of exact termination; lower-parameter admission excludes negative nonintegers. Native pre-evaluation/fallback may cover some public forms. Related: X12. | Admit terminating nonpositive-integer upper parameters before the nonterminating rank gate, with degree/work bounds and truthful omitted tails. A later extension may admit exact negative noninteger lower parameters with proved majorants. Preserve denominator-pole refusals, convergence-radius restrictions, fixed monomial coordinates and constant outer multipliers; no implicit regularization convention. |
| W4-09 | **Pending — setup integrity.** The portable suite records failed `Get` but only its loading-specific case checks that result. A selected package-independent primitive can succeed despite failed setup. Related: V01/V02. | Make successful load a mandatory separate top-level gate before all selected cases; characterize failed/aborted loads and a nominally successful nonpackage file with required-capability checks. Preserve Mathics `Print`/`Check` separation and legitimate non-Null `Get` values. This source-proved gap is not a claim that historical case results used failed setup. |
| W4-10 | **Focused verified — deadline guard in the 32/0 runner checks.** Nonfinite, nonpositive and greater-than-one-day deadlines are rejected before output or launch, including direct `run_case` calls. | The supported interval is `(0, 86400]` seconds. Exact boundaries and NaN/infinity/huge-value controls pass on the recorded Windows host. Larger durations would require an explicit sliced-wait design; cross-platform acceptance beyond this host remains separate. |
| W4-11 | **Focused verified — lexical launcher selection in the 32/0 runner checks.** Existing Python/default-Python/Wolfram paths become absolute without dereferencing symlinks; bare PATH commands are preserved. | Tests cover paths with spaces, actual symlinks and a real temporary venv-only import. The recorded host is Windows; a POSIX symlinked-venv execution and durable child-environment identity remain additional controls. |
| W4-12 | **Partly addressed — observed drift stays invalid in the 32/0 runner checks.** The first mismatch survives restoration in `FirstObservedSourceDriftSHA256`, the final hashes remain available, and the run exits unsuccessfully. Coherent snapshots remain pending. Related: V01/V02. | Freeze the complete declared package/suite/adapter closure, covering `init.m`, renamed modular trees, the executed suite copy and standalone entries, and record original versus executed hashes separately. A sticky flag cannot detect an entire A–B–A edit between observations; endpoint equality does not prove temporal immutability. No historical receipt is alleged to have encountered such an edit. |
| W4-13 | **Partly addressed — output aliases rejected in the 32/0 runner checks.** Final and `.tmp` targets cannot overwrite fingerprinted inputs, including direct, relative, symlink and hard-link aliases checked before launch and before each write. Broader process/report bounds remain pending. Related: V01/P06. | Extend dependency closure under W4-12. Add bounded output with terminal overflow failure even after a success frame; retain bounded diagnostics and compact publication. Write attempted-case identity before launch and preserve interruption/cleanup outcomes. Test owned process trees and inherited pipes on Windows and POSIX; the supplied POSIX supervisor is not a Windows implementation. |
| W4-14 | **Partly addressed before intake.** R34's missing standalone-builder CI trigger is already fixed for push and PR. Broader dependency triggers and declaration/group/shard inventory remain open. Related: V01/V02. | Derive or validate all suite cases and workflow groups against one inventory, reject unknown/dynamic registration constructs deliberately, and detect missing/duplicate/empty coverage. Verify source and test dependencies, both layouts, runtime/version and exact commit. The new 16-test receipt verifier validates complete submitted evidence; it does not itself repair discovery or execute a current Mathics matrix. |
| W4-15 | **Pending — preventive adapter contract.** Late definition rewrites lack a versioned expected-match/consumer/postcondition record. Reports do not establish a currently failed installation. Related: V02/B04, distinct from W3-11 distribution scanning. | Inventory executable consumers, call shapes, attributes, binding time and fallback semantics. Assert expected rewrite counts/residual forms, test perturbed miniature definitions and reload idempotence, and retain separate native definition-preservation checks. Passing native controls does not prove a Mathics-only rewrite executed. |
| W4-16 | **Pending — retained computation proposals.** Gamma coefficient construction repeats phase work; retained Lagrange refinement scans complete association keys for membership. Related: P04/P06/P08. | Profile predicate/key/phase/product/allocation counts before native timing. Investigate direct key membership and Gamma formal Newton doubling in its derived coefficient ring, with independent coefficients, precision frontiers, assumptions, domain and budget controls. Reuse Gamma cores across observable powers only when their contracts agree. Finite prototype agreement is not an all-orders or Barnes derivation. |
| W4-17 | **Pending — exceptional loading lifecycle.** The compatibility context is removed on normal completion without an outer cleanup contract for interruption or partial loading. Related: V02. | Inject interruption at load phases, inspect context/path/stack and partial definitions, and establish subsequent reload behavior for both entries and runtimes. Restoring only `$ContextPath` need not restore the Begin/End stack or atomic definitions. |

## Complete finding crosswalk

The first [32/0 focused runner receipt](../../validation/wave4-runner-integrity-tests.json)
records 18 new cases plus the 14 existing protocol/process/report tests, two
unchanged source hashes and zero skips. It uses synthetic peers and real
temporary Python processes/virtual environments, without loading Wolfram or
Mathics. It closes the stated deadline and lexical-launcher changes and only
the specified parts of source integrity and publication; it does not close
W4-09's mandatory setup gate or the complete portable evidence workstream.

Every identified entry is mapped, including advisory and development entries.
An entry may span more than one work item; overlapping reports do not multiply
the required fixes. The [static crosswalk receipt](../../validation/wave4-intake-crosswalk.json)
compares all 64 IDs with the supplied ledgers. A separate read-only peer audit
checked the 17 work items and 16 proposal groups against all three intake
lanes and found no material omissions or evidence overclaims.

| Report and count | Every local entry → maintained item |
| --- | --- |
| [28](../../external-reports/code-review/wave-4/code-review-28/README.md) — 10 | F01 → W4-02; F02 → W4-01; F03 → W4-05; F04 → W4-06; F05 → W4-10; F06 → W4-12; F07 → W4-13; E01 → W4-03; E02 → W4-08; E03 → W4-15. |
| [29](../../external-reports/code-review/wave-4/code-review-29/README.md) — 7 | N1 → W4-10; N2 → W4-12; N3 → W4-13; N4 → W4-06; D1 → W4-05; P1 → W4-16; P2 → W4-01. |
| [30](../../external-reports/code-review/wave-4/code-review-30/README.md) — 6 | F1 → W4-12; F2 → W4-12; F3 → W4-01; F4 → W4-06/W4-07; F5 → W4-05; F6 → W4-08. |
| [31](../../external-reports/code-review/wave-4/code-review-31/README.md) — 6 | N1 → W4-11; N2 → W4-10; N3 → W4-06; N4 → W4-13; A1 → W4-05; A2 → W4-04. |
| [32](../../external-reports/code-review/wave-4/code-review-32/README.md) — 8 | M01 → W4-01; M02 → W4-03; M03 → W4-03; D-P06 → W4-07; D-V01 → W4-12; L01 → W4-05; G01 → W4-08; T01 → W4-10. |
| [33](../../external-reports/code-review/wave-4/code-review-33/README.md) — 7 | F01 → W4-01; F02 → W4-04; F03 → W4-09; F04 → W4-05; F05 → W4-06; A01 → W4-07; A02 → W4-17. |
| [34](../../external-reports/code-review/wave-4/code-review-34/README.md) — 6 | R1 → W4-01; R2 → W4-12; R3 → W4-10; R4 → W4-14; R5 → W4-06/W4-07; R6 → W4-05. |
| [35](../../external-reports/code-review/wave-4/code-review-35/README.md) — 6 | N01 → W4-12; N02 → W4-10; N03 → W4-07; N04 → W4-06; N05 → W4-03; N06 → W4-05. |
| [36](../../external-reports/code-review/wave-4/code-review-36/README.md) — 8 | N01 → W4-03; N02 → W4-16; N03 → W4-07; N04 → W4-06; N05 → W4-14; N06 → W4-10; N07 → W4-08; A01 → W4-15. |

## Proposals, disagreements, and acceptance decisions

These are maintained proposal groups, not additional authored finding IDs.
They preserve recommendations from article prose and candidate material even
when the narrow finding is already addressed or requires more characterization.

| Proposal and sources | Decision, implementation obligation and evidence limit |
| --- | --- |
| Operation-specific capabilities — 28, 30, 31, 33–36 | Record input class, mathematical contract, interpreter/version, consumer and evidence. Separate exact algebra, proof queries, tails, numerical evaluation and certification. Computed, justified refusal, unresolved, exception and timeout are different outcomes; exact smoke tests do not imply arbitrary-precision support. W4-01/W4-02/W4-15. |
| Branch-safe Lambert evaluation — 28–30, 32–34 | First characterize all evaluation boundaries. R29 proposes the stable log-excess coordinate `delta` and `v` near the lower-branch threshold with bounded rounded iterations; its prototype explicitly sets `certified=False`. Retain correction coordinates and precision/iteration caps rather than flattening away tiny corrections. No global System rewrite is authorized by the proposal. W4-01. |
| Independent rational branch certificates — 28, 30, 33, 34 | Entropy `-x Log[x]`, exponential `Exp[x]/x`, and lower-Lambert monotone equations have distinct domains, error coordinates and endpoint proofs. Reuse existing rational logarithm/exponential enclosure machinery where applicable; independently check final signs, branch and width. Five rational examples or an 80-bit fixture do not certify arbitrary complex branches or install a package evaluator. W4-01 and X05/X06. |
| Constructive neighborhoods and proof records — 28, 31, 32, 35, 36 | Exact affine clauses can precede polynomial leading-sign certificates. Combine strict/weak/zero/slope cases, conjunctions, ordered chains and all-distinct relations with proved operand reality. Unknown leading cancellation requires refusal or justified case splitting. Store the actual sufficient radius and assumptions; do not claim maximality, global uniformity or a larger interval. W4-03. |
| Defining-series extension and exact oracles — 28, 30–32, 36 | Recognize termination, then evaluate broader lower-parameter domains only with a valid tail majorant. Add affine, hypergeometric, monomial-order and Stirling-boundary controls, including equality at cutoff, first omitted support gaps, pole multipliers and denominator poles. Exact finite coefficient agreement does not establish an analytic omitted-tail bound. W4-08. |
| Coherent execution snapshots — 28–30, 32, 34–36 | Latch observed drift first, then stage the complete declared dependency closure. A committed archive excludes uncommitted edits; a working-tree snapshot needs verified acquisition. Record executed suite bytes and modules separately from observed originals. Read-only mode bits, suffix globs and final hashes alone are insufficient. W4-12. |
| Bounded runner and evidence publication — 28, 29, 31, 34, 35 | Choose finite deadline policy, retain attempted-case state, cap output, preserve overflow/error outcomes, and publish atomically without input collisions. Avoid repeatedly rewriting unrestricted transcripts. Timeout and interrupt cleanup must own only the launched tree. POSIX prototype tests leave Windows behavior open. W4-10/W4-11/W4-13. |
| Adapter installation and consumer closure — 28, 29, 31, 33–36 | Manifest expected rewrites/attributes/call shapes, test deliberate missing rewrites, verify public and helper consumers separately, and retain normal/exceptional reload controls. Avoid broad System rewrites and unbounded global caches. W4-04/W4-15/W4-17. |
| Capability probes and adapter retirement — 34, 36 | Add harmless sentinels, tested runtime ranges, upstream issue/fix provenance and explicit retirement criteria. A version string alone does not prove a capability works or justify deleting a compatibility adapter. W4-15. |
| Sparse arithmetic and first-match search — 30–36 | Share support primitives, but budget `Expand` before sparse collection. Preserve coefficient ordering, complete cancellation, envelopes and fallback semantics. Narrow first-level search is distinct from a complete held pattern walker; preserve option grammar and lazy defaults. W4-06/W4-07. |
| Retained phase/key work — 29, 36 | Evaluate Gamma Newton doubling and reusable cores, and direct frontier membership without whole-key scans. Keep finite formal proof, native coefficient comparison, resource accounting and end-to-end speed measurements separate. No automatic extension of a Gamma derivation to Barnes. W4-16. |
| CI and executable inventory — 29, 31, 34–36 | Compare discovery, declared groups and actual jobs/cases; include modular, standalone and dependency-builder triggers. Use exact runtime/commit/source identities and mutation controls. Report 36's direct-token scanner is only a prototype: dynamic `Apply` forms and held nested registrations need deliberate scope handling. W4-14. |
| CI scheduling and truthful resource diagnostics — 35, 36 | Retain per-case/partial records and compare case deadlines with whole-job limits and shard cost. Identify support, polynomial degree, frontier or native allocation when reporting resource failures without changing existing budget meanings. This scheduling proposal does not establish a currently timed-out published run. W4-07/W4-13/W4-14/W4-16. |
| Mutation and decisiveness tests — 31–36 | Mutate Lambert argument/reverse conversion, safe-map consumers, load success, direction, early exit, sparse fallback, suite/group declarations and installation match counts. Pair negative cases with successful controls; an unresolved helper is not proof of a correct conservative refusal. W4-01/W4-04/W4-05/W4-06/W4-09/W4-14/W4-15. |
| Public deadlines and performance evidence — 28–36 | Preserve caller deadlines independently of internal Mathics timeout scaling. Separate startup, loading, warm computation, display, root accuracy, predicate/phase/key counts, allocation and diagnostic bytes. Align chart, side, retained blocks and remainder frontier before comparisons. No supplied microbenchmark establishes a package-wide speedup. |
| Discrete, interpolation and vendored coverage — 30, 31, 33, 36 | Attach article source, branch/interpolation convention, parameter domain, independent coefficients and error theorem to each extension. Integer identities and residue classes need explicit approach sets; sequence frequencies modulo `2 Pi` differ from logarithmic Fourier frequencies. Carry Bell/Fibonacci and q-analog inverse conventions into the existing coverage plans. No `DiscreteAsymptotic` backend is inferred from this intake. |

The runner patches are complementary, not interchangeable: a finite-positive
guard still accepts enormous finite deadlines; a sticky Boolean can still
discard the first mismatch evidence; `init.m` support that requires a parent
named `Kernel` still misses relocated modules. Candidate Git staging omits
parts of the suite/adapter closure. Sparse candidates can expand without a
budget before counting support. The independent numerical and certified
Lambert proposals offer different guarantees and must not be merged under
one undifferentiated success label.

The first implementation sequence is runner integrity and mandatory setup,
then current-Mathics characterization of branch/numerical/empty-list paths,
followed by bounded helper and constructive coverage work. Earlier request
resolution, native coverage and vendored-corpus work remain active. Update
this intake with each accepted repair's actual source hashes, focused tests
and remaining obligations; completion of intake is not completion of the goal.
