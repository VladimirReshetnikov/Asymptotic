# Asymptotic 1.8.0 — focused delta audit and native evidence

**Audited snapshot:** `921387e5ba1239bfda96e63e64e89bf63d9c41e6`  
**Repository:** https://github.com/VladimirReshetnikov/Asymptotic  
**Review date:** 9 September 2026

Start with **`article/asymptotic_delta_audit.pdf`**. Its self-contained LaTeX
source is beside it. The report is 25 pages and compares implemented features
with current official Wolfram documentation and selected native executions.

## Findings

**N01 — certificate scope (critical to soundness).** Constructing the inverse
of `ConditionalExpression[x+x^2,x<1/4]` at zero in a clean environment and
then calling its interval certificate under `$Assumptions=x<1/4` can return
`Certified -> True`, root enclosure `{1,1}`, and `SourceDomainVerified -> True`
for the interval `{9/10,11/10}` at target 2. The domain excludes the entire
interval. This materially strengthens prior assumption-provenance finding
C05; it is not presented as a new discovery of ambient assumptions in general.
The narrow fix gives the domain helper's `Refine` call an explicit
`Assumptions -> True` option.

**N02 — flat multiplication work budget (medium).** A depth-8 exact constant
flat object has leaf count 49. Multiplication by 1 at `MaxTerms -> 60` fails
because a dense gate charges 81 pairs despite an already-sparse execution
loop with one active pair. The fix charges active pairs and preserves the
existing exact-zero predicate. It does not erase finite unknown remainders.

## Evidence

The unmodified package and the two-edited temporary standalone were loaded
in a native **Wolfram Language 15.0.0, Linux x86-64** kernel. The final combined
batch passed **10/10 targeted checks**. The full upstream Wolfram test suite
was **not run**, and no canonical checkout was rebuilt locally.

Separately, **20 independent exact mathematical checks** passed, as did
**20 Python tests** (8 patch-transform fixture tests plus 12 tests of the
restricted affine-domain proof checker). These are different test populations,
not 50 upstream Wolfram tests. The native command-line runner's surrounding
file-I/O workflow was not executed locally; the same core checks were executed
through the native evaluator.

`evidence/native_observations.json` contains selected transcribed native
outputs, hashes, evidence scope, and the corrected invalid-center fixture.
`evidence/native_comparison.json` records polynomial, logarithmic, irrational
inverse, and specialized numerical controls. Service errors are not counted
as package failures.

## Contents and commands

`code/patch_spec.json` defines the two source edits.
`code/apply_fixes.py` previews them by default and applies them only with
`--apply`, to a clean Git checkout at the exact audited HEAD:

```sh
python code/apply_fixes.py /path/to/Asymptotic
python code/apply_fixes.py /path/to/Asymptotic --apply
# From the repository root, regenerate the standalone:
python validation/build_standalone.py
```

The patcher edits only canonical source modules, makes backups, and checks
unique anchors. It refuses a different HEAD, modified target sources, missing
or duplicate anchors, or pre-existing backups. Its transformation logic was
tested on fixtures; application to a complete local checkout remains a local
reproduction step. Run relevant upstream suites after rebuilding.

To test an existing pinned standalone in a fresh kernel:

```sh
wolframscript -file code/native_probe.wls /path/to/AsymptoticInverse.wl
wolframscript -file code/native_probe.wls /path/to/AsymptoticInverse.wl --patched
```

The baseline is expected to fail two desired-contract checks. The optional
patch is applied only to a temporary copy. The runner records supplied-file
and loaded-copy hashes; it does not infer Git provenance from the filename.
`code/regression_checks.wl` supplies the ten named checks;
`tests/DeltaAudit.wlt` is a test-framework wrapper. `code/comparison.wl` and
`code/reproduce_certificate.wl` contain additional reproducible inputs.

Independent checks (SymPy is needed for the mathematical oracle program):

```sh
python code/independent_checks.py
python -m unittest discover -s tests -p 'test_*.py' -v
python code/affine_domain_proof.py
```

The affine checker is intentionally limited to exact rational affine
predicates on closed intervals. It verifies neither a complete root certificate
nor arbitrary nonlinear/function domains. It accepts no ambient assumptions
and rejects floating-point inputs and modified proof records.

Rebuild the article:

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_delta_audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_delta_audit.tex
```

The article needs no external images or bibliography file. Repeat LaTeX if
cross-reference warnings remain. `SHA256SUMS.txt` covers the delivered files
other than itself. No Wolfram installation, font files, full repository copy,
or rebuilt paclet is included. No remote repository changes were made.
