# Asymptotic: request preservation and portable evidence

**Read `article.pdf`**; `article.tex` is its complete editable source.

Audited repository: VladimirReshetnikov/Asymptotic  
Pinned revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`  
Review date: September 10, 2026

The article presents three incremental findings after screening the five-wave
review indexes and consolidated register, with selected original-report reads.
It does not reissue the existing general backlog. The screening method and
limitations are explicit in the article and `evidence/novelty-crosswalk.md`.

## Main contributions

N01: The Mathics inline-assumption protector rewrites `Element` used as held
caller data, not only active membership heads. Loading the actual adapter into
an otherwise native Wolfram package changed a public model coefficient from 1
to 2. This is a wrong-request transformation, not an alleged failure of exact
interval arithmetic. The complete Mathics runtime was not executed.

N02: The numerical comparison's `LocalCoordinate` label confuses the source
coordinate with its powered observable. Two actual pinned standalone-package
runs on Wolfram 15 confirm the discrepancy; the numerical values are correct.

N03: The local documentation checker accepts an outside-checkout file when it
exists on the host. Three characterization methods reproduce this using the
exact upstream Python file and actual Pandoc. No current committed broken link
is alleged. The proposed containment policy is stronger and explicit.

## What ran

The successful remote kernel identified itself as Wolfram Language **15.0.0 for
Linux x86 (64-bit), May 6, 2026**. Public numerical probes used the pinned
standalone. The Mathics adapter was separately isolated in that native kernel;
four candidate-rewrite observations were also checked there. These are focused
tool-mediated observations, not a full suite, modular-load test, or Mathics run.
Intermittent network errors preceded the successful calls.

The local Python run passed **23 test methods with no skips**: 19 documentation
characterization/candidate-policy methods and 4 patch-emitter fixture methods.
The original documentation-checker transcription was byte-verified against the
GitHub blob identity. Tests used temporary repositories, not a complete local
checkout. The first draft of one emitter fixture mistakenly used `none` as text
not containing `one`; that fixture was corrected before the recorded passing run.
No upstream defect is attributed to that test-authoring mistake.

## Reproduce the Python checks

Python 3.10+ and Pandoc on PATH:

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
```

A characterization test passes when it reproduces the upstream acceptance gap;
a candidate test passes when it enforces the proposed policy. On systems without
symlink creation permission, the two symlink methods skip. Record such skips
rather than treating that run as identical to the supplied no-skip result.

To apply the candidate link *check* to an existing checkout without editing it:

```sh
python code/portable_links.py /path/to/Asymptotic
```

This integration command was not run against a complete checkout here. The
candidate deliberately rejects all symlink components, local `file:` links,
Windows drive paths and unconfigured root-relative URLs. Relative `../` links
remaining inside the checkout are accepted. Use a stable clean checkout for a
publication check; root containment alone does not establish Git-trackedness or
protect against concurrent filesystem changes. External URLs are out of scope.

## Candidate Wolfram edits

```sh
python code/emit_candidate_patch.py /path/to/Asymptotic > candidate.diff
```

The emitter checks the audited Git HEAD, refuses changes to its two tracked
source targets, validates unique source anchors, and prints a diff. It does not
write the checkout. `--which diagnostics` emits only N02's string correction;
`--which assumptions` emits the narrow N01 rewrite guard. The explicit
`--skip-commit-check` bypass is for consciously selected alternate trees only.
The four emitter tests use synthetic source fixtures, not an upstream patch run.

The N01 candidate is **not a complete semantics-preserving interpreter for
arbitrary Wolfram option programs**. It preserves bare symbol occurrences and
nested held-data barriers, but higher-order/generated predicates and additional
holding constructs require a precisely declared admission policy. Do not treat
the four isolated native examples as Mathics acceptance.

After review and application, regenerate the standalone from the repository's
canonical modular sources using its normal builder. Run the focused regressions
on both actual runtimes before merging. `tests/ReviewRegressions.wlt` is an
unexecuted proposed Wolfram test suite. For a Mathics session, load a known local
standalone and then `Get[".../code/probe_loaded_kernel.wl"]`; that script prints
observations rather than depending on MUnit or claiming an aggregate pass.

The isolated candidate can be examined without changing the package:

```wl
Get[".../code/candidate_assumption_protector.wl"];
Get[".../code/check_candidate_rewrite.wl"];
```

## Build the article

```sh
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

Standard LaTeX packages are used; no external figures, shell escape or separate
font files are needed. `evidence/` contains the scoped observations, test output,
source coverage, novelty crosswalk and PDF inspection record. No checksum files
or complete upstream package distribution are included.
