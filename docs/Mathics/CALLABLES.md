# Callable functions and bounded inverse branch proofs in Mathics

Named and slot-based `Function` inputs use the interpreter's normal function
application. The package does not replace formal parameters textually. This
retains the interpreter's lexical binding and capture-avoidance rules,
including a named formal parameter whose corresponding global symbol has an
ownvalue.

Mathics 10 lacks the three-argument `Extract` form that the package uses to
inspect named function declarations. The adapter in
[`MathicsCalls.wl`](../../src/Kernel/MathicsCalls.wl) keeps each selected part
in `HoldComplete` during extraction and applies the requested wrapper only
after reaching the selected part. Unsupported positions delegate to the
interpreter. The adapter is selected only while compiling the package in
Mathics; the public context path and native `System` definitions are unchanged.

The late adapter in
[`MathicsInverseBranches.wl`](../../src/Kernel/MathicsInverseBranches.wl)
supplies three exact facts for a bounded class of conditional inverse calls:

- A polynomial with exact real constant coefficients is real on the whole
  real axis.
- A conjunction of affine real equalities and inequalities defines a convex
  subset of the real axis. Disjunctions, excluded points, and nonlinear
  constraints are not admitted by this convexity test.
- On a deleted interval `0 < u < r`, an affine expression is a strict convex
  combination of its values at the two endpoints. Endpoint sign proofs can
  therefore establish an inequality throughout the interval, including a
  strict inequality when one endpoint value is zero.
- As `u -> 0+`, a polynomial in `u` with real coefficients has the sign of
  its lowest-order coefficient whose sign is proved under the retained
  assumptions. An eventual approach condition that is polynomial in the
  local coordinate is therefore decided exactly, on its own arbitrarily
  small neighbourhood: `0 < x < 10^-30` and `u < a` under `a > 0` are proved,
  `u^2 - u > 0` is refuted, and a coefficient whose sign or realness is not
  proved leaves the condition unproved rather than false. Conjunctions and
  relational chains are decided clause by clause. Only nonpolynomial
  conditions still use the seven dyadic trial radii `2^-j`, whose failure at
  every radius says nothing about smaller neighbourhoods (wave-4 W4-03).
- The polynomial real-domain proof of the branch validator receives its
  retained parameter assumptions: a coefficient that is an exact real or is
  proved real under them is admitted, so `InverseFunction[Function[t, a t +
  t^3]][x]` under `a > 0` expands as in the official kernel; an unknown or
  nonreal coefficient keeps the conservative refusal (wave-4 W4-03).

The existing branch validator still checks the conditional source domain,
the target limit, the approach side, and the local derivative sign. When a
single candidate survives, a strictly signed derivative on the complete
convex domain proves uniqueness. That uses the package's existing
`"StrictMonotonicityOnConnectedRealDomain"` selection method; a finite search
alone never establishes completeness.

For example, the positive inverse germ of
`ConditionalExpression[t + t^2, 0 < t < 1]` is covered. The derivative
`1 + 2 t` is positive throughout its interval, and the branch at zero is
validated from above. In contrast, the adapter does not declare `t^2`
monotone on `-1 < t < 1`, does not treat `t^2 > 1` as a convex domain, and does
not resolve an affine inequality whose sign changes inside the deleted
interval. General `FunctionDomain`, quantifier elimination, and arbitrary
inverse branch selection remain dependent on interpreter support. Unproved
cases retain the package's structured failure.
