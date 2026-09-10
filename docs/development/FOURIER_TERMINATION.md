# Termination of Fourier composition recurrences

This note tracks **W3-13**, the Fourier-specific extension of **P03** in
[report 24, F01](../../external-reports/code-review/wave-3/code-review-24/article/audit.tex).
The [wave-3 intake](WAVE_3_INTAKE.md) and
[review register](CODE_REVIEW_STATUS.md) retain the separate ordinary-engine
repair. The Fourier loop is now repaired, with **68/0 focused native acceptance
across four selected files**, including 19 new cases. Avoiding
an unused product is not a measured end-to-end speedup claim.

The [17-observation baseline](../../validation/fourier-termination-baseline.json)
at `cc1b06c` and [same probes after the fix](../../validation/fourier-termination-after-fix.json)
use Wolfram 15.0.1 Windows64. Both record 55 kernel hashes, unchanged sources
and an unchanged probe during execution. They reproduce and repair constant,
linear, quadratic and assumption-dependent helper failures, as well as a
public residual failure with an explicit budget of seven. Genuine pair and
frequency limits, nonterminating coefficients and nonpositive-valuation
refusals remain controls. These observations are distinct from the
[68/0 acceptance run](../../validation/fourier-termination-tests.json), which
records 61 input hashes and unchanged sources during execution.

The report's [historical observations](../../external-reports/code-review/wave-3/code-review-24/evidence/native_observations.json)
are pinned to `6687962f3c858a4f93623cfc496f33e35c6763d4` and describe
Wolfram 15.0.0 Linux. They are manually transcribed selected evaluator
responses, not a complete exported kernel log. The report records both a
private budget failure and a successful public residual control. Its
temporary candidate result is evidence about that candidate, not acceptance
of the current checkout. No full-suite run is requested here.

## The source path and reproduced failure

In [FourierCoefficients.wl](../../src/Kernel/FourierCoefficients.wl),
`fourierComposeBlock` evaluates

```text
(1 + U)^alpha B(L + Log[1 + U]) = Sum[Q_k(L) U^k, {k, 0, Infinity}],
Q_0 = B,
Q_(k+1) = ((alpha - k) Q_k + D[Q_k, L])/(k + 1).
```

Before the repair, its loop checked the iteration budget, constructed the next
`fourierJetMul` product, and only then computed the next coefficient and
checked whether it vanished. The multiplication counts retained candidate
pairs before merging equal source weights. Consequently an unnecessary
product can fail even though the complete requested answer fits the budget.
The public `FourierInverseResidual` uses this helper for the leading core,
each shifted perturbation, and reconstruction of a nonunit observable power.
The public before/after witness is:

```wolfram
s = AsymptoticFourierInverse[
  x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7];
check = FourierInverseResidual[s, Automatic, "MaxTerms" -> 7];
{check["ZeroBelowCutoff"], check["ResidualBlocks"], check["RelativeCutoff"]}
```

The repaired result is `{True, {}, 6}`; the baseline returns `ResourceLimit`.
At relative cutoff six, the unused square for the leading linear block has
ten retained pairs, while the needed square in the shifted quadratic block
has six. The explicit budget seven therefore admits all necessary products
in this example. The result checks the finite forward model, not unspecified
input-remainder terms or a numerical root enclosure.

The minimal independent oracle is `B = 1`, `alpha = 1`, `U = w + w^2`,
with exclusive source-weight cutoff `H = 5`. The answer is exactly
`1 + w + w^2`. Its first useful product has two retained pairs; the unused
square has four pairs at weights `2, 3, 3, 4`. A pair limit of three therefore
rejects the square even though its coefficient `Q_2` is zero. The desired
helper result is the three-row jet shown in the report's
[contract fixture](../../external-reports/code-review/wave-3/code-review-24/code/desired_contracts.wlt).

## Two independent stopping proofs

