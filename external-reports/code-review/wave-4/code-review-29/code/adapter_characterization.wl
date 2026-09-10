(* UNEXECUTED characterization SPECIFICATIONS, not a passing test report.
   Run in a fresh Mathics kernel after loading the pinned package in a prior
   top-level expression. On Wolfram use the System` control instead. These
   intentionally use private adapter names and do not establish a public
   mathematical result. No MUnit dependency. *)
Clear[auditCount, auditActual, auditDefault, auditNative, auditX, alpha, beta];
auditCount = 0;
auditNative = FirstPosition[{alpha, beta},
  _?((auditCount++; True) &), Missing["NotFound"], {1}, Heads -> False];
Print[InputForm[{"NativeFirstPosition", auditNative, auditCount,
  "Desired" -> {{1}, 1}}]];
If[StringContainsQ[$Version, "Mathics"],
  auditCount = 0;
  auditActual = AsymptoticAnalysis`Mathics`FirstPosition[{alpha, beta},
    _?((auditCount++; True) &), Missing["NotFound"], {1}, Heads -> False];
  Print[InputForm[{"AdapterFirstPosition", auditActual, auditCount,
    "Desired" -> {{1}, 1}}]];
  auditDefault = 0;
  auditActual = AsymptoticAnalysis`Mathics`FirstPosition[{alpha}, alpha,
    (auditDefault++; Missing["NotFound"]), {1}, Heads -> False];
  Print[InputForm[{"LazyDefaultControl", auditActual, auditDefault,
    "Desired" -> {{1}, 0}}]];
  Print[InputForm[{"AdapterLimitDefaultCharacterization",
    AsymptoticAnalysis`Mathics`Limit[Sign[auditX], auditX -> 0],
    "Wolfram15Control" -> Indeterminate}]]
];
