# Preserving inline membership assumptions

Mathics3 10.0.1 has native `Element` rules that can replace a symbolic
membership condition by an inequivalent one. For example,
`Element[Sin[a], Reals]` becomes `Element[a, Reals]`. The original condition
does not imply that `a` is real: `a = Pi/2 + I` gives `Sin[a] = Cosh[1]`.

The held analytic entry points preserve membership predicates in two
protected regions before Mathics evaluates those native rules: the value of
an inline `Assumptions` option and the condition of an inline
`ConditionalExpression` in the request. Immediate rules, delayed rules, and
literal nested option lists are covered. The option value is still evaluated
by the existing option-resolution path; the protection itself does not
evaluate it or repeat its effects.

Inside a region only an applied two-argument membership head `Element[_, _]`
is replaced. A bare `Element` symbol is caller data: a delayed option program
may compare it against a saved value to choose a branch, and rewriting it
changed which public coefficient was returned. Anything below a held-data
barrier — `Hold`, `HoldComplete`, `HoldForm`, `Defer`, `HoldPattern`,
`Verbatim`, `Unevaluated` — is left as written, and a membership predicate
outside both regions is not touched. The
[portable cases](../../validation/MathicsTests.wl)
`assumptions-protector-keeps-held-element-data` and
`assumptions-protector-rewrites-only-membership-heads-in-regions` pin these
boundaries on both kernels. The protection is not a semantics-preserving
interpreter for arbitrary option programs: a predicate generated at run time
or held by a construct outside that list is not protected.

Parameter-only clauses of an inline `ConditionalExpression`, such as `a > 0`
or `Element[Log[a], Reals]`, are parameter assumptions on both kernels; only
clauses mentioning the expansion variable are approach conditions. A
membership predicate that neither kernel can reduce to a coefficient's
realness is retained in the refusal it causes rather than dropped or rewritten.

Consequently, the strict package backend rejects a coefficient `a` under
`Assumptions -> Element[Sin[a], Reals]` when it cannot prove that `a` is real.
The same membership assumption remains sufficient for a coefficient
`Sin[a]`. Ordinary positive-parameter assumptions continue to work. Unknown
membership predicates retain an internal held head so inspecting a stored
assumption does not cause Mathics to weaken it again.

This protection applies at the package's existing held analytic boundary.
It cannot reconstruct a condition that Mathics has already rewritten in a
stored variable, a computed option container, or `$Assumptions` before that
boundary is reached. Write the original condition inline when its symbolic
membership structure matters. Other constructors that perform ordinary
argument evaluation before entering that boundary have the same limitation.

Literal explicit native backend calls retain native evaluation and their
native-result contract. A native result does not assert that the package has
proved an analytic remainder or a real branch. The official Wolfram kernel
does not load this protection and retains its original definitions and
evaluation behavior.
