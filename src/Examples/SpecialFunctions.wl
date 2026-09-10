(* Run from the repository root:
   wolfram.exe -script src/Examples/SpecialFunctions.wl *)
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[x];
specialExamples = {
  {"Bessel product", BesselI[0, x] BesselK[0, x], Infinity,
    1/(2 x) + 1/(16 x^3) + 27/(256 x^5)},
  {"Airy decay", AiryAi[x], Infinity,
    Exp[-2 x^(3/2)/3]/(2 Sqrt[Pi] x^(1/4)) (1 - 5/(48 x^(3/2)) + 385/(4608 x^3))},
  {"Oscillatory Bessel", BesselJ[0, x], Infinity,
    Sqrt[2/(Pi x)] (Cos[x - Pi/4] + Sin[x - Pi/4]/(8 x) - 9 Cos[x - Pi/4]/(128 x^2))},
  {"Zeta Dirichlet scale", Zeta[x], Infinity, 1 + 2^-x + 3^-x},
  {"Lerch reciprocal scale", LerchPhi[1/2, 2, x], Infinity, 2/x^2 - 4/x^3 + 18/x^4}};
specialExampleFailed = False;
Do[
  s = AsymptoticExpansion[example[[2]], x -> example[[3]], SeriesTermGoal -> 3];
  If[! MatchQ[s, _GeneralizedSeries] ||
      ! TrueQ[FullSimplify[Normal[s] == example[[4]], x > 1]] ||
      ! FreeQ[Normal[s], _GeneralizedSeries | _PowerLogRemainder | _SeriesData],
    specialExampleFailed = True];
  Print[example[[1]], "\n  Normal: ", InputForm[Normal[s]],
    "\n  Remainder: ", InputForm[s["Remainder"]]],
  {example, specialExamples}];
Exit[If[specialExampleFailed, 1, 0]];
