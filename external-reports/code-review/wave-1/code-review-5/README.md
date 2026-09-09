# Asymptotic 1.8.0 — engineering and mathematical audit

**Reviewed repository:** VladimirReshetnikov/Asymptotic  
**Pinned commit:** `07a9781212beb2eeb9ff16aa625b50ac27974078`  
**Snapshot timestamp:** 2026-09-09 19:01:30 UTC  
**Review date:** 9 September 2026

Start with **`article/asymptotic-audit.pdf`**. The complete editable LaTeX source is beside it. The article covers mathematical algorithms, native Wolfram Language comparison, seven prioritized findings, performance, API and precision contracts, certificates, validation, and staged development recommendations. An appendix records the actual source-review coverage.

## Evidence and limitations

This bundle is a source audit plus independently executed mathematical checks, **not a full repository clone or a native-tested corrected release**.

* **Executed:** 22 independent Python/SymPy/mpmath checks, all passing. Their exact results and environment are in `results/oracles.json`.
* **Executed:** 11 tests of the audit's patch/planning tools, all passing. These use a synthetic anchor fixture; they do not execute the upstream Wolfram package. See `results/tool-tests.txt`.
* **Not executed:** the native Wolfram regression suite, native comparison collector, proposed Wolfram helpers, and patched package. Native evaluation was attempted but the service was unavailable; no local native kernel was usable.

Source-traced behaviors are identified as such. Repository-reported native tests are attributed separately in the article. No fresh native timing or full-suite success is claimed.

## Main findings

| ID | Finding | Evidence |
|---|---|---|
| F01 | Eager optional `SeriesData` conversion may allocate a huge dense grid for a tiny sparse result. | Source formula; exact independent allocation-length calculation. |
| F02 | Compound observables can bypass the real-branch check for a fractional power of a pure remainder. | Source-traced; native regression supplied but unrun. |
| F03 | Newton/grouped constructor paths still enumerate Lagrange indices before choosing their inner algorithm. | Source trace; exact count of 23,025 indices for the supplied 30-block example. |
| F04 | Derived refinement's fixed guard can return order −4 after a request for order 5. | Source-traced; exact precision derivation; native regression supplied but unrun. |
| F05 | Residual normalization label omits the target offset, while the calculation subtracts it. | Source-confirmed diagnostic mismatch. |
| F06 | Mandatory logarithm canonicalization can trigger unrestricted integer factorization. | Source-confirmed resource risk, not a measured native timing. |
| F07 | Flat rates 2 and 3 are rejected although they share the primitive base 1. | Documented restriction/source check; exact lattice algorithm supplied. |

F07 is a supported-class restriction, not a wrong accepted coefficient. F04 concerns a successful request with insufficient achieved precision; the returned weak remainder can still be mathematically correct.

## Independent checks

The scripts require Python 3.9 or later. Recorded execution used Python 3.13.5, SymPy 1.14.0, and mpmath 1.3.0.

```text
python -m pip install sympy==1.14.0 mpmath==1.3.0
python code/audit_oracles.py --output results/oracles.json
python -m unittest discover -s code -p test_audit_tools.py -v
```

The mathematical script calculates the large dense-list length without allocating the list. Its numerical root comparisons and interval-tail sample checks are evidence, not interval certificates for the upstream code.

## Guarded surgical patch proposals

`code/apply_proposed_fixes.py` proposes **only F01, F02, and F05**. It does not implement the refinement redesign, Newton support planner, bounded factorization policy, or integration of primitive flat rates.

Default usage verifies the pinned canonical file and writes a diff without changing the repository:

```text
python code/apply_proposed_fixes.py /path/to/Asymptotic --output proposed-fixes.patch
```

Use `--apply` only after reviewing the generated diff:

```text
python code/apply_proposed_fixes.py /path/to/Asymptotic --output proposed-fixes.patch --apply
```

The script checks Git blob `ea9eaf4a11130e922ac4fb3faae37fd8e8d29643` for `AsymptoticInverse/Kernel/AsymptoticInverse.wl`, after normalizing CRLF to LF. It also checks exact anchor counts, refuses another revision, preserves line endings, and creates a non-overwriting backup before an explicitly requested write. It does not download or execute repository code. It has not been applied to a full local checkout during the audit.

The F01 patch uses a fixed **20,000-slot dense-export cap** as a tactical safeguard. A lazy public conversion API with its own configurable budget is the recommended design, not this hard-coded policy as a final architecture.

After applying a patch, regenerate the repository's standalone source using its builder, then execute native tests. The three small edits do **not** resolve F04, so the entire audit regression suite is not expected to become green merely by applying them.

## Native Wolfram reproduction

Set `ASYMPTOTIC_REPO` to a local checkout at the pinned commit (or its explicitly patched derivative). The package guide requires Wolfram Language 15.0 or later.

PowerShell example:

```powershell
$env:ASYMPTOTIC_REPO = 'C:\src\Asymptotic'
python C:\src\Asymptotic\validation\build_standalone.py
wolframscript -file .\wolfram\RunAudit.wls
wolframscript -file .\wolfram\CompareBuiltins.wls
```

`RunAudit.wls` loads the modular source, runs eleven audit-specific tests, records kernel identity, actual outputs/messages and module hashes, rejects empty/aborted reports, and returns a nonzero exit status on failure. `ASYMPTOTIC_AUDIT_OUTPUT` can override its default output JSON path.

`CompareBuiltins.wls` is a **case collector**, not a claim that every built-in solves every case or that all output orders mean the same thing. Compare branch, variable, scale, complete blocks and remainder before comparing expressions. Sequential timings are not per-case fresh-kernel benchmarks.

`ProposedHelpers.wl` provides a standalone primitive flat-rate lattice function and a negative-power precision-planning helper. It is not installed into the package, and it has not been native-validated.

The audit suite does not replace the repository's full native suite or its standalone/modular parity checks.

## Article build

From `article/`:

```text
latexmk -pdf asymptotic-audit.tex
```

Alternatively run `pdflatex` repeatedly until references settle. The document is self-contained: no network, external images, bundled fonts, or external bibliography database are required.

## Evidence files and licensing

`evidence/snapshot.json` records the snapshot and execution boundary. `evidence/findings.json` makes finding classifications and patch coverage explicit. `evidence/source-map.json` lists source paths and review depth. `MANIFEST.sha256` covers the delivered files other than the manifest itself.

New article/tooling material is released under MIT-0, as specified in `LICENSE`. Limited upstream code excerpts and replacement anchors remain subject to the upstream MIT license; their source and pinned revision are identified. No third-party font files or full repository source distribution is included.
