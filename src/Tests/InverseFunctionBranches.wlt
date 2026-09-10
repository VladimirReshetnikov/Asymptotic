If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
If[DownValues[AsymptoticAnalysis`Private`inverseFunctionSelectBranch] === {},
  Begin["AsymptoticAnalysis`Private`"];
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "InverseFunctionBranches.wl"}]];
  End[]];

(* These exercise the branch contract directly, independently of the syntax
   reader and the inverse coefficient engine. All source symbols are local. *)

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x + x^2 (1 + Log[x]), "SourceVariable" -> x, "Condition" -> Im[x] == 0|>,
    0, 1, True, 1000];
  {r["SourcePoint"], r["Direction"], r["InferenceComplete"],
   TrueQ[FullSimplify[Equivalent[r["SourceDomain"], x > 0], Element[x, Reals]]]}],
 {0, "FromAbove", True, True}, TestID -> "inverse-branch-original-real-logarithmic-question"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x + x^Sqrt[2], "SourceVariable" -> x, "Condition" -> x >= 0|>,
    0, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction", "ConditionalDomainVerified", "LimitVerified"}]],
 {0, "FromAbove", True, True}, TestID -> "inverse-branch-original-irrational-real-question"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> x >= 0|>, 0, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromAbove"}, TestID -> "inverse-branch-square-nonnegative-condition"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> x <= 0|>, 0, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromBelow"}, TestID -> "inverse-branch-square-nonpositive-condition"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000];
  {r[[1]], Sort[Lookup[r[[2]]["Candidates"], "Direction"]]}],
 {"AmbiguousInverseFunctionBranch", {"FromAbove", "FromBelow"}},
 TestID -> "inverse-branch-even-critical-point-has-two-germs"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x - x^3, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000];
  {r[[1]], Sort[Lookup[r[[2]]["Candidates"], "SourcePoint"]]}],
 {"AmbiguousInverseFunctionBranch", {-1, 0, 1}},
 TestID -> "inverse-branch-all-finite-fiber-roots-are-considered"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> x > 0|>, 0, -1, True, 1000];
  {r[[1]], Sort[Lookup[r[[2]]["Candidates"], "SourcePoint"]]}],
 {"AmbiguousInverseFunctionBranch", {0, 1}},
 TestID -> "inverse-branch-logarithmic-boundary-competes-with-interior-root"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> 0 < x < 1/E|>, 0, -1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromAbove"}, TestID -> "inverse-branch-lambert-lower-real-domain"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> x > 1/E|>, 0, -1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {1, "FromBelow"}, TestID -> "inverse-branch-lambert-principal-real-domain"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> 3 + (x - 2)^3, "SourceVariable" -> x, "Condition" -> x < 2|>, 3, -1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {2, "FromBelow"}, TestID -> "inverse-branch-translated-odd-critical-endpoint"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2 + 1, "SourceVariable" -> x, "Condition" -> x > 0|>, 1, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromAbove"}, TestID -> "inverse-branch-excluded-boundary-can-support-a-germ"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2 + 1, "SourceVariable" -> x, "Condition" -> x > 0|>, 1, -1, True, 1000];
  r[[1]]],
 "NoInverseFunctionBranch", TestID -> "inverse-branch-impossible-target-side-is-rejected"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> x > 0|>, 4, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {2, "FromAbove"}, TestID -> "inverse-branch-interior-endpoint-not-assumed-zero"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x + x^2, "SourceVariable" -> x, "Condition" -> x > 0|>, Infinity, 0, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {Infinity, "FromBelow"}, TestID -> "inverse-branch-positive-infinite-source"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> Exp[-x], "SourceVariable" -> x, "Condition" -> x > 0|>, 0, 1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {Infinity, "FromBelow"}, TestID -> "inverse-branch-finite-target-at-infinite-source"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> Log[x], "SourceVariable" -> x, "Condition" -> x > 0|>, -Infinity, 0, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromAbove"}, TestID -> "inverse-branch-negative-infinite-target"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x, "SourceVariable" -> x, "Condition" -> True|>, -Infinity, 0, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {-Infinity, "FromAbove"}, TestID -> "inverse-branch-negative-infinite-source-direction"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> x < -1 || x > 1|>, 4, 1, True, 1000];
  {r[[1]], Sort[Lookup[r[[2]]["Candidates"], "SourcePoint"]]}],
 {"AmbiguousInverseFunctionBranch", {-2, 2}},
 TestID -> "inverse-branch-disconnected-domain-does-not-imply-uniqueness"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> x == 0|>, 0, 1, True, 1000];
  r[[1]]],
 "NoInverseFunctionBranch", TestID -> "inverse-branch-isolated-domain-point-is-not-a-germ"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> x > 0|>, 0, -1, True, 1000,
    <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
  Lookup[r, {"SourcePoint", "Direction", "SelectionMethod"}]],
 {0, "FromAbove", "ExplicitEndpointAndValidatedLocalBranch"},
 TestID -> "inverse-branch-explicit-lower-lambert-selection"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> x > 0|>, 0, -1, True, 1000,
    <|"SourcePoint" -> 1, "Direction" -> "FromBelow"|>];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {1, "FromBelow"}, TestID -> "inverse-branch-explicit-interior-lambert-selection"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x Log[x], "SourceVariable" -> x, "Condition" -> x > 0|>, 0, -1, True, 1000,
    <|"SourcePoint" -> 0, "Direction" -> "FromBelow"|>];
  r[[1]]],
 "NoInverseFunctionBranch", TestID -> "inverse-branch-explicit-selection-still-checks-principal-real-domain"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000,
    <|"SourcePoint" -> 2, "Direction" -> "FromAbove"|>];
  r[[1]]],
 "NoInverseFunctionBranch", TestID -> "inverse-branch-explicit-selection-still-checks-target-limit"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^3, "SourceVariable" -> x, "Condition" -> True|>, 0, -1, True, 1000];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromBelow"}, TestID -> "inverse-branch-odd-ramification-uses-target-side"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000,
    <|"SourcePoint" -> 0, "Direction" -> -1|>];
  Lookup[r, {"SourcePoint", "Direction"}]],
 {0, "FromAbove"}, TestID -> "inverse-branch-numeric-direction-convention"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x, "SourceVariable" -> x, "Condition" -> Sin[1/x] > 0|>, 0, 1, True, 1000,
    <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
  FailureQ[r]],
 True, TestID -> "inverse-branch-oscillatory-condition-has-no-deleted-neighborhood-contract"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 3];
  r[[1]]],
 "ResourceLimit", TestID -> "inverse-branch-candidate-resource-limit-is-explicit"]

