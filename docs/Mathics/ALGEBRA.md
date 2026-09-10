# Bounded algebra operations for Mathics

[`MathicsAlgebra.wl`](../../src/Kernel/MathicsAlgebra.wl) supplies the specific
missing algebra operations used by the package's Fourier coefficients and
special inverse scales. The module loads only on Mathics, and its names are
resolved only by package implementation code.

The coefficient-rules adapter accepts a polynomial in one specified symbol,
given either directly or in a singleton list. It returns nonzero coefficients
as exponent-vector rules in descending degree order. This lets the inverse
Gamma and Barnes G families compute the smallest inverse-logarithmic power
of the first omitted coefficient. It preserves exact symbolic coefficients
and delegates unsupported argument forms to the interpreter.

The Fourier reader uses the usual exact exponential identities for sine,
cosine, hyperbolic sine, and hyperbolic cosine. The reverse conversion uses
Euler's identity for each exponential; its argument can be complex. These
operations introduce no assumptions about reality, sign, logarithm branches,
or the absence of poles. The package's separate Fourier conjugacy checks and
frequency budgets remain responsible for admissibility. The adapter does
not claim general trigonometric simplification.

The sequence adapter supports `Take[expression, UpTo[n]]` for a nonnegative
integer `n`, including sequences shorter than `n` and empty sequences. Core
inverse constructors use this operation to retain complete available
sectors. Other `Take` forms continue to use the interpreter.

Checking only the finite expression is insufficient for these families:
missing coefficient rules or sequence operations can leave the finite
approximation correct while damaging its recorded remainder or sector
metadata. Regression checks therefore need to inspect the relevant metadata
and reject interpreter diagnostics as well as compare exact coefficients.

The late module
[`MathicsCoreFunctions.wl`](../../src/Kernel/MathicsCoreFunctions.wl) also
normalizes package-created principal Lambert values from `ProductLog[0, z]`
to the equivalent `ProductLog[z]`. Mathics 10 lacks a numerical implementation
for the two-argument form, and its conversion to SymPy uses Wolfram's argument
order instead of SymPy's order; for example,
`N[ProductLog[0, E]]` can return `-Infinity`. The package normalizes its four
construction sites before numerical specialization, while retaining ordinary
`System` heads in the returned expressions. Native interpreter definitions
are unchanged. Symbolic nonprincipal branches remain explicit, but this
adapter does not supply their missing reliable numerical evaluation.

Nonprincipal formulas remain available symbolically, including exact
`s[value]` substitution. Applying native Mathics `N` afterward can leave some
`ProductLog` terms unresolved while producing incorrect complex values for
surrounding functions. For example,
`N[Log[-ProductLog[-1, -1/100]], 30]` produces a nonreal value in the tested
interpreter, although the real lower branch makes that logarithm real.
Evaluate such numerical formulas in the official Wolfram kernel. The package
does not replace native `ProductLog` or `N`.

The checked lower-branch core example
`AsymptoticCoreInverse[x Log[x], x^2, {x, 0}, {y, 1}]` retains the correct exact
formula at `y = -1/100`. Its `InverseNumericalCheck` returns a conservative
failure when Mathics cannot establish the recorded branch condition; it does
not report a successful numerical comparison. This one check does not
establish every nonprincipal special-inverse numerical path.
