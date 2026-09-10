# Asymptotic: source-pinned incremental correctness audit

**Reviewed revision:** `8f280847bf8fd1f6488834cadf1542867292ce10`  
**Repository:** VladimirReshetnikov/Asymptotic  
**Review date:** 10 September 2026

Read `article/review.pdf` (or its complete LaTeX source, `article/review.tex`).

## Main result

One new soundness regression is isolated in the recently integrated affine Lerch constructor. At a nonpositive exclusive cutoff, an omitted constant can inherit the strictly positive remainder exponent of the special-function atom. For `1 + LerchPhi[1/2,2,x]` at cutoff zero, the source predicts a zero approximation with bound `3/x^2`. At `x=2`, the defining series proves that the actual error is at least `5/4`, exceeding the predicted bound `3/4`. The correct common power order is zero.

This is not a repetition of report 55's earlier affine-admission request. It concerns the new direct integration's remainder calculation. Other existing findings and their roadmaps were not repackaged as new discoveries.

## Evidence boundary

**No Wolfram or Mathics execution succeeded in this environment.** Public outputs are source-derived predictions, not captured runtime outputs. A complete local upstream checkout was not obtained. The candidate emitter was not applied to a complete upstream checkout, and no patched package was executed.

The executed tests are **20 independent Python test methods and 4 synthetic patch-emitter fixture methods**, all passing. The 3,000 concrete Lerch cases and 725 abstract grade cases occur inside those test methods; they are not additional method counts. A separate finite-source identity was checked with SymPy. The finite identity's public dispatcher reachability is expressly unestablished.

## Files

`article/` contains the PDF and buildable TeX source. `code/affine_tail.py` is an independent exact-rational reference model and defining-sum oracle, not a replacement for the Wolfram package. The two unittest files verify that model and the patch emitter's synthetic anchors. `code/emit_affine_lerch_patch.py` produces a narrowly scoped candidate diff from a separately obtained checkout of the pinned revision. `code/ProbeAffineLerch.wl` and `code/ReviewAffineLerch.wlt` are unexecuted baseline characterization and desired-contract tests. `evidence/` records scope, novelty, coverage, exact counterexample data, counts, and executed logs.

## Reproduce the independent evidence

```sh
cd code
python -m unittest -v test_affine_tail test_patch_emitter
```

These tests need only the Python standard library. The optional identity check needs SymPy (the recorded run used 1.14.0):

```sh
python check_finite_identity.py
```

## Emit, but do not automatically apply, the candidate

```sh
python code/emit_affine_lerch_patch.py \
  --repo /path/to/Asymptotic \
  --output /path/outside/checkout/affine-lerch-candidate.patch
```

The emitter checks the Git revision and five unique text anchors. It refuses an existing output path and writes outside the checkout. It never edits the checkout. Changes in a newer upstream revision require source review and a rebase of the candidate.

The candidate preserves retained rows and joins the atom error with the weight-zero omitted constant. It updates the bound, power, scale and frontier consistently. Its main witness bound is the conservative constant `3`; the independent Python model additionally exposes the sharper pointwise alternative `1 + 2/x^2`, which is not the emitted source patch's bound.

## Kernel validation still required

Set `ASYMPTOTIC_ROOT` to the pinned checkout and run the plain characterization file in a disposable kernel. The file loads the canonical package and prints actual version and object fields. Example Wolfram command:

```sh
wolframscript -file code/ProbeAffineLerch.wl
```

For Mathics, use the installed CLI's file mode (commonly `mathics -f code/ProbeAffineLerch.wl`); verify that CLI locally. No Mathics command in this archive has been executed here. The `.wlt` file contains eight expected-contract tests, but availability of a MUnit runner on Mathics is not assumed. After the candidate is applied to a disposable copy, rebuild the distributed forms using the repository's own workflow and validate canonical and rebuilt loading forms separately.

## Build the article

```sh
cd article
pdflatex -interaction=nonstopmode -halt-on-error review.tex
pdflatex -interaction=nonstopmode -halt-on-error review.tex
```

The source uses standard LaTeX packages and does not require shell escape. No checksum files, font files, upstream binaries, or fabricated native transcripts are included.
