# Code review reports: wave 7

These six retained incremental review packages, numbered 56–61, examine
AsymptoticAnalysis after the wave-6 repairs. All are dated September 10,
2026. Five pin
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
59 alone carries the bootstrap-splitter finding.

| Package | Article | Retained findings | Supplied evidence and limits |
| --- | --- | --- | --- |
| [56 · Incremental technical audit](code-review-56/README.md) | [PDF](code-review-56/article.pdf) · [TeX](code-review-56/article.tex) | N01 composite sine/cosine bounds treat a real finite part as proof that the omitted error is real, so an amplified complex tail yields a false envelope; N02 binary arithmetic joins the operand conditions twice, so repeated self-addition triples the stored conjunction each step; E01 a positive Euler-difference enclosure for `LerchPhi[-q, s, a]` including `q = 1`. | Wolfram 15.0.0 Linux public baseline and in-memory candidate observations ([evidence](code-review-56/evidence/wolfram_observations.md)); 17 Python methods including a 700-case rational Lerch grid; 64 native reference combinations. No Mathics run; the WLT file was not run as a suite. |
| [57 · Source-pinned incremental correctness audit](code-review-57/README.md) | [PDF](code-review-57/article/review.pdf) · [TeX](code-review-57/article/review.tex) | N01 in the wave-6 affine Lerch integration an affine constant charged above a nonpositive cutoff inherited the atom's positive remainder exponent, so `1 + LerchPhi[1/2, 2, x]` at cutoff `0` claimed a bound `3/x^2` while the error at `x = 2` is at least `5/4`. | 20 Python methods over an exact-rational reference and 4 emitter fixtures; a SymPy finite-identity check. **No Wolfram or Mathics execution succeeded**; the public outputs are source-derived predictions. |
| [58 · Incremental audit and uniform Lerch prototype](code-review-58/README.md) | [PDF](code-review-58/article/article.pdf) · [TeX](code-review-58/article/article.tex) | G01 the reflected Erfc adapter reports a `"FrontierTerm"` without the source sign applied to its expression and terms; E01 an additive prototype for the unsupported Lerch transition regime with a proved signed remainder bound. | Wolfram 15.0.0 reproduced the Erfc defect and verified a one-case in-memory patch ([observations](code-review-58/evidence/native-observations.md)); 12 Python methods with 96 numerical subcases. No Mathics run, no full suite. |
| [59 · Componentwise validation and standalone parsing](code-review-59/README.md) | [PDF](code-review-59/article/review.pdf) · [TeX](code-review-59/article/review.tex) | N01 `AsymptoticCoreInverse` validates `core + perturbation` and then consumes the components separately, so a target-dependent offset that cancels in the sum bypasses the fixed-data premise (a squared witness with `x + Abs[y]/2` and `-Abs[y]/2`); N02 the Mathics bootstrap splitter in the standalone builder counts only brackets, so a semicolon inside an association splits a statement. | 33 Python unittest methods over an exact model, a bootstrap lexer and emitter fixtures. **No Wolfram or Mathics package execution**; the public witness is source-predicted. |
| [60 · Core-component validation audit](code-review-60/README.md) | [PDF](code-review-60/article/review.pdf) · [TeX](code-review-60/article/review.tex) | N01 the same component-validation defect, with two public witnesses for `x + 1/x = y` whose claimed errors are `O(y^-2)` and `O(y^-4)` while the true errors are `Θ(y^-1)`. | Both witnesses reproduced in Wolfram 15.0.0 Linux, a temporary patched standalone exhibiting the expected outcomes for five requests, and a 17-input native forward screen. No Mathics run, no full suite. |
| [61 · Exact predicates and Hermitian coefficient arithmetic](code-review-61/README.md) | [PDF](code-review-61/article/asymptotic-review.pdf) · [TeX](code-review-61/article/asymptotic-review.tex) | N01 `inverseFunctionConditionOnJet` uses the finite coefficients of a truncated jet as an exact `Element[..., Reals]` proof, so a cancelled complex Taylor tail makes an everywhere-false condition look true at a low cutoff and `SeriesObservable` returns `1` with zero remainder; H01 an exact Hermitian half-spectrum prototype for Fourier-polynomial products. | Five low/high-cutoff pairs observed on Wolfram 15.0.0 ([observations](code-review-61/evidence/native-observations.json)); 12 Python methods. No Mathics run. |

<a id="implementation-status"></a>
## Implementation status

The [maintained register](../../../docs/development/CODE_REVIEW_STATUS.md)
records the current state; this table maps the wave's entries to it.

| Entries | Status |
| --- | --- |
| 56 N01 | **Implemented** as the report's candidate: a composite `Sin` or `Cos` of a nonzero remainder requires a vanishing envelope and is refused with `UnprovedRealRemainder` otherwise; `Abs` keeps the complex Lipschitz bound. |
| 56 N02 | **Implemented**: operand conditions are joined by structural idempotent conjunction in alignment and finalization. |
| 57 N01 | **Implemented**: a charged affine constant above a positive atom tail order sets the remainder order to zero and enters the bound as a separate term. |
| 58 G01 | **Implemented** as the supplied one-line patch. |
| 59 N01, 60 N01 | **Implemented** as report 60's diff: the core and the perturbation are validated separately, so a target-dependent offset cancelling in the sum is refused. |
| 59 N02 | **Implemented**: the standalone builder's bootstrap splitter keeps a delimiter stack with association delimiters in ASCII, long-name and private-use spellings. |
| 61 N01 | **Implemented** as the supplied guard: only an exact jet proves a membership predicate. |
| 56 E01, 58 E01, 61 H01 | Proposals; recorded under the register's extension items. |

Evidence for the implemented rows is the
[wave-7 contract run](../../../validation/wave7-contract-tests.json) and the
[standalone builder tests](../../../validation/test_standalone.py), described in
the [validation record](../../../validation/README.md#wave-7-contract-repairs).

## Evidence boundary

Reports 56, 58 and 60 executed public calls in Wolfram 15.0.0; reports 57, 59
and 61's public consequences were source-predicted or observed only through
selected calls. **No package ran Mathics.** Independent Python counts are
separate populations and must not be summed into an acceptance total.

Package-specific licensing and notices are preserved:
[57's code notice](code-review-57/CODE-NOTICE.md) and
[59's licenses](code-review-59/licenses/). This index does not create a common
license for the wave.

Return to the [review index](../README.md) or the
[development workflow](../../../docs/development/README.md).
