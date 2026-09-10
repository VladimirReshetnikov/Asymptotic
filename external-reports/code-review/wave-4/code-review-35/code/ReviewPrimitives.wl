(* Independent candidate primitives. NOT installed into AsymptoticAnalysis.
   WL/Mathics execution is pending. Python reference laws were checked.
   The deliberately narrow domains are part of these APIs. *)
BeginPackage["AsymptoticReview`"];
SparseMonomialRules::usage = "SparseMonomialRules[p,x,n] reads an already expanded sum of at most n polynomial monomials without constructing a dense coefficient list. It refuses unexpanded variable-dependent factors.";
AffineRadius::usage = "AffineRadius[{{a,b,relation},...}] returns a positive rational r proving the conjunction a+b u relation 0 throughout 0<u<r. Coefficients must be rational; relations are strings <, <=, >, >=, ==, !=.";
ConservativeRealLimit::usage = "ConservativeRealLimit[e,x->a] checks both real sides at a finite point. It accepts structurally identical resolved one-sided values, otherwise returns Failure. Explicit supported one-sided directions are passed through. This is not a general Limit replacement.";
Begin["`Private`"];

SparseMonomialRules[expression_, variable_Symbol, maxTerms_Integer : 100000] :=
 System`Module[{tag = Unique["sparseRules$"], terms, factors, power, coefficient, rows = {}, groups},
  Catch[
   If[maxTerms < 1, Throw[Failure["InvalidBudget", <||>], tag]];
   terms = If[Head[expression] === Plus, List @@ expression, {expression}];
   If[Length[terms] > maxTerms,
    Throw[Failure["SupportBudget", <|"Monomials" -> Length[terms], "Limit" -> maxTerms|>], tag]];
   Do[
    power = 0; coefficient = 1;
    factors = If[Head[term] === Times, List @@ term, {term}];
    Do[Which[
      FreeQ[factor, variable], coefficient = coefficient factor,
      factor === variable, power++,
      Head[factor] === Power && factor[[1]] === variable &&
        IntegerQ[factor[[2]]] && factor[[2]] >= 0, power += factor[[2]],
      True, Throw[Failure["UnexpandedOrNonPolynomial", <|"Factor" -> factor|>], tag]
     ], {factor, factors}];
    AppendTo[rows, {power, coefficient}], {term, terms}];
   groups = GatherBy[rows, First];
   rows = ({#[[1, 1]], Total[#[[All, 2]]]} &) /@ groups;
   rows = Reverse[SortBy[Select[rows, Last[#] =!= 0 &], First]];
   ({First[#]} -> Last[#]) & /@ rows,
   tag]];
SparseMonomialRules[___] := Failure["InvalidArguments", <||>];

rationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
allowedSigns[relation_] := Switch[relation,
  ">", {1}, ">=", {0, 1}, "<", {-1}, "<=", {-1, 0},
  "==", {0}, "!=", {-1, 1}, _, {}];
AffineRadius[clauses_List] := System`Module[
 {tag = Unique["affineRadius$"], radius = 1, a, b, relation, sign},
 Catch[
  Do[
   If[! MatchQ[clause, {_, _, _String}],
     Throw[Failure["InvalidClause", <|"Clause" -> clause|>], tag]];
   {a, b, relation} = clause;
   If[! (rationalQ[a] && rationalQ[b]) || allowedSigns[relation] === {},
     Throw[Failure["UnsupportedClause", <|"Clause" -> clause|>], tag]];
   sign = If[a === 0, Sign[b], Sign[a]];
   If[! MemberQ[allowedSigns[relation], sign],
     Throw[Failure["NotEventuallyTrue", <|"Clause" -> clause|>], tag]];
   If[a =!= 0 && b =!= 0, radius = Min[radius, Abs[a/(2 b)]]],
   {clause, clauses}];
  radius, tag]];
AffineRadius[___] := Failure["InvalidArguments", <||>];

Options[ConservativeRealLimit] = {Direction -> Reals, Assumptions :> $Assumptions};
ConservativeRealLimit[expression_, specification_Rule, opts : OptionsPattern[]] :=
 System`Module[{tag = Unique["realLimit$"], direction = OptionValue[Direction],
   assumptions = OptionValue[Assumptions], point = Last[specification],
   left, right, oneSide, resolved},
  Catch[
   oneSide[d_] := Block[{$Assumptions = assumptions},
     Quiet[Check[System`Limit[expression, specification, Direction -> d], $Failed]]];
   direction = direction /. {"FromAbove" -> -1, "FromBelow" -> 1, "TwoSided" -> Reals};
   If[MemberQ[{-1, 1}, direction], Throw[oneSide[direction], tag]];
   If[direction =!= Reals,
     Throw[Failure["UnsupportedLimitDirection", <|"Direction" -> direction|>], tag]];
   If[point === Infinity, Throw[oneSide[1], tag]];
   If[point === -Infinity, Throw[oneSide[-1], tag]];
   left = oneSide[1]; right = oneSide[-1];
   resolved[value_] := FreeQ[value,
     $Failed | $Aborted | Indeterminate | _System`Limit | _System`Failure |
       _System`Missing | _ConditionalExpression];
   If[SameQ[left, right] && resolved[left],
     left,
     Failure["TwoSidedLimitNotEstablished", <|"FromBelow" -> left, "FromAbove" -> right|>]],
   tag]];
ConservativeRealLimit[___] := Failure["InvalidArguments", <||>];
End[];
EndPackage[];
