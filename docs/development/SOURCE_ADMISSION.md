# Source admission for analytic remainders

Register item C16 asked for the rule that decides which source expressions
may receive the package's analytic power-log remainder, as opposed to the
formal contract of a native backend. This note states the rule, the code that
enforces it, and the witnesses that pin it.

## The rule

The package analytic engine grants a `PowerLogRemainder` to a source only
through routes whose regularity it knows:

1. **Explicit jets.** `Plus`, `Times`, `Power`, `Log`, `Exp`, `Sqrt`, `Abs`,
   the Gamma/Barnes/Lerch/Zeta adapters, the parameterized special-function
   adapters with their proved real domains, the flat-sector and Fourier
   constructors, and applied or callable inverses through the branch
   validator. Each of these carries its own theorem (a jet recurrence, a
   Stirling-type expansion with a proved tail, a certified branch).
2. **The generic native jet** (`fwdSeries`), used for every other head. It
   expands a truncated Taylor series with the native `Series` and keeps the
   result only when every retained coefficient is provably real (C07) and the
   series is a genuine `SeriesData` in the local coordinate. Its analyticity
   claim is the native kernel's: `Series` expands the analytic branches of
   built-in functions (`Sin`, `BesselJ`, `Erf`, `Sinc`, ...) truthfully or
   leaves them unexpanded, in which case the route fails and the request is
   refused or delegated.

The generic native jet is therefore admitted **only for heads whose symbols
all live in the `` System` `` context** (or in the package's own contexts).
A head that involves any other symbol carries no regularity information: an
undefined `g[x]`, a derivative `Derivative[1][g][x]`, or a function from a
user context is a formal object to `Series`, which will happily produce
`g[0] + x g'[0] + ...` for a function that need not be smooth at all. A few
provably real derivatives are not a regularity proof, so such a source is
refused on the package path with `Failure["UnsupportedSourceHead", ...]`,
naming the heads. A native backend, selected explicitly or by the Automatic
search, still delegates it under its formal contract (`"Kind" -> "Native"`,
`"Remainder" -> Missing["NativeContract"]`, `"Exact" -> Missing["NotEstablished"]`).

Formal variables of pure functions (`Function[t, ...]`) are not opaque heads,
and parameters occur as arguments, never as heads, so `a x + x^3` under
`a > 0` and `InverseFunction[Function[t, t + Exp[t] - 1]][x]` are admitted
as before. A user-defined function that evaluates to built-in heads
(`h[v_] := Exp[v] + v^2`) is admitted because the package sees `Exp[x] + x^2`.

## What the rule does not claim

- It does not prove analyticity of every built-in function at every point.
  A built-in that is smooth but not analytic at the expansion point
  (`Exp[-1/x^2]` at `0`, two-sided) is not expanded by `Series` into a
  `SeriesData` with a nonzero tail, so the package route fails and the
  Automatic search delegates it natively under the formal contract; the
  one-sided request `Exp[-1/x^2]` from above is an exact exponential-scale
  forward result by its own route, not by the generic jet.
- C06's finite-logarithm allowance applies only inside package jets of
  admitted heads.
- `Abs` and `Sign` are handled by their explicit routes (the modulus on the
  real coordinate, the recorded side), not by the generic jet.

## Witnesses

[ReviewSourceAdmission.wlt](../../src/Tests/ReviewSourceAdmission.wlt) pins:
an opaque head with five assumed-real derivatives is refused on the package
path (before the gate it received `PowerLogRemainder[x, 3, 0]`); a derivative
of an opaque head is refused; the same opaque head is delegated natively
under the formal contract by the Automatic search; a sum of `Sin`, `BesselJ`,
`Erf` and `Sinc` and a pure-function inverse are expanded as before; and a
user function that evaluates to built-in heads is admitted.

Return to the [development index](README.md).
