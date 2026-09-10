(* Focused coefficient capability, mathematical coefficients and stored assumptions. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewInverseCoefficientModel.wlt", "AsymptoticInverse.wlt",
   "ExpandedInputs.wlt", "ReviewAssumptions.wlt", "NativePresentation.wlt"},
 "Output" -> "inverse-coefficient-model-tests.json", "Timeout" -> 240,
 "Scope" -> "Five selected coefficient-model, ordinary inverse, extended input, stored-assumption and native-contract files; no full package suite."|>]];
