# Validation record

Date: 2026-09-07. Release: 1.0.0.

| Layer | Result | What it establishes |
|---|---|---|
| Independent symbolic mathematics | PASS: 19 grouped checks | Exact coefficients, truncated residual composition, selected fixed-point cross-checks, collisions, scaling, Catalan identities, corruption detection |
| High-precision numerical comparisons | PASS: 27 cases | Agreement at selected positive arguments; not interval-certified accuracy |
| Wolfram source lexical checks | PASS: 6 files | Balanced delimiters and closed strings/comments only |
| Native Wolfram execution | NOT RUN | The available evaluator failed; there is no native-runtime correctness claim |
| Native regression tests | 34 cases supplied | Reproducible expected tests; no fabricated pass/fail report |
| PDF build | PASS: 22 pages | pdflatex build, resolved cross-references, no overfull-box warnings |
| PDF visual inspection | Completed | All pages rendered and inspected for layout; mathematics also checked independently |

Independent versions: SymPy 1.14.0; mpmath 1.3.0.
Numerical computations used 110 decimal digits.

## Reproduction

Run `python validation/reference_validation.py` to regenerate `results.json`.
Run `python validation/check_wolfram_source.py` to regenerate static checks.
Run `TestReport["Tests/RealLogPowerInverse.wlt"]` in a genuine Wolfram kernel
for the native tests. The intended Wolfram version floor in PacletInfo is a
target, not a tested compatibility assertion.

## Branch/error distinction

The asymptotic expansion is for the positive-real germ at zero. The explicit
majorant at an arbitrary point bounds error relative to the unique positive
root in its reported disk interval, selected by the auxiliary-parameter
homotopy. Equality with a particular global continuation requires an
independent branch argument. The two original forward functions are globally
strictly increasing on the positive axis, so that issue does not arise there.

The symbolic majorant is a rigorous conditional inequality. Its numerical
evaluation is not an outward-rounded interval enclosure. Residual vanishing
is an exact finite algebraic check, not by itself a numerical error certificate.

## Repository inspection

Orientation/status README files and targeted excerpts were read at commit
24ce8bd743eaab64a91ce90725ea00f498d319d2. The oversized consolidated TeX source
was not available in full through the connector. The article discloses this
and proves every result on which this package depends.
