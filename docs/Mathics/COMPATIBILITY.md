# Running AsymptoticAnalysis in Mathics3

Mathics support is being developed and tested against **Mathics3 10.0.1**
with scanner 10.0.1, SymPy 1.14.0, and Python 3.11. The package's declared
Wolfram Language requirement and Wolfram functionality are unchanged.

The [background notes](README.md) describe the language and evaluator
differences. This page tracks the package's actual compatibility work;
background claims about an interpreter are not evidence that a package
feature has passed a regression test.
The maintained [Mathics implementation notes](../MATHICS-NOTES.md) collect
reproducible evaluator gotchas in the same form as the Wolfram notes.

## Install and load

Use an isolated **Python 3.11** environment:

```text
python -m venv .venv/mathics
.venv/mathics/Scripts/python -m pip install -r validation/requirements-mathics.txt
.venv/mathics/Scripts/python -X utf8 -m mathics --no-readline
```

On Linux or macOS, replace `.venv/mathics/Scripts/python` with
`.venv/mathics/bin/python`. The `--no-readline` option avoids a Mathics 10.0.1
Windows command-line startup error. UTF-8 mode allows the command-line
printer to emit Wolfram syntax characters on Windows. `packaging` is included
in the requirements because the Mathics number-theory module imports it even
though Mathics 10.0.1 does not declare it as an installation dependency.

Load either entry point from the repository root:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
(* Or use the generated, self-contained AsymptoticAnalysis.wl. *)
If[StringContainsQ[$Version, "Mathics"], $IterationLimit = 1000000];

s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
Normal[s]
s["Remainder"]
```

Evaluate `Get` before parsing subsequent package calls. A command-line
`--code` string containing both the load and a first package call is parsed
as one expression; its previously unknown function names can bind to
the `Global` context. Separate input expressions or a `.wl` script preserve streaming
package context resolution.

The larger iteration budget is an explicit Mathics session setting. Mathics
counts nonliteral ownvalue substitutions throughout an input evaluation;
its default of 4096 can stop valid package calculations, including a modest
Gamma expansion. The package does not change this global setting itself.
Package term limits and the regression runner's process timeout remain in
force independently of the evaluator budget.

## Isolation from the Wolfram kernel

Only Mathics loads the compatibility modules. Package implementation symbols
then resolve selected missing or incompatible operations through
the ``AsymptoticAnalysis`Mathics`` context. The adapter context is removed from
the public context path at the end of loading. No Mathics `System` function is patched.
Missing inert system names used in public input, such as `SeriesTermGoal`,
are established so caller input and package patterns use the same symbols.
An inert name does not imply an implemented backend or special function.

The standalone builder preserves this isolation by storing Mathics bootstrap
statements as strings and parsing them one at a time only on Mathics. Thus
an official Wolfram kernel does not even create the adapter symbols. The
original arithmetic and formatting declarations still execute on Wolfram;
Mathics uses equivalent package-owned declarations where its tag assignment
checks reject the original forms.

## Compatibility subtleties

* **Early returns:** Mathics 10.0.1 does not implement
  `Return[value, Module]`. Its ordinary returns can be intercepted by loops.
  The package adapter uses a distinct `Catch`/`Throw` tag for each module,
  including nested calls and module initializers.
* **Associations:** the package supplies bounded adapters for lookup,
  membership, updates, and key selection. A missing-key lookup evaluates its
  default only when needed; list-valued lookups preserve key order.
* **Empty lists:** native Mathics mapping can invalidate the cache of a
  reused empty list and crash later metadata construction. Private package
  maps return an empty list directly in the exact two-argument empty case;
  other forms retain native behavior. This enables flat-sector operations
  and empty Fourier residuals. See [list semantics](LISTS.md).
* **Simplification:** Mathics can raise a Python exception for atomic
  assumptions in two-argument simplification. The adapter passes an
  equivalent list of assumptions. Its algebraic and inequality reasoning
  remains more limited than Wolfram's.
  A conservative [exact assumption adapter](ASSUMPTIONS.md) proves finite
  realness and signs from explicit conjunctions, preserving unresolved
  branches. It does not implement quantifier elimination.
  Unresolved ordered predicates are kept out of native simplification until
  their operands are proved real. This prevents cancellation of a common
  complex offset from manufacturing a real inequality.
