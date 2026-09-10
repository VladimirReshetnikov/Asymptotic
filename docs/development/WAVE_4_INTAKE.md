# Wave 4 review intake

This intake maps reports **28–36** to current-source work and proposed
extensions. The [wave index](../../external-reports/code-review/wave-4/README.md)
links every supplied article, README, and execution record. Reports 28, 29,
and 33–36 review `7d1bc832895cc90a9b2a978b7b7684acab908bd2`; reports 30–32
review `513917b5b387152256b14ac76d92dd30cd13a11d`.

The production-source observations below were inspected at
[`38aa253aaf792577100103a76a9db165d7390e0e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/38aa253aaf792577100103a76a9db165d7390e0e).
Two subsequent revisions are reviewed separately below; the Fourier change
is now merged, while the Mathics acceptance update remains peer evidence.
This intake ran
no package code, kernels, benchmarks, or candidate patches. **A mechanism
visible in source is not a newly reproduced public failure.** Reported
interpreter behavior, independent reference algorithms, synthetic runner
experiments, and maintained acceptance records retain their own scopes.

The work serves the three [complete-coverage requirements](COVERAGE_TARGETS.md):
native input coverage, Mathics compatibility, and all vendored asymptotics.
Safe refusals can preserve correctness while still leaving compatibility
work. Successful finite examples do not establish an entire family, option
space, or interpreter contract.

## Attributed inventory

Reading one primary ledger per report with Python's CSV/JSON parsers gives
**64 unique report-local entries**. The uniqueness key is `(report, ID)`;
repeated JSON/CSV renderings of the same report's findings are counted once.
The total includes findings, advisories, and extension proposals. It is not
64 distinct defects, accepted changes, or additional package test cases.
The earlier **167 entries remain the separate waves 1–3 inventory**.

| Report | Primary ledger | Entries | Original IDs |
| --- | --- | ---: | --- |
| 28 | [Novelty ledger][R28] | 10 | F01–F07, E01–E03 |
| 29 | [Novelty ledger][R29] | 7 | N1–N4, D1, P1–P2 |
| 30 | [Finding ledger][R30] | 6 | F1–F6 |
| 31 | [Novelty ledger][R31] | 6 | N1–N4, A1–A2 |
| 32 | [Novelty ledger][R32] | 8 | M01–M03, D-P06, D-V01, L01, G01, T01 |
| 33 | [Source and novelty ledger][R33] | 7 | F01–F05, A01–A02 |
| 34 | [Novelty ledger][R34] | 6 | R1–R6 |
| 35 | [Novelty ledger][R35] | 6 | N01–N06 |
| 36 | [Novelty ledger][R36] | 8 | N01–N07, A01 |

The `W4-*` identifiers below group implementation obligations. One report
entry can map to several groups when it combines distinct mechanisms.
The mapping preserves attribution without treating independent reports as
independent reproductions of the same package failure.

## Consolidated work

### Validation and execution infrastructure

| Item | Current-source disposition | Required work and acceptance boundary |
| --- | --- | --- |
| **W4-01 · Deadline validation** | **Mechanism present.** The [portable runner][runner] rejects only `timeout <= 0`; it has no finiteness check before report writing or process launch. Reports include actual Python-runner and synthetic-helper witnesses. | Reject NaN and infinities before creating output or launching a process; define how unsupported huge finite durations are handled. A proposed one-day ceiling is a policy choice, not an existing requirement. Cover parser errors, ordinary finite timeouts, process cleanup, and valid JSON. Cross-platform exception text need not match. |
| **W4-02 · Executed source provenance and dependency closure** | **Mechanisms present.** The [runner][runner] fingerprints siblings only for an entry named `AsymptoticAnalysis.wl` in a directory named `Kernel`; `init.m` and other relocated layouts need separate treatment. It executes a live package path, copies only the suite, does not recheck that copied suite, and recomputes `before == after` on every write. An observed mismatch can therefore be forgotten after restoration. | Preserve monotone invalidation and the first mismatch; explicitly describe the source layout or dependency set. Stage coherent package, suite, and runner inputs before execution and verify the staged inputs. Endpoint hashes alone cannot exclude a change-and-restore wholly between observations. The [acceptance checker][acceptance] validates recorded hashes against Git blobs; it does not freeze inputs for the runner that produced them. |
| **W4-03 · Interpreter invocation identity** | **Mechanism present.** Existing executable paths are passed through `Path.resolve()` in the [runner][runner]. Report 31's POSIX virtual-environment witness exercises that path-identity issue independently of Mathics. | Preserve the executable invocation path while making it absolute; distinguish an executable path from a command found through PATH. Check a symlinked virtual-environment Python, an ordinary interpreter, missing paths, and Windows launchers. Do not infer a complete Mathics run from a Python environment-only witness. |
| **W4-04 · Interrupted in-flight cases** | **Mechanism present.** The [runner][runner] appends a case only after `run_case` returns. It cleans up on interruption, but an interrupted active case is absent from the last saved result list. The saved run remains incomplete; this is not by itself a false-success finding. | Record the active case before launch and persist an explicit interrupted outcome with available diagnostics during unwinding. Preserve process-tree ownership, completed results, atomic writes, and launch-error behavior. Report 29's SIGINT fixture is POSIX evidence; Windows interruption needs its own check. |
| **W4-05 · Mandatory load success** | **Mechanism present.** [MathicsTests.wl][suite] stores `portableLoadResult = Check[Get[...], $Failed]` and then defines/selects tests without a global load-success gate. A selected primitive test can be independent of package symbols. The report's failed-load fixture was not run as part of this intake. | Require successful setup before every selected case can report a pass. Preserve loading diagnostics and distinguish a returned `$Failed`, a message, missing exports, and an interrupted load. Validate both layouts and both runtimes without making a package-independent primitive assertion certify package loading. |
| **W4-06 · Diagnostic output budgets** | **Mechanism present.** `communicate()` retains the complete merged output in the [runner][runner], and each report write serializes accumulated diagnostics again. No byte ceiling is present. The supplied bounded supervisors were tested with synthetic children. | Bound captured output while retaining a useful prefix/tail or separate diagnostic artifact, explicit overflow status, and reliable timeout/cleanup. Measure actual I/O and memory before claiming a speedup. POSIX prototype success does not establish Windows process-tree behavior or reproduce a real package out-of-memory event. |
| **W4-07 · Complete inventory and CI triggers** | **Partly addressed.** The [Mathics workflow][workflow] already includes `validation/build_standalone.py` and `validation/test_standalone.py` in both push and pull-request path filters, so report 34 R4's concrete trigger omission is repaired in the inspected source. The [runner][runner] and [acceptance checker][acceptance] still derive cases from the same strict line-oriented regular expression. The workflow's group partition is maintained separately. | Preserve the repaired triggers. Check every legal/admitted test declaration and every group exactly once per layout; reject unsupported declaration syntax instead of silently omitting it. Add formatting, comments/strings, duplicate-ID and new-group mutations. The checker already validates complete receipt unions against its parsed reference inventory; that does not independently prove the parser recognized every declaration. No current missing case or shard is asserted here. |

### Mathics semantics and resource behavior

| Item | Current-source disposition | Required work and acceptance boundary |
| --- | --- | --- |
| **W4-08 · ProductLog conversion and nonprincipal evaluation** | **Open compatibility work; documentation clarified.** [MathicsCoreFunctions.wl][core] rewrites selected principal-branch construction sites to one-argument `ProductLog`; other branches retain the System two-argument head. Reports trace exact/reverse SymPy conversion and numerical-arity problems and supply independent countermodels. The [maintained algebra note][algebra-doc] now covers the symbolic and numerical boundaries; that clarification does not repair the interpreter bridge. Those interpreter traces are report evidence, not a fresh runtime reproduction here. | Test exact, symbolic, approximate, forward and reverse conversion, derivatives, all retained construction sites, and later `Normal[s]`/`s[value]` specialization. Preserve real branch conditions. A conservative capability refusal avoids an unsafe numerical claim but does not complete compatibility. Rational entropy/Lambert certificates and floating-point log-excess solvers are different candidate implementations with different guarantees. |
| **W4-09 · Achieved numerical precision** | **Source gap identified; public witness unverified.** [NumericalInverseChecks.wl][numerics] requests working precision and validates numeric/branch/domain results, but has no explicit achieved-precision postcondition for the returned root. Its output calls the result a high-precision comparison. Report 28 traces interpreter numerical limitations; this intake does not reproduce them. The [compatibility note][compatibility-doc] now distinguishes requested working precision from achieved accuracy. | Characterize well-conditioned exact roots at increasing requested precision, then ill-conditioned cases and branch-sensitive targets. Require measured achieved accuracy/precision or a clear unsupported/failure result; extra printed digits are not evidence. Retain the distinction between a numerical comparison, a residual, and an interval certificate. Include the separate Gamma/Barnes and special-adapter numerical paths when defining a shared contract. |
| **W4-10 · Limit default semantics** | **Mechanism present; public wrong-result reachability unverified.** [MathicsSimplification.wl][simplification] maps omitted/`Automatic` direction to `1`. Reports compare this with the recorded Wolfram real two-sided default. Several inspected branch consumers already supply a direction, so the helper mismatch alone does not establish an incorrect public expansion. | Identify every implicit-direction consumer. Supply an explicit local side where mathematically justified; otherwise implement or conservatively retain two-sided semantics. Test agreeing and disagreeing one-sided limits, unresolved sides, assumptions, infinities, and explicit direction controls. Replacing the lower side with the upper side does not implement a two-sided limit. |
| **W4-11 · FirstPosition grammar and traversal** | **Mechanisms present.** [MathicsCompatibility.wl][compat] implements first position by collecting `Position` results, then taking the first. Its three-argument form treats the third argument as a default, including an option-shaped expression. Reports identify both grammar and allocation/work questions. | Preserve defaults lazily, level specifications, `Heads`, missing cases, and supported option forms. A narrow level-one fast path or an upstream primitive needs traversal-law tests. Do not assume a native bounded-`Position` overload exists on the pinned Mathics version. Report 36's native probe did not establish its proposed callback distinction; allocation evidence is separate from side-effect semantics and timing. |
| **W4-12 · Empty-list Map coverage** | **Coverage boundary remains.** [MathicsLists.wl][lists] rewrites references only in `AsymptoticAnalysis`'s private context. The public [InverseExpansionCoefficient definition][main] maps over its multi-index, and [Mathics-context Lookup helpers][compat] map over key/association lists. These are distinct sites outside that sweep. The predicted caller-list cache manifestations were not exercised here. | Characterize valid empty indices, empty key lists and lists of associations, followed by reuse of the caller-owned empty list. Extend protection only where needed, preserving explicit levels/options and nonempty behavior. Keep System definitions unchanged; do not equate coverage of one private `Map` fixture with all package call sites. |
| **W4-13 · Sparse coefficient and Fourier amplitude storage** | **Mechanisms present.** [MathicsAlgebra.wl][mathics-algebra] calls `CoefficientList` before removing zeros. [MathicsInverseBranches.wl][branches] also scans dense polynomial coefficients. [FourierCoefficients.wl][fourier] uses dense logarithmic-polynomial lists in realness and envelope calculations. Fixed outer support does not bound these inner degree-sized intermediates. | Provide sparse exact extraction for an explicitly supported grammar, with separately budgeted expansion and bounded fallback. Compare coefficients, realness, logarithmic degrees, conjugacy and absolute envelopes on fixed-support increasing-degree inputs. Independent Python models are useful oracles, not kernel memory benchmarks. The peer Fourier termination change below addresses unnecessary products, not these inner polynomial representations. |
| **W4-14 · Retained-frontier membership cost** | **Mechanism present.** [Mathics `KeyExistsQ`][compat] maps over `Keys[a]`; [IncrementalInverse.wl][incremental] uses membership checks while extending the retained boundary. This adds potential boundary-size work despite retained inverse state. | Profile actual membership/enumeration work and preserve exact key identity, grouping, persistent-state behavior and statistics. Compare with fresh reconstruction over increasing boundary sizes. An exact counting model is not an end-to-end Mathics speedup, and successful retained-state tests do not measure lookup complexity. |
| **W4-15 · Parameter assumptions in polynomial-domain proofs** | **Mechanism present.** [mathicsPolynomialFunctionDomain][branches] receives the body, variable and `Reals`, and checks `exactRealQ` on its coefficients. The replacement for `FunctionDomain` does not explicitly receive the branch validator's retained `ass` argument. | Thread the retained assumptions into this bounded proof without accidentally using unrelated global assumptions. Cover proved-real symbolic coefficients, unknown/nonreal coefficients, affine domains and parameter capture. Real-valuedness on a domain is not monotonicity, injectivity or global branch selection; preserve those separate obligations. The report's public path remains unverified here. |
| **W4-16 · Constructive eventual neighborhoods** | **Bounded extension required.** [MathicsInverseBranches.wl][branches] tries radii `2^-j` for `j = 0..6`, then delegates to the existing general fallback. Failure at those trial radii does not disprove an eventual condition. Reports supply rational affine or polynomial radius constructions. | Start with a declared exact grammar, construct a positive radius, and independently verify the entire deleted interval. Preserve strict/non-strict inequalities, equalities, conjunctions, real operands, symbolic margins and unknown-sign refusals. Never use existence of some smaller neighborhood as truth on a caller-specified fixed interval. Polynomial eventual sign alone is not global branch uniqueness. |

### Mathematical extensions and adapter maintenance

| Item | Current-source disposition | Required work and acceptance boundary |
| --- | --- | --- |
| **W4-17 · Defining Taylor extensions** | **Proposal; current provider gate confirmed.** [MathicsTaylor.wl][taylor] requires `Length[upper] <= Length[lower] + 1` and positive lower parameters before its coefficient construction. The proposals distinguish finite terminating PFQ polynomials from nonterminating convergence and consider some negative nonintegral lower parameters with explicit tails. Native pre-evaluation may already simplify particular public inputs, so provider rejection is not proof of every proposed public failure. | Detect exact termination before applying a nonterminating rank condition; define denominator-pole and regularization policies explicitly. Preserve finite-order omitted terms and exact-zero termination. For an enlarged infinite family, prove the stated tail under its parameter restrictions rather than importing the finite argument. Test native simplification and direct provider entry separately, plus arity, resources, complex parameters and unsupported cases. |
| **W4-18 · Gamma-specific Newton reversion** | **Development proposal.** [GammaInverse.wl][gamma] computes the normalized unit by a triangular coefficient recurrence. Report 29 supplies independent triangular/Newton agreement and a unit-Jacobian derivation; it does not integrate a package algorithm or benchmark the production path. | Compare complete inverse-logarithmic coefficient polynomials, low-order independent oracles, affine/observable reconstruction, frontiers, resource limits and Poincare remainder metadata. Benchmark equal output/order and account for algebraic expression growth. This is distinct from the already implemented ordinary inverse Newton algorithm. Do not transfer Gamma acceptance automatically to Barnes G. |
| **W4-19 · Adapter installation invariants** | **Preventive proposal.** Late [core][core], [refinement][mathics-refinement], [branch][branches] and [list][lists] adapters transform named definitions or scan private downvalues. The reports request match counts and postconditions; they do not establish a failed current installation. | Declare intended transformation targets and check postconditions after load/reload. Mutation fixtures should detect missing, duplicated or structurally changed targets, while successful preservation checks keep System definitions and held evaluation behavior intact. A match count alone cannot prove the replacement's semantics. |
| **W4-20 · Interrupted loading and context cleanup** | **Source-level exception-safety advisory.** The [main loader][main] removes the Mathics context after the module loads and `EndPackage[]`. This final cleanup is not enclosed in an explicit abort-safe restoration boundary. The report's interrupted-load manifestations remain unverified. | Characterize message, failure and abort paths during early and late loading, then attempt a clean reload. Restore the caller's context state appropriately without masking the original failure or changing System definitions. Normal successful load/reload tests do not cover interrupted parsing or partially installed definitions. |

## Complete report-to-work mapping

Each row below is one original ledger entry. Evidence phrases summarize the
supplied ledger; they do not promote a report's source trace to a runtime
observation. Read the linked primary ledger and package README for details.

| Report / ID | Attributed contribution and evidence boundary | Work items |
| --- | --- | --- |
| [28 F01][R28] | Requested versus achieved root precision; interpreter source trace, public runtime probe unexecuted. | W4-09 |
| [28 F02][R28] | Retained lower-Lambert core specialization; source trace plus independent countermodel/rational certificate. | W4-08 |
| [28 F03][R28] | Omitted Limit direction; explicit-direction consumers excluded from the claim. | W4-10 |
| [28 F04][R28] | FirstPosition option-only grammar and all-match materialization; source analysis, probes unrun. | W4-11 |
| [28 F05][R28] | Nonfinite deadlines; guard countermodel and repaired validator executed independently. | W4-01 |
| [28 F06][R28] | Endpoint hashes versus executed bytes; edit/revert and synthetic immutable-Git checks. | W4-02 |
| [28 F07][R28] | Unbounded diagnostics/report serialization; bounded POSIX supervisor tested with synthetic children. | W4-06 |
| [28 E01][R28] | Exact rational affine radius construction; prototype executed, public fallback behavior unestablished. | W4-16 |
| [28 E02][R28] | Terminating PFQ exception; exact coefficient prototype, native simplification may bypass the provider. | W4-17 |
| [28 E03][R28] | Late-downvalue rewrite invariants; preventive proposal, no failed installation asserted. | W4-19 |
| [29 N1][R29] | Nonfinite/oversized timeouts; actual upstream runner with simulated kernel protocols. | W4-01 |
| [29 N2][R29] | `init.m` dependency monitoring; synthetic dependency-tree mutation. | W4-02 |
| [29 N3][R29] | Missing active case after interruption; POSIX SIGINT fixture, not a false-success allegation. | W4-04 |
| [29 N4][R29] | FirstPosition traversal; algorithmic analysis and unexecuted adapter specification. | W4-11 |
| [29 D1][R29] | Limit default; native Sign controls executed, no public incorrect expansion alleged. | W4-10 |
| [29 P1][R29] | Gamma-specific formal Newton recurrence; exact independent coefficient comparisons. | W4-18 |
| [29 P2][R29] | Real lower-Lambert solver in a log-excess coordinate; numerical prototype and bracket proof, not an interval certificate. | W4-08 |
| [30 F1][R30] | Observed mutation forgotten after restoration; actual runner fixture and tested narrow latch. | W4-02 |
| [30 F2][R30] | Renamed modular directory loses sibling monitoring; runner fixture and synthetic staging. | W4-02 |
| [30 F3][R30] | Nonprincipal exact-core numerical capability; independent conversion countermodel, public Mathics call unrun. | W4-08 |
| [30 F4][R30] | Dense sparse-coefficient conversion and first-position materialization; source complexity, no kernel benchmark. | W4-11, W4-13 |
| [30 F5][R30] | Limit omitted-direction mismatch; public reachability unconfirmed. | W4-10 |
| [30 F6][R30] | Bounded defining Taylor families and tails; constructive extension with independent exact oracles. | W4-17 |
| [31 N1][R31] | Executable symlink escapes virtual-environment identity; real Python environment witness, not a Mathics run. | W4-03 |
| [31 N2][R31] | Invalid subprocess durations; Python/Linux witnesses and candidate helper tests. | W4-01 |
| [31 N3][R31] | First-match consumer performs all-match traversal; source and counting model. | W4-11 |
| [31 N4][R31] | No diagnostic byte ceiling; bounded POSIX prototype, no package out-of-memory observation. | W4-06 |
| [31 A1][R31] | Limit default audit candidate; no public wrong-result reachability established. | W4-10 |
| [31 A2][R31] | Empty Lookup maps outside private-context protection; caller-list effects unverified. | W4-12 |
| [32 M01][R32] | ProductLog exact/reverse conversion, numerical arity and construction-site coverage; independent bridge countermodels. | W4-08 |
| [32 M02][R32] | Retained parameter assumptions omitted from polynomial-domain helper; exact reference oracles, package path unrun. | W4-15 |
| [32 M03][R32] | Parameter-sensitive positive radii versus fixed-interval truth; exact polynomial reference cases. | W4-16 |
| [32 D-P06][R32] | Dense inner logarithmic-polynomial/Fourier degree; sparse reference, no native benchmark. | W4-13 |
| [32 D-V01][R32] | Source equality at endpoints versus coherent frozen inputs; synthetic change-and-restore countermodel. | W4-02 |
| [32 L01][R32] | Automatic Limit side; inspected branch consumers specify a side. | W4-10 |
| [32 G01][R32] | Finite rank-excess PFQ polynomial; exact oracle, native pre-evaluation caveat. | W4-17 |
| [32 T01][R32] | Nonfinite timeout validation; synthetic helper tests, repository patch not applied. | W4-01 |
| [33 F01][R33] | Symbolic ProductLog argument roles; direct SymPy-stage checks, public core call unrun. | W4-08 |
| [33 F02][R33] | Public empty multi-index maps outside the private sweep; predicted alias/cache effect unrun. | W4-12 |
| [33 F03][R33] | Primitive selected case after failed Get; control-flow analysis, fixture invocation unrun. | W4-05 |
| [33 F04][R33] | Implicit Limit side; no public incorrect expansion established. | W4-10 |
| [33 F05][R33] | FirstPosition collection and symbolic-merge work; independent counting model. | W4-11 |
| [33 A01][R33] | Dense coefficient conversion; public stress path not established. | W4-13 |
| [33 A02][R33] | Interrupted load bypasses context cleanup; static advisory, interruption tests unrun. | W4-20 |
| [34 R1][R34] | ProductLog exact/reverse conversion and numerical arity; independent backend/rational checks, integration unexecuted. | W4-08 |
| [34 R2][R34] | Source-change restoration and unchecked copied suite; actual runner with synthetic processes. | W4-02 |
| [34 R3][R34] | Nonfinite/huge deadlines; original/candidate runner reproduction. | W4-01 |
| [34 R4][R34] | CI path filters omitted a direct builder dependency; repaired in the inspected workflow. | W4-07 |
| [34 R5][R34] | Dense coefficient/amplitude storage and unavailable bounded Position shortcut; structural cost evidence. | W4-11, W4-13 |
| [34 R6][R34] | Limit default; independent mathematical counterexample, public reachability unestablished. | W4-10 |
| [35 N01][R35] | Previously detected mutation forgotten; actual runner and candidate with protocol fixtures. | W4-02 |
| [35 N02][R35] | Nonfinite CLI values and JSON tokens; original/candidate infrastructure observations. | W4-01 |
| [35 N03][R35] | Sparse coefficient/branch paths allocate dense lists; exact reference models, no kernel allocation experiment. | W4-13 |
| [35 N04][R35] | All-match FirstPosition and unsupported obvious bounded overload; source/counting evidence. | W4-11 |
| [35 N05][R35] | Seven trial radii miss arbitrarily small affine neighborhoods; constructive proof, public refusal predicted. | W4-16 |
| [35 N06][R35] | Local Limit default; inspected inverse validator explicitly supplies its direction. | W4-10 |
| [36 N01][R36] | Constructive rational polynomial neighborhood; public witness unexecuted. | W4-16 |
| [36 N02][R36] | Full association-key scans in retained frontier extension; exact cost model, no Mathics timing. | W4-14 |
| [36 N03][R36] | Degree-sized CoefficientRules intermediate; source allocation analysis. | W4-13 |
| [36 N04][R36] | FirstPosition materialization; supplied native query did not establish the proposed semantic distinction. | W4-11 |
| [36 N05][R36] | Declaration/group inventory can omit legal forms; synthetic mutations, no current omitted case claimed. | W4-07 |
| [36 N06][R36] | Nonfinite timeout guard; independent Python reproduction. | W4-01 |
| [36 N07][R36] | Terminating PFQ provider admission; exact identities, integration unexecuted. | W4-17 |
| [36 A01][R36] | AST rewrite match counts/postconditions; preventive proposal, no current failed rewrite reproduced. | W4-19 |

## Later integration and peer evidence

The following revisions were inspected from local Git objects, separately
from the `38aa253` working-source audit. The Fourier change was merged in
`9b83d04`; the Mathics acceptance update remains peer evidence at this
intake's final review. Their evidence stays attached to the tested commits.
The intervening documentation change `b145cb9` also clarified the symbolic
ProductLog and achieved-precision boundaries in the maintained guides, as
recorded in W4-08 and W4-09.

- **Mathics peer `4da0dbc`.** Its [published acceptance record](https://github.com/VladimirReshetnikov/Asymptotic/blob/4da0dbc/validation/mathics-linux-ffe08b1-acceptance.json)
  reports 202 successful observations: all 101 portable cases exactly once
  in each layout across ten shards, checked against the immutable
  `ffe08b18ea2a6a72546503b135b47b4979e7d010` reference. The record distinguishes
  the original MUnit suite and all possible inputs, and marks the requirements
  file hash as `NotRecorded` in the supplied receipts. This supersedes a
  pending full-portable-run statement for that snapshot, not the specific
  adversarial runner/adapter obligations above. Later [recursive-logarithm
  checks](https://github.com/VladimirReshetnikov/Asymptotic/blob/4da0dbc/validation/mathics-recursive-log-power-guard-audit.json)
  cover their separate source delta. The peer does not replace the live-source
  execution/fingerprinting mechanism in the portable runner.
- **Merged Fourier revision `10fe5d2`.** Its [source change](https://github.com/VladimirReshetnikov/Asymptotic/commit/10fe5d2a22ad88fd1347774cb1f9249ddaf9ddb6)
  tests positive-valuation support exhaustion and complete homogeneous
  coefficient cancellation before multiplying another Fourier power. The
  [focused receipt](https://github.com/VladimirReshetnikov/Asymptotic/blob/10fe5d2/validation/fourier-termination-tests.json)
  reports 68/68 selected native tests; the [loading receipt](https://github.com/VladimirReshetnikov/Asymptotic/blob/10fe5d2/validation/fourier-termination-loading-tests.json)
  reports 105/105 checks across five fresh kernels. This addresses the
  separate W3-13/P03 termination path. It leaves the `CoefficientList`
  representations relevant to W4-13 and the Mathics key/search mechanisms
  relevant to W4-11/W4-14 unchanged. No Mathics feature acceptance or general
  performance improvement follows from those native receipts.

## Integration order and closure evidence

First protect the evidence pipeline: W4-01–W4-07 can be characterized largely
with controlled Python fixtures before rerunning expensive package cases.
Keep real-kernel acceptance separate from those infrastructure tests. Then
establish exact ProductLog conversion and the numerical capability boundary,
followed by the bounded helper contracts and their public consumers.
Sparse storage, lookup costs, radius construction and new Taylor/Gamma
algorithms require their own correctness and resource comparisons.

For each implemented item, retain the baseline source, actual observed
failure or limitation, candidate source, focused controls, and limitations
of the final acceptance. Add public cases where reachability was previously
only predicted. Do not mark an entire grouped item complete when only one
call site, platform, branch, or prototype is covered. The
[implementation register](CODE_REVIEW_STATUS.md) should link that evidence
when recording a changed disposition; the original ledgers remain intact.

[R28]: ../../external-reports/code-review/wave-4/code-review-28/evidence/novelty-ledger.csv
[R29]: ../../external-reports/code-review/wave-4/code-review-29/results/novelty-ledger.json
[R30]: ../../external-reports/code-review/wave-4/code-review-30/evidence/findings.json
[R31]: ../../external-reports/code-review/wave-4/code-review-31/evidence/novelty_ledger.csv
[R32]: ../../external-reports/code-review/wave-4/code-review-32/evidence/novelty-ledger.csv
[R33]: ../../external-reports/code-review/wave-4/code-review-33/evidence/source-novelty-ledger.json
[R34]: ../../external-reports/code-review/wave-4/code-review-34/evidence/novelty-ledger.csv
[R35]: ../../external-reports/code-review/wave-4/code-review-35/evidence/novelty_ledger.csv
[R36]: ../../external-reports/code-review/wave-4/code-review-36/results/novelty_ledger.csv
[runner]: ../../validation/run_mathics_tests.py
[suite]: ../../validation/MathicsTests.wl
[acceptance]: ../../validation/check_mathics_acceptance.py
[workflow]: ../../.github/workflows/mathics.yml
[compat]: ../../src/Kernel/MathicsCompatibility.wl
[core]: ../../src/Kernel/MathicsCoreFunctions.wl
[algebra-doc]: ../Mathics/ALGEBRA.md
[compatibility-doc]: ../Mathics/COMPATIBILITY.md
[numerics]: ../../src/Kernel/NumericalInverseChecks.wl
[simplification]: ../../src/Kernel/MathicsSimplification.wl
[lists]: ../../src/Kernel/MathicsLists.wl
[main]: ../../src/Kernel/AsymptoticAnalysis.wl
[mathics-algebra]: ../../src/Kernel/MathicsAlgebra.wl
[branches]: ../../src/Kernel/MathicsInverseBranches.wl
[fourier]: ../../src/Kernel/FourierCoefficients.wl
[incremental]: ../../src/Kernel/IncrementalInverse.wl
[taylor]: ../../src/Kernel/MathicsTaylor.wl
[gamma]: ../../src/Kernel/GammaInverse.wl
[mathics-refinement]: ../../src/Kernel/MathicsRefinement.wl
