(* Mathics3 compatibility is isolated in its own context.  The official
   Wolfram evaluator never adds this context to its search path, so the
   streamed kernel sources retain their original System symbols there.
   These are deliberately bounded helpers for the forms used by this package,
   not replacements installed on Mathics' global System definitions. *)

Begin["AsymptoticAnalysis`Mathics`"];

ClearAll[AsymptoticAnalysis`Mathics`Module,
  AsymptoticAnalysis`Mathics`Return,
  AsymptoticAnalysis`Mathics`Lookup,
  AsymptoticAnalysis`Mathics`FailureQ,
  AsymptoticAnalysis`Mathics`MissingQ,
  AsymptoticAnalysis`Mathics`KeyExistsQ,
  AsymptoticAnalysis`Mathics`AssociateTo,
  AsymptoticAnalysis`Mathics`KeyDrop,
  AsymptoticAnalysis`Mathics`KeyTake,
  AsymptoticAnalysis`Mathics`DeleteDuplicatesBy,
  AsymptoticAnalysis`Mathics`FirstPosition,
  AsymptoticAnalysis`Mathics`RootReduce,
  AsymptoticAnalysis`Mathics`ToRadicals,
  AsymptoticAnalysis`Mathics`Refine];

$contextPathBeforeCompatibility = $ContextPath;
$ContextPath = Prepend[DeleteCases[$ContextPath, "AsymptoticAnalysis`Mathics`"],
  "AsymptoticAnalysis`Mathics`"];

(* Mathics 10 implements Return[value] but not Return[value, Module].
   Moreover, its ordinary Return is intercepted by loop constructs.  A
   distinct dynamic tag per invocation implements the package's explicit
   Module destination across loops, recursion, and nested helper calls.
   Wrapping the whole native Module also covers local initializers. *)
SetAttributes[Module, HoldAll];
Module[locals_List, body_] := System`Block[
  {$moduleReturnTag = System`Unique["mathicsModuleReturn$"]},
  System`Catch[System`Module[locals, body], $moduleReturnTag]];
