# Code review implementation status

Updated September 9, 2026. This register consolidates the **119 numbered finding
entries in all seventeen [review packages](../../code-review/README.md)** into shared
work items. It also records substantive roadmap proposals separately. It is a
work map, not a claim that every recommendation is a defect or an accepted API
change.

Reviews 1–6, 8, and 9 examine `07a9781212beb2eeb9ff16aa625b50ac27974078`;
review 7 examines `75de8756175911cd8830704fd1a3406c1022f018`. Their supplied
patches and native observations concern those snapshots. Preserve their notices
and check current source before adapting a patch. Reviews 3 and 8 include limited
native execution; the other reports' independent mathematical and patch-fixture
checks do not execute this package. See the [review index](../../code-review/README.md)
for each report's evidence boundary.

Wave 2 adds reports 10–17, all pinned to
`921387e5ba1239bfda96e63e64e89bf63d9c41e6`, with 32 numbered items.
Reports 10–13 and 17 record selected Wolfram 15.0.0 Linux observations;
reports 14–16 record independent checks without successful package execution.
These snapshots precede the recent C04–C07 repairs. The eight supplied packages
were merged from `origin/main` commit `c19c0cd` without editing their contents.
See the [wave-2 index](../../code-review/wave-2/README.md).

Status meanings:

- **Focused verified:** the implementation and a named current native test record
  were inspected. This does not imply full-suite acceptance.
- **In progress:** assigned implementation, awaiting its acceptance record.
- **Pending — source inspected:** the relevant current code pattern was inspected;
  no new native reproduction is claimed here.
- **Audit candidate:** a proof obligation or possible public route remains to be
  reproduced. It is not a demonstrated wrong result.
- **Decision / deferred:** an API, release-policy, or mathematical extension needs
  an explicit scope decision. It is not silently part of a correctness repair.

The current user instruction is to **skip the full suite**. Focused native
acceptance remains appropriate; the broader release-gate proposal below is
recorded without overriding that instruction. This register was prepared by
reading the ledgers, relevant report sections, source, and existing validation
artifacts. Current native claims refer only to the named focused records and
the separately identified wave-2 characterization probes.

## Correctness and information preservation

### Required native expansion coverage

The updated user objective requires the package's expansion functionality to
handle every input successfully handled by built-in `Series` or `Asymptotic`,
with a different result form permitted. This is an accepted requirement, not
an optional extension or a claim about current coverage. The existing public
name is `AsymptoticExpansion`; the user refers to the target functionality as
`AsymptoticExpand`.

| ID | Required work and acceptance boundary |
| --- | --- |
| B01 | **Pending — accepted scope.** Preserve access to the native engines for all their successful input families, including complex, approximate, symbolic, opaque-function and multivariable expansions. Current real power-log admission is a representation contract, not grounds for permanently excluding a native-supported input from the expansion API. |
| B02 | **Pending.** Define and implement compatible call forms, option forwarding, order conventions, native method selection and held evaluation. Existing exclusive power cutoffs and complete-block goals must remain explicit when adapting native order specifications. |
| B03 | **Pending.** Represent native formal series and native asymptotic results without inventing analytic remainder proofs. Preserve conditions, coordinates, nested orders and branch information. `Normal` must give the finite native expression; operations must retain each result's actual uncertainty contract. Coordinate with C06, C07, C13 and C16. |
| B04 | **Pending.** Record differential native comparisons across the documented input/option families, including R17 N4's Zeta comparison, and correct claims of native unavailability. A finite passing corpus supports particular cases; full coverage needs an implementation argument that the native-supported path remains available. Keep focused runs under the user's no-full-suite instruction. |

Native-supported complex and formal cases in B01–B03 are required even where
the broader custom complex-sector research proposal X09 remains separate.

### C01 — Bound optional native `SeriesData` allocation

**Focused verified.** A shared `makeRationalSeriesData` now allocates through the
last retained coefficient rather than padding to the remainder frontier, while
preserving the denominator and native order. A 100,000-position limit returns
`Missing["DenseSeriesDataLimit", metadata]` for an oversized optional view. Empty
inverse coefficients are handled. The sparse result remains available.

