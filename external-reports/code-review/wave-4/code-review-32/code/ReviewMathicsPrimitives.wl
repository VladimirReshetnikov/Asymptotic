(* Companion prototypes, not an installed patch. These definitions do not
   alter AsymptoticAnalysis or any System symbol. Native/Mathics execution of
   this file has NOT been performed in the review environment. *)
BeginPackage["ReviewMathicsPrimitives`"];
SparseCoefficientRules::usage = "SparseCoefficientRules[p,x,ass] extracts univariate polynomial rules without a degree-indexed coefficient array. Expansion cost is not bounded by this prototype.";
PolynomialRealDomain::usage = "PolynomialRealDomain[p,x,ass] returns True when every polynomial coefficient is proved real under parameter-only assumptions, and None otherwise.";
AffineEventualCertificate::usage = "AffineEventualCertificate[predicate,u,ass] handles a binary affine comparison and returns a truth value with a proved sufficiently small radius. It does not certify an arbitrary pre-existing radius.";
Begin["`Private`"];

mathicsQ[] := StringQ[$Version] && StringContainsQ[$Version, "Mathics"];
(* Mathics users must load AsymptoticAnalysis before this companion so that
   its bounded assumption simplifier is available. No missing System stub
   is treated as a successful proof. *)
simplify[e_, ass_] := If[mathicsQ[],
  AsymptoticAnalysis`Mathics`FullSimplify[e, ass],
  System`FullSimplify[e, ass]];
prove[e_, ass_] := TrueQ[simplify[e, ass]];

SparseCoefficientRules[p_, x_Symbol, ass_: True] := Module[
  {e, terms, pairs, groups, combined, tag = Unique["sparseExit$"]},
  Catch[
    If[! FreeQ[ass, x], Throw[Failure["ParameterAssumptions", <||>], tag]];
    e = Expand[p];
    If[! PolynomialQ[e, x], Throw[Failure["NotPolynomial", <||>], tag]];
    If[e === 0, Throw[{}, tag]];
    terms = If[Head[e] === Plus, List @@ e, {e}];
    pairs = Function[term, With[{d = Exponent[term, x]},
      {d, Coefficient[term, x, d]}]] /@ terms;
    groups = GatherBy[pairs, First];
    combined = Function[group,
      {group[[1, 1]], simplify[Total[group[[All, 2]]], ass]}] /@ groups;
    combined = Select[combined, ! prove[Last[#] == 0, ass] &];
    If[combined === {}, {},
      ({First[#]} -> Last[#]) & /@ Reverse[SortBy[combined, First]]],
    tag]];

PolynomialRealDomain[p_, x_Symbol, ass_: True] := Module[{rules},
  rules = SparseCoefficientRules[p, x, ass];
  If[Head[rules] === Failure, None,
    If[rules === {}, True,
      If[And @@ (prove[Element[Last[#], Reals], ass] & /@ rules), True, None]]]];

AffineEventualCertificate[predicate_, u_Symbol, ass_: True] := Module[
  {head = Head[predicate], left, right, d, a, b, sign, radius,
   ordered, truth, tag = Unique["eventualExit$"]},
  Catch[
    If[! FreeQ[ass, u], Throw[None, tag]];
    If[predicate === True || predicate === False,
      Throw[<|"Truth" -> predicate, "Radius" -> 1,
        "Scope" -> "All sufficiently small positive u"|>, tag]];
    If[! MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head] ||
       Length[predicate] =!= 2, Throw[None, tag]];
    {left, right} = List @@ predicate;
    ordered = MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head];
    If[ordered && ! (prove[Element[left, Reals], ass && Element[u, Reals]] &&
                    prove[Element[right, Reals], ass && Element[u, Reals]]), Throw[None, tag]];
    d = Expand[left - right];
    If[! PolynomialQ[d, u] || Exponent[d, u] > 1, Throw[None, tag]];
    a = d /. u -> 0; b = Coefficient[d, u, 1];
    If[! (prove[Element[a, Reals], ass] && prove[Element[b, Reals], ass]), Throw[None, tag]];
    sign = Which[prove[a > 0, ass], 1, prove[a < 0, ass], -1,
      prove[a == 0, ass], Which[prove[b > 0, ass], 1,
        prove[b < 0, ass], -1, prove[b == 0, ass], 0, True, None], True, None];
    If[sign === None, Throw[None, tag]];
    radius = If[prove[a == 0, ass], 1, Min[1, Abs[a]/(2 (1 + Abs[b]))]];
    truth = Switch[head, Less, sign < 0, LessEqual, sign <= 0,
      Greater, sign > 0, GreaterEqual, sign >= 0, Equal, sign == 0, Unequal, sign != 0];
    <|"Truth" -> truth, "Radius" -> radius, "Difference" -> d,
      "LeadingSign" -> sign,
      "Scope" -> "0 < u < Radius; do not replace a fixed-interval predicate by this eventual claim"|>,
    tag]];

End[];
EndPackage[];
