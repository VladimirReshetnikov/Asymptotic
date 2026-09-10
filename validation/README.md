# Review and validation record

This page preserves evidence from individual source snapshots. A historical
passing count does not validate today's checkout. The project-wide
[coverage targets](../docs/development/COVERAGE_TARGETS.md) remain open;
consult the [native deviations](../docs/development/NATIVE_COMPATIBILITY.md),
[Mathics status](../docs/Mathics/COMPATIBILITY.md), and
[vendored article coverage](../docs/development/VENDORED_ASYMPTOTICS.md)
for known implementation and acceptance gaps.

| Task | Current instructions |
| --- | --- |
| Check documentation sources and generated artifacts | [Documentation maintenance](../docs/MAINTAINING.md) |
| Select a Wolfram regression check | [Focused checks](#choose-a-focused-check) and [test guide](../src/Tests/README.md) |
| Compare Mathics and Wolfram behavior | [Mathics compatibility](#mathics-compatibility) |
| Rebuild the standalone distribution | [Standalone source and freshness checks](../docs/development/README.md#standalone-package) |
| Interpret a saved result | [Evidence by scope](#read-the-evidence-by-scope) |

## Wave-4 integration and merged artifacts

The first [runner-integrity check](wave4-runner-integrity-tests.json) passes
**32/32 Python tests**, including 18 new cases, with no skips and two unchanged
source hashes. `run_mathics_tests.py` now accepts deadlines only in
`(0, 86400]` seconds, preserves lexical executable paths for virtual-environment
launchers, keeps every observed source mismatch invalid after restoration,
and protects both report and `.tmp` paths from aliasing fingerprinted inputs.
The first mismatch hashes remain in `FirstObservedSourceDriftSHA256`.
Tests include actual symlinks/hard links, a temporary venv-only import and
owned-descendant timeout cleanup on Windows. They do not load Mathics or
Wolfram. Package inputs still remain live; unseen between-checkpoint changes,
complete dependency/copy coverage, output byte limits and interrupted-attempt
records remain open in the intake.

The [wave-4 intake](../docs/development/WAVE_4_INTAKE.md) maps all 64 new
identified entries and the unnumbered proposals. Its
[crosswalk audit](wave4-intake-crosswalk.json) verifies every local ID against
the original ledgers; the [payload audit](wave4-payload-provenance.json)
verifies all 180 supplied files against arrival `8cb9b7f`. These are static
intake/provenance checks, not package runtime acceptance.

The wave-4 integration merges `origin/main` through `38aa253`, preserving the
Fourier recurrence repair and the incoming public-help corrections. The
[merged loading receipt](wave4-merge-loading-tests.json) records **105/0** in
five fresh Wolfram kernels, with 61 unchanged input hashes and no local HTTP
server. Seven receipt-summary tests and sixteen acceptance-verifier tests
pass separately; these are Python tooling checks, not Mathics feature runs.
The [merged PDF build](wave4-merge-pdf-build.json) records three serial strict
LaTeX passes over 32 unchanged TeX files. Its [layout record](wave4-merge-pdf-layout.json)
records all 102 pages rendered, visual inspection of pages 1–6 and 67–72 plus
full page 68, and no text outside page bounds. Earlier repair receipts retain
their exact historical inputs; the full package suite remains skipped.

The later documentation-only integration through `9b83d04` retains those
61 loading inputs, all 32 TeX inputs and the same PDF hash. It resolves the
overlapping wave-4 navigation edits against the completed intake, retains
the refined Mathics numerical/symbolic limitations, and passes the three
new maintained-text encoding tests. The earlier incoming layout receipt
below keeps its own historical scope; it is not a replacement for the
current wave-4 merge artifact record.

## Fourier composition stops before unused products

The [four-file native run](fourier-termination-tests.json) passes **68/68**
on Wolfram 15.0.1: 19 new [termination tests](../src/Tests/ReviewFourierTermination.wlt),
22 Fourier regressions, 11 Fourier convolution/refactoring checks, and 16
ordinary recurrence controls. All 61 recorded input hashes stayed unchanged.
The [17-observation baseline](fourier-termination-baseline.json) matches
the 55-module snapshot at `cc1b06c`; the [same probes after the fix](fourier-termination-after-fix.json)
preserve genuine resource failures while repairing the terminating cases.
Both probe runs check source and probe immutability and record no timeouts.

The public residual witness now succeeds with an explicit `"MaxTerms" -> 7`
and reports empty residual blocks below relative cutoff six. Its baseline
failed while forming an unnecessary square with ten retained pairs; the
required quadratic composition uses six retained pairs. These exact counts
and the availability repair do not establish a general timing improvement.
See [the Fourier termination note](../docs/development/FOURIER_TERMINATION.md)
for complete-coefficient identities, positive-valuation stopping, and the
distinction from the earlier ordinary-engine P03 repair.

The [loading check](fourier-termination-loading-tests.json) passes **105/105
in five fresh kernels**, with 21 cases in each local standalone, modular,
`init.m`, `Needs`, and paclet mode. It records 61 unchanged input hashes and
starts no HTTP server. The updated 55-module standalone matches its sources.
The full package and Mathics feature suites remain skipped.

The [article build](fourier-termination-pdf-build.json) records exactly three
serial strict LaTeX passes, all 32 TeX hashes and the final 102-page PDF.
The [render record](fourier-termination-pdf-layout.json) records all pages
rendered, zero text-outside-page findings, and visual inspection of pages
1–6, 61–72, and 97–102 on contact sheets plus full page 68. Other pages were
rendered but not visually inspected at this checkpoint. The
[artifact audit](fourier-termination-artifacts.json) checks current input
and PDF equality and preserves the preceding logarithm milestone against
its committed revision rather than relabeling its receipts as current.

## Principal-logarithm normalization and positive nested bases

The [eight-file native run](log-power-normalization-tests.json) passes
**207 tests with zero failures** on Wolfram 15.0.1, including 21 dedicated
[logarithm regressions](../src/Tests/ReviewLogPowerNormalization.wlt).
All 65 input hashes remain unchanged during the run. The recursive proof
accepts positive monomial bases and real exponents at every nesting level,
including reciprocal source coordinates at infinity. Unsupported winding
remains visible to the parser and receives the caller's structured refusal.
The [development note](../docs/development/LOG_POWER_NORMALIZATION.md)
separates the source-identity obligation from coefficient reality and the
still-open periodic coefficient constructor.

The [first pass](log-power-normalization-first-pass.json) records 201 passes
and two failures against the earlier implementation in `a76c0b5`. One exposed
the nested reciprocal-base gap. The other was an old automatic-backend test
whose blanket inexact-input refusal no longer matched native delegation.
That check now selects the package backend explicitly, and a separate
automatic/native comparison verifies the supported route. The
[seven follow-up observations](log-power-normalization-followup.json) retain
the actual unsupported chart and a representative inexact-input comparison;
they are characterization evidence rather than acceptance.

The [13 baseline observations](log-power-normalization-baseline.json) refer
to `41ac72d`; the [13 after-guard observations](log-power-normalization-after-guard.json)
refer to the first two-pattern repair preserved in `290f1af`. They distinguish
the wrong finite depth and flat expressions from the exact-core admission
issue, whose finite expression retained its winding logarithm.

The [local loading run](log-power-normalization-loading-tests.json) passes
**100 checks in five fresh kernels**, covering isolated standalone, modular,
`init.m`, `Needs`, and paclet loading. It records 61 unchanged input hashes,
20 checks per mode, and no local HTTP server. The 55-module standalone matches
its sources. All 14 standalone-builder tests and the six incoming Mathics
summary tests also pass; no full package or Mathics feature suite was run.

The [article build](log-power-normalization-pdf-build.json) records exactly
three serial strict LaTeX passes. The final **102-page PDF** has no unresolved
references or overflowing boxes. The [render record](log-power-normalization-pdf-layout.json)
records all 102 rendered pages and visual inspection of contact pages 1–12,
25–30, 37–42, and 91–102, plus full page 40. Other pages were rendered but
were not visually inspected in this checkpoint. The final source and artifact
checks are recorded in [the hash audit](log-power-normalization-artifacts.json).

## Observable Taylor information, approach sides, and real arguments

After the final sync through immutable `main` revision `b4c2a2d`, the
[repeated six-file native run](observable-ingress-main-sync-tests.json)
again passes **131/131**. This revision adds the guarded Mathics input-assumption
adapter and a 55-module standalone. These new source hashes distinguish the
latest acceptance from the earlier 54-module records below.
The [repeated local loading run](observable-ingress-main-sync-loading-tests.json)
also passes **95/95 in five fresh kernels**. All 63 focused-test input hashes
and 61 loading hashes match the final committed package and harness files.
The final guide is fresh, and the documentation checker passes across 47
maintained Markdown pages with no broken local links or mathematical references.

The [six-file native acceptance](observable-ingress-tests.json) passes
**131 tests with zero failures**, including 29 new cases in
[ReviewObservableIngress.wlt](../src/Tests/ReviewObservableIngress.wlt).
The run uses sources incorporating immutable `main` revision
`7d1bc832895cc90a9b2a978b7b7684acab908bd2` and verifies source immutability.
The [contract notes](../docs/development/OBSERVABLE_INGRESS.md) explain returned
Taylor order, logarithmic boundary degrees, sided constants, exact points,
and complete-argument reality. This focused selection preserves nearby unit
precision, coefficient cancellation, recurrence and coordinate/calculus cases.

The [nine-observation baseline](observable-ingress-baseline.json) describes
unchanged `a55df16` sources. The [complex-input first pass](observable-reality-first-pass.json)
describes a later intermediate implementation with separate source hashes;
it reproduces a wrong real result from a complex inner path. Neither record
is a passing acceptance suite. The repair's real-axis-only provider test
also establishes an independent constant-error witness when an imaginary
displacement is discarded from the retained inner jet.

The [local loading record](observable-ingress-loading-tests.json) passes
**95 checks in five fresh kernels**, covering the isolated standalone,
modular entry, `init.m`, `Needs` and paclet loading, including reloads and
the sided observable case in each mode. The merged standalone contains
54 modules; native loads keep the Mathics adapter definitions inactive.

The 14 standalone-builder, 14 portable-runner, three native-capture isolation,
and five documentation-link Python tests pass. An initial invocation used
the nonexistent pattern `test_run_mathics_tests.py` and ran zero tests; the
corrected `test_mathics_runner.py` invocation supplies the 14-test result.
These tool tests do not establish Mathics feature acceptance. The full
package suite remains skipped.

The documentation-only merge through `699a9739` left every
recorded input unchanged: all 62 focused-test hashes, 60 loading hashes and
32 TeX-source hashes matched commit `34d9287`. The original baseline's
53 kernel hashes independently match `a55df16`. At that checkpoint the generated guide
matched its Markdown/CSS sources; the documentation checker validated 45
maintained Markdown pages, 1,631 local links, 210 fragments, and 331 mathematical
labels with no missing references. The two coverage-index links missing in
the earlier incoming commit resolve after the latest merge.

The [merged PDF build](observable-ingress-merge-pdf-build.json) records exactly
three serial strict LaTeX passes and the final 100-page artifact. The
[render record](observable-ingress-merge-pdf-layout.json) records rendering of
all pages, zero text-outside-page geometry findings, and visual inspection of
contact pages 1–12, 43–54 and 97–100 plus full page 47. Other pages were rendered
but were not visually inspected in this checkpoint. The earlier
[99-page build](observable-ingress-pdf-build.json) and
[layout record](observable-ingress-pdf-layout.json) belong to the pre-merge
article. Both build histories retain their own source and artifact hashes.


## Documentation quality and coverage register

The [102-page merge-layout record](documentation-merge-layout-2026-09-09.json)
identifies the article retained in merge `38aa253`: all 32 TeX inputs and the
PDF are unchanged from `9f8f434`. It preserves three successful strict LaTeX
build logs, geometry diagnostics, source hashes, and the corrected contents
page. Every page is covered by visual review: pages 1–6 were reinspected
after widening the subsection-number column, while pages 7–102 have identical
rendered bytes to the preceding complete review. This is document-build and
layout evidence, separate from package execution.

The [39-check example run](documentation-help-merged-examples-2026-09-09.json)
and [100-check loading run](documentation-help-merged-loading-2026-09-09.json)
belong to the earlier `9f8f434` merge inputs. Their source hashes distinguish
them from the recursive logarithm changes merged subsequently in `38aa253`;
they do not establish runtime acceptance of those later definitions.

The [public-help consistency pass](documentation-help-2026-09-09.json) corrects
seven usage messages and the corresponding guide descriptions: positive
target coordinates, stored expressions and missing properties, report
associations, source observables, certificate planning, individual coefficient
contributions, and sided Taylor contracts. Only help strings changed in the
kernel. The regenerated standalone package passes [95 local loading and reload
checks in five fresh Wolfram kernels](documentation-help-loading-2026-09-09.json).
This pass also repairs reproducible Mathics receipt hashing and the documented
summary command, preserving historical runtime hashes and outcomes. It does
not rerun the full package suite or establish new Mathics runtime acceptance.

The [merged documentation receipt](documentation-deep-review-2026-09-09.json)
incorporates `origin/main` through `41ac72d`, including observable admission
and held Mathics membership assumptions. The [merged example run](documentation-examples-2026-09-09-merged.json)
passes **39/39** with unchanged source hashes during execution. Both HTML
references were regenerated and checked in desktop and narrow browser layouts.
The 101-page article completed three strict LaTeX passes without overflowing
boxes or unresolved references; every page was rendered and visually reviewed.
The Gamma polynomial equation now stays on one page. Source hashes, retained
build logs, and representative browser screenshots distinguish this review
from the earlier 99-page and 100-page artifacts.

The [deeper example pass](documentation-examples-2026-09-09-premerge.json)
passes **39/39 selected checks in Wolfram 15.0.1** against the recorded
pre-merge source hashes based on `699a973`. It retains the previous 31
worked-example checks, derives the public API inventory dynamically (currently
38 usage symbols), and adds seven native routing, cutoff, and optional-export
checks. The runner checks load success, complete execution, source stability,
and receipt export separately. These are selected documentation examples;
they do not establish full package or Mathics acceptance.

The [initial run](documentation-examples-2026-09-09-initial.json) records
38 passes and one incorrect new expectation: literal complex input is refused
as `InexactInput` before the later `UnprovedRealCoefficient` check. Only the
expectation changed. The [initial runner source](documentation-deep-review-2026-09-09/CheckDocumentation-initial.wl)
is preserved with its matching hash. The result properties reference is a
separate constructor-source audit; it does not claim executable coverage of
every property row.

The [September 9 documentation receipt](documentation-quality-2026-09-09.json)
records the source and artifact hashes for the documentation-quality milestone.
It covers the unified three-goal register, the full 48-root vendored source
index, native and Mathics status, regenerated HTML, and the rebuilt mathematical
article. The source audit incorporated `main` through `7d1bc83`, including the
explicit native rule-goal repair, concurrent Mathics evaluator notes,
empty-list adapter, and frozen native-definition capture script.

The 99-page article completed three serial strict LaTeX passes with no
overfull/underfull boxes or unresolved references. All pages were rendered
and visually reviewed in contact sheets; changed and dense pages were also
inspected at full size. The guide was checked in a browser at 1440-pixel and
390-pixel widths, including the coverage matrix and long function names.
The receipt distinguishes those visual checks from automatic geometry and
link validation and retains the build logs and representative screenshots.

The expanded documentation checker automatically includes new maintained
notes and review-wave indexes, checks Markdown and raw-HTML links/images and
section fragments, and preserves imported report bodies and six historical
engineering files. Five parser/discovery regressions pass. This milestone
does not run a Wolfram or Mathics package suite, prove new mathematical results,
or establish completion of any of the three package-coverage goals.

## Mathics compatibility

### Mathics wave-4 hardening

The initial wave-4 checkpoint `526e561` contains 56 modules. Its standalone is
677,685 bytes, SHA-256
`2490e5c82993cd69b9f6463fc73228915fd754a4748101fc42e392ddd6490820`.
That checkpoint's portable suite has 107 cases. The new work addresses
empty-list lookup cache corruption, incorrect exact nonprincipal Lambert
simplification, unsupported numerical precision, and false-positive harness
results after failed loading or observed source drift.

The focused [modular](mathics-modular-wave4-tests.json) and
[standalone](mathics-standalone-wave4-tests.json) runs each retain six successes
and one failure in a new fixture whose unqualified `RootReduce` did not select
the Mathics adapter. Explicitly qualifying that test's `System` symbol fixes
the dispatch, and the [modular correction](mathics-modular-wave4-proof-tests.json)
and [standalone correction](mathics-standalone-wave4-proof-tests.json) each
pass on identical package bytes. The original failures are preserved.
The official-kernel controls subsequently found an empty-list lookup oracle
mismatch: `Lookup[{}, key, default]` evaluates the default once, treating the
empty list as an empty rule collection. The first Mathics fixture expected
list-of-associations mapping. The subsequent adapter correction treats the
empty first list as an empty rule collection and shares one lazy default
across every missing result of a call;
the first focused Mathics pass is not a claim of parity for that case.
The four numerical contracts cover an exactly verified integer root, explicit
30-digit refusals for rational and irrational noninteger roots, and a successful
10-digit request. This is focused evidence, not a complete 107-case run.

The [numerical characterization](mathics-numerical-precision-audit.json)
separately retains the original machine-root/high-precision-label defects and
the isolated candidate checks on frozen `cc1b06c` sources. It includes an
initial invalid cutoff fixture excluded from conclusions.

The [Mathics loading check](mathics-loading-gate.json) and
[official loading check](mathics-wolfram-loading-gate.json) each pass 7/7:
five incomplete loaders are rejected before the builtin-only assertion,
and both real entry points pass. They identify the exact pre-fixture-correction
suite hash and unchanged package bytes. Run them with:

```text
python validation/check_mathics_loading.py --python .venv/mathics/Scripts/python.exe --output loading-gate.json
python validation/check_mathics_loading.py --wolfram wolfram.exe --output wolfram-loading-gate.json
```

The new [native definition comparison](mathics-wave4-native-definitions.json)
against immutable `cc1b06c` passes for all 2,060 modular and 2,059 standalone
symbols, every compared definition field, load/reload checks, six monitored
System builtins, and eight behavior probes. It tests the actual integrated
56-module candidate. Ambient CURL/OAuth startup contexts are reported
separately. This is separate from the original full Wolfram suite below.

All 50 Mathics-tool unit tests and all 14 standalone-builder tests pass.
These cover harness integrity and generated loading isolation, rather than
additional mathematical feature inputs. The Linux workflow now runs the
loading integration once and permits all ten independent portable shards
to run concurrently; each case retains its own process deadline.

After merging upstream `1a183a8`, the package also includes the independently
reviewed Fourier termination repair and current public help. The updated
standalone has 56 modules, 679,426 bytes, SHA-256
`13319a269729d01cf10180394d9fcd2abf9ec9e5237e761874ab967eed4320ce`.
The suite has **108 cases**, including the shared-default contract and the
corrected empty-rule-collection expectation. The expanded load gate rejects
aborted loads and registered packages without required definitions, while
accepting a fully loaded wrapper that returns a non-`Null` value. It has
11 integration fixtures: eight rejections and three successful controls.
All 66 merged Mathics-tool tests and 14 builder tests pass. Focused paired
kernel checks and the next complete Linux acceptance run are recorded
separately as they finish; the earlier checkpoint receipts remain unchanged.

### Earlier full and focused compatibility evidence

The [Mathics compatibility guide](../docs/Mathics/COMPATIBILITY.md) records
installation, exact proof boundaries, evaluator differences, and tested
features. The portable suite runs each case in a fresh Mathics or official
Wolfram kernel; it checks exact coefficients, remainder metadata, source
immutability where relevant, and explicit failure contracts. Two callable
cases deliberately record different runtime contracts because Wolfram
evaluates their `InverseFunction` before package dispatch.

The complete [Linux acceptance record](mathics-linux-ffe08b1-acceptance.json)
verifies **101/101 cases in each layout** at immutable commit
`ffe08b18ea2a6a72546503b135b47b4979e7d010`. All ten jobs of
[workflow 34430399328](https://github.com/VladimirReshetnikov/Asymptotic/actions/runs/34430399328)
succeeded; the [captured workflow response](mathics-linux-34430399328-workflow.json)
records its exact head and job conclusions. The downloaded raw shards are preserved under
`validation/mathics-linux-34430399328/`. Every maintained case occurs exactly
once per layout, with successful raw protocol and exact source/suite/runner
hashes. Later upstream logarithm repairs have separate focused and native
checks; this full run remains tied to its original source.

The [public API inventory](../docs/Mathics/API-COVERAGE.md) maps all 38 exports
to representative cases. The [receipt summary](mathics-test-coverage.json)
records **101 distinct cases with successful Mathics evidence in each layout,
across three explicitly identified package snapshots**. The maintained suite
contains 101 cases. The [Wolfram preservation audit](mathics-wolfram-preservation.json)
also reports controls for all 101 expectations across separate batches;
per-case Wolfram execution receipts for those batches are not published here.

| Snapshot | Modular evidence | Standalone evidence |
| --- | --- | --- |
| 53 modules | [Full 77-case run](mathics-modular-tests.json): 76 passes, one exact-normalization failure; [corrected assertion](mathics-modular-normalization-tests.json): 1 pass on identical package hashes. | [Full 77-case run](mathics-standalone-tests.json): the same 76/1 result; [corrected assertion](mathics-standalone-normalization-tests.json): 1 pass on identical artifact bytes. |
| 54 modules, empty-list mapping protection | [13 additional cases](mathics-modular-api-tests.json), all pass. | [13 additional cases](mathics-standalone-api-tests.json), all pass. |
| 55 modules, held inline-assumption protection | [8 additional cases](mathics-modular-final-api-tests.json), all pass. | [8 additional cases and 5 repeated loading checks](mathics-standalone-final-tests.json), all pass. |
| Same 55-module snapshot, retained refinement | [3 additional cases](mathics-modular-refinement-tests.json), all pass. | [3 additional cases](mathics-standalone-refinement-tests.json), all pass. |

The first failing fixture used `Expand` where Mathics required `Simplify` to
recognize the same exact zero. Its corrected oracle also passes the untouched
Wolfram package. The summary preserves the original failure and counter values;
it does not rewrite either full run as 77/77 or claim one full 101-case run on
the last snapshot. The complete Linux record above is separate from this
historical Windows aggregate.

Regenerate that explicitly scoped summary with:

```text
python validation/summarize_mathics_tests.py --reconcile validation/mathics-modular-tests.json validation/mathics-modular-normalization-tests.json --reconcile validation/mathics-standalone-tests.json validation/mathics-standalone-normalization-tests.json --supplemental validation/mathics-modular-api-tests.json --supplemental validation/mathics-standalone-api-tests.json --supplemental validation/mathics-modular-final-api-tests.json --supplemental validation/mathics-standalone-final-tests.json --supplemental validation/mathics-modular-refinement-tests.json --supplemental validation/mathics-standalone-refinement-tests.json --output validation/mathics-test-coverage.json
```

Reconciliation requires identical package hashes and successful targeted
corrections for every original failing case. The summarizer rejects incomplete,
drifting, or inconsistent receipts and retains the distinct supplemental
snapshots. [Focused tests](test_mathics_summary.py) check these evidence
boundaries, relative modular paths, line-ending comparison, and protection
against overwriting an input receipt. Raw receipts are exempt from Git newline
conversion: `ReceiptSHA256` identifies their exact captured bytes. The separate
`NormalizedReceiptSHA256` hashes CRLF-to-LF-normalized bytes for comparison.
Embedded runtime source and suite hashes remain the exact historical
fingerprints and are not normalized retroactively.

```text
python -m pip install -r validation/requirements-mathics.txt
python validation/run_mathics_tests.py --timeout 300
python validation/run_mathics_tests.py --source AsymptoticAnalysis.wl --timeout 300
python validation/run_mathics_tests.py --wolfram wolfram.exe
python -m unittest discover -s validation -p test_mathics_runner.py
python -m unittest discover -s validation -p test_standalone.py
```

Use Python 3.11 in an isolated environment for Mathics; `--python` selects its
interpreter when the runner itself uses another Python. `--list` enumerates
cases and `--case` or `--group` selects focused runs. JSON reports include
source hashes, exact actual/expected output, diagnostics, process timeouts,
and the explicit Mathics iteration setting. Incomplete or changed-source
runs are not acceptance records.

[mathics-wolfram-preservation.json](mathics-wolfram-preservation.json) keeps
full original-suite outcomes and native symbol-definition comparisons
separate. It records the unchanged original 1,452 passes and 12 failures,
as well as subsequent definition comparisons against updated upstream
controls. Consult each stage's source hashes before attributing it to a
later commit. The latest stage compares the merged recursive logarithm guard
against `cc1b06c`: all 2,060 modular and 2,059 standalone package symbol
definitions match, as do the six monitored System builtins and eight behavior
probes across load and reload. Relative to the preceding first-guard stage,
the private `parseFinite` downvalues change and `finitePositiveMonomialLog` is
added; all Mathics adapters are unchanged.
This is a definition comparison, separate
from the earlier full MUnit run. The [Mathics CI workflow](../.github/workflows/mathics.yml)
runs both package entry points on Linux and uploads complete per-shard
receipts even when a case fails.

The later logarithm changes have separate Mathics evidence:
[first guard](mathics-log-power-guard-audit.json) and
[recursive positive-monomial recognition](mathics-recursive-log-power-guard-audit.json).
The recursive version at `cc1b06c` passes ten groups across both loaders,
including reciprocal/scaled controls and nested unproved-branch refusals,
with unchanged frozen package bytes and no timeouts. The first-stage report
retains the original two incorrect row-comparison assertions and their exact
reconstruction corrections. Neither focused report is a full portable run.

To verify a complete set of downloaded portable shards against one immutable
commit, use the independent [acceptance verifier](check_mathics_acceptance.py):

```text
python validation/check_mathics_acceptance.py --receipts EXTRACTED_ARTIFACTS --revision IMMUTABLE_COMMIT --output acceptance.json
```

Recheck the committed Linux shards with:

```text
python validation/check_mathics_acceptance.py --receipts validation/mathics-linux-34430399328 --revision ffe08b18ea2a6a72546503b135b47b4979e7d010 --output acceptance.json --run-url https://github.com/VladimirReshetnikov/Asymptotic/actions/runs/34430399328
```

It requires every maintained test ID exactly once in each layout, successful
raw kernel protocol and zero exit statuses, and exact package, suite and
runner hashes read directly from Git blobs. It rejects incomplete runs,
duplicate or unknown cases, mixed sources, altered protocol fields and output
paths that overwrite a receipt. Sixteen integrity tests cover those cases,
including a dirty working tree that differs from the requested commit.
Requirements-file hashes are distinguished from observed runtime versions;
neither is a complete audit of installed dependencies. The historical
multi-snapshot summary above remains separate from this acceptance check.

The native comparison is reproducible with:

```text
python validation/check_mathics_definitions.py --baseline BASELINE_REPOSITORY --candidate . --wolfram wolfram.exe --output native-definitions.json --captures .venv/native-captures
```

The baseline may be an extracted Git archive. Both entry points are checked
by default (`--form` can restrict the run). The runner copies immutable
inputs, checks ten definition fields, caller/package contexts, load/reload
stability and selected builtins, and retains source hashes. Only absolute
source-directory strings are normalized. A deliberate changed-downvalue
fixture verifies that the checker rejects a real mismatch.

## Wave-3 intake and explicit native rule goals

After merging immutable `main` revision
`5d4ff7c569f747245741d940a5a774d51917912f`, the
[merged five-file acceptance](native-rule-goal-merge-tests.json) again passes
**116/116**. The incoming Mathics adapter and standalone-splitting changes
were [reviewed separately](../docs/development/PEER_REVIEWS.md); one finding
concerns a pending peer validation tool outside that commit. The standalone
was regenerated from the merged sources, and the 14 standalone-builder and
14 portable-runner Python tests passed. Those Python results are not Mathics
feature acceptance.
The [merged local loading record](native-rule-goal-merge-loading-tests.json)
also passes **90/90 in five fresh kernels**, including native adapter isolation
and the new scalar-goal case in every loading mode. These merged records
carry their own source hashes; they do not reuse the pre-merge fingerprints.

All nine [wave-3 reports](../external-reports/code-review/wave-3/README.md)
have been read and compared with the current source. The
[maintained intake](../docs/development/WAVE_3_INTAKE.md) maps all 44 ledger
entries and their unnumbered proposals into the implementation scope. This
source audit does not rerun or validate every supplied native witness or
candidate patch. The immutable report payloads remain unchanged.

The [explicit rule-goal acceptance](native-rule-goal-tests.json) passes
**116 tests, zero failures**, across [five selected files](CheckNativeRuleGoals.wl),
including 15 new cases. Scalar rule requests now admit explicit native goals
`Automatic`, zero and negative integers; native oracle comparisons cover
their distinct finite parts. Delayed common options are consumed once,
explicit package constraints remain binding, and triple cutoffs are unchanged.
Configured backend/goal defaults, alias ownership and equivalent option names
remain separate wave-3 items; this repair does not close them.

The [first pass](native-rule-goal-first-pass.json) passed 115 cases and failed
one new test because its helper incorrectly required automatic-only
`OrderConvention` metadata on an explicit native result. The helper was
corrected; production explicit-native behavior did not change. That first
record describes the earlier test source, not the final committed test hash.

The [local loading acceptance](native-rule-goal-loading-tests.json) passes
**90 checks in five fresh kernels**, including the new scalar rule case,
reloads, isolated standalone loading, modular entry, `init.m`, `Needs` and
paclet registration. The generated guide and distribution match their sources;
documentation link checks now include the new wave-3 index and intake.

The native-boundary change does not alter the mathematical article's analytic
theory. Its TeX/PDF are unchanged; the user guide and development notes describe
the new routing behavior. The full package suite was not run.

## Native `SeriesData` integer and order-span limits

The [focused C17 acceptance](review-native-index-range-tests.json) passes
**46 tests, zero failures**, across [four selected files](CheckReviewNativeIndexRange.wl).
Seventeen new cases check native signed-index, positive-denominator and
order-span boundaries, preservation of the sparse result, inverse scaling,
and precedence of the existing export guards. This checkpoint starts from
merged `main` revision `96122d74097c58cb0ea1da341b4e5d8a90af90d4`.

The [fourteen native constructor observations](native-index-range-probe.json)
separately establish the supported boundary values on Wolfram 15.0.1 for
64-bit Windows. Two observations show silent loss of the supplied coefficient
when individually valid indices have an overflowing difference. They are
runtime characterizations, not package acceptance tests. The
[probe](ProbeNativeIndexRange.wl) records indices as decimal strings because
the native `RawJSON` exporter misformats the most-negative machine integer.

The [local loading acceptance](review-native-index-range-loading-tests.json)
passes **85 checks, zero failures, in five fresh kernels**: isolated standalone,
modular entry, `init.m`, `Needs`, and paclet loading. Each includes reloads,
native Mathics-adapter isolation, previous review repairs, and the new C17
endpoint and span witnesses. The 13 standalone-builder Python tests also pass.

The standalone distribution and HTML guide were rebuilt and their source
freshness and documentation links checked. The mathematical
article is unchanged: this fix concerns an optional native representation,
and the sparse mathematical expansion retains its existing contract.
The full package suite and Mathics runtime tests were not run.

## Exact exponent collection, composition scope, and native search

The earlier published checkpoint `243ceff` also merges the subsequent
Mathics-only changes from `main` revision `73c23e0`. Its
[second-sync checks](review-mathics-sync-artifacts.json) pass **32/32 in two
fresh Wolfram kernels**, exercising modular and repository-root standalone
loading, reloads, adapter isolation and the three review repairs. Those two
loads used files in the checkout; they were not an isolated-file fixture.
The [published GitHub acceptance](review-published-loading-tests.json) separately
passes **16/16 in a fresh kernel** using `Get[URLDownload[...]]` with the immutable
`243ceff` URL and an explicit reload. The remote bytes match the rebuilt
standalone before and after the run. No local HTTP server was started.

The fixes are recorded at `5b2b6cd`. Before publication, upstream `main`
advanced to `b6df7a1`, adding the Mathics-only evaluator adapters. The modular
sources merged directly; the generated standalone conflict was resolved by
rebuilding from the merged sources. The
[merged native acceptance](review-normalization-merge-tests.json) passes
**425 tests, zero failures**, across the [23 explicitly selected suites](CheckMergedReviewFixes.wl).
This deduplicates the two selections below and adds five package-identity cases.
See the [merge artifact receipt](review-normalization-merge-artifacts.json)
for the exact parents, source hashes, and distribution checks. This run does
not establish Mathics feature acceptance or complete native input coverage.

The pre-merge C14/C15 and native-search milestone has three separate acceptance records:

| Record | Executed scope | Result |
| --- | --- | --- |
| [Review normalization](review-normalization-tests.json) | [15 selected suites](CheckReviewNormalization.wl), including 23 new equal-exponent and 20 new composition-scope cases | **276 passed, 0 failed** |
| [Native search](native-search-tests.json) | [9 selected suites](CheckNativeSearch.wl), including 16 new compatible-backend search cases | **179 passed, 0 failed** |
| [Local distribution loading](review-normalization-loading-tests.json) | Isolated standalone, modular entry, `init.m`, `Needs`, and paclet loading; reloads and all three new repairs checked | **75 passed, 0 failed, 5 fresh kernels** |

All runs used Wolfram 15.0.1 for Windows. The committed files at `5b2b6cd` match
all 56, 50, and 45 source hashes in these respective records. The two focused runs share
35 assumption/reality cases; their counts are not 455 distinct tests. The
full package suite was skipped. The [artifact receipt](review-normalization-artifacts.json)
ties these records to the rebuilt standalone file, guide and mathematical PDF.

Equal exponents are collected before block counts, remainder logarithmic
degrees and inverse enumeration. The [five baseline observations](exponent-equality-baseline.json)
record the previously lost term, underestimated squared remainder and spurious
inverse enumeration cost at commit `6687962`. See the
[mathematical and implementation notes](../docs/development/EXPONENT_EQUALITY.md).

Composition now checks whether the inner varying symbol was fixed data of the
outer remainder. Supported complete forward sources with exact inner objects
are re-expanded in the joint regime; unsupported captured remainders are refused.
The [ten baseline observations](composition-scope-baseline.json) record exact
diagonal values `1/2`, `2` and `Cos[1]` incorrectly approximated by `1 + O(a^2)`.
The [initial 43-case acceptance](review-scope-and-equality-first-pass.json)
passed 42 cases: a violated source condition was refused with a coefficient
error. Checking the condition before substitution corrected the final case.
See the [scope contract](../docs/development/COMPOSITION_PARAMETER_SCOPE.md).

Automatic native search now tries the other compatible backend when the
preferred result is unresolved or failed, while preserving effective common
options and recording ordered attempts. The [47-observation baseline](native-search-baseline.json)
and [32-call native-only probe](native-search-candidates-probe.json) characterize
the host's native behavior and remaining admission gaps. They are not acceptance
suites. Complete native input coverage remains an open requirement; see the
[compatibility plan](../docs/development/NATIVE_COMPATIBILITY.md).

The standalone builder's 11 existing Python tests passed. The guide was
regenerated and its links, unique anchors and coverage of all 38 public symbols
checked. Its HTML was not visually reviewed in this milestone. The mathematical
article completed three serial strict LaTeX passes, finishing at 98 pages.
All pages were rendered; page 45 and contact sheets covering pages 43–54 and
97–98 were visually inspected without clipping or overlap. All 98 pages passed
the text/page geometry check. The receipt records exact PDF, source and build-log
hashes, including the first pass's temporary 94-page output before the table of
contents stabilized. No cosmetic PDF changes were made.

## Package rename, directory moves, and historical evidence

The maintained package directory, standalone file and Wolfram context are now
`src/`, `AsymptoticAnalysis.wl` and ``"AsymptoticAnalysis`"``.
The public `AsymptoticInverse` function is unchanged. Current loading commands
and navigation use the renamed package; see the
[loading guide](../src/Documentation/UserGuide.md#loading-fixed-versions).

At the `6687962` layout checkpoint, `src/` passed **226 tests, zero failures**, in twelve
selected files, plus **60 loading checks in five fresh kernels**. See
[source-layout-tests.json](source-layout-tests.json),
[source-layout-loading-tests.json](source-layout-loading-tests.json), and the
[layout artifact receipt](source-layout-artifacts.json). The checks cover
the new namespace, all 38 public symbols, native routing, inverse syntax,
certificates, isolated standalone loading, modular loading, `init.m`, `Needs`,
paclet registration and reloads. All 53 focused-test source hashes and all 45
loading source hashes matched the final layout and stayed unchanged during
their respective runs. The full package suite was skipped.

The published [GitHub loader acceptance](source-layout-github-loading-tests.json)
passes **36 checks in three fresh kernels**, including an explicit reload in
each kernel, using the documented `Get[URLDownload[...]]` command with
`main/AsymptoticAnalysis.wl`. Its remote SHA-256 matched the generated standalone
file both before and after the run. The [publication receipt](source-layout-publication.json)
ties that verification to the published commit and artifact; no local HTTP
server was started.

For a new local run, write separate evidence files:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path $env:TEMP 'asymptotic-layout-tests.json'
wolfram.exe -noinit -script validation/CheckPackageRename.wl
python -B validation/check_standalone_loading.py --local-only --output "$env:TEMP/asymptotic-layout-loading.json"
```

The 163/0 automatic-routing, 58/0 certificate and 11/0 standalone records below
belong to the pre-rename checkpoint `01b18ab`. Their source paths, contexts,
hashes, logs and artifact receipts remain unchanged as historical evidence.
Earlier records likewise describe their own snapshots. None of those hashes
or passing counts establishes validation of the renamed files. Commands quoted
in historical run descriptions retain their original paths; reproduce them
from the corresponding revision, or use the current focused runners for a new
run. Current `main` download URLs point to `AsymptoticAnalysis.wl`.

At checkpoint `a6c90ce`, before the later directory reorganization, the renamed
package passed **226 tests, zero failures**, across the twelve
explicitly selected files in [package-rename-tests.json](package-rename-tests.json),
run by [CheckPackageRename.wl](CheckPackageRename.wl). The five identity tests
check all 38 public names, the new context, the unchanged inverse constructor,
serialization/display roundtrips and refinement. The remaining 221 checks
repeat the preceding automatic-native and certificate acceptance against the
renamed sources. All 53 recorded source hashes stayed unchanged during the run.
The [225/1 first pass](package-rename-first-pass.json) preserves a new test
fixture mistake: `Names` returns short names for contexts on `$ContextPath`.
Normalizing those names fixed the assertion; no package behavior changed.

[Local loading acceptance](package-rename-loading-tests.json) recorded **60
checks in five fresh kernels**, covering an isolated standalone file, the
modular entry point, `init.m`, standalone `Needs`, and the guide's
`PacletDirectoryLoad` followed by `Needs`. Each mode also checks reload,
namespace cleanliness, native delegation, inverse expansion and certificates.
The historical command at that checkpoint was:

```powershell
python -B validation/check_standalone_loading.py --local-only --output validation/package-rename-loading-tests.json
```

The [rename artifact receipt](package-rename-artifacts.json), preserved from
checkpoint `a6c90ce`, records source
and output hashes, eleven passing Python builder tests, and documentation
consistency. All 39 kernel modules differ from the pre-rename checkpoint only
by package identity substitutions. Mathematical TeX and the 98-page PDF are
unchanged, so this rename did not require another PDF build. The full package
suite and benchmark measurements were not run.

The subsequent layout moves place the mathematical article in
[`docs/article/`](../docs/article/README.md), Wolfram notes in
[`docs/WOLFRAM-NOTES.md`](../docs/WOLFRAM-NOTES.md), and both report collections
under [`external-reports/`](../external-reports/README.md). Saved test results
and receipts retain the paths and hashes of their original runs. They are not
rewritten to assert matching paths or hashes after the moves. The 98-page
mathematical PDF was relocated without changing its bytes; relocation alone
does not require a new typesetting or visual-review claim.

The modular package directory subsequently moved to [`src/`](../src/README.md).
Its package name and context remain AsymptoticAnalysis, and the standalone
download remains `AsymptoticAnalysis.wl`. Current local commands use
`Get["src/Kernel/AsymptoticAnalysis.wl"]` or `PacletDirectoryLoad["src"]`
followed by ``Needs["AsymptoticAnalysis`"]``. The earlier rename receipts
retain their then-current `AsymptoticAnalysis/` directory paths.

## Automatic native routing and report 18 certificate repair

[CheckNativeAutomatic.wl](CheckNativeAutomatic.wl) passes **163 tests, zero
failures**, across eight selected files in [native-automatic-tests.json](native-automatic-tests.json).
This includes 35 automatic-routing cases and adjacent explicit-native,
presentation, contract, assumption, real-coefficient and inverse-callable
regressions. All 49 recorded source hashes matched the pre-rename worktree and stayed
unchanged during execution. The [159/4 first pass](native-automatic-first-pass.json)
preserves two dispatch bugs (held infinity matching and selector-only empty
option containers) and two fixture errors (a square inverse already simplified
by native evaluation, and a single-support product that did not exceed its budget).

[CheckReviewCertificateAccuracy.wl](CheckReviewCertificateAccuracy.wl) passes
**58 tests, zero failures**, across three files in
[review-certificate-accuracy-tests.json](review-certificate-accuracy-tests.json).
All 44 recorded source hashes matched the pre-rename worktree and stayed unchanged
during execution. Sixteen new tests cover report 18's relative-only witness,
explicit-order retry growth, rational endpoint-square checks at different root
magnitudes, sharp error bounds, best-result retention, exact-root controls,
and separate cap/budget behavior. Existing certificate regression and
acceptance files also pass. The nine-case acceptance file took about 17.54
seconds on this run; this is a single measurement, not a benchmark guarantee.

The [earlier controller diagnostic](certificate-accuracy-first-pass.json) and
its [captured log](certificate-accuracy-first-pass.txt) record 49 observed passes
before the owner stopped the excessively slow acceptance file. That variant
increased order on every retry. The final controller also contracts intervals
without raising order when arithmetic uncertainty is already small; its exact
acceptance predicate remains unchanged. No aggregate acceptance is claimed
for the interrupted run.

The [artifact receipt](automatic-certificate-artifacts.json) records the
regenerated standalone package, eleven passing Python builder tests, and an
isolated fresh-kernel [11/0 local load and reload](native-automatic-standalone.json).
HTTP loading was not rerun. The rebuilt guide passes structural checks for
38 public symbols, 209 anchors and 130 links. The mathematical PDF passed three
serial strict LaTeX builds; all 98 pages were rendered and inspected in layout
overviews, with pages 52 and 54 inspected at full size. No overfull or underfull
boxes or text outside pages were found. Browser guide layout review remains
incomplete following the prior preview-server approval rejection described below.

The full package suite was skipped. Automatic native routing remains partial
coverage of the complete native input-superset objective; an unresolved native
call is not a successfully computed expansion.

## Native backend artifacts and late report 18

The [native artifact receipt](native-compatibility-artifacts.json) records the
completed distribution and documentation checks for the explicit native
backends. The [focused acceptance](native-compatibility-tests.json) has
**130 passes, zero failures** across eight files, with all 49 recorded source
hashes verified against that run's pre-rename worktree. A separate fresh-kernel local
[standalone load and reload run](native-compatibility-standalone.json) passed
all nine checks, including the alias and both native backends. HTTP loading
was not rerun for this milestone. Eleven Python builder tests passed, and
standalone freshness covers 39 modular sources.

The guide HTML was regenerated and its consistency check passed for 38 public
symbols, 206 anchors, and 130 links. Browser visual review is incomplete:
automatic approval review rejected launching the local documentation preview
server with only `blocked by policy`. No new browser layout acceptance is
claimed. The mathematical PDF was rebuilt in three serial strict LaTeX passes;
all 97 pages were rendered and reviewed in layout overviews, with pages 10–11
inspected at full size. There were no overfull or underfull boxes. The build
records the `epstopdf` warning that shell escape is disabled; no layout repair
was needed. Sources, output hashes, and review scope are in the receipt.

Late [report 18](../external-reports/code-review/wave-2/code-review-18/README.md) was imported
unchanged from `84650f3521cfcc89ae832f5bad3554f65faaab31`. It reviews the older
`921387e` snapshot. The current [seven-case characterization](review-18-intake.json)
from [ProbeReview18.wl](ProbeReview18.wl) records:

- At this earlier intake snapshot, the relative-only certificate request stalls at orders
  `{60, 60, 60, 60}`; absolute-error and explicit-order controls reach their goals.
- Lower-cutoff refinement still coarsens forward and inverse approximations.
- The analytic backend rejects the complex coefficient witness, while the
  native backend preserves it without asserting an analytic remainder or exactness.
- Default and explicit-cutoff nonlinear exponential requests both retain the
  corrected logarithmic remainder degree two.

All 40 characterization source hashes were verified and stayed unchanged
during execution. These are observations of the intake snapshot, including then-known
pending work, **not a passing acceptance suite**. The
[implementation register](../docs/development/CODE_REVIEW_STATUS.md) maps the
report's four findings and records the supplied certificate candidates' limits.
The full package suite remains skipped.

This directory contains focused runners, characterization probes, build and
provenance tools, benchmarks, and saved evidence from individual milestones.
The [test directory guide](../src/Tests/README.md) explains test
selection and how to add a small reproducible harness. The
[implementation register](../docs/development/CODE_REVIEW_STATUS.md) tracks
review findings; the [review archive](../external-reports/code-review/README.md) preserves the
reviewers' reports and their original execution scope.

## Choose a focused check

The current development request is to **skip the full package suite**. Select
the files relevant to a change and run one Wolfram kernel at a time. A broader
run is a separate validation decision; the historical full-suite commands
later in this document are reproduction instructions, not the default workflow.
Run the following example from the repository root:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path $env:TEMP 'asymptotic-native-tails-local.json'
wolfram.exe -noinit -script validation/CheckReviewNativeTails.wl
if ($LASTEXITCODE -ne 0) { throw 'Focused validation failed' }
```

The output override prevents this local run from replacing a saved acceptance
record. It remains set for subsequent commands in that PowerShell session;
change or clear it when choosing another destination. The report directory
must already exist. Without the override, each focused entry script uses its
configured filename under `validation/`.

| Area | Focused entry script | Explicitly selected scope |
| --- | --- | --- |
| Automatic native routing | [CheckNativeAutomatic.wl](CheckNativeAutomatic.wl) | Eight files covering automatic/explicit backends, options, assumptions, contracts, and inverse entry paths |
| Certificate accuracy controller | [CheckReviewCertificateAccuracy.wl](CheckReviewCertificateAccuracy.wl) | Three files covering report 18 N01 / C19 and existing exact certificate acceptance |
| Native import/export remainder contracts | [CheckReviewNativeTails.wl](CheckReviewNativeTails.wl) | Nine files covering native tails, ordinary operations, special functions, and refinement |
| Complete real coefficients | [CheckReviewRealCoefficients.wl](CheckReviewRealCoefficients.wl) | Eleven files covering coefficient reality and adjacent assumptions, core, coordinate, and special-function paths |
| Assumption capture | [CheckReviewAssumptions.wl](CheckReviewAssumptions.wl) | Eight files covering construction, arithmetic, inverse branches, and refinement |
| Delayed options and stored assumptions | [CheckReviewAssumptionReplay.wl](CheckReviewAssumptionReplay.wl) | One supplemental regression file |
| Nonlinear input precision and terminating coefficients | [CheckReviewUnitArithmetic.wl](CheckReviewUnitArithmetic.wl) | Nine files covering remainder degrees, recurrence termination, and adjacent operations |
| Fractional-power branches | [CheckReviewPowerBranches.wl](CheckReviewPowerBranches.wl) | Six files covering shared power checks and forward/observable operations |
| Automatic arithmetic and composite bounds | [CheckSeriesArithmetic.wl](CheckSeriesArithmetic.wl) | Seven files covering arithmetic, envelopes, formatting, and inverse operations |

These scripts call [FocusedTests.wl](FocusedTests.wl), which runs only their
listed files. Its JSON records the actual kernel version, selected files,
per-suite time constraint and results, failed expected/actual outputs and
messages, and SHA-256 hashes of the kernel sources, selected tests, entry
script, and shared runner. It checks package loading before testing and
returns a nonzero exit code for failed, empty, or aborted suites, changed
sources during the run, or report-export failure. The configured timeout
applies to each selected file, not to the whole invocation.

[CheckFocusedRunner.wl](CheckFocusedRunner.wl) tests the runner itself using
temporary synthetic fixtures; it does not execute the package regression
suite. It deliberately exercises failure paths, so its printed fixture
failures must be interpreted through its final self-check result. It writes
`focused-runner-tests.json` directly, independently of the output override.

## Explicit native expansion backends

[CheckNativeCompatibility.wl](CheckNativeCompatibility.wl) records
**130 passed, zero failed** on Wolfram 15.0.1 for Windows in
[native-compatibility-tests.json](native-compatibility-tests.json).
The eight selected files cover 33 native compatibility cases, 15 native
contract cases, seven native presentation cases, four result-head checks,
eight `Normal` checks, 28 arithmetic checks, twelve assumption-replay checks,
and 23 real-coefficient checks. The report records source hashes and confirms
that the sources stayed unchanged during execution. **The full suite was not run.**

The explicit `"Series"` and `"Asymptotic"` backends and held `AsymptoticExpand`
alias preserve native requests and results with a distinct contract. Tests
cover held arguments, native options and order conventions, complex and nested
results, metadata, normalization, display, and refusal to invent analytic
remainders. Recognized option rules are excluded from expansion-specification
metadata. Native options are not reevaluated merely to produce metadata.

[native-compatibility-first-pass.json](native-compatibility-first-pass.json)
preserves the earlier **120 passed, two failed** run. Both failures were test
fixture errors: an evaluated `SeriesData` pattern emitted a message, and a
term-goal expectation incorrectly counted native zero coefficients. Those
fixtures were corrected; metadata option/specification classification was
also corrected and additional cases were added before final acceptance.

The [native compatibility plan](../docs/development/NATIVE_COMPATIBILITY.md)
tracks automatic routing and remaining coverage work. This earlier focused result establishes the
recorded explicit-mode cases, not complete input-superset coverage. The
[native result notes](../docs/development/NATIVE_RESULT_CONTRACTS.md) describe
held metadata and the distinct formal or native asymptotic contract. Document
build and artifact acceptance must be recorded separately.

[RunTests.wl](../src/Tests/RunTests.wl) discovers every `.wlt`
file. A historical all-passing run therefore does not establish acceptance
of a later test set. Existing native ingress
and export tests concern the package's current analytic representation;
their results do not establish native-backend compatibility beyond the focused
explicit-mode record above.

## Read the evidence by scope

- A saved native acceptance report establishes its recorded assertions on
  its recorded kernel and source snapshot. Compare its hashes with the
  checkout before presenting it as current validation.
- A characterization probe records observed behavior, including known
  defects. It is not a passing acceptance suite. A reviewer-supplied run
  remains the reviewer's evidence until reproduced locally.
- Python checks, source inspection, generated-file freshness, and native
  Wolfram execution establish different facts. PDF compilation, rendering,
  and visual inspection also have separate scopes.
- Numerical residuals and high-precision comparisons are evidence of
  behavior. An interval certificate needs the certificate's stated
  hypotheses and proved enclosure; a finite-model residual is not that
  certificate.
- Benchmarks describe their recorded fixtures, samples, kernel, and host.
  A faster fixture does not establish a package-wide performance claim.

The milestone records below retain their original counts, snapshot details,
and validation limits. They are historical evidence, not a claim that those
commands were rerun for a later documentation or implementation change.

## Complete real coefficients and wave-2 intake

`CheckReviewRealCoefficients.wl` records **280 passed, zero failed** across
eleven selected files on Wolfram 15.0.1 for Windows. The 23 new public cases
test complete-coefficient reality, target offsets, assumptions, cancellation,
diagnostics, known exact terms before truncation, and signed observable
increments. All tested source/harness hashes match the accepted worktree;
sources were unchanged during execution. The same 23 cases against immutable
`7d98eca3248b9d59e27109f9b4b48fd52f45b00c` passed 12 and failed 11.

`review-real-coefficients-first-pass.json` preserves the earlier 20-case
version's broader run: 275 passed, two cancellation controls failed. The
bounded stronger realness proof and signed positive native Taylor increment
fixed those cases. `review-real-coefficients-tests.json` is the final record;
the first-pass record is historical diagnostic evidence.

```powershell
wolfram.exe -noinit -script validation/CheckReviewRealCoefficients.wl
```

The mathematical article adds a proof that a real-valued germ has real
complete coefficients strictly below its error power. It does not infer a
real source from a finite real prefix. The 96-page PDF was rebuilt with three
strict serial LaTeX passes; all pages were rendered and reviewed in layout
overviews, with pages 9–10 inspected at full size. No final LaTeX warnings or
overfull/underfull boxes were reported. Standalone freshness, eleven Python
builder tests and documentation consistency checks passed. Artifact hashes
and the exact visual-review scope are in `review-real-coefficients-artifacts.json`.

`ProbeReviewWave2.wl` records **six bounded characterization probes**, not a
passing acceptance suite. Its `review-wave-2-intake.json` confirms current
fixed-parameter composition and semantic-weight boundary-degree errors. It
also records the oversized native index, rejection of the old hostile-context
certificate, and C07 rejections of the known nonreal-root and particular opaque
function witnesses. The last rejection does not establish analytic regularity
for arbitrary opaque functions. The [implementation register](../docs/development/CODE_REVIEW_STATUS.md)
maps all 119 numbered findings across 17 reports and distinguishes current
local observations from the reviewers' historical evidence.

The real-coefficient acceptance belongs to the existing real representation.
The user's newly required complete `Series`/`Asymptotic` coverage will also
need native-supported complex and formal result kinds, without promoting
formal native orders to proved analytic remainders. That compatibility work
is required and pending. **The full package suite was not run.**

## Native series remainder preservation

C03/C06 now preserve the distinction between a native formal power cutoff and
the package's analytic power-log remainder. The optional native exporter returns
`Missing["LogarithmicRemainder", metadata]` for nonzero remainder degree,
while retaining ordinary native views with logarithms among kept coefficients
and a degree-zero tail. Its existing coordinate, exactness and irrational-power
guards remain in the same order; dense allocation follows the new tail guard.

The public input

```wolfram
AsymptoticExpansion[EllipticK[1 - x^2]/x^3, {x, 0, 3}]
```

previously returned `PowerLogRemainder[x, 3, 0]`. Its independently derived
next block is `25 x^3 (Log[4/x] - 37/30)/256`, so that bound is false. It now
returns `PowerLogRemainder[x, 3, 1]` with unchanged finite coefficients.
The elliptic oracle follows [DLMF 19.12.1](https://dlmf.nist.gov/19.12.E1);
the companion Bessel Laurent oracle follows
[DLMF 10.8.1](https://dlmf.nist.gov/10.8.E1).

The shared incoming-tail helper uses a half-lattice power allowance, conditional
on the admitted complete tail having some fixed finite logarithmic degree.
The ordinary importer reconciles complete normalized probes, including regular
summands and coefficient power shifts. It sharpens only on consistent stronger
evidence. Empty, unresolved or mismatched probes cannot manufacture exactness or
a degree-zero bound at an unresolved native endpoint. Laurent/Puiseux composition
transports the same bound, and the Taylor coefficient path checks its endpoint.

Against pinned kernel `a2c05e1b3b264736f52ceed98153f81f88b02406`,
`review-native-tail-export-baseline.json` records **four passed, eight failed**
in 12 new export cases. `review-native-tail-import-baseline.json` records
**four passed, five failed** in the nine import tests that call pre-existing
paths. For that baseline subset, use the first seven tests and the final two
Taylor/algebraic controls of `ReviewNativeTailImport.wlt`; the seven new-helper
contract cases have no baseline helper to call and are excluded. The exported
baseline manifest records those selected test IDs and the exact subset hash.

`CheckReviewNativeTails.wl` records **197 passed, zero failed** across nine
selected files, including all 28 new cases. All 49 source/harness hashes match
the final worktree, and sources were unchanged during execution. Supplemental
native probes confirmed both displayed guide examples and preservation of the
first conservative bound when a custom native provider returns an unresolved
or mismatched second probe. **The full package suite was not run.**

```powershell
wolfram.exe -noinit -script validation/CheckReviewNativeTails.wl
```

The standalone build and 11 Python builder tests passed. The guide and purely
mathematical article are current, with detailed
[implementation notes](../docs/development/NATIVE_SERIES_REMAINDERS.md).
The 96-page article was rebuilt in three serial strict LaTeX passes; the final
pass had no warnings or overfull/underfull boxes. Pages 8, 9, 65 and 66 were
rendered and visually inspected. `review-native-tail-artifacts.json` records
source/artifact hashes and this selected visual-review scope.

## Captured assumptions and reusable proof contexts

All nine constructors now default to `Assumptions :> $Assumptions`, with explicit
options replacing the ambient value. The shared request boundary captures the
caller context before neutralizing ambient assumptions for internal proofs.
Arithmetic, observables, queries, refinement and certificate replay continue
using retained hypotheses. Models and coefficient-query results now preserve
assumptions too. Delayed options are resolved once, including nested option
lists and coordinate dispatch. Every nested boundary also neutralizes ambient
assumptions, covering constructors invoked from delayed-option callbacks.

`review-assumptions-baseline.json` records **zero passed and 17 failed** against
immutable kernel `e9c9eb9b9fb785bf02bbf2e89fd187380575a171`. The unchanged original
17-test file passes after the fix. `CheckReviewAssumptions.wl` records
**200 passed, zero failed** in eight selected files.
`CheckReviewAssumptionReplay.wl` adds **12 passed, zero failed** in one explicit
supplemental file. Both acceptance manifests record unchanged sources, and every
recorded source hash was compared with the final worktree. These are focused
native checks on Wolfram 15.0.1; **the full package suite was not run**.

Reproduce the selected checks with one kernel at a time:

```powershell
wolfram.exe -noinit -script validation/CheckReviewAssumptions.wl
wolfram.exe -noinit -script validation/CheckReviewAssumptionReplay.wl
```

The [user guide](../src/Documentation/UserGuide.html#assumption-context)
and [implementation notes](../docs/development/ASSUMPTION_CONTEXT.md) describe
explicit-option replacement, retained contexts, specialized domain restrictions,
and ordinary evaluation limits. The article now explains retained parameter
hypotheses and pointwise versus uniform estimates. It also includes the nonlinear
boundary-degree lemma and homogeneous recurrence termination proof for the
preceding C04/P03 milestone.

The 96-page article PDF was rebuilt in three serial strict LaTeX passes. The final
pass reported no warnings or overfull/underfull boxes. Pages 10, 13, 14, 42 and 43
were rendered and visually inspected for the changed material. Standalone
freshness, all 11 Python builder tests, and documentation consistency checks
passed. `review-assumptions-artifacts.json` records the source/PDF/distribution
hashes and the exact visual-review scope; this was not a fresh full-document
render inspection.

## Nonlinear input frontiers and coefficient termination

An input-limited nonlinear expansion now includes both the inherited error and
discarded Taylor products in its logarithmic remainder degree. The shared unit
precision helper uses the maximum degree of all retained argument blocks and
keeps its existing conservative bound when the requested cutoff lies below the
input frontier. It no longer drops generated logarithmic powers merely because
the caller requested more precision than the operand supplies. The unused
duplicate cutoff calculation in `pUnitSeries` was removed.

The homogeneous composition recurrence now stops as soon as its coefficient
polynomial is proved zero, before multiplying another power. This avoids false
resource failures for constant or terminating polynomial compositions. Required
products and existing input-validation order remain checked. An unrelated
generic coefficient generator may still resume after an isolated zero.

Against pinned kernel sources from `73aabf2`, the 31 new assertions record
**19 passed and 12 failed**: eight nonlinear-bound witnesses and four futile
product failures. After the changes, `CheckReviewUnitArithmetic.wl` records
**196 passed, zero failed**, across nine selected files, with unchanged source
hashes. Explicit Taylor/binomial oracles cover logarithmic frontiers, a genuine
irrational boundary collision, pure and inherited errors, symbolic coefficient
annihilation, required work budgets, Newton coefficients and residual checks.
The independent log-degree majorant remains conservative, rather than claiming
the sharp degree after cancellation.

The baseline and acceptance records are `review-unit-arithmetic-baseline.json`
and `review-unit-arithmetic-tests.json`. Standalone generation, 11 Python builder
tests, and documentation consistency checks passed. **The full package suite
was not run.**

## Shared fractional-power branch checks

The shared `fwdPower` primitive now rejects noninteger powers of a finite pure
remainder. This closes the bypass through nested sums, products, analytic
observables, and forward expansions after cancellation. The public
`SeriesPower` check and existing exponent-validation order remain in place.
Positive integer powers still propagate pure remainder bounds, and positive
fractional powers of an exact zero remain exact. Forward construction can retry
with more terms to establish a positive leading coefficient.

`review-power-branches-baseline.json` records **10 passed and six failed** for
the 16 new assertions against pinned kernel sources from
`73aabf26dfa6258253ed45f31603cb2731b474c7`; those six failures reproduce the branch
defect. `CheckReviewPowerBranches.wl` records **148 passed, zero failed** in six
selected files after the fix, with unchanged source hashes. It covers wrapped
fractional powers, cancellation, unknown symbolic signs, valid integer powers,
exact zero, and rejection of the nonreal square root of `Sin[x]-x`.

The positive control `Sqrt[x-Sin[x]]` checks the independently known leading
term and accepts a valid weaker remainder bound. Its next nonzero term has
power `7/2`; requesting cutoff `2` does not require a constructor to discover
that sharp frontier. The standalone build, 11 Python builder tests, and generated
guide/documentation checks passed. **The full package suite was not run.**

## Bounded native series export

Forward and inverse construction now share one native `SeriesData` exporter.
It retains the original rational denominator and remainder index while storing
coefficients only through the final retained exponent. More than 100,000 dense
slots between retained exponents produce `Missing["DenseSeriesDataLimit", ...]`
for the optional native view; sparse terms, the finite expression, and remainder
remain available. Empty inverse jets also retain their pure remainder correctly.
The existing coordinate, irrational-exponent, and exact-result guard order is
preserved. Logarithmic native-tail semantics are a separate review finding.

`CheckReviewNativeExport.wl` records **115 passed, zero failed**, in five selected
files, with unchanged source hashes. Its 13 new cases cover a billion-slot tail
under a 64 MB evaluation constraint, an excessive interior gap, both sides of
the dense limit, Laurent and rational lattices, empty jets, symbolic inverse
scaling, target translations, refinement, and guard precedence. The standalone
build, 11 Python builder tests, and documentation consistency checks passed.
**The full package suite was not run.**

`BenchmarkNativeExport.wl` compares pinned baseline
`73aabf26dfa6258253ed45f31603cb2731b474c7` with the changed sources in fresh Wolfram
15.0.1 kernels, with one warm-up and three measured runs. All five finite/native
results and remainders agree exactly. Reports retain source/harness hashes and
individual samples. Peaks are `MaxMemoryUsed` evaluation observations, not total
process memory or portable bounds.

| Fixture | Before / after median seconds | Before / after median peak bytes |
| --- | --- | --- |
| Forward native view, million-slot trailing gap | 0.01402 / 0.000114 | 24,010,048 / 10,520 |
| Inverse native view, million-slot trailing gap | 0.01465 / 0.000062 | 16,009,224 / 10,624 |
| Public fractional power with distant remainder | 0.01569 / 0.00237 | 24,054,088 / 73,336 |
| Public series with a wide retained gap | 0.00722 / 0.00308 | 5,654,608 / 87,512 |
| Ordinary polynomial inverse control | 0.00348 / 0.00438 | 131,240 / 131,248 |

The unchanged control was slower in this sample; these selected measurements
establish an allocation improvement for sparse native views, not a general
speedup. Reproduce with `wolfram.exe -noinit -script
validation/BenchmarkNativeExport.wl`; the usual `ASYMPTOTIC_BENCHMARK_ROOT` and
`ASYMPTOTIC_BENCHMARK_OUTPUT` environment variables select the baseline and report.

## Vendored ProveIt articles

The [article catalog](../vendor/proveit/README.md) contains 46 articles and two
reference companions, each with TeX and PDF, pinned to the published ProveIt
revision recorded in its [manifest](../vendor/proveit/manifest.json). All 42
regenerated PDFs and the associated source repairs were committed upstream
before the final snapshot. The other six PDFs passed the dependency freshness
checks without a rebuild. Archived roots are excluded.

`vendor_proveit_articles.py check --source-root C:/ProveIt` verifies copied
bytes against the pinned Git objects. `check_proveit_catalog.py --source-root
C:/ProveIt` checks the complete article inventory, selection evidence, reading
lists, links, freshness, and published build receipts. `build_proveit_pdfs.py
--list` reports any required builds; its build mode uses three serial LaTeX
passes. The [final verification record](../vendor/proveit/verification.json)
binds the audit results to the manifest and validation scripts.

Every rebuilt PDF passed structural and font checks. Targeted rendered-page
reviews cover repaired text loss and the final synchronization; minor layout
warnings remain in the logs. This validates artifact provenance and compilation,
not all mathematical claims or every rendered page. No Lean build or full
Wolfram package suite was run for the document work.

## Parameterized composition probes

Parameterized special-function composition now examines the argument jet
before proving the whole expression real. A nonconstant increment with an
infinite working cutoff is rejected at the same limit as `fwdAnalytic`;
an argument made constant by parameter assumptions still follows the full
construction path. Every successful finite result retains the original
real-domain and real-coefficient checks. The special-inverse numerical check
also drops an unused eager numerical conversion and three unused locals.

`CheckCompositionRefactoring.wl` selects six files and records **100 passed,
zero failed**, with unchanged source hashes, in
`composition-refactoring-tests.json`. Four new cases cover constant arguments
under assumptions, finite retries after an exact probe, logarithmic increments,
and rejected complex parameters/branches/centers. Existing numerical checks
cover reflected Erfc tails, LogGamma, very large exact exponential targets,
and Lambert thresholds. The standalone build, 11 Python builder tests and
documentation checks passed. **The full package suite was not run.**

The `Composition` benchmark compares immutable commit
`07a9781212beb2eeb9ff16aa625b50ac27974078` with these sources in fresh Wolfram
15.0.1 kernels. This baseline also predates the request-local logarithmic
builder, so one fixture measures that builder separately from exact-composition
checks. All seven finite outputs and remainders agree exactly. Each fixture
has one warm-up and three measurements; the reports retain all samples and
source/harness hashes.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Six nested logarithmic regions, without exact-composition checks | 0.01520 | 0.00773 |
| Nonconstant trigamma exact probe | 0.00345 | 0.00239 |
| Irrational Bessel order and argument | 0.08311 | 0.08009 |
| Finite trigamma composition | 0.03211 | 0.02811 |
| Incomplete Gamma with irrational shape and input | 0.11596 | 0.07590 |
| Hypergeometric function with a symbolic positive parameter | 0.05790 | 0.04217 |
| Inverse of a Bessel perturbation | 0.03912 | 0.02763 |

These selected local measurements are not general performance guarantees.
The logarithmic builder improvement does not change the previously observed
whole-constructor bottleneck in exact-composition checks.

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Composition'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckCompositionRefactoring.wl
```

## Request-local construction reuse

Generalized logarithmic term-goal searches now keep one lazy builder per
request. Normalized source data and complete multi-index coefficients are
reused between construction calls, including zero coefficients. Every cutoff
still builds its own index region, merges complete blocks and computes the
full boundary remainder. A final shrinking cutoff cannot retain an earlier
overshoot. New constructor calls and `SeriesRefine` start fresh builders.

Composite arithmetic reuses operand data only for literally identical
operands and skips a domain simplification only when its predicate is exactly
the one already checked in that invocation. Both independent input errors
and their product remain present. Different errors and new conditions still
undergo their original checks.

`CheckConstructionRefactoring.wl` selects eight files and records **135 passed,
zero failed** in `construction-refactoring-tests.json`, with unchanged source
hashes. This includes ten new checks for shrinking cutoffs, cancelled
resonances, independent constructor state, refinement, validation order,
error propagation and domain intersections. The standalone build, 11 Python
builder tests and documentation consistency checks also passed.
**The full package suite was not run.**

The `Construction` benchmark set compares immutable commit
`07a9781212beb2eeb9ff16aa625b50ac27974078` with these sources in fresh Wolfram
15.0.1 kernels. All eight finite expressions and remainders agree exactly.
Each fixture has one warm-up and three measured runs; source and harness
hashes are retained in `construction-benchmark-before.json` and
`construction-benchmark-after.json`.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Generalized logarithmic inverse, six blocks | 8.09769 | 8.08571 |
| Cancelled logarithmic resonance, five blocks | 6.14373 | 6.09454 |
| Identical Gamma inverse composite operands, addition | 0.00170 | 0.00093 |
| Identical Gamma inverse composite operands, multiplication | 0.00116 | 0.00085 |
| Exact scalar added to a Gamma inverse composite | 0.00153 | 0.00130 |

The public logarithmic times are essentially unchanged: bounded exact
composition checks dominate these examples. The cache avoids repeated
coefficient work, but these timings do not establish a public logarithmic
speedup. The three unchanged Lerch control fixtures also show the variability
of millisecond measurements. A separate exploratory moment recurrence was
slower for negative and algebraic geometric weights; it was not adopted.

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Construction'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckConstructionRefactoring.wl
```

## GeneralizedSeries and operation simplification (version 1.8.0)

The public result head is now `GeneralizedSeries`. Constructors, arithmetic,
refinement, residual checks, formatting and examples use the new symbol;
the old head is not exported as an alias. StandardForm and TraditionalForm
still hide the head, InputForm retains the full object, and `Normal` drops
the remainder. The Markdown and generated HTML guides describe the renamed
interface and the migration of explicit patterns and saved input. Historical
validation reports and archived development notes retain their original
names and source hashes.

This milestone also extracts the common outer-condition/parameter-assumption
split, gives ordinary real coordinates direct inverse rules, shares Fourier
weight grouping and frequency counting, prunes discarded Fourier product
pairs, and reuses the parsed elementary exponential product. Gamma and Barnes
residual checks share validation and reporting while keeping their independently
written phase formulas. Existing failure order and residual property order
are retained. Symbolic, nonreal and ambiguous coordinate inverses still use
the previous real-solver path.

The `Operations` benchmark set compares an immutable copy of commit
`916481a2745b69334a605cc499d7af6aa4bebb3d` with these sources in fresh Wolfram
15.0.1 kernels. Each fixture has one warm-up and three measured runs. All four
outputs agree exactly, including the public inverse's finite expression and
remainder; the reports preserve individual timings and source hashes.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| 100 ordinary translated-coordinate inversions | 0.12115 | 0.00418 |
| Fourier source merge with repeated frequencies | 0.19112 | 0.09396 |
| 200-by-200 Fourier product below weight 4 | 1.28634 | 0.00776 |
| Public Fourier inverse through target weight 4 | 0.02514 | 0.02325 |

The first three fixtures show approximately 29, 2 and 166 times improvements.
These local measurements do not establish a general public speedup. Reproduce
the selected operation fixtures with:

```powershell
$env:ASYMPTOTIC_BENCHMARK_SET = 'Operations'
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
wolfram.exe -noinit -script validation/CheckGeneralizedSeries.wl
```

`ASYMPTOTIC_BENCHMARK_ROOT` selects an independent baseline checkout or source
copy; `ASYMPTOTIC_BENCHMARK_OUTPUT` selects the output path. The regression
runner explicitly selects 18 files, including four head-contract checks and
32 new coordinate, Fourier and residual checks. `generalized-series-tests.json`
records **305 passed, zero failed**, with all recorded source hashes unchanged
throughout the run. The 11 builder tests and the documentation checks also
passed: all 37 public symbols are documented, generated HTML matches the
source, and the mathematical article remains free of package syntax.
An isolated copy of the standalone file passed all seven acceptance checks
in a fresh kernel, including the renamed head, arithmetic, formatting,
`Normal`, and an explicit reload; the recorded source hashes stayed unchanged.
**The full package suite was not run.**

## Shared arithmetic refactor (commit 916481a)

The internal refactor shares Gamma/Barnes product parsing and branch proofs,
and the cancelled-frontier search used by inverse construction and refinement.
The inverse term-goal loop now consumes the boundary weight already recorded
in its computation state. Sparse multiplication finds its remainder-boundary
degree with a monotone scan instead of a Cartesian scan; merging normalizes
each weight and coefficient once. Native arithmetic skips absolute-majorant
work for exact-zero errors and reuses accepted truncations and error proofs.
Flat multiplication skips exact-zero sectors while retaining uncertain empty
jets, complete omitted-sector sums, and the original resource budget.

Eight focused validation entry scripts now use `FocusedTests.wl`. Their suite
selections, default output paths, and time limits are preserved. This reduces
the runners from 483 to 143 lines, including the helper: 340 lines removed.
The runner checks package loading, rejects empty suites, records source hashes
before loading, rejects changes during testing, and propagates report-export
failures. `focused-runner-tests.json` records eight passing synthetic checks,
including failing tests, timeouts, empty suites, source mutation, missing
files, empty selections, and a syntax error in the package loader.

`refactoring-tests.json` records **316 passing tests in 17 explicitly selected
files**, including 30 new regression tests. There were no failures, and all
recorded kernel, test, and runner source hashes remained unchanged throughout
the run. Coverage includes sparse arithmetic, complete inverse frontiers,
incremental refinement, native error bounds, flat-sector cancellation,
Gamma/Barnes branch conditions and exact identities, and formatting/`Normal`.
The 11 standalone-builder tests and documentation consistency checks also
passed. `refactoring-standalone-tests.json` records seven additional passing
checks in a fresh kernel loading only the generated file from an isolated
directory, including explicit reload, arithmetic, `Normal`, formatting, and
representative inverse/special-function calls. Both the generated file and
its acceptance script retained their recorded hashes. **The full package
suite was not run.**

`BenchmarkRefactoring.wl` ran unchanged in two fresh Wolfram 15.0.1 kernels,
against an immutable copy of commit `0ddac97340cc223abd36fdeceb325bdffbefc5ab`
and the refactored sources. Each fixture had one warm-up and three measured
runs. The two reports include all samples and source hashes; all seven
returned expressions and remainders agree exactly, with stable results
within each run. These are local measurements, not portable guarantees.

| Fixture | Before, median seconds | After, median seconds |
| --- | ---: | ---: |
| Sparse product with finite remainder | 0.4914 | 0.1540 |
| Merge irrational weights and logarithmic polynomials | 0.1303 | 0.0665 |
| Import a 40-coefficient native logarithmic series | 0.0980 | 0.0028 |
| Irrational inverse, five blocks | 8.3630 | 8.2714 |
| Gamma ratio, five correction blocks | 0.4563 | 0.4868 |
| Barnes G, five correction blocks | 3.3755 | 3.4171 |
| Exact summand plus native Erfc tail | 2.0874 | 3.5020 |

The helper fixtures improved by approximately 3.2, 2.0 and 35.5 times.
The public examples do not establish an overall speedup. The initially
slower Erfc result was investigated by alternating the original and
refactored package in one kernel. Median times for the four passes were
6.624, 6.768, 5.963 and 5.896 seconds, respectively, with identical results.
The overlap and variation do not establish a consistent slowdown either;
`refactoring-native-timing-followup.json` preserves these measurements.

To reproduce the selected regression checks and the current benchmark:

```powershell
wolfram.exe -noinit -script validation/CheckFocusedRunner.wl
wolfram.exe -noinit -script validation/CheckRefactoring.wl
wolfram.exe -noinit -script validation/BenchmarkRefactoring.wl
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
python validation/check_documentation.py
```

`ASYMPTOTIC_BENCHMARK_ROOT` selects a separate baseline checkout or source
copy, and `ASYMPTOTIC_BENCHMARK_OUTPUT` selects the output report. The default
source is this checkout. Validation selects 17 regression files explicitly;
it does not discover or run the full package suite. The public interfaces,
mathematical article, and user guide are unchanged by this internal refactor.

## Standalone distribution (version 1.7.1)

Version 1.7.1 adds a standalone distribution at the repository root:

```wolfram
Get[URLDownload[
  "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticAnalysis.wl"]]
```

The generated file contains all 38 canonical kernel sources, in their
original load order. The builder records per-source hashes, produces
deterministic UTF-8/LF output, and checks freshness without writes.
Eleven focused Python tests passed, covering ordering, dependencies,
lexical masking, deterministic output, stale artifacts, and failed builds.
The user guide HTML was rebuilt; documentation consistency and local-link
checks passed. This packaging change does not change the mathematical
article or require a new PDF build.

`standalone-loading-tests.json` records **45 successful native checks in
seven fresh Wolfram 15.0.1 kernels**. It covers isolated local, plain HTTP,
and gzip HTTP loads,
the modular kernel entry and `init.m`, `Needs`, explicit reloads, and a
missing HTTP file. The served directory contains only the standalone file;
the request log contains exactly one request per downloaded remote load, plus the expected
missing-file request. Kernels run with `-noinit`, startup-argument environment
variables cleared, and a pre-load check for existing package definitions.
Input hashes are recorded and verified unchanged throughout the run,
including all 38 canonical kernel sources and `init.m` used by the modular
loading cases, as well as the standalone file and validation harness.

Acceptance examples check irrational inversion, certified exact termination,
Gamma ratios, Bessel asymptotics, automatic arithmetic, `Normal`, StandardForm
formatting, and Zeta expansion after an explicit reload. This is focused
loading validation; **the full package suite is skipped**.

The supported command retrieves the complete distribution with `URLDownload`
and loads the resulting temporary file with ordinary `Get`. This addresses
intermittent premature-EOF errors observed with direct cold HTTPS `Get` of
the large file, also reproduced by the local gzip fixture. Both explicit
HTTP stream selection and a literal wrapper in the large file still failed.
The checks verify context placement and string-stream cleanup after both
initial loading and reloading.

`github-loading-tests.json` records **21 successful checks in three fresh
kernels** against the real `main` standalone URL using `Get[URLDownload[...]]`.
`github-pinned-loading-tests.json` records **seven successful checks** against
the immutable standalone at `fd357dd2e022bfd8deceae5537fcd2a594c41938`.
Both records verify the published bytes against the local artifact before
and after native loading. No full package suite was run.

Across the three current records, **all 73 native checks passed in 11 fresh
kernels**, with zero failures and normal process exit. An earlier nested
HTTP convenience loader was withdrawn after two later native runs ended
abnormally, despite their seven mathematical checks passing. Its earlier
successful record and the subsequent failure observations are preserved
in the [validation archive](archive/README.md); they are not evidence for
a currently supported loading route.

To reproduce these checks:

```powershell
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
python validation/check_standalone_loading.py
python validation/check_documentation.py
```

After publishing, check the downloaded standalone form with:

```powershell
python validation/check_standalone_loading.py --url https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticAnalysis.wl --repeat 3 --output validation/github-loading-tests.json
```

The published-URL runner compares the remote file byte for byte with the
local build before and after native loading. Replacing `main` in the
standalone URL with a full commit hash selects an immutable revision for
the same downloaded-file check.

The special-function extension in version 1.7.0 is recorded in
`special-functions-tests.json` and `special-functions-validation.json`.
**All 220 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. Twelve files were explicitly selected; the full package suite
was skipped at the user's request. The runner records source hashes before
loading the package and verifies that every tested file remains unchanged
through the run.

The new checks cover finite and infinite special-function expansions,
fixed-parameter composition with irrational powers, exact identity lowering,
oscillatory absolute errors, independent coefficient formulas, conservative
logarithmic tail bounds, and public Zeta/Lerch dispatch and refinement.
Eight checks verify that `Normal` returns an ordinary finite expression,
including `0` for a pure remainder, without exposing remainder or provenance
objects. Selected Gamma, Barnes G, exponential, arithmetic, and formatting
regressions passed alongside the new files.

The broad importer preserves native structured remainders, proves the real
source branch before real projection, and computes enough omitted terms to
justify the returned frontier. Exact half-integer Bessel identities retain
both exponentials. The Zeta and Lerch expansions have independently derived
pointwise tail bounds under their recorded conditions. Other imported
Poincare results assert an asymptotic error class, without a pointwise
constant or an automatic derivative certificate.

`AsymptoticInverse/Examples/SpecialFunctions.wl` checks and prints five public
examples, including their ordinary `Normal` expressions. The native preview
is generated by `RenderSpecialFunctions.wl`. The separate user guide includes
function-family and endpoint scope, block conventions, branch conditions,
and examples. Its HTML is checked against the source and for broken links.
The mathematical article adds a fixed-measure moment theorem and its
special-function consequences. The 95-page PDF was built with three serial
strict passes, and every page was rendered; all contact sheets and the new
dense formula pages were visually inspected. Exact artifact hashes and
the final preview result are recorded in the validation manifest.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckSpecialFunctions.wl
wolfram.exe -script AsymptoticInverse/Examples/SpecialFunctions.wl
wolfram.exe -script validation/RenderSpecialFunctions.wl
python validation/build_user_guide.py
python validation/check_documentation.py
```

The current article build and rendering commands are in [docs/article/README.md](../docs/article/README.md).

The automatic series arithmetic update is recorded in
`series-arithmetic-tests.json` and `series-arithmetic-validation.json`.
**All 137 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. Seven files were explicitly selected: automatic arithmetic,
composite arithmetic, composite functions, existing series operations,
formatting, Gamma inverse operations, and Barnes inverse regressions.
The full package suite was skipped at the user's request.

The checks cover ordinary operators, regular function operands, exact
coefficients, propagated precision, held normalization before cancellation,
adaptive working orders for new nonlinear operations, real branches,
separate error scales, contradictory domains, resource bounds, and existing
inverse and formatting behavior. Independent formulas check the retained
coefficients and error orders. `Normal` continues to return the ordinary
finite expression, dropping the remainder and the series metadata.

`AsymptoticInverse/Examples/Arithmetic.wl` ran successfully. The native
front-end renderer produced `series-arithmetic-preview.png`, which was
visually inspected for notation, grouping, remainder display, and clipping.
The renderer reported that ImageMetadataTools could not be installed, but
returned an image and exported the reviewed PNG successfully.

The Wolfram-style guide documents ordinary arithmetic, `SeriesNormalize`,
precision limits, and composite results. Its HTML was regenerated and
checked for links and source parity. The separate mathematical article
proves the error-envelope rules for arithmetic and supported functions.
The 88-page PDF was rebuilt with three serial LaTeX passes and every page
was rendered for layout inspection. The validation JSON records the final
artifact hashes and the scope of visual review.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckSeriesArithmetic.wl
wolfram.exe -script AsymptoticInverse/Examples/Arithmetic.wl
wolfram.exe -script validation/RenderSeriesArithmetic.wl
python validation/build_user_guide.py
python validation/check_documentation.py
```

The current article build and rendering commands are in [docs/article/README.md](../docs/article/README.md).

The invisible `PowerLogSeries` display update is recorded in
`formatting-tests.json` and `formatting-validation.json`. **All 13 focused
tests passed**, with zero failures on Wolfram 15.0.1 for Windows. Only
`Formatting.wlt` was selected; the full package suite was skipped.

The tests check StandardForm and TraditionalForm interpretations, complete
association preservation, reconstructible InputForm text and boxes, explicit
read-only formatting, and independent visible grouping under powers,
products, reciprocals, negation, and function application. Fixtures include
ordinary, Barnes inverse, exponential, reciprocal-logarithmic, flat-sector,
and nested-logarithmic series. Raw held formatting leaves visible fields,
remainder coordinates, and hidden metadata unevaluated. `Normal` returns the
finite ordinary expression, including zero for a pure-remainder result.

`formatting-preview.png` was generated by the native Wolfram front end and
visually inspected for notation, grouping, and clipping. Its renderer emitted
an environment message that ImageMetadataTools could not be installed; it
nevertheless returned an image and successfully exported the reviewed PNG.
The mathematical article is unchanged. The user guide's HTML was regenerated
and its links and source parity were checked.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckFormatting.wl
wolfram.exe -script validation/RenderFormatting.wl
python validation/check_documentation.py
```

The native `LogBarnesG` update is recorded in `log-barnes-g-tests.json`
and `log-barnes-g-validation.json`. **All 134 focused tests passed**,
with zero failures on Wolfram 15.0.1 for Windows. The full package suite
was skipped at the user's request. The runner selects 17 new native-log
tests and five adjacent Barnes, Gamma, and branch regression files.

The requested applied inverse now uses the existing Barnes coefficient
calculus with the unlogged target coordinate. Tests independently check
its three blocks and frontier, affine forms, powers, refinement, source
and target domains, formal residuals, and 60-digit numerical references
with known source roots 100 and 1000. The exact checking equation uses
native `LogBarnesG` for all positive Barnes inverse forms.

Forward checks cover the five-block expansion, shifted sparse corrections,
finite positive Taylor expansion, exact native/wrapped-log cancellation,
the Barnes recurrence, and exponentiation. Native constants remain intact
and cannot change the inverse family when used inside Gamma arguments.
Expansion of a varying `LogBarnesG` argument requires an eventually positive
argument; nonpositive tails are rejected before native generic series expansion.

The Wolfram-style user guide includes the literal native inverse and
forward syntax, logarithmic target domain, and numerical examples. Its
HTML was rebuilt, checked for local links, and visually reviewed at
desktop and mobile widths. The mathematical article already proves this
logarithmic inverse expansion; its source and previously reviewed PDF are
unchanged, and the PDF hash was verified.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckLogBarnesG.wl
python validation/check_documentation.py
```

The increasing Barnes G inverse update is recorded in
`barnes-g-inverse-tests.json` and `barnes-g-inverse-validation.json`.
**All 142 focused tests passed**, with zero failures on Wolfram 15.0.1
for Windows. The full package suite was skipped at the user's request.
The runner explicitly selects the 24-test inverse Barnes file and five
adjacent inverse Gamma, branch, callable-expression, and Barnes forward files.

The new tests independently derive the first four source blocks, the next
frontier coefficient, and powered observables. They cover the literal
applied conditional inverse, affine and logarithmic targets, reciprocal
forward powers at a finite target, named and slot callables, exclusive
cutoffs, refinement, inherited power precision, branch restrictions,
formal residuals, and a 60-digit numerical reference at `BarnesG[100]`.
That exact target has source root 100 by the Barnes recurrence. The
three-block error is positive and agrees with its first omitted term.
The numerical comparison is explicitly not an interval certificate.
A regression also ensures that a Barnes-valued affine constant inside
Gamma or LogGamma does not change the inverse family.

The pure mathematical article proves monotonicity above three, derives
the Lambert balance and polynomial recurrence, and transports the finite
Barnes remainder to the inverse. The separate Wolfram-style guide gives
the requested syntax, related forms, operations, and limitations. The
87-page PDF was rebuilt with three serial LaTeX passes and every page was
rendered. Changed and new pages were visually reviewed; unchanged pages
20-82 were verified to have identical rendered bytes to the preceding
Barnes milestone. Desktop and mobile guide screenshots were inspected,
with no document overflow or broken local links.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckBarnesGInverse.wl
python validation/check_documentation.py
```

The native report records exact byte hashes of the tested kernel, tests,
and runner. The validation ledger also records the final PDF hash and
the scope of static, browser, and mathematical review.

The Barnes G update is recorded in `barnes-g-tests.json` and
`barnes-g-validation.json`. **All 94 focused tests passed**, with zero
failures on Wolfram 15.0.1 for Windows. The full package suite was skipped
at the user's request. The runner explicitly selects the 22-test Barnes
file and five adjacent Gamma and exponential regression files.

The Barnes tests use independent Bernoulli and exponential-recurrence
coefficients. They check the literal five-block expansion, the sparse
even corrections of `BarnesG[x + 1]`, logarithms, fixed and varying powers,
mixed Gamma products, exact recurrence cancellation, fractional and
symbolic common offsets, transported domain conditions, refinement, and
square-root and quadratic arguments. A finite Barnes logarithmic model
always retains its asymptotic tail; exact termination instead requires
an identity of the original functions.

The separate Wolfram-style user guide includes the requested expression
and related examples. Its HTML was rebuilt and checked at desktop and
mobile widths. The pure mathematical article derives the Barnes formula,
the argument shift, and its absolute and relative remainders. The final
83-page PDF was built with three serial LaTeX passes and every page was
rendered. All contact sheets and the Barnes pages were visually inspected.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckBarnesG.wl
python validation/check_documentation.py
```

The runner exports per-test outcomes and hashes of the tested kernel,
test, and runner files. Article build and render commands are in
[article/README.md](../docs/article/README.md).

The logarithmic Gamma update is recorded in `gamma-logarithms-tests.json`
and `gamma-logarithms-validation.json`. **All 87 focused tests passed**, with
zero failures on Wolfram 15.0.1 for Windows. The full suite was skipped at
the user's request.
Its focused runner checks `GammaLogarithms.wlt` together with the existing
Gamma product, fixed-power, varying-power, related-function, and elementary
exponential suites. The new 18-test file uses independent Bernoulli and
Taylor coefficients for the requested `Log[Gamma[x]]` expansion, complete
block counts, first omitted terms, exact recurrence cancellation, finite
and infinite endpoints, real branches, symbolic powers, and refinement.
The full package suite is excluded from this runner.

The shared logarithmic source is normalized before ordinary expansion.
Gamma arguments and powers are checked before applying real logarithmic
identities. The original expression and target conditions remain available
for refinement. Ordinary forward results now also report
`RequestedTermGoal` and `ReturnedTermCount`. The separate user guide
includes the literal request, supported logarithmic extensions, and the
absolute cutoff convention; its standalone HTML and links were checked.

To reproduce this focused milestone:

```powershell
wolfram.exe -script validation/CheckGammaLogarithms.wl
python validation/check_documentation.py
```

The runner exports per-test outcomes and hashes of the tested source files.
Earlier records below retain the scope and source revision of their own
milestones.

The inverse-Gamma extension is recorded in `gamma-inverse-tests.json` and
`gamma-inverse-validation.json`. **All 134 focused regression tests passed**
on Wolfram 15.0.1 for Windows, in six explicitly selected files: the two
new inverse-Gamma suites, inverse-function branches and expressions,
special-function regressions, and Gamma products. The full package suite
was **not run**, as requested.

The new cases check independent coefficients and the first omitted block,
affine and signed target transformations, reciprocal Gamma at a finite
target, exact real source powers, branch ambiguity, source and target
conditions through refinement, transported `SeriesPower` precision, formal
finite-Stirling residuals, and a 100-digit numerical comparison at
`Exp[10000]`. Numerical comparisons use the original `LogGamma` equation;
they are not interval certificates. The executable runner records every
test outcome and SHA-256 hashes of the tested kernel and test files.

The separate guide now includes an inverse-Gamma reference section and
six additional documentation checks. Its current 32-check result is in
`gamma-inverse-documentation-tests.json`; the earlier 26-check result is
preserved in `documentation-tests.json`. The mathematical article adds
the coefficient recurrence, finite-order proof, and first omitted error
constant. The final article has 82 pages; every page was rendered, and
contact sheets and selected full pages were visually inspected. The HTML
guide was checked at desktop and mobile widths.

`gamma-inverse-documentation-initial-tests.json` preserves the first
documentation run: 31 checks passed and one reported an unexpected message
while rejecting an invalid target for `-1/Gamma[x]`. The real target
inequality is now checked without first forming a logarithm outside its
domain, eliminating the complex-comparison warning.

To reproduce just this milestone from the repository root:

```powershell
wolfram.exe -script validation/CheckGammaInverse.wl
$env:ASYMPTOTIC_VALIDATION_OUTPUT = "$PWD/validation/gamma-inverse-documentation-tests.json"
wolfram.exe -script validation/CheckDocumentation.wl
Remove-Item Env:ASYMPTOTIC_VALIDATION_OUTPUT
python validation/check_documentation.py
```

These runners use explicit test lists. `CheckGammaInverse.wl` also accepts
`ASYMPTOTIC_VALIDATION_OUTPUT` for an alternate report destination. The
following records describe their original historical milestones.

The documentation split is recorded in `documentation-split.json` and
`documentation-tests.json`. The mathematical article was rebuilt with three
serial LaTeX passes and reviewed as rendered pages. The separate user guide
has a reproducible standalone HTML build, public API anchors, and checked
local links. The record includes the final source and artifact hashes and
the precise visual review scope.

**All 26 focused documentation checks passed**, with zero failures on
Wolfram 15.0.1 for Windows. They check the displayed expressions and relevant
remainders or properties for ordinary and irrational inverses, Gamma products
and varying powers, elementary growth, series operations, precision limits,
certification, and the specialized inverse families. The runner checks the
guide against all 36 native public symbols. It runs only its explicitly
listed examples and does not discover package regression files.

The full package suite was **not run**, as requested. The documentation
change only updates usage strings in executable package sources; the
algorithms are unchanged. Historical test records below retain their original
revision and scope.

To reproduce documentation checks from the repository root:

```powershell
python validation/build_user_guide.py --check
python validation/check_documentation.py
wolfram.exe -script validation/CheckDocumentation.wl
```

The native runner exports `validation/documentation-tests.json` by default;
set `ASYMPTOTIC_VALIDATION_OUTPUT` to use another destination. Each example
has a 60-second limit. PDF build and render commands are documented in
[article/README.md](../docs/article/README.md).

The final exact-recovery follow-up is recorded in
`growth-exact-recovery-tests.json`: **57 focused tests passed in four suites,
with zero failures**, on Wolfram 15.0.1 for Windows. This record preserves
the completed runner's aggregate suite outcomes and tested-source hashes;
individual test outcomes were not exported by that focused runner.
The subsequent full-suite rerun was cancelled at the user's request.
The earlier successful 845-test full run below covers the preceding
milestone, not this final source revision.

The follow-up keeps a valid logarithmic expansion when an optional exact-jet
probe encounters an unsupported representation. The added independent
regression checks cancellation in `x^-5 (1+x)^(1/x^2) Exp[-1/x]` near zero,
its relative cutoff and absolute remainder, and refinement to the next
correction. An unsuccessful optional probe cannot establish exactness or
discard the already computed approximation.

To reproduce just these focused tests in a Wolfram kernel from the root:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
TestReport[FileNames[{
  "ExponentialForward.wlt", "GammaProducts.wlt",
  "GammaRelatedFunctions.wlt", "GammaVaryingPowers.wlt"
}, "AsymptoticInverse/Tests"], ProgressReporting -> False]
```

The Gamma-product and elementary-growth update is recorded in
`gamma-products-and-growth-tests.json`. Its final native run passes
**845 tests in 38 suites, with zero failures**, on Wolfram 15.0.1 for Windows.
Its 56 new regressions cover the
requested `Gamma[3 x]/Gamma[x]` ratio, products, reciprocal and varying real
powers, factorials, binomial coefficients, complete beta functions, rising
factorials, and elementary exponential prefactors. Exact correction tables
come from independent Bernoulli-logarithm and exponential-convolution
oracles. A 100-digit normalized evaluation at `x = 1000` checks the requested
ratio against its independently derived first omitted term; it is numerical
asymptotic evidence, not an interval certificate or pointwise error bound.

The same tests check relative cutoffs and nonzero block counts, signed
absolute remainders, source- and domain-preserving refinement, finite Gamma
factors, and realness that holds only eventually. Exact recurrence and
polynomial identities terminate with zero remainder by recovering an exact
jet from the original logarithmic identity. Cancellation in a finite
Stirling approximation does not establish exactness. Optional symbolic
prefactor simplification is bounded and can retain an equivalent exact form.

`gamma-products-and-growth-initial-tests.json` preserves the first complete
run: 843 tests passed and two failed. The Laurent reciprocal regression
exposed an overly broad normalization rule. The corrected rule requires
an elementary logarithmic source to grow faster than `Log[u]`, preserving
ordinary power-law cutoffs for `1/(Exp[x^5] - 1)` near zero. The generated
three-irrational-gap case hit its existing 30-second per-case limit;
all 19 generated-oracle tests passed on the targeted rerun with that limit
unchanged. The 25 review regressions and 16 exponential tests also passed
in that targeted run.

To reproduce the full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-products-and-growth-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved records include the baseline commit and SHA-256 hashes of the
tested kernel and test sources, added after each run. Earlier milestone
records below are preserved.

The Gamma-power update is recorded in `gamma-powers-tests.json`. Its final
native run passes **789 tests in 34 suites, with zero failures**, on Wolfram
15.0.1 for Windows. The 12 new regressions cover the exact requested
`Gamma[x]^2` expression, independently derived correction coefficients and
frontier, the full absolute remainder, reciprocals, rational and irrational
powers, scaled arguments, domain-preserving refinement, and finite-point
behavior. An exact irrational exponent cancels the degree-three correction;
the term goal correctly skips it. A 100-digit normalized numerical comparison
at `x = 1000` verifies the square at the independent first-omitted scale.

The tail construction uses `r LogGamma[arg]` for fixed exact real numeric
`r`, retaining the powered original expression and logarithmic provenance.
Unsupported tail exponents do not intercept regular finite-point expansions.
To reproduce the full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-powers-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved JSON additionally records the baseline commit and SHA-256 hashes
of the changed kernel and test sources, added after the successful run.

The Gamma forward-expansion update is recorded in `gamma-forward-tests.json`.
Its final native run passes **777 tests in 33 suites, with zero failures**, on
Wolfram 15.0.1 for Windows. The 18 new regressions verify the requested
five-term expansion against independent Stirling coefficients, the full
prefactor-scaled remainder and frontier, a 100-digit normalized numerical
comparison at `x = 1000`, positive growing argument substitutions, finite
endpoints, relative cutoffs, domain-preserving refinement, and compatible
series operations. Invalid budgets, cutoffs, and source approaches are
also covered. The full suite includes the earlier callable-input regressions.

The implementation expands `LogGamma` using the existing forward engine,
then uses its explicit series exponential to transport the remainder and
extract the exact prefactor. The result records a Poincare expansion and
does not assert convergence or an unproved derivative remainder contract.
The numerical comparison is evidence of asymptotic accuracy, not an
interval certificate or pointwise error bound.

To reproduce the Gamma update's full native run:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\gamma-forward-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The saved JSON additionally records the baseline commit and SHA-256 hashes
of the changed kernel and test sources, added after the successful run.

The callable-input update is recorded in `callable-expansion-tests.json`.
Its final native run passes **759 tests in 32 suites, with zero failures**, on
Wolfram 15.0.1 for Windows. The 17 new regressions cover rule coordinates,
unapplied inverse and pure functions, native inverse simplification, lexical
scoping, option forwarding, arity failures, conditional wrappers, and source
conditions retained through refinement. The requested five-term inverse of
`x + x^Sqrt[2]` at infinity is checked against independently derived Lagrange
coefficients, its exact reciprocal-coordinate remainder, and a vanishing
formal composition residual. The JSON also records the baseline commit and
SHA-256 hashes of the changed source and test files.

To reproduce this run from the repository root:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path (Get-Location).Path 'validation\callable-expansion-tests.json'
wolfram.exe -script AsymptoticInverse\Tests\RunTests.wl
```

The runner exports test outcomes; the baseline and changed-source hashes in
the saved record were added after the successful run.

Version **1.5.0**, the fourth extension milestone, is recorded in
`milestone-4-tests.json` and `milestone-4-artifacts.json`. The suite covers
applied `InverseFunction` expressions, both original conditional examples,
lexical and selected-argument callable forms, exact varying affine output
families, nested and critical-point composition, native `ProductLog` branches,
symbolic real offsets, algebraic coefficients, and condition-preserving
refinement. Numerical checks and interval certificates retain source domains;
closed rational endpoint comparisons use exact affine bounds before interval
rounding. Tests use explicit coefficient formulas, original-equation residuals,
independently known source roots and certified rational containment.
The final native run passes **742 tests in 31 suites, with zero failures**, on
Wolfram 15.0.1 for Windows.

The milestone also admits expansion-variable assumptions after proving them
on the selected deleted neighborhood. A former test requiring their blanket
rejection is replaced by acceptance with a retained domain and rejection of
an incompatible approach. Unknown input remainders cannot prove equality in
an observable condition, and an excluded inverse endpoint is not silently
filled by continuity.

Observable comparisons distinguish the input placeholder from the original
expansion variable. An expression involving that original variable is expanded
in its own recorded coordinate instead of being mistaken for a constant
coefficient. N-ary `Unequal` checks every pair. These rules prevent a truncated
`Sin[y] = y + O[y^3]` input from falsely proving inequality with `y`.

The artifact register records the tested source hashes and both rebuilt PDF
hashes. Each document received three serial strict LaTeX passes and complete
page rendering; the visual-review scope is recorded separately. Only Wolfram
15.0.1 is validated. The earlier standalone generated campaign and performance
benchmark remain historical evidence and were not rerun for this milestone.
No new quantitative performance claim is made for the per-call syntax and
branch caches.

The original review started from commit `1716eb8`. The native baseline contained
49 passing tests. The historical records below describe version 1.1.0.

The first extension milestone, version 1.2.0, is recorded separately in
`milestone-1-tests.json`, `incremental-benchmark.json`, and
`milestone-1-artifacts.json`. Its eight delivered suites pass 161 tests on
Wolfram 15.0.1, including all 130 previous regressions and 31 new coordinate
and incremental-engine tests. `Tests/BenchmarkIncremental.wl` reproduces three
exactly equal comparisons. Term-goal coefficient evaluations fall from 95 to
31; the measured term-goal and Newton cases improve, while the small grouped
public-method case is slower. Historical snapshots are retained as evidence
of their original milestone, not as hashes of the current source tree.

The second extension milestone, version 1.3.0, is recorded in
`milestone-2-tests.json` and `milestone-2-artifacts.json`. All **311 tests in
13 shipping suites pass** on Wolfram 15.0.1. The new suites cover explicit
calculus, exact-core marker corrections, rigorous rational certificates,
source charts, and 46 independent generated inverse oracles. Certificate
tests include absolute and relative accuracy, zero-root fallback, both
Lambert branches, a near-turning-point bracket and exact-core seeds.
The combined run is a regression run, not a performance comparison with
earlier, smaller suites. Refinement regressions distinguish automatic
forward truncation from a binding declared input error.

`Tests/GeneratedInverseOracles.wlt` records seed 236367 and the generator
method. Forty quadratic cases compare against an independent radical inverse
expanded by the native Taylor-series implementation; six irrational-gap
cases use independent first-coefficient formulas. Case IDs include the
generated parameters. Failed test exports retain expected and actual output
and messages for reproduction. Wider generated families and automatic
counterexample shrinking were deferred in that milestone and are delivered
by the third milestone below.

The third extension milestone, version **1.4.0**, is recorded in
`milestone-3-tests.json`, `refinement-benchmark.json`, `generated-campaign.json`
and `milestone-3-artifacts.json`. It includes the earlier suites plus finite
logarithmic hierarchies, exact growing exponential-core sectors, flat-sector
and reciprocal-log operations, Fourier coefficients, special-function
adapters, retained refinement states and structured requests. Acceptance
suites add coordinate and calculus edge cases, several absolute and relative
certificate tolerances, invalid intervals and insufficient-precision recovery.
Tests compare against independent marker substitutions, exact inverse
formulas and original-equation numerical oracles as appropriate. Passing
tests complement the article's stated mathematical contracts. The final
native run passes **602 tests in 25 suites, with zero failures**, on
Wolfram 15.0.1. The standalone campaign passes all 32 cases, and all nine
benchmark comparisons satisfy their acceptance checks.

The final audit repaired a certificate retry that increased arithmetic order
without resolving invalid bracket geometry. Exact endpoint signs now provide
an alternative existence argument, and a proved same-sign interval exits
immediately. Other regressions preserve reflected Erfc signs, special-adapter
options during refinement, affine Lambert threshold limits, exact small
target differences, observable-dependent numerical errors and explicit replay
statistics. Logarithmic term goals count nonzero blocks despite cancellation.

The nine-case refinement benchmark checks exact equality at every requested
cutoff and the retained-state invariants; the deep one-gap case also uses an
independent Catalan oracle through cutoff 64. In the recorded single sample,
the high-logarithmic-degree Lagrange fixture is about 4.6 times faster.
Two smaller fixtures are slower and most retain more memory. Timings and
evaluation memory peaks are empirical, not portable guarantees or total
process-memory bounds. Polynomial-power cache counters describe their
specific reused work, not the cost of the complete computation.

The standalone campaign uses seed 236369 and 32 cases covering two cycles of
16 bounded families. `generated-campaign.json` preserves the manifest, full
inputs, each expected/actual result and its captured message file. The runner
also preserves completed shrink attempts when failures occur. Shrinking is
exercised by deterministic injected failures in the regression suite; a
passing campaign does not itself demonstrate the failure path. The source
hashes and actual native kernel version are part of the preserved manifest.

The installed 14.3 engine failed its startup probe with exit code 62 and
`No valid password found`; no package test ran on that engine. The paclet
minimum is now 15.0, replacing the former untested 13.0 declaration.
Only 15.0.1 is validated; successful 15.0.1 tests do not establish a result
for an older engine or a future version.

The review corrected observable-dependent transport of forward remainders,
negative-target remainder coordinates, source-side frontier signs, logarithmic
degrees lost at precision boundaries, hidden leading terms after cancellation,
exact-input and branch validation, symbolic depth handling, and finite inverse
termination. The article's convergence class, closure proof, semigroup-tail
argument, signed endpoint formulas, radius claims, and several displayed
coefficients were corrected alongside the implementation.

The new Lambert engine computes finite asymptotic expansions with explicit
relative logarithmic remainders. It handles both `x Log[x]` near zero and
`x Exp[x]` at infinity, as well as affine-logarithm powers, arbitrary polynomial
leading logarithmic blocks with nonzero algebraic power, source infinities,
growing and decaying exponential cores, and specified higher-power
perturbations. Numerical checks use the original forward expression.
General polynomial logarithmic cores do not claim an exact ProductLog inverse.

## Historical full native regression runner

The full runner discovers all `.wlt` files and has no focused-selection
argument. The current development request skips this runner; the following
command is retained for deliberate full-run reproduction from the repository
root:

```powershell
$env:ASYMPTOTIC_VALIDATION_OUTPUT = Join-Path $env:TEMP 'asymptotic-local-tests.json'
wolfram.exe -script AsymptoticInverse/Tests/RunTests.wl
```

The optional output records the Wolfram kernel version and each test outcome.
The historical 1.1.0 combined run in `test-results.json` passed
**130 tests with zero failures** on Wolfram
15.0.1 for Microsoft Windows (64-bit). Its approximately 99-second total
includes symbolic and numerical Lambert tests; it is not a benchmark against
the original, smaller suite. Two original expectations were intentionally
updated: a logarithmic core is now supported, and a cancelled inverse frontier
is skipped when the next nonzero block is found.

## Performance

`benchmark-snapshot.json` records original-commit versus updated-algorithm
measurements made during this review. All four computed results agreed.
The three targeted fixtures improved by approximately 105–110 times. The
weighted-region fixture became approximately 1.75 times slower while gaining
bounded boundary allocation and accurate budget enforcement. These results
are fixture-specific and machine-dependent.

The reference algorithms are preserved for reproducibility:

```powershell
wolfram.exe -script AsymptoticInverse/Tests/BenchmarkPerformance.wl
```

## Article

The following commands record the earlier repository layout. Use the
[current article build instructions](../docs/article/README.md) for the moved
sources. The historical TeX workflow used three serial strict passes:

```powershell
Push-Location article
1..3 | ForEach-Object {
    pdflatex.exe -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex
    if ($LASTEXITCODE -ne 0) { throw 'LaTeX build failed' }
}
Pop-Location
python validation/inspect_pdf.py article/asymptotic-inverse.pdf TEMP_RENDER_DIRECTORY
```

`inspect_pdf.py` uses Poppler, Pillow, and pdfplumber to render every page,
generate contact sheets, and inspect text geometry. `article-validation.json`
records the historical review PDF; each milestone artifact manifest records
its own PDF hash, page count, build diagnostics, and completed visual review.
Geometry checks supplement visual inspection; they do not establish
mathematical correctness. The local Fabius research sources were read as
references and were not modified.

The package README states remaining input-class boundaries. The finite flat
algebra has separate inner and exponential-sector truncations within its
proved commensurable phase family. Arbitrary phase families, general nonlinear
sector composition and unrestricted transseries remain outside that scope.
An exact symbolic composition certificate is distinct from a numerical root
check or a residual of a finite forward model.
