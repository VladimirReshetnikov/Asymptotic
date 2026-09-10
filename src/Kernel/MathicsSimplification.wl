(* Mathics 10's two-argument simplifiers call an expression-only operation on
   the assumptions. Atomic True/False therefore raise a Python exception.
   A list of assumptions has the same logical meaning and keeps evaluation
   inside the kernel's supported representation. These definitions are only
   selected through the Mathics context during package loading. *)

ClearAll[AsymptoticAnalysis`Mathics`Simplify,
  AsymptoticAnalysis`Mathics`FullSimplify,
  AsymptoticAnalysis`Mathics`Series,
  AsymptoticAnalysis`Mathics`Limit,
  AsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ,
  AsymptoticAnalysis`Mathics`mathicsSimplify];

(* Mathics can cancel an unknown complex offset in a real inequality before
   checking its operands' domains (a+u>a becomes u>0). Keep unresolved
   ordered predicates out of native simplification until every operand is
   proved finite real. The exact assumption callback can still simplify
   other parts and prove predicates directly. *)
AsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ[e_, ass_] := Module[
  {facts, predicates},
  predicates = Cases[e, _Less | _LessEqual | _Greater | _GreaterEqual | _Inequality,
    {0, Infinity}];
  If[predicates === {}, Return[True, Module]];
  facts = AsymptoticAnalysis`Mathics`mathicsAssumptionFacts[ass];
  And @@ (Function[predicate,
    And @@ (TrueQ[AsymptoticAnalysis`Mathics`mathicsRealProof[#, facts, 24]] & /@
      If[Head[predicate] === Inequality, (List @@ predicate)[[1 ;; -1 ;; 2]],
        List @@ predicate])] /@ predicates)];
AsymptoticAnalysis`Mathics`mathicsSimplify[e_, ass_, simplifier_] := Module[{prepared},
  (* Mathics sends ProductLog[k,z] to SymPy as LambertW[k,z], although
     SymPy expects LambertW[z,k]. It can therefore turn a satisfiable exact
     equality into False. Keep retained two-argument forms out of both the
     assumption walker and native simplifier, including in assumptions.
     Package-created principal values already use ProductLog[z]. Values
     corrupted by caller-side evaluation cannot be reconstructed here. *)
  If[! FreeQ[{e, ass}, HoldPattern[System`ProductLog[_, _]]],
    Return[e, Module]];
  prepared = AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[e, ass];
  If[! AsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ[prepared, ass],
    Return[prepared, Module]];
  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[simplifier[prepared, {ass}], ass]];

AsymptoticAnalysis`Mathics`Simplify[e_] :=
  AsymptoticAnalysis`Mathics`Simplify[e, $Assumptions];
AsymptoticAnalysis`Mathics`Simplify[e_, ass_] :=
  AsymptoticAnalysis`Mathics`mathicsSimplify[e, ass, System`Simplify];
AsymptoticAnalysis`Mathics`FullSimplify[e_] :=
  AsymptoticAnalysis`Mathics`FullSimplify[e, $Assumptions];
AsymptoticAnalysis`Mathics`FullSimplify[e_, ass_] :=
  AsymptoticAnalysis`Mathics`mathicsSimplify[e, ass, System`FullSimplify];

(* Mathics' Series does not accept Assumptions as an option. Retain the
   assumptions as an evaluation scope for the package's local Taylor calls. *)
AsymptoticAnalysis`Mathics`Series[e_, spec_List, Assumptions -> ass_] :=
  AsymptoticAnalysis`Mathics`mathicsTaylorSeries[e, spec, ass];
AsymptoticAnalysis`Mathics`Series[e_, spec_List] :=
  AsymptoticAnalysis`Mathics`mathicsTaylorSeries[e, spec, $Assumptions];

(* Direction strings and the Assumptions option are absent from Mathics'
   Limit interface. The supported integer directions have the same meaning:
   -1 approaches from above and +1 from below. *)
Options[AsymptoticAnalysis`Mathics`Limit] =
  {Direction -> Automatic, Assumptions :> $Assumptions};
(* An omitted or Automatic direction at a finite point is two-sided, as in
   the official kernel: both one-sided limits are taken and must agree, and
   disagreeing sides give Indeterminate rather than the value from one side
   (W4-05). An unresolved side stays unresolved. *)
AsymptoticAnalysis`Mathics`Limit[e_, spec_Rule, opts : OptionsPattern[]] :=
  Block[{$Assumptions = OptionValue[Assumptions]}, System`Module[{direction = OptionValue[Direction], above, below},
    Which[
      MemberQ[{"FromAbove", -1}, direction], System`Limit[e, spec, Direction -> -1],
      MemberQ[{"FromBelow", 1}, direction], System`Limit[e, spec, Direction -> 1],
      MemberQ[{Infinity, -Infinity}, spec[[2]]], System`Limit[e, spec],
      True,
        above = System`Limit[e, spec, Direction -> -1];
        below = System`Limit[e, spec, Direction -> 1];
        Which[! FreeQ[{above, below}, System`Limit], System`Limit[e, spec],
          above === below, above,
          TrueQ[AsymptoticAnalysis`Mathics`Simplify[above == below]], above,
          True, Indeterminate]]]];
