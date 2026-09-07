# Verification status — 7 September 2026

## Executed

`verify.py` was run with Python 3.13.5, SymPy 1.14.0, and mpmath 1.3.0. All 18 checks passed; 24 numerical comparisons were recorded at 150 decimal digits. The exact mathematical cases include logarithmic blocks, irrational exponents, colliding exponents, nonunit and fractional leading powers, and mixed perturbations. Separate sparse composition checks the finite inverse formula rather than reusing it to assert a zero residual. The derivative Lagrange formula and the Catalan coefficients provide additional comparisons.

The script also checks balanced brackets, comments, and strings in the Wolfram source, loader, examples, tests, and runner. This is only a lexical check. It does not prove Wolfram parser correctness or evaluation semantics.

The high-precision root calculations use mpmath bisection and are numerical diagnostics, not interval-certified computations. Twelve diagnostics check a globally proved residual error bound for the logarithmic example. Exact coefficients and analytical error theorems are proved separately in the article.

## Not executed

The connected Wolfram tools were attempted. Both context retrieval and the language evaluator failed before computation, returning an HTTP 404 from the MCP endpoint. No local Wolfram kernel was found. Plugin discovery found no alternative installed Wolfram evaluator.

Consequently:

- The 36 tests in `Tests/RealInverseAsymptotics.wlt` have **not** been run in Wolfram Language.
- The package is a reviewed implementation with independent mathematical checks, not a native-kernel-certified release.
- No Mathematica version, runtime benchmark, native test pass count, or native output transcript is claimed.
- Running the supplied native tests is the next validation step before depending on the package in production research.

## Scope of guarantees

The asymptotic theorems in the article apply under their stated fixed-parameter hypotheses. The package does not automatically prove user-supplied differentiated input remainder bounds, compute explicit validity intervals, or supply floating-point interval certificates. Exact support ordering in the implementation is restricted to real algebraic exponents.

`verification_results.json` is the actual independent run record. `build_summary.json` records the final PDF build and visual inspection. The article identifies the source material actually inspected and the canonical repository file that the connector could not read in full.
