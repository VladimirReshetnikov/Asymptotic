# Wave 4: findings, proposals, and implementation scope

All nine [wave-4 reports](../../external-reports/code-review/wave-4/README.md)
as supplied, numbered 28–36, are included in the active implementation scope;
eight packages are retained and report 32 is retired, its rows kept below. They
add **64 identified entries**: 10, 7, 6, 6, 8, 7, 6, 6, and 8 respectively.
Together with 167 entries from the earlier waves, the wave-1 to wave-4 packages
supplied **231 attributed entries in 36 reports**. Overlaps are consolidated below;
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
every supplied byte with its arrival Git blob and records all hashes; it
describes the arrival tree, not the current checkout. The eight retained
packages' payloads, candidate programs, notices and original evidence remain
unchanged; report 32's seventeen files were retired afterwards, so 163 of the
180 are still present, unedited.

The incoming intake recorded at `c11995f` reports three independent lanes
reading every README, complete TeX article, finding ledger and relevant
evidence/candidate code, then comparing the mechanisms with production sources
through `725a547`. No supplied program was executed during that intake.
**Source inspected** below establishes
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
current package acceptance are not combined into one passing total. This
intake did not run the full original MUnit package suite. The later Mathics
acceptance record below covers a separate portable-suite snapshot.

## Consolidated work

`W4-*` identifiers are maintained work items; report-local IDs are retained in
the complete crosswalk below. A corrected source comment or previous related
repair does not settle a new mathematical or runtime obligation.