Return[value_, Module] := System`Throw[value, $moduleReturnTag];
Return[value_, System`Module] := System`Throw[value, $moduleReturnTag];
Return[value_] := System`Throw[value, $moduleReturnTag];
Return[] := System`Throw[Null, $moduleReturnTag];

FailureQ[e_] := MatchQ[e, _System`Failure];
MissingQ[e_] := MatchQ[e, _System`Missing];
KeyExistsQ[a_Association, key_] := Or @@ (SameQ[#, key] & /@ Keys[a]);

(* Hold the default through argument evaluation; it must not run for a
   present key. Share one lazy value across all missing results of a call,
   including lists of keys or associations. Mathics 10's built-in Lookup
   rewrites to an unevaluated FirstCase and does not implement these forms.
   Association application supplies ordinary value semantics. *)
SetAttributes[Lookup, HoldAllComplete];
Lookup[a_, key_] := lookupRequired[a, key];
Lookup[a_, key_, default_] := System`Module[{lookupDefault},
  lookupDefault := lookupDefault = default;
  lookupValue[a, key, HoldComplete[lookupDefault]]];
(* An empty first list is an empty rule collection in Wolfram Lookup, not a
   list with zero associations. Its scalar lookup therefore uses the default. *)
lookupRequired[{}, key_] := lookupRequired[<||>, key];
lookupRequired[a_Association, keys_List] := lookupRequired[a, #] & /@ keys;
lookupRequired[a_Association, key_] :=
  If[KeyExistsQ[a, key], a[key], Missing["KeyAbsent", key]];
lookupRequired[associations_List, key_] := lookupRequired[#, key] & /@ associations;
lookupValue[{}, key_, default_HoldComplete] := lookupValue[<||>, key, default];
lookupValue[a_Association, keys_List, default_HoldComplete] :=
  lookupValue[a, #, default] & /@ keys;
lookupValue[a_Association, key_, default_HoldComplete] :=
  If[KeyExistsQ[a, key], a[key], ReleaseHold[default]];
lookupValue[associations_List, key_, default_HoldComplete] :=
  lookupValue[#, key, default] & /@ associations;

SetAttributes[AssociateTo, HoldFirst];
AssociateTo[a_, rules_] := (a = Join[a, Association[rules]]);
KeyDrop[a_Association, key_] := KeyDrop[a, {key}];
KeyDrop[a_Association, keys_List] := Association @@ Select[List @@ a,
  Function[rule, ! Or @@ (SameQ[First[rule], #] & /@ keys)]];
KeyTake[a_Association, key_] := KeyTake[a, {key}];
KeyTake[a_Association, keys_List] := Association @@ Flatten[
  Function[key, Select[List @@ a, SameQ[First[#], key] &]] /@ keys, 1];
DeleteDuplicatesBy[items_List, function_] := First /@ GatherBy[items, function];

(* Mathics FirstPosition compares exact expressions instead of matching its
   pattern and does not accept Heads.  Position supports the required forms.
   Keep a potentially effectful default held until there is no match. *)
SetAttributes[FirstPosition, HoldRest];
FirstPosition[expr_, pattern_] :=
  firstPosition[expr, pattern, HoldComplete[Missing["NotFound"]], {0, Infinity}, True];
(* A Heads option in the third slot is an option, not a default value (W4-06). *)
FirstPosition[expr_, pattern_, Heads -> heads_] :=
  firstPosition[expr, pattern, HoldComplete[Missing["NotFound"]], {0, Infinity}, heads];
FirstPosition[expr_, pattern_, default_] :=
  firstPosition[expr, pattern, HoldComplete[default], {0, Infinity}, True];
FirstPosition[expr_, pattern_, default_, levels_, opts : OptionsPattern[]] :=
  firstPosition[expr, pattern, HoldComplete[default], levels, OptionValue[Heads]];
Options[FirstPosition] = {Heads -> True};
firstPosition[expr_, pattern_, default_HoldComplete, levels_, heads_] := System`Module[{positions},
  positions = Position[expr, pattern, levels, Heads -> heads];
  If[positions === {}, ReleaseHold[default], First[positions]]];

(* The exact expression is retained when Mathics lacks Wolfram's algebraic
   number normalizer/radical converter.  Simplify can reduce elementary exact
   radicals without introducing approximate numbers or asserting a new root. *)
RootReduce[e_] := AsymptoticAnalysis`Mathics`Simplify[e];
ToRadicals[e_] := e;
Refine[e_, ass_] := AsymptoticAnalysis`Mathics`Simplify[e, ass];
Refine[e_] := AsymptoticAnalysis`Mathics`Simplify[e];

$ContextPath = $contextPathBeforeCompatibility;
End[];

If[StringQ[$Version] && StringContainsQ[$Version, "Mathics"],
  (* Names occurring in public inputs/options must resolve identically in the
     caller and the package even when Mathics has no implementation for them.
     Creating inert System names does not claim that those kernels exist. *)
  Scan[Symbol, {"System`SeriesTermGoal", "System`BarnesG", "System`LogBarnesG",
    "System`Asymptotic", "System`Failure", "System`FunctionDomain",
    "System`Reduce", "System`Resolve", "System`ForAll", "System`Exists",
    "System`Inactive", "System`Activate", "System`Algebraics",
    "System`InverseFunction", "System`WorkingPrecision", "System`\[FormalL]", "System`Glaisher",
    "System`BetaRegularized", "System`CosIntegral", "System`CoshIntegral",
    "System`DawsonF", "System`EllipticTheta", "System`Erfi",
    "System`GammaRegularized", "System`HurwitzZeta", "System`Hypergeometric0F1",
    "System`Hypergeometric0F1Regularized", "System`Hypergeometric1F1Regularized",
    "System`Hypergeometric2F1Regularized", "System`HypergeometricPFQRegularized",
    "System`InverseGammaRegularized", "System`JacobiAmplitude", "System`JacobiCN",
    "System`JacobiDN", "System`JacobiSN", "System`JacobiZeta", "System`LogIntegral",
    "System`ParabolicCylinderD", "System`SinIntegral", "System`SinhIntegral",
    "System`SpheroidalPS", "System`SpheroidalQS", "System`WhittakerM", "System`WhittakerW"}];
  $ContextPath = Prepend[DeleteCases[$ContextPath, "AsymptoticAnalysis`Mathics`"],
    "AsymptoticAnalysis`Mathics`"]];
