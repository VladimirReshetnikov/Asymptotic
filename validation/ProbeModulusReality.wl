(* Reproduce the wave-5 signed-real modulus witnesses on the current source. *)
Module[{root, files, hashes, before, algebraic, logarithmic, control,
  normalOf, output},
 (* x and a stay Global` so the recorded expressions are readable. *)
 ClearAll[Global`x, Global`a];
 With[{x = Global`x, a = Global`a},
 root = DirectoryName[DirectoryName[$InputFileName]];
 files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@ files];
 before = hashes[];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 normalOf[expr_, cutoff_, assumptions_] :=
  Module[{s}, s = TimeConstrained[
     AsymptoticAnalysis`AsymptoticExpansion[expr, {x, 0, cutoff},
      "Backend" -> "Package", Assumptions -> assumptions], 60, $Aborted];
   If[MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries],
    <|"Normal" -> ToString[Normal[s], InputForm],
      "Exact" -> TrueQ[s["Exact"]],
      "RemainderPower" -> ToString[s["RemainderPower"], InputForm]|>,
    <|"Normal" -> ToString[s, InputForm], "Exact" -> Null,
      "RemainderPower" -> Null|>]];
 algebraic = normalOf[Abs[1 + a x] + Abs[1 - a x] - 2, 4, a^2 == -1];
 logarithmic = normalOf[Abs[Log[x] + a] + Abs[Log[x] - a], 2, a^2 == -1];
 control = normalOf[Abs[1 + a x] + Abs[1 - a x] - 2, 4, Element[a, Reals]];
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "",
  output = FileNameJoin[{root, "validation", "wave5-modulus-witness.json"}]];
 Export[output, <|"Kernel" -> $Version,
   "Scope" -> "Three bounded public characterizations of the signed-real \
absolute-value shortcut on nonreal retained coefficients. This is a \
characterization probe, not an acceptance suite, and no repair is applied.",
   "SourceSHA256" -> before,
   "SourcesUnchangedDuringRun" -> (before === hashes[]),
   "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
   "Observations" -> {
     <|"Case" -> "algebraic-cancellation",
       "Input" -> "Abs[1 + a x] + Abs[1 - a x] - 2",
       "Assumptions" -> "a^2 == -1", "Cutoff" -> 4,
       "Observed" -> algebraic,
       "ExactValue" -> "2 Sqrt[1 + x^2] - 2",
       "ExactLeadingTerm" -> "x^2",
       "IndependentCheck" ->
        ToString[FullSimplify[
          Abs[1 + I x] + Abs[1 - I x] - 2 == 2 Sqrt[1 + x^2] - 2,
          Element[x, Reals]], InputForm],
       "Agrees" -> False|>,
     <|"Case" -> "logarithmic-scale-boundary",
       "Input" -> "Abs[Log[x] + a] + Abs[Log[x] - a]",
       "Assumptions" -> "a^2 == -1", "Cutoff" -> 2,
       "Observed" -> logarithmic,
       "ExactValue" -> "2 Sqrt[Log[x]^2 + 1]",
       "FirstOmittedTerm" -> "-1/Log[x]",
       "IndependentCheck" ->
        ToString[FullSimplify[
          Abs[Log[x] + I] + Abs[Log[x] - I] == 2 Sqrt[Log[x]^2 + 1],
          0 < x < 1], InputForm],
       "Agrees" -> False|>,
     <|"Case" -> "real-parameter-control",
       "Input" -> "Abs[1 + a x] + Abs[1 - a x] - 2",
       "Assumptions" -> "Element[a, Reals]", "Cutoff" -> 4,
       "Observed" -> control,
       "ExactValue" -> "0",
       "Agrees" -> True|>}|>, "RawJSON"];
 Print[output];
 Print["algebraic=", algebraic["Normal"], "  logarithmic=", logarithmic["Normal"],
  "  control=", control["Normal"]];
 Exit[If[before === hashes[], 0, 1]]]];
