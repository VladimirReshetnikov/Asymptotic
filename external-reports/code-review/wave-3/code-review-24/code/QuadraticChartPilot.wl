(* Restricted candidate for the audited reciprocal-square coordinate.
   This is not a general branch solver. Load the package first.
   It installs private DownValues and is intended only for a disposable kernel.
   Positive-branch mechanism was exercised in the audit; the complete installer,
   its negative-branch case and its uninstaller require the supplied tests. *)
BeginPackage["AsymptoticAudit`"];
InstallQuadraticChartPilot::usage = "InstallQuadraticChartPilot[] installs a restricted, domain-checked inverse chart for w=1/x^2 in a disposable kernel.";
UninstallQuadraticChartPilot::usage = "UninstallQuadraticChartPilot[] restores the saved private DownValues. Do not mutate those definitions between installation and restoration.";
Begin["`Private`"];
$savedChartDefinitions = None;
InstallQuadraticChartPilot[] := Module[{},
  If[DownValues[AsymptoticAnalysis`Private`seriesCoordinateRule] === {},
    Return[Failure["PackageNotLoaded", <|"MessageTemplate" -> "Load the pinned package before installing the pilot."|>]]];
  If[$savedChartDefinitions =!= None,
    Return[Failure["AlreadyInstalled", <|"MessageTemplate" -> "The pilot is already installed."|>]]];
  $savedChartDefinitions = DownValues[AsymptoticAnalysis`Private`seriesCoordinateRule];
  AsymptoticAnalysis`Private`seriesCoordinateRule[d_Association, u_] /;
    d["ScaleVariable"] === 1/d["Variable"]^2 &&
    TrueQ[Quiet[TimeConstrained[
      FullSimplify[d["Variable"] > 0, d["Assumptions"] && d["Domain"]], 3, False]]] :=
      d["Variable"] -> 1/Sqrt[u];
  AsymptoticAnalysis`Private`seriesCoordinateRule[d_Association, u_] /;
    d["ScaleVariable"] === 1/d["Variable"]^2 &&
    TrueQ[Quiet[TimeConstrained[
      FullSimplify[d["Variable"] < 0, d["Assumptions"] && d["Domain"]], 3, False]]] :=
      d["Variable"] -> -1/Sqrt[u];
  True
];
UninstallQuadraticChartPilot[] := If[$savedChartDefinitions === None,
  Failure["NotInstalled", <|"MessageTemplate" -> "No saved definitions exist."|>],
  DownValues[AsymptoticAnalysis`Private`seriesCoordinateRule] = $savedChartDefinitions;
  $savedChartDefinitions = None; True];
End[];
EndPackage[];