Let `nu > 0` be the least source weight of the finite input jet `U`.
Every term of `U^j` has weight at least `j nu`; coefficient differentiation
and frequency convolution do not change source weights. Thus
`(k + 1) nu >= H` removes every subsequent product from the retained jet.
Equality is sufficient because the cutoff is exclusive. This is a support
argument: it does not declare the underlying function exact or discard a
boundary logarithmic factor from an analytic remainder.

Independently, `Q_(k+1) == 0` as a complete Fourier-polynomial identity is
absorbing: its Euler derivative also vanishes, so induction gives zero for
every later coefficient. Equal frequencies and their complete polynomial
amplitudes must first be collected under the stored parameter assumptions.
A value that vanishes at one logarithmic argument, an unproved parameter
relation, or a zero Taylor coefficient from an arbitrary provider is not
this identity. The [mathematical chapter](../article/sections/22-fourier.tex)
states both arguments alongside the existing composition recurrence.

The repaired loop checks support exhaustion first,
forms and normalizes the next homogeneous coefficient second, and constructs
the next power only if a nonzero retained contribution remains possible.
Support exhaustion should precede coefficient work too: otherwise a needless
coefficient operation could introduce a new failure on a path whose next
product is already outside the cutoff. Preserve input/option validation,
positive-valuation admission, and budgets for genuinely needed coefficients,
products and accumulated output. This is a local loop change; it does not
change the convolution's retained-pair accounting or introduce a global cache.
The source uses the current product's actual least weight plus `nu` for the
support check, which also respects any earlier increase from cancellation.

## Independent acceptance obligations

| Case | Required result or boundary |
| --- | --- |
| Constant `B`, `alpha = 1`, `U = w + w^2`, `H = 5`, limit three | Exact `1 + w + w^2`; no unused square is required. |
| Constant `B`, `alpha = 0` | The coefficient recurrence ends immediately after the constant, subject to normal input validation. |
| Positive valuation with `(k + 1) nu == H` | No next retained product; include rational and irrational source weights and a nonterminating coefficient as controls. |
| Complete coefficient cancels under retained assumptions | The zero identity terminates; later ambient assumptions must not replace the stored proof context. |
| `B = Exp[I L]`, `alpha = 0` | `Q_k = Binomial[I, k] Exp[I L]` never vanishes. For `U = w`, retain `Exp[I L] (1 + I w + (-1-I) w^2/2)` below cutoff three. |
| `B = L`, `alpha = 1` | For `U = w`, retain `L + (L+1) w + w^2/2 - w^3/6` below cutoff four; the integer exponent does not terminate this logarithmic amplitude. |
| Genuinely required products or modes exceed their limits | Preserve the applicable resource refusal; the stopping rules are not budget bypasses. |
| Empty input or inadmissible nonpositive valuation | Preserve the existing constant result or validation failure, respectively. |

The complex mode is a coefficient-algebra control, not a new public nonreal
inverse branch. Public conjugate-mode controls should retain the real source
contract. Existing [Fourier regressions](../../src/Tests/FourierRegressions.wlt)
cover ordinary and nonunit-power residuals, oscillatory and logarithmic
amplitudes, shifted/infinite coordinates, and frequency limits.
[Fourier refactoring tests](../../src/Tests/FourierRefactoring.wlt) protect
support convolution, exact resonances and cancellation. The ordinary
[recurrence tests](../../src/Tests/ReviewRecurrenceTermination.wlt) remain
separate evidence and do not establish this Fourier path's acceptance.

The [focused runner](../../validation/CheckFourierTermination.wl) selects
[19 new termination cases](../../src/Tests/ReviewFourierTermination.wlt)
alongside 22 Fourier regressions, 11 Fourier refactoring cases and 16 ordinary
recurrence cases. All 68 pass in the
[completed receipt](../../validation/fourier-termination-tests.json).
The separate [loading receipt](../../validation/fourier-termination-loading-tests.json)
records 105/0 checks in five fresh native kernels, with 61 stable input hashes
and no local HTTP server. Loading checks and mathematical regressions are
different populations; neither is a full-suite result. Operation-count
savings on the terminating witness do not establish an end-to-end timing
improvement, and no derivative contract or sharper remainder follows merely
from avoiding the unused product.
