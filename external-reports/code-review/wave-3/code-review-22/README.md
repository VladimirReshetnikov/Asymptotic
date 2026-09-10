# AsymptoticAnalysis: precision-boundary audit

The main deliverable is **article/audit.pdf**, with its complete LaTeX source in
**article/audit.tex**. It reviews VladimirReshetnikov/Asymptotic at commit
`6687962f3c858a4f93623cfc496f33e35c6763d4` and compares its architecture and
contracts with official Wolfram Language documentation.

## Results and scope

The report uses the maintained finding register, both archived review-wave
indexes, and selected original finding ledgers to delimit its contributions.
It does not claim to have independently reproduced or reread every archived
report, or verified every specialized implementation module.

**T01 — native Taylor order consumption.** The generic observable path checks
the shape of a returned native series but not its endpoint, then zero-fills
missing coefficients. A truthful short oracle for `1/(1-t)` supplies
`1+t+O(t^2)`; interpreting it as sufficient for an exclusive cubic cutoff loses
an unknown quadratic coefficient. The exact countermodel and finite coefficient
demand theorem are proved in the article. The guard candidate checks the
returned chart and endpoint before consuming the coefficients.

**A01 — coefficient-model capability.** A valid forward expansion can enter the
inverse coefficient object overload before its missing inverse model is checked.
The helper supplies a precise refusal before inverse-only metadata access. This
is a targeted delta to the existing capability discussion, not a repair of the
separately recorded stored-Power option-precedence issue.

**N01 — conditional-source routing.** A conditional complex polynomial exposes
a pre-native obstruction to the accepted automatic-coverage objective. The
current protected-source policy is documented, so this is an attributed coverage
limitation, not a violation of that current policy.

**U01 — native outcome diagnostics.** A proposed helper distinguishes failure
markers from the syntactic disappearance of native calls. It does not redefine
the documented `NativeEvaluationStatus`, and it never treats marker absence as
an analytic proof.

## What actually ran

`code/independent_checks.py` passed **940 exact-model and synthetic text-fixture
checks**, with zero failed assertions, on Python 3.13.5. Most are finite rational
coefficient-demand cases. They are not upstream package tests. The full cases
and population counts are in `evidence/independent_results.json`.

**No Wolfram package, candidate patch, regression suite, or native benchmark
was successfully executed here.** The Wolfram service returned connection
errors even for version probes. Public behavior and exact message sequences
are therefore source-predicted where indicated. The Wolfram test files themselves
remain unvalidated in a native kernel. No native performance improvement is
claimed. The PDF was compiled and visually inspected separately.

## Files

| Path | Purpose |
| --- | --- |
| `article/audit.tex`, `article/audit.pdf` | Detailed article, proofs, comparison, source citations, recommendations, and exclusions |
| `article/build.sh` | Local LaTeX build |
| `code/independent_checks.py` | Executed exact rational/sparse countermodels and synthetic patch checks |
| `code/observable_order_patch.py` | Fail-closed T01 patch emitter; does not overwrite source |
| `code/TaylorIngressRegressions.wlt` | Seven unrun T01 desired-contract tests and controls |
| `code/ReviewAdapters.wl` | Unrun A01 capability and U01 diagnostic helpers; no upstream definitions altered |
| `code/BoundaryPolicyRegressions.wlt` | Four unrun helper/policy tests, separate from T01 |
| `code/characterize.wl` | Unrun baseline observation script: twelve cases, messages, timeouts, native version/options |
| `code/run_focused.wl` | Unrun convenience driver for the T01 file only; not a release gate |
| `evidence/` | Execution scope, full independent results, novelty ledger, inspection inventory, and artifact checks |
| `LICENSE-AUDIT.txt`, `UPSTREAM-LICENSE.txt` | Scope of original audit material and upstream source excerpts |

## Reproduction

From this directory:

```sh
python code/independent_checks.py --output evidence/independent_results.json
sh article/build.sh
```

Python checks use the standard library. The LaTeX article uses ordinary TeX Live
packages, including `mathpazo`, `amsmath`, `booktabs`, `tabularx`, `listings`,
`hyperref`, and `xurl`.

To emit a candidate patch against the canonical source in your own checkout:

```sh
python code/observable_order_patch.py \
  /checkout/Asymptotic/src/Kernel/SeriesOperations.wl > observable-order.patch
```

The emitter requires adjacent exact source anchors and refuses changed,
ambiguous, or already-patched input. These anchors were compared with the
pinned connector-returned source. Automated emitter checks used a small
synthetic fixture, not a local repository clone. Review the diff in a scratch
checkout before applying it. When testing the standalone distribution,
regenerate it from the modified canonical sources; do not test an unchanged
standalone file after patching only the modular implementation.

In a fresh native kernel, first characterize the original revision:

```sh
wolframscript -file code/characterize.wl \
  /checkout/Asymptotic/AsymptoticAnalysis.wl native-observations.json
```

Then run the focused T01 tests on the intended baseline or patched entry:

```sh
wolframscript -file code/run_focused.wl /path/to/AsymptoticAnalysis.wl
```

The driver prints `TestReport`; it does not claim acceptance through a shell exit
code. Inspect every individual result. The separate policy/helper suite requires
loading `code/ReviewAdapters.wl` after the upstream package and then evaluating
`TestReport["code/BoundaryPolicyRegressions.wlt"]`. Some desired-behavior tests
are expected to fail on the unmodified source. The N01 routing proposal is not
implemented by the T01 patch or by the helper package.

The archive contains no checksum files and no upstream repository mirror.
