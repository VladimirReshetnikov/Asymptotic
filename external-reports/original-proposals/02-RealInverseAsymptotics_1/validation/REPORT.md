# Validation record — 7 September 2026

## Executed: independent mathematical implementation

`python validation/validate.py` completed successfully. The full output and
fixtures are in `results.json`; console output is in `run-log.txt`.

- Exact assertions passed: **104**.
- Numerical inverse comparisons: **11**, with mpmath precision set to **180
  decimal digits**.
- SymPy: **1.14.0**. mpmath: **1.3.0**.
- Deterministic random seed: **236367**.

The exact assertions compare the differential-operator coefficient formula
against a separately coded finite-jet composition/fixed-point implementation.
They cover both motivating examples; the finite product formula for pure
powers; mixed and resonant exponents; irrational leading powers and two
irrational increments; positive, fractional and negative observable powers;
normalized residuals; and the frontier residual sign/slope relation.
Twenty explicit random fixtures in `results.json` are mirrored in the MUnit
suite. The numerical comparisons use positive-bracket bisection and compare
the approximation error with the first omitted term. They are high-precision
computations, **not outward-rounded interval proofs**. The mathematical
convergence and remainder theorems are proved independently in the article.

## Not executed: native Wolfram package and MUnit tests

The remote Wolfram Language evaluator returned:

```json
{
  "type": "invalid_mcp_response",
  "message": "MCP SSE probe returned 404 from wolfram.com",
  "status_code": 404,
  "is_error": true
}
```

No local Wolfram kernel was available. An attempted alternative interpreter
installation also failed because network name resolution was unavailable.
Accordingly:

- The Wolfram package **has not been executed in a native kernel**.
- The supplied **95 MUnit tests are NOT RUN**, not passed.
- No supported Wolfram Language version has been experimentally established.
- No native runtime or performance measurements are claimed.

The 104 Python assertions do not test Wolfram parsing, symbol contexts,
evaluation semantics, pattern matching, option handling, or the public input
parser. Manual review and the static scan do not replace those checks. The
package is a reference implementation pending native integration testing.

Native test command, from the project directory:

```text
wolframscript -file Tests/RunTests.wls
```

Or evaluate `TestReport[".../Tests/RealInverseAsymptotics.wlt"]` in a notebook.
The file loads the package relative to its own location.

## Executed: static and document checks

`static-check.py` scans Wolfram source, test, and example files with awareness
of strings, escape sequences, and nested `(* ... *)` comments. It checks balanced
`()`, `[]`, and `{}` delimiters and unique test identifiers. Its result is stored
in `static-results.json`. This is explicitly **not a Wolfram parser or evaluator**.

The 26-page article was built with pdfLaTeX. Cross-references and citations
resolved, and the final build log contained no overfull/underfull boxes or
LaTeX warnings. All pages were rendered and visually reviewed, including the
coefficient formulas, API tables, numerical results, and bibliography.
