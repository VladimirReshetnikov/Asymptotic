# Code review implementation status

The review work serves three active requirements, consolidated in
[Coverage targets and current gaps](COVERAGE_TARGETS.md):

- **Complete compatibility with both the official Wolfram kernel and Mathics3.**
  Current bounded adapters are a stage toward that goal; their verified scope
  is recorded in the [Mathics compatibility plan](../Mathics/COMPATIBILITY.md).
- **Completely subsume `Series`, `Asymptotic`, and `DiscreteAsymptotic`.** Every
  input successfully handled by any of them must be handled correctly and
  successfully by AsymptoticAnalysis. The result representation may differ.
  The [native compatibility plan](NATIVE_COMPATIBILITY.md) records known gaps.
- **Support all asymptotics documented in `vendor/proveit/docs`**, including
  q-analogs, inverses, and combinatorial sequences. The
  [vendored asymptotics register](VENDORED_ASYMPTOTICS.md) maps the mathematical
  source material to package coverage and remaining work.

These requirements are not yet achieved. Closing a review item establishes
only its stated implementation and validation scope; it does not establish
complete native, Mathics, or vendored-corpus coverage. Known deviations must
remain visible in the linked plans as the implementation develops.

The maintained package is now named AsymptoticAnalysis. Public function names,
including `AsymptoticInverse`, are unchanged. Source and test links below follow
the renamed directory; saved review payloads and validation records retain
their original paths and contexts. The 163/0 routing, 58/0 certificate and 11/0
standalone evidence at checkpoint `01b18ab` predates this rename. Earlier
passing counts likewise apply to their recorded source snapshots, not to new
path/context hashes after the rename.

Updated September 10, 2026. This register and the linked wave-3 and wave-4
intakes consolidate **231 attributed report entries from the thirty-six
supplied wave-1 to wave-4 [review packages](../../external-reports/code-review/README.md)**
into shared work items: 123 entries from waves 1–2, 44 from wave 3, and 64 from
wave 4. The earlier 167-entry count therefore remains scoped to waves 1–3.
Numbered advisories and extension proposals are included in their wave's
inventory; the intakes also discuss unnumbered proposals. These counts do not
measure distinct current defects, accepted API changes, or completed repairs.

