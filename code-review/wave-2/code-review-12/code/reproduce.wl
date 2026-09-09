(* Bounded observations on an explicit LOCAL package file.
   wolframscript -file reproduce.wl /path/to/AsymptoticInverse.wl evidence.json
   This runner never downloads or overwrites the package. *)
Module[{args = Rest[$ScriptCommandLine], path, output, records = {}, observe, compact},
 If[Length[args] < 1 || Length[args] > 2,
  Print["Usage: wolframscript -file reproduce.wl PACKAGE [OUTPUT.json]"]; Exit[2]];
 path = ExpandFileName[args[[1]]];
 output = If[Length[args] == 2, args[[2]], "native-observations.json"];
 If[! FileExistsQ[path], Print["Package file does not exist: ", path]; Exit[2]];
 If[Check[Get[path]; True, False] =!= True,
  Print["Package loading produced an error."]; Exit[3]];
 If[Names["AsymptoticInverse`AsymptoticExpansion"] === {},
  Print["The expected package context was not loaded."]; Exit[3]];
 compact[s_] := If[MatchQ[s, AsymptoticInverse`GeneralizedSeries[_Association]],
   KeyTake[s[[1]], {"Kind", "Scale", "Expression", "Remainder", "SeriesData",
     "RemainderScaleExpression", "TargetDomain", "Exact"}], s];
 SetAttributes[observe, HoldAllComplete];
 observe[id_String, expr_] := Module[{value, elapsed, messages},
   Block[{$Assumptions = True, $MessageList = {}},
    elapsed = First[AbsoluteTiming[value = TimeConstrained[
      MemoryConstrained[expr, 512*1024^2, Failure["AuditMemoryLimit", <||>]],
      25, Failure["AuditTimeLimit", <||>]]]];
    messages = ToString[#, InputForm] & /@ $MessageList];
   AppendTo[records, <|"ID" -> id, "ElapsedSeconds" -> elapsed,
     "OutputInputForm" -> ToString[value, InputForm, PageWidth -> Infinity],
     "Messages" -> messages|>];
   Print[id, ": ", ToString[value, InputForm, PageWidth -> 120]]];
 observe["E01-refine-context", Module[{x}, {
   Block[{$Assumptions = True}, Refine[x > 100, Element[x, Reals]]],
   Block[{$Assumptions = x > 100}, Refine[x > 100, Element[x, Reals]]]}]];
 observe["E02-certificate-domain", Module[{x, y, s, clean, ambient, valid, brief},
   s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 100],
     {x, Infinity}, {y, 2}];
   brief[r_] := If[AssociationQ[r], KeyTake[r, {"Certified", "RootEnclosure",
      "CertifiedSourceDomain", "SourceDomainVerified"}], r];
   clean = AsymptoticInverse`InverseCertificate[s, 2, "Interval" -> {1, 3},
     "Center" -> 2, "MaxRefinements" -> 0];
   ambient = Block[{$Assumptions = x > 100}, AsymptoticInverse`InverseCertificate[s,
     2, "Interval" -> {1, 3}, "Center" -> 2, "MaxRefinements" -> 0]];
   valid = AsymptoticInverse`InverseCertificate[s, 102, "Interval" -> {101, 103},
     "Center" -> 102, "MaxRefinements" -> 0];
   {brief[clean], brief[ambient], brief[valid]}]];
 observe["E03-E04-complex-tail", Module[{x, c, s},
   c = Root[5 + 5*# + #^5 &, 2];
   s = AsymptoticInverse`AsymptoticExpansion[c/x, {x, 0, -2}];
   {Head[c], FreeQ[c, _Real | _Complex], Element[c, Reals], compact[s],
    If[FailureQ[s], "RejectedAtAdmission", compact[Sin[s]]]}]];
 observe["E05-E06-native-view-range", Module[{x, q = 2^100, s, t},
   s = AsymptoticInverse`AsymptoticExpansion[1 + x^q, {x, 0, 2}];
   t = AsymptoticInverse`AsymptoticExpansion[x^(1/q) + x^(3/q), {x, 0, 2/q}];
   {compact[s], compact[t]}]];
 observe["E10-certificate-numerical-differential", Module[{x, y, s},
   s = AsymptoticInverse`AsymptoticInverse[ConditionalExpression[x, x > 100],
     {x, Infinity}, {y, 2}];
   Block[{$Assumptions = x > 100}, AsymptoticInverse`InverseNumericalCheck[s, 2,
     WorkingPrecision -> 20]]]];
 observe["E11-polynomial-comparison", Module[{x, y, s, n},
   s = AsymptoticInverse`AsymptoticInverse[x + x^3, {x, 0}, {y, 6}];
   n = InverseSeries[Series[x + x^3, {x, 0, 6}], y];
   {Normal[s], Normal[n], Simplify[Normal[s] - Normal[n]], s["Remainder"]}]];
 observe["E12-zeta-comparison", Module[{x, s},
   s = AsymptoticInverse`AsymptoticExpansion[Zeta[x], x -> Infinity,
     SeriesTermGoal -> 4];
   {compact[s], Asymptotic[Zeta[x], x -> Infinity, SeriesTermGoal -> 4]}]];
 If[Check[Export[output, <|"Kernel" -> $Version, "PackagePath" -> path,
       "PackageSHA256" -> FileHash[path, "SHA256", "HexString"],
       "Observations" -> records|>, "RawJSON"]; True, False] =!= True,
  Print["Evidence export failed."]; Exit[4]];
 Print["Evidence written to ", output];
];
