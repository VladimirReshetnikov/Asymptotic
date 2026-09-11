# Code review reports: wave 7

These nine retained incremental review packages, numbered 56–64, examine
AsymptoticAnalysis after the wave-6 repairs. All are dated September 10,
2026. Eight pin
[efa1aee](https://github.com/VladimirReshetnikov/Asymptotic/tree/efa1aeec4845a9c35e140963a0333d0c9ec33b05),
the commit that indexed wave 6; report 57 pins
[8f28084](https://github.com/VladimirReshetnikov/Asymptotic/tree/8f280847bf8fd1f6488834cadf1542867292ce10),
the first commit carrying the wave-6 affine Dirichlet integration it audits.
Each novelty ledger states how far its author screened against the earlier
waves and the register; none could screen against its own wave.

This wave has **no consolidated intake**. Its entries are not part of the 231
attributed entries counted for waves 1–4. Reports 59 and 60 report the same
component-validation defect of `AsymptoticCoreInverse` with different
witnesses; both are retained because 60 alone executed public witnesses and
59 alone carries the bootstrap-splitter finding. Report 62, which arrived
after the first six, reports the same duplicated-condition mechanism as 56
N02 with its own growth measurements and witnesses; it is retained for those.
Report 63, which arrived after 62, audits the exact-rational certificate
logarithm and is the only package of the wave whose findings are refusals
rather than false results. Report 64, the last arrival, restates the
component-validation defect of 59 and 60 with an all-depth proof and a
vanishing-ratio family, and adds a rational Lerch enclosure construction; it
is retained for the proof and the construction.

| Package | Article | Retained findings | Supplied evidence and limits |
| --- | --- | --- | --- |
| [56 · Incremental technical audit](code-review-56/README.md) | [PDF](code-review-56/article.pdf) · [TeX](code-review-56/article.tex) | N01 composite sine/cosine bounds treat a real finite part as proof that the omitted error is real, so an amplified complex tail yields a false envelope; N02 binary arithmetic joins the operand conditions twice, so repeated self-addition triples the stored conjunction each step; E01 a positive Euler-difference enclosure for `LerchPhi[-q, s, a]` including `q = 1`. | Wolfram 15.0.0 Linux public baseline and in-memory candidate observations ([evidence](code-review-56/evidence/wolfram_observations.md)); 17 Python methods including a 700-case rational Lerch grid; 64 native reference combinations. No Mathics run; the WLT file was not run as a suite. |
| [57 · Source-pinned incremental correctness audit](code-review-57/README.md) | [PDF](code-review-57/article/review.pdf) · [TeX](code-review-57/article/review.tex) | N01 in the wave-6 affine Lerch integration an affine constant charged above a nonpositive cutoff inherited the atom's positive remainder exponent, so `1 + LerchPhi[1/2, 2, x]` at cutoff `0` claimed a bound `3/x^2` while the error at `x = 2` is at least `5/4`. | 20 Python methods over an exact-rational reference and 4 emitter fixtures; a SymPy finite-identity check. **No Wolfram or Mathics execution succeeded**; the public outputs are source-derived predictions. |
| [58 · Incremental audit and uniform Lerch prototype](code-review-58/README.md) | [PDF](code-review-58/article/article.pdf) · [TeX](code-review-58/article/article.tex) | G01 the reflected Erfc adapter reports a `"FrontierTerm"` without the source sign applied to its expression and terms; E01 an additive prototype for the unsupported Lerch transition regime with a proved signed remainder bound. | Wolfram 15.0.0 reproduced the Erfc defect and verified a one-case in-memory patch ([observations](code-review-58/evidence/native-observations.md)); 12 Python methods with 96 numerical subcases. No Mathics run, no full suite. |
| [59 · Componentwise validation and standalone parsing](code-review-59/README.md) | [PDF](code-review-59/article/review.pdf) · [TeX](code-review-59/article/review.tex) | N01 `AsymptoticCoreInverse` validates `core + perturbation` and then consumes the components separately, so a target-dependent offset that cancels in the sum bypasses the fixed-data premise (a squared witness with `x + Abs[y]/2` and `-Abs[y]/2`); N02 the Mathics bootstrap splitter in the standalone builder counts only brackets, so a semicolon inside an association splits a statement. | 33 Python unittest methods over an exact model, a bootstrap lexer and emitter fixtures. **No Wolfram or Mathics package execution**; the public witness is source-predicted. |
| [60 · Core-component validation audit](code-review-60/README.md) | [PDF](code-review-60/article/review.pdf) · [TeX](code-review-60/article/review.tex) | N01 the same component-validation defect, with two public witnesses for `x + 1/x = y` whose claimed errors are `O(y^-2)` and `O(y^-4)` while the true errors are `Θ(y^-1)`. | Both witnesses reproduced in Wolfram 15.0.0 Linux, a temporary patched standalone exhibiting the expected outcomes for five requests, and a 17-input native forward screen. No Mathics run, no full suite. |
| [61 · Exact predicates and Hermitian coefficient arithmetic](code-review-61/README.md) | [PDF](code-review-61/article/asymptotic-review.pdf) · [TeX](code-review-61/article/asymptotic-review.tex) | N01 `inverseFunctionConditionOnJet` uses the finite coefficients of a truncated jet as an exact `Element[..., Reals]` proof, so a cancelled complex Taylor tail makes an everywhere-false condition look true at a low cutoff and `SeriesObservable` returns `1` with zero remainder; H01 an exact Hermitian half-spectrum prototype for Fourier-polynomial products. | Five low/high-cutoff pairs observed on Wolfram 15.0.0 ([observations](code-review-61/evidence/native-observations.json)); 12 Python methods. No Mathics run. |
| [62 · Incremental source and runtime audit](code-review-62/README.md) | [PDF](code-review-62/article/audit.pdf) · [TeX](code-review-62/article/audit.tex) | CG-01 binary arithmetic duplicates already-aligned operational conditions: repeated addition of an independent zero series stores `2^(n+1) - 1` copies of `x > 0`, and repeated scalar-zero addition the sequence `3, 9, 27, 81`, while the finite expression stays `x`; removing only the second merge still leaves `2, 4, 8, 16`. | Wolfram 15.0.0 Linux observations of the growth sequences and of a candidate exercised by source substitution ([observations](code-review-62/evidence/native_observations.json)); 26 Python methods over Boolean/count models. No Mathics run, no full suite. |
| [63 · Logarithmic certificate precision](code-review-63/README.md) | [PDF](code-review-63/article/report.pdf) · [TeX](code-review-63/article/report.tex) | F01 the certificate point logarithm reduces a rational just below one as `Log[2 - 2 delta] - Log[2]`, so two near-equal unit enclosures cancel and the result straddles zero at every fixed order once `delta` is small (`Log[1 - 2^-200]` enclosed by about `±1.85*10^-3`); F02 an exact rational affine logarithm argument is rounded to the dyadic grid before the logarithm, so the singleton `1 + 2^-200` becomes `[1, 1 + 2^-47]` and its logarithm must contain zero. Both are avoidable refusals (`ResidualBracketOutsideInterval`), not false certificates; E01 a positivity-guarded centered log-ratio residual prototype. | Wolfram 15.0.0 Linux: three public witnesses against four full standalone variants, with the 2×2 matrix showing neither repair substitutes for the other ([matrix](code-review-63/evidence/native-matrix.json), [observations](code-review-63/evidence/native-observations.json)); 24 exact-rational Python methods. No Mathics run; the WLT file was not run as a suite. |
| [64 · After six review waves](code-review-64/README.md) | [PDF](code-review-64/article/article.pdf) · [TeX](code-review-64/article/article.tex) | N01 `AsymptoticCoreInverse` checks target independence on `core + perturbation` and then uses the operands separately, so for `1/x + Abs[y]/2` with perturbation `-Abs[y]/2` the sum is exactly `1/x` while the marker approximations alternate between `0` and `2/y` at every depth and the claimed remainder improves by one power each time; a second family with a genuinely vanishing perturbation ratio still violates the reported scale. E01 a hierarchy of exact rational Gauss/Radau lower and upper bounds for `LerchPhi[q, 1, a]` from two Meixner three-term recurrences, with positivity, signed errors, error caps and nesting proved. | Isolated Wolfram 15.0.0 Linux evaluations of the marker recurrence and of four enclosure orders against native `LerchPhi` ([observations](code-review-64/evidence/native-observations.json)); 24 Python methods with exact defining-sum and moment oracles. **No package load succeeded**; the public N01 outcome is source-predicted, no Mathics run, the WLT file was not run. |

<a id="implementation-status"></a>
## Implementation status

The [maintained register](../../../docs/development/CODE_REVIEW_STATUS.md)
records the current state; this table maps the wave's entries to it.

| Entries | Status |
| --- | --- |
| 56 N01 | **Implemented** as the report's candidate: a composite `Sin` or `Cos` of a nonzero remainder requires a vanishing envelope and is refused with `UnprovedRealRemainder` otherwise; `Abs` keeps the complex Lipschitz bound. |
| 56 N02, 62 CG-01 | **Implemented**: operand conditions are joined by structural idempotent conjunction in alignment and finalization, which is the stronger repair report 62 asks for; 62's zero-series, scalar-zero and unit-multiplication witnesses are pinned beside 56's self-addition. |
| 57 N01 | **Implemented**: a charged affine constant above a positive atom tail order sets the remainder order to zero and enters the bound as a separate term. |
| 58 G01 | **Implemented** as the supplied one-line patch. |
| 59 N01, 60 N01, 64 N01 | **Implemented** as report 60's diff: the core and the perturbation are validated separately, so a target-dependent offset cancelling in the sum is refused. Report 64's all-depth witness, its vanishing-ratio family, its fixed-data controls and its inexact-operand refusal are pinned beside the earlier witnesses. |
| 59 N02 | **Implemented**: the standalone builder's bootstrap splitter keeps a delimiter stack with association delimiters in ASCII, long-name and private-use spellings. |
| 61 N01 | **Implemented** as the supplied guard: only an exact jet proves a membership predicate. |
| 63 F01, 63 F02 | **Implemented** as the supplied two lines: below one the point logarithm returns the negated logarithm of the reciprocal, and a rational affine logarithm argument passes its exact range to the logarithm primitive. All three witnesses certify at enclosure order 2 without refinement on Wolfram 15.0.1; the portable case `certificate-logarithm-near-one-relative-precision` is queued for Mathics. |
| 56 E01, 58 E01, 61 H01, 63 E01, 64 E01 | Proposals; recorded under the register's extension items. |

Evidence for the implemented rows is the
[wave-7 contract run](../../../validation/wave7-contract-tests.json) and the
[standalone builder tests](../../../validation/test_standalone.py), described in
the [validation record](../../../validation/README.md#wave-7-contract-repairs).

## Evidence boundary

Reports 56, 58, 60, 62 and 63 executed public calls in Wolfram 15.0.0; reports
57, 59, 61 and 64's public consequences were source-predicted or observed only
through selected calls. **No package ran Mathics.** Independent Python counts are
separate populations and must not be summed into an acceptance total.

Package-specific licensing and notices are preserved:
[57's code notice](code-review-57/CODE-NOTICE.md),
[59's licenses](code-review-59/licenses/), and
[62's license](code-review-62/LICENSE) and [notice](code-review-62/NOTICE.md), and
[63's notice](code-review-63/NOTICE.md) with its
[upstream license copy](code-review-63/UPSTREAM-LICENSE.txt), and
[64's license](code-review-64/LICENSE). This index does
not create a common license for the wave.

Return to the [review index](../README.md) or the
[development workflow](../../../docs/development/README.md).
