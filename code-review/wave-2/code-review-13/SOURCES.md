# Source and evidence map

All repository claims are scoped to commit **921387e5ba1239bfda96e63e64e89bf63d9c41e6**. URLs below are immutable source locators; function names are preferable to line numbers after applying any patch.

## Non-duplication baseline

- Review index: https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/code-review/README.md
- Consolidated review register: https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/docs/development/CODE_REVIEW_STATUS.md
- Targeted earlier discussion (review 2): https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/code-review/code-review-2/article/asymptotic-review.tex

The maintained register supplied the cross-review map. The audit did not reread every line of all nine earlier articles. A1 has a different mechanism from C04 and C12; A2 sharpens C07; A3 develops the numerical-resolution aspect of the existing numerical-evidence/API discussion. Older findings are attributed, not presented as newly discovered.

## Source anchors for the findings

### A1

Core module: https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/AsymptoticInverse.wl

Inspect `canon`, `compare`, `jetMerge`, `jetProductBoundaryDegree`, `pMul`, `forwardCore`, `makeForwardObject`, and normalized inverse-model construction. Directly read source windows included 1–180, 180–340, 340–500, 490–650, 990–1055, and 1050–1210. These windows are a record of selected coverage, not a claim of complete module review.

The source patcher expects Git blob `e01210c050dc923215c08d808db52fab140a7c4a` and the unique anchor:

```wl
groups = GatherBy[{canon[#[[1]]], #[[2]]} & /@ terms, First];
```

Internal equality-aware precedent, `fourierWeightGroups`:
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/FourierCoefficients.wl

Native outputs: `results/native_observations.json`, `merge_baseline` and `merge_after_transformation`. Mathematical proof: article Section 3. Independent algorithm model: `tests/independent_oracles.py`.

### A2

Core anchors: `exactQ`, `validateInput`, `pConst`, `fwdAnalytic`, inverse result construction.

Existing sufficient real-domain machinery:
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/SpecialFunctionRealDomain.wl

Real-only envelope contracts:
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/SeriesEnvelopeArithmetic.wl

Native outputs: `results/native_observations.json`, `real_domain`. Principal-branch proof and distinction between correct complex algebra and a failed real contract: article Section 4.

### A3

`numericalInverseEvidence`:
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/NumericalInverseChecks.wl

Separate certificate route (not shown false by this audit):
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse/Kernel/InverseCertificates.wl

Native values including backtick accuracy annotations: `results/native_observations.json`, `numerical`. Exact positive rational error bracket: `results/independent_oracles.json`, `numeric_oracle`. Derivation: article Section 5.

## Broader coverage

The article's Appendix A lists all 13 modules whose relevant paths were directly inspected. Other engine families were compared primarily through the README, public interfaces, imports and review register, not an exhaustive reread of their implementations.

Repository overview:
https://github.com/VladimirReshetnikov/Asymptotic/blob/921387e5ba1239bfda96e63e64e89bf63d9c41e6/README.md

Pinned standalone used for native examples:
https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/921387e5ba1239bfda96e63e64e89bf63d9c41e6/AsymptoticInverse.wl

## Official Wolfram references consulted

Consulted 9 September 2026. Public documentation describes capabilities, not a promise that every call succeeds on every version.

- https://reference.wolfram.com/language/ref/Asymptotic.html
- https://reference.wolfram.com/language/ref/AsymptoticSolve.html
- https://reference.wolfram.com/language/ref/Series.html
- https://reference.wolfram.com/language/ref/InverseSeries.html
- https://reference.wolfram.com/language/ref/SeriesData.html
- https://reference.wolfram.com/language/ref/GatherBy.html
- https://reference.wolfram.com/language/ref/ArcSin.html
- https://reference.wolfram.com/language/ref/WorkingPrecision.html
- https://reference.wolfram.com/language/ref/Accuracy.html

Native comparison results are scoped to the specific inputs and the reported Wolfram 15.0.0 Linux environment. An unevaluated result is not a proof of general impossibility, and an exact retained expression is not counted as an incorrect asymptotic answer.