VerificationTest[
 Module[{x, f, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> f[x], "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000];
  r[[1]]],
 "UnsupportedInverseFunctionBody", TestID -> "inverse-branch-opaque-function-is-not-assumed-continuous"]

VerificationTest[
 Module[{x, r},
  r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> ArcCot[x - 2], "SourceVariable" -> x, "Condition" -> True|>, Pi/2, -1, True, 1000];
  r[[1]]],
 "UnsupportedInverseFunctionBody", TestID -> "inverse-branch-discontinuous-principal-function-needs-an-adapter"]

VerificationTest[
 Module[{x, r},
  (* Synthetic solver-interface regression: a potentially competing branch
     whose validation is unresolved must not disappear from completeness. *)
  Block[{AsymptoticAnalysis`Private`inverseBranchValidate,
    AsymptoticAnalysis`Private`inverseBranchGlobalMonotonicity},
   AsymptoticAnalysis`Private`inverseBranchValidate[_, _, _, p_, d_, ___] :=
    Which[p === 0 && d === "FromAbove", <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>,
      p === 0 && d === "FromBelow", None, True, False];
   AsymptoticAnalysis`Private`inverseBranchGlobalMonotonicity[___] := None;
   r = AsymptoticAnalysis`Private`inverseFunctionSelectBranch[
    <|"Body" -> x^2, "SourceVariable" -> x, "Condition" -> True|>, 0, 1, True, 1000];
   {r[[1]], r[[2]]["UnresolvedCandidates"]}]],
 {"IncompleteInverseBranchInference", {{0, "FromBelow"}}},
 TestID -> "inverse-branch-unresolved-competing-germ-blocks-uniqueness"]

