(* Reproduce the wave-6 public witnesses on the current source.

   Each case records what the package returned and a verdict derived in the run
   from that return value; nothing here is a hardcoded conclusion. This is a
   characterization probe, not an acceptance suite, and no repair is applied. *)
Module[{root, files, hashes, before, obs, shift, coeff, fields, zeta, output,
  spellings, sample, trueError, claimedScale},
 ClearAll[Global`x, Global`y, Global`s];
 With[{x = Global`x, y = Global`y},
  root = DirectoryName[DirectoryName[$InputFileName]];
  files = Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]];
  hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
      FileHash[#, "SHA256", "HexString"]) & /@ files];
  before = hashes[];
  Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];

  (* 1. Target-dependent SourceShift: reports 46 and 50 F1. *)
  shift = TimeConstrained[
    AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
     {x, Infinity}, {y, 1}, "SourceShift" -> -Abs[y]], 60, $Aborted];
  sample = 20;
  trueError = N[Abs[Log[sample - 1] - (Log[sample] - 1/sample)], 30];
  claimedScale = N[Exp[-2 sample]/sample^2, 30];
  obs = {<|"Case" -> "exponential-core-target-dependent-shift",
     "Reports" -> "46 principal finding; 50 F1",
     "Call" -> "AsymptoticExponentialCoreInverse[Exp[x], 1, {x, Infinity}, \
{y, 1}, \"SourceShift\" -> -Abs[y]]",
     "Refused" -> ! MatchQ[shift, _AsymptoticAnalysis`GeneralizedSeries],
     "Normal" -> ToString[
       If[MatchQ[shift, _AsymptoticAnalysis`GeneralizedSeries], Normal[shift],
        shift], InputForm],
     "NormalUnderPositiveTarget" -> ToString[
       If[MatchQ[shift, _AsymptoticAnalysis`GeneralizedSeries],
        Simplify[Normal[shift], y > 2], shift], InputForm],
     "Remainder" -> ToString[
       If[MatchQ[shift, _AsymptoticAnalysis`GeneralizedSeries],
        shift["Remainder"], Missing["NoResult"]], InputForm],
     "ExactInverse" -> "Log[y - 1]",
     "TrueErrorLeadingTerm" -> ToString[
       Normal[Series[Log[y - 1] - (Log[y] - 1/y), {y, Infinity, 2}]], InputForm],
     "SampleTarget" -> sample,
     "TrueErrorAtSample" -> ToString[trueError, InputForm],
     "ClaimedRemainderScaleAtSample" -> ToString[claimedScale, InputForm],
     "ClaimedBoundExceededAtSample" -> TrueQ[trueError > claimedScale],
     "Note" -> "The finite expression is correct; the reported remainder scale \
is exponentially smaller than the true error, so the bound is false rather \
than merely weak."|>};

  (* 2. Coefficient-option key handling after C09: report 48 N1. *)
  Block[{s},
   s = AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
   spellings = {
     {"string key", Hold[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" -> 2]]},
     {"symbol key", Hold[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, Power -> 2]]},
     {"symbol then string", Hold[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, Power -> 2, "Power" -> 3]]},
     {"nested list", Hold[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, {"Power" -> 2}]]},
     {"delayed string", Hold[AsymptoticAnalysis`InverseExpansionCoefficient[s, {1}, "Power" :> 2]]}};
   coeff = Function[{entry},
      Module[{r = ReleaseHold[entry[[2]]]},
       <|"Spelling" -> entry[[1]],
         "Head" -> ToString[Head[r], InputForm],
         "Exponent" -> ToString[r["Exponent"], InputForm],
         "Coefficient" -> ToString[r["Coefficient"], InputForm],
         "ExponentIsNumeric" -> TrueQ[NumericQ[r["Exponent"]]],
         "CoefficientIsNumeric" -> TrueQ[NumericQ[r["Coefficient"]]]|>]] /@
     spellings];
  AppendTo[obs, <|"Case" -> "coefficient-option-key-handling",
    "Reports" -> "48 N1",
    "RelatedClosedItem" -> "C09 (focused verified - explicit precedence)",
    "Constructor" -> "AsymptoticInverse[x + x^2, {x, 0}, {y, 4}]",
    "Query" -> "InverseExpansionCoefficient[s, {1}, <option spelling>]",
    "Results" -> coeff,
    "AllSpellingsSucceeded" -> AllTrue[coeff, #["Head"] === "Association" &],
    "SpellingsWithNonNumericFields" ->
     Count[coeff, _?(! (#["ExponentIsNumeric"] && #["CoefficientIsNumeric"]) &)],
    "FirstOptionPrecedenceHolds" ->
     TrueQ[SelectFirst[coeff, #["Spelling"] === "symbol then string" &][
        "Coefficient"] ===
       SelectFirst[coeff, #["Spelling"] === "symbol key" &]["Coefficient"]],
    "Note" -> "A successful association whose Exponent and Coefficient retain \
an unevaluated option name is a type-corrupted result, not a refusal. The \
symbol-then-string case shows the later string option winning."|>];

  (* 3. Local numerical metadata labels: reports 48 N3, 51 N02, 54 N04. *)
  fields = TimeConstrained[
    AsymptoticAnalysis`InverseNumericalCheck[
     AsymptoticAnalysis`AsymptoticInverse[x, {x, 0}, {y, 3}, "Power" -> 2], 2,
     WorkingPrecision -> 30], 60, $Aborted];
  AppendTo[obs, <|"Case" -> "local-numerical-field-labels",
    "Reports" -> "48 N3; 51 N02; 54 N04",
    "Call" -> "InverseNumericalCheck[AsymptoticInverse[x, {x, 0}, {y, 3}, \
\"Power\" -> 2], 2, WorkingPrecision -> 30]",
    "LocalRoot" -> ToString[fields["LocalRoot"], InputForm],
    "LocalApproximation" -> ToString[fields["LocalApproximation"], InputForm],
    "ReferenceObservable" -> ToString[fields["ReferenceObservable"], InputForm],
    "LocalCoordinateLabel" -> ToString[fields["LocalCoordinate"], InputForm],
    "LocalRootPoweredEqualsApproximation" ->
     TrueQ[Chop[N[fields["LocalRoot"]^2 - fields["LocalApproximation"], 20]] === 0],
    "Note" -> "The numerical values are correct. LocalRoot is the source \
coordinate and LocalApproximation is its squared observable, so one label \
covering both quantities is what the reports dispute."|>];

  (* 4. Affine translation of an accepted defining-sum atom: report 55 N01. *)
  zeta = {
    <|"Input" -> "Zeta[x]",
      "Result" -> TimeConstrained[
        AsymptoticAnalysis`AsymptoticExpansion[Zeta[x], {x, Infinity, 2},
         "Backend" -> "Package"], 60, $Aborted]|>,
    <|"Input" -> "Zeta[x] - 1",
      "Result" -> TimeConstrained[
        AsymptoticAnalysis`AsymptoticExpansion[Zeta[x] - 1, {x, Infinity, 2},
         "Backend" -> "Package"], 60, $Aborted]|>};
  AppendTo[obs, <|"Case" -> "defining-sum-affine-translation",
    "Reports" -> "55 N01",
    "Observations" -> (<|"Input" -> #["Input"],
        "Head" -> ToString[Head[#["Result"]], InputForm],
        "Accepted" -> MatchQ[#["Result"], _AsymptoticAnalysis`GeneralizedSeries],
        "Normal" -> ToString[
          If[MatchQ[#["Result"], _AsymptoticAnalysis`GeneralizedSeries],
           Normal[#["Result"]], #["Result"]], InputForm]|> & /@ zeta),
    "TranslationRefusedWhileAtomAccepted" ->
     TrueQ[MatchQ[zeta[[1]]["Result"], _AsymptoticAnalysis`GeneralizedSeries] &&
       ! MatchQ[zeta[[2]]["Result"], _AsymptoticAnalysis`GeneralizedSeries]],
    "Note" -> "A coverage gap, not a false formula: subtracting an exact \
constant from an accepted atom is refused."|>];

  output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
  If[! StringQ[output] || output === "",
   output = FileNameJoin[{root, "validation", "wave6-witness-probe.json"}]];
  Export[output, <|"Kernel" -> $Version,
    "Scope" -> "Four bounded public characterizations of wave-6 witnesses on \
the current source. Verdict fields are computed in the run from the returned \
values. This is a characterization probe, not an acceptance suite; no repair \
is applied and no full suite was executed.",
    "SourceSHA256" -> before,
    "SourcesUnchangedDuringRun" -> (before === hashes[]),
    "ProbeSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
    "Observations" -> obs|>, "RawJSON"];
  Print[output];
  Do[Print["  ", o["Case"]], {o, obs}];
  Exit[If[before === hashes[], 0, 1]]]];
