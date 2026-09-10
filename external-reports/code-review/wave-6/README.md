# Code review reports: wave 6

These ten retained incremental review packages, numbered 46–55, examine
AsymptoticAnalysis after the wave-5 retirements. All are dated September 10,
2026 and all pin one snapshot,
[8cee870](https://github.com/VladimirReshetnikov/Asymptotic/tree/8cee870994f506b501bae3ea6bd4a3a7edb895c1),
the commit that left a tombstone where each retired package stood. Nothing under
`src/` changed between that snapshot and the current HEAD, so every mechanism
below is present at the cited lines today. Each novelty ledger states how far its
author screened against the earlier waves and the register; none could screen
against its own wave, which was produced in parallel.

**No package was retired from this wave.** Five defects are reported two or three
times and one extension proposal twice, but in every case each copy carries a
witness, a proof, an executed check or a *different proposed repair* that the
others do not — and in five of the six overlaps the members propose
non-interchangeable repairs at the same line. The overlap table records those
obligations once; it removes no package. The
[retirement rule](../README.md#retired-review-packages) also cannot reach this
wave yet: with no intake, no entry is implemented or settled, so "restated by a
retained package" is the only available ground, and it fails for at least one
entry in all ten packages.

This wave has **no consolidated intake**. Its entries are not part of the 231
attributed entries counted for waves 1–4, and none is mapped to a `C*`, `P*`,
`D*`, `V*`, `X*`, `W3-*` or `W4-*` work item. Four witnesses — and only those
four — were reproduced on the pinned source in the
[wave-6 characterization](../../../validation/wave6-witness-probe.json), which is
a probe, not an acceptance suite, and which records the behaviour before any
repair. The [implementation status](#implementation-status) below says which
entries have since been repaired with focused evidence; the rows themselves
describe what each package supplied.

| Package | Article | Retained findings | Supplied evidence and limits |
| --- | --- | --- | --- |
| [46 · Incremental audit](code-review-46/README.md) | [PDF](code-review-46/article/review.pdf) · [TeX](code-review-46/article/review.tex) | N01 a target-dependent `"SourceShift"` is admitted, cancels out of every displayed coefficient and survives only in the remainder scale, so the reported bound is false rather than weak. Six unnumbered advisories, including a usage/message text that calls `CoreInverse` and `SourceShift` alike "source-independent", a chart-parameter postcondition, and a three-expectation rule for any regression, since a fixed shift legitimately multiplies the scale by a constant. | Two transcribed Wolfram 15.0.0 Linux groups — an unpatched baseline and a temporarily patched copy of the downloaded standalone ([observations](code-review-46/evidence/native_observations.json)); [20 Python methods](code-review-46/evidence/independent_tests.json); four 90-digit [samples](code-review-46/evidence/numerical_samples.csv). No Mathics run; the 12-case `ReviewSourceShift.wlt`, the portable smoke and `ProbeSourceShift.wl` are unrun; no suite and no benchmark. |
| [47 · Incremental technical audit](code-review-47/README.md) | [PDF](code-review-47/article/asymptotic_incremental_audit.pdf) · [TeX](code-review-47/article/asymptotic_incremental_audit.tex) | N01 the mutually recursive Mathics realness/sign provers re-derive the same subquery along several branches; N02 the documentation checker's bare `assert` gates are removed by `python -O` while its record hardcodes zero missing references; N03 the checker scans unfiltered TeX, so a commented command manufactures a definition or a false rejection. | Wolfram 15.0.0 with helper bodies instrumented by `DownValues` rewriting: entry counts 1, 8, 29, 92, 281, 848, 2549 for depths 0–6 ([observations](code-review-47/evidence/wolfram-observations.md)); [19 Python methods](code-review-47/evidence/python-tests.txt) running the unmodified repository file under normal and `-O`; five two-pass `pdflatex` builds. No Mathics run; every cost figure beyond depth 6 is a Python grammar model counting body evaluations, **not elapsed time**; the documentation command was never run against its live dependencies. |
| [48 · Differential audit](code-review-48/README.md) | [PDF](code-review-48/article/asymptotic-differential-audit.pdf) · [TeX](code-review-48/article/asymptotic-differential-audit.tex) | N1 the coefficient overload selects an explicit power by name-equivalent `FilterRules` but extracts it by literal string replacement, so a symbol-spelled option returns a **successful** association with a string inside its arithmetic; N2 an exact rational below the double underflow threshold makes the Mathics logarithm-split guard false, losing a valid recovery; N3 the `"LocalCoordinate"` sentence describes two fields with different units; P1 the flat-tail collector materializes a quadratic candidate population before selecting the least grade. | One Wolfram 15.0.0 Linux kernel with the pinned standalone: five option spellings, two `InverseNumericalCheck` witnesses, a `FilterRules` control and a 45-case comparison matrix, then two patched-copy runs ([observations](code-review-48/evidence/native-observations.json)); [39 Python methods](code-review-48/evidence/independent-results.json) plus one executed host primitive, `float(Rational(1, 10**M))`, locating the threshold between `10^-323` and `10^-324`. No Mathics in any form, so N2 is source-predicted by construction; the emitter was never run against a real checkout. |
| [49 · Incremental contract audit](code-review-49/README.md) | [PDF](code-review-49/article.pdf) · [TeX](code-review-49/article.tex) | N1 the Mathics protector reaches only membership predicates below an `Assumptions` rule value, so a live predicate carried in an inline source `ConditionalExpression` is never protected — the **opposite** gap from 51 N01 and 54 N02; E1 a signed mean–variance enclosure for the Lerch remainder; E2 an all-orders derivative contract for the Zeta Dirichlet tail with an explicit finite constant. | Exactly one command: [seven unittest methods](code-review-49/evidence/python_test_log.txt), standard library only, exact `Fraction`, including a 576-case containment grid checked against an independently bounded partial sum. Neither Wolfram nor Mathics was available; `LerchEnclosure.wl`, the 108-case `ReferenceWL.wl` and the probes are unrun, and the article states it contains **no claimed result** for the N1 witness. |
| [50 · Fixed charts, exact cores, rational moments](code-review-50/README.md) | [PDF](code-review-50/article/article.pdf) · [TeX](code-review-50/article/article.tex) | F1 the same `SourceShift` defect as 46, with an all-depths theorem, the coefficient-cancellation identity, a converse bound for genuine fixed shifts and a **different repair** carrying a dedicated `"TargetDependentSourceShift"` tag; E1 grouping a fixed constant as a perturbation costs exactness, with an opt-in absorption prototype; E2 an exact-rational Eulerian moment table for the existing Lerch expansion. | [32 Python methods](code-review-50/evidence/independent-results.json) at 100 decimal digits; a lexical scan of its own WL files; a `pdflatex` build. No repository checkout was obtained, Wolfram service calls failed and Mathics was unavailable, so **F1's public witness is source-predicted**, as the README, scope record, findings file and the article all state. The desired-contract tests and prototypes are unrun. |
| [51 · Request preservation and portable evidence](code-review-51/README.md) | [PDF](code-review-51/article.pdf) · [TeX](code-review-51/article.tex) | N01 the Mathics protector rewrites an `Element` symbol a caller holds as data, changing which branch a delayed `Assumptions` program selects and therefore which public coefficient is returned; N02 the `"LocalCoordinate"` label; N03 the documentation link checker resolves a local target and only asks whether it exists, so a link escaping the checkout passes whenever the outside file happens to exist. | Six transcribed [Wolfram 15.0.0 observations](code-review-51/evidence/native-observations.json), including a before/after `{1, 2}` on a public model coefficient obtained by loading the actual pinned adapter into the private context, and two public checker calls at `WorkingPrecision -> 30`; [23 Python methods](code-review-51/evidence/python-tests.txt) with real Pandoc and a byte-identical upstream fixture. **No Mathics run at all**: the Mathics-only adapter was deliberately force-loaded into a Wolfram kernel, so this is an adapter isolation, not a Mathics execution. |
| [52 · Three public-boundary defects](code-review-52/README.md) | [PDF](code-review-52/article.pdf) · [TeX](code-review-52/article.tex) | N1 a numeric named constant such as `Pi` is admitted as an expansion or target coordinate, where native `Series` refuses; N2 `FourierInverseResidual`'s unrestricted optional positional cutoff sits in front of `OptionsPattern[]`, so a documented option binds to the cutoff and is rejected; N3 `SeriesObservable` tests its exact fast paths before peeling an outer `ConditionalExpression`, so a proved condition diverts an exact carrier to a route that refuses it. | Wolfram 15.0.0 Linux, fresh kernel per batch, with executed negative controls and a delayed-option evaluation counter ([observations](code-review-52/evidence/native_observations.json)). No Mathics; no suite; candidate edits were injected into temporary standalone copies. **Its 42-case arithmetic screen carries no evidential weight**: `code/run_controls.wl` divides by `"RemainderScaleExpression"`, which [ResultReference](../../../src/Documentation/ResultReference.md) records as absent from an ordinary forward object, so the numeric guard is unreachable and the reported zero flags are vacuous. |
| [53 · Range-aware certificates](code-review-53/README.md) | [PDF](code-review-53/article/article.pdf) · [TeX](code-review-53/article/article.tex) | N01 binary exponentiation multiplies a zero-crossing base against later squared bases as independent factors, so an odd power keeps the wrong lower endpoint and a strictly positive derivative enclosure can contain zero; N02 the general `Power` branch has no rational-exponent case, so an admitted algebraic root inherits the exponential magnitude budget; N03 the driver doubles `EnclosureOrder` after a failure whose cause is precision-independent, then labels the terminal failure budget exhaustion. | [22 Python methods](code-review-53/evidence/python-tests.txt) over an independent exact-`Fraction` transcription — 3,036 admissible intervals, 7,800 integer-root and 800 rational-root cases — plus 360 mpmath controls at 120 digits. **Nothing was executed in Wolfram or Mathics**, so every public result is a source prediction. Its own N01 candidate cannot be loaded: `code/CandidateCertificatePowers.wl` has one unclosed bracket, so the README's installation recipe fails. The endpoint rule itself is unaffected. |
| [54 · Interval geometry and Mathics rewrite contracts](code-review-54/README.md) | [PDF](code-review-54/article.pdf) · [TeX](code-review-54/article.tex) | N01 the same odd-power loss as 53, with the exact returned interval proved for all odd powers and a witness where an exactly-zero residual is refused at an exact root; N02 the protector's position match is not restricted to heads, so held caller data is rewritten; N03 the same numerical sign guard as 48 N2 in the **unsound** direction — an exactly-negative factor whose rounded value is positive licenses a principal-branch change; N04 the `"LocalCoordinate"` label. Four unnumbered proposals, including a declared assumption-value grammar and an exact-positive factor grammar. | [34 Python methods](code-review-54/evidence/test-output.txt) — 28 model and 6 emitter fixtures, with nested families recorded as subcases and **not** counted as further tests; a `pdflatex` build; a lexical WL check. **Nothing that loads the repository ran** ([environment](code-review-54/evidence/environment.json)): no wolframscript, no Mathics, connector errors, and `git clone` failed, so there was no local checkout. All four candidate edits were emitted against synthetic anchors and never applied. |
| [55 · Defining-sum integration audit](code-review-55/README.md) | [PDF](code-review-55/article/review.pdf) · [TeX](code-review-55/article/review.tex) | N01 the Dirichlet dispatcher requires the whole expression to **be** the atom, so `Zeta[x]-1` skips the defining-sum constructor and dies in the native adapter, although arithmetic on the bare atom's result produces the wanted object; N02 an explicit cutoff and `SeriesTermGoal` are treated as alternatives, so a validated goal is stored and ignored, and the cutoff preflight refuses without consulting an active goal; D01-local an integer-indexed Dirichlet jet algebra with proved coefficient-majorant transport. | Selected public calls and five candidate controls in Wolfram 15.0.0 Linux against the pinned standalone, plus a three-substitution patched copy re-loaded in a fresh kernel — the **only wave-6 candidate executed as a patched package** ([observations](code-review-55/evidence/native-observations.json)); [32 Python methods](code-review-55/evidence/python-tests.txt) over a prototype that never loads the package. No Mathics kernel; no upstream suite; no rebuilt canonical distribution. **N02 is not a new finding**: see below. |

## Overlapping obligations inside this wave

No package was retired, so every row is a bookkeeping instruction: count the
obligation once, keep every witness, and choose the repair deliberately.

| Obligation | Cited source | Also carried by, and what only it supplies |
| --- | --- | --- |
| Target-dependent `"SourceShift"` is admitted into a chart the remainder theorem assumes fixed | [46 N01](code-review-46/README.md) — the only kernel reproduction, and the only source of the stored target domain and normalized core parameters | [50 F1](code-review-50/README.md), source-predicted, uniquely proves failure at **every** depth, proves the converse bound that a genuine fixed shift changes the scale only by a finite constant, and proposes a **different repair**: a dedicated `"TargetDependentSourceShift"` diagnostic, against 46's widening of the existing condition. Both anchors match the current tree exactly once, so the intake must choose. Reproduced in the [characterization](../../../validation/wave6-witness-probe.json). |
| The Mathics inline-assumption protector rewrites `Element` occurrences a caller holds as data | [51 N01](code-review-51/README.md) — the only executed public consequence, and the only source of the nested-held witness that **defeats report 54's own patch** | [54 N02](code-review-54/README.md) supplies a witness needing no caller-side global and an arity policy 51's guard lacks, so the correct repair is the conjunction of the two conditions and neither package states it. Resolve jointly with [49 N1](code-review-49/README.md), which reports the *opposite* gap in the same routine: widening the traversal for 49 worsens 51/54, and narrowing the match for 51/54 does nothing for 49. One work item, with a declared grammar of protected positions. |
| One `"LocalCoordinate"` sentence describes two different quantities | [48 N3](code-review-48/README.md) — the only member that executed its own repair | [51 N02](code-review-51/README.md) supplies literal transcripts with the label inside the returned association; [54 N04](code-review-54/README.md) supplies the source derivation and a reasoned dissent against 48's additive-field repair. **All three patch only the kernel string.** The same sentence also stands in the [user guide](../../../src/Documentation/UserGuide.md) and its generated HTML, shipped by the same commit; no package notices it. Reproduced in the [characterization](../../../validation/wave6-witness-probe.json). |
| An exact symbolic logarithm split is authorized by a rounded machine sign | [54 N03](code-review-54/README.md) — the unsound direction, with an exact negative counterfamily and the only grammar that repairs both directions | [48 N2](code-review-48/README.md) reports the conservative direction and holds the only **publicly reachable** witness — the form the source comment names as the reason the recovery exists — plus the only executed host primitive and the threshold sweep. One guard, two failure directions, one obligation. Both emitters take the same anchor, so adopting either consumes the other; both are Mathics-only and neither ran Mathics. |
| Odd interval powers across zero lose endpoint geometry | [54 N01](code-review-54/README.md) — the exact returned-interval theorem, and a witness reaching the primitive from a verification interval that never crosses zero | [53 N01](code-review-53/README.md) has a witness needing neither the affine-range path nor a factored stored function, and it alone establishes that the candidate never widens an enclosure and warns that symmetric intervals conceal the defect. Keep both witnesses. `CertificateRegressions.wlt` pins three cases of this primitive, none an odd power across zero, which is why the gap survived. |
| Exact-rational arithmetic for the Lerch moment family | [49 E1](code-review-49/README.md) and [50 E2](code-review-50/README.md) | Both propose the same moment table in the same helpers and neither screened the other. They diverge on the theorem: 49 **strengthens** the bound to a signed two-sided enclosure on a narrower domain with 576 executed grid cases; 50 **preserves** the existing absolute bound on the full domain and adds an independent oracle. Count the work once and keep both theorems; under P08's own rule neither is admissible without matched measurements. |

## Relation to the maintained register

Two entries are **not new obligations**, and this index records that so a later
consolidation does not double-count them.

- **55 N02** restates retained [report 16](../wave-2/code-review-16/README.md)'s
  N04 — the same mechanism in the same two constructors. The register already
  carries it: *"R16 N04 still requires a common cutoff/term-goal policy"* under
  D01. Report 55 adds a native reproduction, the sub-mechanism that a resource
  refusal ignores an active goal, and a working patch. Report 16 named two
  coherent policies and warned that a regression must not codify a preference as
  a pre-existing promise; report 55 selects one of them, and two existing cases
  in `DirichletSpecialFunctions.wlt` would change behaviour under its patch.
  Record it as **selecting D01's policy**, not as landing a fix.
- **49 E2** supplies a proof and an explicit constant for an obligation already
  recorded as *"R16 O01/O02 … supply concrete Zeta/Lerch tail derivative
  obligations for X04/X05."* New as mathematics, not as a work item.

Three further entries sit inside stated open scopes and are governed by their
acceptance rules rather than by a new item: **47 N01** and **50 E2** inside P08,
which already names proof queries as a lane, already prescribes bounded
request-local reuse, and already forbids keeping an optimization without matched
measurements; and **48 P1** inside P06.

<a id="implementation-status"></a>
## Implementation status

The [maintained register](../../../docs/development/CODE_REVIEW_STATUS.md)
records the current state; this table only maps the wave's entries to it.

| Entries | Status |
| --- | --- |
| 46 N01, 50 F1 | **Implemented.** A target-dependent `"SourceShift"` is refused with the dedicated `TargetDependentSourceShift` diagnostic report 50 proposed; report 46's message-text advisory is applied. Fixed shifts remain admitted. |
| 48 N1 | **Implemented** inside C09: every option spelling resolves through `OptionValue`, first occurrence wins. |
| 48 N3, 51 N02, 54 N04 | **Implemented.** The kernel label, the user guide, the result reference and the generated HTML were corrected together, with 54's wording, and `"LocalReferenceObservable"` and `"ObservablePower"` were added as 48 proposed. |
| 52 N1, N2, N3 | **Implemented**, with the variable guard placed in the shared chart and the ordinary inverse constructor as report 52 staged it, the optional cutoff restricted to non-option arguments, and the exact observable routes dispatched after the condition is proved. |
| 55 N01 | **Implemented** in the Dirichlet dispatcher itself rather than through arithmetic, so the affine result keeps the atom's cutoff, remainder and transported bound. |
| 47 N02, 47 N03, 51 N03 | **Implemented** in the documentation checker: optimization-proof gates, comment masking and checkout containment. |
| 53 N01–N03, 54 N01 | Open: certificate interval geometry, rational powers and the retry policy. |
| 49 N1, 51 N01, 54 N02; 48 N2, 54 N03; 47 N01 | Open: the Mathics protector, the numerical logarithm split guard and prover reuse. None has been run on Mathics. |
| 55 N02 | Selects a D01 policy; not a new obligation (see above). |
| 48 P1; 49 E1, E2; 50 E1, E2 | Inside P06, P08 and the X04/X05 proposals; governed by those items. |

Evidence for the implemented rows is the 181/0
[wave-6 boundary run](../../../validation/wave6-boundaries-tests.json) and the
Python documentation tests, described in the
[validation record](../../../validation/README.md#wave-6-public-boundary-repairs).

## Evidence boundary

Six packages executed something in Wolfram 15.0.0 (46, 47, 48, 51, 52, 55);
report 55 is the only one that loaded a patched package. Reports 49, 50, 53 and
54 executed nothing that loads the repository. **No package ran Mathics**, yet
four findings are Mathics-specific (48 N2, 49 N1, 51 N01, 54 N02/N03) — those are
source-predicted by construction. Independent Python counts are separate
populations and must not be summed into an acceptance total, and each package's
transcribed observations are manual records rather than kernel logs.

Package-specific licensing and notices are preserved:
[48's audit and upstream licenses](code-review-48/LICENSE-AUDIT.txt),
[51's notices](code-review-51/NOTICES.md),
[52's notice](code-review-52/NOTICE.md),
[54's license](code-review-54/LICENSE.txt), and
[55's notice](code-review-55/NOTICE.md).
This index does not create a common license for the wave.

Return to the [review index](../README.md) or the
[development workflow](../../../docs/development/README.md).
