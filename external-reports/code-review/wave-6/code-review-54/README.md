# Asymptotic: interval geometry and Mathics rewrite contracts

Prepared for Vladimir Reshetnikov. Read **article.pdf**; **article.tex** is the
complete self-contained LaTeX source.

Reviewed repository: `VladimirReshetnikov/Asymptotic`  
Reviewed revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`  
Commit timestamp: September 10, 2026, 17:10:56 UTC.

## Retained items

| ID | Contribution | Evidence boundary |
|---|---|---|
| N01 | Odd interval powers lose monotone endpoint geometry across zero, obstructing derivative separation for a quartic equation with an exact center. | Source, proof, independent exact interval model. Public package call unexecuted. This is a safe but unnecessarily wide enclosure, not a false certificate. |
| N02 | Mathics assumption protection replaces bare `Element` symbols used as program data. | Source transformation and a bounded AST countermodel. Public coefficient consequence unexecuted. |
| N03 | Numerical logarithm recovery uses rounded signs as exact branch premises. | Exact negative-factor family, primary upstream Mathics source, and a 53-bit mpmath policy model. Actual Mathics signs and full public fallback trigger unexecuted. |
| N04 | Local numerical metadata confuses the positive source root coordinate with a signed power observable. | Source assignments and exact coordinate identities. No wrong numerical formula is alleged. |

The novelty screen used the retained review index, implementation register,
wave crosswalks, and closest original materials. It did not reread every page
of all historical reports. `evidence/novelty-ledger.json` states the nearest
prior IDs and the specific differences; the article does not reissue the
existing backlog.

## What actually ran

**34 independent Python test methods passed, with no failures or errors:**
28 model tests and six patch-emitter fixture tests. Nested deterministic test
families are described separately in the evidence. No test in this count loads
the repository. The article was compiled and rendered for visual inspection.

**No Wolfram or Mathics package run succeeded in this audit environment.**
The remote Wolfram service failed and no local kernel was installed. The WL
probes and candidate source edits are unexecuted and not accepted production
fixes. There is no claimed native speedup or complete package acceptance run.

## Reproduce independent evidence

Python 3.10 or later and mpmath 1.3.0 are required. From the bundle directory:

```sh
python code/run_independent.py
```

The command overwrites `evidence/independent-results.json` and
`evidence/test-output.txt`. It makes no network request, invokes no native
kernel, and changes no upstream checkout. Copy the delivered receipts elsewhere
before rerunning when preserving them matters.

`code/independent_models.py` is deliberately not a WL interpreter. Its interval
oracle uses mathematical endpoint hulls independently of the transcribed binary
interval recurrence. Its AST model only isolates the held-tree replacement.
Its 53-bit numerical experiment is an arithmetic-policy model motivated by
Mathics 10.0.1 source, not a Mathics execution.

## Inspect candidate edits

Use an existing checkout of the audited revision:

```sh
python patches/emit_candidate_patch.py /path/to/Asymptotic
python patches/emit_candidate_patch.py /path/to/Asymptotic --which power
```

Choices are `power`, `assumptions`, `log`, `label`, and `all`. The emitter checks
Git HEAD and unique source anchors. It prints a diff only after every selected
edit validates. It **never writes to the checkout**. The explicit
`--skip-commit-check` option is for a consciously selected changed or unversioned
tree; unique-anchor checks remain mandatory.

The emitted edits are candidates. They were tested against synthetic anchor
fixtures, not a full checkout. After separately reviewing and applying a diff,
rebuild the standalone artifact through the repository's
`validation/build_standalone.py` and execute focused tests in fresh Wolfram 15
and Mathics processes. Do not edit only the generated root distribution.

The assumption patch fixes bare-symbol rewriting but does not promise semantic
transparency for arbitrary quoted membership programs. The logarithm patch is
an intentionally conservative exact-positive grammar; unknown positive factors
may remain unsplit rather than being guessed positive.

## Native characterization (unexecuted)

In a fresh kernel:

```wl
$AuditPackagePath = "/absolute/path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl";
Get["/absolute/path/to/bundle/code/native_probe.wl"];
```

Use distinct fresh processes and separate output files for baseline and candidate
sources. The probe prints the actual runtime version and raw observations, not
an invented success receipt. It labels its revision as expected rather than
verified. Record the actual checkout revision externally. Reaching the last
print statement is not a pass.

`code/desired_regressions.wlt` supplies eight desired tests, including guarded
Mathics-only cases. It is not a claim that Mathics supports the complete Wolfram
MUnit format. Use an appropriate test harness and inspect whether each case
actually executed. No native observation results are pre-populated in this ZIP.

## Rebuild the document

```sh
sh build.sh
```

Or run `pdflatex -interaction=nonstopmode -halt-on-error article.tex` three times.
The article uses standard LaTeX packages listed in its preamble. Its bibliography
is embedded in the `.tex` file. Separate font files are neither needed nor
included.

## Files

`article.*` contains the report. `code/` contains independent models/tests and
unexecuted WL probes. `patches/` contains the diff emitter. `evidence/` contains
actual independent receipts, environment and coverage records, the novelty
ledger, and document preflight. The archive includes no checksum files or full
upstream package distribution. No remote repository was modified.
