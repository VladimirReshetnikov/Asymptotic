# Which inverse, and which derivative?

A differential source audit of **VladimirReshetnikov/Asymptotic**, pinned to
`8e859961d7d37f008b826f3a8cad406460271614` (2026-09-10 04:00:14 UTC).

Read `article/article.pdf`; its editable source is `article/article.tex`.

## Findings

**N1 — inverse-branch identification.** A real root on the selected source side
need not be the endpoint-incident inverse branch. An approximation can itself
be an exact root on another component, making an equation-root discrepancy zero.
The cubic and quartic witnesses have true selected-branch errors 1/4 and 3/8,
respectively. The quartic's remote root also has the expected derivative sign.
The source acceptance gap and mathematics are established; the public Wolfram
output is a prediction, not an observed native transcript.

**N2 — derivative-bound scope.** The special Gamma/LogGamma adapter exposes a
LogGamma derivative lower bound under `OriginalDerivativeLowerBound`, although
the stored original function may be scaled or exponentiated. Half-scale LogGamma
is an exact counterexample to the natural original-equation interpretation.
The helper supplies explicitly scoped transformed and original-magnitude bounds.
No internal false interval certificate has been demonstrated from this field.

## Novelty and source scope

The exclusion comparison used maintained records for 36 prior reviews and 231
attributed entries, plus relevant indexes and original numerical-review material.
These are not counts of current distinct bugs. It did not include a line-by-line
reread of all 36 articles. `evidence/novelty-ledger.json` identifies nearby prior
items and the precise differences. Existing backlog findings and roadmaps are
not reissued as new recommendations.

Source was read through the GitHub connector; there was no complete local
checkout. The source map and article distinguish broad section coverage from
complete-file inspection. All repository links are pinned.

## What was executed

**28 independent Python unittest methods passed**, with zero failures, errors,
or skips in the final run. They include 12 exact scaled-polynomial subcases and
18 derivative-transport family/scale/point subcases. These subcases are inside
the method count, not additional package tests. Exact rational/algebraic checks
and 80-decimal mpmath samples are labeled separately.

**Not executed:** the repository in Wolfram or Mathics; the Wolfram helper;
the native characterization; the seven native desired-contract/positive-control
tests; the upstream suite; fresh CI; any package-wide benchmark. The Wolfram
service failed at the connection boundary, and the local runtime lacked Mathics.
A lexical delimiter check of the WL files is not execution or parsing by a kernel.

## Independent reproduction

From this directory, in an environment with the indicated dependencies:

```sh
python -m pip install -r requirements.txt
python code/run_review.py
```

The runner regenerates `evidence/independent-results.json` and
`evidence/python-tests.txt`. Preserve a copy of the supplied records before
comparing later runs. The exact oracle can be used directly:

```python
import sys
sys.path.insert(0, "code")
import sympy as sp
from branch_reference import endpoint_branch_reference

x = sp.Symbol("x", real=True)
f = x + 8*x**2 - 16*x**3
r = endpoint_branch_reference(f, x, 0, sp.Rational(1, 2))
assert r.root == sp.Rational(1, 4)
print(r.to_dict())
```

The oracle's scope is deliberately narrow: QQ polynomials, a finite rational
endpoint and target, and a source side. It selects the open component ending at
the first critical point on that side. It does not continue through even a
nonturning critical point. It refuses floats, symbolic parameters and unsupported
inputs. Input degree/bit/operation limits are **not** a wall-clock or memory
sandbox, and expressions evaluated by the caller cannot be retroactively limited.
It is original reference code, not a port of the entire repository.

## Native reproduction — supplied but unrun

Use a fresh kernel, an independently selected checkout of the pinned revision,
and absolute local paths. Load the package *before* parsing the audit files:

```wolfram
Get["/absolute/path/to/Asymptotic/src/Kernel/AsymptoticAnalysis.wl"];
$AuditOutputFile = "/absolute/path/to/native-observations.json";
Get["/absolute/path/to/audit/code/native_characterization.wl"];

Get["/absolute/path/to/audit/code/ScopeGammaAdapterDerivativeBounds.wl"];
TestReport["/absolute/path/to/audit/code/native_regressions.wlt"]
```

The observation recorder writes actual values, not expected-contract pass claims.
It records the expected revision but does not verify what source was loaded.
The branch regressions allow a correct reference or an explicit refusal/unverified
status; separate constructor controls require the expected leading expression.
The N2 tests exercise the opt-in helper. These are **not** an upstream acceptance
suite. Existing Mathics precision refusals may precede a branch witness and do
not by themselves establish branch identification.

The helper returns a new object; it neither edits source files nor patches
package definitions. Its bounds are pointwise in the original source variable.
An interval lower bound requires a separately verified infimum on that interval.

## Article build

```sh
make pdf
```

The Makefile uses `latexmk` and ordinary LaTeX packages. `make clean` removes
intermediate article files without removing the final PDF. No fonts or complete
upstream checkout are bundled. No checksum files are included.

## Artifact inventory

- `article/`: article in TeX and PDF.
- `code/`: exact Python reference/tests/runner; unrun Wolfram helper and probes.
- `evidence/`: executed independent results, scope, novelty ledger and source map.
- `requirements.txt`, `Makefile`, `LICENSE`: reproduction and original-material terms.
