(* Mathics 10's two-argument simplifiers call an expression-only operation on
   the assumptions. Atomic True/False therefore raise a Python exception.
   A list of assumptions has the same logical meaning and keeps evaluation
   inside the kernel's supported representation. These definitions are only
   selected through the Mathics context during package loading. *)

AsymptoticAnalysis`Mathics`Simplify[e_] := System`Simplify[e];
AsymptoticAnalysis`Mathics`Simplify[e_, ass_] := System`Simplify[e, {ass}];
AsymptoticAnalysis`Mathics`FullSimplify[e_] := System`FullSimplify[e];
AsymptoticAnalysis`Mathics`FullSimplify[e_, ass_] := System`FullSimplify[e, {ass}];

(* Mathics' Series does not accept Assumptions as an option. Retain the
   assumptions as an evaluation scope for the package's local Taylor calls. *)
AsymptoticAnalysis`Mathics`Series[e_, spec_List, Assumptions -> ass_] :=
  Block[{$Assumptions = ass}, System`Series[e, spec]];
AsymptoticAnalysis`Mathics`Series[e_, spec_List] := System`Series[e, spec];
