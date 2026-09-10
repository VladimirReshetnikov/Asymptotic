# Development and provenance

This directory connects current implementation work to its mathematical
hypotheses, public contracts, and validation evidence. Return to the
[documentation index](../README.md) for reader-facing and historical material.

Complete package compatibility with both the official Wolfram kernel and
[Mathics3](https://mathics.org/) is a project goal. Mathics support is currently
partial: use the [compatibility status](../Mathics/COMPATIBILITY.md#goal-and-current-status)
to distinguish implemented adapters, focused evidence, and remaining work.
Wolfram preservation checks and Mathics acceptance are separate requirements;
success on one interpreter does not establish success on the other.

The [coverage targets](COVERAGE_TARGETS.md) also require every input handled
by `Series`, `Asymptotic`, or `DiscreteAsymptotic`, and all asymptotics developed
in the vendored ProveIt articles, including q-analogs, inverses, and
combinatorial sequences. A different result representation is permitted;
incomplete coverage remains work to do. See the
[known native deviations](NATIVE_COMPATIBILITY.md) and
[vendored article coverage map](VENDORED_ASYMPTOTICS.md).

The [documentation maintenance guide](../MAINTAINING.md) gives the
source/output map, consistency checks, and build and visual-review workflow.

The maintained package and Wolfram context are named `AsymptoticAnalysis`;
the modular sources are under `src/`. Public `AsymptoticInverse` calls remain unchanged.
Saved validation records from before the rename describe their original
paths, contexts and source hashes. In particular, checkpoint `01b18ab` contains
the pre-rename 163/0 routing, 58/0 certificate and 11/0 standalone results;
these are not validation of the renamed source files.

The maintained reader-facing documentation consists of the
[mathematical article](../article/asymptotic-inverse.pdf) and the
[package user guide](../../src/Documentation/UserGuide.html).

The [code review library](../../external-reports/code-review/README.md) contains thirty-six
packages in four waves: [reports 1–9](../../external-reports/code-review/wave-1/README.md),
[reports 10–18](../../external-reports/code-review/wave-2/README.md),
[reports 19–27](../../external-reports/code-review/wave-3/README.md), and
[reports 28–36](../../external-reports/code-review/wave-4/README.md). The maintained
[code review status](CODE_REVIEW_STATUS.md) consolidates findings, links current
implementation evidence, and keeps pending repairs separate from deferred API
and research proposals. The wave indexes record each package's pinned snapshot
and distinguish executed native observations from independent models and
unrun regression specifications.
The [wave-3 intake](WAVE_3_INTAKE.md) maps that wave's 44 attributed ledger entries
and consolidates their proposals. There are 167 identified entries across
the first three waves before overlapping findings are grouped; they are not
167 distinct current defects. Wave 4's detailed intake remains pending, so its
findings are not included in that entry count. Current work implements and documents the reviewed
recommendations, with each repair tied to its own focused validation.

The [request-resolution workplan](REQUEST_RESOLUTION.md) connects W3-01–W3-03
and W3-15 through shared argument roles, effective defaults, and once-only
option evaluation. Its design and characterization matrix remain pending
implementation and native acceptance.

[Periodic peer-work reviews](PEER_REVIEWS.md) record inspections of other
worktrees and incoming `main` changes, with committed work distinguished from
pending changes and source review separated from executed validation.

The [native compatibility plan](NATIVE_COMPATIBILITY.md) records the required
input coverage of `Series`, `Asymptotic`, and `DiscreteAsymptotic`, including
formal, complex, multivariable, and discrete results. The currently implemented
native backends cover only `Series` and `Asymptotic`. Those backends and the held
`AsymptoticExpand` alias are implemented, with
[130 passed, zero failed focused checks](../../validation/native-compatibility-tests.json)
across eight selected files and unchanged sources at that pre-rename milestone.
`Automatic` now routes native specifications/options and selected representation
failures to a compatible native backend. Successful package requests retain
their existing analytic contract, cutoff and block-count semantics. The
[automatic focused runner](../../validation/CheckNativeAutomatic.wl) checks
routing, evaluation, constraints, and adjacent inverse entry paths. Complete
native coverage remains unestablished; the register and intake identify the
specific interface and correctness work being implemented.
The [native result contracts](NATIVE_RESULT_CONTRACTS.md) explain preserved
native output, held request metadata, option conflicts, and the absence of
an independently proved analytic remainder.

Report 18's certificate accuracy stall is addressed in
[InverseCertificates.wl](../../src/Kernel/InverseCertificates.wl).
The [focused certificate runner](../../validation/CheckReviewCertificateAccuracy.wl)
checks relative-aware planning, arithmetic retries, sharp root-interval bounds,
best-result retention, and the distinction between a proved enclosure and
achieving the requested accuracy.

The [assumption-context notes](ASSUMPTION_CONTEXT.md) explain how constructor
hypotheses survive coefficient queries, arithmetic and refinement, including
delayed options, nested representations and Wolfram evaluation subtleties.
The [native-series remainder notes](NATIVE_SERIES_REMAINDERS.md) distinguish
formal native order from analytic bounds and explain incoming and outgoing
logarithmic-tail policies.
The [observable Taylor notes](OBSERVABLE_INGRESS.md) distinguish returned
coefficient information, sided limiting constants, real input paths, and
the analytic hypotheses needed to transport a Taylor remainder.
The [real-coefficient notes](REAL_COEFFICIENTS.md) explain why complete
coefficients are checked after collection, including target offsets and
observables, and distinguish this check from a proof that the source is real.
The [log-power normalization notes](LOG_POWER_NORMALIZATION.md) explain why
rewriting a principal logarithm requires a recursively proved positive
monomial base and real exponents before coefficient validation. They record
W3-10's native baseline, intermediate guard evidence and preserved first-pass
failures, 207/0 focused acceptance, and the separate open periodic
coefficient proposal.
The [Fourier termination notes](FOURIER_TERMINATION.md) explain the separate
W3-13/P03 loop repair, support and complete-coefficient stopping proofs,
reproduced public budget-seven residual, and 68/0 focused acceptance.
The [equal-exponent notes](EXPONENT_EQUALITY.md) describe exact mathematical
collection before block counts, logarithmic frontier degrees and inverse
enumeration, while preserving genuinely distinct close powers.
The [composition parameter-scope notes](COMPOSITION_PARAMETER_SCOPE.md)
explain why a fixed-parameter remainder needs a new joint proof when an inner
variable captures a parameter, and when complete source replay supplies one.

## Working on a change

1. Check the [implementation register](CODE_REVIEW_STATUS.md) and the relevant
   pinned review. Reproduce the issue on the current source before treating a
   historical observation as a current defect.
2. Use the [kernel source map](../../src/Kernel/README.md) to
   locate the implementation, then update the relevant tests and contract
   notes. Preserve the distinction between formal order, asymptotic remainder,
   numerical comparison, and a quantitative certificate.
3. Select a [focused validation run](../../validation/README.md), regenerate
   affected distribution or documentation artifacts, and record exactly what
   ran. The current instruction is to skip the full package suite.
4. Commit coherent source, documentation, and validation changes together.
   Keep proposed behavior and unexecuted regression specifications labeled as
   pending until their implementation and focused acceptance are available.

Update the [user guide source](../../src/Documentation/UserGuide.md)
and rebuild its HTML for public behavior changes. Update the
[mathematical article](../article/README.md) when its hypotheses, results,
or examples change, and rebuild its PDF using the documented three-pass
procedure. Wolfram-specific evaluation subtleties belong in these development
notes or [WOLFRAM-NOTES.md](../WOLFRAM-NOTES.md).

## Historical engineering material

This directory preserves engineering material that previously appeared in
or alongside the combined article:

- [Implementation plan (PDF)](implementation-plan.pdf) and
  [LaTeX source](implementation-plan.tex): the original engineering roadmap,
  moved without changing its contents.
- [Former article chapters](article-notes/README.md): historical package, report,
  validation, and integration notes preserved verbatim from revision `2a3d75a`.

These documents describe their original milestones. Consult the current
guide for supported behavior and the [validation record](../../validation/README.md)
for the precise revision and scope of each test run. Historical validation
manifests retain their original artifact paths and hashes.

The [original reports](../../external-reports/original-proposals/README.md), their
[comparison](../../external-reports/original-proposals/COMPARISON.md), and
[Wolfram development notes](../WOLFRAM-NOTES.md) remain separate sources
of engineering history.

## Standalone package

The canonical implementation is the modular package under
`src/Kernel/`. The repository-root `AsymptoticAnalysis.wl` is a
generated distribution for HTTP `Get` and single-file offline loading.
It preserves the original module order and top-level context transitions.
Each included source carries its path and SHA-256 hash, calculated after
normalizing line endings to LF.

For remote loading, retrieve the standalone source completely with
`URLDownload` and load the resulting temporary file with ordinary `Get`.
Cold direct HTTP loading of the large
distribution intermittently produced premature end-of-file errors in
Wolfram 15.0.1, including a local gzip fixture. Downloading before `Get`
avoids that reader path and preserves sequential context changes.
The downloaded-file form uses one HTTP fetch and accepts either the current `main`
URL or a commit-pinned standalone URL. A nested HTTP convenience loader was
withdrawn after abnormal kernel exits; its earlier evidence and the reason
for withdrawal are preserved in the [validation archive](../../validation/archive/README.md).

After editing kernel sources, rebuild and commit the standalone file with
the source changes:

```powershell
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

The builder validates all dependencies before replacing the output. Unknown
file loads, dependencies outside the kernel directory, repeated or cyclic
loads, and runtime file-location dependencies require explicit review.
Strings and nested comments are ignored when checking executable loads.
The `--check` command verifies byte-for-byte freshness without modifying the
artifact. A GitHub Actions workflow runs this check and the builder tests
when relevant files change.

For focused native acceptance checks, run:

```powershell
python validation/check_standalone_loading.py
```

This checks isolated local, plain HTTP, and gzip HTTP loading, both modular
entry points,
`Needs`, explicit reloads, and a missing HTTP file in separate Wolfram
kernels. It checks stream cleanup on initial load and reload. The HTTP fixture
contains only the standalone file and records
every request. It does not run the full package suite. See the
[validation record](../../validation/README.md) for published-URL checks.
