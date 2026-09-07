# Independent validation

Run `python validation/validate.py` from the archive root. The script writes
`validation/results.json` and the auxiliary table in `article/`.

The recorded run passed 93 checks, including independent coefficient reversion,
exact identities, irrational cutoffs, resonant cancellation, and numerical
residual/error comparisons. Numerical inverses are obtained using 120-digit
mpmath bisection. The reference perturbation solver uses ordinary truncated
series arithmetic separately from the coefficient-operator implementation.

The source-structure checks only inspect delimiters, strings, and nested
comments. They do not parse, execute, or formally verify Wolfram Language.

`native_wolfram_tests_executed` in the JSON is explicitly false. The 38 native
`VerificationTest` cases in `Tests/` have not run in this environment. Their
number is separate from the 93 completed independent checks.

The mathematical proofs in the article, exact symbolic checks, high-precision
numerical comparisons, and native runtime testing are distinct evidence types.
Neither numerical agreement nor delimiter balance is a substitute for a proof
or for executing the delivered package in a Wolfram kernel.