| Item | Finding and current disposition | Implementation and focused acceptance obligations |
| --- | --- | --- |
| W4-01 | **Characterized on Mathics 10.0.1 against an mpmath oracle; no unsafe public route found.** The package never stores a raw two-argument `ProductLog` in a returned expansion: `AsymptoticInverse[x Exp[x], {x, 0}, {y, 3}]` is the principal Lagrange series `y - y^2 + O(y^3)`, the infinite endpoint gives the logarithmic-scale Lambert expansion, and the lower branch `{x, -Infinity}` gives the `"Transformed"`-scale expansion in `Log[-y]` and `Log[-Log[-y]]` whose finite part is free of `ProductLog`. Numerical specialization at 20 digits agrees with mpmath: the cutoff-6 lower branch at `y = -1/100` gives `-6.4727729` against `W_{-1} = -6.4727751`, at `y = -10^-6` `-16.6265099` against `-16.6265089`, and the cutoff-4 infinite endpoint at `y = 100` gives `3.3926` against `W_0 = 3.3856`, differences within the stated remainders. Mathics' own `N[ProductLog[-1, -1/100], 20]` stays unevaluated (the numerical arity is missing), which is why the package keeps that spelling out of its results; `AsymptoticSpecialInverse["LambertThreshold"]` at an infinite endpoint is refused (`UnsupportedEndpoint`). Related: D05, X05/X06. | Characterize both construction and specialization of entropy and exponential exact cores, literal principal-branch forms, differentiation and arbitrary precision. Test original equations and branch intervals with an independent oracle. Repair argument/reverse conversion and numerical arity together, or guard the unsupported operation before it can evaluate unsafely. A late `s[value]` guard cannot repair an already changed core or external use of `Normal[s]`. Swapped SymPy/mpmath examples in the reports are countermodels, not observed Mathics package outputs. |
| W4-02 | **Verified on Mathics — explicit refusal, no manufactured digits.** The Mathics numerical adapter refuses a `PrecisionGoal` above machine precision before solving (`MathicsNumericalPrecisionUnavailable`) and, after a solve, refuses a root whose returned precision is below the goal; an exact root is accepted only after exact polynomial substitution proves it. Probed on Mathics 10.0.1: `InverseNumericalCheck` on `Exp[x] - 1` at `WorkingPrecision -> 50` and on `x + x^2` at `40` both return the refusal rather than a machine-precision root labelled as a high-precision comparison. Numerical approximation (machine precision on Mathics), interval certification (`InverseCertificate`, exact rationals) and this capability refusal are therefore distinct records; a 20/50/100-digit comparison table exists only for the official kernel. Related: D05, distinct from C21 translated coordinates. | Compare requested 20/50/100 digits with achieved precision, true error and residual on well-scaled roots, including exact roots and solver failures. Do not manufacture accuracy with `SetPrecision`. Numerical approximation, interval certification and capability refusal need distinct records. |
| W4-03 | **Partly implemented — exact polynomial eventual-sign certificate.** On Mathics, `inverseFunctionEventually` first decides a polynomial condition in the local coordinate exactly: the lowest-order coefficient with a proved sign under the retained assumptions fixes the eventual sign, so `0 < x < 10^-30` and `u < a` under `a > 0` are proved on their own arbitrarily small neighbourhoods, `u^2 - u > 0` is refuted, and an unproved or nonreal coefficient stays unproved rather than false; conjunctions and relational chains are combined clause by clause. The seven dyadic trial radii remain only for nonpolynomial conditions. Polynomial domain inference with parameter coefficients still uses exact real coefficients only (the `FunctionDomain` replacement has no assumption argument), which remains open. Related: C05/C16, X07. | Add exact affine and then polynomial eventual-sign certificates with a proved positive radius; combine conjunctions and relational chains correctly. Propagate a smaller radius into any later fixed-neighborhood theorem. Distinguish unproved from false, symbolic pointwise radii from uniform bounds, and coefficient reality from monotonicity. Thread retained assumptions into domain proof without accepting unknown, nonreal or source-dependent coefficients. |
| W4-04 | **Public consequences probed on Mathics — no unsafe path found.** `InverseExpansionCoefficient[s, {}]` on Mathics 10.0.1 returns the structured `InvalidMultiIndex` refusal (one nonnegative integer per correction block) and `{5}` returns the full coefficient record, so the public validation does not reach an empty `Map`; the compatibility `Lookup` and key adapters were covered by the W3-08 empty-list cases (`operations-empty-inverse-multi-index`, `primitive-lookup-*`), which pass in the current 33/33 operations and primitive runs on both layouts. Related: V02; W3-08 model admission is separate. | Audit `Lookup`, key operations and zero-dimensional multi-indices. Test reuse of caller inputs and returned empty lists inside subsequent numeric lists. Add narrow empty fast paths after required dimension/type checks; avoid global System or blanket context rewrites. |
| W4-05 | **Addressed — two-sided Automatic direction.** The private Mathics `Limit` adapter now takes both one-sided limits when the direction is omitted or `Automatic` at a finite point and returns their common value, `Indeterminate` when they disagree, or the unresolved form when a side is unresolved, as the official kernel does; explicit sides and infinite endpoints are unchanged. Pinned by the portable case `primitive-limit-automatic-direction-is-two-sided` on both kernels. Related: D06; W3-06 is separate. | Replacing left by right no longer implements the default: `Abs[u]/u` at `0` is `Indeterminate`, `1` from above and `-1` from below. |
| W4-06 | **Partly addressed — option grammar.** The `FirstPosition` adapter treats a `Heads` rule in the third slot as an option rather than as a default value, matching the official kernel (portable case `primitive-firstposition-third-slot-heads-option`); held effectful defaults and level specifications were already preserved. The first-level early stop remains a performance proposal: Mathics 10.0.1 `Position` has no match-count argument, so the adapter still gathers every match. Related: P08. | Verify first/middle/last/missing and head/level controls before any early-stop rewrite; predicate counts are not timings. |
| W4-07 | **Measured for power-log jets — sparse; remaining dense allocations named.** On Wolfram 15.0.1, `AsymptoticExpansion[1 + x^d, {x, 0, d + 3}]` and its square keep a constant `ByteCount` (5,072 and 17,472 bytes) and constant time (about 0.03 and 0.01 s) for `d = 100`, `1000` and `10000`: the power-log jets are sparse row lists and no degree-sized coefficient list is built for a compact support. The degree-sized allocations that remain are the `CoefficientList` over the logarithmic variable in coefficient realness proofs (its degree is the logarithmic degree, not the power), the dense native `SeriesData` view (guarded separately, C17), and the Mathics `CoefficientRules` adapter documented in the Mathics algebra notes; dense `(1 + x)^D` inputs are dense by nature. Related: P06/P08. | Inventory and share sparse support operations, while bounding expansion before allocation. Compare fixed occupied support at increasing degree, cancellation, zero polynomials, coefficient ordering, realness, conjugacy and envelopes. Compact `x^D` and dense `(1+x)^D` need different bounds; never drop retained amplitudes to meet a cap. |
| W4-08 | **Implemented, and a hidden Mathics abort repaired.** The Mathics defining-series provider now admits a terminating sum of any rank (a nonpositive-integer upper parameter `-m` ends the sum at index `m`, so `p <= q + 1` is required only for nonterminating sums), an exact real noninteger lower parameter, and for a terminating sum a nonpositive-integer lower parameter `-n` with `n >= m`; a lower parameter at a pole below the termination index and a divergent nonterminating rank are still refused, with no regularization convention. In practice Mathics evaluates terminating sums to polynomials before the provider is reached, and the shared terminating-identity path already covered the official kernel. The provider also builds rising factorials as explicit products: Mathics evaluates `Pochhammer[1/3, 2]` to factorial ratios such as `(-3/2)!` whose downstream coefficient proofs aborted the whole request silently, so `AsymptoticExpansion[Hypergeometric0F1[3/2, x], {x, 0, 4}]` and the `2F1(1/3, 2/3; 5/4; x)` control returned `$Aborted` on Mathics 10.0.1 before this change and now give exact rational coefficients. Portable cases `special-hypergeometric-parameter-admission` and `special-hypergeometric-defining-series` pass on both kernels. Related: X12. | Admit terminating nonpositive-integer upper parameters before the nonterminating rank gate, with degree/work bounds and truthful omitted tails. A later extension may admit exact negative noninteger lower parameters with proved majorants. Preserve denominator-pole refusals, convergence-radius restrictions, fixed monomial coordinates and constant outer multipliers; no implicit regularization convention. |
| W4-09 | **Addressed — mandatory load gate.** [MathicsTests.wl](../../validation/MathicsTests.wl) now exits with `ASYMPTOTIC_PORTABLE_LOAD_FAILED` before any case is selected unless `Get` returned neither `$Failed` nor `$Aborted`, the package context and context path are present, the working context is `Global`` and the public `AsymptoticInverse`, `AsymptoticExpansion` and `GeneralizedSeries` definitions exist, so a package-independent primitive cannot pass on failed setup. A nominally successful nonpackage file is rejected by the capability checks. Related: V01/V02. | Make successful load a mandatory separate top-level gate before all selected cases; characterize failed/aborted loads and a nominally successful nonpackage file with required-capability checks. Preserve Mathics `Print`/`Check` separation and legitimate non-Null `Get` values. This source-proved gap is not a claim that historical case results used failed setup. |
| W4-10 | **Focused verified — deadline guard in the 32/0 runner checks.** Nonfinite, nonpositive and greater-than-one-day deadlines are rejected before output or launch, including direct `run_case` calls. | The supported interval is `(0, 86400]` seconds. Exact boundaries and NaN/infinity/huge-value controls pass on the recorded Windows host. Larger durations require a separately supported waiting policy; cross-platform acceptance beyond this host remains separate. |
| W4-11 | **Focused verified — lexical launcher selection in the 32/0 runner checks.** Existing Python/default-Python/Wolfram paths become absolute without dereferencing symlinks; bare PATH commands are preserved. | Tests cover paths with spaces, actual symlinks and a real temporary venv-only import. The recorded host is Windows; a POSIX symlinked-venv execution and durable child-environment identity remain additional controls. |
| W4-12 | **Implemented — coherent snapshots.** The runner copies the package closure (the entry, or the modular `Kernel` directory's `*.wl` files and `init.m`) into its private directory after fingerprinting, refuses to launch when the copy does not reproduce `TestedSourcesSHA256`, and runs every kernel from that copy; `ExecutedSource`, `ExecutedSourcesSHA256` and `SourceSnapshot` record it. Original and executed hashes are recorded separately: `SourcesUnchangedDuringRun` now rehashes the executed copy at every checkpoint (a tampered copy stays latched in `FirstObservedSourceDriftSHA256` and fails the run), while an edit of the live tree is reported by `LiveSourcesChangedDuringRun` and its fields without invalidating the evidence, since no kernel can read it. An A–B–A edit of the live tree between observations is therefore harmless rather than undetected. The 34/34 runner tests cover the frozen suite, the frozen modular closure with siblings, live drift, tampered-copy latching and the attempted-case record. Related: V01/V02. | Freeze the complete declared package/suite/adapter closure, covering `init.m`, renamed modular trees, the executed suite copy and standalone entries, and record original versus executed hashes separately. A sticky flag cannot detect an entire A–B–A edit between observations; endpoint equality does not prove temporal immutability. No historical receipt is alleged to have encountered such an edit. |
| W4-13 | **Partly addressed — aliases rejected, attempted case recorded.** Final and `.tmp` aliases of fingerprinted inputs are rejected before launch and before each write, including direct, relative, symlink and hard-link aliases, and the incomplete report now names the case whose kernel is running in `InProgressCase` before that kernel is launched. These checks do not lock the filesystem against intervening changes; bounded output with terminal overflow failure and the Windows process-tree tests remain pending. Related: V01/P06. | Extend dependency closure under W4-12. Add bounded output with terminal overflow failure even after a success frame; retain bounded diagnostics and compact publication. Write attempted-case identity before launch and preserve interruption/cleanup outcomes. Test owned process trees and inherited pipes on Windows and POSIX; the supplied POSIX supervisor is not a Windows implementation. |
| W4-14 | **Partly addressed before intake.** R34's missing standalone-builder CI trigger is already fixed for push and PR. Broader dependency triggers and declaration/group/shard inventory remain open. Related: V01/V02. | Derive or validate all suite cases and workflow groups against one inventory, reject unknown/dynamic registration constructs deliberately, and detect missing/duplicate/empty coverage. Verify source and test dependencies, both layouts, runtime/version and exact commit. The new 16-test receipt verifier validates complete submitted evidence; it does not itself repair discovery or execute a current Mathics matrix. |
| W4-15 | **Pending — preventive adapter contract.** Late definition rewrites lack a versioned expected-match/consumer/postcondition record. Reports do not establish a currently failed installation. Related: V02/B04, distinct from W3-11 distribution scanning. | Inventory executable consumers, call shapes, attributes, binding time and fallback semantics. Assert expected rewrite counts/residual forms, test perturbed miniature definitions and reload idempotence, and retain separate native definition-preservation checks. Passing native controls does not prove a Mathics-only rewrite executed. |
| W4-16 | **Measured — no material cost found; proposals remain optional.** On Wolfram 15.0.1, `AsymptoticExpansion[Gamma[x], {x, Infinity, n}]` takes about 0.5, 0.4, 0.6 and 0.9 s for `n = 4, 8, 12, 16`, and `SeriesRefine` of `AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, n}]` to `2 n` takes 0.06, 0.21, 0.61 and 2.3 s for `n = 5, 10, 20, 40` (about `n^1.8`, the coefficient work itself); neither shows the repeated-phase or key-scan growth the reports projected. Direct key membership and Gamma Newton doubling stay optional optimizations. Related: P04/P06/P08. | Profile predicate/key/phase/product/allocation counts before native timing. Investigate direct key membership and Gamma formal Newton doubling in its derived coefficient ring, with independent coefficients, precision frontiers, assumptions, domain and budget controls. Reuse Gamma cores across observable powers only when their contracts agree. Finite prototype agreement is not an all-orders or Barnes derivation. |
| W4-17 | **Pending — exceptional loading lifecycle.** The compatibility context is removed on normal completion without an outer cleanup contract for interruption or partial loading. Related: V02. | Inject interruption at load phases, inspect context/path/stack and partial definitions, and establish subsequent reload behavior for both entries and runtimes. Restoring only `$ContextPath` need not restore the Begin/End stack or atomic definitions. |

## Detailed source obligations

The following **20 mechanism-level notes** refine the 17 work items above;
they are not additional finding IDs or a second disposition count. Their
production-source baseline was
[`38aa253aaf792577100103a76a9db165d7390e0e`](https://github.com/VladimirReshetnikov/Asymptotic/tree/38aa253aaf792577100103a76a9db165d7390e0e).
The runner notes incorporate the merged `45ea65f` changes. Later Fourier
integration and Mathics peer acceptance are recorded separately below.

### Deadline validation — W4-10

**Focused repair merged.** The [portable runner][runner] now validates a finite timeout in `(0, 86400]` seconds before reporting or launching, including direct `run_case` calls. This replaces the earlier `timeout <= 0` guard; the one-day ceiling is now the documented policy.

Retain parser errors, exact boundaries, ordinary finite timeouts, process cleanup and valid JSON controls. The [32/0 receipt][runner-receipt] verifies the recorded Windows host; cross-platform exception text need not match and other platforms need their own acceptance.

### Executed source provenance and dependency closure — W4-12

**Partly addressed.** The [runner][runner] now latches the first observed mismatch in `FirstObservedSourceDriftSHA256`, retains final hashes, and exits unsuccessfully even after restoration. It still fingerprints siblings only for an entry named `AsymptoticAnalysis.wl` in a directory named `Kernel`; `init.m` and other relocated layouts need separate treatment. It executes a live package path, copies only the suite, and does not recheck that executed copy.

Preserve monotone invalidation and the first mismatch; explicitly describe the source layout or dependency set. Stage coherent package, suite and runner inputs before execution and verify the staged inputs. Endpoint hashes cannot exclude a change-and-restore wholly between observations. The [acceptance checker][acceptance] validates recorded hashes against Git blobs; it does not freeze the runner inputs.

### Interpreter invocation identity — W4-11

**Focused repair merged.** Existing executable paths in the [runner][runner] now become absolute without dereferencing symlinks; bare PATH commands remain unchanged. The [32/0 receipt][runner-receipt] includes actual symlinks, paths with spaces and a temporary virtual environment with a private import on Windows. Report 31's POSIX witness remains separate evidence.

Retain selected/default Python and Wolfram launcher controls, missing paths and ordinary interpreters. A POSIX symlinked-venv execution and durable child-environment identity remain additional controls. A Python environment-only witness is not a complete Mathics run.

### Interrupted in-flight cases — W4-13

**Mechanism present.** The [runner][runner] appends a case only after `run_case` returns. It cleans up on interruption, but an interrupted active case is absent from the last saved result list. The saved run remains incomplete; this is not by itself a false-success finding.

Record the active case before launch and persist an explicit interrupted outcome with available diagnostics during unwinding. Preserve process-tree ownership, completed results, atomic writes, and launch-error behavior. Report 29's SIGINT fixture is POSIX evidence; Windows interruption needs its own check.

### Mandatory load success — W4-09

**Addressed.** [MathicsTests.wl][suite] stores `portableLoadResult = CheckAbort[Check[Get[...], $Failed], $Aborted]` and, in a separate input, refuses to define or select any case unless the load returned neither `$Failed` nor `$Aborted`, the package context and context path are present, the working context is `Global`` and the public `AsymptoticInverse`, `AsymptoticExpansion` and `GeneralizedSeries` definitions exist; it prints `ASYMPTOTIC_PORTABLE_LOAD_FAILED` and exits with status 2 otherwise. A package-independent primitive therefore cannot certify package loading, and a nominally successful nonpackage file fails the capability checks. The runner records that exit as a case failure in both layouts and both runtimes.

