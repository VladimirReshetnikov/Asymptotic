(* Mathics 10's two-argument simplifiers call an expression-only operation on
   the assumptions. Atomic True/False therefore raise a Python exception.
   A list of assumptions has the same logical meaning and keeps evaluation
   inside the kernel's supported representation. These definitions are only
   selected through the Mathics context during package loading. *)

ClearAll[AsymptoticAnalysis`Mathics`Simplify,
  AsymptoticAnalysis`Mathics`FullSimplify,
  AsymptoticAnalysis`Mathics`Series,
  AsymptoticAnalysis`Mathics`Limit];

AsymptoticAnalysis`Mathics`Simplify[e_] :=
  AsymptoticAnalysis`Mathics`Simplify[e, $Assumptions];
AsymptoticAnalysis`Mathics`Simplify[e_, ass_] :=
  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[
    System`Simplify[AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[e, ass], {ass}], ass];
AsymptoticAnalysis`Mathics`FullSimplify[e_] :=
  AsymptoticAnalysis`Mathics`FullSimplify[e, $Assumptions];
AsymptoticAnalysis`Mathics`FullSimplify[e_, ass_] :=
  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[
    System`FullSimplify[AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[e, ass], {ass}], ass];

(* Mathics' Series does not accept Assumptions as an option. Retain the
   assumptions as an evaluation scope for the package's local Taylor calls. *)
AsymptoticAnalysis`Mathics`Series[e_, spec_List, Assumptions -> ass_] :=
  Block[{$Assumptions = ass}, System`Series[e, spec]];
AsymptoticAnalysis`Mathics`Series[e_, spec_List] := System`Series[e, spec];

(* Direction strings and the Assumptions option are absent from Mathics'
   Limit interface. The supported integer directions have the same meaning:
   -1 approaches from above and +1 from below. *)
Options[AsymptoticAnalysis`Mathics`Limit] =
  {Direction -> Automatic, Assumptions :> $Assumptions};
AsymptoticAnalysis`Mathics`Limit[e_, spec_Rule, opts : OptionsPattern[]] :=
  Block[{$Assumptions = OptionValue[Assumptions]},
    System`Limit[e, spec, Direction -> Replace[OptionValue[Direction],
      {"FromAbove" -> -1, "FromBelow" -> 1, Automatic -> 1}]]];
