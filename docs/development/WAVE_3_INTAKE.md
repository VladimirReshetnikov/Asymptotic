# Wave 3: findings, proposals, and implementation scope

All nine [wave-3 reports](../../external-reports/code-review/wave-3/README.md)
are included in the current review implementation scope. They add **44
identified ledger entries**: 6, 5, 6, 4, 4, 4, 6, 4, and 5 entries in reports
19 through 27, respectively. Overlapping reports share work items below;
they do not multiply the number of fixes. Unnumbered proposals are recorded
separately. The [main register](CODE_REVIEW_STATUS.md) retains the earlier
123 entries and their implementation history.

Each report reviews commit
[`6687962f3c858a4f93623cfc496f33e35c6763d4`](https://github.com/VladimirReshetnikov/Asymptotic/tree/6687962f3c858a4f93623cfc496f33e35c6763d4).
Their 166 supplied files arrived through `main` revision
`68b8e1e70731998c5bc1533be1bec0f5b507acd7` and were merged in `350c70f`.
The supplied code, articles, evidence, and notices are preserved. Proposed
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
| W3-01 | **Pending — source inspected.** Omitted backend selection hardcodes `Automatic`; configured canonical and alias defaults are not honored. Rule-form routing also checks the syntactic presence of a term goal before reading its configured value. Related: B02, D01. | Resolve effective defaults without turning omitted direction, branch, or budget defaults into explicit constraints. Choose and document alias ownership. Preserve first explicit option precedence and once-only delayed evaluation. Compare configured and explicit calls, and insulate internal analytic replay/refinement from a user-selected native default. |
| W3-02 | **Pending — source inspected.** Computed keys, equivalent symbol/string/context option names, and positional variable names are classified inconsistently. Unknown symbolic suffix options can escape validation; a first positional variable named `Method` can lose metadata. Related: B02/B03, D02/D06. | Assign positional roles once; resolve admitted computed keys once, then canonicalize option identity. Preserve rules inside source/option values as data and delayed RHS evaluation. Share the resolved roles across dispatch, forwarding, protection, metadata, and diagnostics. Include variable alpha-renaming, nested containers, duplicate precedence, numerical application, and unknown-option refusals. |
| W3-03 | **Pending — source inspected.** A recursive `Function` search mistakes applied identities and internal algebraic-root encodings for callable-source contracts. Related: B01/B02. | Distinguish actual callable syntax from ordinary expressions containing or consuming a function. Compare plain/applied sources and preserve genuine callable, inverse, condition, direction, budget, and remainder contracts. Establish the reported `Root` witness independently. |
| W3-04 | **Pending — source inspected; historical storage measurements.** Native construction eagerly stores `Normal[result]`, potentially densifying sparse output before the user asks for it. Related: B03, P07/P08; distinct from C01/C17 optional native export. | Preserve raw native payloads; design demand-driven finite-expression access consistently for `Normal`, `"Expression"`, display and numerical application. Specify evaluation timing and restored-object behavior. Measure fixed-support sparse growth and construction/first/repeated access separately; byte counts are not peak memory or a speedup proof. |
| W3-05 | **Partly addressed before intake.** Current `nativeEvaluationStatus` already recognizes nested `$Failed`, `Failure` and `$Aborted`. The broader diagnostic proposal remains open: held native syntax can be mistaken for active unresolved work, and partial/nonfinite outcomes need deliberate policy. Related: B03, D02. | Preserve failure/abort controls and search stopping. Characterize held bodies without releasing them; retain raw output and side-effect counts. Distinguish structural unresolved syntax, evaluation outcome and analytic evidence. Do not classify `Infinity` alone as failure. |
| W3-06 | **Implemented; focused acceptance pending.** Native probes reproduce insufficient Taylor information, the lost `FractionalPart[1-x]` constant, uncertainty at a jump, and a complex inner path whose final coefficients are real. The [observable notes](OBSERVABLE_INGRESS.md) separate the original baseline from the intermediate complex-path receipt. Related: C06/C13/C16. | Validate the returned chart, regular lattice and exclusive endpoint; preserve the proved sided constant or require two-sided/point compatibility; prove reality of the complete inner argument before using a real-sided bound. Focused cases include truthful short providers, exact endpoint equality, logarithmic boundary degrees, discarded imaginary inputs and domain controls. General opaque-source regularity remains C16. |
| W3-07 | **Pending — source inspected.** Refining an exact derived constant can demand unavailable coefficients from an uncertain ancestor. Related: C08, P07/P08, D10. | Add a validated zero-demand path for exact derived values. Preserve domains, assumptions, prefactors and statistics; reject invalid budgets. Do not silently change lower-cutoff retargeting or uncertain-result refinement. |
| W3-08 | **Pending — source inspected.** `InverseExpansionCoefficient` accepts a valid forward object far enough to read absent inverse-only metadata. Related: C11, D02; distinct from C09. | Validate the object capability/model before field access and return a message-free structured refusal for unsupported kinds. Preserve ordinary inverse coefficient and option controls. |
| W3-09 | **Open policy/coverage item.** Original `ConditionalExpression` syntax unconditionally preserves the package path, excluding some native-supported conditioned complex expressions. Related: B01–B03, C07. | Decide and implement a route for ordinary conditioned native expressions that preserves the complete condition, assumptions and evaluation counts. It must not grant an analytic package remainder or discard explicit package-only constraints. Keep true callable/inverse/remainder objects distinct. |
| W3-10 | **Pending — source inspected; public witness unrun.** Symbolic inverse parsing rewrites `Log[u^k]` and `Log[c u^k]` without proving `k` real. This can turn a bounded periodic amplitude into a false polynomial in `Log[u]`. Related: C07/C16, X09. | Require the real-exponent hypothesis for both identities. Probe the parser, model constructor and public depth route separately, including `a^2 == -1`, proved-real/unproved-real exponents and positive scaled bases. Preserve branch-safe refusals before adding a new periodic coefficient algebra. |
| W3-11 | **Pending — source inspected.** The standalone dependency gate recognizes bracket calls but can miss prefix, postfix or `Apply` spellings under future source changes. No hidden dependency in the current artifact is alleged. Related: V02 and distribution validation. | Exercise the actual builder with bounded temporary fixtures for these spellings, qualified names, inert strings/comments and unrelated identifiers. A conservative dependency-token gate is a packaging check, not a security or arbitrary-I/O proof. |
| W3-12 | **Pending closure improvement.** Signed quadratic/monomial coordinates are solved without using retained branch assumptions, producing a valid but unnecessarily general Composite result. Related: X02, D01/D02, adjacent to C18. | Select only a proved unique chart branch and transport powers/remainders through it. Cover positive/negative/unknown source signs and scaled charts. Reproduce the Lerch product's expected powers `{3/2,5/2,7/2}` and remainder `9/2` in `w=x^-2`, then check later refinement. |
| W3-13 | **Pending — source inspected.** Fourier homogeneous composition spends the next product budget before detecting a vanishing next coefficient. This is a separate P03 implementation path. | Reproduce the budget-three helper witness; check the next weight and homogeneous coefficient before multiplication. Preserve support-exhaustion, assumption-dependent-zero, nonzero-frequency and nonterminating controls. |
| W3-14 | **API consistency decision.** Zeroth differentiation returns the original object even when a cutoff is supplied. The zeroth derivative itself is mathematically correct. Related: D01/D10. | Choose documented truncation or explicit refusal for the conflicting request. Preserve zero-order identity without a cutoff and normal budget/native-contract validation. The report did not establish a zero-budget bypass. |
| W3-15 | **Pending — source inspected.** Nested option trees are repeatedly revalidated during recursive selector scans, producing avoidable quadratic traversal. Related: P06/P08. | Integrate a single request-local classification pass with W3-02. Count traversal at increasing depths and preserve data-list/side-effect controls. Avoid a global memoization cache. |
| W3-16 | **Documentation corrected in this intake checkpoint.** The root README's final status paragraph contradicted its introduction and the implemented automatic routing. Related: B01/B02, D01. | Keep current routing descriptions consistent, distinguish Package from Automatic, update all three wave indexes, and link evidence with its actual scope. Historical explicit-native counts remain historical. |

The adjacent explicit scalar rule-goal repair has a
[116/0 focused record](../../validation/native-rule-goal-tests.json), including
15 new cases. It admits explicit `Automatic` and nonpositive integer native
goals while preserving already-consumed common options and explicit package
constraints. **It does not close W3-01's configured-default or alias cases,
W3-02's equivalent-key cases, or W3-09's conditional-source policy.**

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
| [26](../../external-reports/code-review/wave-3/code-review-26/README.md) — 4 | N1 → W3-01; N2, N3 → W3-02; P-N1 → W3-04. |
| [27](../../external-reports/code-review/wave-3/code-review-27/README.md) — 5 | N01 → W3-01; N02 → W3-02; N03 → W3-03; N04 → W3-15; N05 → W3-16. |

## Proposals and implementation decisions

These proposals are included for evaluation and implementation where their
contracts can be established. They are not discarded because a narrow patch
already passes, nor presented as accepted native or mathematical behavior.

| Proposal | Sources, decision and validation boundary |
| --- | --- |
| One resolved request shared by routing, forwarding, metadata and diagnostics | Reports 19–21 and 24–27; W3-01/W3-02/W3-15. Retain original held syntax, positional role, effective value, explicit/default origin and consumption state; evaluate the proposed explanation facility from that record. Resolve computed keys separately from name equivalence; a rule inside data is not an option. |
| Alias/default ownership | Reports 20 and 26 propose policies beyond the primary-only repairs in 19/21/25/27. Independent alias defaults and alias-overrides-primary inheritance are distinct alternatives. Choose a coherent policy and test internal analytic replay rather than combining incompatible patch fragments. |
| Shared native coefficient-provider admission | Reports 21/22/25; W3-06, C06/C16. Track chart, lattice, coefficient independence, endpoint, exact termination and regularity separately. The regular Taylor endpoint `q >= Ceiling[c/alpha]` supports indices below that bound; equality can suffice. A continuity screen or `Analytic -> False` alone does not prove a Taylor remainder. |
| Demand-driven native expression views | Reports 19/20/25/26; W3-04. Specify first/repeated evaluation and serialization before adding caching; measure growth independently of analytic-to-native export. |
| Orthogonal native outcome metadata | Reports 19/22/23; W3-05. Distinguish actual failures, held residual syntax and legitimate nonfinite results without promoting a syntactically computed output to an analytic theorem. |
| Differential behavior catalog and reducer | Report 20 and the metamorphic sections across wave 3; B04. Include alpha-renaming, option spellings, positional forms and controlled expression transformations; keep independent irrational inverse-coefficient oracles alongside native comparisons. |
| Exact derived-value demand planning | Report 21; W3-07, C08/P08. Exact constants have zero ancestor coefficient demand. Preserve truthful statistics and lower-cutoff policy. |
| Minimal observable Taylor requests | Report 22; P08 after W3-06. Request only the degree mathematically consumed, then measure the benefit while retaining sufficient returned-order checks. |
| Periodic Lipschitz coefficient constructor | Report 23; X02/X05 after W3-10. State realness, boundedness, frequency and derivative/remainder assumptions, including the proposed cubic majorant, before extending beyond branch-safe refusal. |
| Signed monomial charts and regrading | Report 24; W3-12, X02/D01. Use explicit branch information and proved coordinate inversion; transport the remainder as well as the finite terms. |

Repeated CI, result-schema and benchmark proposals remain mapped to V01,
D02 and P08. Fourier work-count profiling belongs to W3-13/P03. The proposed
full-suite release gate does not override the instruction to skip that suite
during this task.

Immediate correctness priorities are W3-06's observable information/side
checks and W3-10's logarithm identity hypotheses. Request-resolution work
W3-01–W3-03 should follow one consistent option/default policy. The remaining
capability, packaging, exact-demand and resource items retain their separate
focused acceptance obligations. Update this intake and the main register
when a current-source reproduction, implementation decision or accepted fix
changes an item's status.
