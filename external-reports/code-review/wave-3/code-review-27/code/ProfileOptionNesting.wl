(* Run after loading a pinned package. Instrumentation is restored afterwards.
   These are definition-invocation counts, NOT timing measurements. *)
If[!MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Load AsymptoticAnalysis first."]; Abort[]];
Module[{saved, calls = 0, held, rows},
  Internal`WithLocalSettings[
    saved = DownValues[AsymptoticAnalysis`Private`nativeOptionTreeQ];
    DownValues[AsymptoticAnalysis`Private`nativeOptionTreeQ] = saved /.
      Verbatim[RuleDelayed][lhs_, rhs_] :> RuleDelayed[lhs, (calls++; rhs)],
    rows = Table[
      held = With[{p = Nest[List, Assumptions -> True, d]}, HoldComplete[p]];
      calls = 0;
      AsymptoticAnalysis`Private`nativeSelectorValues[held];
      <|"Depth" -> d, "ValidationCalls" -> calls,
        "SourceRecurrencePrediction" -> d (d + 3)/2|>,
      {d, {4, 8, 16, 32}}];
    <|"Kernel" -> $Version, "Instrumentation" -> "Counter at entry to nativeOptionTreeQ",
      "Scope" -> "Selector discovery only, not full request parsing or elapsed time", "Rows" -> rows|>,
    DownValues[AsymptoticAnalysis`Private`nativeOptionTreeQ] = saved]]
