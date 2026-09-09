(* Ordinary arithmetic is a thin, guarded entry to the precision calculus.
   The explicit normalizer holds the expression tree before evaluation so that
   a reciprocal is checked before Times can cancel its denominator. *)

AsymptoticInverse`SeriesNormalize::usage =
"SeriesNormalize[expr] merges arithmetic expressions containing GeneralizedSeries objects and regular functions, transporting all operand remainders. SeriesNormalize[expr, \"Cutoff\" -> h] truncates the normalized result at h without improving operand precision. The expression is held before automatic arithmetic. Compatible scales use ordered jets; other compatible approaches retain a composite error bound.";
Options[AsymptoticInverse`SeriesNormalize] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};
SetAttributes[AsymptoticInverse`SeriesNormalize, HoldAllComplete];
$seriesArithmeticEnabled = True;

seriesArithmeticObjectQ[GeneralizedSeries[a_Association]] :=
  KeyExistsQ[a, "Variable"] && KeyExistsQ[a, "Expression"] && KeyExistsQ[a, "Remainder"];
seriesArithmeticObjectQ[_] := False;
seriesArithmeticFlatQ[GeneralizedSeries[a_Association]] := Lookup[a, "Scale", ""] === "FiniteFlatSectors";
seriesArithmeticFlatQ[_] := False;
seriesArithmeticCompositeQ[GeneralizedSeries[a_Association]] := Lookup[a, "Scale", ""] === "Composite";
seriesArithmeticCompositeQ[_] := False;

seriesArithmeticFallbackQ[Failure[tag_, _]] := MemberQ[{
  "UnsupportedScale", "IncompatibleScales", "IncompatibleCarriers", "UnsupportedInput", "UnsupportedObservableCoefficient",
  "UnsupportedFlatCoefficient", "UnsupportedFlatSeries", "IncompatibleFlatScales", "LogarithmicLeadingPower", "ExponentialScale"}, tag];
seriesArithmeticFallbackQ[_] := False;

seriesArithmeticCheck[result_] := If[FailureQ[result], Throw[result, $tag], result];
seriesArithmeticOperationCheck[Failure["UnknownLeadingTerm", data_Association], s_GeneralizedSeries] :=
  Throw[Failure["UnknownLeadingTerm", Join[data, <|"OperandExpression" -> Normal[s],
    "OperandRemainderPower" -> Lookup[s[[1]], "RemainderPower", Missing["CompositePrecision"]]|>]], $tag];
seriesArithmeticOperationCheck[result_, _] := seriesArithmeticCheck[result];
seriesArithmeticFinish[result_List, cut_, limit_] := seriesArithmeticFinish[#, cut, limit] & /@ result;
seriesArithmeticFinish[result_, cut_, limit_] := If[cut === Automatic || ! MatchQ[result, _GeneralizedSeries], result,
  If[seriesArithmeticCompositeQ[result], fail["UnsupportedCompositeCutoff", "A composite bound has no single exponent cutoff; truncate its operands in their own scales first."]];
  If[seriesArithmeticFlatQ[result], AsymptoticInverse`FlatSeriesTruncate[result, cut, "MaxTerms" -> limit],
    AsymptoticInverse`SeriesTruncate[result, cut, "MaxTerms" -> limit]]];
seriesArithmeticPublicBinary[op_, s_, t_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  seriesArithmeticFinish[seriesArithmeticBinary[op, s, t, Automatic, limit], cut, limit]]];
seriesArithmeticPublicPower[s_, r_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[Module[{result},
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  result = seriesArithmeticPower[s, r, cut, limit, True];
  If[seriesArithmeticFlatQ[result], seriesArithmeticFinish[result, cut, limit], result]]]];
seriesArithmeticPublicUnary[head_, s_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  seriesArithmeticUnary[head, s, cut, limit]]];

(* Exact finite coefficients are never truncated before an operation. An
   infinite coefficient expansion is computed to the precision needed after
   multiplication, including the operand's leading valuation. *)
seriesRegularOperand[e_, s_GeneralizedSeries, op_, working_, limit_] := Module[
  {d = seriesData[s, limit], j, h, alpha, beta, needed, precision, attempts = 0, ass, ell},
  validateInput[e, limit]; ass = seriesAss[d]; ell = d["LogVariable"];
  j = seriesExpressionJet[e, d, limit];
  If[j === $Failed,
    h = Max[1, seriesWorkingCut[d, working]];
    j = seriesIndependentJet[e, d, h, limit];
    While[j[[1]] === {} && j[[2]] =!= Infinity && attempts < 8,
      attempts++; h = 2 h + 1; j = seriesIndependentJet[e, d, h, limit]];
    precision = d["Jet"][[2]];
    alpha = If[d["Jet"][[1]] === {}, precision, jetValuation[d["Jet"][[1]]]];
    beta = If[j[[1]] === {}, j[[2]], jetValuation[j[[1]]]];
    needed = If[precision === Infinity, h, precision];
    If[op === "Multiply" && alpha =!= Infinity && beta =!= Infinity,
      needed = needed + beta - alpha];
    If[working =!= Automatic, needed = Max[needed, working]];
    If[j[[2]] =!= Infinity && less[j[[2]], needed], j = seriesIndependentJet[e, d, needed, limit]]];
  If[! And @@ (corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ j[[1]]),
    fail["UnprovedRealCoefficient", "The regular operand must have provably real coefficients on the series branch."]];
  seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> 1, "Jet" -> j,
    "RemainderDerivativeOrder" -> If[j[[2]] === Infinity, Infinity, 0]|>],
    {"RegularOperand", {s}, e, op}]];

seriesArithmeticBinary[op_, s_GeneralizedSeries, t_, working_, limit_] := Module[{result, operand = t, data, z},
  If[FailureQ[t], Throw[t, $tag]];
  If[seriesArithmeticCompositeQ[s] || seriesArithmeticCompositeQ[t],
    Return[seriesEnvelopeBinary[op, s, t, Automatic, limit], Module]];
  If[seriesArithmeticFlatQ[s] || seriesArithmeticFlatQ[t],
    If[! seriesArithmeticFlatQ[s] && MatchQ[t, _GeneralizedSeries],
      Return[seriesArithmeticBinary[op, t, s, working, limit], Module]];
    result = catch[If[op === "Multiply",
      AsymptoticInverse`FlatSeriesMultiply[s, t, "MaxTerms" -> limit],
      If[! MatchQ[t, _GeneralizedSeries],
        z = Unique["flatOperand$"];
        AsymptoticInverse`FlatSeriesObservable[s, z + t, z, "MaxTerms" -> limit],
        fail["UnsupportedScale", "Addition needs compatible flat-sector data or a composite bound."]]]];
    If[! seriesArithmeticFallbackQ[result], Return[seriesArithmeticCheck[result], Module]];
    Return[seriesEnvelopeBinary[op, s, t, Automatic, limit], Module]];
  result = catch[
    If[! MatchQ[operand, _GeneralizedSeries], operand = seriesRegularOperand[t, s, op, working, limit]];
    seriesBinary[op, s, operand, Automatic, limit]];
  If[seriesArithmeticFallbackQ[result], seriesEnvelopeBinary[op, s, t, Automatic, limit], seriesArithmeticCheck[result]]];

seriesArithmeticPower[s_GeneralizedSeries, r_, working_, limit_, truncate_: False] := Module[{result, z, powerCut},
  If[! exactRealQ[r],
    If[! FreeQ[r, _GeneralizedSeries] || ! FreeQ[r, s["Variable"]],
      result = seriesArithmeticUnary[Log, s, working, limit];
      result = seriesArithmeticNary[Times, {r, result}, working, limit];
      Return[seriesArithmeticUnary[Exp, result, working, limit], Module]];
    fail["InvalidPower", "The exponent must be an exact real number or a supported real varying expression."]];
  If[seriesArithmeticCompositeQ[s], Return[seriesEnvelopePower[s, r, working, limit], Module]];
  If[seriesArithmeticFlatQ[s],
    If[IntegerQ[r] && r >= 0,
      z = Unique["flatPower$"];
      Return[seriesArithmeticCheck[AsymptoticInverse`FlatSeriesObservable[s, z^r, z,
        "MaxPolynomialDegree" -> Max[32, r], "MaxTerms" -> limit]], Module]];
    Return[seriesEnvelopePower[s, r, working, limit], Module]];
  powerCut = If[IntegerQ[r] && r >= 0 && ! TrueQ[truncate], Automatic, working];
  result = catch[seriesPower[s, r, powerCut, limit, truncate]];
  If[seriesArithmeticFallbackQ[result], seriesEnvelopePower[s, r, working, limit], seriesArithmeticOperationCheck[result, s]]];

