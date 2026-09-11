(* Focused checks for the q-special-function regimes (QSpecialFunctions.wl), with the forward, coordinate, source-chart, native and inverse-expression suites whose dispatch order the module touches. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"QSpecialFunctions.wlt", "GammaForward.wlt", "ExponentialForward.wlt", "SourceCoordinateRegressions.wlt",
   "CoordinateRegressions.wlt", "NativeCompatibility.wlt", "NativeSpecialIngress.wlt", "InverseFunctionExpressions.wlt", "SpecialFunctionForward.wlt"},
 "Output" -> "q-special-functions-tests.json", "Timeout" -> 1800,
 "Scope" -> "Nine selected files: the new q-special-function suite and the Gamma, exponential, source-chart, coordinate, native, native-ingress, inverse-expression and special-function forward suites that share the dispatch order; no full package suite."|>]];
