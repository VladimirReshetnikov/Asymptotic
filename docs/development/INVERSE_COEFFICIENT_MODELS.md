# Inverse coefficient model admission

`InverseExpansionCoefficient` computes a Lagrange coefficient from an ordinary
inverse model. A `GeneralizedSeries` head alone does not imply that this model
exists. This repair addresses W3-08, report 22 A01, and the associated C11/D02
capability concern. The separate C09 stored-versus-explicit `"Power"` precedence
issue remains open.

## Public behavior

The query checks the model association before reading inverse-only fields.
It requires the gap and polynomial lists to have equal lengths, a symbolic
log variable, a Boolean symbolic-depth marker, and a nonzero leading power.
An object also needs its stored power and expansion point. This is a schema
and capability check, not a new certification of arbitrary user-built models.

Unsupported forward, derived, exact-core, and Fourier objects now return
`Failure["UnsupportedCoefficientModel", ...]` without `Join::incpt` or subsequent
generic argument errors. Incomplete raw model associations receive the same
specific refusal. Ordinary models continue to validate the multi-index and
return `"InvalidMultiIndex"` for a wrong dimension or invalid entry.

The guard preserves zero-dimensional models and their empty multi-index `{}`.
It does not require a positive leading power: reciprocal coordinates at source
infinity use a negative leading power. Retained parameter assumptions and
symbolic-depth coefficients follow the existing computation. Native and
logarithmic results keep their established `"NativeSeriesContract"` and
`"Unsupported"` tags respectively. Compatible retained models remain usable;
admission does not impose a new blanket whitelist of result kinds.

See the [user reference](../../src/Documentation/UserGuide.md#InverseExpansionCoefficient)
for the supported query and returned fields. This change does not alter the
mathematical coefficient formula or the article's hypotheses.

## Focused evidence

The [eleven-case baseline](../../validation/inverse-coefficient-model-baseline.json)
records the 55-module source snapshot at `1a183a8`. Forward, derived, exact-core,
and Fourier queries emit `Join::incpt`; an empty model is misclassified as an
invalid multi-index. The [same probes after the repair](../../validation/inverse-coefficient-model-after-fix.json)
record message-free specific refusals, with the ordinary, native, invalid-index,
empty-index, and infinity controls preserved. Each probe has a twenty-second
limit; neither run has a timeout. The receipt records the probe's hash as well
as the module hashes and their stability.

The [first focused run](../../validation/inverse-coefficient-model-first-pass.json)
is preserved at `4f42d22`: 96 passed and three failed. Two new expectations used
global symbols while the actual values contained `Module`-local symbols; the
corrected fixtures compare inside that scope. An existing cutoff test expected
package refusal while allowing automatic native fallback. It now selects
`"Backend" -> "Package"` explicitly.

The [completed run](../../validation/inverse-coefficient-model-tests.json)
passes **99/99** on Wolfram 15.0.1: 16 new capability tests, 49 ordinary inverse
tests, 10 expanded-input tests, 17 stored-assumption tests, and seven native
presentation tests. All recorded inputs stayed unchanged. The
[local loading check](../../validation/inverse-coefficient-model-loading-tests.json)
separately checks the generated standalone file and maintained entry points
with **105/105** checks in five fresh kernels. The
[evidence audit](../../validation/inverse-coefficient-model-evidence-audit.json)
matches all baseline and first-pass inputs to the stated Git blobs and all
accepted-run inputs to the repair checkpoint. These checks do not establish Mathics acceptance; its
empty-list evaluator issue is tracked separately as W4-04. The full package
suite remains skipped.
