(* Desired-contract tests. NOT EXECUTED in the audit session.
   Load the pinned package in a fresh native Wolfram kernel before TestReport.
   New code: MIT-0. These tests target N01/N02; they are not the upstream suite. *)

VerificationTest[
 Module[{a, u, ell},
  AsymptoticAnalysis`Private`parseFinite[
   u + u^2 Log[u^a]^2, u, ell, a^2 == -1]],
 $Failed, TestID -> "N01-reject-unproved-real-log-exponent"]

VerificationTest[
 Module[{a, u, ell},
  ListQ[AsymptoticAnalysis`Private`parseFinite[
    u + u^2 Log[u^a]^2, u, ell, a > 0]]],
 True, TestID -> "N01-positive-real-exponent-control"]

VerificationTest[
 Module[{a, u, ell},
  AsymptoticAnalysis`Private`parseFinite[
   u + u^2 Log[2 u^a]^2, u, ell, a^2 == -1]],
 $Failed, TestID -> "N01-scaled-power-rewrite-also-guarded"]

VerificationTest[
 {Log[Exp[-2 Pi I]]^2, (-2 Pi I)^2},
 {0, -4 Pi^2}, TestID -> "N01-exact-principal-branch-oracle"]

VerificationTest[
 Module[{saved = Options[AsymptoticAnalysis`AsymptoticExpansion], x, result},
  Internal`WithLocalSettings[
   SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"],
   result = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
   result["NativeBackend"],
   Options[AsymptoticAnalysis`AsymptoticExpansion] = saved]],
 "Series", TestID -> "N02-SetOptions-backend-default-is-consumed"]

VerificationTest[
 Module[{saved = Options[AsymptoticAnalysis`AsymptoticExpansion], x, result},
  Internal`WithLocalSettings[
   SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"],
   result = AsymptoticAnalysis`AsymptoticExpansion[
     Exp[x], {x, 0, 3}, "Backend" -> "Package"];
   result["Kind"],
   Options[AsymptoticAnalysis`AsymptoticExpansion] = saved]],
 "Forward", TestID -> "N02-explicit-selector-overrides-default"]

VerificationTest[
 Module[{saved = Options[AsymptoticAnalysis`AsymptoticExpansion], calls = 0, x, result},
  Internal`WithLocalSettings[
   SetOptions[AsymptoticAnalysis`AsymptoticExpansion,
    "Backend" :> (calls++; "Series")],
   result = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
   {result["NativeBackend"], calls},
   Options[AsymptoticAnalysis`AsymptoticExpansion] = saved]],
 {"Series", 1}, TestID -> "N02-delayed-default-evaluated-once"]

VerificationTest[
 Module[{saved = Options[AsymptoticAnalysis`AsymptoticExpansion], x, result},
  Internal`WithLocalSettings[
   SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"],
   result = AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x, 0, 3}];
   result["NativeBackend"],
   Options[AsymptoticAnalysis`AsymptoticExpansion] = saved]],
 "Series", TestID -> "N02-alias-consumes-canonical-default"]

VerificationTest[
 Module[{x},
  AsymptoticAnalysis`AsymptoticExpansion[
   Exp[x], {x, 0, 3}, "Backend" -> "Series"]["NativeBackend"]],
 "Series", TestID -> "N02-explicit-native-backend-control"]
