# Asymptotic: incremental audit after nine reviews

Prepared 9 September 2026. Pinned repository commit:
`921387e5ba1239bfda96e63e64e89bf63d9c41e6`.

Read `article/asymptotic_incremental_audit.pdf` (source beside it).
The report develops three natively confirmed, materially incremental findings:
false source-domain certification under ambient assumptions, a false trigonometric
error bound after nonreal coefficient admission, and unrepresentable native
series indices despite a one-slot coefficient array.

## Evidence limits

Successful focused experiments used Wolfram Language 15.0.0 on Linux x86-64.
`evidence/native_observations.json` is a curated transcription of those responses,
not an invented complete session log. The whole upstream Wolfram suite and the
complete delivered regression file were not run in this audit. Individual patch
mechanisms and controls were tested separately; they are not a release-qualified
combined patch. The 23 executed Python checks are independent arithmetic and
source-transformation fixture tests, not a Wolfram emulator or package test suite.
No repository file was modified by the audit.

## Contents

- `article/`: complete LaTeX source, bibliography source, and rendered PDF.
- `code/reproduce.wl`: bounded native probes; accepts an explicit local package.
- `code/regressions.wlt`, `code/run_regressions.wl`: eight desired-contract tests
  and a fail-closed runner. The baseline is expected to fail the new contracts.
- `code/apply_candidate_patch.py`, `code/patch_rules.json`: guarded proposal emitter.
- `code/test_independent.py`: the 23 independent checks.
- `evidence/`: snapshot, selected native outputs, novelty ledger, and Python results.
- `patches/README.md`: scope and limitations of the proposals.

## Reproduce

Obtain the repository snapshot independently and use a clean Wolfram kernel.
These commands do not download or overwrite the package:

```sh
wolframscript -file code/reproduce.wl /absolute/path/to/AsymptoticInverse.wl observations.json
wolframscript -file code/run_regressions.wl /absolute/path/to/AsymptoticInverse.wl test-results.json
python code/apply_candidate_patch.py /absolute/path/to/checkout --output /absolute/path/to/new-candidate-directory
(cd code && python -m unittest test_independent -v)
```

The patch emitter refuses a mismatched Git commit, missing/duplicate anchors,
or a destination within the checkout. Review its output before application.
Regenerate the standalone package after applying canonical-source changes.

## Rebuild the article

Requires a standard TeX Live installation with latexmk, pdfLaTeX, lmodern,
microtype, geometry, amsmath, amsthm, booktabs, longtable, listings, xcolor,
xurl, fancyhdr, enumitem, needspace, and hyperref.

```sh
make pdf
```

The article can also be built by running `latexmk -pdf` in `article/`.
