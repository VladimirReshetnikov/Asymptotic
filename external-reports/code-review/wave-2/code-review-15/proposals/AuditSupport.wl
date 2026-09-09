(* Review-only helpers for AsymptoticInverse at 921387e.
   Not executed in a native Wolfram kernel during this audit.
   Load the pinned upstream package first. No upstream definitions are replaced.
   The graded product uses private upstream primitives and is revision-specific. *)
BeginPackage["AsymptoticAudit`"];
ExpectedTargetApproach::usage = "ExpectedTargetApproach[s] derives the target endpoint and side for the reviewed flat, Erfc-tail, or quadratic-threshold charts.";
AttachExpectedApproach::usage = "AttachExpectedApproach[s] returns a new object with corrected SeriesApproach for the explicitly supported charts. It does not mutate s or patch producers.";
TightenCertificate::usage = "TightenCertificate[c] intersects the reported center-error bounds with those already proved by c's root enclosure. It does not establish a new certificate.";
FlatSeriesMultiplyGraded::usage = "FlatSeriesMultiplyGraded[s,t] is a revision-specific proposed flat product preserving exponential grades until tail dominance is decided.";
Options[FlatSeriesMultiplyGraded] = {"InnerCutoff" -> Automatic, "MaxTerms" -> 20000};
Begin["`Private`"];

failure[tag_, message_] := Failure[tag, <|"MessageTemplate" -> message|>];
provedSign[e_, ass_] := Block[{$Assumptions = True}, Which[
  TrueQ[FullSimplify[e > 0, ass]], 1,
  TrueQ[FullSimplify[e < 0, ass]], -1,
  True, 0]];
monomialApproach[y_, b_, a_, q_, ass_] := Module[{s = provedSign[a, ass], p = provedSign[q, ass]},
  If[s == 0 || p == 0, Return[failure["UnprovedChartSign", "The chart coefficient and power must have proved nonzero real signs."]]];
  If[p > 0,
    <|"Variable" -> y, "Point" -> b, "Direction" -> If[s > 0, "FromAbove", "FromBelow"]|>,
    <|"Variable" -> y, "Point" -> s Infinity, "Direction" -> If[s > 0, "FromBelow", "FromAbove"]|>]];

