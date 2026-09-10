(* Desired contracts. Several tests should fail on the pinned baseline.
   The complete file was not run as a suite during this audit. *)
ClearAll[withDefaults, x, y, z];
SetAttributes[withDefaults, HoldRest];
withDefaults[symbol_Symbol, rules_List, body_] := Module[{saved = Options[symbol], r},
  CheckAbort[SetOptions[symbol, Sequence @@ rules]; r = body;
    Options[symbol] = saved; r, Options[symbol] = saved; Abort[]]];
VerificationTest[
 withDefaults[AsymptoticAnalysis`AsymptoticExpansion, {"Backend" -> "Series"},
  Normal[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x,0,3}]]],
 1+x+x^2/2+x^3/6, TestID -> "N01-main-default"]
VerificationTest[
 withDefaults[AsymptoticAnalysis`AsymptoticExpansion, {"Backend" -> "Package"},
  FailureQ[AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x,0,3}]]],
 True, TestID -> "N01-package-default"]
VerificationTest[Module[{n=0},
 withDefaults[AsymptoticAnalysis`AsymptoticExpansion, {"Backend" :> (n++; "Series")},
  AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x,0,3}]; n]],
 1, TestID -> "N01-delayed-default-once"]
VerificationTest[Module[{n=0},
 withDefaults[AsymptoticAnalysis`AsymptoticExpansion, {"Backend" :> (n++; "Series")},
  AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x,0,3}, "Backend" -> "Package"]; n]],
 0, TestID -> "N01-explicit-wins-without-consuming-default"]
VerificationTest[
 withDefaults[AsymptoticAnalysis`AsymptoticExpand, {"Backend" -> "Series"},
  Normal[AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x,0,3}]]],
 1+x+x^2/2+x^3/6, TestID -> "N01-alias-default"]
VerificationTest[
 withDefaults[AsymptoticAnalysis`AsymptoticExpand, {"Backend" -> "Series"},
  AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x,0,3}, "Backend" -> "Package"]["Kind"]],
 "Forward", TestID -> "N01-alias-explicit-wins"]
VerificationTest[Module[{s=AsymptoticAnalysis`AsymptoticExpansion[Sin[Method],
 Method->0,"Backend"->"Asymptotic"]}, {s["Variable"], s[1/10]}],
 {Method,1/10}, TestID -> "N02-option-name-as-variable"]
VerificationTest[AsymptoticAnalysis`AsymptoticExpansion[Sin[x], {x,0,3},
 "Backend"->"Asymptotic", Method->Automatic]["Variable"],
 x, TestID -> "N02-actual-option-not-variable"]
VerificationTest[FailureQ[AsymptoticAnalysis`AsymptoticExpansion[Exp[x+y],
 {x,0,1},{y,0,1},"Backend"->"Series"][1/10]],
 True, TestID -> "N02-multivariable-still-refused"]
VerificationTest[Normal[AsymptoticAnalysis`AsymptoticExpansion[
 Function[z,z][Exp[I x]], {x,0,3}]], Normal[Series[Exp[I x],{x,0,3}]],
 TestID -> "N03-applied-identity-complex"]
VerificationTest[AsymptoticAnalysis`AsymptoticExpansion[
 Function[z,z][Sin[x]], {x,0,3}, Analytic->True]["Kind"],
 "Native", TestID -> "N03-applied-identity-native-option"]
VerificationTest[AsymptoticAnalysis`AsymptoticExpansion[
 Function[z,Sin[z]], {x,0,3}]["Kind"],
 "Forward", TestID -> "N03-unapplied-callable-protected"]
VerificationTest[FailureQ[AsymptoticAnalysis`AsymptoticExpansion[
 Function[z,z][Exp[I x]], {x,0,3}, Direction->"FromAbove"]],
 True, TestID -> "N03-explicit-direction-protected"]
VerificationTest[Module[{n=0},
 AsymptoticAnalysis`AsymptoticExpansion[Function[z,(n++;z)][Exp[I x]],{x,0,3}]; n],
 1, TestID -> "N03-no-source-replay"]
VerificationTest[AsymptoticAnalysis`AsymptoticExpansion[Sin[x],{x,0,3},
 "Backend"->"Series"]["NativeResult"], Series[Sin[x],{x,0,3}],
 TestID -> "native-result-unchanged-control"]
