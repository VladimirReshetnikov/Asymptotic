# Wave 3: findings, proposals, and implementation scope

This intake contributes to the active [project coverage targets](COVERAGE_TARGETS.md):
complete compatibility with the official Wolfram kernel and Mathics3;
correct and successful handling of every input successfully handled by
`Series`, `Asymptotic`, or `DiscreteAsymptotic`, with a different result
representation permitted; and support for all asymptotics documented in
`vendor/proveit/docs`, including q-analogs, inverses, and combinatorial
sequences. These are required goals, not claims of current completeness.
The [native compatibility plan](NATIVE_COMPATIBILITY.md),
[Mathics compatibility plan](../Mathics/COMPATIBILITY.md), and
[vendored asymptotics register](VENDORED_ASYMPTOTICS.md) track known gaps
and evidence beyond this review wave.

All nine [wave-3 reports](../../external-reports/code-review/wave-3/README.md)
as supplied are included in the current review implementation scope; eight
packages are retained and report 26 is retired, its rows kept below. They add **44
identified ledger entries**: 6, 5, 6, 4, 4, 4, 6, 4, and 5 entries in reports
19 through 27, respectively. Overlapping reports share work items below;
they do not multiply the number of fixes. Unnumbered proposals are recorded
separately. The [main register](CODE_REVIEW_STATUS.md) retains the earlier
123 entries and their implementation history.

