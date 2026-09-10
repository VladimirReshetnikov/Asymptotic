(* Read-only C14 reproduction: selected R13 A1 witnesses and exact controls.
   Run with wolfram.exe -script validation/ProbeExponentEquality.wl.
   Each observation is time-bounded; this is not a package acceptance suite. *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],
  "src", "Kernel", "AsymptoticAnalysis.wl"}]];

SetAttributes[exponentObservation, HoldRest];
exponentObservation[name_, expression_] := Module[{seconds, result},
  {seconds, result} = AbsoluteTiming[TimeConstrained[expression, 45, $Aborted]];
  Print[ExportString[<|"Observation" -> name, "Seconds" -> seconds,
    "Result" -> ToString[result, InputForm]|>, "RawJSON"]]];

Print["Wolfram version: ", $Version];
exponentObservation["canonical forms and proved identity",
  Module[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2},
    {AsymptoticAnalysis`Private`canon[a], AsymptoticAnalysis`Private`canon[b],
      FullSimplify[a - b], AsymptoticAnalysis`Private`compare[a, b]}]];
exponentObservation["cancellation before one-term request",
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticExpansion[x^a - x^b + x^2, {x, 0},
      SeriesTermGoal -> 1, "Backend" -> "Package"];
    If[FailureQ[s], s, {Normal[s], s["Remainder"], s["ReturnedTermCount"]}]]];
exponentObservation["square at logarithmic frontier",
  Module[{x, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s, t},
    s = AsymptoticExpansion[1 + x^a + x^b Log[x]^3 + x^(2 a),
      {x, 0, 2 a}, "Backend" -> "Package"];
    t = SeriesMultiply[s, s];
    If[FailureQ[t], t, {Normal[t], t["RemainderPower"], t["RemainderLogDegree"]}]]];
exponentObservation["cancelled inverse under an eight-index budget",
  Module[{x, y, a = Sinh[1]^2, b = (Cosh[2] - 1)/2, s},
    s = AsymptoticInverse[x^a - x^b + x^2, {x, 0}, {y, 2}, "MaxTerms" -> 8];
    If[FailureQ[s], s, {Normal[s], s["Remainder"], s["Model"]["Gaps"]}]]];
exponentObservation["strictly distinct close weights",
  Module[{a = Sinh[1]^2, b = (Cosh[2] - 1)/2},
    {AsymptoticAnalysis`Private`compare[a, b + 10^-100],
      AsymptoticAnalysis`Private`compare[b + 10^-100, a],
      AsymptoticAnalysis`Private`compare[a, b - 10^-100]}]];
