# Focused proposals (not executed in a Wolfram or Mathics kernel)

Pinned source: `7d1bc832895cc90a9b2a978b7b7684acab908bd2`.
Apply edits to modular sources, run focused tests, then regenerate the standalone
file using the repository's builder. No script in this bundle edits the repository.

## F02: protect the valid zero-dimensional multi-index

In the public `InverseExpansionCoefficient[model_Association, k_List, ...]`
definition in `src/Kernel/AsymptoticAnalysis.wl`, replace only the validation:

```wl
If[Length[k] =!= Length[model["Gaps"]] ||
   !(And @@ (IntegerQ[#] && # >= 0 & /@ k)), ...]
```

with:

```wl
If[Length[k] =!= Length[model["Gaps"]] ||
   !(k === {} || And @@ (IntegerQ[#] && # >= 0 & /@ k)), ...]
```

`Or` short-circuits. Empty input is valid precisely when the model has no
correction gaps. This avoids the missed native `Map` invocation without changing
System definitions or rewriting arbitrary stored/held user expressions. It is a
narrow fix: audit the separate compatibility-context lookup/key adapters too.

## F03: reject load failure before selecting any portable case

Immediately after the existing standalone top-level expression
`portableLoadResult = Check[Get[portableSource], $Failed];`, insert:

```wl
If[portableLoadResult === $Failed,
  Print["ASYMPTOTIC_PORTABLE_LOAD_ERROR"];
  Exit[2]];
```

Keep it a separate top-level expression because of the documented Mathics
Print/Check interaction. The runner already treats exit code 2 as a kernel error.
An explicit LoadError category would improve diagnostics, but is not needed to
prevent a false success. Also verify a small required-symbol set when accepting
an unusual successful Get result; do not require Get always to return Null.

## F05: stop first-level search immediately

Do NOT just add the fourth `1` argument to `Position`. In Mathics 10.0.1 the
retrieved `Position` implementation does not implement that maximum-count form.
The package's actual hot call uses a list, `{1}`, and `Heads -> False`. A candidate
specialization of the existing `firstPosition` helper is:

```wl
firstPosition[expr_List, pattern_, default_HoldComplete, {1}, False] :=
  System`Module[{index = 0, tag = Unique["firstPosition$"]},
    Catch[
      Scan[(index++;
        If[MatchQ[#, pattern], Throw[{index}, tag]]) &, expr];
      ReleaseHold[default], tag]];
```

Install the specialization together with the original generic rule from clean
DownValues during loading; Mathics can evaluate an existing definition while
installing a replacement left-hand side. Preserve the existing generic traversal
for other levels/heads. Validate predicate counts and lazy default evaluation.
This proposal has NOT been kernel-tested.

## F01: upstream bridge repair must be bidirectional

For Mathics `ProductLog`, swap `(branch, argument)` to `(argument, branch)` on
SymPy input and back on output. Preserve the one-argument form. Add arity 2 to the
numeric dispatcher and a callable that invokes `mpmath.lambertw(z, k)` for the
Wolfram order `(k, z)`. Check integer branch selection, exact/inexact values,
round-trips, and derivatives. A `prepare_sympy`-only patch is insufficient.

Until that upstream repair is integrated, use a package-owned inert nonprincipal
branch representation or reject unsupported evaluation explicitly. Do not pass
raw nonprincipal System`ProductLog through a backend known to misinterpret it.
The independent `lambert_minus_one.py` supplies an exact-rational reference oracle
for real rational arguments. It is NOT a drop-in Mathics adapter.
