(* Applied inverse functions are implicit scalar germs.  Parse their callable,
   establish its real source branch, then compose the existing inverse with
   the precision-tracked target argument.  Never use native Series on an
   unevaluated InverseFunction as the coefficient oracle. *)

$inverseFunctionProvenance = None;
$inverseFunctionBranchSelections = Automatic;
$inverseFunctionSyntaxCache = None;
$inverseFunctionBranchCache = None;

inverseFunctionParsedData[e_, ass_, limit_] := Module[{key = HoldComplete[e, ass, limit], data},
  If[AssociationQ[$inverseFunctionSyntaxCache] && KeyExistsQ[$inverseFunctionSyntaxCache, key],
    Return[$inverseFunctionSyntaxCache[key], Module]];
  data = inverseFunctionApplicationData[e, ass, limit];
  If[AssociationQ[$inverseFunctionSyntaxCache], AssociateTo[$inverseFunctionSyntaxCache, key -> data]];
  data];

inverseFunctionSelectedBranch[data_, target_, side_, ass_, limit_] := Module[{selection, key, branch},
  selection = inverseFunctionSelection[data];
  key = With[{body = data["Body"], source = data["SourceVariable"], condition = data["Condition"], chosen = selection},
    HoldComplete[body, source, condition, target, side, ass, limit, chosen]];
  If[AssociationQ[$inverseFunctionBranchCache] && KeyExistsQ[$inverseFunctionBranchCache, key],
    Return[$inverseFunctionBranchCache[key], Module]];
  branch = inverseFunctionSelectBranch[data, target, side, ass, limit, selection];
  If[FailureQ[branch], Throw[branch, $tag]];
  If[AssociationQ[$inverseFunctionBranchCache], AssociateTo[$inverseFunctionBranchCache, key -> branch]];
  branch];

