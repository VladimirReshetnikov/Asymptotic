(* Observation script, NOT an assertion that any probe was executed here.
   Usage: wolframscript -file native_probe.wl /absolute/path/to/package.wl
   Run separately for original and staged sources, in fresh kernels. *)
If[Length[$ScriptCommandLine] < 2, Print["Supply an audited local package path."]; Exit[2]];
Get[Last[$ScriptCommandLine]];
Clear[x, y];
probe[label_, held_HoldComplete] := Module[{answer},
  answer = TimeConstrained[ReleaseHold[held], 120, $TimedOut];
  Print[InputForm[<|"Label" -> label, "Result" -> answer|>]];
];
Print[InputForm[<|"Kernel" -> $Version, "System" -> $SystemID, "Assumptions" -> $Assumptions|>]];
probe["Refine positional versus option", HoldComplete[
  Block[{$Assumptions = x > 1},
    {Refine[x > 1, Element[x, Reals]], Refine[x > 1, Assumptions -> Element[x, Reals]]}]]];
probe["Certificate isolation", HoldComplete[
  Block[{$Assumptions = True}, Module[{s},
    s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 1], {x, Infinity}, {y, 2}];
    {s["SourceDomain"],
      AsymptoticInverse`InverseCertificate[s, 1/2, "Interval" -> {1/4, 3/4}, "Center" -> 1/2, "MaxRefinements" -> 0],
      Block[{$Assumptions = x > 1},
        AsymptoticInverse`InverseCertificate[s, 1/2, "Interval" -> {1/4, 3/4}, "Center" -> 1/2, "MaxRefinements" -> 0]]}
  ]]]];
probe["Relative accuracy and precision history", HoldComplete[
  Block[{$Assumptions = True}, Module[{s},
    s = AsymptoticInverse`AsymptoticInverse[x, {x, 0}, {y, 2}];
    AsymptoticInverse`InverseCertificate[s, 1/3, "Interval" -> {1/4, 1/2},
      "RelativeError" -> 10^-1000, "RefineExpansion" -> False, "MaxRefinements" -> 6]
  ]]]];
probe["Simultaneous cutoff and term goal", HoldComplete[
  Block[{$Assumptions = True},
    {AsymptoticInverse`AsymptoticExpansion[x+x^2+x^3, {x, 0, 4}, SeriesTermGoal -> 1],
     AsymptoticInverse`AsymptoticExpansion[Zeta[x], {x, Infinity, Log[5]}, SeriesTermGoal -> 1]}]]];