### Diagnostic output budgets — W4-13

**Partly addressed; output limits remain open.** The [runner][runner] rejects final and `.tmp` report paths aliasing fingerprinted inputs before launch and before every write, including relative, symlink and hard-link aliases. These are observed-path guards, not an atomic filesystem lock. `communicate()` still retains complete merged output and report writes still reserialize accumulated diagnostics without a byte ceiling.

Retain the alias controls while extending dependency closure. Bound captured output with a useful prefix/tail or separate diagnostic artifact, explicit terminal overflow status, and reliable timeout/cleanup even after a success frame. Measure I/O and memory before claiming a speedup. Synthetic POSIX supervisor tests do not establish Windows process-tree behavior or a real package out-of-memory event.

### Complete inventory and CI triggers — W4-14

**Partly addressed.** The [Mathics workflow][workflow] already includes `validation/build_standalone.py` and `validation/test_standalone.py` in both push and pull-request path filters, so report 34 R4's concrete trigger omission is repaired in the inspected source. The [runner][runner] and [acceptance checker][acceptance] still derive cases from the same strict line-oriented regular expression. The workflow's group partition is maintained separately.

Preserve the repaired triggers. Check every legal/admitted test declaration and every group exactly once per layout; reject unsupported declaration syntax instead of silently omitting it. Add formatting, comments/strings, duplicate-ID and new-group mutations. The checker already validates complete receipt unions against its parsed reference inventory; that does not independently prove the parser recognized every declaration. No current missing case or shard is asserted here.

