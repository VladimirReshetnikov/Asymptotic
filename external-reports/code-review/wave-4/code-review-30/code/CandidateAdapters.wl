(* Review prototypes, not installed into AsymptoticAnalysis or System`.
   This file was NOT executed on a Wolfram or Mathics kernel in this review.
   Sparse conversion is for an already admissible univariate polynomial.
   Expand itself is not resource bounded; callers must budget expansion.
*)
BeginPackage["AsymptoticAuditCandidates`"];
SparseCoefficientRules1::usage = "SparseCoefficientRules1[p,z] returns descending nonzero coefficient rules without CoefficientList.";
EvaluateWithoutTwoArgumentProductLog::usage = "EvaluateWithoutTwoArgumentProductLog[s,v,p] refuses an exposed two-argument ProductLog before substitution on Mathics. It is not a domain or accuracy certificate.";
Begin["`Private`"];
SparseCoefficientRules1[p_, z_Symbol] := Module[{expanded, terms, rows, groups},
  If[! PolynomialQ[p,z], Return[Failure["NotPolynomial",<|"Variable"->z|>]]];
  expanded = Expand[p];
  If[expanded === 0, Return[{}]];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  rows = ({Exponent[#,z], Coefficient[#,z,Exponent[#,z]]}&) /@ terms;
  If[! And @@ (IntegerQ[First[#]] && First[#] >= 0 & /@ rows),
    Return[Failure["InvalidPolynomialExponent",<||>]]];
  groups = GatherBy[rows,First];
  rows = ({#[[1,1]], Total[#[[All,2]]]}&) /@ groups;
  rows = Select[rows, Last[#] =!= 0 &];
  rows = SortBy[rows,-First[#]&];
  ({First[#]} -> Last[#] &) /@ rows
];
EvaluateWithoutTwoArgumentProductLog[s_, v_?NumericQ, precision_:50] := Module[
  {expression, variable},
  expression = Normal[s]; variable = s["Variable"];
  If[! MatchQ[variable,_Symbol], Return[Failure["UnsupportedVariable",<||>]]];
  If[StringContainsQ[$Version,"Mathics"] &&
     ! FreeQ[expression,HoldPattern[System`ProductLog[_,_]]],
    Return[Failure["UnavailableMathicsLambertBranch",<|
      "MessageTemplate"->"The retained exact expression uses a two-argument ProductLog; do not pass it to this Mathics evaluator.",
      "Scope"->"A numeric capability guard, not a domain or error certificate."|>]]];
  N[expression /. variable -> v, precision]
];
End[];
EndPackage[];
