# Running AsymptoticAnalysis in Mathics3

Mathics support is being developed and tested against **Mathics3 10.0.1**
with scanner 10.0.1, SymPy 1.14.0, and Python 3.11. The package's declared
Wolfram Language requirement and Wolfram functionality are unchanged.

The [background notes](README.md) describe the language and evaluator
differences. This page tracks the package's actual compatibility work;
background claims about an interpreter are not evidence that a package
feature has passed a regression test.

## Install and load

Use an isolated Python environment:

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
`Global``. Separate input expressions or a `.wl` script preserve streaming
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
`AsymptoticAnalysis`Mathics``. The adapter context is removed from the public
context path at the end of loading. No Mathics `System`` function is patched.
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
* **Simplification:** Mathics can raise a Python exception for atomic
  assumptions in two-argument simplification. The adapter passes an
  equivalent list of assumptions. Its algebraic and inequality reasoning
  remains more limited than Wolfram's.
  A conservative [exact assumption adapter](ASSUMPTIONS.md) proves finite
  realness and signs from explicit conjunctions, preserving unresolved
  branches. It does not implement quantifier elimination.
* **Held callables:** named `Function` parameters require the three-argument
  held `Extract` operation that Mathics lacks. The adapter preserves held
  parameters and lexical binding while traversing the requested parts.
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
* **Exact numbers:** unsupported algebraic-number normalization retains an
  exact symbolic expression and uses exact simplification. It never replaces
  an exact exponent or coefficient by a floating-point approximation.
* **Taylor series:** local package Taylor calls apply assumptions in a
  scope because Mathics `Series` does not accept the Wolfram assumptions
  option. Native backend requests retain their distinct native contract.
  The limit adapter maps Wolfram direction strings to Mathics' numeric
  direction convention; Mathics' native limit engine has limited assumption
  handling, so parameter-dependent limits still need individual validation.
* **Gamma asymptotics:** a finite large-positive-argument Stirling model
  supplies the missing native `LogGamma` series to the existing jet algebra.
  Its Bernoulli tail remains a Poincare remainder, with term limits enforced;
  it is never reported as an exact expansion. See
  [DLMF 5.11](https://dlmf.nist.gov/5.11).
* **Display:** Mathics and Wolfram front ends have different box support.
  Use `Normal[s]`, `s["Remainder"]`, and `InputForm[s]` when inspecting
  computation results independently of their display.

## Validation and remaining work

Run the portable exact regression suite with:

```text
python validation/run_mathics_tests.py --python .venv/mathics/Scripts/python.exe
python validation/run_mathics_tests.py --python .venv/mathics/Scripts/python.exe --source AsymptoticAnalysis.wl
python validation/run_mathics_tests.py --wolfram wolfram.exe
```

Use `--list` to list cases and `--case` or `--group` to select a focused run.
Each case has a fresh kernel and a process timeout. Reports retain exact
expected and actual values, interpreter diagnostics, and source hashes.
An interrupted run or one that overlaps source edits is not an acceptance
record. The portable suite supplements the existing Wolfram MUnit suite.

Live checks now cover ordinary and generalized inversion, elementary forward
expansions, symbolic positive coefficients, named and slot callables,
arithmetic and truncation, flat exponential sectors, perturbative formulas,
and an exact rational certificate. A direct Gamma check also recovers the
first three Stirling coefficients and cubic relative remainder. A frozen
34-case feature run passed 29 cases before subsequent targeted fixes; a
consolidated acceptance run is still pending. The numerical smoke check uses
an exact quadratic root and does not establish arbitrary-precision accuracy.

Symbolic branch proofs, sophisticated native asymptotics, remaining special
functions, refinement, nontrivial numerical certificates, and notebook
display require feature-specific testing. Mathics does not implement all
Wolfram builtins, and an explicit native backend request is limited to the
interpreter's actual implementation. Unsupported proofs must remain failures
or unresolved expressions; they are not replaced by guessed domains or
numerical evidence.

The unmodified Wolfram baseline at `6687962` produced **1,452 passes and
12 failures across 79 suites** on Wolfram 15.0.1 for Windows. Preservation
checks compare against those original outcomes as well as the definitions
of existing package symbols. Passing newly selected examples alone does not
establish preservation of the original package.
