(* Public result-head contract; scale-specific operations and formatting are
   covered by their selected regression suites. No deprecated alias is exported. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  {Context[GeneralizedSeries], StringQ[GeneralizedSeries::usage],
    Names["AsymptoticAnalysis`PowerLogSeries"]},
  {"AsymptoticAnalysis`", True, {}}, TestID -> "generalized-series-public-head-replaces-the-former-export"]

VerificationTest[Module[{x, y, forward, inverse, direct},
  forward = AsymptoticExpansion[1/(1 - x), {x, 0, 3}];
  inverse = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
  direct = GeneralizedSeries[forward[[1]]];
  {Head[forward], Head[inverse], direct === forward,
    MatchQ[forward, _GeneralizedSeries], Normal[forward] === 1 + x + x^2,
    Normal[inverse] === y - y^2, FreeQ[Normal[forward], _GeneralizedSeries]}],
  {GeneralizedSeries, GeneralizedSeries, True, True, True, True, True},
  TestID -> "generalized-series-forward-inverse-and-explicit-construction-use-the-new-head"]

VerificationTest[Module[{x, s, text},
  s = AsymptoticExpansion[1/(1 - x), {x, 0, 3}];
  text = ToString[s, InputForm, PageWidth -> Infinity];
  {StringStartsQ[text, "GeneralizedSeries["], ToExpression[text, InputForm] === s,
    s["Remainder"] === PowerLogRemainder[x, 3, 0],
    MemberQ[s["Properties"], "Remainder"], s[1/2] === 7/4}],
  {True, True, True, True, True},
  TestID -> "generalized-series-input-form-properties-and-numeric-evaluation-survive-the-rename"]

VerificationTest[Module[{x, s, sum, product, refined},
  s = AsymptoticExpansion[1/(1 - x), {x, 0, 3}];
  sum = s + s; product = s s; refined = SeriesRefine[s, 4];
  {Head /@ {sum, product, refined},
    Expand[Normal[sum] - 2 (1 + x + x^2)] === 0,
    Expand[Normal[product] - (1 + 2 x + 3 x^2)] === 0,
    Expand[Normal[refined] - (1 + x + x^2 + x^3)] === 0}],
  {{GeneralizedSeries, GeneralizedSeries, GeneralizedSeries}, True, True, True},
  TestID -> "generalized-series-arithmetic-and-refinement-preserve-the-new-head"]
