# Asymptotic — regularity contracts and structural work

An incremental technical audit for Vladimir Reshetnikov.

**Repository:** VladimirReshetnikov/Asymptotic  
**Audited commit:** `651f2029d0b2cd4da9e4dfdf1f4275a124d23b99`  
**Commit timestamp:** 2026-09-10 13:42:02 UTC  
**Article date:** 10 September 2026

Start with **article.pdf**. **article.tex** is the complete editable source.
The report uses the existing four-wave review register as an exclusion map,
with direct comparison of the relevant sections of review 14. It does not
reissue the existing development backlog.

## Findings

| ID | New contribution | Validation status |
|---|---|---|
| N01 | The ordinary `SeriesObservable` path can preserve a derivative contract through an absolute value of a pure remainder, even though a permitted real smooth input produces infinitely many cusps. | Pinned source trace, rigorous counterexample, independent checks; public native sequence unrun. |
| N02 | The recently added affine-recognition path is repeatedly invoked on overlapping nonlinear subtrees. A canonical Horner family has exactly `4(d+1)^2-1` recognizer invocations in the inspected recursive control structure. | Source analysis, exact counts, and independent rational-interval reference implementation; native timings unrun. |
| N03 | Bound-preserving truncation finds discarded rows with repeated general membership queries even when the retained rows are an identical prefix. | Source analysis and tested guarded-prefix model; the comparison counts are not claims about undocumented native `MemberQ` optimizations. |

N01 is a classical-regularity defect, not an incorrect magnitude bound. N02
does not dispute the earlier affine-cancellation repair. N03 does not reissue
the earlier missing-bound-transport finding: it changes the selection algorithm
inside that newly implemented transport.

## What actually ran

- **14 independent Python tests passed**, including 300 randomized expression trees, 2,100 exact rational sample points, 500 prefix cases, exact derivative recurrences, and structural work counts.
- **6 patch-emitter fixture tests passed.** These used synthetic source fixtures, not a complete upstream checkout.
- The PDF was compiled, rendered, and inspected. The supplied Wolfram code received a lexical delimiter/string/comment check, not a native semantic validation.

**No Wolfram or Mathics package execution succeeded in this audit.** The remote
kernel connections failed, and no local kernel was available. No patched native
run, full upstream-suite result, or native speedup is claimed. The source was
inspected through pinned GitHub reads, not a complete local checkout. See the
article's coverage appendix and `evidence/audit_manifest.json`.

## Reproduce the independent checks

Python 3.10 or later; standard library only. Run from this directory:

```sh
python code/verify_independent.py
python code/test_patch_emitter.py
```

These commands overwrite their own result records under `evidence/` with the
new run's outcomes. They do not access the network or load the Wolfram package.

## Emit candidate edits without changing the repository

```sh
python patches/emit_candidate_patch.py /path/to/Asymptotic > candidate.diff
```

The emitter requires the audited Git `HEAD` by default, checks that each source
anchor occurs exactly once, and prints a unified diff. It never applies the
diff or writes to the checkout. Use `--which regularity` or `--which prefix` to
emit only one edit. `--skip-commit-check` is an explicit override for a
consciously selected unversioned or changed source tree; the anchor checks remain.

The two edits are **native-unverified candidates**:

- The regularity edit conservatively resets the derivative-order contract to zero for an inexact ordinary observable containing `Abs`. It can discard useful regularity in valid sign-known cases. The article describes a more precise sign-aware transfer rule.
- The prefix edit structurally verifies the common retained-prefix case and extracts the discarded suffix directly. Nonprefix input retains the old fallback, and the subsequent bound formula and conditions are unchanged.

After reviewing/applying a diff, rebuild the standalone through the repository's
`validation/build_standalone.py` and run focused native regressions plus the
normal upstream validation. Editing only the generated root distribution is
not a canonical-source update. No production certificate-engine replacement is
supplied for N02; its bottom-up annotation design is implemented in the separate
independent rational model.

## Run the native observations locally

Use a fresh Wolfram kernel and an existing checkout. In PowerShell:

```powershell
$env:ASYMPTOTIC_REPO = 'C:\src\Asymptotic'
wolframscript -file code/run_native.wls
```

Or in a POSIX shell:

```sh
ASYMPTOTIC_REPO=/path/to/Asymptotic wolframscript -file code/run_native.wls
```

The runner records the actual kernel version and Git revision, the N01 public
operation chain and exact control, N02 Horner-family interval observations,
and N03 public Zeta truncations. Each observation has a time limit. Raw returned
expressions and messages are preserved as strings.

By default it creates `evidence/native_observations.json`; set
`ASYMPTOTIC_AUDIT_OUTPUT` to another existing-directory file path to preserve
separate baseline and patched records. That output is deliberately **not**
pre-populated in this archive. Exit code zero means observations were written,
not that the defects or proposed fixes passed. Inspect the results, timeouts,
messages, and observed revision. This is not a complete upstream test runner or
a claimed Mathics-compatible runner.

## Rebuild the article

Use a TeX distribution with pdfLaTeX, Latin Modern, amsmath/amsthm, geometry,
booktabs, longtable, tabularx, listings, microtype, xurl, fancyhdr, and hyperref:

```sh
sh build.sh
```

On Windows, run the following three times:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The PDF has embedded fonts; separate font files are not required or supplied.

## Contents

The article contains the counterexample proofs, exact structural recurrences,
implementation alternatives, acceptance criteria, source-coverage record,
novelty crosswalk, and references pinned to the audited revision. Supporting
files contain the independent models, recorded test outcomes, conservative
patch emitter, and unexecuted native observation runner. No upstream package
distribution or fabricated native results are included.
