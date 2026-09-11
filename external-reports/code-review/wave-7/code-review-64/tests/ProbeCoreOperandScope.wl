(* UNRUN integration probe. Load the PINNED package before this file.
   Use the same Get expressions in a Wolfram 15 or Mathics3 session.
   It prints what happened; it does not mislabel a refusal as a successful test. *)
Begin["ReviewCoreOperandScope`"];
ClearAll[x, y, summarize];
If[Length[DownValues[AsymptoticAnalysis`AsymptoticCoreInverse]] === 0,
  Print["PACKAGE_NOT_LOADED"]; Abort[]];
summarize[s_] := If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
  With[{a = s[[1]]}, {"Series", a["Expression"], a["RemainderPower"],
    a["RemainderScaleExpression"], a["TargetDomain"]}], {"NotSeries", s}];
Print["Runtime: ", $Version];
Do[
  Print["moving-linear depth ", n, ": ", InputForm[summarize[
    AsymptoticAnalysis`AsymptoticCoreInverse[
      1/x + Abs[y]/2, -Abs[y]/2, {x,0}, {y,n}]]]],
  {n,0,3}];
Print["moving-small: ", InputForm[summarize[
  AsymptoticAnalysis`AsymptoticCoreInverse[
    1/x + Sqrt[Abs[y]], -Sqrt[Abs[y]], {x,0}, {y,2}]]]];
Print["fixed-positive control: ", InputForm[summarize[
  AsymptoticAnalysis`AsymptoticCoreInverse[1/x+2,-2,{x,0},{y,2}]]]];
Print["fixed-negative control: ", InputForm[summarize[
  AsymptoticAnalysis`AsymptoticCoreInverse[1/x-2,2,{x,0},{y,2}]]]];
Print["zero control: ", InputForm[summarize[
  AsymptoticAnalysis`AsymptoticCoreInverse[1/x,0,{x,0},{y,2}]]]];
End[];
