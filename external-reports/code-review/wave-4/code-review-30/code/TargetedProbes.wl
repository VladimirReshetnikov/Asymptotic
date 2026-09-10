(* UNEXECUTED ON WOLFRAM/MATHICS IN THIS REVIEW.
   Stream this file, do not parse Get and later package names in one --code.
   Set ASYMPTOTIC_AUDIT_SOURCE to the pinned modular or standalone entry file.
   These are characterization probes, not an automatic pass/fail acceptance suite.
*)
auditSource = Environment["ASYMPTOTIC_AUDIT_SOURCE"];
If[! StringQ[auditSource] || ! FileExistsQ[auditSource],
  Print["Set ASYMPTOTIC_AUDIT_SOURCE to an existing package entry file."]; Exit[2]];
Get[auditSource];
If[StringContainsQ[$Version,"Mathics"],$IterationLimit=1000000];
Print["KERNEL: ",$Version];
Print["No result below is a numerical certificate merely because it is high precision."];

Clear[x,y,z,a,b];
s = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x]/x,0,{x,Infinity},{y,0}];
Print["LOWER-LAMBERT-CORE: ",InputForm[s]];
If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
  Print["LOWER-LAMBERT-EXPRESSION: ",InputForm[Normal[s]]];
  Print["LOWER-LAMBERT-NUMERIC: ",InputForm[N[s[10],30]]];
  Print["Expected real value near 3.577152063957297218409391963512, or an explicit unsupported-evaluator refusal."]];
Print["PRINCIPAL-CONTROL: ",InputForm[N[ProductLog[E],30]]];
Print["TWO-ARGUMENT-PRINCIPAL: ",InputForm[N[ProductLog[0,E],30]]];
Print["TWO-ARGUMENT-LOWER: ",InputForm[N[ProductLog[-1,-1/10],30]]];

If[StringContainsQ[$Version,"Mathics"],
  Print["LOCAL-LIMIT-OMITTED: ",InputForm[AsymptoticAnalysis`Mathics`Limit[Abs[x]/x,x->0]]];
  Print["LOCAL-LIMIT-ABOVE: ",InputForm[AsymptoticAnalysis`Mathics`Limit[Abs[x]/x,x->0,Direction->"FromAbove"]]];
  Print["LOCAL-LIMIT-BELOW: ",InputForm[AsymptoticAnalysis`Mathics`Limit[Abs[x]/x,x->0,Direction->"FromBelow"]]];
  Print["SPARSE-COEFFICIENT-RULES: ",InputForm[AsymptoticAnalysis`Mathics`CoefficientRules[a+b z^1000,z]]];
  auditCount=0;
  auditPosition=AsymptoticAnalysis`Mathics`FirstPosition[Range[1000],
    _Integer?(Function[q,auditCount++;True]),Missing["NoMatch"],{1},Heads->False];
  Print["FIRST-POSITION-AND-PREDICATE-COUNT: ",InputForm[{auditPosition,auditCount}]];
  Print["DEFAULT LIMIT SHOULD NOT BE ADVERTISED AS WOLFRAM TWO-SIDED SEMANTICS IF IT RETURNS -1."]];

Print["TAYLOR-NEGATIVE-NONINTEGER-DENOMINATOR: ",InputForm[
  AsymptoticAnalysis`AsymptoticExpansion[Hypergeometric0F1[-1/2,x],{x,0,5},"Backend"->"Package"]]];
Print["TAYLOR-TERMINATING-EXCESS-UPPER-RANK: ",InputForm[
  AsymptoticAnalysis`AsymptoticExpansion[HypergeometricPFQ[{-2,1,1},{},x],{x,0,3},"Backend"->"Package"]]];
Print["Expected coefficient oracles: 1-2x-2x^2-4x^3/9-2x^4/45; and exact 1-2x+4x^2."];