ExpectedTargetApproach[AsymptoticInverse`GeneralizedSeries[a_Association]] := Module[
  {y = Lookup[a, "Variable", None], ass = Lookup[a, "Assumptions", True], d, model, s, b, x, c},
  If[! MatchQ[y, _Symbol], Return[failure["InvalidOperand", "A recorded target variable is required."]]];
  d = Lookup[a, "FlatRepresentation", None];
  If[AssociationQ[d], Return[monomialApproach[y, d["TargetOffset"], d["CoreCoefficient"], d["CorePower"], ass]]];
  If[Lookup[a, "Kind", ""] === "FlatInverse",
    model = Lookup[a, "Model", None];
    If[! AssociationQ[model], Return[failure["InvalidOperand", "Missing flat model."]]];
    Return[monomialApproach[y, model["Offset"], model["CoreCoefficient"], model["CorePower"], ass]]];
  If[Lookup[a, "Adapter", ""] === "Erfc",
    s = Lookup[a, "SourceSign", 0] provedSign[a["TargetScale"], ass];
    If[! MemberQ[{-1, 1}, s], Return[failure["UnprovedChartSign", "The Erfc orientation was not proved."]]];
    b = If[a["SourceSign"] === 1, a["TargetOffset"], a["TargetOffset"] + 2 a["TargetScale"]];
    Return[<|"Variable" -> y, "Point" -> b, "Direction" -> If[s > 0, "FromAbove", "FromBelow"]|>]];
  If[Lookup[a, "Adapter", ""] === "QuadraticThreshold",
    If[! MatchQ[Lookup[a, "Variables", {}], {_Symbol, _Symbol}], Return[failure["InvalidOperand", "Missing source variable."]]];
    x = First[a["Variables"]]; c = Coefficient[Expand[a["Function"]], x, 2];
    Return[monomialApproach[y, a["ThresholdTarget"], c, 2, ass]]];
  failure["UnsupportedChart", "This helper is intentionally restricted to the three chart families reviewed in F01."]];
ExpectedTargetApproach[___] := failure["InvalidArguments", "Use ExpectedTargetApproach[series]."];

AttachExpectedApproach[s : AsymptoticInverse`GeneralizedSeries[a_Association]] := Module[{p = ExpectedTargetApproach[s]},
  If[FailureQ[p], p, AsymptoticInverse`GeneralizedSeries[Join[a, <|"SeriesApproach" -> p,
    "AuditApproachDerivation" -> "Exact target-chart orientation; see audit F01."|>]]]];
AttachExpectedApproach[___] := failure["InvalidArguments", "Use AttachExpectedApproach[series]."];

rationalQ[x_] := IntegerQ[x] || Head[x] === Rational;
TightenCertificate[c_Association] := Module[{i, center, old, bound, lower, mag, result, goal},
  i = Lookup[c, "RootEnclosure", None]; center = Lookup[c, "Center", None];
  old = Lookup[c, "CertifiedErrorBound", None];
  If[! TrueQ[Lookup[c, "Certified", False]] || ! MatchQ[i, {_?rationalQ, _?rationalQ}] ||
      ! rationalQ[center] || ! rationalQ[old] || ! TrueQ[i[[1]] <= i[[2]]] || old < 0,
    Return[failure["InvalidCertificate", "An existing successful exact-rational center/root-enclosure certificate is required."]]];
  bound = Min[old, Max[Abs[i - center]]];
  lower = Max[Lookup[c, "CertifiedErrorLowerBound", 0],
    If[i[[1]] <= center <= i[[2]], 0, Min[Abs[i - center]]]];
  If[lower > bound, Return[failure["InconsistentCertificate", "The retained proofs have inconsistent center-error bounds."]]];
  result = Join[c, <|"CertifiedErrorBound" -> bound, "CertifiedErrorLowerBound" -> lower,
    "AuditBoundTightening" -> <|"PreviousUpperBound" -> old,
      "Reason" -> "Every certified root lies in the retained RootEnclosure."|>|>];
  mag = Lookup[c, "ProvedRootMagnitudeLowerBound", 0];
  If[rationalQ[mag] && mag > 0, result = Join[result, <|"CertifiedRelativeErrorBound" -> bound/mag|>]];
  goal = Lookup[c, "SufficientAbsoluteTolerance", None];
  If[goal === Infinity || (rationalQ[goal] && goal >= 0),
    result = Join[result, <|"AccuracyGoalReached" -> TrueQ[bound <= goal]|>]];
  result];
TightenCertificate[___] := failure["InvalidArguments", "Use TightenCertificate[successfulCertificateAssociation]."];

(* A grade {k,p,d} denotes E^k O(u^p (1+Abs[Log[u]])^d).
   Lower sector first, then lower power, then larger logarithmic degree.
   Infinity precision denotes exact zero and contributes no envelope. *)
gradeCombine[None, b_] := b;
gradeCombine[a_, None] := a;
gradeCombine[a_, b_] := Which[
  a[[1]] < b[[1]], a, a[[1]] > b[[1]], b,
  AsymptoticInverse`Private`less[a[[2]], b[[2]]], a,
  AsymptoticInverse`Private`less[b[[2]], a[[2]]], b,
  True, {a[[1]], a[[2]], Max[a[[3]], b[[3]]]}];
grade[k_, pair_] := If[pair[[1]] === Infinity, None, {k, pair[[1]], pair[[2]]}];

multiplyData[a0_, b0_, limit_] := Module[
  {a, b, n, na, nb, ell, ass, aj, bj, ai, bi, jets, term, tail = None,
    pair, data, retainedPairs = 0, omittedPairs = 0},
  {a, b} = AsymptoticInverse`Private`flatOpsAlign[a0, b0];
  {na, nb} = {a["SectorDepth"], b["SectorDepth"]}; n = Min[na, nb];
  ell = a["LogVariable"]; ass = a["Assumptions"]; aj = a["SectorJets"]; bj = b["SectorJets"];
  (* Preserve the baseline's aggregate pair-budget policy in this proposal.
     Changing resource-policy units is a separate existing review item. *)
  If[(na + 1) (nb + 1) > limit,
    AsymptoticInverse`Private`fail["ResourceLimit", "The complete flat-sector pair schedule exceeds MaxTerms."]];
  ai = Select[Range[na + 1], ! AsymptoticInverse`Private`flatOpsExactZeroQ[aj[[#]]] &];
  bi = Select[Range[nb + 1], ! AsymptoticInverse`Private`flatOpsExactZeroQ[bj[[#]]] &];
  jets = Table[AsymptoticInverse`Private`flatOpsZero[ell, ass], {n + 1}];
  Do[
    If[i + j - 2 <= n,
      retainedPairs++;
      term = AsymptoticInverse`Private`pMul[aj[[i]], bj[[j]], ell, ass, limit];
      jets[[i + j - 1]] = AsymptoticInverse`Private`pAdd[jets[[i + j - 1]], term, ell, ass],
      omittedPairs++;
      pair = AsymptoticInverse`Private`flatOpsBoundProduct[
        AsymptoticInverse`Private`flatOpsJetBound[aj[[i]], ell],
        AsymptoticInverse`Private`flatOpsJetBound[bj[[j]], ell]];
      tail = gradeCombine[tail, grade[i + j - 2, pair]]],
    {i, ai}, {j, bi}];
  Do[pair = AsymptoticInverse`Private`flatOpsBoundProduct[a["SectorTail"],
      AsymptoticInverse`Private`flatOpsJetBound[bj[[j]], ell]];
    tail = gradeCombine[tail, grade[na + j, pair]], {j, bi}];
  Do[pair = AsymptoticInverse`Private`flatOpsBoundProduct[b["SectorTail"],
      AsymptoticInverse`Private`flatOpsJetBound[aj[[i]], ell]];
    tail = gradeCombine[tail, grade[nb + i, pair]], {i, ai}];
  pair = AsymptoticInverse`Private`flatOpsBoundProduct[a["SectorTail"], b["SectorTail"]];
  tail = gradeCombine[tail, grade[na + nb + 2, pair]];
  data = Join[a, <|"SectorDepth" -> n, "SectorJets" -> jets,
    (* Weaken to the legacy E^(n+1) tail only AFTER selecting dominance. *)
    "SectorTail" -> If[tail === None, {Infinity, 0}, tail[[{2, 3}]]],
    "InnerCutoff" -> Automatic,
    "DerivativeContract" -> (TrueQ[a["DerivativeContract"]] && TrueQ[b["DerivativeContract"]]),
    "DerivativeProvenance" -> <|"Type" -> "ClosedUnderFlatOperations",
      "Inputs" -> {a["DerivativeProvenance"], b["DerivativeProvenance"]}|>,
    "AuditGradedProduct" -> <|"DominantTailGrade" -> tail,
      "RetainedCoefficientPairs" -> retainedPairs, "EnvelopeOnlyPairs" -> omittedPairs|>|>];
  AsymptoticInverse`Private`flatOpsBudget[data, limit]];

FlatSeriesMultiplyGraded[s_AsymptoticInverse`GeneralizedSeries,
    t_AsymptoticInverse`GeneralizedSeries, OptionsPattern[]] :=
  AsymptoticInverse`Private`catch[Module[{limit = OptionValue["MaxTerms"], d, result},
    d = multiplyData[AsymptoticInverse`Private`flatOpsData[s, limit],
      AsymptoticInverse`Private`flatOpsData[t, limit], limit];
    d = AsymptoticInverse`Private`flatOpsTruncateData[d, OptionValue["InnerCutoff"], limit];
    result = AsymptoticInverse`Private`flatOpsMake[d, {"AuditGradedMultiply", {s, t}}];
    AttachExpectedApproach[result]]];
FlatSeriesMultiplyGraded[___] := failure["InvalidArguments", "This proposal accepts two flat GeneralizedSeries operands."];
End[];
EndPackage[];
