# AsymptoticInverse

Real asymptotic expansions of functions and their inverses in Wolfram Language.

- **[User guide](Documentation/UserGuide.html)** — syntax, options, worked
  examples, result properties, supported scales, and possible issues.
  [Read the Markdown version](Documentation/UserGuide.md).
- **[Mathematical article](../article/asymptotic-inverse.pdf)** — definitions,
  theorems, proofs, branch selection, and error estimates.
  [Read the LaTeX source](../article/asymptotic-inverse.tex).

## Loading

From the repository root:

```wolfram
Get["AsymptoticInverse/Kernel/AsymptoticInverse.wl"];
```

Or register the local paclet directory and load its context:

```wolfram
PacletDirectoryLoad["/absolute/path/to/AsymptoticInverse"];
Needs["AsymptoticInverse`"];
```

Version 1.7.0 requires Wolfram Language 15.0 or later. The recorded native
checks used version 15.0.1 for Windows.

## First expansion

```wolfram
s = AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}];
Normal[s]
(* y - y^2 (1 + Log[y]) + y^3 (3 + 5 Log[y] + 2 Log[y]^2) *)
s["Remainder"]
(* PowerLogRemainder[y, 4, 3] *)
```

Ordinary arithmetic preserves the series remainder:

```wolfram
s + y^2
s/(1 + y)
s^2
SeriesNormalize[(s + y^2)/(1 + y), "Cutoff" -> 3]
```

See [Series Arithmetic and Normalization](Documentation/UserGuide.md#series-operations)
for regular function operands, available precision, and composite error bounds.

## Special-function expansions

The same forward interface handles admitted finite-point and large-argument
expansions of Bessel, Airy, error-integral, incomplete Gamma, zeta/polylogarithm,
hypergeometric, and elliptic functions:

```wolfram
s = AsymptoticExpansion[BesselK[0, x], x -> Infinity,
  SeriesTermGoal -> 3];
Normal[s]
s["Remainder"]
```

`Normal[s]` returns an ordinary finite expression. The series object retains
its error, including separate error scales when oscillations or distinct
exponential factors occur. See [Other Special Functions](Documentation/UserGuide.md#special-function-expansions)
for supported endpoint examples, real-branch and fixed-parameter conditions,
carrier-specific cutoffs, and exact versus exponentially small contributions.

Use the guide's [function overview](Documentation/UserGuide.md#function-overview)
for the public API and its [possible issues](Documentation/UserGuide.md#possible-issues)
for domain and precision restrictions. Native examples are in [Examples/](Examples/);
test and artifact evidence is described in the
[validation record](../validation/README.md).