### ProductLog conversion and nonprincipal evaluation — W4-01

**Open compatibility work; documentation clarified.** [MathicsCoreFunctions.wl][core] rewrites selected principal-branch construction sites to one-argument `ProductLog`; other branches retain the System two-argument head. Reports trace exact/reverse SymPy conversion and numerical-arity problems and supply independent countermodels. The [maintained algebra note][algebra-doc] now covers the symbolic and numerical boundaries; that clarification does not repair the interpreter bridge. Those interpreter traces are report evidence, not a fresh runtime reproduction here.

Test exact, symbolic, approximate, forward and reverse conversion, derivatives, all retained construction sites, and later `Normal[s]`/`s[value]` specialization. Preserve real branch conditions. A conservative capability refusal avoids an unsafe numerical claim but does not complete compatibility. Rational entropy/Lambert certificates and floating-point log-excess solvers are different candidate implementations with different guarantees.

### Achieved numerical precision — W4-02

**Source gap identified; public witness unverified.** [NumericalInverseChecks.wl][numerics] requests working precision and validates numeric/branch/domain results, but has no explicit achieved-precision postcondition for the returned root. Its output calls the result a high-precision comparison. Report 28 traces interpreter numerical limitations; this intake does not reproduce them. The [compatibility note][compatibility-doc] now distinguishes requested working precision from achieved accuracy.

