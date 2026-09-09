(* Automatic native routing, constraints, and adjacent public entry contracts. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
  "Suites" -> {"NativeAutomatic.wlt", "NativeCompatibility.wlt", "NativeContracts.wlt",
    "NativePresentation.wlt", "ReviewAssumptionReplay.wlt", "ReviewRealCoefficients.wlt",
    "InverseFunctionIntegration.wlt", "InverseFunctionSyntax.wlt"},
  "Output" -> "native-automatic-tests.json", "Timeout" -> 600,
  "Scope" -> "Automatic native routing and representation fallback, evaluation and option constraints, plus selected explicit native, analytic contract, presentation, assumption, coefficient reality and inverse callable regressions. No full package suite or claim of exhaustive native coverage."|>]];
