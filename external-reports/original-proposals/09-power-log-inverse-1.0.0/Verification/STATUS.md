# Verification status

The Python checks in `verify.py` were actually executed with Python 3.13.5,
SymPy 1.14.0, and mpmath 1.3.0. All 155 checks passed. Their exact list and
numerical results are recorded in `verification-results.json` and
`verification-report.txt`. The numerical calculations use 100 decimal digits;
they are floating-point experiments, not interval-arithmetic certificates.

The checks cover direct Lagrange differentiation through order 10, the Catalan
leading logarithmic coefficients, independent multivariate formal Picard
inversion and forward residuals, rational and irrational gaps, nonunit leading
powers, powers of the inverse, exact radical comparisons, exponent collisions,
weighted enumeration, and numerical residual-to-error inequalities.

The Wolfram Language source and examples received a manual audit and a lexical
delimiter check (`static_check.py`). That checker is not a Wolfram parser.

**The Wolfram Language package and its 35 MUnit regression tests were NOT
executed in a native Wolfram kernel in this session.** Both attempted calls to
the connected Wolfram context/evaluator service returned HTTP 404. There was
no local Wolfram kernel. No native test success or cross-version compatibility
is claimed. The source targets the standard language facilities available in
modern Mathematica/Wolfram Engine, and the native regression suite should be
run in the user's installation before relying on it in a larger workflow.

Run the native tests with:

```sh
wolframscript -file Tests/RunTests.wl
```

Alternatively, evaluate `TestReport[".../Tests/PowerLogInverse.wlt"]` in a
notebook. The command-line runner writes `Tests/native-test-report.wl`; this
file is deliberately absent from this release because no native run occurred.