inverseFunctionEventually[condition_, u_, ass_] := Module[{simple, delta, proof},
  simple = Quiet[FullSimplify[condition, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  delta = Unique["inverseRadius$"];
  proof = Quiet[TimeConstrained[Resolve[Exists[delta, delta > 0 &&
      ForAll[u, Implies[0 < u < delta, condition]]], Reals], 5, $Failed]];
  TrueQ[Quiet[FullSimplify[proof, ass]]]];

(* HoldAllComplete at the public boundary prevents Wolfram's automatic
   ConditionalExpression propagation from rewriting Assumptions before this
   check.  The private entry evaluates arguments normally, including Sequence
   and native closed-form inverse evaluation. *)
forwardPublic[f_, x_, x0_, cutoff_, opts : OptionsPattern[AsymptoticExpansion]] := Block[
  {$inverseFunctionProvenance = {}, $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>, $inverseFunctionBranchSelections =
    OptionValue[AsymptoticExpansion, {opts}, "InverseFunctionBranches"]}, Module[
  {body = f, condition, ass, parameterAss, coord, result, rules, records, targetDomain},
  ass = optionAssumptions[AsymptoticExpansion, {opts}];
  {body, parameterAss, condition} = splitApproachInput[body, x, ass];
  coord = localCoordinate[x, x0, OptionValue[AsymptoticExpansion, {opts}, Direction]];
  If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], coord["u"], parameterAss],
    fail["IncompatibleTargetCondition", "The expression's condition must hold eventually on the requested real approach.",
      <|"Condition" -> condition, "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"]|>]];
  rules = DeleteCases[withoutAssumptions[{opts}], HoldPattern[("InverseFunctionBranches" -> _) | ("InverseFunctionBranches" :> _)]];
  result = inverseFunctionDirectExpansion[body, x, x0, cutoff, parameterAss, coord,
    OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]];
  If[result === $Failed,
    result = dirichletSpecialForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = specialFunctionForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = barnesForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = gammaForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = exponentialForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = forwardCore[body, x, x0, cutoff, Assumptions -> parameterAss, Sequence @@ rules]];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  records = DeleteDuplicates[$inverseFunctionProvenance];
  targetDomain = condition && coord["LocalVariable"] > 0 && Lookup[result[[1]], "TargetDomain", True];
  GeneralizedSeries[Join[result[[1]],
    If[AssociationQ[Lookup[result[[1]], "SeriesRepresentation", None]],
      <|"SeriesRepresentation" -> Join[result["SeriesRepresentation"],
        <|"Domain" -> targetDomain && Lookup[result["SeriesRepresentation"], "Domain", True]|>]|>, <||>],
    If[Lookup[result[[1]], "Kind", ""] === "Forward", <|"Function" -> ConditionalExpression[body, condition]|>, <||>],
    If[KeyExistsQ[result[[1]], "InverseFunctionExpression"],
      <|"InverseFunctionExpression" -> ConditionalExpression[body, condition]|>, <||>], <|
    "TargetDomain" -> targetDomain,
    "InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> records|>]]]];

Options[AsymptoticExpansion] = Append[Options[AsymptoticExpansion], "InverseFunctionBranches" -> Automatic];
Options[AsymptoticInverse] = Append[Options[AsymptoticInverse], "InverseFunctionBranches" -> Automatic];
Options[AsymptoticAnalysis`SeriesObservable] = Append[Options[AsymptoticAnalysis`SeriesObservable], "InverseFunctionBranches" -> Automatic];

(* Decide relational conditions using the available input jet, including its
   remainder. An unknown zero block cannot prove equality or a sign. *)
inverseFunctionConditionOnJet[c_, x_, input_, d_, cut_, limit_] := Module[
  {head = Head[c], values, pairs, j, row, degree, coefficient, sign, scalar},
  If[FreeQ[c, x], Return[TrueQ[Quiet[FullSimplify[c, seriesAss[d]]]], Module]];
  If[MemberQ[{And, Or}, head],
    values = inverseFunctionConditionOnJet[#, x, input, d, cut, limit] & /@ List @@ c;
    Return[If[head === And, And @@ values, Or @@ values], Module]];
  If[head === Inequality,
    pairs = Partition[List @@ c, 3, 2];
    Return[And @@ (inverseFunctionConditionOnJet[#[[2]][#[[1]], #[[3]]], x, input, d, cut, limit] & /@ pairs), Module]];
  If[head === Element && c[[2]] === Reals,
    j = seriesJetApply[c[[1]], x, input, d, cut, limit];
    Return[And @@ (TrueQ[FullSimplify[Element[#[[2]], Reals], seriesAss[d] && Element[d["LogVariable"], Reals]]] & /@ j[[1]]), Module]];
  If[! MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head], Return[False, Module]];
  If[Length[c] > 2,
    pairs = If[head === Unequal, Subsets[List @@ c, {2}], Partition[List @@ c, 2, 1]];
    Return[And @@ (inverseFunctionConditionOnJet[Apply[head, #], x, input, d, cut, limit] & /@ pairs), Module]];
  j = seriesJetApply[c[[1]] - c[[2]], x, input, d, cut, limit];
  If[j[[1]] === {},
    Return[j[[2]] === Infinity && MemberQ[{Equal, LessEqual, GreaterEqual}, head], Module]];
  row = First[j[[1]]]; degree = polyDegree[row[[2]], d["LogVariable"]];
  coefficient = (-1)^degree Coefficient[row[[2]], d["LogVariable"], degree];
  sign = Which[provablyPositive[coefficient, seriesAss[d]], 1,
    provablyNegative[coefficient, seriesAss[d]], -1, True, 0];
  Which[MemberQ[{Less, LessEqual}, head], sign === -1,
    MemberQ[{Greater, GreaterEqual}, head], sign === 1, head === Unequal, sign =!= 0,
    True, False]];

inverseFunctionDirectExpansion[e_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {data, branch, result, source, record, base = e, power = 1, model},
  If[Head[e] === Power && FreeQ[e[[2]], x] && inverseFunctionApplicationQ[e[[1]]],
    base = e[[1]]; power = e[[2]]];
  data = If[inverseFunctionApplicationQ[base], inverseFunctionParsedData[base, ass, limit],
    inverseFunctionNativeLambertData[base, x]];
  If[data === $Failed, Return[$Failed, Module]];
  If[data["TargetExpression"] =!= x || ! FreeQ[data["Parameters"], x], Return[$Failed, Module]];
  branch = inverseFunctionSelectedBranch[data, x0, If[coord["Infinite"], 0, coord["Sign"]], ass, limit];
  source = data["SourceVariable"];
  (* Gamma inversion at a source infinity supports powers of the source
     itself. Other inverse charts may instead represent a displacement
     from a finite endpoint, so their outer powers use the ordinary path. *)
  If[power =!= 1,
    model = gammaInverseModel[data["Body"], source, ass];
    If[model === $Failed || branch["SourcePoint"] =!=
        If[provablyPositive[model["SourceScale"], ass], Infinity, -Infinity],
      Return[$Failed, Module]]];
  result = inverseDispatch[data["Body"], source, branch["SourcePoint"], x, cut,
    Assumptions -> ass, Direction -> branch["Direction"], SeriesTermGoal -> goal,
    "Power" -> power, "MaxTerms" -> limit];
  If[FailureQ[result], Throw[result, $tag]];
  result = GeneralizedSeries[Join[result[[1]], <|"SourceVariable" -> source,
    "SourceDomain" -> branch["SourceDomain"] && inverseEvidenceSourceDomain[result[[1]], source], "InverseFunctionSyntax" -> data,
    "InverseFunctionBranch" -> branch, "InverseFunctionExpression" -> e,
    "InverseFunctionExpansionPoint" -> x0, "InverseFunctionExpansionDirection" -> coord["Direction"]|>]];
  record = <|"Expression" -> e, "Syntax" -> data, "Branch" -> branch, "InverseSeries" -> result|>;
  If[ListQ[$inverseFunctionProvenance], AppendTo[$inverseFunctionProvenance, record]];
  result];

(* Native evaluation of an inverse of t Exp[t] can erase the InverseFunction
   head. Recover its documented real branch from ProductLog itself, retaining
   that branch rather than applying a principal-root convention afterwards. *)
inverseFunctionNativeLambertData[e_, x_] := Module[{k, argument, source},
  If[Head[e] =!= ProductLog || ! MemberQ[{1, 2}, Length[e]], Return[$Failed, Module]];
  k = If[Length[e] === 1, 0, e[[1]]]; argument = Last[e];
  If[! MemberQ[{0, -1}, k] || argument =!= x, Return[$Failed, Module]];
  source = Unique["inverseSource$"];
  <|"Body" -> source Exp[source], "SourceVariable" -> source,
    "Condition" -> If[k === 0, source >= -1, source <= -1],
    "TargetExpression" -> argument, "Parameters" -> {}, "ParameterPositions" -> {},
    "SourceArguments" -> {source}, "ArgumentIndex" -> 1, "ArgumentCount" -> 1,
    "OriginalExpression" -> e, "OriginalOperator" -> ProductLog,
    "NativeRealBranch" -> k, "NativeIdentity" -> "ProductLog[k,z] Exp[ProductLog[k,z]] == z"|>];

inverseFunctionPublicInverse[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Block[
  {$inverseFunctionProvenance = {}, $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>, $inverseFunctionBranchSelections =
    OptionValue[AsymptoticInverse, {opts}, "InverseFunctionBranches"]}, Module[
  {body = f, condition, ass, parameterAss, coord, result, rules},
  ass = optionAssumptions[AsymptoticInverse, {opts}];
  {body, parameterAss, condition} = splitApproachInput[body, x, ass];
  coord = localCoordinate[x, x0, OptionValue[AsymptoticInverse, {opts}, Direction]];
  If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], coord["u"], parameterAss],
    fail["IncompatibleSourceCondition", "The forward expression's condition must hold eventually on the requested real source approach.",
      <|"Condition" -> condition, "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"]|>]];
  rules = DeleteCases[withoutAssumptions[{opts}], HoldPattern[("InverseFunctionBranches" -> _) | ("InverseFunctionBranches" :> _)]];
  result = inverseDispatch[body, x, x0, y, cutoff, Assumptions -> parameterAss, Sequence @@ rules];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  If[condition === True && $inverseFunctionProvenance === {} && $inverseFunctionBranchSelections === Automatic,
    Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"OriginalExpression" -> f,
    "ConditionalSourceReplay" -> ConditionalExpression[body, condition],
    "SourceVariable" -> x, "SourceDomain" -> condition &&
      inverseEvidenceSourceDomain[result[[1]], x],
    "InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> DeleteDuplicates[$inverseFunctionProvenance]|>]]]];

inverseFunctionTargetGerm[j_, ell_, ass_] := Module[{parts, eta, rest, row, degree, sign},
  If[j[[1]] === {}, fail["UnknownLeadingTerm", "The inverse target is known only through a remainder."]];
  parts = splitJet[j[[1]]];
  If[parts[[1]] =!= {},
    row = First[parts[[1]]]; degree = polyDegree[row[[2]], ell];
    sign = (-1)^degree Coefficient[row[[2]], ell, degree];
    Return[<|"Limit" -> Which[provablyPositive[sign, ass], Infinity,
      provablyNegative[sign, ass], -Infinity,
      True, fail["UnprovedSign", "The inverse target's infinite limit has no proved sign."]],
      "Side" -> 0, "Order" -> -row[[1]]|>, Module]];
  eta = parts[[2]];
  If[! FreeQ[eta, ell],
    fail["UnsupportedInverseTargetScale", "A purely logarithmically divergent target requires a logarithmic composition chart."]];
  rest = parts[[3]];
  If[rest === {}, fail["UnknownLeadingTerm", "No nonconstant inverse target block is available; increase its precision."]];
  row = First[rest]; degree = polyDegree[row[[2]], ell];
  sign = (-1)^degree Coefficient[row[[2]], ell, degree];
  <|"Limit" -> eta, "Side" -> Which[provablyPositive[sign, ass], 1,
    provablyNegative[sign, ass], -1,
    True, fail["UnprovedSign", "The inverse target's one-sided approach has no proved sign."]],
    "Order" -> row[[1]]|>];

inverseFunctionSelection[data_] := Which[
  $inverseFunctionBranchSelections === Automatic, Automatic,
  AssociationQ[$inverseFunctionBranchSelections],
    Lookup[$inverseFunctionBranchSelections, data["OriginalOperator"], Automatic],
  True, fail["InvalidOption", "InverseFunctionBranches must be Automatic or an association from inverse operators to source-point/direction associations."]];

inverseFunctionForwardJet[e_, u_, ell_, ass_, cut_, limit_] :=
  inverseFunctionJetApply[e, u, pVar,
    <|"Variable" -> u, "ScaleVariable" -> u, "LogVariable" -> ell,
      "Assumptions" -> ass, "Domain" -> u > 0, "Prefactor" -> 1, "Offset" -> 0,
      "Jet" -> pVar, "Cutoff" -> cut, "RemainderDerivativeOrder" -> Infinity|>, cut, limit];

inverseFunctionJetApply[e_, x_, input_, d_, cut_, limit_] := Module[
  {data, reduced, target, germ, branch, source, v, outer, inner, composed, flat, outerCut, record, ass},
  If[cut === Infinity, fail["InfiniteSeries", "An implicit inverse generally needs a finite working precision."]];
  ass = d["Assumptions"];
  data = inverseFunctionParsedData[e, ass, limit];
  If[! FreeQ[data["Parameters"], x],
    reduced = inverseFunctionSeparateFamily[data, x, ass, limit];
    If[reduced === $Failed,
      fail["VaryingInverseParameters", "The varying non-inverted arguments do not reduce to a proved affine output family and need a coupled implicit expansion.",
        <|"ParameterPositions" -> data["ParameterPositions"], "Parameters" -> data["Parameters"]|>]];
    If[! TrueQ[inverseFunctionConditionOnJet[reduced["Amplitude"] != 0, x, input, d, cut, limit]],
      fail["UnprovedInverseFamilyAmplitude", "The exact inverse-family reduction requires an eventually nonzero amplitude.",
        <|"Amplitude" -> reduced["Amplitude"]|>]];
    data = Join[reduced, <|"AmplitudeNonvanishingVerified" -> True|>]];
  target = seriesJetApply[data["TargetExpression"], x, input, d, cut, limit];
  germ = inverseFunctionTargetGerm[target, d["LogVariable"], seriesAss[d]];
  branch = inverseFunctionSelectedBranch[data, germ["Limit"], germ["Side"], ass, limit];
  source = data["SourceVariable"]; v = Unique["inverseTarget$"];
  outerCut = Max[2, Ceiling[Abs[cut]/germ["Order"]] + 2];
  outer = inverseDispatch[data["Body"], source, branch["SourcePoint"], v, outerCut,
    Assumptions -> ass, Direction -> branch["Direction"], "MaxTerms" -> limit];
  If[FailureQ[outer], Throw[outer, $tag]];
  outer = GeneralizedSeries[Join[outer[[1]], <|"SourceVariable" -> source,
    "SourceDomain" -> branch["SourceDomain"] && inverseEvidenceSourceDomain[outer[[1]], source], "InverseFunctionSyntax" -> data,
    "InverseFunctionBranch" -> branch|>]];
  inner = seriesMake[Join[d, <|"Jet" -> target, "Prefactor" -> 1, "Offset" -> 0|>], {"InverseTarget", {}, e}];
  composed = AsymptoticAnalysis`SeriesCompose[outer, inner, "Cutoff" -> cut, "MaxTerms" -> limit];
  If[FailureQ[composed], Throw[composed, $tag]];
  flat = seriesFlat[seriesData[composed, limit], limit];
  If[flat === $Failed, fail["UnsupportedInverseCompositionScale", "The selected inverse does not flatten to the enclosing power-log coordinate."]];
  record = <|"Expression" -> e, "Syntax" -> data, "Branch" -> branch, "InverseSeries" -> outer|>;
  If[ListQ[$inverseFunctionProvenance], AppendTo[$inverseFunctionProvenance, record]];
  flat["Jet"] /. flat["LogVariable"] -> d["LogVariable"]];
