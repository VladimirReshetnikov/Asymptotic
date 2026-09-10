# Provenance growth and lifted-operand templates

P07 in the [review register](CODE_REVIEW_STATUS.md) asked for measurements of
retained recipe and cache size before any shared-node, compact-serialization
or cache-elision work (R1 A13, R4 A04, R7 R02). W3-04 in the
[wave-3 intake](WAVE_3_INTAKE.md) asked for fixed-support measurements of the
eagerly stored native finite expression. This note records both measurements
on Wolfram 15.0.1 for Windows, the one structural defect they exposed, its
repair, and what remains a design decision rather than a defect.

The measurement script is
[MeasureProvenanceGrowth.wl](../../validation/MeasureProvenanceGrowth.wl). It
asserts nothing. For each object it records `ByteCount` (which charges every
occurrence of a shared subexpression), `LeafCount`, the character counts of
`Compress` and `InputForm` (serializations, which share nothing), the number
of `GeneralizedSeries` nodes reachable through operation recipes counted as a
tree and as a set of distinct objects, the recipe depth, and the difference
of `MemoryInUse[]` around holding the object after `ClearSystemCache[]`, which
estimates the memory the object actually retains. The
[baseline receipt](../../validation/provenance-growth-baseline.json) measured
the kernel exported from commit `8d42b5d`, before the repair below; the
[current receipt](../../validation/provenance-growth-measurements.json)
measured the repaired kernel. Both loaded their kernel with unchanged sources.

## What operation recipes retain

Every derived object stores `"SeriesRecipe" -> {operation, {operands...}, ...}`
with the complete operand objects, so that `SeriesRefine` can replay the
operation at a new cutoff. Three chains were measured for eight steps from
`s = AsymptoticExpansion[Exp[x], {x, 0, 6}]`:

| Chain | Step 8 tree nodes | Step 8 distinct objects | Step 8 `ByteCount` | Step 8 `InputForm` chars | Retained bytes per step |
| --- | --- | --- | --- | --- | --- |
| `t -> SeriesAdd[t, t]` | 511 | 9 | 4,260,608 | 564,501 | about 5,300 |
| `t -> SeriesMultiply[t, s]` | 17 | 9 | 139,736 | 19,025 | about 5,300 |
| `t -> SeriesPower[SeriesAdd[t, 1], 2, 6]`, baseline | 1021 | 25 | 7,064,056 | 1,029,152 | about 14,000 |
| `t -> SeriesPower[SeriesAdd[t, 1], 2, 6]`, repaired | 33 | 32 | 257,496 | 40,501 | about 14,000 |

Two facts follow.

**In memory the recipe tree is a DAG.** The retained-memory estimate grows
by a constant per step in every chain, including self-addition, because the
kernel shares the repeated operand by reference. `ByteCount` counts the tree
and overstates the self-addition object by a factor near 500 at step 8. The
reported "exponential history growth" (R4 A04) is therefore a property of
serialization, not of the live object.

**Serialization of a repeated reference is exponential, and one ordinary
chain repeated a reference without the user asking for it.** For
`SeriesAdd[t, t]` the doubling is inherent to whole-operand recipes: the
user's expression references `t` twice, and `InputForm`, `Compress`, `Put`
and `Export` write the tree. Doubling also appeared in `t + 1`, where the
user references `t` once: a scalar or regular operand is lifted onto the
chart of the series beside it, and the lifted operand's recipe
`{"RegularOperand", {s}, e, op}` retained that whole series as its template.
The sum's recipe then held `t` once as an operand and once more inside the
lifted `1`, so the tree, `InputForm` and `Compress` size of an `n`-step
`t + c` or `t e` chain grew like `2^n` (1021 nodes and a megabyte of
`InputForm` at step 8) while the live object stayed linear.

## Repair: chart templates

A lifted scalar (`"Constant"`) or regular operand (`"RegularOperand"`) now
records `seriesRecipeTemplate[s]`, the series `s` with its own
`"SeriesRecipe"` removed: the chart data (variable, scale, assumptions,
representation) that lifting needs, without the ancestry the sibling operand
already carries. Replay does not refine a template. `SeriesRefine` passes the
stored template to `seriesRegularOperand` or `seriesConstant` unchanged and
re-expands the lifted expression to the working cutoff against it; the outer
operation still clips to its transported precision. The composition scope
walker (C15) treats a template recipe as complete data: the lifted operand
is determined by its expression and the chart, both retained, and the
template's ancestry is reachable through the sibling operand.

After the repair the `t + 1` chain has `3n + 1` reachable nodes and its
`InputForm` grows by about 5 kB per step. Refinement of `Exp[x] + 3`,
`Exp[x] Sin[x]`, `(Exp[x] + 2) Cos[x] + 1/3` and `(1/x + 1) Exp[x]` chains
reproduces the fresh expansions at the new cutoffs, including the negative
leading valuation whose margin the replay already accounted for. The
[recipe-template run](../../validation/recipe-template-tests.json) from
[CheckRecipeTemplates.wl](../../validation/CheckRecipeTemplates.wl) passes
**153/153** across eleven files: the two new
[provenance-growth regressions](../../src/Tests/ReviewProvenanceGrowth.wlt),
the refinement, arithmetic, operation, bound-transport, composite,
flat-sector, envelope and result suites, and the composition-scope suites
that exercise the walker. No full package suite was run.

## What remains a decision

- **Repeated references stay repeated in serialization.** `SeriesAdd[t, t]`
  and any expression that names one derived object twice serialize its
  recipe tree twice per level. A DAG serialization (shared immutable nodes
  with identifiers) would remove this at the cost of a new object format and
  its migration; the live object does not need it. This is the P07 design
  lane, now with measurements, and it is not implemented.
- **Refinement caches are retained by design.** An inverse at cutoff 12
  retains about 30 kB; its coarser view at cutoff 4 keeps the larger cache
  (about 40 kB with the view) and a later refinement to 16 about 98 kB. D10
  records this retargeting as intentional.
- **Native fixed-support storage is linear in the nonzero terms (W3-04).**
  `AsymptoticExpansion[1/(1 - x^7), {x, 0, 7 k}, "Backend" -> "Series"]` for
  `k = 1..8` stores a `SeriesData` of `7 k + 1` dense coefficients (384 to
  1,560 bytes) and an eagerly evaluated finite expression of `k + 1` terms
  (144 to 704 bytes) inside an object of 5 to 7 kB. `Normal` of a sparse
  native series is a sparse polynomial, so the eager evaluation does not
  densify fixed-support output; the measured object is dominated by fixed
  request and provenance metadata. Demand-driven `Normal` remains a design
  choice for very long dense native results, not a storage defect at fixed
  support. Byte counts are not peak memory and not a speed claim.

Return to the [development index](README.md).
