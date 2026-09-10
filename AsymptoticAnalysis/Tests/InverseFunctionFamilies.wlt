If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
If[DownValues[AsymptoticAnalysis`Private`inverseFunctionSeparateFamily] === {},
  Block[{$Context = "AsymptoticAnalysis`Private`", $ContextPath = {"AsymptoticAnalysis`", "System`"}},
    Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "InverseFunctionFamilies.wl"}]]]];

inverseFamilyFixture[body_, t_, target_, params_, condition_: True, positions_: Automatic] :=
  <|"Body" -> body, "SourceVariable" -> t, "TargetExpression" -> target,
    "Parameters" -> params, "Condition" -> condition,
    "ParameterPositions" -> If[positions === Automatic, Range[Length[params]], positions],
    "OriginalExpression" -> HoldComplete["family fixture application"],
    "OriginalOperator" -> HoldComplete["family fixture operator"]|>;
inverseFamilyReduce[d_, x_, ass_: True, limit_: 20000] := AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`inverseFunctionSeparateFamily[d, x, ass, limit]];
inverseFamilyEqual[s_, expected_, ass_] := MatchQ[s, _GeneralizedSeries] &&
  TrueQ[FullSimplify[Normal[s] == expected, ass]];
inverseFamilyH[t_] := t + t^2 (1 + Log[t]);
inverseFamilyOracle[y_] := y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3);

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[y + inverseFamilyH[t], t, 2 y, {y}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - inverseFamilyH[t]], r["TargetExpression"], r["Amplitude"],
    r["Parameters"], r["ExactFamilyReduction"]["Offset"]} /. y -> \[FormalY]],
  {0, \[FormalY], 1, {}, \[FormalY]}, TestID -> "inverse-family-exact-varying-output-translation"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[(1 + y) inverseFamilyH[t], t, y, {1 + y}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - inverseFamilyH[t]],
    TrueQ[FullSimplify[r["TargetExpression"] == y/(1 + y)]], r["Amplitude"] === 1 + y,
    r["ExactFamilyReduction"]["IdentityVerified"]}],
  {0, True, True, True}, TestID -> "inverse-family-recombines-expanded-amplitude-coefficients"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[(1 + y) inverseFamilyH[t] + y, t, 2 y, {y, 1 + y}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - inverseFamilyH[t]],
    TrueQ[FullSimplify[r["TargetExpression"] == y/(1 + y)]], r["Parameters"]}],
  {0, True, {}}, TestID -> "inverse-family-combines-varying-output-amplitude-and-offset"]

VerificationTest[Module[{t, y, a, b, d, r},
  d = inverseFamilyFixture[(1 + y) (a t + b t^2) + y^2, t, y,
    {y, a, y^2}, t > 0, {1, 3, 4}]; r = inverseFamilyReduce[d, y, Element[{a, b}, Reals]];
  {Expand[r["Body"] - (a t + b t^2)], r["Amplitude"] === 1 + y,
    r["Parameters"] === {a}, r["ParameterPositions"],
    r["ExactFamilyReduction"]["RemovedParameterPositions"], r["Condition"] === (t > 0)}],
  {0, True, True, {3}, {1, 4}, True}, TestID -> "inverse-family-keeps-fixed-parameters-without-spurious-nonzero-assumption"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[Exp[y] + inverseFamilyH[t], t, Exp[y] + y, {Exp[y]}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - inverseFamilyH[t]], r["TargetExpression"] === y, r["Amplitude"]}],
  {0, True, 1}, TestID -> "inverse-family-allows-exact-nonpolynomial-output-translation"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[Exp[y] (t + t^Sqrt[2]), t, y, {Exp[y]}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - (t + t^Sqrt[2])], r["Amplitude"] === Exp[y],
    TrueQ[FullSimplify[r["TargetExpression"] == y Exp[-y]]]}],
  {0, True, True}, TestID -> "inverse-family-retains-exact-irrational-source-powers"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[y inverseFamilyH[t], t, y^2, {y}]; r = inverseFamilyReduce[d, y];
  {Expand[r["Body"] - inverseFamilyH[t]], r["TargetExpression"] === y,
    r["Amplitude"] === y,
    r["ExactFamilyReduction"]["RequiredCondition"] === (y != 0)}],
  {0, True, True, True}, TestID -> "inverse-family-records-nonzero-obligation-for-endpoint-vanishing-amplitude"]

VerificationTest[Module[{t, y, d, r},
  d = inverseFamilyFixture[(1 + y) inverseFamilyH[t] + y, t, 2 y, {y}]; r = inverseFamilyReduce[d, y];
  {r["OriginalExpression"] === d["OriginalExpression"], r["OriginalOperator"] === d["OriginalOperator"],
    r["ExactFamilyReduction"]["OriginalBody"] === d["Body"],
    r["ExactFamilyReduction"]["OriginalParameters"] === {y},
    r["ExactFamilyReduction"]["OriginalTargetExpression"] === 2 y}],
  {True, True, True, True, True}, TestID -> "inverse-family-preserves-exact-original-provenance"]

VerificationTest[Module[{t, y},
  inverseFamilyReduce[inverseFamilyFixture[t + y t^2, t, y, {y}], y]],
  $Failed, TestID -> "inverse-family-rejects-genuinely-varying-relative-coefficients"]

VerificationTest[Module[{t, y},
  inverseFamilyReduce[inverseFamilyFixture[t + t^(1 + y), t, y, {y}], y]],
  $Failed, TestID -> "inverse-family-rejects-coupled-source-exponents"]

VerificationTest[Module[{t, y},
  inverseFamilyReduce[inverseFamilyFixture[t + Log[t + y], t, y, {y}], y]],
  $Failed, TestID -> "inverse-family-rejects-coupled-logarithm-argument"]

VerificationTest[Module[{t, y},
  inverseFamilyReduce[inverseFamilyFixture[y + inverseFamilyH[t], t, 2 y, {y}, t > y], y]],
  $Failed, TestID -> "inverse-family-does-not-freeze-varying-source-domain"]

VerificationTest[Module[{t, y, a},
  inverseFamilyReduce[inverseFamilyFixture[a + inverseFamilyH[t], t, y, {a}], y]],
  $Failed, TestID -> "inverse-family-leaves-fixed-parameter-input-to-ordinary-route"]

VerificationTest[Module[{t, y}, MatchQ[inverseFamilyReduce[
  inverseFamilyFixture[(1 + y)^100 t, t, y, {y}], y, True, 40], Failure["ResourceLimit", _Association]]],
  True, TestID -> "inverse-family-bounds-polynomial-distribution-before-expansion"]

VerificationTest[MatchQ[AsymptoticAnalysis`Private`catch[
  AsymptoticAnalysis`Private`inverseFunctionSeparateFamily[]], Failure["InvalidArguments", _Association]],
  True, TestID -> "inverse-family-malformed-helper-call-fails-descriptively"]

(* Independent end-to-end oracles.  The source inverse is the logarithmic
   polynomial above.  For target q=y/(1+y), directly substituting
   q=y-y^2+y^3+O(y^4) and Log[q]=Log[y]-y+y^2/2+O(y^3) gives
   g(q)=y-(2+Log[y])y^2+(2Log[y]^2+7Log[y]+7)y^3+O(y^4 Log[y]^3). *)
VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[#1 + #2 + #2^2 (1 + Log[#2]) &, 2, 2][y, 2 y], {y, 0, 4}];
  inverseFamilyEqual[s, inverseFamilyOracle[y], y > 0]],
  True, TestID -> "inverse-family-public-varying-offset-exactly-reduces-target"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[#1 (#2 + #2^2 (1 + Log[#2])) &, 2, 2][1 + y, y], {y, 0, 4}];
  inverseFamilyEqual[s, y - y^2 (2 + Log[y]) + y^3 (2 Log[y]^2 + 7 Log[y] + 7), y > 0]],
  True, TestID -> "inverse-family-public-varying-amplitude-composition-oracle"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[
    #1 + #2 (#3 + #3^2 (1 + Log[#3])) &, 3, 3][y, 1 + y, 2 y], {y, 0, 4}];
  inverseFamilyEqual[s, y - y^2 (2 + Log[y]) + y^3 (2 Log[y]^2 + 7 Log[y] + 7), y > 0]],
  True, TestID -> "inverse-family-public-varying-amplitude-and-offset"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[#1 (#2 + #2^2 (1 + Log[#2])) &, 2, 2][y, y^2], {y, 0, 4}];
  inverseFamilyEqual[s, inverseFamilyOracle[y], y > 0]],
  True, TestID -> "inverse-family-public-amplitude-may-vanish-at-endpoint"]

VerificationTest[Module[{y, s},
  s = AsymptoticExpansion[InverseFunction[#1 (#2 + #2^2 (1 + Log[#2])) &, 2, 2][-1 - y, -y], {y, 0, 4}];
  inverseFamilyEqual[s, y - y^2 (2 + Log[y]) + y^3 (2 Log[y]^2 + 7 Log[y] + 7), y > 0]],
  True, TestID -> "inverse-family-public-negative-amplitude-preserves-real-equation"]

VerificationTest[Module[{y}, FailureQ[AsymptoticExpansion[InverseFunction[
    #2 + #2^2 (1 + Log[#2]) + #1 #2^3 &, 2, 2][y, y], {y, 0, 3}]]],
  True, TestID -> "inverse-family-public-nonseparable-coupling-remains-explicit-failure"]
