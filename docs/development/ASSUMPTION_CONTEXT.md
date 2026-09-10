# Assumption context and reusable results

This note specifies the C05 contract from the
[code review register](CODE_REVIEW_STATUS.md#c05--retain-every-assumption-used-to-establish-a-reusable-result).
The [user guide](../../src/Documentation/UserGuide.md#assumption-context)
describes the public behavior. Implementation and native acceptance must be
recorded separately in the [validation record](../../validation/README.md);
this explanation alone is not test evidence.

The shared `catch` boundary captures the caller context only for an outer
request, but neutralizes `$Assumptions` on every entry. The latter matters when
a delayed assumption option invokes another package function while option
resolution has temporarily restored the caller's context.

## Public contract

All nine constructors use `Assumptions :> $Assumptions`:

- `AsymptoticExpansion`, `AsymptoticInverse`, and `PowerLogModel`.
- `AsymptoticCoreInverse`, `AsymptoticExponentialCoreInverse`,
  `AsymptoticFlatInverse`, `AsymptoticFourierInverse`,
  `AsymptoticLogarithmicInverse`, and `AsymptoticSpecialInverse`.

Resolve the default or explicitly supplied option once at construction. An
explicit option **replaces** the caller's ambient assumptions; it is not
conjoined with them. In particular, `Assumptions -> True` must not borrow a sign
or equality from an enclosing `Assuming`. Nested `Assuming` scopes contribute
through the ambient value when the option is omitted. An explicitly delayed
option is also resolved once and is not saved as a thunk to be reevaluated
during refinement.

The three primary constructors separate parameter-only conjuncts from
source/approach conditions. Such variable conditions must hold eventually on
the selected real approach and remain in the appropriate retained domain.
The six specialized constructors retain their stricter parameter-only policy:
source- or target-bearing assumptions are rejected rather than silently
discarded or treated as parameter facts. Capturing the ambient value does not
change the source-domain contract of those constructors.

Operations, automatic arithmetic, normalization, refinement, coefficient queries,
residuals and numerical/certificate checks use the stored operand context.
They do not accept a new `Assumptions` option. A new ambient assumption must
neither simplify a saved coefficient nor unlock a branch or a regular scalar
operand. Binary operations combine retained hypotheses and enforce compatibility.
Additional hypotheses belong in a new construction, with their consequences
recorded there.

## Capture first, prove under a neutral ambient context

The caller's `$Assumptions` must be captured **before** entering a neutral proof
boundary. Capturing it after an unconditional `Block[{$Assumptions = True}, ...]`
loses the default context. Conversely, merely saving it while leaving it active
allows an explicit replacement option to borrow facts that it did not declare.
Use a held boundary where needed to control this ordering, and pass the resolved
context explicitly into the internal construction.

Within package proof and simplification work, ambient `$Assumptions` is neutral.
Predicates that intentionally depend on the selected context receive it
explicitly. Bare canonicalization, contradiction checks, branch selection,
native asymptotic calls, and fallback paths must not escape that boundary.
The stored context also governs internal calls reached through public arithmetic
or specialized entry points; wrapping only the two primary constructors is
insufficient.

Do not establish the context by simplifying its predicate under itself. For
example, simplifying `a > 0` with the hypothesis `a > 0` yields `True`, which
does not preserve the condition needed by `Sqrt[a^2] == a`. Retain the effective
predicate under neutral ambient assumptions; use it as a premise for other
proofs. A structurally different but unconditionally equivalent representation
is acceptable. Deleting a needed hypothesis because it was locally available
is not.

Helpers such as `canon`, `compare`, and generic coefficient normalization may
invoke symbolic simplification without an explicit context parameter. Neutral
execution prevents ambient leakage, but a helper that genuinely needs retained
parameter hypotheses must receive them deliberately. Avoid restoring the
caller's ambient state merely to make such a proof succeed.

## Models, nested representations, and replay

Every representation subsequently used as mathematical input must carry the
effective hypotheses, not only the outer display object. Relevant paths include
`"Model"`, `"SeriesRepresentation"`, `"FlatRepresentation"`, `"CoordinateSeries"`,
`"AdapterOptions"`, and `"ComputationState"`. Source and target domains retain
their own meaning and must survive coordinate substitution and reconstruction.

`PowerLogModel` returns a reusable association. Its `"Assumptions"` field must
retain the parameter hypotheses used to normalize its coefficients.
`InverseExpansionCoefficient` must inherit them for both the model and series
overloads; passing `True` to the coefficient calculation or dropping the series'
context when selecting its model loses information. A legacy raw model without
an assumptions field may conservatively use `True`; no missing hypothesis can
be reconstructed from a later ambient context.

Refinement has two paths: reuse stored state, or replay a source/operation.
Both use the original hypotheses. An internal call to a public constructor must
pass the already resolved assumptions explicitly and run under the neutral
boundary. It must not capture the assumptions of the user who happens to request
more coefficients later. The same rule applies to certificate seed refinement
and Gamma/Barnes observable reconstruction.

Cache correctness depends on this fixed context. The request-local inverse
syntax/branch cache keys already include their explicit assumptions. Incremental
inverse states and refinement signatures also include assumptions, and the
logarithmic coefficient builder captures a constructor-local context. Keep these
keys and closures aligned with the effective context. A context change requires
newly justified state; relabeling cached coefficients is insufficient.

## Evaluation and mathematical limits

The package does not snapshot the Wolfram evaluator. `OwnValues`, `DownValues`,
explicit `Simplify` performed by the caller, delayed user definitions, and later
symbol assignments retain ordinary Wolfram semantics. Already evaluated input
cannot be restored to its earlier form. Parameters and source/target symbols
should remain unassigned while manipulating symbolic results.

Pass-through accessors retain their existing purpose: `Normal[s]` returns an
ordinary expression, property lookup retrieves stored data, and `s[value]`
substitutes into the finite approximation. Formatting must preserve the held
object without creating new proof claims. The finite derivative formula returned
by `PerturbativeInverse` is likewise not a reusable asymptotic certificate.

Retaining a parameter domain records **where a theorem applies**. It does not
make an asymptotic estimate uniform over that domain. Error constants and
neighborhood sizes may depend on each fixed parameter. Uniform parameter limits,
especially near a vanishing leading coefficient or a changing branch, require
additional mathematics. See the article's parameter-domain discussion in
[refinement by complete weight layers](../article/sections/25-refinement-state.tex).

## Focused regression obligations

The bounded regression file
[ReviewAssumptions.wlt](../../src/Tests/ReviewAssumptions.wlt)
is the starting point. Acceptance should cover:

- Positive, negative and nested ambient constructor contexts; explicit replacement
  and explicit `True`; a delayed option evaluated exactly once.
- Separation of source conditions in primary constructors and conservative
  rejection in specialized constructors, including inherited conditions.
- Saved forward/inverse refinement, observables, scalar operands and automatic
  arithmetic under later conflicting equalities or sign assumptions.
- Specialized routes and every nested representation consumed by later work.
- `PowerLogModel` and both coefficient-query overloads retaining their premises.
- Direct property access, exact results and held normalization preserving their
  pass-through behavior without adding a new assumption option.

Compare mathematical expressions under explicit test hypotheses in a neutral
ambient context. Check stored predicates for logical equivalence, not a preferred
printed ordering. A test that evaluates both expected and actual expressions
under the same leaked ambient assumption can conceal the defect.