Each report reviews commit
[`6687962f3c858a4f93623cfc496f33e35c6763d4`](https://github.com/VladimirReshetnikov/Asymptotic/tree/6687962f3c858a4f93623cfc496f33e35c6763d4).
Their 166 supplied files arrived through `main` revision
`68b8e1e70731998c5bc1533be1bec0f5b507acd7` and were merged in `350c70f`.
The eight retained packages' code, articles, evidence and notices are
preserved unedited; report 26's package was retired after intake and remains in
Git history behind its
[tombstone](../../external-reports/code-review/wave-3/code-review-26.md). Proposed
patches have not been applied wholesale, and their bundled programs have
not been executed as part of intake.

The intake read the nine READMEs, articles, novelty ledgers and relevant
evidence, then compared their mechanisms with production sources at
`350c70f`. **Source inspected** means that the mechanism remains in current
code; it does not mean that a historical public witness was rerun.
Reports 19–20 and 24–27 contain selected native observations, often manually
transcribed from Wolfram 15.0.0 Linux calls. Reports 21–23 have no successful
native package execution. Independent Python models, synthetic patch checks,
separately exercised candidate mechanisms, and complete package acceptance
remain distinct kinds of evidence. The full package suite remains skipped.

## Consolidated work

The `W3-*` identifiers below distinguish these intake items from report-local
IDs such as `N01` and `D01`. Existing register IDs identify related earlier
work without asserting that those earlier fixes settle the new findings.

| Item | Finding and current disposition | Implementation and acceptance obligations |
| --- | --- | --- |
| W3-01 | **Implemented.** An omitted `"Backend"` selector now takes the configured default of `AsymptoticExpansion` (`SetOptions[AsymptoticExpansion, "Backend" -> "Series"]` routes an ordinary request natively); an explicit selector in the call still comes first. Alias ownership is decided: a default configured on `AsymptoticExpand` itself is appended as a trailing selector, so it overrides the primary's default while an explicit call selector wins, and an alias left at `Automatic` inherits the primary's configured default. Internal replays (`SeriesRefine` of forward and inverse-function objects, composite observable re-expansion) select `"Package"` explicitly and never inherit a user-selected native default. Rule-form routing consults the configured `SeriesTermGoal` when no explicit goal is present, so a configured goal keeps `f, x -> 0` on the package engine. Delayed `"MaxTerms"`, `SeriesTermGoal`, `Direction` and `"InverseFunctionBranches"` values are materialized once on the package path instead of at every internal read ([request-resolution cases](../../src/Tests/ReviewRequestResolution.wlt)). Related: B02, D01. | Resolve effective defaults without turning omitted direction, branch, or budget defaults into explicit constraints. Choose and document alias ownership. Preserve first explicit option precedence and once-only delayed evaluation. Compare configured and explicit calls, and insulate internal analytic replay/refinement from a user-selected native default. |
| W3-02 | **Implemented for keys and unknown options; positional-name metadata open.** A rule whose key is a symbol with an own value (`key = "Backend"; f[..., key -> "Series"]`) is a computed argument resolved once on the prepared path, matching a computed container. Symbol spellings of the string-named options (`Backend`, `MaxTerms`, `InverseFunctionBranches`, in any context) are rewritten to the string key without evaluating the value, so every classifier sees one identity. An unknown symbol-keyed rule is a specification only in the rule form and only as the first such rule; after a list specification or a first rule specification it is refused with `Failure["UnknownOption", ...]` instead of silently becoming a native specification (`{x, 0, 3}, Foo -> 1` previously produced a native result that ignored `Foo`). A first positional variable named `Method` is not yet treated specially. Related: B02/B03, D02/D06. | Assign positional roles once; resolve admitted computed keys once, then canonicalize option identity. Preserve rules inside source/option values as data and delayed RHS evaluation. Share the resolved roles across dispatch, forwarding, protection, metadata, and diagnostics. Include variable alpha-renaming, nested containers, duplicate precedence, numerical application, and unknown-option refusals. |
| W3-03 | **Implemented.** `automaticProtectedQ` treats a `Function` as a callable-source contract only when it is the source itself (or the package's own callable marker), so `Root[#^3 - # - 1 &, 1] x + Exp[I x]` and `Function[t, t^2][x] + Exp[I x]`, which previously failed with `InexactInput` because their consumed functions blocked the fallback, now fall back to native `Series` like `Exp[I x]` alone; a pure-function source with a complex value stays protected and refused, and a real one expands on the package engine ([request-resolution cases](../../src/Tests/ReviewRequestResolution.wlt)). Inverse, conditional and retained-object contracts remain protected wherever they occur. Related: B01/B02. | Distinguish actual callable syntax from ordinary expressions containing or consuming a function. Compare plain/applied sources and preserve genuine callable, inverse, condition, direction, budget, and remainder contracts. Establish the reported `Root` witness independently. |
| W3-04 | **Measured at fixed support; demand-driven views remain a design choice.** Native construction eagerly stores `Normal[result]`. The [provenance growth note](PROVENANCE_GROWTH.md) measured `1/(1 - x^7)` through native order 56: the stored finite expression grows by one term per nonzero coefficient (144 to 704 bytes) beside a dense `SeriesData` of 384 to 1,560 bytes inside a 5–7 kB object, so `Normal` of a sparse native series does not densify fixed-support output and the object is dominated by fixed metadata. Related: B03, P07/P08; distinct from C01/C17 optional native export. | Preserve raw native payloads; design demand-driven finite-expression access consistently for `Normal`, `"Expression"`, display and numerical application. Specify evaluation timing and restored-object behavior. Measure fixed-support sparse growth and construction/first/repeated access separately; byte counts are not peak memory or a speedup proof. |
| W3-05 | **Partly addressed before intake.** Current `nativeEvaluationStatus` already recognizes nested `$Failed`, `Failure` and `$Aborted`. The broader diagnostic proposal remains open: held native syntax can be mistaken for active unresolved work, and partial/nonfinite outcomes need deliberate policy. Related: B03, D02. | Preserve failure/abort controls and search stopping. Characterize held bodies without releasing them; retain raw output and side-effect counts. Distinguish structural unresolved syntax, evaluation outcome and analytic evidence. Do not classify `Infinity` alone as failure. |
| W3-06 | **Focused verified — 131/0 across six selected files, including 29 new cases.** Native probes reproduce insufficient Taylor information, the lost `FractionalPart[1-x]` constant, uncertainty at a jump, and a complex inner path whose final coefficients are real. The [observable notes](OBSERVABLE_INGRESS.md) separate the original baseline, intermediate complex-path receipt and merged-source acceptance. Related: C06/C13/C16. | The repair validates returned chart, regular lattice and exclusive endpoint; preserves a proved sided constant or requires two-sided/point compatibility; and proves complete inner-argument reality before using a real-sided bound. Tests cover truthful short providers, endpoint equality, logarithmic boundary degrees, discarded imaginary inputs and domain controls. General opaque-source regularity remains C16. |
| W3-07 | **Implemented — zero-demand path for exact derived values.** `SeriesRefine` of a derived result with remainder `0` at or above its cutoff returns the value with the new cutoff, `"Strategy" -> "ExactDerivedValue"` and zero coefficient evaluations, preserving assumptions, domains and history; `SeriesMultiply[inv, 0]` refined to 10 no longer fails with `InsufficientInputOrder` from its uncertain ancestor. A lower request keeps the documented retargeting path. Related: C08, P07/P08, D10. | Add a validated zero-demand path for exact derived values. Preserve domains, assumptions, prefactors and statistics; reject invalid budgets. Do not silently change lower-cutoff retargeting or uncertain-result refinement. |
| W3-08 | **Focused verified — 99/0 native checks.** Model admission precedes inverse-only field access, with message-free `UnsupportedCoefficientModel` refusals for unsupported objects and incomplete models. [Baseline, controls, and first-pass corrections](INVERSE_COEFFICIENT_MODELS.md). Related: C11, D02; distinct from C09. | Ordinary coefficients, empty multi-indices, negative leading powers at infinity, stored assumptions, symbolic depth, and native/logarithmic refusal tags are preserved. This is capability admission, not mathematical recertification of arbitrary associations. Mathics empty-list behavior remains W4-04; C09 option precedence is unchanged. |
| W3-09 | **Open policy/coverage item.** Original `ConditionalExpression` syntax unconditionally preserves the package path, excluding some native-supported conditioned complex expressions. Related: B01–B03, C07. | Decide and implement a route for ordinary conditioned native expressions that preserves the complete condition, assumptions and evaluation counts. It must not grant an analytic package remainder or discard explicit package-only constraints. Keep true callable/inverse/remainder objects distinct. |
| W3-10 | **Focused verified — 207/0 across eight selected files, including 21 new cases.** Recursive positive-monomial logarithm normalization requires positive constant factors and proved-real exponents at every nested power, including reciprocal coordinates. An unproved inner or outer branch leaves the complete logarithm unnormalized. The [13-observation baseline](../../validation/log-power-normalization-baseline.json) reproduces false public depth and flat-coefficient formulas under `a^2 == -1`; the [initial after-guard probes](../../validation/log-power-normalization-after-guard.json) record structured refusals with unchanged real controls. See [log-power normalization](LOG_POWER_NORMALIZATION.md). Related: C07/C16, X09. | The [first focused pass](../../validation/log-power-normalization-first-pass.json) preserves 201 successes and 2 failures: an unsupported valid reciprocal-coordinate case and a stale Automatic-refusal fixture. The [completed second pass](../../validation/log-power-normalization-tests.json) covers the recursive repair and corrected Package/native controls with 65 recorded source hashes and unchanged sources. The exact-core baseline demonstrates unsupported model admission, not the same changed finite expression. A periodic coefficient constructor remains a separate open proposal. |
| W3-11 | **Addressed — conservative token gate.** The standalone builder now flags any spelling of a loading or file primitive in executable text — bracket call, prefix `@` or postfix `//` application, `@@`, `/@`, `Map`/`Scan` arguments, a qualified `System`` name or the bare symbol — while identifiers merely containing those names (`GetValue`, `ReadListing`) and masked strings and comments stay inert; the [builder tests](../../validation/test_standalone.py) cover these spellings and the unrelated identifiers. This is a packaging check, not a security or arbitrary-I/O proof. Related: V02 and distribution validation. | The gate ran on the current sources when the standalone distribution was rebuilt. |
| W3-12 | **Implemented — proved branch selection.** When the real solver returns several branches for a scale coordinate such as `w = x^-2`, the coordinate rule keeps the one branch the retained domain proves for small positive `w` (`x -> w^(-1/2)` under `x > 0`, `-w^(-1/2)` under `x < 0`) and still fails without a proved sign. The Lerch product `SeriesMultiply[s, x]` now stays a power-log series in `x^-2` with powers `{3/2, 5/2, 7/2}` and remainder `9/2`, `SeriesMultiply[s, 1/x]` gives `{5/2, 7/2, 9/2}` with `11/2`, and refinement replays the product to `13/2`; an exponential-scale operand keeps the composite fallback ([scale-coordinate cases](../../src/Tests/ReviewScaleCoordinateBranches.wlt)). Related: X02, D01/D02, adjacent to C18. | Select only a proved unique chart branch and transport powers/remainders through it. Cover positive/negative/unknown source signs and scaled charts. Reproduce the Lerch product's expected powers `{3/2,5/2,7/2}` and remainder `9/2` in `w=x^-2`, then check later refinement. |
| W3-13 | **Focused verified — 68/0 across four selected files, including 19 new cases.** The [17-observation baseline](../../validation/fourier-termination-baseline.json) reproduces unused-product resource failures in the separate Fourier P03 path, including a public residual with budget seven. The [after-fix probes](../../validation/fourier-termination-after-fix.json) record `{True, {}, 6}` for that residual's zero flag, blocks and relative cutoff, and preserve genuine resource/nontermination controls. See [Fourier termination](FOURIER_TERMINATION.md). | Support exhaustion and complete homogeneous-coefficient annihilation are checked before the next product. The [68/0 acceptance](../../validation/fourier-termination-tests.json) records 61 stable input hashes and covers nonpositive-valuation admission, necessary pair/frequency limits, logarithmic amplitudes and nonzero modes. Separate loading checks pass 105/0 in five fresh kernels. No end-to-end speedup or stronger remainder is inferred. |
| W3-14 | **Decided — documented truncation.** `SeriesDifferentiate[s, 0, "Cutoff" -> h]` now returns `SeriesTruncate[s, h]` instead of ignoring the cutoff, so the zeroth derivative without a cutoff is still the object itself while a supplied cutoff is honoured with the ordinary cutoff validation; pinned in [SeriesOperations.wlt](../../src/Tests/SeriesOperations.wlt) (`zeroth-derivative-with-a-cutoff-truncates-instead-of-ignoring-it`). Related: D01/D10. | Zero-order identity without a cutoff, budget and native-contract validation are preserved; an inexact cutoff is refused as elsewhere. |
| W3-15 | **Measured — no quadratic growth observed; single-pass classification still a design lane.** On Wolfram 15.0.1, `AsymptoticExpansion[Exp[x], {x, 0, 3}, opts]` with the option container nested 0, 8, 32 and 64 levels deep takes about 21, 22, 39 and 78 ms per call (three-call averages), a linear cost of roughly one millisecond per nesting level, and 200 repeated `"MaxTerms"` rules add about 5 ms; the traversal is not quadratic at these depths. Related: P06/P08. | Integrate a single request-local classification pass with W3-02. Count traversal at increasing depths and preserve data-list/side-effect controls. Avoid a global memoization cache. |
| W3-16 | **Documentation corrected in this intake checkpoint.** The root README's final status paragraph contradicted its introduction and the implemented automatic routing. Related: B01/B02, D01. | Keep current routing descriptions consistent, distinguish Package from Automatic, update all three wave indexes, and link evidence with its actual scope. Historical explicit-native counts remain historical. |

The adjacent explicit scalar rule-goal repair has a
[116/0 focused record](../../validation/native-rule-goal-tests.json), including
15 new cases. It admits explicit `Automatic` and nonpositive integer native
goals while preserving already-consumed common options and explicit package
constraints. W3-01's configured-default and alias cases and W3-02's
equivalent-key cases were closed later by the request-resolution change;
**W3-09's conditional-source policy stays open.**

## Complete wave-3 finding crosswalk

| Report and count | Every ledger entry → consolidated item |
| --- | --- |
| [19](../../external-reports/code-review/wave-3/code-review-19/README.md) — 6 | N01 → W3-01; N02, N03 → W3-02; N04 → W3-04; N05 → W3-05; D01-local → W3-16. |
| [20](../../external-reports/code-review/wave-3/code-review-20/README.md) — 5 | N01 → W3-01; N02 → W3-02; N03 → W3-03; N04 → W3-04; N05 → W3-16. |
| [21](../../external-reports/code-review/wave-3/code-review-21/README.md) — 6 | N01 → W3-01; N02 → W3-03; N03 → W3-02; AUDIT-D01 (article D01) → W3-06; AUDIT-D02 (article D02) → W3-07; N04 → W3-16. |
| [22](../../external-reports/code-review/wave-3/code-review-22/README.md) — 4 | T01 → W3-06; A01 → W3-08; N01 → W3-09; U01 → W3-05. |
| [23](../../external-reports/code-review/wave-3/code-review-23/README.md) — 4 | N01 → W3-10; N02 → W3-01; N03 → W3-11; N04 → W3-05. |
| [24](../../external-reports/code-review/wave-3/code-review-24/README.md) — 4 | N01 → W3-01; N02 → W3-02; N03 → W3-12; F01 → W3-13. |
| [25](../../external-reports/code-review/wave-3/code-review-25/README.md) — 6 | N01, N02 → W3-06; N03 → W3-01; N04 → W3-14; N05 → W3-02; N06 → W3-04. |
| [26](../../external-reports/code-review/wave-3/code-review-26.md) — 4, package retired | N1 → W3-01; N2, N3 → W3-02; P-N1 → W3-04. Every entry is also carried by a retained report, so nothing here is lost. |
| [27](../../external-reports/code-review/wave-3/code-review-27/README.md) — 5 | N01 → W3-01; N02 → W3-02; N03 → W3-03; N04 → W3-15; N05 → W3-16. |

## Proposals and implementation decisions

These proposals are included for evaluation and implementation where their
contracts can be established. They are not discarded because a narrow patch
already passes, nor presented as accepted native or mathematical behavior.
Implementation and API choices remain open, but coverage required by the
three project goals is not optional. In particular, the current absence of a
`DiscreteAsymptotic` backend and incomplete Mathics and vendored-corpus
coverage remain obligations even where no wave-3 finding names them.

| Proposal | Sources, decision and validation boundary |
| --- | --- |
| One resolved request shared by routing, forwarding, metadata and diagnostics | Reports 19–21 and 24–27; W3-01/W3-02/W3-15. Retain original held syntax, positional role, effective value, explicit/default origin and consumption state; evaluate the proposed explanation facility from that record. Resolve computed keys separately from name equivalence; a rule inside data is not an option. |
| Alias/default ownership | Reports 20 and 26 proposed policies beyond the primary-only repairs in 19/21/25/27; report 26 is retired and report 20 remains. Independent alias defaults and alias-overrides-primary inheritance are distinct alternatives, and both are retained here as options. Choose a coherent policy and test internal analytic replay rather than combining incompatible patch fragments. |
| Shared native coefficient-provider admission | Reports 21/22/25; W3-06, C06/C16. Track chart, lattice, coefficient independence, endpoint, exact termination and regularity separately. The regular Taylor endpoint `q >= Ceiling[c/alpha]` supports indices below that bound; equality can suffice. A continuity screen or `Analytic -> False` alone does not prove a Taylor remainder. |
| Demand-driven native expression views | Reports 19/20/25/26; W3-04. Specify first/repeated evaluation and serialization before adding caching; measure growth independently of analytic-to-native export. |
| Orthogonal native outcome metadata | Reports 19/22/23; W3-05. Distinguish actual failures, held residual syntax and legitimate nonfinite results without promoting a syntactically computed output to an analytic theorem. |
| Differential behavior catalog and reducer | Report 20 and the metamorphic sections across wave 3; B04. Include alpha-renaming, option spellings, positional forms and controlled expression transformations; keep independent irrational inverse-coefficient oracles alongside native comparisons. |
| Exact derived-value demand planning | Report 21; W3-07, C08/P08. Implemented: exact derived values refine with zero ancestor demand, and replay propagates observed shortfalls with truthful `"ReplayRounds"`/`"AchievedCutoff"` statistics; the lower-cutoff policy is unchanged. |
| Minimal observable Taylor requests | Report 22; P08 after W3-06. Request only the degree mathematically consumed, then measure the benefit while retaining sufficient returned-order checks. |
| Periodic Lipschitz coefficient constructor | **Open proposal.** Report 23; X02/X05 after W3-10. The [normalization notes](LOG_POWER_NORMALIZATION.md#constructive-periodic-extension-remains-separate) distinguish the valid cubic inverse approximation from an implemented constructor. State realness, boundedness, frequency and derivative/remainder assumptions before extending beyond branch-safe refusal. |
| Signed monomial charts and regrading | Report 24; W3-12, X02/D01. Use explicit branch information and proved coordinate inversion; transport the remainder as well as the finite terms. |

Repeated CI, result-schema and benchmark proposals remain mapped to V01,
D02 and P08. Fourier work-count profiling belongs to W3-13/P03. The proposed
full-suite release gate does not override the instruction to skip that suite
during this task.

W3-06's observable information, side and real-input guards are focused
verified. W3-10's logarithm identity guards are implemented and characterized
before and after the change, with 207/0 focused acceptance across eight files.
Request-resolution work
W3-01–W3-03 should follow one consistent option/default policy. The remaining
capability, packaging, exact-demand and resource items retain their separate
focused acceptance obligations. Update this intake and the main register
when a current-source reproduction, implementation decision or accepted fix
changes an item's status. Carry any remaining native, Mathics, or vendored
coverage gap into its maintained plan; completing this intake alone does
not complete the project coverage goals.
