# PowerLogInverse 1.0.0

Positive-real asymptotic inversion with logarithmic coefficient polynomials
and exact irrational powers. The accompanying article develops the theory,
explains the complex inverse germ in the archived question, proves the
coefficient formula and remainder estimates, and describes the implementation.

## Read the article

- `article/real_branch_reversion.pdf`
- `article/real_branch_reversion.tex` (self-contained source)

## Load the Wolfram Language package

```wl
Get["/your/path/PowerLogInverse/Kernel/PowerLogInverse.wl"];
```

The source targets the Wolfram Language features available in version 12 and
later. **Native-kernel execution was not available during this build.**
See `VALIDATION.md` for the distinction between executed independent checks
and the supplied, unexecuted native tests. No external Wolfram packages are
required by the implementation.

## The two original examples

```wl
PowerLogInverse[x + x^2 (1 + Log[x]), {x, y, 5}]

PowerLogInverse[x + x^Sqrt[2], {x, y, 4 Sqrt[2] - 3}]
```

The first call retains the inverse blocks of powers less than 5. The second
retains exactly the four blocks requested in the archived question:

```text
y - y^sqrt(2) + sqrt(2) y^(2 sqrt(2)-1)
  - (6-sqrt(2))/2 y^(3 sqrt(2)-2)
```

The latter has remainder `O(y^(4 sqrt(2)-3))`.
For the logarithmic example, the two-block remainder is
`O(y^3 Log[y]^2)`, not `O(y^3)`.

## Get the remainder, normalization, and residual check

```wl
d = PowerLogInverseData[x + x^2 (1 + Log[x]), {x, y, 5}];
d["Expression"]
d["Remainder"]
(* PowerLogOrder[y, 5, 4] *)

PowerLogResidual[d]["Certificate"]
(* Expected result in a native kernel: True *)

PowerLogResidual[d, 5]["Expression"]
(* Expand the normalized residual one power further. *)
```

`PowerLogOrder[u,c,k]` is an **inert descriptor** for
`O(u^c (1+Abs[Log[u]])^k)` as `u -> 0+`. It is not a `SeriesData` object,
not a numerical error bound, and not an arithmetic object. The finite
expression is returned separately from its remainder.

`PowerLogResidual` independently composes the stored finite approximation
using clipped binomial and logarithmic series. It checks the normalized
residual `f(A)/(a u^p)-1`. Its certificate concerns exact truncated algebra;
it is not a proof-kernel certificate or a floating-point interval certificate.
Requesting too short a residual range returns
`Missing["InsufficientCutoff"]`, not `True`.

## General input and cutoff convention

The core supports exact finite functions

```text
f(x) = a x^p (1 + sum_i x^delta_i P_i(Log[x]))
```

with `a > 0`, `p > 0`, `delta_i > 0`, and polynomial logarithmic blocks.
The selected branch is characterized by

```text
g(y) > 0, g(y) -> 0, g(y)/(y/a)^(1/p) -> 1.
```

**The cutoff is an exponent of `u=(y/a)^(1/p)`, not necessarily an exponent
of `y`.** An absolute uniformizer cutoff `c` corresponds to target powers
less than `c/p`. Both examples above have `p=a=1`, hence `u=y`.

```wl
d = PowerLogInverseData[
  4 x^2 (1 + x Log[x] + 3 x^Sqrt[2]), {x, y, 4}
];
d["UniformizerRule"]  (* u -> (y/4)^(1/2) *)
d["LogRule"]          (* ell -> Log[y/4]/2 *)
d["Expression"]
```

For already prepared input, use independent symbols `u,L`:

```wl
d = PowerLogReversion[
  4, 2, {{1, L}, {Sqrt[2], 3}}, {u, L}, 4
];
d["Terms"]
PowerLogResidual[d]["Certificate"]
```

In low-level data, `Expression` and `UniformizerExpression` use these
independent symbols. In high-level data, `Expression` is specialized to
the target variable, while `UniformizerExpression` retains the internal
symbols. `Terms` always stores the internal uniformizer/logarithm blocks.

## Exactness and input restrictions

Support exponents, the leading exponent, and cutoffs must be exact real
algebraic numbers. Polynomial coefficients must be exact and provably
real constants. The parser rejects machine exponents, unresolved symbolic
exponents, nonconstant leading log blocks, inverse log powers, and unprepared
functions such as `Sin[x]`. It does not silently apply `PowerExpand`, infer a
branch from floating-point samples, or rationalize irrational exponents.

A `ConditionalExpression` is accepted only when its condition is provably
implied by `x>0`. Other conditions require explicit preparation of the
intended germ. Source and target symbols must be distinct, and the target
must not occur in the input.

The finite input is treated as **exact**. When it is only a truncated
asymptotic jet of another function, its own uncertainty must be propagated
separately; the article proves the required transfer theorem.

## Additional helpers

```wl
(* Small positive inverse of x (-Log[x]): *)
LogPowerBaseInverse[y, 1, 1, 1]
(* Exp[ProductLog[-1,-y]] *)

(* Small positive inverse of x/(-Log[x]): *)
LogPowerBaseInverse[y, 1, 1, -1]
(* Exp[-ProductLog[0,1/y]] *)

(* Observable homotopy jet for s+h(s)=y, x=b(s): *)
InversePerturbationJet[Sqrt[z], z^(3/2), {z, y, 3}]
(* Inverse of x^2+x^3, through perturbation degree 3. *)
```

`InversePerturbationJet` accepts the perturbation in the **pivot coordinate**,
not the original x-coordinate. It supplies a formal finite derivative jet;
the caller establishes its branch, ordering, and analytic remainder.

## Resource controls

String-valued option names have these defaults:

```wl
"MaxMultiIndices" -> 100000
"MaxTerms"        -> 50000
"MaxTotalDegree"  -> 256
"MaxProducts"     -> 2000000
```

`MaxProducts` also bounds the enumeration frontier. Limit violations return
named `Failure` objects. These are structural budgets, not wall-clock bounds
on symbolic simplification. The implementation combines all contributions
at colliding exact exponents before removing zero blocks.

## Tests and examples

With a native Wolfram installation:

```sh
wolframscript -file Tests/run-tests.wls
wolframscript -file Examples/examples.wls
```

The archive contains 40 native regression definitions, including expected
failure cases, branch conditions, collisions, residual verification, and a
corrupted-coefficient test. They were **not executed in a native kernel**
during this build.

Independent validation, executed during this build:

```sh
python Validation/validate.py
python Validation/static_check.py
```

The first requires SymPy and mpmath and regenerates the recorded 46/46
mathematical checks and numerical results. The second checks lexical
balance of Wolfram files; it is not a parser or an evaluator.

## Rebuild the article

```sh
cd article
latexmk -pdf -interaction=nonstopmode -halt-on-error real_branch_reversion.tex
```

## License and source material

Newly prepared code, article, tests, and validation scripts are provided
under MIT No Attribution (`LICENSE`). The supplied question copy in
`Sources/question.md` retains its original authorship and applicable rights;
references to external publications do not relicense those publications.
