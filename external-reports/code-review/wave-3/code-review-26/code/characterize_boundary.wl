(* Load the target package first. No TestReport pass/fail claim is made here:
   these are observable characterizations, valid on baseline or candidate. *)
Module[{saved = Options[AsymptoticExpansion], aliasSaved = Options[AsymptoticExpand],
   x, a, summary, rows = <||>, s, restore},
  summary[r_] := If[FailureQ[r], <|"FailureTag" -> r[[1]]|>,
    <|"Kind" -> r["Kind"], "NormalInputForm" -> ToString[Normal[r], InputForm]|>];
  restore[] := (Options[AsymptoticExpansion] = saved; Options[AsymptoticExpand] = aliasSaved);
  CheckAbort[
    rows["OrdinaryControl"] = summary[AsymptoticExpansion[Exp[x], {x, 0, 3}]];
    SetOptions[AsymptoticExpansion, "Backend" -> "Series"];
    rows["ConfiguredBackend"] = summary[AsymptoticExpansion[Exp[x], {x, 0, 3}]];
    rows["ExplicitBackend"] = summary[AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"]];
    restore[];
    SetOptions[AsymptoticExpansion, SeriesTermGoal -> 4];
    rows["ConfiguredGoal"] = summary[AsymptoticExpansion[Exp[x], x -> 0]];
    rows["ExplicitGoal"] = summary[AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 4]];
    restore[];
    SetOptions[AsymptoticExpand, "Backend" -> "Series"];
    rows["AliasConfiguredBackend"] = summary[AsymptoticExpand[Exp[x], {x, 0, 3}]];
    restore[];
    rows["StringAssumptions"] = summary[AsymptoticExpansion[Sqrt[a^2] Exp[x], {x, 0, 2}, "Assumptions" -> a > 0]];
    rows["NativeStringControl"] = ToString[Normal[Series[Sqrt[a^2] Exp[x], {x, 0, 2}, "Assumptions" -> a > 0]], InputForm];
    s = AsymptoticExpansion[Exp[Method], Method -> 0, "Backend" -> "Asymptotic"];
    rows["OptionNamedVariable"] = <|"NativeResult" -> ToString[s["NativeResult"], InputForm],
      "Variable" -> ToString[s["Variable"], InputForm],
      "Specifications" -> ToString[s["ExpansionSpecifications"], InputForm],
      "ApplicationAt2" -> ToString[s[2], InputForm]|>;
    restore[];
    <|"KernelVersion" -> $Version, "SystemID" -> $SystemID, "Observations" -> rows|>,
    restore[]; Abort[]]]
