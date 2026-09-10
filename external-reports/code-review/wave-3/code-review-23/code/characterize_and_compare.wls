(* Native characterization and contract-aligned comparison candidates.
   NOT EXECUTED in the audit. Records returned evidence, never invents pass counts.
   Set ASYMPTOTIC_AUDIT_REPO; run in a fresh native kernel. New code: MIT-0. *)
scriptDirectory = DirectoryName[$InputFileName];
repo = Environment["ASYMPTOTIC_AUDIT_REPO"];
If[! StringQ[repo] || ! DirectoryQ[repo], Print["Set ASYMPTOTIC_AUDIT_REPO."]; Exit[2]];
If[MemberQ[$Packages, "AsymptoticAnalysis`"], Print["Use a fresh kernel."]; Exit[2]];
Get[FileNameJoin[{repo, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[x, y, a, t, ell];

capture[label_String, held_HoldComplete] := Module[{seconds, result, messages},
 Block[{$Assumptions = True, $MessageList = {}},
  {seconds, result} = AbsoluteTiming[
    TimeConstrained[ReleaseHold[held], 60, Failure["AuditTimeout", <||>]]];
  messages = ToString[#, InputForm] & /@ $MessageList];
 <|"Case" -> label, "Request" -> ToString[held, InputForm],
   "Seconds" -> seconds, "ReturnedHead" -> ToString[Head[result], InputForm],
   "Failure" -> TrueQ[FailureQ[result]], "Messages" -> messages,
   "ResultInputForm" -> ToString[result, InputForm],
   "Kind" -> If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
     ToString[result["Kind"], InputForm], "not a package object"],
   "Remainder" -> If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
     ToString[result["Remainder"], InputForm], "inspect native result"],
   "NativeEvaluationStatus" -> If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
     ToString[result["NativeEvaluationStatus"], InputForm], "not applicable"]|>];

cases = {
 {"N01-private-normalizer", HoldComplete[
   AsymptoticAnalysis`Private`parseFinite[x+x^2 Log[x^a]^2, x, ell, a^2 == -1]]},
 {"N01-core-constructor", HoldComplete[
   AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`construct[x+x^2 Log[x^a]^2, x, 0, y, 1,
     Assumptions -> a^2 == -1, "Truncation" -> "Depth"]]]},
 {"N01-public-facade", HoldComplete[
   AsymptoticAnalysis`AsymptoticInverse[x+x^2 Log[x^a]^2,
    {x,0},{y,1}, Assumptions -> a^2 == -1, "Truncation" -> "Depth"]]},
 {"N04-native-held-data-control", HoldComplete[
   System`Series[HoldComplete[Series[t,{t,0,1}]],{x,0,1}]]},
 {"N04-wrapper-held-data", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[
    HoldComplete[Series[t,{t,0,1}]],{x,0,1},"Backend"->"Series"]]},
 {"ordinary-package-cutoff4", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[Exp[x],{x,0,4},"Backend"->"Package"]]},
 {"ordinary-native-order3", HoldComplete[System`Series[Exp[x],{x,0,3}]]},
 {"logarithmic-package", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[Exp[x Log[x]],{x,0,4},"Backend"->"Package"]]},
 {"logarithmic-native", HoldComplete[System`Series[Exp[x Log[x]],{x,0,3}]]},
 {"irrational-gap-inverse", HoldComplete[
   AsymptoticAnalysis`AsymptoticInverse[x+x^(1+Sqrt[2]),{x,0},{y,4}]]},
 {"irrational-gap-AsymptoticSolve", HoldComplete[
   System`AsymptoticSolve[x+x^(1+Sqrt[2])==y,x->0,{y,0,3},Reals]]},
 {"zeta-package-3blocks", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[Zeta[x],{x,Infinity,Automatic},
    SeriesTermGoal->3,"Backend"->"Package"]]},
 {"zeta-native-3terms", HoldComplete[
   System`Asymptotic[Zeta[x],x->Infinity,SeriesTermGoal->3]]},
 {"complex-explicit-native", HoldComplete[
   AsymptoticAnalysis`AsymptoticExpansion[Exp[I x],{x,0,3},"Backend"->"Series"]]}
};
observations = capture[#[[1]], #[[2]]] & /@ cases;
record = <|"KernelVersion"->$Version,"SystemID"->$SystemID,
 "ReferenceRevision"->"6687962f3c858a4f93623cfc496f33e35c6763d4",
 "ContractNote"->"Only the ordinary and logarithmic forward pairs align algebraic cutoffs. Other pairs compare scope and require manual branch/order interpretation. Timings are single observations, not benchmarks.",
 "Observations"->observations|>;
Export[FileNameJoin[{scriptDirectory,"..","results","native_characterization.json"}],record,"RawJSON"];
Print["Recorded ",Length[observations]," observations."];
