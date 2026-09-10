# AsymptoticAnalysis: A Native-Boundary Audit

Read **[the article (PDF)](article/audit.pdf)** or its **[self-contained LaTeX source](article/audit.tex)**.

The audited source is `VladimirReshetnikov/Asymptotic` commit
`6687962f3c858a4f93623cfc496f33e35c6763d4` (September 9, 2026, 17:18:17 PDT).
This is a pinned-source incremental review, with a built-in Wolfram Language comparison.
The eighteen existing reviews are screened through their wave indexes and the
maintained finding register; the article explains the precise novelty boundary.

## Main findings

N01: `SetOptions` changes the published backend default, but the dispatcher ignores it.
N02: computed option keys are classified too early; a valid backend is missed, and an
option alias can become a false expansion variable that disables numerical application.
N03: an unrecognized symbolic option after a complete specification is accepted without
a failure result. This shares part of N02's parser root cause.
N04: a native 624-byte sparse result is preserved but accompanied by an unsolicited
2.4 MB dense stored view for a 100000-element vector.
N05: failure sentinels are classified as `"Computed"` by the documented syntactic rule;
this is a diagnostic-design deficiency, not a claimed contradiction of that rule.
A separate low-priority README policy contradiction is also documented.

## Evidence, not blanket acceptance

`evidence/native_observations.json` contains thirteen grouped observations and two
independently exercised patch mechanisms from successful Wolfram 15.0.0 Linux calls.
These records are transcriptions, not raw upstream test logs and not fifteen
homogeneous test-suite cases. Some exploratory calls failed at the service/network
layer; no package finding is inferred from those failures.

The two patch mechanisms were exercised **separately** on temporary standalone text.
The complete combined candidate, the supplied native test runner, the full benchmark
harness, and the outcome prototype were not run as integrated native programs here.
The full upstream suite was not run. The article does not claim to close existing
mathematical obligations in the upstream register.

Twelve local Python methods passed: eight synthetic patch-emitter tests and four
independent mathematics/storage checks. This is not Wolfram package acceptance.
The complete output is in `evidence/python_tests.txt`.

## Reproduce individual native observations

Use a fresh licensed Wolfram Language 15+ kernel. Load the pinned source:

```wolfram
Get[URLDownload[
 "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/6687962f3c858a4f93623cfc496f33e35c6763d4/AsymptoticAnalysis.wl"]];
```

Then run an observation body from the JSON. Unqualified public symbols should be
entered **after** package loading; fully qualified public symbols
avoid context ambiguity in code parsed earlier. Each default-option probe should
start in a fresh kernel, or restore `Options` afterward.

## Stage the candidate source fixes

The emitter only repairs N01 and the demonstrated computed-key preparation subset
of N02. It does not repair N03, N04, N05, or every possible option/evaluation case.

```sh
python code/patch_native_dispatch.py NativeCompatibility.wl candidate.wl --fix both
```

The input can be the pinned modular file or the generated standalone. The output
must be a **new file**; the input is not modified. `--fix default` and `--fix keys`
allow independent staging. The emitter refuses missing or duplicate anchors and
already-patched input. Review the diff. For a checkout, integrate the modular change
and regenerate the standalone with the upstream builder. Do not load a companion
module independently.

## Desired-contract tests

After loading an unmodified or candidate **complete package**, run:

```wolfram
TestReport["code/DesiredContracts.wlt"]
```

Or, from the archive root:

```sh
wolframscript -file code/RunAudit.wl /absolute/path/AsymptoticAnalysis.wl /absolute/path/report.txt
```

Fourteen specifications and controls are supplied. Several are expected to fail on
the baseline. Some remain failing after the two-fix candidate because the remaining
findings require other changes. The runner returns nonzero when tests fail; these
are deliberate desired-contract tests, not a baseline characterization suite.
Run in a fresh kernel: an external abort can interrupt test-local option restoration.

## Independent Python checks

```sh
python -m pip install -r code/requirements.txt
python -m unittest discover -s code -p test_audit_tools.py -v
```

The tests use Python's standard library plus SymPy. They check the patch emitter
against synthetic anchors and independently check the displayed coefficient,
frontier, and storage-ratio arithmetic. They do not load the repository.

## Other prototypes

`code/BenchmarkNativeStorage.wl` provides bounded array sizes and separates native,
dense-expression, and whole-wrapper `ByteCount`. Its timing fields are for a local
run; no timing table is claimed in the article. The 100000-element native observation
was run separately. `ByteCount` is not peak resident memory.

`code/NativeOutcomePrototype.wl` inspects a supplied `HoldComplete[result]` without
re-executing it. It is additive, unintegrated, and not a proof of analytic validity.
It was not natively executed during this audit.

## Build the article

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error audit.tex
```

A normal TeX Live installation with Latin Modern, `microtype`, `amsmath`, `booktabs`,
`longtable`, `listings`, `hyperref`, `footmisc`, and `xurl` is sufficient. The source contains its
citations and has no external bibliography or figure dependency. The supplied PDF
was rendered and inspected; the article is 26 pages.

No checksum files or font files are included. The root upstream license is retained
in `UPSTREAM_LICENSE.txt`; new audit code/material is covered by `LICENSE-AUDIT.txt`.
