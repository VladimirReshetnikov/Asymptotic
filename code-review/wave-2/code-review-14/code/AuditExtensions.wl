(* Incremental audit prototypes. These helpers do NOT alter upstream definitions.
   Native execution was unavailable during the audit; run the supplied tests.
   Load the AsymptoticInverse package first, then Get this file. *)
BeginPackage["AsymptoticAudit`", {"AsymptoticInverse`"}];
ParameterSafeCompose::usage = "ParameterSafeCompose[outer,inner,opts] conservatively rejects capture of a fixed parameter of an inexact outer germ by the inner variable. The prototype requires a retained ordinary forward source or explicit FixedParameters metadata.";
BoundPreservingTruncate::usage = "BoundPreservingTruncate[s,h,opts] retains a finite absolute tail bound when truncating: Bnew=Bold+Abs[Normal[s]-Normal[result]], on the original bound conditions. It does not invent a numeric constant for Big-O.";
CheckedFourierInverse::usage = "CheckedFourierInverse[args,opts] rejects non-Automatic SeriesTermGoal instead of silently ignoring it; otherwise calls AsymptoticFourierInverse.";
RationalAffineRange::usage = "RationalAffineRange[expression,x,{lo,hi}] gives the exact range of a structurally rational affine expression. Nonaffine or unsupported syntax returns $Failed. No Expand or symbolic solver is used.";
Options[ParameterSafeCompose] = Options[AsymptoticInverse`SeriesCompose];
Options[BoundPreservingTruncate] = Options[AsymptoticInverse`SeriesTruncate];
Options[CheckedFourierInverse] = Options[AsymptoticInverse`AsymptoticFourierInverse];
Begin["`Private`"];

ParameterSafeCompose[
    outer : AsymptoticInverse`GeneralizedSeries[oa_Association],
    inner : AsymptoticInverse`GeneralizedSeries[ia_Association],
    opts : OptionsPattern[]] := Module[{ov, iv, source, parameters, dependencies},
  ov = Lookup[oa, "Variable", Missing["Variable"]];
  iv = Lookup[ia, "Variable", Missing["Variable"]];
  If[! MatchQ[{ov, iv}, {_Symbol, _Symbol}],
    Return[Failure["MissingScope", <|"MessageTemplate" -> "Both germs need named expansion variables."|>]]];
  If[ov =!= iv && Lookup[oa, "Remainder", Missing["Remainder"]] =!= 0,
    parameters = Lookup[oa, "FixedParameters", Missing["Unrecorded"]];
    source = If[Lookup[oa, "Kind", ""] === "Forward",
      Lookup[oa, "Function", Missing["Source"]], Missing["Source"]];
    If[MissingQ[source] && ! ListQ[parameters],
      Return[Failure["MissingParameterScope", <|"MessageTemplate" ->
        "This prototype requires a retained forward source or explicit FixedParameters metadata; it does not infer uniformity from a finite jet."|>]]];
    dependencies = {If[MissingQ[source], {}, source],
      If[ListQ[parameters], parameters, {}],
      Lookup[oa, "Assumptions", True], Lookup[oa, "TargetDomain", True]};
    If[! FreeQ[dependencies, iv],
      Return[Failure["ParameterCapture", <|"MessageTemplate" ->
        "The inner expansion variable was a fixed parameter of the inexact outer germ. Re-expand the exact composed source or supply a separately verified uniform contract.",
        "OuterVariable" -> ov, "CapturedParameter" -> iv,
        "UniformityEstablished" -> False|>]]]];
  AsymptoticInverse`SeriesCompose[outer, inner, opts]];

BoundPreservingTruncate[
    s : AsymptoticInverse`GeneralizedSeries[a_Association], h_,
    opts : OptionsPattern[]] := Module[{result, bound, condition, difference, data},
  result = AsymptoticInverse`SeriesTruncate[s, h, opts];
  If[FailureQ[result], Return[result]];
  If[! MatchQ[result, AsymptoticInverse`GeneralizedSeries[_Association]],
    Return[Failure["UnexpectedResult", <|"Result" -> result|>]]];
  bound = Lookup[a, "AbsoluteRemainderBound", Missing["Unavailable"]];
  condition = Lookup[a, "RemainderBoundConditions", Missing["Unavailable"]];
  If[MissingQ[bound] || MissingQ[condition],
    Return[Failure["MissingQuantitativeBound", <|"MessageTemplate" ->
      "No explicit absolute remainder bound with conditions is retained; a Big-O scale is not a numerical bound.",
      "TruncatedSeries" -> result|>]]];
  difference = Normal[s] - Normal[result];
  difference = TimeConstrained[FullSimplify[difference,
    Lookup[a, "Assumptions", True] && condition], 2, difference];
  data = result[[1]];
  (* A signed lower bound is intentionally NOT copied. *)
  AsymptoticInverse`GeneralizedSeries[Join[data, <|
    "AbsoluteRemainderBound" -> bound + Abs[difference],
    "RemainderBoundConditions" -> condition,
    "QuantitativeRemainderTransport" -> <|
      "Rule" -> "TriangleInequalityUnderExactFiniteTruncation",
      "InputBound" -> bound, "DiscardedFiniteExpression" -> difference,
      "EvidenceSource" -> "Retained upstream absolute bound; no native or interval proof rerun."|>|>]]];

CheckedFourierInverse[f_, {x_Symbol, x0_}, {y_Symbol, h_},
    opts : OptionsPattern[]] := Module[{goal = OptionValue[SeriesTermGoal]},
  If[goal =!= Automatic,
    Return[Failure["UnsupportedOption", <|"MessageTemplate" ->
      "This explicit-cutoff Fourier interface does not implement SeriesTermGoal; omit it or use Automatic.",
      "Option" -> SeriesTermGoal, "Value" -> goal|>]]];
  AsymptoticInverse`AsymptoticFourierInverse[f, {x, x0}, {y, h}, opts]];

rationalQ[q_] := IntegerQ[q] || Head[q] === Rational;
affinePair[e_, x_Symbol] := Module[{pairs, acc, next},
  Which[e === x, {1, 0}, rationalQ[e], {0, e},
    Head[e] === Plus,
      pairs = affinePair[#, x] & /@ (List @@ e);
      If[MemberQ[pairs, $Failed], $Failed, Total[pairs]],
    Head[e] === Times,
      pairs = affinePair[#, x] & /@ (List @@ e);
      If[MemberQ[pairs, $Failed], Return[$Failed, Module]];
      acc = {0, 1};
      Do[If[acc[[1]] pair[[1]] =!= 0, Return[$Failed, Module]];
        next = {acc[[1]] pair[[2]] + acc[[2]] pair[[1]], acc[[2]] pair[[2]]};
        acc = next, {pair, pairs}]; acc,
    True, $Failed]];
RationalAffineRange[e_, x_Symbol, interval : {lo_?rationalQ, hi_?rationalQ}] :=
  Module[{pair},
    If[lo > hi, Return[$Failed, Module]];
    pair = affinePair[e, x];
    If[pair === $Failed, $Failed, Sort[pair[[1]] interval + pair[[2]]]]];
RationalAffineRange[___] := $Failed;
End[];
EndPackage[];
