(* Observation harness, not a pass/fail suite. Equivalent focused expressions
   were executed through the connector; this complete wrapper was not. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "load_review.wl"}]];
ClearAll[emit, brief, probe, x, y, z];
brief[s_AsymptoticAnalysis`GeneralizedSeries] :=
  KeyTake[s[[1]], {"Kind", "NativeBackend", "Variable", "Expression", "Remainder"}];
brief[e_] := e;
emit[id_, value_] := Print[ExportString[<|"ID" -> id,
  "InputForm" -> ToString[value, InputForm]|>, "RawJSON"]];
SetAttributes[probe, HoldRest];
probe[id_, body_] := emit[id, TimeConstrained[body, 30, "HARNESS_TIME_LIMIT"]];
emit["runtime", <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "Source" -> $AuditSourceDescription|>];
probe["N01-main", Module[{old = Options[AsymptoticAnalysis`AsymptoticExpansion], result},
  SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
  result = brief[AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}]];
  Options[AsymptoticAnalysis`AsymptoticExpansion] = old; result]];
probe["N01-alias", Module[{old = Options[AsymptoticAnalysis`AsymptoticExpand], result},
  SetOptions[AsymptoticAnalysis`AsymptoticExpand, "Backend" -> "Series"];
  result = brief[AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x, 0, 3}]];
  Options[AsymptoticAnalysis`AsymptoticExpand] = old; result]];
probe["N02", Module[{s},
  s = AsymptoticAnalysis`AsymptoticExpansion[Sin[Method], Method -> 0,
    "Backend" -> "Asymptotic"];
  {Asymptotic[Sin[Method], Method -> 0], s["NativeResult"], s["Variable"], s[1/10]}]];
probe["N03-complex", {brief[AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}]],
  brief[AsymptoticAnalysis`AsymptoticExpansion[Function[z,z][Exp[I x]], {x, 0, 3}]]}];
probe["N03-native-option", {
  brief[AsymptoticAnalysis`AsymptoticExpansion[Sin[x], {x, 0, 3}, Analytic -> True]],
  brief[AsymptoticAnalysis`AsymptoticExpansion[Function[z,z][Sin[x]], {x, 0, 3}, Analytic -> True]]}];
probe["irrational-forward", brief[AsymptoticAnalysis`AsymptoticExpansion[
  Exp[x+x^Sqrt[2]], {x, 0, 3}, "Backend" -> "Package"]]];
probe["irrational-inverse", brief[AsymptoticAnalysis`AsymptoticInverse[
  x+x^Sqrt[2], {x, 0}, {y, 3}]]];
probe["N04-storage", Table[Module[{raw, normal, wrapped},
  raw = Series[1/(1-x-y), {x, 0, n}, {y, 0, n}]; normal = Normal[raw];
  wrapped = AsymptoticAnalysis`AsymptoticExpansion[1/(1-x-y),
    {x, 0, n}, {y, 0, n}, "Backend" -> "Series"];
  <|"n" -> n, "NativeBytes" -> ByteCount[raw], "NormalBytes" -> ByteCount[normal],
    "WrapperBytes" -> ByteCount[wrapped],
    "NativeEqual" -> SameQ[raw, wrapped["NativeResult"]],
    "NormalEqual" -> SameQ[normal, Normal[wrapped]]|>], {n, {8,16,24}}]];