* **Held callables:** named `Function` parameters require the three-argument
  held `Extract` operation that Mathics lacks. The adapter preserves held
  parameters and lexical binding while traversing the requested parts.
  See [callable and inverse-branch contracts](CALLABLES.md) for the bounded
  polynomial and affine-domain proofs. Wolfram can evaluate `InverseFunction`
  before package dispatch; two regression cases explicitly record the
  resulting runtime difference instead of requiring a false parity claim.
* **Messages and `Check`:** Mathics 10's two-argument `Check` can treat an
  earlier `Print` in the same input evaluation as an error from its checked
  expression. Evaluate progress output in a separate input. Regression
  diagnostics are emitted after the tested calculation for this reason.
* **Finite derivative sums:** Mathics can evaluate a symbolic derivative
  index before binding a finite `Sum`. The perturbative inverse and
  logarithmic Euler adapters use equivalent finite tables.
* **Certificates:** the Mathics adapter updates the final history entry
  using its positive list index. Mathics 10 can otherwise raise a Python
  `IndexError` for the equivalent negative-index assignment.
* **Retained refinement:** computed association rule lists are evaluated
  before constructing refinement frontiers and depth regions. Successive
  refinements preserve the original source object and transport its remainder.
* **Exact numbers:** unsupported algebraic-number normalization retains an
  exact symbolic expression and uses exact simplification. It never replaces
  an exact exponent or coefficient by a floating-point approximation.
* **Taylor series:** local package Taylor calls apply assumptions in a
  scope because Mathics `Series` does not accept the Wolfram assumptions
  option. Native backend requests retain their distinct native contract.
  The limit adapter maps Wolfram direction strings to Mathics' numeric
  direction convention; Mathics' native limit engine has limited assumption
  handling, so parameter-dependent limits still need individual validation.
  Bounded defining-series adapters additionally support `Hypergeometric0F1`,
  `Hypergeometric1F1`, `Hypergeometric2F1`, convergent `HypergeometricPFQ`, and
  `PolyLog` at a vanishing monomial argument. Positive denominator parameters,
  exact function arity, a constant outer multiplier, and an explicit order
  term prevent unsupported continuation or lost tails. This also supplies the
  ordinary Bessel J origin expansion through the existing Frobenius identity.
