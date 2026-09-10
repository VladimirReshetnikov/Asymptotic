(* Desired-contract specifications, NOT a recorded passing acceptance suite.
   Load the package before evaluating this file. Baseline failures are expected.
   The supplied two-fix candidate does not address unknown options, eager Normal,
   or sentinel status. Each test has a deliberately separate contract. *)

VerificationTest[
 Module[{old = Options[AsymptoticAnalysis`AsymptoticExpansion], r, answer},
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
  answer = {r["Kind"], r["NativeBackend"], Normal[r]};
  Options[AsymptoticAnalysis`AsymptoticExpansion] = old; answer],
 {"Native", "Series", 1 + x + x^2/2 + x^3/6}, TestID -> "N01-default-Series"]

VerificationTest[
 Module[{old = Options[AsymptoticAnalysis`AsymptoticExpansion], r, answer},
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Package"];
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}];
  answer = FailureQ[r]; Options[AsymptoticAnalysis`AsymptoticExpansion] = old; answer],
 True, TestID -> "N01-default-Package-preserves-strict-policy"]

VerificationTest[
 Module[{old = Options[AsymptoticAnalysis`AsymptoticExpansion], r, answer},
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Package"];
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}, "Backend" -> "Series"];
  answer = r["NativeBackend"];
  Options[AsymptoticAnalysis`AsymptoticExpansion] = old; answer],
 "Series", TestID -> "control-explicit-overrides-default"]

VerificationTest[
 Module[{key = "Backend", r},
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> "Series"];
  If[FailureQ[r], r[[1]], r["NativeBackend"]]],
 "Series", TestID -> "N02-computed-selector-key"]

VerificationTest[
 Module[{key = Analytic, r},
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> False, "Backend" -> "Series"];
  {r["Variable"], r[1]}],
 {x, 8/3}, TestID -> "N02-alias-does-not-create-a-variable"]

VerificationTest[
 Module[{key = "Backend", count = 0, r},
  r = AsymptoticAnalysis`AsymptoticExpansion[(count++; Exp[x]), {x, 0, 3}, key -> "Series"];
  {If[FailureQ[r], r[[1]], r["NativeBackend"]], count}],
 {"Series", 1}, TestID -> "N02-held-source-single-evaluation"]

VerificationTest[
 Module[{count = 0, r},
  r = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3},
    "Backend" :> (count++; "Series")]; {r["NativeBackend"], count}],
 {"Series", 1}, TestID -> "control-delayed-selector-single-evaluation"]

VerificationTest[
 FailureQ[Quiet[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3},
   unknownOption -> 7, "Backend" -> "Package"]]],
 True, TestID -> "N03-unknown-symbol-option-rejected"]

VerificationTest[
 Module[{r = AsymptoticAnalysis`AsymptoticExpansion[$Failed, {x, 0, 3}, "Backend" -> "Series"]},
  r["NativeEvaluationStatus"] =!= "Computed"],
 True, TestID -> "N05-failed-sentinel-not-computed"]

VerificationTest[
 Module[{r = AsymptoticAnalysis`AsymptoticExpansion[Failure["SourceFailed", <||>],
   {x, 0, 3}, "Backend" -> "Series"]}, r["NativeEvaluationStatus"] =!= "Computed"],
 True, TestID -> "N05-Failure-not-computed"]

VerificationTest[
 Module[{input = SparseArray[{1 -> Exp[x]}, 100000], native, r},
  native = Series[input, {x, 0, 3}];
  r = AsymptoticAnalysis`AsymptoticExpansion[input, {x, 0, 3}, "Backend" -> "Series"];
  {SameQ[native, r["NativeResult"]], ByteCount[r] < 50 ByteCount[native] + 100000}],
 {True, True}, TestID -> "N04-native-storage-does-not-densify"]

VerificationTest[
 Normal[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"]],
 1 + x + x^2/2 + x^3/6, TestID -> "control-native-inclusive-order"]

VerificationTest[
 Normal[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"]],
 1 + x + x^2/2, TestID -> "control-package-exclusive-order"]

VerificationTest[
 Module[{r = AsymptoticAnalysis`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, {y, 2}]},
  {Normal[r], r["Remainder"]}],
 {y - y^Sqrt[2] + Sqrt[2] y^(-1 + 2 Sqrt[2]),
  AsymptoticAnalysis`PowerLogRemainder[y, -2 + 3 Sqrt[2], 0]},
 TestID -> "control-irrational-inverse"]
