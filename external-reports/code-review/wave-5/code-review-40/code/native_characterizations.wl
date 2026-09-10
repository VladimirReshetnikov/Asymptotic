(* Run, not previously observed:
   wolframscript -file code/native_characterizations.wl /path/to/AsymptoticAnalysis.wl
   Prints observations; does not label predicted source traces as measured.
*)
If[Length[$ScriptCommandLine] < 2, Print["Supply a local package path."]; Exit[2]];
packagePath = Last[$ScriptCommandLine];
If[! FileExistsQ[packagePath], Print["Package path does not exist."]; Exit[2]];
Get[packagePath];
If[! NameQ["AsymptoticAnalysis`SeriesObservable"], Print["Package did not load."]; Exit[2]];
Print["KERNEL: ", $Version];
Clear[x, y, z, u, ell];
summary[result_] := If[MatchQ[result, AsymptoticAnalysis`GeneralizedSeries[_Association]],
 <|"Expression" -> Normal[result], "Remainder" -> result["Remainder"],
   "DerivativeContract" -> Lookup[Lookup[result[[1]], "SeriesRepresentation", <||>],
      "RemainderDerivativeOrder", Missing["Absent"]]|>, result];
s = AsymptoticAnalysis`AsymptoticExpansion[u, {u, 0, 4}, "Backend" -> "Package"];
Print["BASE: ", InputForm[summary[s]]];
If[! MatchQ[s, AsymptoticAnalysis`GeneralizedSeries[_Association]], Exit[1]];
Print["UNIT-PAIR: ", InputForm[summary[AsymptoticAnalysis`SeriesObservable[
 s, Abs[1 + I z] + Abs[1 - I z], z]]]];
Print["LOG-PAIR: ", InputForm[summary[AsymptoticAnalysis`SeriesObservable[
 s, Abs[Log[z] + I] + Abs[Log[z] - I], z]]]];
base = AsymptoticAnalysis`AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 2}];
Print["EXACT-FOURIER-SOURCE: ", InputForm[summary[base]]];
If[! MatchQ[base, AsymptoticAnalysis`GeneralizedSeries[_Association]], Exit[1]];
derivative = AsymptoticAnalysis`SeriesDifferentiate[base, 1, "RemainderDerivativeOrder" -> 2];
Print["FIRST-DERIVATIVE: ", InputForm[summary[derivative]]];
If[! MatchQ[derivative, AsymptoticAnalysis`GeneralizedSeries[_Association]], Exit[1]];
modulus = AsymptoticAnalysis`SeriesObservable[derivative, Abs[z - 1], z];
Print["UNCERTAIN-MODULUS: ", InputForm[summary[modulus]]];
If[! MatchQ[modulus, AsymptoticAnalysis`GeneralizedSeries[_Association]], Exit[1]];
Print["DERIVATIVE-AFTER-MODULUS: ", InputForm[summary[
 AsymptoticAnalysis`SeriesDifferentiate[modulus]]]];