Source: [core exporters](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
[ReviewNativeExport.wlt](../../AsymptoticInverse/Tests/ReviewNativeExport.wlt)
contains 13 targeted cases. The inspected
[five-file native record](../../validation/review-native-export-tests.json)
reports **115 successes, 0 failures**, Wolfram 15.0.1 for Windows, and unchanged
sources during the run. The [before](../../validation/review-native-export-benchmark-before.json)
and [after](../../validation/review-native-export-benchmark-after.json) benchmark
records preserve the measured workload evidence. This is bounded eager export;
fully lazy export and a public configurable representation budget remain design
options. It does not resolve C03.
Published implementation: `0e96e6b`.

Findings: [R1 A02][R1], [R2 F04][R2], [R3 F02][R3], [R4 A02][R4],
[R5 F01][R5], [R6 A01][R6], [R7 F01][R7], [R8 F03][R8], [R9 F01][R9].

### C02 — Share the real-branch guard for powers of pure uncertainty

**Focused verified.** The shared `fwdPower` path now rejects an unproved real
fractional power of pure uncertainty, closing recursive routes that bypassed
the direct operation guard. Exact-zero and positive integer cases remain
distinct from an unknown-sign remainder and a proved positive leading term.
The inspected [baseline record](../../validation/review-power-branches-baseline.json)
reports 10 successes and six branch-case failures on `73aabf2`; the
[post-fix record](../../validation/review-power-branches-tests.json) reports
**148 successes, 0 failures** across six selected files, with unchanged sources
during the run. Its 16 new
[branch regressions](../../AsymptoticInverse/Tests/ReviewPowerBranches.wlt)
cover recursive and direct routes and valid controls. Published implementation:
`921387e`.

Sources: [core `fwdPower`](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl),
[operation dispatch](../../AsymptoticInverse/Kernel/SeriesOperations.wl).
Existing neighboring regressions: [SeriesOperations](../../AsymptoticInverse/Tests/SeriesOperations.wlt),
[SeriesArithmetic](../../AsymptoticInverse/Tests/SeriesArithmetic.wlt).
Findings: [R1 A01][R1], [R2 F02][R2], [R3 F01][R3], [R4 A01][R4],
[R5 F02][R5], [R7 F02][R7], [R8 F02][R8].

### C03 — Make logarithmic information loss on native export explicit

**Focused verified.** An otherwise eligible optional native view now returns
`Missing["LogarithmicRemainder", metadata]` when the recorded remainder degree
is nonzero. The metadata retains its power and logarithmic degree. Retained
logarithmic coefficients still export when the remainder degree is zero;
coordinate, exactness and irrational-exponent guard precedence is preserved.
The new guard runs before dense allocation. No exponent is silently weakened.

The [export baseline](../../validation/review-native-tail-export-baseline.json)
records four passes and eight failures in 12 new cases against `a2c05e1`.
The [nine-file acceptance](../../validation/review-native-tail-tests.json)
records **197 passed, zero failed**, including all 12 export and 16 import
regressions, with unchanged sources and all final source hashes verified.
See the [native-remainder notes](NATIVE_SERIES_REMAINDERS.md) for the formal
versus analytic distinction and the separate incoming-tail contract.

Source: [core exporters](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
Require forward/inverse tests with positive logarithmic degree and unchanged
ordinary algebraic exports. Findings: [R1 A03][R1], [R2 F03][R2], [R3 F03][R3],
[R6 A02][R6], [R9 F06][R9].

### C04 — Preserve nonlinear logarithmic degree at an input precision ceiling

**Focused verified.** `unitSeriesPrecision` now combines the input logarithmic
degree with the Taylor-product majorant whenever the input sets the active
frontier, including a request beyond that frontier. It retains the maximum
degree of every input block, so a later logarithmic block cannot disappear
from the bound. The estimate is conservative and need not detect cancellations
among complete boundary polynomials.

Source: [core `unitSeriesPrecision` / `pUnitSeries`](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
The 15 new [precision tests](../../AsymptoticInverse/Tests/ReviewUnitPrecision.wlt)
cover explicit logarithm, exponential, radical, reciprocal and sine witnesses,
an irrational frontier, later-block degrees, inherited errors and exact cases.
The [baseline record](../../validation/review-unit-arithmetic-baseline.json)
has eight precision failures; the [nine-file acceptance](../../validation/review-unit-arithmetic-tests.json)
has **196 successes, 0 failures**, including the recurrence tests below, with
unchanged sources during the run. Finding: [R2 F01][R2].

### C05 — Retain every assumption used to establish a reusable result

**Focused verified.** All nine constructors now capture the
ambient default through `Assumptions :> $Assumptions`; explicit options replace
it. A shared request boundary isolates internal proofs from later ambient
assumptions, including arithmetic, observables, coefficient queries and replay.
Models retain their parameter assumptions, and coefficient queries inherit them.
Delayed options are resolved before dispatch and forwarded as immediate rules;
nested option lists and specialized constructor paths are covered.

The original 17 [assumption regressions](../../AsymptoticInverse/Tests/ReviewAssumptions.wlt)
all fail against pinned kernel `e9c9eb9` in the
[baseline record](../../validation/review-assumptions-baseline.json). The
[acceptance record](../../validation/review-assumptions-tests.json) identifies
**200 passed, zero failed** across eight selected files. The
[supplemental replay record](../../validation/review-assumption-replay-tests.json)
adds **12 passed, zero failed** for delayed options, all remaining specialized
constructors, nested callbacks, representations and retained state. Both records
match the current source hashes and report unchanged sources during execution.
The [implementation notes](ASSUMPTION_CONTEXT.md) explain the policy, nested-state
requirements and evaluation limits. The mathematical article and user guide
now discuss retained parameter domains and distinguish pointwise from uniform
asymptotic claims. The six specialized constructors retain their existing
parameter-only assumption restriction.

Sources: [core assumption splitting](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl),
[public expression adapters](../../AsymptoticInverse/Kernel/InverseFunctionExpressions.wl).
Findings: [R1 A04][R1], [R3 F04][R3], [R6 A12][R6], [R8 F01][R8].

### C06 — Reconcile unresolved logarithmic tails in native import paths

**Focused verified under the admitted native tail contract.** Native execution
confirmed a public wrong bound for
`AsymptoticExpansion[EllipticK[1-x^2]/x^3, {x,0,3}]`: the old result reported
power three and degree zero even though the next block contains `x^3 Log[x]`.
The corrected result retains the same finite expression and reports `{3,1}`.
Private elliptic and Bessel Laurent witnesses reproduce the same lost degree.

Both incoming paths now share a half-lattice power allowance for an unknown
fixed finite logarithmic degree. The ordinary fallback normalizes both complete
probes and sharpens only from a compatible, more precise second expansion.
An empty second difference retains a conservative unknown tail; invalid or
unresolved second probes leave the first bound in place. Laurent/Puiseux
composition transports the same allowance. The Taylor path checks that its
native endpoint exceeds the coefficient order it needs.

The [import baseline](../../validation/review-native-tail-import-baseline.json)
records **four passes and five failures** for the nine tests exercising
pre-existing paths on `a2c05e1`; seven new-helper contract tests are excluded
from that baseline. All 16 import tests pass in the
[197-test acceptance](../../validation/review-native-tail-tests.json).
This closes the identified unsafe inference; it does not infer a tail theorem
for an arbitrary function from a finite native coefficient list. The required
finite-logarithmic tail premise is stated in the article and
[native-remainder notes](NATIVE_SERIES_REMAINDERS.md).

Sources: [ordinary fallback](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl),
[structured importer](../../AsymptoticInverse/Kernel/NativeSpecialFunctions.wl).
Regressions: [ReviewNativeTailImport](../../AsymptoticInverse/Tests/ReviewNativeTailImport.wlt),
[NativeSpecialIngress](../../AsymptoticInverse/Tests/NativeSpecialIngress.wlt).
Findings: [R4 R03][R4], [R7 F03][R7].

### C07 — Apply the advertised real-coefficient contract consistently

**Focused verified for the ordinary real representation.** Complete coefficient
rows are normalized and checked at forward-result, inverse-model and explicit
series-operation boundaries. The inverse offset is checked before extraction.
Temporary complex summands and Taylor coefficients can cancel; ordinary proof
uses `Simplify` followed by a one-second `FullSimplify` fallback when needed.
Failure metadata distinguish proved nonrealness from an unproved condition.
Observable Taylor probes use a signed positive local increment.

The [23 focused cases](../../AsymptoticInverse/Tests/ReviewRealCoefficients.wlt)
cover constant/native coefficients, offsets, retained assumptions, cancellation,
known exact blocks above a requested cutoff and real special-function controls.
The [eleven-file acceptance](../../validation/review-real-coefficients-tests.json)
records **280 passed, zero failed** on Wolfram 15.0.1 Windows with unchanged
sources. The pinned `7d98eca` baseline records 12 passed and 11 failed.
Implementation checkpoint: `5ca0ee7`. See [coefficient notes](REAL_COEFFICIENTS.md).

This check does not prove arbitrary sources real or analytic, nor settle
semantic exponent grouping (C14). Native-supported complex/formal inputs need
the distinct compatibility representation in B01–B03; they must not remain
excluded merely because they do not satisfy the real representation's contract.

Sources: [core constants and analytic expansion](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl),
[observables](../../AsymptoticInverse/Kernel/SeriesOperations.wl),
[special-function domains](../../AsymptoticInverse/Kernel/SpecialFunctionRealDomain.wl).
Findings: [R4 R02][R4], [R7 F04][R7], [R9 F04][R9], [R11 N04][R11],
[R12 N02][R12], [R13 A2][R13]. The wave-2 nonreal algebraic-root witness
is now rejected by this real representation, as recorded in the intake probe.

### C08 — Make refinement meet or honestly report its precision target

**Pending — source inspected.** Recipe replay uses a fixed operand margin and
records the requested cutoff without a general achieved-precision postcondition.
Negative powers and cancellation can require substantially more input. Propagate
demands backward through the operation, reconstruct forward, and check the
achieved bound; report insufficient source information accurately. For shared
operands, collect the strongest demand before refinement.

Source: [recipe refinement](../../AsymptoticInverse/Kernel/SeriesOperations.wl).
Independent target: refine the negative tenth power of a truncated `Exp[x]-1`
to cutoff 5, which requires operand precision 16 under the report's convention.
Existing tests: [RefinementRegressions](../../AsymptoticInverse/Tests/RefinementRegressions.wlt).
Findings: [R2 F05][R2], [R5 F04][R5], [R6 A04][R6], [R9 F05][R9]. A correct
but weaker expansion must not be described as an achieved requested cutoff.

### C09 — Resolve stored versus explicitly supplied coefficient power

**Pending — source inspected; policy decision needed.** The object overload of
`InverseExpansionCoefficient` places the stored `"Power"` option before caller
options. Choose explicit-option precedence or reject a conflict. Test omitted,
matching, and conflicting options at finite and infinite source endpoints.
Source: [core coefficient overload](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
Finding: [R6 A03][R6].

### C10 — Include the target offset in residual normalization labels

**Pending — source inspected.** The usage and ordinary residual label say
`f(g(y))/(a z^p)-1`; the translated model requires
`(f(g(y))-y0)/(a z^p)-1`. Inspect the actual residual calculation alongside the
wording and retain its finite-model scope. Test nonzero target offset and the
zero-offset control. Source: [core residual API](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
Finding: [R5 F05][R5]. This entry does not assert that the calculated residual
has the same defect as the label.

### C11 — Validate externally constructed or restored result associations

**Decision / pending.** A raw `GeneralizedSeries[association]` can present
inconsistent finite terms, internal jets, or metadata. Specify which construction
and import boundaries are supported, then validate invariants there. Avoid
revalidating every trusted internal operation. Include malformed and older
saved-object fixtures; coordinate with D02–D03.
Source: [result accessors](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
Finding: [R4 A05][R4]. No claim is made that arbitrary hand-built associations
already have a documented validity guarantee.

### C12 — Prove comparator equality and strict order separately

**Audit candidate — source inspected.** The final `compare` fallback treats a
proved negation of `d < 0` as strict positivity. Establish equality separately
or preserve an undecidable-order result; do not conflate nonnegative with
positive. Preserve exact algebraic resonance and sorting requirements.
Source: [core `compare`](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl).
Finding: [R6 A15][R6]. No wrong public result has been reproduced.

### C13 — Audit composition domains and the realness of unknown errors

**Audit candidate.** Transport the entire uncertain inner germ into the outer
domain, not only its finite approximation. Check whether real trigonometric
error bounds require a retained real-valued error contract. Use boundary-touching
compositions and uncertain inner branches to settle public reachability.
Sources: [series operations](../../AsymptoticInverse/Kernel/SeriesOperations.wl),
[composite envelopes](../../AsymptoticInverse/Kernel/SeriesEnvelopeArithmetic.wl).
Findings: [R4 R01][R4], [R7 R01][R7]. Preserve existing conservative refusals;
neither report establishes a current counterexample.

## Additional wave-2 obligations

The [current characterization](../../validation/review-wave-2-intake.json)
comes from [six bounded public probes](../../validation/ProbeReviewWave2.wl),
not an acceptance suite. It confirms two current mathematical errors: diagonal
composition returns `1 + O(a^2)` where the exact answer is `1/2` (C15), and
semantic duplicate powers yield logarithmic remainder degree 3 where degree 6
is required (C14). It also records an unrepresentable native index (C17).
The hostile-assumption certificate is now rejected with `OutsideBranch` under
C05. C07 rejects both the nonreal algebraic-root witness and the particular
opaque-function probe; the latter rejection does not prove a general analytic
source-admission policy.

| ID | Current evidence and required repair | Findings |
| --- | --- | --- |
| C14 | **Current native wrong bound.** Merge mathematically equal exponents before coefficient collection, truncation, boundary-degree scans and inverse enumeration. Structural keys distinguish `Sinh[1]^2` from `(Cosh[2]-1)/2`; the squared logarithmic block needs degree 6, not 3. Coordinate equality and strict ordering with C12; preserve distinct close powers and proof budgets. | [R13 A1][R13] |
| C15 | **Current native wrong composition.** Preserve the fixed-parameter scope of the outer remainder when the inner varying symbol was an outer parameter. Outer `x/(a+x)` at fixed positive `a`, composed with `x=a` as `a` tends to zero, requires a new diagonal expansion or a refusal to transport the nonuniform bound. Inspect source and remainder dependence, not only retained coefficients; exact outer expressions remain usable. | [R11 N02][R11], [R14 N01][R14]; C13, X10 |
| C16 | **Source admission audit remains open.** Native `Series` may use formal analyticity for an opaque function with only a few truthful derivatives. C06's finite-log allowance presupposes an analytic tail theorem. The reported smooth nonanalytic function is now rejected by C07 because a derivative coefficient is unproved real, but this incidental refusal is not a regularity proof. Native coverage B03 must preserve formal output separately from a proved analytic bound. | [R11 N03][R11]; C06, B03 |
| C17 | **Current native invalid optional view.** Check native integer/index representability as well as dense allocation length. A one-slot view for `1+x^(2^100)` still contains a native endpoint outside the supported machine range. Check denominator and signed lattice indices before constructing the optional view; preserve the sparse result. | [R12 N03][R12]; C01 |
| C18 | **Pending — source inspected.** Derive and verify the target endpoint and approach direction from the complete target chart. Current composite fallback misuses flat offsets and isolated target scales: flat pole inverses approach infinity, negative-source Erfc approaches 2 from below, and negative quadratic curvature reverses the side. Cover original and derived objects. | [R15 F01][R15]; D01, D02 |
| C19 | **Pending — source inspected.** A successful but inaccurate interval-certificate attempt must increase arithmetic precision when needed. Plan relative-only targets, tighten bounds from the proved root interval, retain the best certificate, and distinguish certification from reaching requested accuracy. | [R15 F02][R15], [R16 N02][R16]; C08, X05 |
| C20 | **Pending — source inspected.** Evaluate exact rational affine cancellation before interval rounding. Separately enclosing a huge translation and its cancellation can make even a linear certificate unusably wide. Preserve outward enclosures for nonlinear subexpressions; this is an availability failure, not evidence of an unsound certificate. | [R14 N02][R14]; X05 |
| C21 | **Pending — source inspected.** Solve and compare in the local source coordinate, and expose unresolved numerical error/ratio states. A large source origin can erase a small displacement; an inexact zero with poor accuracy is not exact agreement. Use bounded precision retries or normalized corrections without manufacturing target digits; keep numerical diagnostics distinct from interval certificates. | [R13 A3][R13], [R14 N03][R14], [R17 N3][R17]; D05, D06 |
| C22 | **Pending — source inspected.** Retain quantitative remainder bounds and their conditions through truncation. Transport a known upper bound by adding the absolute discarded finite part; do not copy a signed lower bound blindly. Include a no-op truncation of a Zeta/Lerch result and later supported arithmetic. | [R14 N05][R14]; D02, X05 |
| C23 | **Pending — source inspected; historical native witness.** Keep exponential sector grades until omitted-tail dominance is decided. Dropping a later sector's grade too soon weakens the leading flat-product error and can make deeper input look worse. Preserve exact/unknown-zero distinctions and validate any retained-only convolution optimization separately. | [R15 F03][R15], [R17 N2][R17]; P01, P06, X08 |

Additional concrete existing-item work: R10 N02 supplies a sparse flat-product
budget witness for P06; R14 N04 adds ignored Fourier term goals to D01/D02;
R16 N03 requires correcting the documented seed-only `WorkingPrecision`
contract and its capped proof-order conversion; R16 N04 requires a common
cutoff/term-goal policy. R16 S01 is optional sharper closed-boundary convolution
under C04/P02/P03, not a reason to erase C04's verified conservative fix.
R15 F04 adds reflected positive Gamma/Barnes observables to X02.
R16 O01/O02 and R17's derivative extension supply concrete Zeta/Lerch tail
derivative obligations for X04/X05, with parameter and coordinate restrictions.

## Performance and resource contracts

| ID | Current status and bounded next action | Report evidence and source |
| --- | --- | --- |
| P01 | **Pending — source inspected.** Nonnegative integer powers use binary powering, but exact operands can still be fully expanded before a tiny requested cutoff. Propagate the cutoff through intermediate products with correct negative-valuation shifts. Compare with an independent truncated Cartesian oracle and preserve failure ordering. | [R9 F02][R9]; core `fwdPower`, `pIntegerPower`, `pMul` in [AsymptoticInverse.wl](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl). |
| P02 | **Pending — source inspected.** Generic unit-series loops check product limits but do not consistently bound accumulated support or depth. Define the units and check each stage without charging an irrelevant continuation after exact termination. Historical native reproduction is in review 8. | [R8 F04][R8]; core `jetPowerSeries` / `jetComposeBlock`. |
| P03 | **Focused verified.** The homogeneous Euler recurrence stops before multiplying another power once its coefficient polynomial is proved zero. Its 16 [regressions](../../AsymptoticInverse/Tests/ReviewRecurrenceTermination.wlt) cover finite products, logarithmic coefficients, valid assumption-dependent termination, validation order and required-versus-futile resource use. Four baseline resource failures now pass in the [196-test acceptance](../../validation/review-unit-arithmetic-tests.json). Generic coefficient generators still permit isolated zeros. | [R4 A03][R4], [R8 F05][R8]; core `jetComposeBlock`. |
| P04 | **Pending — source inspected.** Grouped and Newton routes still construct the direct multi-index region/frontier. Separate method-specific coefficient scheduling from complete-weight/frontier certification. Test collisions, irrational gaps, cancellation, term goals, and exact termination before considering a priority queue or automatic strategy selection. | [R2 F06][R2], [R3 F05][R3], [R5 F03][R5], [R9 F03][R9]; [core constructor](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl), [refinement state](../../AsymptoticInverse/Kernel/RefinementState.wl). |
| P05 | **Pending — source inspected.** `logCanon` unconditionally factors exact integer/rational logarithm arguments. Bound optional canonicalization and retain opaque exact logarithms when that budget is exhausted. Test equality/zero detection and reproducibility as well as runtime. | [R5 F06][R5], [R6 A05][R6]; core `logCanon`, `coefCanon`, `polyCanon`. |
| P06 | **Decision / pending.** Separate output support, candidate products, recursion/depth, frequencies, dense positions, coefficient size, and symbolic proof work. Preflight expensive expansion/allocation and preserve local failure ordering. A shared request budget should report the exhausted resource; replacing every limit with one counter is not the proposal. | [R1 A06][R1], [R4 A06][R4], [R6 A06][R6], [R8 F06][R8]; [kernel modules](../../AsymptoticInverse/Kernel/). |
| P07 | **Profiling required.** Measure nested recipe/provenance size and cache retention before introducing shared immutable nodes, compact serialization, or cache elision. Bound caches by meaningful cost and preserve branch/refinement evidence when removing optional state. Reported exponential history growth is structural, not a measured current workload. | [R1 A13][R1], [R4 A04][R4], [R7 R02][R7]; [SeriesOperations](../../AsymptoticInverse/Kernel/SeriesOperations.wl), [RefinementState](../../AsymptoticInverse/Kernel/RefinementState.wl). |
| P08 | **Profiling required.** Profile repeated `Expand`/normalization, native powers and analytic calls, coefficient recurrences, proof queries, and rebuild/replay work. Prefer bounded request-local reuse over a global cache. Only keep optimizations with identical coefficients, domains, errors, and meaningful matched measurements. | [R6 A16][R6], [R7 R02][R7]; [NativeSpecialFunctions](../../AsymptoticInverse/Kernel/NativeSpecialFunctions.wl), [GammaInverse](../../AsymptoticInverse/Kernel/GammaInverse.wl), and report roadmap discussions. |

Already implemented mechanisms must remain the baseline: sparse sorted-product
pruning, binary integer powering, Fourier weight pruning, grouped Lagrange,
Newton doubling, and bounded incremental coefficient caches. Their existence
does not settle P01/P04, but replacing them with similarly named algorithms is
not a new optimization. Benchmarks should match achieved precision and branch
conditions, record failed cases, separate cold and warm work, retain raw
observations, and include peak memory and unchanged controls.

## API, validation, and distribution decisions

| ID | Current status / decision to make | References |
| --- | --- | --- |
| D01 | **Decision.** Normalize requests internally by coordinate, absolute/relative cutoff, complete-weight or carrier term goal, and achieved error. Keep existing syntax compatible. Do not imply a single cutoff exists for arbitrary composite envelopes. | [R1 A07][R1], [R4 A08][R4], [R6 A09][R6], [R7 E02][R7]; [user guide](../../AsymptoticInverse/Documentation/UserGuide.md). |
| D02 | **Decision.** Specify a small shared result/scale contract and capability discovery, including error evidence and derivative-contract order. Preserve unsupported versus undecidable versus disproved outcomes and report selected adapter/method/fallback. Avoid a broad registry refactor before concrete duplicated contracts are settled. | [R1 A12][R1], [R4 A08][R4], [R6 A11][R6], [R7 E02][R7]; [operation dispatch](../../AsymptoticInverse/Kernel/SeriesOperations.wl), [automatic arithmetic](../../AsymptoticInverse/Kernel/SeriesArithmetic.wl). |
| D03 | **Decision.** Add versioned saved-object import/migration if persistence is supported. The public rename to `GeneralizedSeries` is already documented; a compatibility alias was intentionally not exported. Validate migration rather than textually rewriting arbitrary code. | [R1 A08][R1], [R6 A11][R6], [R7 E02][R7], [R8 F08][R8]; guide and C11. |
| D04 | **Pending — source inspected.** `InverseCertificate` defaults `"Interval"` to `Automatic` but requires ordered rational endpoints. Either clearly make the interval required with a specific diagnostic or separately implement verified bracketing. Do not infer an interval from unspecified asymptotic constants. | [R1 A09][R1], [R6 A13][R6], [R7 E04][R7], [R8 F10][R8]; [InverseCertificates](../../AsymptoticInverse/Kernel/InverseCertificates.wl), [CertificateRegressions](../../AsymptoticInverse/Tests/CertificateRegressions.wlt). |
| D05 | **Optional API decision.** Keep `Normal[s]` and `s[value]` as the documented finite expression and its numerical substitution. A separate checked evaluator could report domain, conditioning, scale, and available bounds. A bare asymptotic `O` with unknown constant cannot supply a numerical error bar. | [R1 A11][R1], [R6 A10][R6]; [result accessors](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl). |
| D06 | **Compatibility decision.** Normalize supported real native direction aliases or reject them helpfully; preserve a clear assumption policy (C05). Clarify absolute source observables versus displacement powers at translated endpoints before changing syntax or semantics. Retain the role of held `SeriesNormalize` before automatic Wolfram cancellations. | [R4 A08][R4], [R6 A12][R6], [R7 E02][R7]; [review 3 API discussion][R3-article], [review 5 API discussion][R5-article], [review 9 API discussion][R9-article]. |
| D07 | **Decision / partially existing.** Versioned release artifacts, checksums, and reproducible load examples remain useful. Download-before-`Get`, offline use, commit-pinned examples, canonical modular sources, and standalone freshness checks already exist; do not implement them again as missing features. | [R1 A14][R1]; [development README](README.md), [standalone workflow](../../.github/workflows/standalone.yml). |
| D08 | **Pending — source inspected.** Align the paclet's `"MIT"` identifier with the root MIT No Attribution license after confirming the intended distribution metadata. Preserve separate review-package licenses and notices. | [R1 A14][R1], [R6 A14][R6], [R7 E03][R7], [R8 F09][R8]; [PacletInfo](../../AsymptoticInverse/PacletInfo.wl), [LICENSE](../../LICENSE). |
| D09 | **Optional distribution decision.** Add Documentation Center symbol/reference pages and executable examples if native paclet help integration is desired. The current paclet declares a Kernel extension only; the existing HTML guide remains maintained documentation. | [R1 A10][R1], [R6 A14][R6]; [PacletInfo](../../AsymptoticInverse/PacletInfo.wl). |
| V01 | **Deferred by current user instruction.** The reviews propose a full native release gate and CI semantic coverage. The present workflow checks standalone generation with Python; focused native records remain scoped evidence. Record source hashes, kernel version, selected suites, messages and failed/aborted cases. Do not claim or run a full-suite gate for this task. | [R1 A05][R1], [R4 A07][R4], [R6 A07][R6], [R7 E01][R7], [R8 F07][R8]; [validation record](../../validation/README.md). |
| V02 | **Pending — source inspected.** Make the legacy aggregate runner reject zero discovered/executed tests and failed report/export construction. Reuse the stronger focused runner's checks without running the aggregate suite. Validate the runner itself with isolated empty/aborted fixtures. | [R6 A08][R6]; [RunTests](../../AsymptoticInverse/Tests/RunTests.wl), [FocusedTests](../../validation/FocusedTests.wl). |

## Deferred mathematical and architectural extensions

These are explicit **scope decisions**, not defects in a documented unsupported
case. They remain visible for future work but are not prerequisites for closing
C01–C23. Required native coverage B01–B04 is not deferred here. Each additional
custom extension needs a finite admitted domain, independent
coefficient oracles, remainder/branch obligations, and refusal cases.

| ID | Proposal and boundary | Report source |
| --- | --- | --- |
| X01 | Primitive rationally commensurate flat-rate normalization. Current `flatModel` requires integer multiples of the smallest rate; rates 2 and 3 instead admit primitive rate 1. Bound lattice denominator/degree growth and keep genuinely irrational rate ratios distinct. **Pending scope decision; current restriction inspected.** | [R2 F07][R2], [R5 F07][R5], [R7 F05][R7]; [FlatSectors](../../AsymptoticInverse/Kernel/FlatSectors.wl). |
| X02 | Shared coefficient algebra for rational/reciprocal logarithms, iterated slow variables, and compatible retained Gamma/Barnes cores. Improve ordered arithmetic, selected composition, Fourier term goals/refinement, and nonvanishing oscillatory coefficients under explicit hypotheses. Preserve conservative composite envelopes when no ordered closure is proved. | [R2 roadmap][R2-article], [R5 specialized scales][R5-article], [R7 roadmap][R7-roadmap], [R8 extensions][R8-article]. |
| X03 | Integration of already constructed germs with an explicit integration constant/normalization, exponent `-1` resonance, coordinate Jacobian, and integrable remainder condition. This is a proposed operation, not a replacement for native asymptotic integration. | [R2 roadmap][R2-article], [R3 roadmap][R3-article], [R4 extensions][R4-article], [R5 roadmap][R5-article], [R8 extensions][R8-article]. |
| X04 | A source-differentiation/re-expansion operation can complement differentiation under a retained derivative contract. It must not infer derivatives of unknown magnitude remainders. | [R3 roadmap][R3-article]. |
| X05 | Quantitative tail bounds from checked majorants, stronger interval subdivision/polynomial enclosures, and original-function Gamma/Barnes/Erfc inverse certificates. Require explicit function and derivative bounds; a high-precision residual or a finite asymptotic model is insufficient. | [R3 roadmap][R3-article], [R4 certification][R4-article], [R5 certification][R5-article], [R6 future work][R6-article], [R8 certification][R8-article]. |
| X06 | Independent proof records/checkers for rational interval arithmetic, finite residual identities, and local remainder transport; optional proof-assistant formalization of this small trusted core. Keep formal identity, asymptotic theorem, numerical evidence, and root certification distinct. | [R2 roadmap][R2-article], [R3 verification boundary][R3-article], [R5 evidence architecture][R5-article], [R6 future work][R6-article], [R7 evidence][R7-roadmap], [R8 certification][R8-article]. |
| X07 | Finite conditional parameter cases when a bounded decision procedure proves them. Keep a separate chart, branch and precision contract per case, and retain an inconclusive-within-budget outcome. | [R5 longer-range work][R5-article]. |
| X08 | Multiple independent exponential rates, different phase orders, and nested transseries. Require rate-vector/valuation ordering, local finiteness, resonance handling, and adequate algebraic zero-sector precision. This is substantially larger than X01. | [R2 roadmap][R2-article], [R4 extensions][R4-article], [R5 longer-range work][R5-article], [R7 roadmap][R7-roadmap]. |
| X09 | Selected complex sectors and Stokes-dependent behavior. Define branch geometry, sector-dependent dominance and applicable remainder theorems; accepting complex constants is not such an implementation. | [R3 roadmap][R3-article], [R4 extensions][R4-article], [R6 future work][R6-article], [R7 roadmap][R7-roadmap], [R9 roadmap][R9-article]. |
| X10 | Uniform parameter asymptotics and transition cores near vanishing leading coefficients, closing exponent gaps or changing branches. Fixed-parameter assumptions do not imply uniform error constants. | [R3 roadmap][R3-article], [R4 extensions][R4-article], [R6 future work][R6-article], [R7 roadmap][R7-roadmap], [R8 roadmap][R8-article]. |
| X11 | Coupled/multivariate implicit systems, initially a fixed grading and a nonsingular real leading Jacobian. Partial support orders and conditioning need their own contract; singular systems are a further step. | [R4 extensions][R4-article], [R6 future work][R6-article], [R9 roadmap][R9-article]. |
| X12 | Scoped adapters for native asymptotic integration, summation, ODE and recurrence solvers, or additional special-function thresholds. Report endpoint/parameter scope, native dependence and imported error evidence. Avoid building a new general solver solely to broaden a function-name list. | [R6 adapter roadmap][R6-article], [R7 roadmap][R7-roadmap], [R8 adapter catalogue][R8-article], [R9 roadmap][R9-article]. |

## Complete finding crosswalk

Every numbered ledger/README finding appears below. A finding spanning several
contracts maps to more than one item; duplicate reports do not multiply the
number of required fixes. Unnumbered roadmap proposals are covered above.

| Review | Finding → register item |
| --- | --- |
| [1][R1] — 14 entries | A01 → C02; A02 → C01; A03 → C03; A04 → C05; A05 → V01; A06 → P06; A07 → D01; A08 → D03; A09 → D04; A10 → D09; A11 → D05; A12 → D02; A13 → P07; A14 → D07, D08. |
| [2][R2] — 7 entries | F01 → C04; F02 → C02; F03 → C03; F04 → C01; F05 → C08; F06 → P04; F07 → X01. |
| [3][R3] — 5 entries | F01 → C02; F02 → C01; F03 → C03; F04 → C05; F05 → P04. |
| [4][R4] — 11 entries | A01 → C02; A02 → C01; A03 → P03; A04 → P07; A05 → C11; A06 → P06; A07 → V01; A08 → D01, D02, D06; R01 → C13; R02 → C07; R03 → C06. |
| [5][R5] — 7 entries | F01 → C01; F02 → C02; F03 → P04; F04 → C08; F05 → C10; F06 → P05; F07 → X01. |
| [6][R6] — 16 entries | A01 → C01; A02 → C03; A03 → C09; A04 → C08; A05 → P05; A06 → P06; A07 → V01; A08 → V02; A09 → D01; A10 → D05; A11 → D02, D03; A12 → C05, D06; A13 → D04; A14 → D08, D09; A15 → C12; A16 → P08. |
| [7][R7] — 11 entries | F01 → C01; F02 → C02; F03 → C06; F04 → C07; F05 → X01; E01 → V01; E02 → D01, D02, D03, D06; E03 → D08; E04 → D04; R01 → C13; R02 → P07, P08. |
| [8][R8] — 10 entries | F01 → C05; F02 → C02; F03 → C01; F04 → P02; F05 → P03; F06 → P06; F07 → V01; F08 → D03; F09 → D08; F10 → D04. |
| [9][R9] — 6 entries | F01 → C01; F02 → P01; F03 → P04; F04 → C07; F05 → C08; F06 → C03. |
| [10][R10] — 2 entries | N01 → C05; N02 → P06. |
| [11][R11] — 4 entries | N01 → C05; N02 → C15; N03 → C16, B03; N04 → C07, B01. |
| [12][R12] — 3 entries | N01 → C05; N02 → C07, C13, B01; N03 → C17. |
| [13][R13] — 3 entries | A1 → C14, C12; A2 → C07, B01; A3 → C21. |
| [14][R14] — 5 entries | N01 → C15; N02 → C20; N03 → C21; N04 → D01, D02; N05 → C22. |
| [15][R15] — 4 entries | F01 → C18; F02 → C19; F03 → C23; F04 → X02. |
| [16][R16] — 7 entries | N01 → C05; N02 → C19; N03 → D01, P06; N04 → D01; S01 → C04, P02, P03; O01 → X04, X05; O02 → X04, X05. |
| [17][R17] — 4 entries | N1 → C05; N2 → C23; N3 → C21; N4 → B04. |

## Next priorities and acceptance records

1. Implement B01–B03's native-compatible entry and result contracts, preserving
   native formal/complex output without giving it an unproved real analytic
   interpretation. Current real-model repairs remain scoped to that model.
2. Repair the current wrong results C14/C15, then target-chart correctness C18.
   Establish C16's source/admission boundary alongside native compatibility.
3. Retain the focused acceptance boundaries for C01–C07 and P03; extend their
   evidence with wave-2 witnesses where applicable. C17 adds a distinct native
   index constraint beyond C01's dense-allocation bound.
4. Establish C08's achieved-precision postcondition; then replace the fixed
   margins with backward demand planning. Address P01–P03 as bounded resource
   fixes, followed by measured P04/P05 work.
5. Address C19–C23, C09/C10, D04/D08 and V02 with focused contract checks.
   Required native input coverage is not deferred with the optional research
   proposals; preserve that distinction when prioritizing extensions.

For each completed item, record the implementation revision, exact source hashes,
focused tests and kernel, independent oracle, relevant benchmark/control results,
and any remaining contract boundary. Update this register alongside that evidence.
Passing an unrelated historical suite, a source-only model, or a patched review
fixture alone does not close an item in the current package.

[R1]: ../../code-review/wave-1/code-review-1/evidence/findings.csv
[R2]: ../../code-review/wave-1/code-review-2/README.md#findings-and-supplied-implementation-scope
[R3]: ../../code-review/wave-1/code-review-3/README.md#start-here
[R4]: ../../code-review/wave-1/code-review-4/evidence/findings.json
[R5]: ../../code-review/wave-1/code-review-5/evidence/findings.json
[R6]: ../../code-review/wave-1/code-review-6/evidence/findings.csv
[R7]: ../../code-review/wave-1/code-review-7/evidence/findings.csv
[R8]: ../../code-review/wave-1/code-review-8/evidence/findings.csv
[R9]: ../../code-review/wave-1/code-review-9/README.md#findings
[R10]: ../../code-review/wave-2/code-review-10/evidence/review_crosswalk.json
[R11]: ../../code-review/wave-2/code-review-11/evidence/findings-delta.json
[R12]: ../../code-review/wave-2/code-review-12/evidence/novelty_ledger.csv
[R13]: ../../code-review/wave-2/code-review-13/README.md#principal-results
[R14]: ../../code-review/wave-2/code-review-14/evidence/findings.json
[R15]: ../../code-review/wave-2/code-review-15/evidence/findings.csv
[R16]: ../../code-review/wave-2/code-review-16/evidence/findings.csv
[R17]: ../../code-review/wave-2/code-review-17/evidence/novelty_matrix.json
[R2-article]: ../../code-review/wave-1/code-review-2/article/asymptotic-review.tex
[R3-article]: ../../code-review/wave-1/code-review-3/article/asymptotic-audit.tex
[R4-article]: ../../code-review/wave-1/code-review-4/article.tex
[R5-article]: ../../code-review/wave-1/code-review-5/article/asymptotic-audit.tex
[R6-article]: ../../code-review/wave-1/code-review-6/article/article.tex
[R7-roadmap]: ../../code-review/wave-1/code-review-7/article/04-engineering-and-roadmap.tex
[R8-article]: ../../code-review/wave-1/code-review-8/article/asymptotic_repository_audit.tex
[R9-article]: ../../code-review/wave-1/code-review-9/article.tex
