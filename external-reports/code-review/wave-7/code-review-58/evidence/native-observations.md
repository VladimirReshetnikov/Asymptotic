# Native observations (manual transcription)

These are transcriptions of successful Wolfram connector responses in this
review, not downloaded raw service logs or the repository's acceptance receipts.
The public package was fetched from the commit-pinned raw URL below, not `main`.

Commit: efa1aeec4845a9c35e140963a0333d0c9ec33b05
Raw input: https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/efa1aeec4845a9c35e140963a0333d0c9ec33b05/AsymptoticAnalysis.wl
Runtime: 15.0.0 for Linux x86 (64-bit) (May 6, 2026)

## Environment and load control

`{$Version, 1+1}` returned the version above and `2`.
Importing the pinned standalone as text gave `StringLength` 692380, and the
loaded package returned `y-y^2+2*y^3` for
`Normal[AsymptoticInverse[x+x^2,{x,0},{y,4}]]`.
The string length is an observation, not an integrity certificate.

## F01: original package

Input after loading:

```wolfram
With[{s=AsymptoticAnalysis`AsymptoticSpecialInverse[
  "Erfc",{x,-Infinity},{y,1}]},
 {Normal[s],s["FrontierTerm"],s["RemainderPower"]}]
```

Let `v=-Log[Sqrt[Pi]*(2-y)]`. The exact returned expressions were:

```wolfram
{-Sqrt[v]+Log[v]/(4*Sqrt[v]),
 (-1/4+Log[v]/8-Log[v]^2/32)/v^(3/2),
 3/2}
```

Only `v` is an editorial abbreviation; no numerical rounding was introduced.

## F01: in-memory candidate patch

The fetched standalone text contained the exact Erfc object-assembly anchor
once. That occurrence was followed by:

```wolfram
"FrontierTerm" -> If[MissingQ[innerData["FrontierTerm"]],
  innerData["FrontierTerm"], sign innerData["FrontierTerm"]],
```

The modified text was loaded in the native service and the same one-object
probe returned:

```wolfram
{-Sqrt[v]+Log[v]/(4*Sqrt[v]),
 -((-1/4+Log[v]/8-Log[v]^2/32)/v^(3/2)),
 3/2}
```

This validates the targeted in-memory mechanism. It is NOT a local regenerated
standalone build, a modular-layout run, or execution of the full proposed WLT.

## G01: unsupported transition regime

Input:

```wolfram
AsymptoticAnalysis`AsymptoticExpansion[
 LerchPhi[Exp[-1/x],2,x],{x,Infinity,4},"Backend"->"Package"]
```

Output:

```wolfram
Failure["UnsupportedNativeCoefficient", <|
 "MessageTemplate" -> "A native amplitude must have polynomial logarithmic coefficients and bounded real sine/cosine modes.",
 "Coefficient" -> LerchPhi[E^(-u$10),2,u$10^(-1)]|>]
```

`u$10` is the service's fresh internal symbol; its name is not a test invariant.
This is a conservative unsupported result, not a wrong asymptotic expansion.

## E01: equivalent fully qualified coefficient routine

A fully qualified Wolfram implementation of the prototype's moment sum and
model assembly, without loading AsymptoticAnalysis, returned for lambda=1,
s=2, K=2:

```wolfram
{{1,E*Gamma[-1,1]},{2,1/2},{3,1/4},{5,-49/720}}
233/(4320*a^7)
```

At a=10, `N[(LerchPhi[Exp[-1/10],2,10]-model)/bound,30]` returned
`0.985632727002140196667077137474...`.
The complete distributed `UniformLerch.wl` file and `ReviewProbes.wlt` were not
executed as files in the native service.

## Exploratory forward screen (not acceptance)

For n=2,3,4, the expressions were Sin[x+x^n], Cos[x+x^n],
Log[1+x+x^n], Sqrt[x+x^n], (1+x+x^n)^(-3/2),
(x+x^n)^(-3/2), Exp[x+x^n], ArcSin[x+x^n], with cutoff 4.
A native Taylor comparison returned no low-order discrepancy for the 18
integral-power cases. The six fractional-power cases produced invalid oracle
flags: the comparison substituted x=t^2 without establishing t>0 and then
misused polynomial coefficient extraction on the resulting expressions.
Those six observations were discarded; they are not package failures.
MinValue/MaxValue diagnostic messages were emitted during this exploratory call.
No additional UX finding is inferred from them without isolation.

## Rejected / incomplete executions

Several further service calls failed at the network/upstream-service layer;
no mathematical conclusion is drawn from them. An initial prototype declaration
was parsed in the wrong context and returned undefined-symbol expressions; it
was discarded as a harness error. The subsequent fully qualified routine is
recorded above. Mathics was unavailable locally and was not executed. No full
upstream suite, portable acceptance run, or benchmark of upstream performance
was performed.
