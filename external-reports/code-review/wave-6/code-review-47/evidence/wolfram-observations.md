# Native Wolfram observations

Date: 2026-09-10. Pinned source: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`.
Kernel: `15.0.0 for Linux x86 (64-bit) (May 6, 2026)`.

These records are manual transcriptions of returned connector text, not
kernel-written acceptance receipts. The complete MUnit suite and Mathics itself
were not run. Initially failed service/package-loading attempts supplied no
results. Loading the downloaded file's **path** subsequently succeeded; those
earlier failed attempts are not attributed to a repository defect.

## A. Seven actual pinned-package controls

Executed input:

```wl
Module[{p,cases,rows,r,expected,inv},
 p=URLDownload["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/8cee870994f506b501bae3ea6bd4a3a7edb895c1/AsymptoticAnalysis.wl"];
 Get[p[[1]]];
 cases={Exp[x],Sin[x],Log[1+x],Sqrt[1+x],1/(1-x),Exp[x+x^2]};
 rows=Table[
  r=AsymptoticAnalysis`AsymptoticExpansion[f,{x,0,4},"Backend"->"Package"];
  expected=Normal[Series[f,{x,0,3}]];
  {ToString[f,InputForm],Head[r]===AsymptoticAnalysis`GeneralizedSeries,
   TrueQ[Simplify[Normal[r]-expected]==0],r["Remainder"]},{f,cases}];
 inv=AsymptoticAnalysis`AsymptoticInverse[x+x^2,{x,0},{y,4}];
 {$Version,rows,{Head[inv]===AsymptoticAnalysis`GeneralizedSeries,
 Normal[inv],TrueQ[Simplify[Normal[inv]-Normal[
 Series[(Sqrt[1+4y]-1)/2,{y,0,3}]]]==0]}}]
```

Returned text:

```text
{"15.0.0 for Linux x86 (64-bit) (May 6, 2026)",
 {{"E^x", True, True, PowerLogRemainder[x, 4, 0]},
  {"Sin[x]", True, True, PowerLogRemainder[x, 5, 0]},
  {"Log[1 + x]", True, True, PowerLogRemainder[x, 4, 0]},
  {"Sqrt[1 + x]", True, True, PowerLogRemainder[x, 4, 0]},
  {"(1 - x)^(-1)", True, True, PowerLogRemainder[x, 4, 0]},
  {"E^(x + x^2)", True, True, PowerLogRemainder[x, 4, 0]}},
 {True, y - y^2 + 2*y^3, True}}
```

All seven finite expressions match their independent/native control. This is
not proof of every advertised class, of all remainders, or of Mathics parity.

## B. Actual source-helper entry counts, native host

Executed input:

```wl
Module[{p,calls=0,out,
 r=AsymptoticAnalysis`Mathics`mathicsRealProof,
 s=AsymptoticAnalysis`Mathics`mathicsSignProof},
 p=URLDownload["https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/8cee870994f506b501bae3ea6bd4a3a7edb895c1/src/Kernel/MathicsAssumptions.wl"];
 Block[{$ContextPath=Prepend[$ContextPath,"AsymptoticAnalysis`Mathics`"]},
  Get[p[[1]]]];
 Scan[(DownValues[#]=DownValues[#]/.
  HoldPattern[RuleDelayed[lhs_,rhs_]]:>RuleDelayed[lhs,(calls++;rhs)])&,{r,s}];
 out=Table[calls=0;With[{answer=r[Nest[Cosh[#]^2&,a,n],{{},{}},24]},
  {n,answer,calls}],{n,0,6}];
 {$Version,out}]
```

Returned values:

```text
{"15.0.0 for Linux x86 (64-bit) (May 6, 2026)",
 {{0,None,1},{1,None,8},{2,None,29},{3,None,92},
  {4,None,281},{5,None,848},{6,None,2549}}}
```

The deliberately injected compatibility context emitted `Element::shdw`:
`Element` appeared in both `AsymptoticAnalysis`Mathics`` and `System``.
The connector also emitted its generic messages notice. This experiment must
not be called message-free native compatibility or a Mathics runtime test.
Only two helper bodies were instrumented; their branch predicates were retained.
The larger 335,521/200 comparison is independently modeled, not measured here.

## C. Restricted native mirror

A separately hand-transcribed restricted `Cosh[e]^2` real/sign mirror returned
`{None, 2549, 19, <version above>}` for n=6: answer, helper calls, native LeafCount,
version. This redundant control is not included as an additional package test.
