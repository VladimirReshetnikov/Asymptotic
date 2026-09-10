(* Focused wave-5 modulus repair (report 37 F01, 42 N01) and its nearest existing suites. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewModulusReality.wlt", "ReviewRealCoefficients.wlt", "SeriesOperations.wlt",
   "ExpandedInputs.wlt", "ReviewObservableIngress.wlt", "SeriesEnvelopeFunctions.wlt",
   "LogarithmicScales.wlt", "CallableExpansion.wlt"},
 "Output" -> "wave5-modulus-tests.json", "Timeout" -> 900,
 "Scope" -> "Eight selected files: the new modulus regressions and the real-coefficient, operation, expanded-input, observable, envelope, logarithmic-scale and forward-expansion suites that share the forward Abs path; no full package suite."|>]];
