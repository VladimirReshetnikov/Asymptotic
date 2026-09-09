# Real coefficients and public result boundaries

This note specifies the C07 contract in the
[code review register](CODE_REVIEW_STATUS.md#c07--apply-the-advertised-real-coefficient-contract-consistently).
It records implementation obligations, not a claim that the implementation
or native regression checks are complete. Acceptance reports belong in the
[validation record](../../validation/README.md).

## Validate complete coefficients

The ordinary power-log representation uses real exponents and polynomials
in the logarithm with real coefficients on the retained parameter domain.
Each public construction or operation must validate the complete coefficients
of its result. This includes constants, analytic forward coefficients,
regular scalar operands and composed observables; checking only the leading
coefficient of an inverse model leaves other entry paths uncovered.

Equal exponent contributions must first be collected, and their entire
coefficient polynomials simplified under the retained assumptions. Exact
resonances and coefficient cancellation precede the reality check. Inspect
every coefficient of each resulting logarithmic polynomial, including its
constant coefficient. Testing only a polynomial's leading coefficient or
its value at one logarithm is insufficient.

Temporary complex arithmetic is not itself a rejection condition. For
example, `(1 + I) x + (1 - I) x` has real collected coefficient `2`, and
`Exp[I x] + Exp[-I x]` is a real function on the real axis. A check attached
to every intermediate summand would reject valid cancellations. Conversely,
removing imaginary coefficients or applying `Re` to an unproved result would
change the represented function. A genuinely complex surviving coefficient
is outside this representation; undecidable realness also cannot establish
admission, but must not be described as a proof of nonrealness.

## Retain the proof domain and every translation

Reality is proved under the same effective assumptions retained by the
result and its nested model. A symbolic coefficient is allowed when those
hypotheses establish that it is real. Reused objects, coefficient queries
and operation recipes must not borrow a later ambient `$Assumptions` value.
See [assumption context](ASSUMPTION_CONTEXT.md) for capture, explicit-option
replacement and the neutral proof boundary.

Finite offsets and limits are part of the real-valued result. Validate a
constant block before extracting it into a target limit or translation;
normalizing the remaining coefficients does not discharge its reality
obligation. In particular, a forward expression `I + x` has a real linear
coefficient but a nonreal limiting target. It cannot define the admitted
real inverse branch merely by subtracting that limit internally. The same
coverage is needed for an offset introduced by an observable or an exact
prefactor representation. Positivity and nonzero conditions required by a
particular operation remain separate obligations from realness.

## Source reality and the resolved-coefficient theorem

[The power-log scale](../../article/sections/02-scale.tex),
`lem:real-resolved-coefficients`, proves that a real-valued function with a
finite complex-coefficient approximation and error `O[w^P M^D]` has real
complete coefficients at every resolved exponent strictly below `P`.
Taking imaginary parts and choosing a least nonzero imaginary block
contradicts power dominance. The proof assumes a fixed finite degree `D`
and an analytic tail estimate, not just a formal cutoff.

This implication has no converse. Real retained coefficients do not prove
that the original source is real: `1 + I x^100` has a real low-order
approximation. A coefficient check therefore complements the admitted
source and branch conditions; it cannot replace them. An explicitly known
nonreal term cannot be made into a real source by discarding it at a low
cutoff. Likewise, the theorem only forces real coefficients strictly below
the proved error power. Requiring all coefficients stored in the ordinary
real representation to be real is an additional representation policy.

## The proved special-function projection case

The structured special-function path may use complex intermediate
approximations with transported absolute error envelopes. If the exact
source `F` has independently been proved real on the selected approach and
`F - A = O[R]` with `R >= 0`, then `F - Re[A] = O[R]`. Taking the real part
does not increase that absolute bound. This is
`prop:special-function-real-projection` in
[the special-function chapter](../../article/sections/35-special-function-expansions.tex).

That theorem justifies a specific projection after a source-domain proof;
it is not a general conversion of complex inputs into real expansions.
Keep the original source, proof assumptions and transported envelope.
Projection alone establishes neither a real source nor cancellation of an
unknown error. The relevant source boundaries are
[special-function real domains](../../AsymptoticInverse/Kernel/SpecialFunctionRealDomain.wl)
and [structured native ingress](../../AsymptoticInverse/Kernel/NativeSpecialFunctions.wl).

## Focused acceptance obligations

The C07 reports should cover these independent cases without treating this
list as evidence that they already pass:

- Reject nonreal constants and surviving imaginary coefficients, including
  those introduced by analytic expansion or a nested observable.
- Accept complete cancellations and symbolic real coefficients under their
  retained assumptions; reject an unproved coefficient without inventing
  an assumption or narrowing the domain silently.
- Reject nonreal target offsets before inverse model normalization, and
  cover corresponding translations in operation results.
- Preserve the justified structured special-function projection path and
  its recorded source-domain proof.
- Check high-order explicit imaginary source terms and reuse under changed
  ambient assumptions, so truncation and later context cannot bypass the
  source or coefficient contract.

Primary implementation sites are the
[ordinary forward/model core](../../AsymptoticInverse/Kernel/AsymptoticInverse.wl)
and [series operations](../../AsymptoticInverse/Kernel/SeriesOperations.wl).
The review register maps C07 to review 4 R02, review 7 F04 and review 9 F04;
those findings identify audit scope rather than establish current behavior.
