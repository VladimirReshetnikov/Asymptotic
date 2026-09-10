(* Candidate companion helpers. NOT an installed or native-validated patch.
   Load the reviewed AsymptoticAnalysis package first. This file changes no
   definitions in that package and makes no global System changes. *)
BeginPackage["AsymptoticReview`"];
OrientedInverseContribution::usage =
  "OrientedInverseContribution[s,k] describes an ordinary inverse coefficient in the represented observable, including its source orientation. Add AdditiveOffset once, not once per coefficient.";
DescribeModelLimit::usage =
  "DescribeModelLimit[model] separates the normalized model offset from the actual target limit for a numerical nonzero real leading power.";
PerturbativeInverseChecked::usage =
  "PerturbativeInverseChecked[phi,h,{x,y},n] refuses a core inverse containing the eliminated source variable before calling PerturbativeInverse.";
Begin["`Private`"];

OrientedInverseContribution[s_AsymptoticAnalysis`GeneralizedSeries, k_List] :=
 Module[{a = s[[1]], c, sign, r, p, y, v, offset, multiplier, contribution},
  If[Lookup[a, "Kind", None] =!= "Inverse" || Lookup[a, "Truncation", None] =!= "Exponent",
   Return[Failure["UnsupportedReviewScope", <|"MessageTemplate" ->
     "This companion supports ordinary exponent-truncated inverse objects only."|>]]];
  c = AsymptoticAnalysis`InverseExpansionCoefficient[s, k];
  If[FailureQ[c], Return[c]];
  {r, y} = Lookup[a, {"Power", "Variable"}];
  p = a["Model"]["LeadingPower"];
  sign = Which[a["ExpansionPoint"] === Infinity, 1,
    a["ExpansionPoint"] === -Infinity, -1,
    a["Direction"] === "FromBelow", -1, True, 1];
  v = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]];
  offset = If[! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]] && r === 1,
    a["ExpansionPoint"], 0];
  multiplier = sign^r;
  contribution = multiplier (v/a["LeadingCoefficient"])^c["Exponent"]
    (c["Coefficient"] /. \[FormalL] -> Log[v/a["LeadingCoefficient"]]/p);
  Join[c, <|"LocalCoefficient" -> c["Coefficient"],
    "ObservableMultiplier" -> multiplier,
    "ObservableCoefficient" -> multiplier c["Coefficient"],
    "AdditiveOffset" -> offset,
    "ContributionExpression" -> contribution,
    "Meaning" -> "Add AdditiveOffset once to the sum of ContributionExpression over the retained multi-indices. Equal-weight contributions must be collected before term counting.",
    "ReviewScope" -> "Ordinary inverse; no change to stored coefficients or remainder precision."|>]];
OrientedInverseContribution[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
  "Use OrientedInverseContribution[ordinaryInverse,kList]."|>];

DescribeModelLimit[m_Association] := Module[{p, a, b, ass, endpoint},
  If[! And @@ (KeyExistsQ[m, #] & /@ {"LeadingPower", "LeadingCoefficient", "Limit"}),
    Return[Failure["InvalidModel", <|"MessageTemplate" -> "Required model fields are absent."|>]]];
  {p, a, b} = Lookup[m, {"LeadingPower", "LeadingCoefficient", "Limit"}];
  ass = Lookup[m, "Assumptions", True];
  endpoint = Which[
    TrueQ[FullSimplify[p > 0, ass]], b,
    TrueQ[FullSimplify[p < 0 && a > 0, ass]], Infinity,
    TrueQ[FullSimplify[p < 0 && a < 0, ass]], -Infinity,
    True, Missing["UnprovedTargetLimit"]];
  <|"ModelOffset" -> b, "TargetLimit" -> endpoint,
    "LeadingPower" -> p, "LeadingCoefficient" -> a,
    "Assumptions" -> ass,
    "LegacyLimitMeaning" -> "Offset removed by rowsToModel, not necessarily a limit and not necessarily the Laurent constant coefficient."|>];
DescribeModelLimit[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
  "Use DescribeModelLimit[modelAssociation]."|>];

PerturbativeInverseChecked[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=
 If[x === y || ! FreeQ[h, y] || ! FreeQ[phi, x],
   Failure["InvalidVariables", <|"MessageTemplate" ->
     "Use distinct source and target variables; h must not contain y and phi must not contain x."|>],
   AsymptoticAnalysis`PerturbativeInverse[phi, h, {x, y}, n]];
PerturbativeInverseChecked[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=
 PerturbativeInverseChecked[y, h, {x, y}, n];
PerturbativeInverseChecked[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
  "Use PerturbativeInverseChecked[phi,h,{x,y},nonnegativeOrder]."|>];
End[];
EndPackage[];
