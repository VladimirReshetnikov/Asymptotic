(* Reproduce the wave-5 signed-real modulus witnesses on the current source.

   Every recorded verdict is derived from the run: "Agrees" compares the
   returned finite expression with the exact value under the case's own domain,
   and "Difference" records what the expansion omits or misstates. Nothing in
   the exported record is a hardcoded conclusion. *)
Module[{root, files, hashes, before, cases, probe, observations, output},
 (* x and a stay Global` so the recorded expressions are readable. *)
 ClearAll[Global`x, Global`a];
 With[{x = Global`x, a = Global`a},
  root = DirectoryName[DirectoryName[$InputFileName]];
  files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
  hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
      FileHash[#, "SHA256", "HexString"]) & /@ files];
  before = hashes[];
  Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];

  probe[case_, expr_, cutoff_, assumptions_, exact_, domain_, check_,
    provenance_] :=
   Module[{s, normal, difference, agrees},
    s = TimeConstrained[
      AsymptoticAnalysis`AsymptoticExpansion[expr, {x, 0, cutoff},
       "Backend" -> "Package", Assumptions -> assumptions], 60, $Aborted];
    normal = If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries], Normal[s], s];
    difference =
     If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
      FullSimplify[exact - normal, domain], Missing["NoResult"]];
    agrees = TrueQ[difference === 0];
    <|"Case" -> case,
      "Input" -> ToString[expr, InputForm],
      "Assumptions" -> ToString[assumptions, InputForm],
      "Cutoff" -> cutoff,
      "Observed" -> <|
        "Normal" -> ToString[normal, InputForm],
        "Exact" -> If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
          TrueQ[s["Exact"]], Null],
        "RemainderPower" -> If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
          ToString[s["RemainderPower"], InputForm], Null]|>,
      "ExactValue" -> ToString[exact, InputForm],
      "Difference" -> ToString[difference, InputForm],
      "Agrees" -> agrees,
      "IndependentCheck" -> ToString[check, InputForm],
      "Provenance" -> provenance|>];

  observations = {
    probe["algebraic-cancellation",
     Abs[1 + a x] + Abs[1 - a x] - 2, 4, a^2 == -1,
     2 Sqrt[1 + x^2] - 2, x > 0,
     FullSimplify[Abs[1 + I x] + Abs[1 - I x] - 2 == 2 Sqrt[1 + x^2] - 2,
      Element[x, Reals]],
     "Wave-5 report 37 F01; the same witness family was reported by retired \
reports 40 and 41."],
    probe["squared-wrong-sign",
     Abs[1 + a x]^2 + Abs[1 - a x]^2, 4, a^2 == -1,
     2 + 2 x^2, x > 0,
     FullSimplify[Abs[1 + I x]^2 + Abs[1 - I x]^2 == 2 + 2 x^2,
      Element[x, Reals]],
     "Retired wave-5 report 41 ABS-01, second witness: no square root is \
involved, so the shortcut returns a real coefficient of the wrong sign."],
    probe["logarithmic-scale-boundary",
     Abs[Log[x] + a] + Abs[Log[x] - a], 2, a^2 == -1,
     2 Sqrt[Log[x]^2 + 1], 0 < x < 1,
     FullSimplify[Abs[Log[x] + I] + Abs[Log[x] - I] == 2 Sqrt[Log[x]^2 + 1],
      0 < x < 1],
     "Retired wave-5 report 40 ABS-01, logarithmic witness: the exact value \
leaves the power-logarithmic scale."],
    probe["real-parameter-control",
     Abs[1 + a x] + Abs[1 - a x] - 2, 4, Element[a, Reals], 0, x > 0,
     True, "Control: the sign-based shortcut is valid for a real parameter."],
    probe["real-parameter-squared-control",
     Abs[1 + a x]^2 + Abs[1 - a x]^2, 4, Element[a, Reals],
     2 + 2 a^2 x^2, x > 0,
     True, "Control for the squared witness under a real parameter."]};

  output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
  If[! StringQ[output] || output === "",
   output = FileNameJoin[{root, "validation", "wave5-modulus-witness.json"}]];
  Export[output, <|"Kernel" -> $Version,
    "Scope" -> "Five bounded public characterizations of the signed-real \
absolute-value shortcut on nonreal retained coefficients, with two real-parameter \
controls. Each verdict is computed in the run by comparing the returned finite \
expression with the exact value. This is a characterization probe, not an \
acceptance suite, and no repair is applied.",
    "Route" -> "AsymptoticExpansion with \"Backend\" -> \"Package\". The \
SeriesObservable route used by some of the original reports was not probed.",
    "SourceSHA256" -> before,
    "SourcesUnchangedDuringRun" -> (before === hashes[]),
    "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
    "CasesDisagreeing" -> Count[observations, _?(! #["Agrees"] &)],
    "Observations" -> observations|>, "RawJSON"];
  Print[output];
  Do[Print[o["Case"], " agrees=", o["Agrees"], " normal=", o["Observed"]["Normal"]],
   {o, observations}];
  Exit[If[before === hashes[], 0, 1]]]];
