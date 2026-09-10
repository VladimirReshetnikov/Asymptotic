(* UNEXECUTED parser-only integration probe, independent of package loading.
   Use in fresh Wolfram and Mathics kernels. ToExpression's third argument
   requests a held parse; this does not establish ordinary evaluation parity. *)
Begin["ReviewBootstrapSyntax`"];
ClearAll[whole, fragments, parsed];
Print[InputForm[<|"Probe" -> "Association bootstrap syntax", "Version" -> $Version|>]];
whole = "settings = <| counter = 1; \"key\" -> counter |>;";
fragments = {"settings = <| counter = 1;", " \"key\" -> counter |>;"};
parsed = Quiet[Check[ToExpression[whole, InputForm, HoldComplete], $Failed]];
Print[InputForm[<|"Case" -> "WholeAssociation", "Parse" -> parsed|>]];
Do[parsed = Quiet[Check[ToExpression[fragment, InputForm, HoldComplete], $Failed]];
 Print[InputForm[<|"Case" -> "BrokenFragment", "Source" -> fragment, "Parse" -> parsed|>]],
 {fragment, fragments}];
End[];
