# Novelty and exclusion ledger

Revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`.

The exclusion baseline comprises all five maintained wave indexes, the root
review index and retirement map, relevant sections of the implementation
register, and selected original review material (including report 37). It is
not an assertion that every appendix of all 35 retained articles was reread.
Code search returned no usable full-text matches for this repository. Findings
were consequently chosen at specific post-review implementation changes.

| New item | Nearest earlier obligation | What is new here | Deliberately excluded |
|---|---|---|---|
| N1: coefficient-option type corruption | C09 / report 6 A03; wave-3 option-name issues | The new C09 implementation mixes FilterRules name equivalence with literal string replacement, injecting the string `"Power"` into coefficients. Native public witness and a tested local repair. | Re-reporting the former stored-versus-explicit precedence bug or proposing another generic backend option normalizer. |
| N2: rational underflow in Mathics logarithm recovery | W4 numerical precision; report 45's exact rational **root seeds** | The newly added logarithm fallback rounds an exact rational to machine zero merely to determine its sign. | High-precision FindRoot claims, the root-seed extension, or a general new logarithm algorithm. |
| N3: numerical local-field units | C21 large-offset numerical cancellation | The new local-coordinate fields have an incorrect powered-observable label and omit an explicitly aligned local reference observable. Two native witnesses. | Claiming that large-offset cancellation is still unfixed, or that the demonstrated root/error calculations are wrong. |
| P1: candidate-list cost after grading repair | C23 / reports 15 and 17; P06 resource taxonomy | The new graded collector materializes a quadratic list of mostly dominated tail candidates. Exact count and comparison-preserving two-pass design. | Re-reporting erased exponential grade, general sparse budgets, or the already-recorded higher-grade remainder export extension. |

## Controls and rejected hypotheses

Wolfram's nested FilterRules input and delayed string option both worked. They
are controls, not Wolfram defects. Mathics 10.0.1's upstream FilterRules source
has a narrower primitive contract; public package consequences remain unrun.
The numerical metadata witnesses had correct roots and observable values.
The 45-case unmodified inverse matrix passed; it did not inspect remainders.
No new complete analytic-tail, certified-root-branch, Abs, or native-dispatch
finding is asserted.