Eight of those packages, together with two of the nine wave-5 packages, have
since been [retired](../../external-reports/code-review/README.md#retired-review-packages):
reports 2, 3, 10, 12, 13, 14, 26 and 32, plus 40 and 41. Every entry they carried was
implemented and verified below, settled as a decision, or restated by a retained
report; the register keeps their attributions and the retirement table names the
retained package that still carries each open obligation. Retiring a copy does
not close an item, and the entry counts above still describe what arrived.
References of the form `[Rn]` for a retired package resolve to that package's
tombstone page, which records the disposition of each of its entries.
Forty-five packages are retained across six waves.

The [wave-4 intake](WAVE_4_INTAKE.md) maps every report-local entry from
reports 28–36 to implementation obligations and proposals. Source-audited
mechanisms, unverified public manifestations, historical observations, and
later implementation evidence retain separate status. The
[wave-4 index](../../external-reports/code-review/wave-4/README.md) preserves
each report's article and supplied evidence.

Reviews 1–6, 8, and 9 examine `07a9781212beb2eeb9ff16aa625b50ac27974078`;
review 7 examines `75de8756175911cd8830704fd1a3406c1022f018`. Their supplied
patches and native observations concern those snapshots. Preserve their notices
and check current source before adapting a patch. Reviews 3 and 8 included
limited native execution; review 3 is retired, and the other reports'
independent mathematical and patch-fixture checks do not execute this package. See the [review index](../../external-reports/code-review/README.md)
for each report's evidence boundary.

Wave 2 adds reports 10–18, all pinned to
`921387e5ba1239bfda96e63e64e89bf63d9c41e6`, with 36 identified items, including
report 18's two explicitly attributed deltas to earlier findings.
Reports 10–13, 17 and 18 record selected Wolfram 15.0.0 Linux observations;
reports 14–16 record independent checks without successful package execution.
Reports 10 and 12–14 are retired; their C05, C07, C14, C15, C17, C20 and C21
evidence is superseded by the focused acceptance records cited below, as is
report 14's C22 truncation evidence. C22's arithmetic transport stays open and
is now carried by its register row rather than by a retained report.
These snapshots precede the recent C04–C07 repairs. The first eight supplied packages
were merged from `origin/main` commit `c19c0cd` without editing their contents.
Report 18's nineteen files were added from
`84650f3521cfcc89ae832f5bad3554f65faaab31`; its observations are historical,
not new reproductions against this checkout. The separately recorded
[seven current characterizations](../../validation/review-18-intake.json)
use Wolfram 15.0.1 Windows and unchanged sources; they are not an acceptance suite.
See the [wave-2 index](../../external-reports/code-review/wave-2/README.md).

Wave 3 adds reports 19–27, all pinned to
`6687962f3c858a4f93623cfc496f33e35c6763d4`. Their **44 ledger entries and
unnumbered proposals are included in scope** and mapped in the
[wave-3 intake](WAVE_3_INTAKE.md). That document records every local finding
ID, current source evidence, overlapping earlier work, policy alternatives,
and focused acceptance obligations. The supplied 166 payload files were
merged from `68b8e1e70731998c5bc1533be1bec0f5b507acd7` without editing them;
report 26's files have since been retired, and the remaining eight packages are
still unedited.
Current source inspection does not turn their historical or unrun witnesses
into current native reproductions.

Wave 4 adds reports 28–36 at the two exact snapshots recorded in the
[wave-4 intake](WAVE_4_INTAKE.md). Its **64 identified entries and unnumbered
proposals are included in scope**, with current-source comparisons and
focused acceptance obligations. All 180 supplied files, including nine TeX
and nine PDF articles, match their [arrival Git blobs](../../validation/wave4-payload-provenance.json)
as they arrived; report 32's seventeen files are recorded there and have since
been retired from the working tree.
Review evidence and candidate code do not establish current Mathics or
Wolfram package behavior; no bundled programs were executed during intake.

Wave 5 supplied reports 37–45 at `8e85996` and `651f202`; seven are retained and
indexed in the [wave-5 index](../../external-reports/code-review/wave-5/README.md).
**This wave has no consolidated intake.** Its entries are outside the 231 counted
above and outside every `C*`, `P*`, `D*`, `V*`, `X*`, `W3-*` and `W4-*` item, so
nothing below is closed or refuted by them. Three of the nine packages reported
the same signed-real absolute-value shortcut, and two reported the same
observable derivative-contract loss; reports 40 and 41 were retired as the
duplicate copies.

That modulus finding is no longer only source-predicted. The
[three-case characterization](../../validation/wave5-modulus-witness.json),
produced by [ProbeModulusReality](../../validation/ProbeModulusReality.wl) on
Wolfram 15.0.1 Windows with unchanged sources, reproduces two public wrong
results on the current source: under `a^2 == -1` the package returns exact `0`
with `RemainderPower -> Infinity` for `Abs[1 + a x] + Abs[1 - a x] - 2`, whose
true value is `2 Sqrt[1 + x^2] - 2 = x^2 + O(x^4)`, and `-2 Log[x]` for
`Abs[Log[x] + a] + Abs[Log[x] - a]`, whose true value is
`2 Sqrt[Log[x]^2 + 1]` and omits `-1/Log[x]`. The real-parameter control is
correct. This is a characterization probe, not an acceptance suite, and no
repair is applied here. The underlying mathematics — why a positive leading
coefficient does not license the sign rule, the norm-square construction that
does compute a modulus on the real coordinate, and the scale boundary at a
nonconstant logarithmic leading block — is now in the
[mathematical article](../article/sections/03-forward.tex), together with the
[separate reason](../article/sections/17-calculus.tex) a faithful magnitude
bound does not transport a classical derivative contract.

Wave 6 supplied reports 46–55 at `8cee870`, all ten retained and indexed in the
[wave-6 index](../../external-reports/code-review/wave-6/README.md). **It has no
consolidated intake either**, so its entries are outside the 231 counted above
and outside every item; nothing below is closed or refuted by them. No package
was retired: five defects are reported two or three times, but in five of the six
overlaps the copies propose non-interchangeable repairs at the same line, so the
index counts each obligation once instead. The
[four-case characterization](../../validation/wave6-witness-probe.json) from
[ProbeWave6Witnesses](../../validation/ProbeWave6Witnesses.wl) reproduces four of
its witnesses on the current source with unchanged sources during the run.

Three of those bear directly on items recorded here.
`AsymptoticExponentialCoreInverse` admits a target-dependent `"SourceShift"`
instead of refusing it, and returns a correct finite expression under a
remainder scale that is exponentially too small — at `y = 20` the true error is
`1.29·10⁻³` against a claimed `1.06·10⁻²⁰`. No register file mentions
`SourceShift`, so this is unrecorded work rather than a regression; its nearest
recorded principle is C15's forward note in the
[parameter-scope notes](COMPOSITION_PARAMETER_SCOPE.md) that later shifting
operations must keep fixed data separate from varying coordinates. The
coefficient-option corruption is a defect inside C09's own repair and is
recorded in that section. The `"LocalCoordinate"` label shipped by C21's
implementation describes `LocalRoot` and `LocalApproximation` as one quantity
when the run confirms the second is the first raised to the requested power;
the same sentence stands in the [user guide](../../src/Documentation/UserGuide.md)
and its generated HTML, which no wave-6 package noticed, so a kernel-only repair
would leave the documentation contradicting the new contract.

Two wave-6 entries are **not** new obligations. Report 55's N02 restates
retained report 16's N04, which this register already carries under D01 as the
open common cutoff and term-goal policy; report 55 adds a native reproduction, a
sub-mechanism in which a resource refusal ignores an active goal, and a patch
that selects one of the two policies report 16 identified. Report 49's E2 proves
an obligation already recorded as R16 O01/O02 under X04/X05. Reports 47 N01 and
50 E2 fall inside P08's stated lanes and 48 P1 inside P06's, and are governed by
those items' acceptance rules rather than by new entries.

The first wave-4 [runner repair](../../validation/wave4-runner-integrity-tests.json)
records **32 passed, 0 failed focused Python tests** on Windows, using synthetic
protocol peers and temporary Python processes/environments. It restricts
deadlines to finite values in `(0, 86400]` seconds (W4-10), preserves the
selected executable's invocation path (W4-11), latches observed source drift
(part of W4-12), and prevents report/staging aliases of fingerprinted inputs
(part of W4-13). These identifiers follow the
[maintained wave-4 intake](WAVE_4_INTAKE.md). Complete executed-source coverage
and freezing, mandatory load admission, output caps and interruption records
remain pending. This receipt contains no Mathics or Wolfram package execution.

W3-08 now has [99/0 focused native acceptance](../../validation/inverse-coefficient-model-tests.json).
The [coefficient-model note](INVERSE_COEFFICIENT_MODELS.md) records the four
message-emitting unsupported object families, the capability check, preserved
ordinary coefficients and special refusal tags, and the first-pass fixture
corrections. C09's separate option precedence issue is now closed with explicit precedence.

W3-06 now has independently reproduced native failures and
[131/0 focused native acceptance](../../validation/observable-ingress-main-sync-tests.json).
The [observable Taylor notes](OBSERVABLE_INGRESS.md)
record returned-order checks, sided constants, and complete-argument reality,
including an intermediate wrong result that final real-coefficient checking
could not detect. C16's broader opaque-source regularity audit remains open.

W3-10 is **focused verified — 207/0 across eight selected files**. The
[baseline](../../validation/log-power-normalization-baseline.json) and
[after-guard characterizations](../../validation/log-power-normalization-after-guard.json)
each record 13 observations on Wolfram 15.0.1 Windows64, 55 kernel hashes,
and unchanged sources during the run. They reproduce the false public depth
and flat-coefficient formulas, then the applicable structured refusals;
proved-real controls remain unchanged. The final `parseFinite` helper
recursively proves positive monomial bases: constant factors must be positive
and every nested power must have a proved-real exponent. This preserves
reciprocal-coordinate forms such as `(1/u)^a` without erasing an unproved
inner branch. The [normalization notes](LOG_POWER_NORMALIZATION.md) distinguish the
exact-core admission defect from the wrong finite-expression witnesses.
The [first focused pass](../../validation/log-power-normalization-first-pass.json)
records 201 successes and 2 failures: the initial guard rejected a valid
reciprocal-coordinate case, and an old inexact-input fixture expected an
Automatic refusal despite supported native fallback. The recursive helper
and explicit Package/native controls address those observations. The updated
[21-case focused tests](../../src/Tests/ReviewLogPowerNormalization.wlt)
and 186 existing cases in the [runner](../../validation/CheckLogPowerNormalization.wl)
pass in the [completed second run](../../validation/log-power-normalization-tests.json),
which records 65 source hashes and unchanged sources during execution.
The constructive periodic coefficient API remains
an open proposal, separate from this identity guard.

W3-13's separate Fourier recurrence is **focused verified — 68/0 across four
selected files**. The [17-observation baseline](../../validation/fourier-termination-baseline.json)
and [after-fix probes](../../validation/fourier-termination-after-fix.json)
record unchanged sources and reproduce the private terminating cases plus a
public budget-seven residual that now has zero residual blocks at relative
cutoff six. The [Fourier termination notes](FOURIER_TERMINATION.md) explain
the support and complete-coefficient stopping proofs, preserved genuine
resource failures, and the 19 new cases. The
[completed acceptance](../../validation/fourier-termination-tests.json) includes
22 Fourier regressions, 11 Fourier refactoring cases and 16 ordinary recurrence
cases, with 61 stable input hashes. Separate
[loading checks](../../validation/fourier-termination-loading-tests.json) pass
105/0 in five fresh native kernels. The earlier ordinary P03 acceptance alone
did not establish this separate path; the new records retain their own scope.

Status meanings:

- **Focused verified:** the implementation and a named current native test record
  were inspected. This does not imply full-suite acceptance.
- **In progress:** assigned implementation, awaiting its acceptance record.
- **Pending — source inspected:** the relevant current code pattern was inspected;
  no new native reproduction is claimed here.
- **Audit candidate:** a proof obligation or possible public route remains to be
  reproduced. It is not a demonstrated wrong result.
- **Decision / deferred:** an API, release-policy, or mathematical extension needs
  an implementation or scope decision. This status does not waive behavior
  required by the accepted coverage targets; any additional generality remains
  distinct from a correctness repair.

The current user instruction is to **skip the full suite**. Focused native
acceptance remains appropriate; the broader release-gate proposal below is
recorded without overriding that instruction. This register was prepared by
reading the ledgers, relevant report sections, source, and existing validation
artifacts. Current native claims refer only to the named focused records and
the separately identified wave-2 characterization probes.

## Correctness and information preservation

### Native expansion compatibility review stream

The updated user objective is to implement recommendations from all three
review waves and keep the mathematical article, user guide and development
notes current while pursuing the complete coverage requirements above.
B01–B04 and the compatibility matrix track the active requirement to subsume
every successful input of `Series`, `Asymptotic`, and `DiscreteAsymptotic`.
Concrete native-interface findings identify part of the remaining work;
resolving them does not exhaust that requirement. The current dispatcher
implements `Series` and `Asymptotic` delegation; a `DiscreteAsymptotic` backend
is still absent. The public function `AsymptoticExpansion` also has the held
alias `AsymptoticExpand`. Complete native coverage is not established.

| ID | Required work and acceptance boundary |
| --- | --- |
| B01 | **Partial — automatic routing and compatible second-backend search focused verified.** Native delegation precedes real-coordinate admission and has no special-function whitelist. `Automatic` retains successful package results and searches compatible native backends for admitted native routes. Explicit scalar rule goals `Automatic` and nonpositive integers now have 15 new cases in a 116/0 focused run. Configured defaults, option identity/roles, callable overprotection, conditioned inputs and native outcome handling remain wave-3 obligations W3-01–W3-05/W3-09. |
| B02 | **Automatic policy focused verified.** Held alias, explicit backend selection, native options and native order conventions are implemented. Automatic native results identify native order and routing reason, retaining the package failure when applicable. Callables, inverse/conditional sources and explicit direction/branch/budget options stay on the package path. `"Package"` rejects native-only options instead of silently ignoring them. |
| B03 | **Native representation focused verified.** `Kind`/`Scale` `"Native"` preserves the complete native result, held request and syntactic specifications, ambient context and runtime provenance. Analytic remainder and exactness remain missing; `Normal` applies native normalization and can retain infinite expressions. Analytic operations refuse to infer a remainder theorem. Further analytic promotion and native operations remain separate work; coordinate with C06, C07, C13 and C16. |
| B04 | **Partial — focused comparisons recorded.** The earlier nine-file search selection passes 179 tests; the latest five-file rule-goal selection passes 116, including 15 new cases, on Wolfram 15.0.1 Windows with unchanged sources. These overlapping populations are not one combined acceptance count. Separate bounded probes reproduce R17 N4's selected native `x^x`, Zeta and quadratic inverse calculations. The wave-3 differential-catalog and equivalent-request proposals remain open. |

Implementation: [NativeCompatibility.wl](../../src/Kernel/NativeCompatibility.wl).
Latest rule-goal evidence: [116/0 acceptance](../../validation/native-rule-goal-tests.json)
and [five-file runner](../../validation/CheckNativeRuleGoals.wl). Explicit
package constraints and triple cutoffs are unchanged; this does not close
configured-default or equivalent-key findings in wave 3.
The merged-source [425/0 acceptance](../../validation/review-normalization-merge-tests.json)
rechecks the union of normalization/scope and native-search cases plus package
identity after integrating `main` revision `b6df7a1`'s Mathics-only bootstrap.
See the [merge receipt](../../validation/review-normalization-merge-artifacts.json).
The individual search evidence at `5b2b6cd` is the [179/0 record](../../validation/native-search-tests.json),
[nine-file runner](../../validation/CheckNativeSearch.wl), and
[normalization/search artifact receipt](../../validation/review-normalization-artifacts.json).
Automatic search records `NativeAttempts`, consumes effective explicit common
options once, stops on a computed result or abort, and preserves the preferred
result if neither compatible backend computes. The earlier automatic evidence
is the [163/0 record](../../validation/native-automatic-tests.json),
[eight-file runner](../../validation/CheckNativeAutomatic.wl), and
[artifact receipt](../../validation/automatic-certificate-artifacts.json).
The following records preserve the earlier explicit-mode milestone.
Evidence: [entry script](../../validation/CheckNativeCompatibility.wl),
[final 130/0 record](../../validation/native-compatibility-tests.json), and
[earlier 120/2 fixture-diagnostic record](../../validation/native-compatibility-first-pass.json).
See [result contracts](NATIVE_RESULT_CONTRACTS.md) and the
[remaining compatibility plan](NATIVE_COMPATIBILITY.md). No full-suite or
complete-superset claim follows from this milestone.

Native-supported complex and formal cases in B01–B03 remain distinct from
the broader custom complex-sector research proposal X09.

### C01 — Bound optional native `SeriesData` allocation

**Focused verified.** A shared `makeRationalSeriesData` now allocates through the
last retained coefficient rather than padding to the remainder frontier, while
preserving the denominator and native order. A 100,000-position limit returns
`Missing["DenseSeriesDataLimit", metadata]` for an oversized optional view. Empty
inverse coefficients are handled. The sparse result remains available.

Source: [core exporters](../../src/Kernel/AsymptoticAnalysis.wl).
[ReviewNativeExport.wlt](../../src/Tests/ReviewNativeExport.wlt)
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
[branch regressions](../../src/Tests/ReviewPowerBranches.wlt)
cover recursive and direct routes and valid controls. Published implementation:
`921387e`.

Sources: [core `fwdPower`](../../src/Kernel/AsymptoticAnalysis.wl),
[operation dispatch](../../src/Kernel/SeriesOperations.wl).
Existing neighboring regressions: [SeriesOperations](../../src/Tests/SeriesOperations.wlt),
[SeriesArithmetic](../../src/Tests/SeriesArithmetic.wlt).
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

Source: [core exporters](../../src/Kernel/AsymptoticAnalysis.wl).
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

Source: [core `unitSeriesPrecision` / `pUnitSeries`](../../src/Kernel/AsymptoticAnalysis.wl).
The 15 new [precision tests](../../src/Tests/ReviewUnitPrecision.wlt)
cover explicit logarithm, exponential, radical, reciprocal and sine witnesses,
an irrational frontier, later-block degrees, inherited errors and exact cases.
The [baseline record](../../validation/review-unit-arithmetic-baseline.json)
has eight precision failures; the [nine-file acceptance](../../validation/review-unit-arithmetic-tests.json)
has **196 successes, 0 failures**, including the recurrence tests below, with
unchanged sources during the run. Finding: [R2 F01][R2].

[R18 D-C04][R18] supplies historical native confirmation plus a separate
rational-weight prototype that computes the complete boundary polynomial
before discarding it. Its thirteen Python methods include forty deterministic
independent-oracle subcases. This sharper-degree proposal is not integrated
and is not needed to make the existing conservative bound sound. Any future
implementation must preserve unknown input errors, call stateful coefficient
generators once in order, and retain a sound fallback under its budget; see
P02/P03 and [the report's validation scope][R18-validation].
The current report-18 probe records `PowerLogRemainder[x, 2, 2]` for both
default `SeriesExp[s]` and the formerly failing explicit `SeriesExp[s, 3]`.
The broader precision acceptance above covers adjacent nonlinear operations.

### C05 — Retain every assumption used to establish a reusable result

**Focused verified.** All nine constructors now capture the
ambient default through `Assumptions :> $Assumptions`; explicit options replace
it. A shared request boundary isolates internal proofs from later ambient
assumptions, including arithmetic, observables, coefficient queries and replay.
Models retain their parameter assumptions, and coefficient queries inherit them.
Delayed options are resolved before dispatch and forwarded as immediate rules;
nested option lists and specialized constructor paths are covered.

The original 17 [assumption regressions](../../src/Tests/ReviewAssumptions.wlt)
all fail against pinned kernel `e9c9eb9` in the
[baseline record](../../validation/review-assumptions-baseline.json). The
[acceptance record](../../validation/review-assumptions-tests.json) identifies
**200 passed, zero failed** across eight selected files. The
[supplemental replay record](../../validation/review-assumption-replay-tests.json)
adds **12 passed, zero failed** for delayed options, all remaining specialized
constructors, nested callbacks, representations and retained state. Both records
match the source hashes of that recorded snapshot and report unchanged sources during execution.
The [implementation notes](ASSUMPTION_CONTEXT.md) explain the policy, nested-state
requirements and evaluation limits. The mathematical article and user guide
now discuss retained parameter domains and distinguish pointwise from uniform
asymptotic claims. The six specialized constructors retain their existing
parameter-only assumption restriction.

Sources: [core assumption splitting](../../src/Kernel/AsymptoticAnalysis.wl),
[public expression adapters](../../src/Kernel/InverseFunctionExpressions.wl).
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

Sources: [ordinary fallback](../../src/Kernel/AsymptoticAnalysis.wl),
[structured importer](../../src/Kernel/NativeSpecialFunctions.wl).
Regressions: [ReviewNativeTailImport](../../src/Tests/ReviewNativeTailImport.wlt),
[NativeSpecialIngress](../../src/Tests/NativeSpecialIngress.wlt).
Findings: [R4 R03][R4], [R7 F03][R7].

### C07 — Apply the advertised real-coefficient contract consistently

**Focused verified for the ordinary real representation.** Complete coefficient
rows are normalized and checked at forward-result, inverse-model and explicit
series-operation boundaries. The inverse offset is checked before extraction.
Temporary complex summands and Taylor coefficients can cancel; ordinary proof
uses `Simplify` followed by a one-second `FullSimplify` fallback when needed.
Failure metadata distinguish proved nonrealness from an unproved condition.
Observable Taylor probes use a signed positive local increment.

The [23 focused cases](../../src/Tests/ReviewRealCoefficients.wlt)
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

Sources: [core constants and analytic expansion](../../src/Kernel/AsymptoticAnalysis.wl),
[observables](../../src/Kernel/SeriesOperations.wl),
[special-function domains](../../src/Kernel/SpecialFunctionRealDomain.wl).
Findings: [R4 R02][R4], [R7 F04][R7], [R9 F04][R9], [R11 N04][R11],
[R12 N02][R12], [R13 A2][R13], [R18 D-C07][R18]. Report 18 adds a historical
cross-entry acceptance matrix for nonreal constants; it does not replace the
current scoped acceptance above or the separate native-result policy.
The current report-18 probe for `ArcSin[2] + x` returns
`UnprovedRealCoefficient` under `"Package"`, while `"Series"` preserves a
`"Native"` result with missing analytic remainder and exactness contracts.
The wave-2 nonreal algebraic-root witness
is now rejected by this real representation, as recorded in the intake probe.

### C08 — Make refinement meet or honestly report its precision target

**Pending — source inspected.** Recipe replay uses a fixed operand margin and
records the requested cutoff without a general achieved-precision postcondition.
Negative powers and cancellation can require substantially more input. Propagate
demands backward through the operation, reconstruct forward, and check the
achieved bound; report insufficient source information accurately. For shared
operands, collect the strongest demand before refinement.

Source: [recipe refinement](../../src/Kernel/SeriesOperations.wl).
Independent target: refine the negative tenth power of a truncated `Exp[x]-1`
to cutoff 5, which requires operand precision 16 under the report's convention.
Existing tests: [RefinementRegressions](../../src/Tests/RefinementRegressions.wlt).
Findings: [R2 F05][R2], [R5 F04][R5], [R6 A04][R6], [R9 F05][R9]. A correct
but weaker expansion must not be described as an achieved requested cutoff.

### C09 — Resolve stored versus explicitly supplied coefficient power

**Focused verified — explicit precedence.** The object overload of
`InverseExpansionCoefficient` now reads an explicit caller `"Power"` before
the stored observable power, and converts either to the internal uniformizer
convention at an infinite endpoint. Omitted and matching options reproduce the
stored coefficient; a conflicting option agrees with the coefficient of the
same inverse constructed with that power, at finite and infinite endpoints
([tests](../../src/Tests/ReviewCoefficientPowerResidualLabel.wlt)).
Source: [core coefficient overload](../../src/Kernel/AsymptoticAnalysis.wl).
Finding: [R6 A03][R6].

**Verified for the string spelling only; a symbol-spelled option is not
covered.** Wave-6 report 48 N1 reports, and the
[wave-6 characterization](../../validation/wave6-witness-probe.json) reproduces,
that the selection matches the option by name equivalence but extracts it by
literal string replacement. `InverseExpansionCoefficient[s, {1}, Power -> 2]`
therefore returns a *successful* association whose `Exponent` is `1 + "Power"`
and whose `Coefficient` is `-"Power"`, and supplying both spellings lets the
later string win, so first-option precedence does not hold. Every case in the
regression file above uses the string spelling, which is also the only spelling
the user guide documents. This is a defect inside the repair recorded here, not
a new area; it must be repaired and the regression extended before the
precedence claim is restated without qualification.

### C10 — Include the target offset in residual normalization labels

**Focused verified — label only.** The calculation already used `v = y - y0`;
the usage and the `"Normalization"` label now read
`(f(g(y)) - y0)/(a z^p) - 1` for a finite target offset, which the report also
returns as `"TargetOffset"`, and keep `f(g(y))/(a z^p) - 1` at an infinite
target. The nonzero-offset residual `3 + x + x^2` and the zero-offset control
are [tested](../../src/Tests/ReviewCoefficientPowerResidualLabel.wlt).
Source: [core residual API](../../src/Kernel/AsymptoticAnalysis.wl).
Finding: [R5 F05][R5]. The calculated residual did not share the label's defect.

### C11 — Validate externally constructed or restored result associations

**Decision / pending.** A raw `GeneralizedSeries[association]` can present
inconsistent finite terms, internal jets, or metadata. Specify which construction
and import boundaries are supported, then validate invariants there. Avoid
revalidating every trusted internal operation. Include malformed and older
saved-object fixtures; coordinate with D02–D03.
Source: [result accessors](../../src/Kernel/AsymptoticAnalysis.wl).
Finding: [R4 A05][R4]. No claim is made that arbitrary hand-built associations
already have a documented validity guarantee.

### C12 — Prove comparator equality and strict order separately

**Audit candidate — source inspected.** The final `compare` fallback treats a
proved negation of `d < 0` as strict positivity. Establish equality separately
or preserve an undecidable-order result; do not conflate nonnegative with
positive. Preserve exact algebraic resonance and sorting requirements.
Source: [core `compare`](../../src/Kernel/AsymptoticAnalysis.wl).
Finding: [R6 A15][R6]. No wrong public result has been reproduced.

### C13 — Audit composition domains and the realness of unknown errors

**Audit candidate.** Transport the entire uncertain inner germ into the outer
domain, not only its finite approximation. Check whether real trigonometric
error bounds require a retained real-valued error contract. Use boundary-touching
compositions and uncertain inner branches to settle public reachability.
Sources: [series operations](../../src/Kernel/SeriesOperations.wl),
[composite envelopes](../../src/Kernel/SeriesEnvelopeArithmetic.wl).
Findings: [R4 R01][R4], [R7 R01][R7]. Preserve existing conservative refusals;
neither report establishes a current counterexample.

## Additional wave-2 obligations

The [current characterization](../../validation/review-wave-2-intake.json)
comes from [six bounded public probes](../../validation/ProbeReviewWave2.wl),
not an acceptance suite. It recorded two mathematical errors before the C14/C15 repairs: diagonal
composition returns `1 + O(a^2)` where the exact answer is `1/2` (C15), and
semantic duplicate powers yield logarithmic remainder degree 3 where degree 6
is required (C14). It also records an unrepresentable native index (C17).
The hostile-assumption certificate is now rejected with `OutsideBranch` under
C05. C07 rejects both the nonreal algebraic-root witness and the particular
opaque-function probe; the latter rejection does not prove a general analytic
source-admission policy.

| ID | Current evidence and required repair | Findings |
| --- | --- | --- |
| C14 | **Focused verified — 23 new cases in the 276/0 acceptance.** Shared ordered equality groups collect provably equal exponents before block counts, logarithmic boundary degrees and inverse generators. The reported square now retains degree 6; cancelled equal powers no longer consume a term goal or create a spurious inverse gap. Close distinct powers and existing proof/resource limits remain distinct. See [equal-exponent notes](EXPONENT_EQUALITY.md). | [R13 A1][R13]; [baseline](../../validation/exponent-equality-baseline.json), [276/0 acceptance](../../validation/review-normalization-tests.json), C12 |
| C15 | **Focused verified — 20 new cases in the 276/0 acceptance.** Scope admission examines retained source, remainder metadata and recursive operation provenance, respecting bound inverse variables. Complete forward outer sources composed with exact forward inner objects are re-expanded in the joint regime; the reported diagonal gives exact `1/2`. Other captured nonexact remainders are refused. Exact outer identities still propagate inner uncertainty and recheck parameter/source conditions. See [parameter-scope notes](COMPOSITION_PARAMETER_SCOPE.md). | [R11 N02][R11], [R14 N01][R14]; [baseline](../../validation/composition-scope-baseline.json), [276/0 acceptance](../../validation/review-normalization-tests.json), C13, X10 |
| C16 | **Source admission audit remains open.** Native `Series` may use formal analyticity for an opaque function with only a few truthful derivatives. C06's finite-log allowance presupposes an analytic tail theorem. The reported smooth nonanalytic function is now rejected by C07 because a derivative coefficient is unproved real, but this incidental refusal is not a regularity proof. Native coverage B03 must preserve formal output separately from a proved analytic bound. | [R11 N03][R11]; C06, B03 |
| C17 | **Focused verified — 46/0 across four explicitly selected files, including 17 new index-range cases.** The guard checks the positive native denominator, both signed lattice indices, and their nonnegative span before dense allocation or inverse coefficient scaling. On Wolfram 15.0.1 Windows64, a span exceeding `2^63-1` can silently discard coefficients even when both endpoint indices are individually valid. `Missing["NativeSeriesDataRange", metadata]` refuses only the optional native view; the sparse expansion and its analytic remainder remain usable. The selected files are `ReviewNativeIndexRange.wlt` (17), `ReviewNativeExport.wlt` (13), `ReviewNativeTailExport.wlt` (12), and `GeneralizedSeries.wlt` (4), with unchanged sources during the run. | [R12 N03][R12]; [46/0 acceptance](../../validation/review-native-index-range-tests.json), [14 constructor characterizations](../../validation/native-index-range-probe.json), C01 |
| C18 | **Pending — source inspected.** Derive and verify the target endpoint and approach direction from the complete target chart. Current composite fallback misuses flat offsets and isolated target scales: flat pole inverses approach infinity, negative-source Erfc approaches 2 from below, and negative quadratic curvature reverses the side. Cover original and derived objects. | [R15 F01][R15]; D01, D02 |
| C19 | **Focused verified — 58/0 across three selected files.** Automatic order planning includes relative tolerances and is capped without rejecting exact zero-residual proofs. Selective retries increase arithmetic precision when residual uncertainty or stalled progress limits a valid but insufficient certificate; useful geometric contraction keeps its existing arithmetic order. The reported error uses the sharp proved root interval; `ResidualRadius` retains the old residual/derivative majorant. Best retention uses exact normalized goal progress, absolute error and interval width, with stable ties. Budget exhaustion and an active arithmetic cap are reported separately; the cap does not stop interval contraction. The earlier R18 probe records the original `{60,60,60,60}` stall. Supplied external adapters remain unvalidated candidate artifacts. | [R15 F02][R15], [R16 N02][R16], [R18 N01][R18]; [baseline probe](../../validation/review-18-intake.json), [58/0 acceptance](../../validation/review-certificate-accuracy-tests.json), [focused runner](../../validation/CheckReviewCertificateAccuracy.wl), C08, X05 |
| C20 | **Focused verified.** The certificate evaluator now computes the exact range of a rational affine tree (rational constants, the source symbol, `Plus`, `Times`) before any dyadic rounding, then rounds the two exact endpoints outward once. The review witness `x - (2^10000 + 1)` with a supplied exact center previously failed with `ResidualBracketOutsideInterval` at every admitted order ([baseline](../../validation/affine-certificate-baseline.txt)); it now certifies with zero residual and error bound at `"EnclosureOrder" -> 2`. Nonlinear and transcendental subexpressions keep the outward enclosures. The [two-file certificate run](../../validation/certificate-affine-tests.json) passes 46/46 and the portable case `certificate-exact-affine-translation` passes on both kernels. | [R14 N02][R14]; X05; [InverseCertificates](../../src/Kernel/InverseCertificates.wl). |
| C21 | **Focused verified — ordinary checker.** `InverseNumericalCheck` now solves, tests the branch and compares errors in the local displacement `u` with `x = x0 + side u`, substituting the exact endpoint symbolically before numerical evaluation; the domain predicate is rewritten in `u` the same way. The review witness `(x - 10^100) + (x - 10^100)^2` previously failed with `OutsideBranch` because the displacement vanished at `WorkingPrecision + 10` digits ([baseline](../../validation/numerical-local-coordinate-baseline.txt)); it now returns the local root to 50 digits, and the zero-offset control reproduces its earlier root, error and ratio exactly. Reconstructed absolute values carry extra presentation digits. The [twelve-file run](../../validation/numerical-local-coordinate-tests.json) and the portable case `numerical-local-coordinate-huge-offset` record the change. The coordinate and special routes still solve in their own recorded charts; exposing unresolved ratio states remains open. | [R13 A3][R13], [R14 N03][R14], [R17 N3][R17]; D05, D06; [NumericalInverseChecks](../../src/Kernel/NumericalInverseChecks.wl). |
| C22 | **Focused verified — truncation; arithmetic still open.** `SeriesTruncate` transports a quantitative forward tail bound: the new `"AbsoluteRemainderBound"` is the original bound plus `Abs` of the recorded `"TruncationDiscardedPart"` under unchanged `"RemainderBoundConditions"`, with a `"TransportedThroughTruncation"` contract retaining the original. The signed `"RemainderLowerBound"`, Lerch `"RemainderBoundConstant"` and `"FirstOmittedInteger"` are kept only by a no-op truncation and are never copied to a shorter expansion. The [four-file run](../../validation/truncation-bounds-tests.json) passes 94/94 on Wolfram 15.0.1 with independent numerical tail checks for Zeta and Lerch; the portable case `special-zeta-truncation-transports-bound` passes on both kernels. Supported arithmetic on such results still drops the bound fields; that transport remains open. | [R14 N05][R14]; D02, X05; [SeriesOperations](../../src/Kernel/SeriesOperations.wl), [DirichletSpecialFunctions tests](../../src/Tests/DirichletSpecialFunctions.wlt). |
| C23 | **Focused verified.** Flat products now collect every omitted contribution as a graded candidate (sector, algebraic/logarithmic pair), select the least sector, combine only those candidates by power-log dominance, and then weaken to the schema's sector `N + 1`, reporting the least sector as `"SectorTailGrade"`; sums combine tails by grade too, and exact constants carry an infinite grade. Retained sectors and the first omitted sector use full coefficient products so cancellations there are found; deeper omitted pairs use envelopes. The [baseline](../../validation/flat-graded-tail-baseline.txt) squares of the depth-1, 2, 3 inverses of `x + Exp[-1/x]` carried tail powers `-4, -8, -12`; they now carry `-1, -3, -5`, the review's graded values, with unchanged retained coefficients. Exact-zero annihilation, pure unknown inner coefficients, unequal depths and derivative-contract preservation are tested ([tests](../../src/Tests/ReviewFlatGradedTails.wlt)); the portable case `flat-graded-product-tail` covers both kernels. Preserving a grade above `N + 1` explicitly in the remainder remains a possible later extension. | [R15 F03][R15], [R17 N2][R17]; P01, P06, X08; [FlatSectorOperations](../../src/Kernel/FlatSectorOperations.wl). |

Additional concrete existing-item work: R10 N02 supplies a sparse flat-product
budget witness for P06; R14 N04 adds ignored Fourier term goals to D01/D02;
R16 N03's seed-only `WorkingPrecision` documentation and capped proof-order
conversion are addressed with C19; R16 N04 still requires a common
cutoff/term-goal policy. R16 S01 and R18 D-C04 propose sharper closed-boundary convolution
under C04/P02/P03, not a reason to erase C04's verified conservative fix.
R15 F04 adds reflected positive Gamma/Barnes observables to X02.
R16 O01/O02 and R17's derivative extension supply concrete Zeta/Lerch tail
derivative obligations for X04/X05, with parameter and coordinate restrictions.

R18's [certificate adapter](../../external-reports/code-review/wave-2/code-review-18/code/AccuracyAwareCertificate.wl)
and [source patch generator](../../external-reports/code-review/wave-2/code-review-18/code/patch_certificate.py)
remain candidates. Before integration, audit the adapter's `Return` inside
`Do`, its stricter enclosure-order range, and whether the cap limits all
underlying attempts. The patch's automatic relative-digit heuristic also needs
capping before existing order validation, so an extreme requested tolerance
does not reject an exact zero-residual case unnecessarily. These are static
candidate concerns, not new native reproductions or defects attributed to the
current package.

## Performance and resource contracts

| ID | Current status and bounded next action | Report evidence and source |
| --- | --- | --- |
| P01 | **Pending — source inspected.** Nonnegative integer powers use binary powering, but exact operands can still be fully expanded before a tiny requested cutoff. Propagate the cutoff through intermediate products with correct negative-valuation shifts. Compare with an independent truncated Cartesian oracle and preserve failure ordering. | [R9 F02][R9]; core `fwdPower`, `pIntegerPower`, `pMul` in [AsymptoticAnalysis.wl](../../src/Kernel/AsymptoticAnalysis.wl). |
| P02 | **Pending — source inspected.** Generic unit-series loops check product limits but do not consistently bound accumulated support or depth. Define the units and check each stage without charging an irrelevant continuation after exact termination. Historical native reproduction is in review 8. | [R8 F04][R8]; core `jetPowerSeries` / `jetComposeBlock`. |
| P03 | **Focused verified.** The homogeneous Euler recurrence stops before multiplying another power once its coefficient polynomial is proved zero. Its 16 [regressions](../../src/Tests/ReviewRecurrenceTermination.wlt) cover finite products, logarithmic coefficients, valid assumption-dependent termination, validation order and required-versus-futile resource use. Four baseline resource failures now pass in the [196-test acceptance](../../validation/review-unit-arithmetic-tests.json). Generic coefficient generators still permit isolated zeros. | [R4 A03][R4], [R8 F05][R8]; core `jetComposeBlock`. |
| P04 | **Pending — source inspected.** Grouped and Newton routes still construct the direct multi-index region/frontier. Separate method-specific coefficient scheduling from complete-weight/frontier certification. Test collisions, irrational gaps, cancellation, term goals, and exact termination before considering a priority queue or automatic strategy selection. | [R2 F06][R2], [R3 F05][R3], [R5 F03][R5], [R9 F03][R9]; [core constructor](../../src/Kernel/AsymptoticAnalysis.wl), [refinement state](../../src/Kernel/RefinementState.wl). |
| P05 | **Pending — source inspected.** `logCanon` unconditionally factors exact integer/rational logarithm arguments. Bound optional canonicalization and retain opaque exact logarithms when that budget is exhausted. Test equality/zero detection and reproducibility as well as runtime. | [R5 F06][R5], [R6 A05][R6]; core `logCanon`, `coefCanon`, `polyCanon`. |
| P06 | **Decision / pending.** Separate output support, candidate products, recursion/depth, frequencies, dense positions, coefficient size, and symbolic proof work. Preflight expensive expansion/allocation and preserve local failure ordering. A shared request budget should report the exhausted resource; replacing every limit with one counter is not the proposal. | [R1 A06][R1], [R4 A06][R4], [R6 A06][R6], [R8 F06][R8]; [kernel modules](../../src/Kernel/). |
| P07 | **Profiling required.** Measure nested recipe/provenance size and cache retention before introducing shared immutable nodes, compact serialization, or cache elision. Bound caches by meaningful cost and preserve branch/refinement evidence when removing optional state. Reported exponential history growth is structural, not a measured current workload. | [R1 A13][R1], [R4 A04][R4], [R7 R02][R7]; [SeriesOperations](../../src/Kernel/SeriesOperations.wl), [RefinementState](../../src/Kernel/RefinementState.wl). |
| P08 | **Profiling required.** Profile repeated `Expand`/normalization, native powers and analytic calls, coefficient recurrences, proof queries, and rebuild/replay work. Prefer bounded request-local reuse over a global cache. Only keep optimizations with identical coefficients, domains, errors, and meaningful matched measurements. | [R6 A16][R6], [R7 R02][R7]; [NativeSpecialFunctions](../../src/Kernel/NativeSpecialFunctions.wl), [GammaInverse](../../src/Kernel/GammaInverse.wl), and report roadmap discussions. |

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
| D01 | **Decision.** Normalize requests internally by coordinate, absolute/relative cutoff, complete-weight or carrier term goal, and achieved error. Keep existing syntax compatible. Do not imply a single cutoff exists for arbitrary composite envelopes. | [R1 A07][R1], [R4 A08][R4], [R6 A09][R6], [R7 E02][R7]; [user guide](../../src/Documentation/UserGuide.md). |
| D02 | **Decision.** Specify a small shared result/scale contract and capability discovery, including error evidence and derivative-contract order. Preserve unsupported versus undecidable versus disproved outcomes and report selected adapter/method/fallback. Avoid a broad registry refactor before concrete duplicated contracts are settled. | [R1 A12][R1], [R4 A08][R4], [R6 A11][R6], [R7 E02][R7]; [operation dispatch](../../src/Kernel/SeriesOperations.wl), [automatic arithmetic](../../src/Kernel/SeriesArithmetic.wl). |
| D03 | **Decision.** Add versioned saved-object import/migration if persistence is supported. The public rename to `GeneralizedSeries` is already documented; a compatibility alias was intentionally not exported. Validate migration rather than textually rewriting arbitrary code. | [R1 A08][R1], [R6 A11][R6], [R7 E02][R7], [R8 F08][R8]; guide and C11. |
| D04 | **Focused verified — interval required.** `InverseCertificate` keeps `"Interval" -> Automatic` as the option default but treats an omitted interval as its own refusal: `Failure["InvalidInterval", ...]` with `"Reason" -> "IntervalNotSupplied"` states that no interval is inferred from asymptotic constants. Malformed endpoints return the same tag with `"Reason" -> "MalformedInterval"` and the offending `"Interval"`. Verified bracketing is not implemented; the [certificate regressions](../../src/Tests/CertificateRegressions.wlt) pass 34/34 on Wolfram 15.0.1 and the portable case `certificate-omitted-interval-diagnostic` covers both kernels. | [R1 A09][R1], [R6 A13][R6], [R7 E04][R7], [R8 F10][R8]; [InverseCertificates](../../src/Kernel/InverseCertificates.wl), [CertificateRegressions](../../src/Tests/CertificateRegressions.wlt). |
| D05 | **Optional API decision.** Keep `Normal[s]` and `s[value]` as the documented finite expression and its numerical substitution. A separate checked evaluator could report domain, conditioning, scale, and available bounds. A bare asymptotic `O` with unknown constant cannot supply a numerical error bar. | [R1 A11][R1], [R6 A10][R6]; [result accessors](../../src/Kernel/AsymptoticAnalysis.wl). |
| D06 | **Compatibility decision.** Normalize supported real native direction aliases or reject them helpfully; preserve a clear assumption policy (C05). Clarify absolute source observables versus displacement powers at translated endpoints before changing syntax or semantics. Retain the role of held `SeriesNormalize` before automatic Wolfram cancellations. | [R4 A08][R4], [R6 A12][R6], [R7 E02][R7]; [review 3 API discussion][R3-article], [review 5 API discussion][R5-article], [review 9 API discussion][R9-article]. |
| D07 | **Decision / partially existing.** Versioned release artifacts, checksums, and reproducible load examples remain useful. Download-before-`Get`, offline use, commit-pinned examples, canonical modular sources, and standalone freshness checks already exist; do not implement them again as missing features. | [R1 A14][R1]; [development README](README.md), [standalone workflow](../../.github/workflows/standalone.yml). |
| D08 | **Completed.** The paclet `"License"` and the generated standalone header now use the SPDX identifier `MIT-0`, matching the root MIT No Attribution license; the maintainer confirmed `MIT-0` as the intended distribution metadata. Review-package licenses and notices are unchanged. | [R1 A14][R1], [R6 A14][R6], [R7 E03][R7], [R8 F09][R8]; [PacletInfo](../../src/PacletInfo.wl), [LICENSE](../../LICENSE), [standalone builder](../../validation/build_standalone.py). |
| D09 | **Optional distribution decision.** Add Documentation Center symbol/reference pages and executable examples if native paclet help integration is desired. The current paclet declares a Kernel extension only; the existing HTML guide remains maintained documentation. | [R1 A10][R1], [R6 A14][R6]; [PacletInfo](../../src/PacletInfo.wl). |
| D10 | **API policy decision; current coarsening observed.** Decide whether `SeriesRefine[s, lowerCutoff]` is a minimum-precision request, an explicit refusal, or intentional retargeting that may discard displayed terms. The current R18 probe reproduces valid coarser forward and inverse approximations; this is not a wrong asymptotic formula. Any no-op guard must first validate the request and establish comparable coordinates and cutoff conventions, preserve domains and retained information, and leave deliberate coarsening available through `SeriesTruncate`. | [R18 N02][R18]; [current probe](../../validation/review-18-intake.json), C08, D01, P08 |
| V01 | **Deferred by current user instruction.** The reviews propose a full native release gate and CI semantic coverage. The present workflow checks standalone generation with Python; focused native records remain scoped evidence. Record source hashes, kernel version, selected suites, messages and failed/aborted cases. Do not claim or run a full-suite gate for this task. | [R1 A05][R1], [R4 A07][R4], [R6 A07][R6], [R7 E01][R7], [R8 F07][R8]; [validation record](../../validation/README.md). |
| V02 | **Focused verified.** The aggregate runner reports each discovered `.wlt` file separately, as the focused runner does, and exits nonzero when no file is discovered, the package fails to load, a file produces no report object or executes no test, any test fails, or a requested JSON export cannot be written. The [gate fixture check](../../validation/check_run_tests_gate.py) reproduces all eight synthetic outcomes in a temporary tree ([receipt](../../validation/run-tests-gate-fixtures.json)); no aggregate suite was run. | [R6 A08][R6]; [RunTests](../../src/Tests/RunTests.wl), [FocusedTests](../../validation/FocusedTests.wl). |

<a id="deferred-mathematical-and-architectural-extensions"></a>
## Mathematical and architectural extension proposals

The proposals retain their review identifiers and their distinction from
defects in currently supported behavior. Their relationship to the active
[coverage targets](COVERAGE_TARGETS.md) must now be mapped explicitly:
behavior needed to cover a successful native input or an asymptotic result
in the vendored corpus is required project work. Historical scope-decision
labels below leave the implementation approach and any additional generality
open; they do not exclude required coverage or make it optional.

Closing C01–C23 or the wave-3 intake remains a narrower milestone than meeting
the project goals. Native compatibility items B01–B04, the
[Mathics plan](../Mathics/COMPATIBILITY.md), and the
[vendored coverage register](VENDORED_ASYMPTOTICS.md) track the broader work.
Each new analytic extension still needs an admitted domain, independent
coefficient oracles, remainder and branch obligations, and refusal cases for
inputs outside its proved contract.

| ID | Proposal and boundary | Report source |
| --- | --- | --- |
| X01 | Primitive rationally commensurate flat-rate normalization. Current `flatModel` requires integer multiples of the smallest rate; rates 2 and 3 instead admit primitive rate 1. Bound lattice denominator/degree growth and keep genuinely irrational rate ratios distinct. **Pending scope decision; current restriction inspected.** | [R2 F07][R2], [R5 F07][R5], [R7 F05][R7]; [FlatSectors](../../src/Kernel/FlatSectors.wl). |
| X02 | Shared coefficient algebra for rational/reciprocal logarithms, iterated slow variables, and compatible retained Gamma/Barnes cores. Improve ordered arithmetic, selected composition, Fourier term goals/refinement, and nonvanishing oscillatory coefficients under explicit hypotheses. Preserve conservative composite envelopes when no ordered closure is proved. | [R2 roadmap][R2-article], [R5 specialized scales][R5-article], [R7 roadmap][R7-roadmap], [R8 extensions][R8-article]. |
| X03 | Integration of already constructed germs with an explicit integration constant/normalization, exponent `-1` resonance, coordinate Jacobian, and integrable remainder condition. This is a proposed operation, not a replacement for native asymptotic integration. | [R2 roadmap][R2-article], [R3 roadmap][R3-article], [R4 extensions][R4-article], [R5 roadmap][R5-article], [R8 extensions][R8-article]. |
| X04 | A source-differentiation/re-expansion operation can complement differentiation under a retained derivative contract. It must not infer derivatives of unknown magnitude remainders. | [R16 O01/O02][R16]; [R3 roadmap][R3-article] (retired). |
| X05 | Quantitative tail bounds from checked majorants, stronger interval subdivision/polynomial enclosures, and original-function Gamma/Barnes/Erfc inverse certificates. Require explicit function and derivative bounds; a high-precision residual or a finite asymptotic model is insufficient. | [R3 roadmap][R3-article], [R4 certification][R4-article], [R5 certification][R5-article], [R6 future work][R6-article], [R8 certification][R8-article]. |
| X06 | Independent proof records/checkers for rational interval arithmetic, finite residual identities, and local remainder transport; optional proof-assistant formalization of this small trusted core. Keep formal identity, asymptotic theorem, numerical evidence, and root certification distinct. | [R2 roadmap][R2-article], [R3 verification boundary][R3-article], [R5 evidence architecture][R5-article], [R6 future work][R6-article], [R7 evidence][R7-roadmap], [R8 certification][R8-article]. |
| X07 | Finite conditional parameter cases when a bounded decision procedure proves them. Keep a separate chart, branch and precision contract per case, and retain an inconclusive-within-budget outcome. | [R5 longer-range work][R5-article]. |
| X08 | Multiple independent exponential rates, different phase orders, and nested transseries. Require rate-vector/valuation ordering, local finiteness, resonance handling, and adequate algebraic zero-sector precision. This is substantially larger than X01. | [R2 roadmap][R2-article], [R4 extensions][R4-article], [R5 longer-range work][R5-article], [R7 roadmap][R7-roadmap]. |
| X09 | Selected complex sectors and Stokes-dependent behavior. Define branch geometry, sector-dependent dominance and applicable remainder theorems; accepting complex constants is not such an implementation. | [R3 roadmap][R3-article], [R4 extensions][R4-article], [R6 future work][R6-article], [R7 roadmap][R7-roadmap], [R9 roadmap][R9-article]. |
| X10 | Uniform parameter asymptotics and transition cores near vanishing leading coefficients, closing exponent gaps or changing branches. Fixed-parameter assumptions do not imply uniform error constants. | [R3 roadmap][R3-article], [R4 extensions][R4-article], [R6 future work][R6-article], [R7 roadmap][R7-roadmap], [R8 roadmap][R8-article]. |
| X11 | Coupled/multivariate implicit systems, initially a fixed grading and a nonsingular real leading Jacobian. Partial support orders and conditioning need their own contract; singular systems are a further step. | [R4 extensions][R4-article], [R6 future work][R6-article], [R9 roadmap][R9-article]. |
| X12 | Scoped adapters for native asymptotic integration, summation, ODE and recurrence solvers, or additional special-function thresholds. Report endpoint/parameter scope, native dependence and imported error evidence. Avoid building a new general solver solely to broaden a function-name list. | [R6 adapter roadmap][R6-article], [R7 roadmap][R7-roadmap], [R8 adapter catalogue][R8-article], [R9 roadmap][R9-article]. |

## Complete finding crosswalk

Every wave-1/2 ledger/README finding appears below, including the two named
deltas in report 18. A finding spanning several
contracts maps to more than one item; duplicate reports do not multiply the
number of required fixes. Unnumbered roadmap proposals are covered above.
The [complete wave-3 crosswalk](WAVE_3_INTAKE.md#complete-wave-3-finding-crosswalk)
adds all 44 entries from reports 19–27 and the consolidated `W3-*` work items.

| Review | Finding → register item |
| --- | --- |
| [1][R1] — 14 entries | A01 → C02; A02 → C01; A03 → C03; A04 → C05; A05 → V01; A06 → P06; A07 → D01; A08 → D03; A09 → D04; A10 → D09; A11 → D05; A12 → D02; A13 → P07; A14 → D07, D08. |
| [2][R2] — 7 entries, package retired | F01 → C04; F02 → C02; F03 → C03; F04 → C01; F05 → C08; F06 → P04; F07 → X01. |
| [3][R3] — 5 entries, package retired | F01 → C02; F02 → C01; F03 → C03; F04 → C05; F05 → P04. |
| [4][R4] — 11 entries | A01 → C02; A02 → C01; A03 → P03; A04 → P07; A05 → C11; A06 → P06; A07 → V01; A08 → D01, D02, D06; R01 → C13; R02 → C07; R03 → C06. |
| [5][R5] — 7 entries | F01 → C01; F02 → C02; F03 → P04; F04 → C08; F05 → C10; F06 → P05; F07 → X01. |
| [6][R6] — 16 entries | A01 → C01; A02 → C03; A03 → C09; A04 → C08; A05 → P05; A06 → P06; A07 → V01; A08 → V02; A09 → D01; A10 → D05; A11 → D02, D03; A12 → C05, D06; A13 → D04; A14 → D08, D09; A15 → C12; A16 → P08. |
| [7][R7] — 11 entries | F01 → C01; F02 → C02; F03 → C06; F04 → C07; F05 → X01; E01 → V01; E02 → D01, D02, D03, D06; E03 → D08; E04 → D04; R01 → C13; R02 → P07, P08. |
| [8][R8] — 10 entries | F01 → C05; F02 → C02; F03 → C01; F04 → P02; F05 → P03; F06 → P06; F07 → V01; F08 → D03; F09 → D08; F10 → D04. |
| [9][R9] — 6 entries | F01 → C01; F02 → P01; F03 → P04; F04 → C07; F05 → C08; F06 → C03. |
| [10][R10] — 2 entries, package retired | N01 → C05; N02 → P06. |
| [11][R11] — 4 entries | N01 → C05; N02 → C15; N03 → C16, B03; N04 → C07, B01. |
| [12][R12] — 3 entries, package retired | N01 → C05; N02 → C07, C13, B01; N03 → C17. |
| [13][R13] — 3 entries, package retired | A1 → C14, C12; A2 → C07, B01; A3 → C21. |
| [14][R14] — 5 entries, package retired | N01 → C15; N02 → C20; N03 → C21; N04 → D01, D02; N05 → C22. |
| [15][R15] — 4 entries | F01 → C18; F02 → C19; F03 → C23; F04 → X02. |
| [16][R16] — 7 entries | N01 → C05; N02 → C19; N03 → D01, P06; N04 → D01; S01 → C04, P02, P03; O01 → X04, X05; O02 → X04, X05. |
| [17][R17] — 4 entries | N1 → C05; N2 → C23; N3 → C21; N4 → B04. |
| [18][R18] — 4 entries | N01 → C19; N02 → D10, C08; D-C07 → C07, B01–B03; D-C04 → C04, P02, P03. |

## Next priorities and acceptance records

1. Preserve W3-10's recursive logarithm identity hypotheses and its 207/0
   focused acceptance when parser consumers change. Its public baseline,
   intermediate guard and first-pass failures remain separate evidence.
   W3-06's observable Taylor and real-input guards remain focused verified.
2. Resolve W3-01–W3-03 with one coherent option/default and positional-role
   policy; the [request-resolution workplan](REQUEST_RESOLUTION.md) records
   the source audit, proposed shared record and characterization matrix.
   Retain explicit contracts and once-only evaluation. Track W3-04,
   W3-05 and W3-15's native storage/outcome/traversal proposals separately.
3. Extend C14/C15's focused evidence when related paths change, then address target-chart correctness C18.
   Establish C16's source/admission boundary alongside native compatibility.
4. Retain the focused acceptance boundaries for C01–C07 and P03; extend their
   evidence with wave-2 witnesses where applicable. C17 adds a distinct native
   index constraint beyond C01's dense-allocation bound.
5. Establish C08's achieved-precision postcondition, including W3-07's exact
   zero-demand case; then replace the fixed
   margins with backward demand planning. Address P01–P03 as bounded resource
   fixes, followed by measured P04/P05 work.
6. Address the remaining W3 items with focused contract checks;
   C09, C10, C20, C21, C23, D04, D08 and V02 are closed above, and C22 is closed for truncation but not for arithmetic.
   Resolve D10's lower-cutoff refinement policy separately from a soundness fix.
   Distinguish correctness repairs, required coverage gaps, and additional
   mathematical generality when evaluating the recorded proposals. Map every
   native or vendored asymptotic requirement to the coverage plans.

For each completed item, record the implementation revision, exact source hashes,
focused tests and kernel, independent oracle, relevant benchmark/control results,
and any remaining contract boundary. Update this register alongside that evidence.
Passing an unrelated historical suite, a source-only model, or a patched review
fixture alone does not close an item in the current package.

[R1]: ../../external-reports/code-review/wave-1/code-review-1/evidence/findings.csv
[R2]: ../../external-reports/code-review/wave-1/code-review-2.md
[R3]: ../../external-reports/code-review/wave-1/code-review-3.md
[R4]: ../../external-reports/code-review/wave-1/code-review-4/evidence/findings.json
[R5]: ../../external-reports/code-review/wave-1/code-review-5/evidence/findings.json
[R6]: ../../external-reports/code-review/wave-1/code-review-6/evidence/findings.csv
[R7]: ../../external-reports/code-review/wave-1/code-review-7/evidence/findings.csv
[R8]: ../../external-reports/code-review/wave-1/code-review-8/evidence/findings.csv
[R9]: ../../external-reports/code-review/wave-1/code-review-9/README.md#findings
[R10]: ../../external-reports/code-review/wave-2/code-review-10.md
[R11]: ../../external-reports/code-review/wave-2/code-review-11/evidence/findings-delta.json
[R12]: ../../external-reports/code-review/wave-2/code-review-12.md
[R13]: ../../external-reports/code-review/wave-2/code-review-13.md
[R14]: ../../external-reports/code-review/wave-2/code-review-14.md
[R15]: ../../external-reports/code-review/wave-2/code-review-15/evidence/findings.csv
[R16]: ../../external-reports/code-review/wave-2/code-review-16/evidence/findings.csv
[R17]: ../../external-reports/code-review/wave-2/code-review-17/evidence/novelty_matrix.json
[R18]: ../../external-reports/code-review/wave-2/code-review-18/evidence/novelty_ledger.json
[R18-validation]: ../../external-reports/code-review/wave-2/code-review-18/evidence/patch_validation.json
[R2-article]: ../../external-reports/code-review/wave-1/code-review-2.md
[R3-article]: ../../external-reports/code-review/wave-1/code-review-3.md
[R4-article]: ../../external-reports/code-review/wave-1/code-review-4/article.tex
[R5-article]: ../../external-reports/code-review/wave-1/code-review-5/article/asymptotic-audit.tex
[R6-article]: ../../external-reports/code-review/wave-1/code-review-6/article/article.tex
[R7-roadmap]: ../../external-reports/code-review/wave-1/code-review-7/article/04-engineering-and-roadmap.tex
[R8-article]: ../../external-reports/code-review/wave-1/code-review-8/article/asymptotic_repository_audit.tex
[R9-article]: ../../external-reports/code-review/wave-1/code-review-9/article.tex