Characterize well-conditioned exact roots at increasing requested precision, then ill-conditioned cases and branch-sensitive targets. Require measured achieved accuracy/precision or a clear unsupported/failure result; extra printed digits are not evidence. Retain the distinction between a numerical comparison, a residual, and an interval certificate. Include the separate Gamma/Barnes and special-adapter numerical paths when defining a shared contract.

### Limit default semantics — W4-05

**Mechanism present; public wrong-result reachability unverified.** [MathicsSimplification.wl][simplification] maps omitted/`Automatic` direction to `1`. Reports compare this with the recorded Wolfram real two-sided default. Several inspected branch consumers already supply a direction, so the helper mismatch alone does not establish an incorrect public expansion.

Identify every implicit-direction consumer. Supply an explicit local side where mathematically justified; otherwise implement or conservatively retain two-sided semantics. Test agreeing and disagreeing one-sided limits, unresolved sides, assumptions, infinities, and explicit direction controls. Replacing the lower side with the upper side does not implement a two-sided limit.

### FirstPosition grammar and traversal — W4-06

**Mechanisms present.** [MathicsCompatibility.wl][compat] implements first position by collecting `Position` results, then taking the first. Its three-argument form treats the third argument as a default, including an option-shaped expression. Reports identify both grammar and allocation/work questions.

Preserve defaults lazily, level specifications, `Heads`, missing cases, and supported option forms. A narrow level-one fast path or an upstream primitive needs traversal-law tests. Do not assume a native bounded-`Position` overload exists on the pinned Mathics version. Report 36's native probe did not establish its proposed callback distinction; allocation evidence is separate from side-effect semantics and timing.

### Empty-list Map coverage — W4-04

**Coverage boundary remains.** [MathicsLists.wl][lists] rewrites references only in `AsymptoticAnalysis`'s private context. The public [InverseExpansionCoefficient definition][main] maps over its multi-index, and [Mathics-context Lookup helpers][compat] map over key/association lists. These are distinct sites outside that sweep. The predicted caller-list cache manifestations were not exercised here.

Characterize valid empty indices, empty key lists and lists of associations, followed by reuse of the caller-owned empty list. Extend protection only where needed, preserving explicit levels/options and nonempty behavior. Keep System definitions unchanged; do not equate coverage of one private `Map` fixture with all package call sites.

### Sparse coefficient and Fourier amplitude storage — W4-07

**Mechanisms present.** [MathicsAlgebra.wl][mathics-algebra] calls `CoefficientList` before removing zeros. [MathicsInverseBranches.wl][branches] also scans dense polynomial coefficients. [FourierCoefficients.wl][fourier] uses dense logarithmic-polynomial lists in realness and envelope calculations. Fixed outer support does not bound these inner degree-sized intermediates.

Provide sparse exact extraction for an explicitly supported grammar, with separately budgeted expansion and bounded fallback. Compare coefficients, realness, logarithmic degrees, conjugacy and absolute envelopes on fixed-support increasing-degree inputs. Independent Python models are useful oracles, not kernel memory benchmarks. The peer Fourier termination change below addresses unnecessary products, not these inner polynomial representations.

