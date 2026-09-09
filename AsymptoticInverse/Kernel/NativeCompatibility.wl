(* Native delegation is a distinct result contract. Keep the complete native
   call held until it is released to the selected built-in. In particular,
   do not resolve native delayed options for a second metadata lookup. *)

Options[AsymptoticExpansion] = DeleteDuplicatesBy[Join[
  Options[AsymptoticExpansion], {"Backend" -> Automatic},
  Options[System`Series], Options[System`Asymptotic]], First];
Options[AsymptoticExpand] = Options[AsymptoticExpansion];
SetAttributes[AsymptoticExpand, HoldAllComplete];
AsymptoticExpand[args___] := AsymptoticExpansion[args];

nativeSeriesQ[GeneralizedSeries[a_Association]] := Lookup[a, "Kind", None] === "Native";
nativeSeriesQ[_] := False;
requireAnalyticSeries[s_] := If[nativeSeriesQ[s],
  fail["NativeSeriesContract", "This operation requires a package analytic remainder contract. Use NativeResult for native formal operations."]];
nativeSeriesValue[a_Association, value_] := catch[Module[{variable = Lookup[a, "Variable", None]},
  If[! MatchQ[variable, _Symbol], fail["NativeVariables",
    "Numerical application requires one identified expansion variable. Substitute into Normal[result] explicitly for other native specifications."]];
  a["Expression"] /. variable -> value]];

nativeHeldArguments[held_HoldComplete] := Cases[held, item_ :> HoldComplete[item], {1}];
nativeHeldJoin[items_List] := Fold[
  Function[{left, right}, Replace[{left, right},
    {HoldComplete[a___], HoldComplete[b___]} :> HoldComplete[a, b]]], HoldComplete[], items];