* **Gamma asymptotics:** a finite large-positive-argument Stirling model
  supplies the missing native `LogGamma` series to the existing jet algebra.
  Its Bernoulli tail remains a Poincare remainder, with term limits enforced;
  it is never reported as an exact expansion. See
  [DLMF 5.11](https://dlmf.nist.gov/5.11).
* **Fourier and exact cores:** bounded coefficient rules and trigonometric
  identities preserve inverse coefficients and sector metadata. Principal
  Lambert expressions are normalized to one-argument `ProductLog` before
  numerical specialization, avoiding Mathics' incorrect argument order in
  the two-argument evaluator. Numerical nonprincipal Lambert evaluation
  remains unsupported; see [algebra and core-function details](ALGEBRA.md).
* **Time budgets:** internal symbolic proof attempts receive four times their
  Wolfram wall-clock allowance because Mathics interpretation is slower.
  Proof criteria and fallbacks are unchanged. Explicit `CoreCheckTimeConstraint`
  values and the documented five-second callable-application guard keep their
  original deadlines. User calls to ``System`TimeConstrained`` are unaffected.
* **Display:** Mathics and Wolfram front ends have different box support.
  Use `Normal[s]`, `s["Remainder"]`, and `InputForm[s]` when inspecting
  computation results independently of their display.

## Validation and remaining work

Run the portable exact regression suite with:

```text
python validation/run_mathics_tests.py --python .venv/mathics/Scripts/python.exe --timeout 300
python validation/run_mathics_tests.py --python .venv/mathics/Scripts/python.exe --source AsymptoticAnalysis.wl --timeout 300
python validation/run_mathics_tests.py --wolfram wolfram.exe
```

Use `--list` to list cases and `--case` or `--group` to select a focused run.
Each case has a fresh kernel and a process timeout. Reports retain exact
expected and actual values, interpreter diagnostics, and source hashes.
An interrupted run or one that overlaps source edits is not an acceptance
record. The portable suite supplements the existing Wolfram MUnit suite.

Focused live checks establish the following examples. A consolidated run of
the final source snapshot is pending; individual examples do not establish
every parameter range of a family.

| Area | Checked behavior |
| --- | --- |
| Loading and evaluator primitives | Clean load, reload, public contexts, held returns, association operations, pattern positions. |
| Ordinary inverse calculus | Finite and infinite source points, ramification, irrational powers, logarithmic coefficients, exact termination, residuals, perturbative formulas. |
| Forward calculus | Exact polynomial, exponential, logarithmic and irrational-power terms, finite approach from below, decaying exponential. |
| Algebra and state | Addition, multiplication, cancellation with retained error, truncation, two-stage refinement, depth enumeration. |
| Function input | Named and slot callables, binding and capture avoidance, conditional polynomial inverse branches, explicit conservative domain failures. |
| Special forward examples | Gamma and Barnes G Stirling corrections, Bessel J and Erf at zero, PolyLog at zero, Zeta Dirichlet terms. |
| Other inverse scales | Reciprocal-logarithmic, Lambert, Fourier, Gamma, Barnes G, exponential-core, first flat exponential sector. |
| Exact error checks | Rational quadratic root certificate and inaccurate fixed-center `AccuracyFloor` with retained history. |
| Numerical smoke checks | Exact quadratic root and principal Lambert specialization at `E`. These do not establish general numerical accuracy. |

Unrestricted symbolic branch proofs, sophisticated native asymptotics,
remaining special-function parameter ranges, nontrivial numerical
certificates, and notebook display require further feature-specific testing.
Mathics does not implement all
Wolfram builtins, and an explicit native backend request is limited to the
interpreter's actual implementation. Unsupported proofs must remain failures
or unresolved expressions; they are not replaced by guessed domains or
numerical evidence.

The [Wolfram preservation receipt](../../validation/mathics-wolfram-preservation.json)
records **1,452 passes and the same 12 existing failures across 79 suites**
on Wolfram 15.0.1 for Windows. All 1,464 per-test records match the untouched
`6687962` baseline. The receipt retains an earlier run with one extra failure
and the subsequent matching full rerun instead of discarding that evidence.

Independent review fixes were subsequently merged from `origin/main`.
Native definition comparisons separately record the `021c584` review merge
and the later `350c70f` control. The latest comparison uses `a55df16`, including
its independent native rule-goal changes, as the control for the 54-module
Mathics candidate. All 2,051 modular and 2,050 standalone package symbols
match across attributes, options, own/down/up/sub/numeric/default/format
values, messages, and contexts. Six System builtins, including `Map`, retain
their definitions before loading, after loading, and after reloading; eight
behavior probes also pass in every phase. The earlier full-suite result is
not relabeled as a full run of these later upstream changes. Each receipt
identifies its exact source hashes; absolute source-directory strings are
the only normalized definition content.

To reproduce a native definition comparison, provide a baseline checkout or
extracted Git archive and run:

```text
python validation/check_mathics_definitions.py --baseline BASELINE_REPOSITORY --candidate . --wolfram wolfram.exe --output native-definitions.json --captures .venv/native-captures
```

Both entry points are checked by default. The tool copies package inputs and
the exact hashed Wolfram capture script into temporary snapshots, runs fresh
kernels serially, and verifies load/reload and selected builtin state. It
checks the frozen capture script before each launch and at completion, and
rejects changes to original package or tool files. Focused regressions confirm
that editing either the original or frozen capture script invalidates the
run; a changed frozen script also blocks the next kernel launch. Its deliberate
changed-value fixture was rejected as well. Definition comparisons and finite
regressions are scoped evidence; neither proves every possible surrounding
program or every Wolfram version behaves identically.
