# Asymptotic — additional contract audit

Prepared for Vladimir Reshetnikov, 9 September 2026.

Read `article/asymptotic-contract-audit.pdf`. Its complete LaTeX source is next to it.

## Reviewed source and evidence

Repository: https://github.com/VladimirReshetnikov/Asymptotic

Pinned commit: `921387e5ba1239bfda96e63e64e89bf63d9c41e6`

Standalone Git blob: `609eaae41eac2a0f00c9c898b22265375add4306`

Native audit kernel: `15.0.0 for Linux x86 (64-bit) (May 6, 2026)`.

Four findings were reproduced natively on that snapshot:

| ID | Finding | Additional evidence beyond the existing register |
|---|---|---|
| N01 | Ambient assumptions produce a false source-domain certificate. | An excluded root receives `Certified -> True`; sharper than prior ambient-metadata concerns. |
| N02 | Composition silently varies a formerly fixed parameter. | The package returns `1 + O(a^2)` for an expression identically equal to `1/2`. |
| N03 | Opaque-function expansion imports hidden analyticity. | A real function with a truthful derivative receives a false magnitude remainder. |
| N04 | Public routes disagree about real-coefficient admission. | Direct and observable paths accept a nonreal coefficient while scalar and inverse controls reject it. |

The article maps these to the prior review register rather than presenting the entire old backlog again. It distinguishes the algebraically correct complex expression in N04 from the mathematically false bound/certificate claims in N01–N03.

## What ran

The successful native connector observations are transcribed in `evidence/native-observations.json`. This is **not** represented as an automated log from the packaged scripts. Equivalent expressions were evaluated through the connector.

Ten Python mathematical checks and five Python patch-mechanics checks passed. Logs are included. The patch-mechanics tests use explicit small source-anchor fixtures, not a complete upstream source file.

The twelve Wolfram desired-contract tests were **not run as a suite**. The full upstream suite was **not run**. The proposed certificate patch was **not successfully integration-tested natively**; attempted additional runs encountered service/network failures. Those failures are not counted as package defects. No measured performance improvement is claimed.

## Contents

- `article/`: compiled PDF and self-contained LaTeX source.
- `code/reproduce.wl`: native observation harness for the four findings.
- `code/load_pinned.wl`: shared loader with a pinned Git-blob check.
- `code/regressions.wlt`, `code/run_regressions.wl`: twelve desired-contract tests and runner.
- `code/compare_builtins.wl`: optional native comparison probes, unexecuted here.
- `code/make_certificate_patch.py`: fail-closed, source-pinned, review-only patch generator.
- `code/independent_checks.py`, `code/test_patch_generator.py`: executed Python checks.
- `evidence/`: native observations, overlap/delta mapping, inspected-source coverage, Python logs, and layout/static QA.
- `SHA256SUMS.txt`: hashes of all other shipped files.

The upstream repository, upstream package, complete upstream tests, and fonts are not bundled.

## Run independent checks

Python 3.10+; standard library only:

```sh
python code/independent_checks.py
python -m unittest discover -s code -p test_patch_generator.py -v
```

The numerical illustrations in the first script are not substitutes for the exact proofs in the article.

## Reproduce native behavior

Use a fresh Wolfram Language 15.0+ kernel. Loading a package executes its code; review the upstream source first.

```sh
wolframscript -file code/reproduce.wl
wolframscript -file code/run_regressions.wl
wolframscript -file code/compare_builtins.wl
```

The loader downloads the standalone at the pinned commit and checks its Git blob. To use a local standalone, set `ASYMPTOTIC_AUDIT_SOURCE` to its absolute path. For example, in PowerShell:

```powershell
$env:ASYMPTOTIC_AUDIT_SOURCE = 'C:\src\Asymptotic\AsymptoticInverse.wl'
wolframscript -file code/reproduce.wl
```

For an explicitly reviewed modified standalone, `ASYMPTOTIC_AUDIT_ALLOW_MODIFIED=1` overrides the blob match. The loader records the actual hash and override. Do not confuse a focused candidate with a validated release. The wrappers were statically delimiter-checked, but not executed as complete command-line programs in the audit environment.

The observation harness prints results, not pass/fail claims about known bugs. Some desired-contract tests intentionally fail on the unmodified baseline. A refusal by one built-in comparison probe is not evidence of a universal limitation; order conventions differ across APIs.

## Generate the minimal certificate candidate

Obtain the **canonical** `AsymptoticInverse/Kernel/InverseCertificates.wl` at the pinned commit. The generator verifies its Git blob after normalizing CRLF to LF, requires one exact anchor, and refuses to overwrite an existing output directory.

```sh
python code/make_certificate_patch.py /path/to/InverseCertificates.wl --out candidate-certificate
```

The new directory contains a candidate module, unified diff, and manifest. The only source change is:

```wolfram
Refine[condition, Element[x, Reals], Assumptions -> True]
```

in place of the same call without the explicit assumption option.

This candidate isolates **one** certificate normalization call from ambient `$Assumptions`. It does not repair constructor-origin context contamination or N02–N04. Review/apply the canonical diff in a separate worktree, regenerate the root distribution with the upstream `validation/build_standalone.py`, and run the focused regressions and broader upstream validation. The generator has not been exercised on a complete locally mounted upstream module here; only its fixture mechanics were executed.

## Build the article

A standard TeX Live installation with Latin Modern and the packages named in the `.tex` preamble is sufficient. No external bibliography database, images, shell escape, or supplied font files are needed.

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-contract-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-contract-audit.tex
```

The PDF was compiled, rendered, and visually inspected. Local rebuilds may differ in byte hashes because of timestamps or TeX versions.
