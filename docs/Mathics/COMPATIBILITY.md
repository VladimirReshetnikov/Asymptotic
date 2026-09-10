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

s = AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
Normal[s]
s["Remainder"]
```

Evaluate `Get` before parsing subsequent package calls. A command-line
`--code` string containing both the load and a first package call is parsed
as one expression; its previously unknown function names can bind to
`Global``. Separate input expressions or a `.wl` script preserve streaming
package context resolution.

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
* **Exact numbers:** unsupported algebraic-number normalization retains an
  exact symbolic expression and uses exact simplification. It never replaces
  an exact exponent or coefficient by a floating-point approximation.
* **Taylor series:** local package Taylor calls apply assumptions in a
  scope because Mathics `Series` does not accept the Wolfram assumptions
  option. Native backend requests retain their distinct native contract.
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

Initial live checks established ordinary quadratic inversion and the local
sine expansion. Broader feature acceptance is still in progress; no general
claim of parity with Wolfram is made. Symbolic branch proofs, sophisticated
native asymptotics, special-function evaluator coverage, numerical checks,
and notebook display require feature-specific testing.

The unmodified Wolfram baseline at `6687962` produced **1,452 passes and
12 failures across 79 suites** on Wolfram 15.0.1 for Windows. Preservation
checks compare against those original outcomes as well as the definitions
of existing package symbols. Passing newly selected examples alone does not
establish preservation of the original package.
