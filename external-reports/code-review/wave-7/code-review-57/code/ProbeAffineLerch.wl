(* UNEXECUTED characterization. Does not install any candidate patch.
   Set ASYMPTOTIC_ROOT to a checkout of the pinned revision before running.
   Wolfram: wolframscript -file code/ProbeAffineLerch.wl
   Mathics: mathics -f code/ProbeAffineLerch.wl (verify local CLI syntax).
   Exact arithmetic proves the counterexample without numerical LerchPhi.
*)
root = Environment["ASYMPTOTIC_ROOT"];
If[! StringQ[root] || ! FileExistsQ[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]],
  Print["Set ASYMPTOTIC_ROOT to the checkout directory."]; Quit[2]];
Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
Print[InputForm[{"Runtime", $Version}]];
Clear[x];
Do[
  result = AsymptoticAnalysis`AsymptoticExpansion[
    1 + System`LerchPhi[1/2, 2, x], {x, Infinity, cutoff}, "Backend" -> "Package"];
  Print[InputForm[{"Cutoff", cutoff, "Result", result}]];
  If[MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries],
    Print[InputForm[{
      "Normal", Normal[result], "Remainder", result["Remainder"],
      "RemainderPower", result["RemainderPower"],
      "FrontierTerm", result["FrontierTerm"],
      "AbsoluteRemainderBound", result["AbsoluteRemainderBound"],
      "BoundAt2", result["AbsoluteRemainderBound"] /. x -> 2,
      "ExactDefiningSumLowerBoundAt2", 1 + 1/2^2,
      "BoundStrictlyBelowProvedLowerBound", TrueQ[
        (result["AbsoluteRemainderBound"] /. x -> 2) < 5/4]
    }]]],
  {cutoff, {-1, 0, 1, 3}}];
(* Separate private finite-tail edge: evaluate only in a disposable kernel.
   Public simplification may eliminate a finite Lerch atom before dispatch.
*)
Print["Probe complete; the printed observations, not this file, are runtime evidence."];
