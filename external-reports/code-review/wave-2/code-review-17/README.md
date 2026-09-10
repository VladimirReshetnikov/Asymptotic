# Asymptotic — differential audit (9 September 2026)

**Audited revision:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6` of
`VladimirReshetnikov/Asymptotic`, package 1.8.0.

Start with **`article/asymptotic_delta_audit.pdf`**. Its editable source is
`article/asymptotic_delta_audit.tex` (self-contained, no downloaded assets).
The article contains a comparison with native Wolfram Language, four specific
new or sharper findings, mathematical proofs, and a concrete derivative-tail
extension. `evidence/novelty_matrix.json` maps these contributions to the closest
existing reviews and records the deliberately excluded topics.

## What is included

- `patches/`: exact before/after replacement blocks for the certificate proof
  step and flat-tail projection. These are narrow candidate patches, not a
  complete fork or a claim that every ambient-assumption problem is fixed.
- `code/apply_patches.py`: local-checkout patch utility; dry run by default,
  revision check, exact single-occurrence anchors, backups, atomic per-file writes.
- `code/reproduce.wl`: baseline/patched native probes; preserves raw native
  outputs and finite-precision metadata. The package path is a required argument.
- `code/acceptance.wlt`: corrected-behavior integration specifications. The
  baseline is expected to fail the N1 and N2 repaired-behavior tests. The entire
  file was not run as a suite during this audit.
- `code/independent_checks.py`: independent flat-coefficient derivation,
  tagged-tail model, and direct versus normalized numerical error computation.
- `code/test_patch_utility.py`: reproducible synthetic-fixture checks, including
  preservation of LF and CRLF line endings and byte-for-byte backups.
- `code/check_zeta_bounds.py`: independent numerical checks of the proved
  derivative-tail bound.
- `code/zeta_tail_derivatives.wl`: a standalone proposed bound function with
  explicit conditions, not an installed package API or interval certificate.
- `evidence/`: successful native observations, independent executed results,
  novelty screening, patch-utility tests, and environment information.

## Evidence and limitations

Focused native executions used **Wolfram Language 15.0.0 for Linux x86 (64-bit)
(May 6, 2026)**. The certificate witness and its clean control were reproduced;
a narrow patched version rejected the invalid interval and retained a valid
control. The flat-product precision sequence `{-4,-6,-8}` and patched sequence
`{-1,-1,-1}` were both reproduced. Native numerical-resolution and built-in
comparison examples were also executed.

`native_observations.json` is a faithful transcription of successful connector
responses, **not a raw kernel log**. Remote source replacements tested the same
executable patch logic; whitespace/comments differed from the distributed text.
Several other remote calls failed with network/HTTP errors. Those failures do
not imply package failures, timeouts, or performance defects.

The independent tests passed **4,000 seeded bound-model cases and two edge
cases**, **28 derivative-tail numerical cases**, and **17 patch-utility fixture
checks**. They are not native package tests. There was no full upstream-suite
run, no full formal verification, and no measured package-wide performance
benchmark. The article carefully distinguishes a false certificate (N1), a
valid but weak bound (N2), unresolved numerical evidence (N3), and an overbroad
capability comment (N4).

## Reproduce against a local checkout

Use a separate checkout at the audited revision. The patch utility does not
clone or download repositories and never pushes changes remotely.

```sh
git clone https://github.com/VladimirReshetnikov/Asymptotic.git
cd Asymptotic
git checkout --detach 921387e5ba1239bfda96e63e64e89bf63d9c41e6
cd ..
```

From this extracted audit bundle, run baseline probes first:

```sh
wolframscript -file code/reproduce.wl /absolute/path/Asymptotic/AsymptoticInverse.wl
python code/apply_patches.py /absolute/path/Asymptotic
python code/apply_patches.py /absolute/path/Asymptotic --write
```

The utility changes the **modular sources only**. In the repository checkout,
regenerate and verify the root standalone using the repository builder:

```sh
python validation/build_standalone.py
python validation/build_standalone.py --check
```

Then rerun `reproduce.wl` against the regenerated standalone. A `.pre-delta-audit`
backup is retained next to each modified modular source. To test just one patch,
use `--patch certificate` or `--patch flat_tail`. Applying to another revision
requires the explicit `--allow-other-revision` flag and still requires exact
single-occurrence anchors. Do not blindly force a failed patch.

To run the supplied integration specifications in a native kernel, first load
the intended package, then invoke `TestReport` on the absolute path to
`code/acceptance.wlt`. Run both the modular and regenerated standalone loading
paths and the upstream suite before treating the changes as release-ready.

## Independent checks

```sh
python -m pip install -r code/requirements.txt
python code/independent_checks.py
python code/check_zeta_bounds.py
python code/test_patch_utility.py
```

These scripts overwrite only their corresponding JSON results under `evidence/`.
The normalized correction example avoids subtracting source roots separated by
about `2.58e-863`; it is numerical evidence, not a certificate.

## Rebuild the article

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic_delta_audit.tex
```

Standard TeX Live packages are sufficient. The bundle contains no font files.
All repository citations in the article are pinned to the audited revision.
`SHA256SUMS` covers the distributed files other than itself.
