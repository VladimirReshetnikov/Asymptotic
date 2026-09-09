(* Applies the four local changes in a temporary copy and checks five controls.
   Does NOT repair ambient assumptions or execute the upstream suite.
   This script encodes the same replacements as harden_source.py.
   Run: wolframscript -file code/native_patch_check.wl *)
$AuditCallerPath = ExpandFileName[$InputFileName];
Get[FileNameJoin[{DirectoryName[$AuditCallerPath], "load_pinned.wl"}]];
$PatchLoad = AuditLoad[];
If[FailureQ[$PatchLoad], Print[InputForm[$PatchLoad]]; Exit[1]];
$PatchSource = Import[$PatchLoad["SourcePath"], "Text"];
$PatchRules = {
"  If[T === {},\n   If[less[0, rr], Return[{{}," -> "  If[T === {},\n   If[P =!= Infinity && ! IntegerQ[rr],\n    fail[\"UnknownLeadingTerm\", \"A pure remainder does not prove the real branch of a noninteger power; refine or supply a proved sign contract.\"]];\n   If[less[0, rr], Return[{{},",
"  coeffs = Table[0, {nmax - nmin}];" -> "  If[nmax - nmin > 100000, Return[Missing[\"DenseRepresentationLimit\",\n    <|\"RequiredCoefficients\" -> nmax - nmin, \"MaximumCoefficients\" -> 100000|>], Module]];\n  coeffs = Table[0, {nmax - nmin}];",
"jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},\n  If[u === {}, Return[{}, Module]];\n  If[cut === Infinity, fail[\"InfiniteSeries\", \"An infinite series is required; a finite working order is needed.\"]];\n  If[! less[0, jetValuation[u]], fail[\"NonSmallJet\", \"Unit-series arithmetic requires positive valuation.\"]];\n  While[True,\n   k++;\n   pw = jetMul[pw, u, cut, ell, ass, limit];\n   If[pw === {}, Break[]];\n   c = cf[k];\n   If[c === Null, Break[]];\n   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]]];\n  ans];" -> "jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},\n  If[u === {}, Return[{}, Module]];\n  If[cut === Infinity, fail[\"InfiniteSeries\", \"An infinite series is required; a finite working order is needed.\"]];\n  If[! less[0, jetValuation[u]], fail[\"NonSmallJet\", \"Unit-series arithmetic requires positive valuation.\"]];\n  While[True,\n   k++;\n   pw = jetMul[pw, u, cut, ell, ass, limit];\n   If[pw === {}, Break[]];\n   c = cf[k];\n   If[c === Null, Break[]];\n   If[k > limit, fail[\"ResourceLimit\", \"Unit-series depth exceeds MaxTerms.\"]];\n   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]];\n   If[Length[ans] > limit, fail[\"ResourceLimit\", \"Unit-series output support exceeds MaxTerms.\"]]];\n  ans];",
"jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},\n  ans = jetMerge[{{0, P}}, ell, ass];\n  If[u === {}, Return[ans, Module]];\n  If[cut === Infinity, fail[\"InfiniteSeries\", \"An infinite series is required; a finite working order is needed.\"]];\n  If[! less[0, jetValuation[u]], fail[\"NonSmallJet\", \"Unit-series arithmetic requires positive valuation.\"]];\n  While[True,\n   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];\n   k++;\n   pw = jetMul[pw, u, cut, ell, ass, limit];\n   If[pw === {}, Break[]];\n   If[polyZeroQ[Q, ell, ass], Continue[]];\n   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass]];\n  ans];" -> "jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},\n  ans = jetMerge[{{0, P}}, ell, ass];\n  If[u === {}, Return[ans, Module]];\n  If[cut === Infinity, fail[\"InfiniteSeries\", \"An infinite series is required; a finite working order is needed.\"]];\n  If[! less[0, jetValuation[u]], fail[\"NonSmallJet\", \"Unit-series arithmetic requires positive valuation.\"]];\n  While[True,\n   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];\n   k++;\n   (* The recurrence is linear: zero stays zero at every later step. *)\n   If[polyZeroQ[Q, ell, ass], Break[]];\n   pw = jetMul[pw, u, cut, ell, ass, limit];\n   If[pw === {}, Break[]];\n   If[k > limit, fail[\"ResourceLimit\", \"Unit composition depth exceeds MaxTerms.\"]];\n   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass];\n   If[Length[ans] > limit, fail[\"ResourceLimit\", \"Unit composition output support exceeds MaxTerms.\"]]];\n  ans];"
};
$PatchCounts = StringCount[$PatchSource, First[#]] & /@ $PatchRules;
If[$PatchCounts =!= {1, 2, 1, 1}, Print[InputForm[Failure["SourceAnchors",
  <|"Expected" -> {1, 2, 1, 1}, "Observed" -> $PatchCounts|>]]]; Exit[1]];
$PatchCandidate = StringReplace[$PatchSource, $PatchRules];
$PatchTemporary = CreateTemporary[];
Export[$PatchTemporary, $PatchCandidate, "Text"];
$PatchHash = IntegerString[FileHash[$PatchTemporary, "SHA256"], 16, 64];
Get[$PatchTemporary];
Clear[x, y, z, ell];
$PatchCheck = TimeConstrained[MemoryConstrained[Module[{s, p, b, d, i, c, checks},
  s = AsymptoticInverse`AsymptoticExpansion[-x^4, {x,0,1}];
  p = AsymptoticInverse`SeriesObservable[s, 1+Sqrt[z], z];
  b = AsymptoticInverse`AsymptoticExpansion[Exp[x^(1/50)], {x,0,1}, "MaxTerms"->10];
  d = AsymptoticInverse`AsymptoticExpansion[x+x^(1+1/1000000)+x^2,
    {x,0,3/2}, "MaxTerms"->10];
  i = AsymptoticInverse`AsymptoticInverse[x+x^2, {x,0}, {y,6}];
  c = AsymptoticInverse`Private`jetComposeBlock[{{1/1000000,1}},0,1,1,ell,True,10];
  checks = <|"WrappedPower" -> MatchQ[p, Failure["UnknownLeadingTerm",_Association]],
    "LoopBudget" -> MatchQ[b, Failure["ResourceLimit",_Association]],
    "DenseCache" -> (MatchQ[d,_AsymptoticInverse`GeneralizedSeries] &&
      MatchQ[d["SeriesData"],Missing["DenseRepresentationLimit",_Association]] &&
      Normal[d] === x+x^(1000001/1000000)),
    "PolynomialControl" -> (Normal[i] === y-y^2+2 y^3-5 y^4+14 y^5),
    "AnnihilatedComposition" -> (c === {{0,1}})|>;
  <|"Checks"->checks,"AllPassed"->And@@Values[checks],
    "Results"-><|"WrappedPower"->p,"LoopBudget"->b,
      "DenseCache"->d["SeriesData"],"DenseExpression"->Normal[d],
      "PolynomialControl"->Normal[i],"AnnihilatedComposition"->c|>|>
], 268435456, Failure["AuditMemoryLimit",<||>]],
  30, Failure["AuditTimeout",<||>]];
Print[InputForm[<|"Environment"->$PatchLoad,"AnchorCounts"->$PatchCounts,
  "CandidateSHA256"->$PatchHash,"Observed"->$PatchCheck|>]];
DeleteFile[$PatchTemporary];
If[! AssociationQ[$PatchCheck] || ! TrueQ[$PatchCheck["AllPassed"]], Exit[1]];