seriesArithmeticUnary[head_, s_GeneralizedSeries, working_, limit_] := Module[{z = Unique["observable$"], result},
  result = catch[Switch[head,
    Log, seriesLog[s, working, limit],
    Exp, seriesExp[s, working, limit],
    _, AsymptoticInverse`SeriesObservable[s, head[z], z, "Cutoff" -> working, "MaxTerms" -> limit]]];
  If[(seriesArithmeticFallbackQ[result] || MatchQ[result, Failure["UnsupportedObservable", _Association]]) &&
      MemberQ[{Log, Exp, Abs, Sin, Cos}, head],
    seriesEnvelopeUnary[head, s, working, limit], seriesArithmeticOperationCheck[result, s]]];

seriesArithmeticNary[head_, args_List, working_, limit_] := Module[{objects, regular, result, op},
  If[Length[args] > limit, fail["ResourceLimit", "The arithmetic expression exceeds MaxTerms operands."]];
  If[AnyTrue[args, FailureQ], Throw[First[Select[args, FailureQ]], $tag]];
  objects = Select[args, MatchQ[#, _GeneralizedSeries] &];
  regular = Select[args, ! MatchQ[#, _GeneralizedSeries] &];
  If[objects === {}, Return[Apply[head, args], Module]];
  If[! FreeQ[regular, _GeneralizedSeries], fail["UnnormalizedSeriesExpression", "An operand contains a series inside an unsupported expression."]];
  op = If[head === Plus, "Add", "Multiply"];
  result = First[objects];
  Do[result = seriesArithmeticCheck[seriesArithmeticBinary[op, result, t, working, limit]], {t, Rest[objects]}];
  If[regular =!= {}, result = seriesArithmeticCheck[seriesArithmeticBinary[op, result, Apply[head, regular], working, limit]]];
  result];

seriesHeldArguments[HoldComplete[args___]] := Apply[List, Map[HoldComplete, HoldComplete[args]]];
seriesHeldNormalize[HoldComplete[s_Symbol], working_, limit_] := Module[{definitions = OwnValues[s], held},
  If[definitions === {}, Return[s, Module]];
  held = Replace[definitions, {HoldPattern[RuleDelayed[_, value_]]} :> HoldComplete[value]];
  If[! MatchQ[held, _HoldComplete], fail["UnsupportedSeriesAlias", "The symbol does not have one ordinary stored value."]];
  seriesHeldNormalize[held, working, limit]];
seriesHeldNormalize[HoldComplete[s_GeneralizedSeries], working_, limit_] := s;
seriesHeldNormalize[HoldComplete[Plus[args___]], working_, limit_] :=
  seriesArithmeticNary[Plus, seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]], working, limit];
seriesHeldNormalize[HoldComplete[Times[args___]], working_, limit_] :=
  seriesArithmeticNary[Times, seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]], working, limit];
seriesHeldNormalize[HoldComplete[Power[b_, r_]], working_, limit_] := Module[{base, exponent, logarithm},
  base = seriesHeldNormalize[HoldComplete[b], working, limit];
  exponent = seriesHeldNormalize[HoldComplete[r], working, limit];
  If[FailureQ[base] || FailureQ[exponent], Throw[If[FailureQ[base], base, exponent], $tag]];
  Which[MatchQ[base, _GeneralizedSeries], seriesArithmeticPower[base, exponent, working, limit],
    MatchQ[exponent, _GeneralizedSeries],
      logarithm = If[base === E, exponent, seriesArithmeticBinary["Multiply", exponent, Log[base], working, limit]];
      seriesArithmeticUnary[Exp, logarithm, working, limit],
    True, base^exponent]];
seriesHeldNormalize[HoldComplete[(head : Log | Exp | Abs | Sin | Cos | Tan | Sinh | Cosh | Tanh | ArcSin | ArcCos | ArcTan)[arg_]], working_, limit_] :=
  Module[{value = seriesHeldNormalize[HoldComplete[arg], working, limit]},
    If[MatchQ[value, _GeneralizedSeries], seriesArithmeticUnary[head, value, working, limit], head[value]]];
seriesHeldNormalize[HoldComplete[List[args___]], working_, limit_] :=
  seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]];
seriesHeldNormalize[held_HoldComplete, working_, limit_] := Module[{value, next},
  value = ReleaseHold[held];
  If[FailureQ[value], Throw[value, $tag]];
  If[MatchQ[value, _GeneralizedSeries] || FreeQ[value, _GeneralizedSeries], Return[value, Module]];
  next = With[{v = value}, HoldComplete[v]];
  If[next === held, fail["UnsupportedSeriesExpression", "Use arithmetic or a supported analytic function around series objects; use Normal to discard their remainders."]];
  seriesHeldNormalize[next, working, limit]];

seriesArithmeticAutomatic[held_HoldComplete] := Block[{$seriesArithmeticEnabled = False},
  catch[seriesHeldNormalize[held, Automatic, 20000]]];

GeneralizedSeries /: expression : Plus[___, s_GeneralizedSeries, ___] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Times[___, s_GeneralizedSeries, ___] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Power[s_GeneralizedSeries, _] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Power[_, s_GeneralizedSeries] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
Scan[Function[head, With[{h = head},
  GeneralizedSeries /: expression : h[s_GeneralizedSeries] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
    seriesArithmeticAutomatic[HoldComplete[expression]]]],
  {Log, Exp, Abs, Sin, Cos, Tan, Sinh, Cosh, Tanh, ArcSin, ArcCos, ArcTan}];

AsymptoticInverse`SeriesNormalize[expr_, OptionsPattern[]] := Block[{$seriesArithmeticEnabled = False}, catch[Module[
  {cut = OptionValue["Cutoff"], limit = OptionValue["MaxTerms"], result, candidate, precision, next, working, tries = 0},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  result = catch[seriesHeldNormalize[HoldComplete[expr], Automatic, limit]];
  working = If[cut === Automatic, 1, Max[1, cut]];
  While[MatchQ[result, Failure["UnknownLeadingTerm", _Association]] && tries < 8,
    tries++; working = 2 working + 1;
    candidate = catch[seriesHeldNormalize[HoldComplete[expr], working, limit]];
    If[candidate === result, Break[]]; result = candidate];
  seriesArithmeticCheck[result];
  (* Recompute only operations on the supplied operands. A larger work order
     can expose coefficients of an exact regular function or a newly formed
     reciprocal, but can never improve an operand's unknown remainder. *)
  If[cut =!= Automatic && MatchQ[result, _GeneralizedSeries] &&
      ! seriesArithmeticCompositeQ[result] && ! seriesArithmeticFlatQ[result],
    precision = Lookup[result[[1]], "RemainderPower", Infinity]; working = Max[working, cut];
    While[precision =!= Infinity && less[precision, cut] && tries < 8,
      tries++; working = working + cut - precision + 1;
      candidate = seriesHeldNormalize[HoldComplete[expr], working, limit];
      If[! MatchQ[candidate, _GeneralizedSeries] || seriesArithmeticCompositeQ[candidate], Break[]];
      next = Lookup[candidate[[1]], "RemainderPower", Infinity]; result = candidate;
      If[! less[precision, next], Break[]]; precision = next]];
  seriesArithmeticFinish[result, cut, limit]]]];
AsymptoticInverse`SeriesNormalize[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use SeriesNormalize[expression, options]."|>];
