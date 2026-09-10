# Validation record

Build date: 2026-09-07.

## Executed

`Validation/validate.py` passed **46/46 independent checks**. Exact symbolic
work used SymPy; numerical roots used mpmath bisection, independently of the
coefficient formula. The script and `validation-results.json` record software
versions, every named check, coefficient tables, the irrational-series
convergence radius, and 27 numerical comparisons across three models,
three target values, and three cutoffs.

The checks include exact substitution, generalized Fuss-Catalan coefficients,
ordinary Catalan coefficients, mixed irrational/logarithmic support,
collisions, duplicate-generator merging, nonunit and fractional leading
powers, strict cutoff boundaries, and detection of a deliberately altered
coefficient. A separate direct ordinary-power substitution validates the
logarithmic example without the sparse residual routine.

`Validation/static_check.py` audited five Wolfram source/test/example files
for balanced brackets, associations, strings, and nested comments. It passed.
This is a lexical delimiter check, **not** a native Wolfram syntax parse.

The article was compiled using pdfLaTeX/latexmk. Its PDF was rendered and
visually inspected; final packaging excludes TeX build intermediates.

## Not executed

The 40 tests in `Tests/PowerLogInverse.wlt` have **not been run in a native
Wolfram kernel** in this build. No local kernel was available, and the
connected Wolfram evaluator could not provide a working execution service.
The supplied runner is ready for native `TestReport` execution.

Consequently, the executed tests establish evidence for the mathematics
and independent algorithms, but do not establish native-kernel compatibility
of every Wolfram Language evaluation path. The Wolfram implementation was
manually reviewed and lexically checked. Native regression execution remains
the explicit unverified part of this delivery.

## Meaning of a residual certificate

For inverse cutoff C, the checker tests whether the normalized residual
`f(A)/(a u^p)-1` vanishes at every retained relative power below C-1. It uses
a separate sparse binomial/logarithmic composition implementation. The
analytic theorems in the article connect this exact truncated-algebra
calculation to an actual inverse asymptotic under the stated hypotheses.

It is not a formally kernel-checked proof, a proof of global invertibility,
a verified floating-point enclosure, or an automatic remainder analysis
for an arbitrary external input jet. The article gives a separate explicit
slope-bound route to finite-point error enclosures.