(* Only option containers are traversed. A rule inside the source or inside
   another option's value is data, not a selector for this wrapper. *)
nativeOptionTreeQ[HoldComplete[_Rule | _RuleDelayed]] := True;
nativeOptionTreeQ[HoldComplete[(List | Sequence)[args___]]] :=
  And @@ (nativeOptionTreeQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeOptionTreeQ[_] := False;
nativeSelectorValues[HoldComplete[(Rule | RuleDelayed)["Backend", value_]]] := {HoldComplete[value]};
nativeSelectorValues[HoldComplete[Sequence[args___]]] :=
  Flatten[nativeSelectorValues /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSelectorValues[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativeSelectorValues /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSelectorValues[_] := {};
nativeStripSelector[HoldComplete[(Rule | RuleDelayed)["Backend", _]]] := HoldComplete[Sequence[]];
nativeStripSelector[HoldComplete[Sequence[args___]]] :=
  Replace[nativeHeldJoin[nativeStripSelector /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[Sequence[items]]];
nativeStripSelector[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[nativeStripSelector /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[List[items]]];
nativeStripSelector[held_] := held;

(* A computed option container needs ordinary argument evaluation once before
   selection. Literal native requests bypass this preparation altogether. *)
nativeComputedArgumentQ[HoldComplete[_Rule | _RuleDelayed | _List]] := False;
nativeComputedArgumentQ[HoldComplete[Sequence[args___]]] :=
  Or @@ (nativeComputedArgumentQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeComputedArgumentQ[_] := True;
SetAttributes[expansionHeldEntry, HoldAllComplete];
expansionHeldEntry[args___] := expansionDispatch[HoldComplete[args], False];
expansionPreparedEntry[original_HoldComplete, args___] := expansionDispatch[HoldComplete[args], True, original];
expansionDispatch[request_HoldComplete, prepared_, original_: Automatic] := Module[
  {parts = nativeHeldArguments[request], values, backend, clean, sourceRequest},
  If[parts === {}, Return[catch[forwardEntry[]], Module]];
  sourceRequest = If[original === Automatic, request, original];
  values = Flatten[nativeSelectorValues /@ Rest[parts], 1];
  If[values === {} && ! TrueQ[prepared] && Or @@ (nativeComputedArgumentQ /@ Rest[parts]),
    Return[Replace[request, HoldComplete[args___] :> expansionPreparedEntry[sourceRequest, args]], Module]];
  backend = If[values === {}, Automatic, ReleaseHold[First[values]]];
  clean = nativeHeldJoin[Prepend[nativeStripSelector /@ Rest[parts], First[parts]]];
  Switch[backend,
    "Series" | "Asymptotic", nativeExpansion[clean, backend, sourceRequest],
    Automatic | "Package", Replace[clean, HoldComplete[args___] :> catch[forwardHeldEntry[args]]],
    _, Failure["InvalidBackend", <|"MessageTemplate" -> "Backend must be Automatic, Package, Series, or Asymptotic.", "Backend" -> backend|>]]];

nativeSpecificationVariable[HoldComplete[{x_Symbol, _, ___}]] := HoldComplete[x];
nativeSpecificationVariable[HoldComplete[(Rule | RuleDelayed)[x_Symbol, _]]] := HoldComplete[x];
nativeSpecificationVariable[_] := Missing["NotLiteralSpecification"];
nativeSpecificationQ[HoldComplete[{_Symbol, _, ___}]] := True;
nativeSpecificationQ[HoldComplete[(Rule | RuleDelayed)[key_Symbol, _]]] :=
  ! MemberQ[First /@ Options[AsymptoticExpansion], Unevaluated[key]];
nativeSpecificationQ[_] := False;
nativePackageOption[HoldComplete[(Rule | RuleDelayed)[key : ("MaxTerms" | "InverseFunctionBranches"), _]]] := {key};
nativePackageOption[held : HoldComplete[(List | Sequence)[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativePackageOption /@ nativeHeldArguments[HoldComplete[args]]];
nativePackageOption[_] := {};

nativeExpansion[request_HoldComplete, backend_, original_HoldComplete] := Module[
  {call, result, normal, parts, specifications, variables, variable, conflicts, ambient},
  parts = Rest[nativeHeldArguments[request]];
  conflicts = Flatten[nativePackageOption /@ parts];
  If[conflicts =!= {}, Return[Failure["NativeOptionConflict", <|
    "MessageTemplate" -> "Package resource budgets and inverse branch selectors require Backend -> Package; native delegation does not implement these options.",
    "Options" -> DeleteDuplicates[conflicts]|>], Module]];
  call = If[backend === "Series",
    Replace[request, HoldComplete[args___] :> HoldComplete[System`Series[args]]],
    Replace[request, HoldComplete[args___] :> HoldComplete[System`Asymptotic[args]]]];
  ambient = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions];
  result = Block[{$Assumptions = ambient}, ReleaseHold[call]];
  normal = Normal[result];
  specifications = Select[parts, nativeSpecificationQ];
  variables = DeleteDuplicates[Cases[nativeSpecificationVariable /@ specifications, _HoldComplete]];
  variable = If[Length[variables] === 1, ReleaseHold[First[variables]], Missing["MultipleOrUnresolvedVariables"]];
  GeneralizedSeries[<|"Kind" -> "Native", "Scale" -> "Native", "NativeBackend" -> backend,
    "NativeResult" -> result, "Expression" -> normal,
    "Remainder" -> Missing["NativeContract"], "Exact" -> Missing["NotEstablished"],
    "RemainderContract" -> If[backend === "Series", "NativeFormalOrder", "NativeAsymptotic"],
    "NativeEvaluationStatus" -> If[FreeQ[result, _System`Series | _System`Asymptotic], "Computed", "Unresolved"],
    "NativeRequest" -> call, "OriginalArguments" -> original,
    "ExpansionSpecifications" -> specifications, "Variable" -> variable,
    "AmbientAssumptions" -> ambient, "Assumptions" -> Missing["NativeContract"],
    "NativeKernelVersion" -> $Version, "NativeSystemID" -> $SystemID|>]];
