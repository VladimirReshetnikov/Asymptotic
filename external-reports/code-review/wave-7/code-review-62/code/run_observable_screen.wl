(* Run in a fresh session after setting $AuditPackage to a local package file.
   This assembled diagnostic is supplied, not claimed to have run wholesale.
   An earlier baseline screen with the same function/observable grid checked
   41 eligible cases with no discrepancy in Wolfram 15.0.0. *)
If[! StringQ[$AuditPackage], Print["Set $AuditPackage first."]; Abort[]];
Get[$AuditPackage];
Clear[screenX, screenZ];
screenFunctions = {1 + screenX + screenX^2, Exp[screenX], 1/(1-screenX),
  Sin[screenX], Log[1+screenX], screenX/(1+screenX)};
screenObservables = {screenZ^2, 1/screenZ, Sqrt[screenZ], Exp[screenZ],
  Sin[screenZ], Cos[screenZ], Log[screenZ]};
screenRows = {};
Do[
  screenInput = AsymptoticAnalysis`AsymptoticExpansion[ff,
    {screenX, 0, 4}, "Backend" -> "Package"];
  Do[
    screenOutput = AsymptoticAnalysis`SeriesObservable[screenInput, gg, screenZ];
    screenStatus = "NotAssessed"; screenResidual = Missing["NoEligibleJet"];
    screenPower = Missing["NoEligibleJet"];
    If[Head[screenOutput] === AsymptoticAnalysis`GeneralizedSeries,
      screenPower = screenOutput["RemainderPower"];
      If[NumberQ[screenPower] && TrueQ[0 < screenPower < 20],
        screenResidual = Quiet[Normal[Series[(gg /. screenZ -> ff) - Normal[screenOutput],
          {screenX, 0, Ceiling[screenPower] - 1}]]];
        screenStatus = Which[screenResidual === 0, "Pass",
          ! FreeQ[screenResidual, _Series | _SeriesData], "OracleUnavailable",
          True, "Discrepancy"]]];
    AppendTo[screenRows, <|"Function" -> ff, "Observable" -> gg,
      "Status" -> screenStatus, "RemainderPower" -> screenPower,
      "Residual" -> screenResidual, "ResultHead" -> Head[screenOutput]|>],
    {gg, screenObservables}],
  {ff, screenFunctions}];
screenResult = <|"Kernel" -> $Version, "Attempted" -> Length[screenRows],
  "Passed" -> Length[Select[screenRows, #["Status"] === "Pass" &]],
  "Discrepancies" -> Length[Select[screenRows, #["Status"] === "Discrepancy" &]],
  "Unassessed" -> Length[Select[screenRows, MemberQ[{"NotAssessed", "OracleUnavailable"}, #["Status"]] &]],
  "Rows" -> screenRows|>;
Print[InputForm[screenResult]];
screenResult
