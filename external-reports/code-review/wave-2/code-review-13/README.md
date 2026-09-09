# Asymptotic: incremental technical audit

**Snapshot:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6`  
**Audit date:** 9 September 2026  
**Observed kernel:** Wolfram Language 15.0.0, Linux x86 (64-bit), build dated 6 May 2026.

The article is in `article/asymptotic-incremental-audit.pdf`; its self-contained LaTeX source is beside it. It compares the repository with native Wolfram Language and focuses on new evidence beyond the nine prior reviews. `SOURCES.md` identifies the immutable sources and the non-duplication baseline.

## Principal results

**A1 — semantic weight grouping:** `Sinh[1]^2` and `(Cosh[2]-1)/2` are provably equal, but their separately simplified expression trees remain different. Ordinary `jetMerge` groups by the trees. This can invalidate its distinct-support invariant. Three public examples respectively return no terms for a one-term request, claim logarithmic remainder degree 3 where degree 6 is required, and exhaust an inverse-enumeration budget for an expression equal to `x^2`. Replacing the structural grouping with sorted proved-equality groups fixed all three examples in the native evaluator.

**A2 — realness:** sharpens the earlier C07 concern with public examples. Exact nonreal expressions such as `ArcSin[2]` bypass a syntactic check for `Complex` atoms. The real-inverse constructor can then return a complex inverse and nonreal target limit. These are valid complex formulas, but they violate the advertised real-domain contract. No global realness repair is included.

**A3 — numerical resolution:** a numerical inverse check returns a numerical zero whose uncertainty is much larger than the true error. An exact rational residual proves that the error is strictly positive, about `1.76072344470623091315e-51`. Wolfram retains the zero's limited accuracy; the proposal is to expose an explicit unresolved-error state. This is not a counterexample to the asymptotic remainder or to interval certification.

## What was actually validated

The pinned standalone package loaded successfully in the native Wolfram evaluator. Selected public baseline examples, the three A1 examples after the grouping transformation, and built-in comparison calls were executed. `results/native_observations.json` is a selected transcription of those observations, not a complete session log or repository TestReport.

The independent Python run passed 68 degree-pair cases with 204 family conditions, plus the exact positive-error oracle. Five Python tests passed for source-patcher guards on synthetic fixtures. These are not Wolfram repository tests.

The complete repository suite, the supplied nine-test Wolfram runner, the complete hotfix install/remove safeguards, and the numerical-wrapper prototype were **not** run against the package. No broad timing or cross-platform benchmark was obtained. No full checkout was available in the local artifact-build container. Later service/download failures are not treated as package failures.

## Reproduce the independent checks

Python 3.10 or later, standard library only:

```sh
python tests/independent_oracles.py
python tests/test_patch_tool.py
```

The first program regenerates the exact fractions, decimal oracle, and remainder-growth data in `results/`. It models how the two-pointer boundary algorithm behaves on duplicate *semantic* weights. It does not claim the kernel fails to merge literal duplicate integer weights.

## Reproduce the native regression specifications

Use a separate checkout at the pinned revision and a compatible native Wolfram installation. The runner loads that checkout's **modular** kernel; it neither downloads code nor edits the checkout.

```sh
wolframscript -file tests/run_audit.wls /path/to/Asymptotic
wolframscript -file tests/run_audit.wls /path/to/Asymptotic --semantic-fix
wolframscript -file tests/builtin_comparison.wls
```

These tests specify desired behavior. The A1 tests should fail on the audited baseline. The A2 real-domain tests intentionally remain failing after the A1 fix. Consequently, a nonzero exit after `--semantic-fix` does not by itself mean the grouping repair failed: inspect the individual TestIDs. The runner rejects a zero-test or unexpected-count run rather than calling it success.

## Two opt-in ways to try the A1 repair

### Session-local hotfix

Load the pinned package, load `code/semantic_weight_hotfix.wl`, then call:

```wl
AsymptoticAudit`InstallSemanticWeightFix[]
(* Run the focused examples or regression specifications. *)
AsymptoticAudit`RemoveSemanticWeightFix[]
```

This modifies one private symbol's DownValues in the current kernel, not files on disk. It expects one structural grouping anchor and refuses to overwrite or discard unexpected later definitions. The underlying grouping transformation was natively tested; the delivered installation/removal guards were not separately package-tested. Its anchor is not a full version fingerprint, so use the pinned snapshot.

### Hash-guarded source patch

```sh
python code/apply_semantic_weight_patch.py /path/to/Asymptotic
python code/apply_semantic_weight_patch.py /path/to/Asymptotic --apply
```

The first command is a dry run. The second edits only `AsymptoticInverse/Kernel/AsymptoticInverse.wl`, verifies the audited Git blob hash, and preserves a backup. A changed source, including line-ending conversion, can fail the guard; do not bypass it without reviewing the new source. The patcher intentionally leaves the generated root `AsymptoticInverse.wl` unchanged. Test the modular source, then regenerate the standalone distribution using the repository's own build workflow. No generator path is assumed here.

The patcher was tested on synthetic fixtures; it was not applied to a complete local checkout during this audit. It is not a universal installer and does not repair A2, A3, or unrelated earlier findings.

## Numerical diagnostic prototype

`code/reliable_numerical_check.wl` defines:

```wl
AsymptoticAudit`ResolvedInverseNumericalCheck[s, exactTarget]
```

It repeats the existing checker at increasing working precision until a positive error and ratio have enough reported digits. A numerical zero remains unresolved, including when the approximation happens to be exact; establish exactness separately. It refuses to manufacture extra target precision. Reported digits are numerical evidence, not an interval proof or a guarantee that every native solver diagnostic is sound. This wrapper was not package-tested in the audit.

## Rebuild the article

Run `./build.sh`, or run `latexmk -pdf` on the `.tex` file from its directory. A TeX installation with the New PX fonts and the standard packages named in the preamble is required. All bibliography entries are embedded in the `.tex` file; no external `.bib` file is needed.

`manifest.json` records the evidence boundary and snapshot. `SHA256SUMS` covers the distributed files except itself. Newly supplied helper code is offered under MIT-0; see `NOTICE.md`. No upstream executable package or font files are bundled.
