# AsymptoticAnalysis: incremental technical review

Reviewed revision: `6687962f3c858a4f93623cfc496f33e35c6763d4`.
Review date: 9 September 2026, America/Los_Angeles.

Read `article/article.pdf`; its complete source is `article/article.tex`.

## Main results

N01 reproduces two incorrect `FractionalPart` observable expansions and identifies the loss of a one-sided native constant. N02 reproduces a false remainder when a truthful custom native Series handler returns less precision than requested. N03 reproduces ignored canonical constructor backend defaults, including a package-only policy. N04 and N05 are smaller cutoff/option-admission inconsistencies. N06 is an observed eager native projection and a performance opportunity, not a measured speedup.

The novelty ledger explicitly relates the first two findings to the existing C13/C16 and C06 obligations. The previous 18-review crosswalk is used as the primary suppression baseline; the report does not pretend that all included TeX sections or every source module were reviewed line by line.

## Evidence limits

Successful baseline probes used Wolfram Language `15.0.0 for Linux x86 (64-bit) (May 6, 2026)`. Three mechanism-level controls succeeded on a temporary patched standalone with the same guard logic and backend-default change, but abbreviated diagnostic strings. Fourteen independent Python mathematical/patch-fixture test methods passed.

The full upstream suite, the packaged WLT files as a suite, and the exact staged modular patch in a local checkout were **not run**. Several other Wolfram connector attempts returned network/502 errors; no results are inferred from them. The JSON observation file is a transcription of returned observations, not a fabricated TestReport.

## Reproduce the baseline

Use a fresh Wolfram 15+ kernel and the pinned local standalone:

```text
wolframscript -file code/native_characterizations.wl /path/to/AsymptoticAnalysis.wl
```

The script deliberately includes an unknown-option witness that emits warnings.

## Independent checks

Python 3.9 or newer, standard library only:

```text
python code/check_independent.py
```

This overwrites `evidence/independent_checks.json` with the new run's result. The included `.txt` log records the authoring run. These checks are not Wolfram package tests.

## Candidate patch

```text
python code/stage_patch.py /path/to/Asymptotic /path/to/new-external-staging-directory
```

The staging directory must not already exist and must be outside the source checkout. The script reads only two modular files, requires every edit anchor to occur exactly once, validates all edits before writing, and never modifies the input checkout. It writes **changed modular files only**, not a complete package. Exact anchor matching is not whole-repository identity verification. Review the diff against the pinned revision.

The candidate changes:

* resolve the canonical `AsymptoticExpansion` backend default through `OptionValue`;
* refuse generic native Taylor results whose returned order does not reach the requested coefficient order;
* apply a bounded, necessary two-sided continuity screen to nonconstant generic observable inputs.

The continuity screen is deliberately conservative. It does not implement valid discontinuous one-sided observable germs and it is **not a complete analyticity proof**. It may reject requests that a future sided-germ implementation should support. Independently changed `AsymptoticExpand` alias defaults are not synchronized by this patch.

For development, apply reviewed changes to a separate checkout, regenerate its root standalone using the repository's existing `validation/build_standalone.py`, and run focused native tests. For a temporary standalone-only experiment:

```text
wolframscript -file code/apply_candidate_to_standalone.wl original.wl new-candidate.wl
```

Then, in a fresh kernel:

```wl
Get["/path/to/new-candidate.wl"];
TestReport["/path/to/code/focused_candidate_tests.wlt"]
```

`proposed_policy_tests.wlt` deliberately tests **unimplemented proposed policies** for zero-order differentiation and unknown symbolic options. It is not part of the claimed narrow patch. `native_projection_probe.wl` is an instrumented diagnostic; no timing results from it are included as measured findings.

## Build the article

With a reasonably complete TeX Live installation:

```text
sh build.sh
```

The article uses standard installed NewTX fonts; no font files are distributed.

No checksum files are included. Commit identifiers are source provenance, not checksum artifacts.
