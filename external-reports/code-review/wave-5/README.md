# Code review reports: wave 5

These seven retained incremental review packages, numbered 37–39 and 42–45,
examine AsymptoticAnalysis after the wave-4 repairs. They are dated
September 10, 2026 and pin two snapshots:
[8e85996](https://github.com/VladimirReshetnikov/Asymptotic/tree/8e859961d7d37f008b826f3a8cad406460271614)
for reports 37, 38, 43, 44 and 45, and
[651f202](https://github.com/VladimirReshetnikov/Asymptotic/tree/651f2029d0b2cd4da9e4dfdf1f4275a124d23b99)
for reports 39 and 42. Each novelty ledger states how far its author compared
the findings with the earlier waves and the maintained register.

Reports [40](code-review-40.md) and [41](code-review-41.md) were
[retired](../README.md#retired-review-packages) as duplicates: three packages independently reported the same signed-real
`Abs` shortcut, and the observable derivative-contract finding was reported
twice. The surviving copies are named in the overlap table below.

This wave has **no consolidated intake yet**. Its entries are not part of the
231 attributed entries counted for waves 1–4, and none of them has been mapped
to a `C*`, `P*`, `D*`, `V*`, `X*`, `W3-*` or `W4-*` work item. Treat every row
below as unprocessed review material, not as accepted or refuted behavior.

| Package | Article | Retained findings | Supplied evidence and limits |
| --- | --- | --- | --- |
| [37 · Differential code audit](code-review-37/README.md) | [PDF](code-review-37/article/audit.pdf) · [TeX](code-review-37/article/audit.tex) | F01 signed-real `Abs` shortcut on complex retained coefficients; F02 zeroth power without a parameter-domain nonvanishing proof; F03 ignored Gamma/Barnes cutoff. | [22 independent Python checks](code-review-37/evidence/independent_results.json); [no Wolfram or Mathics package execution](code-review-37/evidence/execution_status.json). The candidate emitter, characterization script and 14 desired-contract tests are unrun. |
| [38 · Which inverse, and which derivative?](code-review-38/README.md) | [PDF](code-review-38/article/article.pdf) · [TeX](code-review-38/article/article.tex) | N1 selected-branch identification when a remote exact root has zero equation residual; N2 scope of the LogGamma `OriginalDerivativeLowerBound` under scaling. | [28 independent Python methods](code-review-38/evidence/independent-results.json) with exact and 80-digit samples; [package, native and Mathics runs unavailable](code-review-38/evidence/scope.json). |
| [39 · Incremental repository audit](code-review-39/README.md) | [PDF](code-review-39/article/review.pdf) · [TeX](code-review-39/article/review.tex) | N01 no-op truncation drops the transported-bound companion field; N02 repeated affine classification on overlapping nonlinear subtrees; N03 the receipt checker admits internally contradictory records. | [34 pytest cases](code-review-39/evidence/independent-results.json) and one transcribed [public native witness plus load smoke](code-review-39/evidence/native-witness.json). Six MUnit regressions and the native probe are unrun. |
| [42 · Regularity contracts and structural work](code-review-42/README.md) | [PDF](code-review-42/article.pdf) · [TeX](code-review-42/article.tex) | N01 a derivative contract survives an `Abs` of a pure remainder with infinitely many cusps; N02 repeated affine probing (same obligation as 39 N02); N03 discarded-suffix selection by repeated membership queries. | [14 independent tests and six patch-emitter fixtures](code-review-42/evidence/independent_results.json); [no Wolfram or Mathics execution](code-review-42/evidence/audit_manifest.json). Supplied WL received a lexical check only. |
| [43 · Focused source-review deltas](code-review-43/README.md) | [PDF](code-review-43/article/article.pdf) · [TeX](code-review-43/article/article.tex) | F01 missing explicit source orientation in inverse coefficient reconstruction; F02 a public model's `Limit` may be its normalization offset; F03 a core inverse can retain the eliminated source symbol; E01 strict polynomial monotonicity certificates with isolated stationary points. | [35 independent Python tests](code-review-43/evidence/independent-tests.json) and one transcribed [package smoke](code-review-43/evidence/native-smoke.json). The integration probes are unrun; the [quintic certificate](code-review-43/evidence/quintic-monotonicity-certificate.json) proves strict increase, not an error bound. |
| [44 · Incremental repository audit](code-review-44/README.md) | [PDF](code-review-44/article/asymptotic-review.pdf) · [TeX](code-review-44/article/asymptotic-review.tex) | T01 test-contract identity in historical reconciliation; T02 POSIX permission loss when publishing PDFs; T03 last-pass-only TeX recorder provenance; T04 lost shared-ledger updates between concurrent builders; P01 PDF build-environment freshness, a policy improvement adjacent to D07; Q01 an unresolved analytic question on complex phase-error transfer, adjacent to C07 and C13, with no public reachability established. The report keeps its own distinction between the four tooling findings and these two. | [22 unittest methods](code-review-44/evidence/test-output.txt), some POSIX-only or requiring `pdflatex`; [no repository, Wolfram or Mathics run](code-review-44/evidence/scope.json). No new public mathematical defect is claimed. |
| [45 · Incremental source review](code-review-45/README.md) | [PDF](code-review-45/article/review.pdf) · [TeX](code-review-45/article/review.tex) | N01 exact rational source seeds fall outside the new Mathics exact-integer root exception, a conservative coverage limit rather than a wrong result. | [30 independent Python methods](code-review-45/evidence/independent-tests.json); [no Wolfram or Mathics package run](code-review-45/evidence/review-scope.json). The WL overlay, probes and public regressions are unexecuted. |

## Overlapping obligations inside this wave

Retiring reports 40 and 41 removed duplicate copies, not the underlying
obligations. The remaining overlaps must be treated as single work items when
this wave is consolidated.

| Obligation | Retained source | Duplicates removed or still present |
| --- | --- | --- |
| Signed-real `Abs` shortcut accepts nonreal retained coefficients | [37 F01](code-review-37/README.md) | The same defect was reported by retired [40 ABS-01](code-review-40.md) and [41 ABS-01](code-review-41.md), but the three packages supplied **different witnesses**. Report 37 gives the algebraic cancellation `Abs[1+a x]+Abs[1-a x]-2` under `a^2 == -1`, which passes the package's input screen; retired 40 added a logarithmic witness whose exact value leaves the power-logarithmic scale; retired 41 added a squared witness returning a real coefficient of the wrong sign. All three are reproduced on the current source in the [five-case characterization](../../../validation/wave5-modulus-witness.json), which also records two agreeing real-parameter controls. |
| `Abs` of a pure remainder keeps an unproved classical derivative contract | [42 N01](code-review-42/README.md) | The same defect was reported by retired [40 ABS-02](code-review-40.md), again with a different witness: 42 uses the pure-remainder family `R(y) = y^3 Sin[Log[y]]` reached through `AsymptoticInverse`, while 40 used the exact source `f(x) = x + x^2 Sin[Log[x]]` routed through `AsymptoticFourierInverse`, naming the Fourier constructor's default derivative order as part of the affected path. The article's Example 16.2 preserves 40's family. |
| Repeated affine classification on nested nonlinear subtrees | [39 N02](code-review-39/README.md) | [42 N02](code-review-42/README.md) reports the same mechanism in the same code, with an independently derived quadratic count on a different Horner family: 39 proves `4n(n+1)` recognizer visits for `e_n = x(1 + e_{n-1})`, 42 proves `4(d+1)^2 - 1` for `h_{d+1} = 1 + x h_d`. The two formulas differ at every degree. Both packages carry unique findings, so neither was retired; count the obligation once and keep both witness families. |
| Truncation transport after C22 | [39 N01](code-review-39/README.md) and [42 N03](code-review-42/README.md) | Different mechanisms in the same new code: a dropped companion field versus repeated membership queries. Not duplicates. |

The retired packages' modulus mathematics is preserved. The correct
complex-modulus construction on a real local coordinate — square the norm,
take the positive root of the resulting jet, and transport magnitude error by
the reverse triangle inequality — is recorded in the
[mathematical article](../../../docs/article/sections/03-forward.tex), together
with retired report 41's Hermitian pairing count (`r(r+1)/2` unordered products
instead of `r^2`, so 2080 rather than 4096 at support 64), the reason a positive
leading coefficient does not license the shortcut, and the reason a valid
magnitude bound does not transport a classical derivative contract.

## Implementation status

The [maintained register](../../../docs/development/CODE_REVIEW_STATUS.md)
records the current state; this table maps the wave's entries to it.

| Entries | Status |
| --- | --- |
| 37 F01 (with retired 40 ABS-01, 41 ABS-01) | **Implemented.** The forward modulus applies the sign rule only to provably real retained coefficients and otherwise uses the article's norm-square construction on the real coordinate; the logarithmic witness is refused as leaving the power-log scale. Pinned in [ReviewModulusReality.wlt](../../../src/Tests/ReviewModulusReality.wlt) and the [wave-5 modulus run](../../../validation/wave5-modulus-tests.json). |
| 42 N01 (with retired 40 ABS-02) | **Implemented.** A modulus of a nonzero remainder records `RemainderDerivativeOrder -> 0`; report 42's differentiated pure-remainder chain now refuses a further derivative. |
| 37 F02 | **Implemented.** A zeroth power requires a retained leading coefficient provably nonzero on the parameter domain; a pure remainder is refused. |
| 37 F03 | **Implemented.** The Gamma/Barnes zeroth-power path forwards the validated cutoff to the constant result instead of a literal `1`. |
| 38 N1 | **Implemented** for exact numeric polynomial sources: the numerical check isolates the endpoint-incident monotone component and takes the unique equation root inside it, or refuses; the cubic witness now returns the selected-branch value `1/4`. Nonpolynomial sources keep the solver's root and report the component as unverified. |
| 38 N2 | **Implemented.** The Gamma/LogGamma adapters return `"TransformedDerivativeLowerBound"`, a scaled `"OriginalDerivativeLowerBound"` for the stored original function, and a scope record. |
| 39 N01, 42 N03 | **Implemented.** A no-op truncation keeps `"TruncationDiscardedPart"`; discarded rows are the suffix of the ordered rows when the retained rows are a prefix. |
| 39 N03 | **Implemented** in the acceptance verifier: a recorded first source mismatch is rejected; the reference-set comparison already establishes that the selected entry is fingerprinted. |
| 43 F01 | **Implemented.** `InverseExpansionCoefficient` on a result object returns `"SourceOrientation"`, `"ObservableCoefficient"`, `"AdditiveOffset"` and `"ContributionExpression"` beside the unchanged local coefficient. |
| 43 F02 | **Implemented.** `PowerLogModel` returns `"ModelOffset"` and `"TargetLimit"` beside the legacy `"Limit"`. |
| 43 F03 | **Implemented** on both kernels: a perturbative core containing the source symbol is refused. |
| 44 T01 | **Implemented.** The historical summarizer refuses to reconcile receipts with different test-suite snapshots. |
| 45 N01 | **Implemented.** The Mathics exact-seed exception verifies exact rationals by substitution. |
| 39 N02, 42 N02 | **Implemented.** The certificate evaluator memoizes its affine recognizer within one attempt; the depth-8 Horner tree costs fewer than 40 recognizer bodies instead of more than 300, with identical enclosures. |
| 44 T02, T03, T04 | **Implemented.** PDF publication preserves the target's POSIX access mode; the builder captures the TeX recorder after every pass and keeps their union; the builds ledger is updated by a locked fresh-read merge, so independently launched builders no longer lose each other's entries. Covered by the [tooling tests](../../../validation/test_proveit_tooling.py). |
| 43 E01; 44 P01, Q01 | Open: the polynomial monotonicity certificate proposal, the build-freshness policy adjacent to D07, and the unresolved phase-error question adjacent to C07 and C13. |

## Evidence boundary

No package in this wave executed the repository in Wolfram or in Mathics beyond
two transcribed observations (39 and 43, each recorded before subsequent calls
failed). The one exception added afterwards is the maintained
[modulus characterization](../../../validation/wave5-modulus-witness.json),
which reproduces the modulus witnesses on the current source; it is a probe, not
an acceptance suite. The other packages record the connector or a local kernel as
unavailable: reports 37, 38, 42 and 45 record service or connection failures, and
report 44's scope file gives "Wolfram connector unavailable; no functioning local
symbolic kernel" — not that a kernel was unnecessary, though it does separately
claim no new public mathematical defect. Public behavior below the finding level
is therefore **source-predicted**, and the supplied WLT
files, overlays, probes and characterization scripts are specifications rather
than results. Independent Python counts are separate populations and must not
be summed into a package acceptance total.

Package-specific licensing and notices are preserved:
[37's upstream license](code-review-37/UPSTREAM-LICENSE.txt),
[38's license](code-review-38/LICENSE),
[39's license](code-review-39/LICENSE),
[44's fixture provenance notice](code-review-44/fixtures/NOTICE.md), and
[45's licenses directory](code-review-45/licenses/).
This index does not create a common license for the wave.

Return to the [review index](../README.md) or the
[development workflow](../../../docs/development/README.md).