### Retained-frontier membership cost — W4-16

**Mechanism present.** [Mathics `KeyExistsQ`][compat] maps over `Keys[a]`; [IncrementalInverse.wl][incremental] uses membership checks while extending the retained boundary. This adds potential boundary-size work despite retained inverse state.

Profile actual membership/enumeration work and preserve exact key identity, grouping, persistent-state behavior and statistics. Compare with fresh reconstruction over increasing boundary sizes. An exact counting model is not an end-to-end Mathics speedup, and successful retained-state tests do not measure lookup complexity.

### Parameter assumptions in polynomial-domain proofs — W4-03

**Mechanism present.** [mathicsPolynomialFunctionDomain][branches] receives the body, variable and `Reals`, and checks `exactRealQ` on its coefficients. The replacement for `FunctionDomain` does not explicitly receive the branch validator's retained `ass` argument.

Thread the retained assumptions into this bounded proof without accidentally using unrelated global assumptions. Cover proved-real symbolic coefficients, unknown/nonreal coefficients, affine domains and parameter capture. Real-valuedness on a domain is not monotonicity, injectivity or global branch selection; preserve those separate obligations. The report's public path remains unverified here.

### Constructive eventual neighborhoods — W4-03

**Bounded extension required.** [MathicsInverseBranches.wl][branches] tries radii `2^-j` for `j = 0..6`, then delegates to the existing general fallback. Failure at those trial radii does not disprove an eventual condition. Reports supply rational affine or polynomial radius constructions.

Start with a declared exact grammar, construct a positive radius, and independently verify the entire deleted interval. Preserve strict/non-strict inequalities, equalities, conjunctions, real operands, symbolic margins and unknown-sign refusals. Never use existence of some smaller neighborhood as truth on a caller-specified fixed interval. Polynomial eventual sign alone is not global branch uniqueness.

### Defining Taylor extensions — W4-08

**Proposal; current provider gate confirmed.** [MathicsTaylor.wl][taylor] requires `Length[upper] <= Length[lower] + 1` and positive lower parameters before its coefficient construction. The proposals distinguish finite terminating PFQ polynomials from nonterminating convergence and consider some negative nonintegral lower parameters with explicit tails. Native pre-evaluation may already simplify particular public inputs, so provider rejection is not proof of every proposed public failure.

Detect exact termination before applying a nonterminating rank condition; define denominator-pole and regularization policies explicitly. Preserve finite-order omitted terms and exact-zero termination. For an enlarged infinite family, prove the stated tail under its parameter restrictions rather than importing the finite argument. Test native simplification and direct provider entry separately, plus arity, resources, complex parameters and unsupported cases.

### Gamma-specific Newton reversion — W4-16

**Development proposal.** [GammaInverse.wl][gamma] computes the normalized unit by a triangular coefficient recurrence. Report 29 supplies independent triangular/Newton agreement and a unit-Jacobian derivation; it does not integrate a package algorithm or benchmark the production path.

Compare complete inverse-logarithmic coefficient polynomials, low-order independent oracles, affine/observable reconstruction, frontiers, resource limits and Poincare remainder metadata. Benchmark equal output/order and account for algebraic expression growth. This is distinct from the already implemented ordinary inverse Newton algorithm. Do not transfer Gamma acceptance automatically to Barnes G.

### Adapter installation invariants — W4-15

**Preventive proposal.** Late [core][core], [refinement][mathics-refinement], [branch][branches] and [list][lists] adapters transform named definitions or scan private downvalues. The reports request match counts and postconditions; they do not establish a failed current installation.

Declare intended transformation targets and check postconditions after load/reload. Mutation fixtures should detect missing, duplicated or structurally changed targets, while successful preservation checks keep System definitions and held evaluation behavior intact. A match count alone cannot prove the replacement's semantics.

### Interrupted loading and context cleanup — W4-17

**Source-level exception-safety advisory.** The [main loader][main] removes the Mathics context after the module loads and `EndPackage[]`. This final cleanup is not enclosed in an explicit abort-safe restoration boundary. The report's interrupted-load manifestations remain unverified.

Characterize message, failure and abort paths during early and late loading, then attempt a clean reload. Restore the caller's context state appropriately without masking the original failure or changing System definitions. Normal successful load/reload tests do not cover interrupted parsing or partially installed definitions.

## Complete finding crosswalk

