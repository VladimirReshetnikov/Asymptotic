(* Public package identity after the namespace rename. The short API names
   are the 38 documented symbols exported at pre-rename checkpoint 01b18ab. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{expected = {
    "AsymptoticCoreInverse", "AsymptoticExpand", "AsymptoticExpansion",
    "AsymptoticExponentialCoreInverse", "AsymptoticFlatInverse", "AsymptoticFourierInverse",
    "AsymptoticInverse", "AsymptoticLogarithmicInverse", "AsymptoticSpecialInverse",
    "FlatSeriesDifferentiate", "FlatSeriesMultiply", "FlatSeriesObservable", "FlatSeriesTruncate",
    "FourierInverseCoefficient", "FourierInverseResidual", "GeneralizedSeries",
    "InverseCertificate", "InverseExpansionCoefficient", "InverseNumericalCheck", "InverseResidual",
    "LogarithmicInverseResidual", "PerturbativeInverse", "PowerLogModel", "PowerLogRemainder",
    "ReciprocalLogCompose", "ReciprocalLogDifferentiate", "SeriesAdd", "SeriesCompose",
    "SeriesDifferentiate", "SeriesExp", "SeriesLog", "SeriesMultiply", "SeriesNormalize",
    "SeriesObservable", "SeriesPower", "SeriesRefine", "SeriesTruncate", "SpecialInverseNumericalCheck"}},
    (* Names uses short names for symbols on $ContextPath. Normalize both
       possible spellings before comparing the entire public symbol set. *)
    Sort[Last[StringSplit[#, "`"]] & /@ Names["AsymptoticAnalysis`*"]] === Sort[expected]],
  True, TestID -> "package-identity-retains-all-38-documented-public-symbols"]

VerificationTest[
  {$Context, MemberQ[$Packages, "AsymptoticAnalysis`"],
    MemberQ[$ContextPath, "AsymptoticAnalysis`"], MemberQ[$Packages, "AsymptoticInverse`"],
    Names["AsymptoticInverse`*"], Names["AsymptoticInverse`Private`*"]},
  {"Global`", True, True, False, {}, {}},
  TestID -> "package-identity-new-context-without-legacy-public-or-private-symbols"]

VerificationTest[
  Module[{x, y, s},
    s = AsymptoticAnalysis`AsymptoticInverse[x + x^2, {x, 0}, {y, 4}];
    Context[AsymptoticInverse] === "AsymptoticAnalysis`" &&
      Head[s] === GeneralizedSeries && Normal[s] === y - y^2 + 2 y^3],
  True,
  TestID -> "package-identity-qualified-public-inverse-retains-name-and-behavior"]

VerificationTest[
  Module[{x, s, text},
    s = AsymptoticExpansion[Exp[x], {x, 0, 3}];
    text = Block[{$ContextPath = {"System`", "Global`"}},
      ToString[s, InputForm, PageWidth -> Infinity]];
    StringContainsQ[text, "AsymptoticAnalysis`GeneralizedSeries"] &&
      StringFreeQ[text, "AsymptoticInverse`"] && ToExpression[text, InputForm] === s &&
      ToExpression[ToBoxes[s, StandardForm], StandardForm] === s &&
      Normal[s] === 1 + x + x^2/2],
  True, TestID -> "package-identity-serialized-and-formatted-series-roundtrip-in-new-context"]

VerificationTest[
  Module[{x, y, original, refined, fresh},
    original = AsymptoticInverse[x + x^2, {x, 0}, {y, 3}];
    refined = SeriesRefine[original, 5];
    fresh = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
    MatchQ[refined, _GeneralizedSeries] && Normal[refined] === Normal[fresh] &&
      refined["Remainder"] === fresh["Remainder"] &&
      FreeQ[refined, symbol_Symbol /; StringStartsQ[Context[symbol], "AsymptoticInverse`"]]],
  True, TestID -> "package-identity-refinement-replays-in-renamed-context"]
