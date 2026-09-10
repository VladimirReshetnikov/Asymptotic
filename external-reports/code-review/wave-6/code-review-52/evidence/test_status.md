# Execution status

## Executed and returned

1. Wolfram kernel identification: 15.0.0 for Linux x86 (64-bit), May 6, 2026; SystemID Linux-x86-64.
2. Pinned standalone load: 692,381 downloaded bytes; 38 exported public-context names after loading.
3. Baseline N1: malformed numeric source and ordinary inverse target both produced GeneralizedSeries objects, with SeriesData invalid-variable messages; native Series did not evaluate the Pi-variable request.
4. Baseline N2: options-only call failed with InvalidCutoff; explicit Automatic plus the same option returned a zero formal residual below relative cutoff 2.
5. Baseline N3: plain exponential returned an exact factored expression; a true conditional wrapper returned ExponentialScale.
6. Candidate N2/N3 batch: immediate, nested, and delayed options succeeded; the delayed option counter was 1; the true conditioned exponential was exact and retained its condition in the recipe; a false condition was refused.
7. Final candidate N1 batch: two anchors matched once each; numeric source and ordinary inverse target were refused; a user-context Pi symbol and an ordinary sine control remained correct.
8. Baseline 42-case diagnostic: 41 nonexact results, one exact result, no growth-ratio flags under the stated heuristic.
9. Six local Python synthetic-fragment staging tests passed.
10. Article compiled; every PDF page was rendered, the page contact sheet inspected, and selected detail pages inspected. The final compile has no overfull-box warnings.

## Not completed or not executed

- Mathics package loading or numerical/symbolic regression execution.
- The full repository test suite on either runtime.
- A completed combined batch containing the final four edits and all proposed controls.
- A completed native refinement-replay test of the conditional candidate.
- The complete canonical-source rebuild and its modular/standalone parity validation.
- A full-text scan of every archived report. Completed text screens covered twelve retained articles, in addition to the review registers/intakes/indexes.
- Production use of candidate_patch.py on the actual full checkout in the local container; exact anchors were confirmed through native source inspection, while local utility tests used synthetic fragments.
- Execution of the newly packaged reproduce.wl file as one complete script. Its principal calls were executed in separate native batches; the full runner remains a reproducibility artifact for integration.

An initial broad variable-guard experiment did not cover the ordinary inverse target. That gap led to the explicit ordinary-constructor guard in the final N1 candidate. The initial target result is not represented as a passing fix.

Transport errors from the connected service provide no pass/fail information about the submitted package code. Numerical ratio samples provide no rigorous enclosure certificate.
