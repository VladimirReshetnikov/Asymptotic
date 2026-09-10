
(* Incremental native-boundary audit candidate, pinned to 6687962f3c85.
   Only changed defaults are appended: appending every native default would
   force native routing and destroy the established Automatic policy. *)
$nativeBoundaryExpansionDefaults = Options[AsymptoticExpansion];
$nativeBoundaryAliasDefaults = Options[AsymptoticExpand];
nativeBoundaryChangedDefaults[public_] := Module[{baseline},
  baseline = If[public === AsymptoticExpand,
    $nativeBoundaryAliasDefaults, $nativeBoundaryExpansionDefaults];
  Select[Options[public], Function[rule,
    ! AnyTrue[baseline, Function[old, SameQ[old, rule]]]]]];
nativeBoundaryWithDefaults[held_HoldComplete, public_] :=
  nativeHeldJoin[Prepend[HoldComplete /@ nativeBoundaryChangedDefaults[public], held]];

(* Classify option spellings without evaluating values or interning names. *)
nativeBoundaryOptionName[HoldComplete[key_Symbol]] := SymbolName[Unevaluated[key]];
nativeBoundaryOptionName[HoldComplete[key_String]] := key;
nativeBoundaryOptionName[_] := Missing["NonstandardOptionKey"];
$nativeBoundaryOptionKeys = Association[Map[Function[key,
  nativeBoundaryOptionName[key] -> key],
  HoldComplete /@ (First /@ Options[AsymptoticExpansion])]];
nativeBoundaryCanonicalKey[key_HoldComplete] :=
  Lookup[$nativeBoundaryOptionKeys, nativeBoundaryOptionName[key], key];

(* Parse the positional specification prefix, not a symbol-name whitelist.
   This is a bounded grammar repair, not a claim of full native coverage. *)
nativeBoundarySpecificationStartQ[HoldComplete[{(_Symbol | _List), _, ___}]] := True;
nativeBoundarySpecificationStartQ[HoldComplete[(Rule | RuleDelayed)[(_Symbol | _List), _]]] := True;
nativeBoundarySpecificationStartQ[_] := False;
nativeBoundaryNextSpecificationQ[HoldComplete[{(_Symbol | _List), _, ___}]] := True;
nativeBoundaryNextSpecificationQ[_] := False;
nativeBoundarySplit[request_HoldComplete] := Module[
  {tail = nativeTailArguments[request], count = 0},
  If[tail =!= {} && nativeBoundarySpecificationStartQ[First[tail]],
    count = 1;
    While[count < Length[tail] && nativeBoundaryNextSpecificationQ[tail[[count + 1]]], count++]];
  {Take[tail, count], Drop[tail, count]}];
nativeBoundarySpecifications[request_HoldComplete] := First[nativeBoundarySplit[request]];
nativeBoundaryOptions[request_HoldComplete] := Last[nativeBoundarySplit[request]];