VerificationTest[
 Module[{t, y, z, input, operator, selection, r},
  operator = InverseFunction[Function[t, t^2 + t^4 (1 + Log[t^2])]];
  selection = Association[operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
  input = AsymptoticExpansion[y^2 + y^4, {y, 0, 4}];
  r = SeriesObservable[input, operator[z], z, "Cutoff" -> 5,
    "InverseFunctionBranches" -> selection];
  (* Writing q=t^2 gives q+q^2(1+Log[q])=z. Thus t=sqrt[z]
     -z^(3/2)(1+Log[z])/2+..., whereas uncertainty O(y^4) in
     z=y^2+O(y^4) propagates through t'(z)~1/(2y) as O(y^3).
     Dropping the whole boundary block also includes its known Log[y]. *)
  {TrueQ[FullSimplify[Normal[r] == y, y > 0]],
    r["RemainderPower"], r["RemainderLogDegree"]}],
 {True, 3, 1}, TestID -> "inverse-branch-critical-composition-transports-input-error-through-singular-derivative"]

VerificationTest[
 Module[{t, y, operator, selection, r},
  operator = InverseFunction[Function[t, t^2 + t^4 (1 + Log[t^2])]];
  selection = Association[operator -> <|"SourcePoint" -> 0, "Direction" -> "FromAbove"|>];
  r = AsymptoticExpansion[operator[y^2], {y, 0, 4}, Direction -> "FromBelow",
    "InverseFunctionBranches" -> selection];
  TrueQ[FullSimplify[Normal[r] == -y + y^3 (1 + 2 Log[-y])/2, y < 0]]],
 True, TestID -> "inverse-branch-outer-positive-square-root-of-left-approaching-target"]

VerificationTest[
 Module[{y, r, l},
  r = AsymptoticExpansion[InverseFunction[ConditionalExpression[
      # + #^2 (1 + Log[#]), # > 0] &][InverseFunction[ConditionalExpression[
      -# - #^2 (1 + Log[#]), # > 0] &][y]], {y, 0, 4}, Direction -> "FromBelow"];
  l = Log[-y];
  TrueQ[FullSimplify[Normal[r] == -y - 2 y^2 (1 + l) - y^3 (6 l^2 + 15 l + 9), y < 0]]],
 True, TestID -> "inverse-branch-nested-left-target-has-separate-intermediate-approach"]

VerificationTest[
 Module[{t, y, r},
  r = Quiet[AsymptoticExpansion[InverseFunction[Function[t,
    ConditionalExpression[t^2, t >= 0]]][0], {y, 0, 3}]];
  {Normal[r], r["Remainder"]}],
 {0, 0}, TestID -> "inverse-branch-native-exact-constant-value-at-admissible-endpoint"]

VerificationTest[
 Module[{y, r},
  r = AsymptoticExpansion[InverseFunction[ConditionalExpression[
    # + #^2 (1 + Log[#]), # > 0] &][0], {y, 0, 3}];
  FailureQ[r]],
 True, TestID -> "inverse-branch-constant-target-does-not-invent-continuous-endpoint-extension"]

VerificationTest[
 Module[{y, r, refined},
  r = AsymptoticExpansion[ConditionalExpression[
    InverseFunction[# + #^2 (1 + Log[#]) &][y], 0 < y < 1], {y, 0, 3}];
  refined = SeriesRefine[r, 4];
  {TrueQ[r["TargetDomain"] /. y -> 1/2],
   TrueQ[(refined["TargetDomain"] /. y -> 2) === False]}],
 {True, True}, TestID -> "inverse-branch-refinement-retains-outer-conditional-target-domain"]

VerificationTest[
 Module[{x, y, r, refined},
  r = AsymptoticInverse[ConditionalExpression[x + x^2, 0 < x < 1],
    {x, 0}, {y, 3}, Method -> "GroupedLagrange"];
  refined = SeriesRefine[r, 4];
  {TrueQ[r["SourceDomain"] /. x -> 1/2],
   TrueQ[(refined["SourceDomain"] /. x -> 2) === False]}],
 {True, True}, TestID -> "inverse-branch-source-condition-survives-nonincremental-refinement-replay"]
