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
to the equivalent `ProductLog[z]`. Mathics 10 passes the two-argument form
to its numerical library in the wrong argument order; for example,
`N[ProductLog[0, E]]` can return `-Infinity`. The package normalizes its four
construction sites before numerical specialization, while retaining ordinary
`System` heads in the returned expressions. Native interpreter definitions
are unchanged. Symbolic nonprincipal branches remain explicit, but this
adapter does not supply their missing reliable numerical evaluation.
