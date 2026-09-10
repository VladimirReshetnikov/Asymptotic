(* UNRUN policy/robustness specifications, separate from the T01 patch suite.
   Load the package and ReviewAdapters.wl before TestReport. The native-routing
   test specifies a proposed coverage improvement, not documented current behavior. *)
VerificationTest[
 Module[{x, s},
  s = AsymptoticAnalysis`AsymptoticExpansion[1+x, {x,0,2}, "Backend"->"Package"];
  MatchQ[Quiet[Check[AsymptoticBoundaryReview`CheckedInverseCoefficient[s, {0}],
       "UnexpectedMessage"]], Failure["UnsupportedCoefficientModel", _Association]]],
 True, TestID -> "A01-valid-forward-object-rejected-before-model-indexing"]

VerificationTest[
 Module[{x, y, s, a, b},
  s = AsymptoticAnalysis`AsymptoticInverse[x+x^2, {x,0}, {y,4}];
  a = AsymptoticBoundaryReview`CheckedInverseCoefficient[s, {1}];
  b = AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}];
  SameQ[a,b]],
 True, TestID -> "A01-ordinary-inverse-control"]

VerificationTest[
 Module[{x, a, native, automatic},
  native = AsymptoticAnalysis`AsymptoticExpansion[
    ConditionalExpression[1+I*x, a>0], {x,0,2},
    Assumptions->a>0, "Backend"->"Series"];
  automatic = AsymptoticAnalysis`AsymptoticExpansion[
    ConditionalExpression[1+I*x, a>0], {x,0,2}, Assumptions->a>0];
  If[! MatchQ[native, _AsymptoticAnalysis`GeneralizedSeries], False,
   MatchQ[automatic, _AsymptoticAnalysis`GeneralizedSeries] &&
    automatic["Kind"] === "Native" &&
    TrueQ[FullSimplify[Normal[automatic] == Normal[native], a>0]]]],
 True, TestID -> "N01-proposed-conditional-native-coverage"]

VerificationTest[
 AsymptoticBoundaryReview`NativeOutcome /@ {
  $Failed, Failure["Example", <||>], 0, ConditionalExpression[1, a>0], {1,$Failed}},
 {"Failed","Failed","ReturnedWithoutFailureMarker","ReturnedWithoutFailureMarker","ContainsFailure"},
 TestID -> "U01-proposed-outcome-classification"]
