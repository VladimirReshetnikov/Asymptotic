# Source and implementation notes

`fixtures/run_mathics_tests_upstream.py` is an exact copy of
`validation/run_mathics_tests.py` from VladimirReshetnikov/Asymptotic at
commit `7d1bc832895cc90a9b2a978b7b7684acab908bd2`. It is included solely to make
the runner observations reproducible. The upstream repository uses the
MIT No Attribution License, Copyright 2026 Asymptotic Contributors.

The new audit code and article in this archive are supplied under MIT-0.
The candidate ProductLog bridge is new integration code, not a redistribution
of the Mathics interpreter. An integrated Mathics distribution remains subject
to its own license. No Mathics interpreter, Wolfram kernel, or font files are
included.

Neither the Wolfram Language characterization driver nor the candidate WL
helper was executed in a Wolfram or Mathics kernel during this review.
The Python test reports explicitly distinguish runner tests, synthetic process
fixtures, and independent mathematical/bridge checks from package execution.