The merged [`45ea65f` runner repair](https://github.com/VladimirReshetnikov/Asymptotic/commit/45ea65ffb969dc5f1df8e08f3a92b407e3db096d)
and its [32/0 focused runner receipt](../../validation/wave4-runner-integrity-tests.json)
record 18 new cases plus the 14 existing protocol/process/report tests, two
unchanged source hashes and zero skips. It uses synthetic peers and real
temporary Python processes/virtual environments, without loading Wolfram or
Mathics. It closes the stated deadline and lexical-launcher changes and only
the specified parts of source integrity and publication; it does not close
W4-09's mandatory setup gate or the complete portable evidence workstream.

Every identified entry is mapped, including advisory and development entries.
An entry may span more than one work item; overlapping reports do not multiply
the required fixes. The [static crosswalk receipt](../../validation/wave4-intake-crosswalk.json)
compares all 64 IDs with the supplied ledgers. The 17 identifiers match that
maintained crosswalk. The detailed rows below preserve each attributed entry
under those identifiers. The 20 source-mechanism descriptions above are
details of the same work items; the 16 proposal groups below separately cover
the unnumbered recommendations.

Each row below is one original ledger entry. Evidence phrases summarize the
supplied ledger; they do not promote a report's source trace to a runtime
observation. Read the linked primary ledger and package README for details.

| Report / ID | Attributed contribution and evidence boundary | Work items |
| --- | --- | --- |
| [28 F01][R28] | Requested versus achieved root precision; interpreter source trace, public runtime probe unexecuted. | W4-02 |
| [28 F02][R28] | Retained lower-Lambert core specialization; source trace plus independent countermodel/rational certificate. | W4-01 |
| [28 F03][R28] | Omitted Limit direction; explicit-direction consumers excluded from the claim. | W4-05 |
| [28 F04][R28] | FirstPosition option-only grammar and all-match materialization; source analysis, probes unrun. | W4-06 |
| [28 F05][R28] | Nonfinite deadlines; guard countermodel and repaired validator executed independently. | W4-10 |
| [28 F06][R28] | Endpoint hashes versus executed bytes; edit/revert and synthetic immutable-Git checks. | W4-12 |
| [28 F07][R28] | Unbounded diagnostics/report serialization; bounded POSIX supervisor tested with synthetic children. | W4-13 |
| [28 E01][R28] | Exact rational affine radius construction; prototype executed, public fallback behavior unestablished. | W4-03 |
| [28 E02][R28] | Terminating PFQ exception; exact coefficient prototype, native simplification may bypass the provider. | W4-08 |
| [28 E03][R28] | Late-downvalue rewrite invariants; preventive proposal, no failed installation asserted. | W4-15 |
| [29 N1][R29] | Nonfinite/oversized timeouts; actual upstream runner with simulated kernel protocols. | W4-10 |
| [29 N2][R29] | `init.m` dependency monitoring; synthetic dependency-tree mutation. | W4-12 |
| [29 N3][R29] | Missing active case after interruption; POSIX SIGINT fixture, not a false-success allegation. | W4-13 |
| [29 N4][R29] | FirstPosition traversal; algorithmic analysis and unexecuted adapter specification. | W4-06 |
| [29 D1][R29] | Limit default; native Sign controls executed, no public incorrect expansion alleged. | W4-05 |
| [29 P1][R29] | Gamma-specific formal Newton recurrence; exact independent coefficient comparisons. | W4-16 |
| [29 P2][R29] | Real lower-Lambert solver in a log-excess coordinate; numerical prototype and bracket proof, not an interval certificate. | W4-01 |
| [30 F1][R30] | Observed mutation forgotten after restoration; actual runner fixture and tested narrow latch. | W4-12 |
| [30 F2][R30] | Renamed modular directory loses sibling monitoring; runner fixture and synthetic staging. | W4-12 |
| [30 F3][R30] | Nonprincipal exact-core numerical capability; independent conversion countermodel, public Mathics call unrun. | W4-01 |
| [30 F4][R30] | Dense sparse-coefficient conversion and first-position materialization; source complexity, no kernel benchmark. | W4-06, W4-07 |
| [30 F5][R30] | Limit omitted-direction mismatch; public reachability unconfirmed. | W4-05 |
| [30 F6][R30] | Bounded defining Taylor families and tails; constructive extension with independent exact oracles. | W4-08 |
| [31 N1][R31] | Executable symlink escapes virtual-environment identity; real Python environment witness, not a Mathics run. | W4-11 |
| [31 N2][R31] | Invalid subprocess durations; Python/Linux witnesses and candidate helper tests. | W4-10 |
| [31 N3][R31] | First-match consumer performs all-match traversal; source and counting model. | W4-06 |
| [31 N4][R31] | No diagnostic byte ceiling; bounded POSIX prototype, no package out-of-memory observation. | W4-13 |
| [31 A1][R31] | Limit default audit candidate; no public wrong-result reachability established. | W4-05 |
| [31 A2][R31] | Empty Lookup maps outside private-context protection; caller-list effects unverified. | W4-04 |
| [32 M01][R32] | ProductLog exact/reverse conversion, numerical arity and construction-site coverage; independent bridge countermodels. | W4-01 |
| [32 M02][R32] | Retained parameter assumptions omitted from polynomial-domain helper; exact reference oracles, package path unrun. | W4-03 |
| [32 M03][R32] | Parameter-sensitive positive radii versus fixed-interval truth; exact polynomial reference cases. | W4-03 |
| [32 D-P06][R32] | Dense inner logarithmic-polynomial/Fourier degree; sparse reference, no native benchmark. | W4-07 |
| [32 D-V01][R32] | Source equality at endpoints versus coherent frozen inputs; synthetic change-and-restore countermodel. | W4-12 |
| [32 L01][R32] | Automatic Limit side; inspected branch consumers specify a side. | W4-05 |
| [32 G01][R32] | Finite rank-excess PFQ polynomial; exact oracle, native pre-evaluation caveat. | W4-08 |
| [32 T01][R32] | Nonfinite timeout validation; synthetic helper tests, repository patch not applied. | W4-10 |
| [33 F01][R33] | Symbolic ProductLog argument roles; direct SymPy-stage checks, public core call unrun. | W4-01 |
| [33 F02][R33] | Public empty multi-index maps outside the private sweep; predicted alias/cache effect unrun. | W4-04 |
| [33 F03][R33] | Primitive selected case after failed Get; control-flow analysis, fixture invocation unrun. | W4-09 |
| [33 F04][R33] | Implicit Limit side; no public incorrect expansion established. | W4-05 |
| [33 F05][R33] | FirstPosition collection and symbolic-merge work; independent counting model. | W4-06 |
| [33 A01][R33] | Dense coefficient conversion; public stress path not established. | W4-07 |
| [33 A02][R33] | Interrupted load bypasses context cleanup; static advisory, interruption tests unrun. | W4-17 |
| [34 R1][R34] | ProductLog exact/reverse conversion and numerical arity; independent backend/rational checks, integration unexecuted. | W4-01 |
| [34 R2][R34] | Source-change restoration and unchecked copied suite; actual runner with synthetic processes. | W4-12 |
| [34 R3][R34] | Nonfinite/huge deadlines; original/candidate runner reproduction. | W4-10 |
| [34 R4][R34] | CI path filters omitted a direct builder dependency; repaired in the inspected workflow. | W4-14 |
| [34 R5][R34] | Dense coefficient/amplitude storage and unavailable bounded Position shortcut; structural cost evidence. | W4-06, W4-07 |
| [34 R6][R34] | Limit default; independent mathematical counterexample, public reachability unestablished. | W4-05 |
| [35 N01][R35] | Previously detected mutation forgotten; actual runner and candidate with protocol fixtures. | W4-12 |
| [35 N02][R35] | Nonfinite CLI values and JSON tokens; original/candidate infrastructure observations. | W4-10 |
| [35 N03][R35] | Sparse coefficient/branch paths allocate dense lists; exact reference models, no kernel allocation experiment. | W4-07 |
| [35 N04][R35] | All-match FirstPosition and unsupported obvious bounded overload; source/counting evidence. | W4-06 |
| [35 N05][R35] | Seven trial radii miss arbitrarily small affine neighborhoods; constructive proof, public refusal predicted. | W4-03 |
| [35 N06][R35] | Local Limit default; inspected inverse validator explicitly supplies its direction. | W4-05 |
| [36 N01][R36] | Constructive rational polynomial neighborhood; public witness unexecuted. | W4-03 |
| [36 N02][R36] | Full association-key scans in retained frontier extension; exact cost model, no Mathics timing. | W4-16 |
| [36 N03][R36] | Degree-sized CoefficientRules intermediate; source allocation analysis. | W4-07 |
| [36 N04][R36] | FirstPosition materialization; supplied native query did not establish the proposed semantic distinction. | W4-06 |
| [36 N05][R36] | Declaration/group inventory can omit legal forms; synthetic mutations, no current omitted case claimed. | W4-14 |
| [36 N06][R36] | Nonfinite timeout guard; independent Python reproduction. | W4-10 |
| [36 N07][R36] | Terminating PFQ provider admission; exact identities, integration unexecuted. | W4-08 |
| [36 A01][R36] | AST rewrite match counts/postconditions; preventive proposal, no current failed rewrite reproduced. | W4-15 |

Report 32 is retired: T01's work item is closed, and its other seven entries are
each carried by two or more retained packages. Its rows stay above so the 64-entry
crosswalk remains complete, and its `[R32]` references resolve to the package's
[tombstone](../../external-reports/code-review/wave-4/code-review-32.md).

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

The supplied candidate runner patches have different limits; the merged
repair above already supplies the deadline ceiling and first-mismatch
record. In isolation, a finite-positive guard still accepts enormous finite
deadlines, and a sticky Boolean can discard the first mismatch evidence; `init.m` support that requires a parent
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

## Later integration and peer evidence

The following revisions were inspected from local Git objects, separately
from the `38aa253` working-source audit. The Fourier change was merged in
`9b83d04`; the Mathics acceptance update remains peer evidence at this
intake's final review. Their evidence stays attached to the tested commits.
The intervening documentation change `b145cb9` also clarified the symbolic
ProductLog and achieved-precision boundaries in the maintained guides, as
recorded in W4-01 and W4-02.

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
  representations relevant to W4-07 and the Mathics key/search mechanisms
  relevant to W4-06/W4-16 unchanged. No Mathics feature acceptance or general
  performance improvement follows from those native receipts.

[R28]: ../../external-reports/code-review/wave-4/code-review-28/evidence/novelty-ledger.csv
[R29]: ../../external-reports/code-review/wave-4/code-review-29/results/novelty-ledger.json
[R30]: ../../external-reports/code-review/wave-4/code-review-30/evidence/findings.json
[R31]: ../../external-reports/code-review/wave-4/code-review-31/evidence/novelty_ledger.csv
[R32]: ../../external-reports/code-review/wave-4/code-review-32.md
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

[runner-receipt]: ../../validation/wave4-runner-integrity-tests.json
