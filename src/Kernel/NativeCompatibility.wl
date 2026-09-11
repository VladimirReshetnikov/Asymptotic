(* Native delegation is a distinct result contract. Keep the complete native
   call held until it is released to the selected built-in. In particular,
   do not resolve native delayed options for a second metadata lookup. *)

Options[AsymptoticExpansion] = DeleteDuplicatesBy[Join[
  Options[AsymptoticExpansion], {"Backend" -> Automatic},
  Options[System`Series], Options[System`Asymptotic]], First];
Options[AsymptoticExpand] = Options[AsymptoticExpansion];
SetAttributes[AsymptoticExpand, HoldAllComplete];
(* Alias ownership (W3-01): a default configured on the alias itself is
   appended as a trailing selector, so an explicit selector in the call
   still comes first; an alias left at Automatic inherits the primary's
   configured default through the ordinary dispatch. *)
AsymptoticExpand[args___] := With[{configured = OptionValue[AsymptoticExpand, "Backend"]},
  If[configured === Automatic, AsymptoticExpansion[args], AsymptoticExpansion[args, "Backend" -> configured]]];

nativeSeriesQ[GeneralizedSeries[a_Association]] := Lookup[a, "Kind", None] === "Native";
nativeSeriesQ[_] := False;
requireAnalyticSeries[s_] := If[nativeSeriesQ[s],
  fail["NativeSeriesContract", "This operation requires a package analytic remainder contract. Use NativeResult for native formal operations."]];
nativeSeriesValue[a_Association, value_] := catch[Module[{variable = Lookup[a, "Variable", None]},
  If[! MatchQ[variable, _Symbol], fail["NativeVariables",
    "Numerical application requires one identified expansion variable. Substitute into Normal[result] explicitly for other native specifications."]];
  a["Expression"] /. variable -> value]];

nativeHeldArguments[held_HoldComplete] := Cases[held, item_ :> HoldComplete[item], {1}];
nativeSequenceArguments[HoldComplete[Sequence[args___]]] :=
  Flatten[nativeSequenceArguments /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSequenceArguments[held_HoldComplete] := {held};
nativeTailArguments[request_HoldComplete] :=
  Flatten[nativeSequenceArguments /@ Rest[nativeHeldArguments[request]], 1];
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
nativeStripSelector[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] := Module[{items},
  items = DeleteCases[nativeStripSelector /@ nativeHeldArguments[HoldComplete[args]], HoldComplete[Sequence[]]];
  If[items === {} && nativeHeldArguments[HoldComplete[args]] =!= {}, Return[HoldComplete[Sequence[]], Module]];
  Replace[nativeHeldJoin[items], HoldComplete[kept___] :> HoldComplete[List[kept]]]];
nativeStripSelector[held_] := held;

(* Resolve computed trailing argument containers before selecting a backend,
   keeping the source held for that backend's evaluation context. Literal
   native requests bypass this preparation altogether. *)
(* A rule whose key is a symbol with an own value is a computed option
   (key = "Backend"; f[..., key -> "Series"]) and is resolved once on the
   prepared path like a computed container (W3-02). *)
nativeComputedArgumentQ[HoldComplete[(Rule | RuleDelayed)[key_, _]]] :=
  If[MatchQ[Hold[key], Hold[_Symbol]], OwnValues[key] =!= {}, False];
nativeComputedArgumentQ[HoldComplete[{x_Symbol, _, ___}]] /; OwnValues[x] === {} := False;
nativeComputedArgumentQ[HoldComplete[List[args___]]] :=
  Or @@ (nativeComputedArgumentQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeComputedArgumentQ[HoldComplete[Sequence[args___]]] :=
  Or @@ (nativeComputedArgumentQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeComputedArgumentQ[_] := True;
(* String-named options accept their symbol spellings (Backend -> "Series",
   MaxTerms -> 5): the held key is rewritten to the string without
   evaluating the option value, so every later classifier sees one
   identity (W3-02). *)
$nativeStringOptionNames = {"Backend", "MaxTerms", "InverseFunctionBranches"};
nativeCanonicalKey[HoldComplete[(head : Rule | RuleDelayed)[key_Symbol, value_]]] /;
    OwnValues[key] === {} && MemberQ[$nativeStringOptionNames, SymbolName[Unevaluated[key]]] :=
  With[{name = SymbolName[Unevaluated[key]]}, HoldComplete[head[name, value]]];
nativeCanonicalKey[HoldComplete[Sequence[args___]]] :=
  Replace[nativeHeldJoin[nativeCanonicalKey /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[Sequence[items]]];
nativeCanonicalKey[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[nativeCanonicalKey /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[List[items]]];
nativeCanonicalKey[held_] := held;

(* An unknown symbol-keyed rule is a specification only in the rule form
   f[expr, x -> x0, ...] and only for the first such rule; after a list
   specification or a first rule specification it is an unknown option
   and is refused instead of silently becoming a native specification. *)
nativeKnownOptionQ[HoldComplete[key_]] := MemberQ[First /@ Options[AsymptoticExpansion], Unevaluated[key]];
nativeUnknownOptions[parts_List] := Module[{tail = Rest[parts], specificationSeen = False, unknown = {}, scan},
  scan[HoldComplete[{_Symbol, _, ___}]] := (specificationSeen = True);
  scan[held : HoldComplete[(Rule | RuleDelayed)[key_Symbol, _]]] := Which[
    nativeKnownOptionQ[HoldComplete[key]], Null,
    specificationSeen, AppendTo[unknown, HoldComplete[key]],
    True, specificationSeen = True];
  scan[held : HoldComplete[(List | Sequence)[args___]]] /; nativeOptionTreeQ[held] :=
    Scan[scan, nativeHeldArguments[HoldComplete[args]]];
  scan[_] := Null;
  Scan[scan, tail];
  unknown];

(* The configured default of the primary applies to omitted selectors of
   public requests (W3-01); internal replays select the package engine
   explicitly and never inherit a user-selected native default. *)
nativeConfiguredBackend[] := OptionValue[AsymptoticExpansion, "Backend"];
SetAttributes[expansionHeldEntry, HoldAllComplete];
expansionHeldEntry[args___] := expansionDispatch[HoldComplete[args], False];
expansionPreparedEntry[original_HoldComplete, source_HoldComplete, args___] :=
  expansionDispatch[nativeHeldJoin[{source, HoldComplete[args]}], True, original];
expansionDispatch[request0_HoldComplete, prepared_, original_: Automatic] := Module[
  {request, parts, values, backend, clean, sourceRequest, unknown},
  parts = nativeHeldArguments[request0];
  If[parts === {}, Return[catch[forwardEntry[]], Module]];
  parts = Prepend[nativeCanonicalKey /@ Rest[parts], First[parts]];
  request = nativeHeldJoin[parts];
  sourceRequest = If[original === Automatic, request0, original];
  values = Flatten[nativeSelectorValues /@ Rest[parts], 1];
  If[! TrueQ[prepared] && Or @@ (nativeComputedArgumentQ /@ Rest[parts]),
    Return[Replace[request, HoldComplete[f_, args___] :>
      expansionPreparedEntry[sourceRequest, HoldComplete[f], args]], Module]];
  unknown = nativeUnknownOptions[parts];
  If[unknown =!= {}, Return[Failure["UnknownOption", <|
    "MessageTemplate" -> "These trailing rules are neither options of AsymptoticExpansion nor its native backends nor the single rule-form specification.",
    "Options" -> unknown|>], Module]];
  backend = If[values === {}, nativeConfiguredBackend[], ReleaseHold[First[values]]];
  clean = nativeHeldJoin[Prepend[nativeStripSelector /@ Rest[parts], First[parts]]];
  Switch[backend,
    "Series" | "Asymptotic", nativeExpansion[clean, backend, sourceRequest],
    Automatic, automaticExpansion[clean, sourceRequest],
    "Package", packageExpansion[clean],
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

nativeOptionKeys[HoldComplete[(Rule | RuleDelayed)[key_, _]]] := {HoldComplete[key]};
nativeOptionKeys[held : HoldComplete[(List | Sequence)[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativeOptionKeys /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeOptionKeys[_] := {};
nativeRequestOptionKeys[request_HoldComplete] := DeleteDuplicates[Flatten[
  nativeOptionKeys /@ Select[nativeTailArguments[request], ! nativeSpecificationQ[#] &], 1]];

$packageExpansionOptionKeys = {HoldComplete[Assumptions], HoldComplete[Direction],
  HoldComplete[SeriesTermGoal], HoldComplete["MaxTerms"], HoldComplete["InverseFunctionBranches"]};
nativeExclusiveOptionKeys[request_HoldComplete] := Complement[
  nativeRequestOptionKeys[request], $packageExpansionOptionKeys];
packageExpansion[request_HoldComplete] := Replace[request,
  HoldComplete[f_, args___] :> catch[packageEvaluatedEntry[forwardHeldExpression[f], args]]];
packageEvaluatedEntry[args___] := packagePreparedExpansion[HoldComplete[args]];
(* A delayed package option is one program: its value is materialized once
   here instead of at every OptionValue read inside the engines (W3-01/02).
   Assumptions keep their own once-only ambient resolution. *)
packageMaterializeOption[HoldComplete[RuleDelayed[key : ("MaxTerms" | SeriesTermGoal | Direction | "InverseFunctionBranches"), value_]]] :=
  With[{materialized = value}, HoldComplete[key -> materialized]];
packageMaterializeOption[HoldComplete[Sequence[args___]]] :=
  Replace[nativeHeldJoin[packageMaterializeOption /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[Sequence[items]]];
packageMaterializeOption[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[packageMaterializeOption /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[List[items]]];
packageMaterializeOption[held_] := held;
packagePreparedExpansion[request_HoldComplete] := Module[{extra = nativeExclusiveOptionKeys[request], parts, materialized},
  If[extra =!= {}, Return[Failure["UnsupportedOption", <|
    "MessageTemplate" -> "The package analytic engine does not implement these native options. Select a compatible native backend or Automatic.",
    "Options" -> extra|>], Module]];
  parts = nativeHeldArguments[request];
  materialized = nativeHeldJoin[Prepend[packageMaterializeOption /@ Rest[parts], First[parts]]];
  Replace[materialized, HoldComplete[args___] :> catch[forwardEntry[args]]]];

(* Native-only options must be dispatched before an otherwise successful
   package calculation can silently ignore them. No backend may discard an
   explicit branch, direction, or resource contract to obtain a result. *)
(* A pure function is a callable-source contract only when it is the source
   itself; a Function consumed inside the source (an applied identity, the
   defining function of a Root object) is ordinary data that both engines
   evaluate, and must not block the native fallback (W3-03). Inverse,
   conditional and retained-object contracts are protected wherever they
   occur. *)
automaticProtectedQ[request_HoldComplete, original_HoldComplete] :=
  MatchQ[First[nativeHeldArguments[original]], HoldComplete[_Function]] ||
  MatchQ[First[nativeHeldArguments[request]], HoldComplete[_Function | _forwardCallable]] ||
  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _ConditionalExpression | _forwardCallable | _GeneralizedSeries | _PowerLogRemainder] ||
  Intersection[nativeRequestOptionKeys[request],
    {HoldComplete[Direction], HoldComplete["MaxTerms"], HoldComplete["InverseFunctionBranches"]}] =!= {};

automaticNativeBackend[request_HoldComplete] := Module[{keys, series, asymptotic, specifications},
  keys = nativeExclusiveOptionKeys[request];
  series = HoldComplete /@ (First /@ Options[System`Series]);
  asymptotic = HoldComplete /@ (First /@ Options[System`Asymptotic]);
  If[keys =!= {}, Return[Which[
    Complement[keys, series] === {}, "Series",
    Complement[keys, asymptotic] === {}, "Asymptotic",
    True, Failure["NativeOptionConflict", <|
      "MessageTemplate" -> "No native backend supports all the supplied option keys.", "Options" -> keys|>]], Module]];
  specifications = Select[nativeTailArguments[request], nativeSpecificationQ];
  If[MatchQ[specifications, {HoldComplete[{_Symbol, _, Infinity | DirectedInfinity[1]}]}],
    Return["Asymptotic", Module]];
  If[MatchQ[specifications, {HoldComplete[{_Symbol, _, _}]}] || Length[specifications] > 1,
    "Series", "Asymptotic"]];

automaticNativeBackends[request_HoldComplete] := Module[{preferred, keys, candidates},
  preferred = automaticNativeBackend[request];
  If[FailureQ[preferred], Return[preferred, Module]];
  keys = nativeRequestOptionKeys[request];
  candidates = Select[{"Series", "Asymptotic"}, Function[backend,
    Complement[keys, HoldComplete /@ (First /@ Options[
      If[backend === "Series", System`Series, System`Asymptotic]])] === {}]];
  DeleteDuplicates[Prepend[DeleteCases[candidates, preferred], preferred]]];

(* Two native attempts share effective common options. In particular, a
   delayed option is not another program to run when retrying the request.
   OptionValue preserves first-option precedence; unused duplicate delayed
   values are not evaluated. Explicit and native-exclusive paths bypass this. *)
automaticNativeOption[HoldComplete[(Rule | RuleDelayed)[key : (Assumptions | SeriesTermGoal), _]], values_] :=
  With[{value = Lookup[values, key]}, HoldComplete[key -> value]];
automaticNativeOption[HoldComplete[Sequence[args___]], values_] :=
  Replace[nativeHeldJoin[automaticNativeOption[#, values] & /@
      nativeHeldArguments[HoldComplete[args]]], HoldComplete[items___] :> HoldComplete[Sequence[items]]];
automaticNativeOption[held : HoldComplete[List[args___]], values_] /; nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[automaticNativeOption[#, values] & /@
      nativeHeldArguments[HoldComplete[args]]], HoldComplete[items___] :> HoldComplete[List[items]]];
automaticNativeOption[held_, _] := held;

automaticNativeSearchRequest[request_HoldComplete] := Module[{keys, options, values = <||>, ambient, parts},
  keys = nativeRequestOptionKeys[request];
  If[Intersection[keys, {HoldComplete[Assumptions], HoldComplete[SeriesTermGoal]}] === {},
    Return[request, Module]];
  options = Flatten[ReleaseHold /@ Select[nativeTailArguments[request],
    nativeOptionTreeQ[#] && ! nativeSpecificationQ[#] &]];
  ambient = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions];
  Block[{$Assumptions = ambient},
    If[MemberQ[keys, HoldComplete[Assumptions]],
      AssociateTo[values, Assumptions -> optionAssumptions[AsymptoticExpansion, options]]];
    If[MemberQ[keys, HoldComplete[SeriesTermGoal]],
      AssociateTo[values, SeriesTermGoal -> OptionValue[AsymptoticExpansion, options, SeriesTermGoal]]]];
  parts = nativeHeldArguments[request];
  nativeHeldJoin[Prepend[automaticNativeOption[#, values] & /@ Rest[parts], First[parts]]]];

nativeEvaluationStatus[result_] := Which[
  ! FreeQ[result, $Aborted], "Aborted",
  ! FreeQ[result, $Failed | _Failure], "Failed",
  ! FreeQ[result, _System`Series | _System`Asymptotic], "Unresolved",
  True, "Computed"];

automaticNativeResult[request_HoldComplete, original_HoldComplete, reason_, failure_: None] := Module[
  {backends, prepared, result, selected = None, attempts = {}, backend, status},
  backends = automaticNativeBackends[request];
  If[FailureQ[backends], Return[backends, Module]];
  prepared = If[Length[backends] > 1, automaticNativeSearchRequest[request], request];
  Do[
    result = nativeExpansion[prepared, backend, original];
    If[selected === None, selected = result];
    status = If[MatchQ[result, _GeneralizedSeries], result["NativeEvaluationStatus"], "Failed"];
    AppendTo[attempts, <|"Backend" -> backend, "EvaluationStatus" -> status,
      "Request" -> If[MatchQ[result, _GeneralizedSeries], result["NativeRequest"], Missing["NotDelegated"]]|>];
    If[MemberQ[{"Computed", "Aborted"}, status], selected = result; Break[]],
    {backend, backends}];
  If[! MatchQ[selected, _GeneralizedSeries], Return[selected, Module]];
  GeneralizedSeries[Join[selected[[1]], <|"BackendSelection" -> Automatic,
    "BackendSelectionReason" -> reason, "OrderConvention" -> "Native",
    "PackageFailure" -> failure, "NativeAttempts" -> attempts|>]]];

(* Ordinary argument evaluation happens once at this entry, under the same
   neutral proof context as the established package entry. The resulting
   source and specifications, not their original programs, are reused after
   a representation failure. Literal explicit native calls never enter it. *)
automaticExpansion[request_HoldComplete, original_HoldComplete] := Module[{extra},
  If[automaticProtectedQ[request, original], Return[packageExpansion[request], Module]];
  extra = nativeExclusiveOptionKeys[request];
  If[extra =!= {}, Return[automaticNativeResult[request, original, "NativeOptions"], Module]];
  Replace[request, HoldComplete[f_, args___] :>
    catch[automaticEvaluatedEntry[original, forwardHeldExpression[f], args]]]];
automaticEvaluatedEntry[original_HoldComplete, args___] :=
  automaticPreparedExpansion[HoldComplete[args], original];

automaticNativeShapeQ[request_HoldComplete] := Module[{parts, specifications, center, order},
  parts = nativeHeldArguments[request];
  specifications = Select[Rest[parts], nativeSpecificationQ];
  If[specifications === {}, Return[False, Module]];
  If[Length[specifications] > 1, Return[True, Module]];
  If[MatchQ[First[parts], HoldComplete[_List]] || ! FreeQ[First[parts], _Inactive], Return[True, Module]];
  If[MatchQ[First[specifications], HoldComplete[_RuleDelayed]], Return[True, Module]];
  center = Replace[First[specifications], {
    HoldComplete[{_, point_, ___}] :> point,
    HoldComplete[(Rule | RuleDelayed)[_, point_]] :> point}];
  If[! MemberQ[{Infinity, -Infinity}, center] && ! exactRealQ[center], Return[True, Module]];
  order = Replace[First[specifications], {HoldComplete[{_, _, n_}] :> n, _ :> Automatic}];
  If[order =!= Automatic, Return[! exactRealQ[order], Module]];
  ! MemberQ[nativeRequestOptionKeys[request], HoldComplete[SeriesTermGoal]] &&
    OptionValue[AsymptoticExpansion, SeriesTermGoal] === Automatic];

(* These tags describe limitations of the real power-log representation.
   Domain, inverse branch, arithmetic budget and invalid-option failures are
   deliberately absent. A failed analytic proof is never reused as native
   analytic evidence. *)
$automaticNativeRepresentationFailures = {"InexactInput", "UnprovedRealCoefficient",
  "UnsupportedInput", "UnsupportedCoefficient", "SymbolicExponent", "ComplexExponent",
  "LogarithmicLeadingPower", "ExponentialScale", "UnsupportedNumber", "InfiniteSeries"};

automaticPreparedExpansion[request_HoldComplete, original_HoldComplete] := Module[
  {parts, specifications, options, keys, ass, dir, goal, limit, branches, packageRequest, replay, result},
  If[automaticProtectedQ[request, original], Return[packageExpansion[request], Module]];
  If[nativeExclusiveOptionKeys[request] =!= {},
    Return[automaticNativeResult[request, original, "NativeOptions"], Module]];
  If[automaticNativeShapeQ[request],
    Return[automaticNativeResult[request, original, "NativeSpecification"], Module]];
  parts = nativeHeldArguments[request];
  specifications = Select[Rest[parts], nativeSpecificationQ];
  options = Flatten[ReleaseHold /@ Select[Rest[parts], ! nativeSpecificationQ[#] &]];
  keys = nativeRequestOptionKeys[request];
  ass = optionAssumptions[AsymptoticExpansion, options];
  dir = OptionValue[AsymptoticExpansion, options, Direction];
  goal = OptionValue[AsymptoticExpansion, options, SeriesTermGoal];
  limit = OptionValue[AsymptoticExpansion, options, "MaxTerms"];
  branches = OptionValue[AsymptoticExpansion, options, "InverseFunctionBranches"];
  (* Native rule-form leading requests admit Automatic and nonpositive
     integer goals even though those are not package nonzero-block counts.
     Reuse the common values already consumed above, including delayed ones. *)
  If[MatchQ[specifications, {HoldComplete[_Rule]}] &&
      MemberQ[keys, HoldComplete[SeriesTermGoal]] &&
      (goal === Automatic || (IntegerQ[goal] && goal <= 0)),
    replay = nativeHeldJoin[Prepend[automaticNativeOption[#, <|
      Assumptions -> ass, SeriesTermGoal -> goal|>] & /@ Rest[parts], First[parts]]];
    Return[automaticNativeResult[replay, original, "NativeSpecification"], Module]];
  packageRequest = nativeHeldJoin[Join[Take[parts, 1], specifications,
    With[{a = ass, d = dir, g = goal, m = limit, b = branches},
      {HoldComplete[Assumptions -> a], HoldComplete[Direction -> d],
        HoldComplete[SeriesTermGoal -> g], HoldComplete["MaxTerms" -> m],
        HoldComplete["InverseFunctionBranches" -> b]}]]];
  result = Replace[packageRequest, HoldComplete[args___] :> catch[forwardEntry[args]]];
  If[! FailureQ[result] || ! MemberQ[$automaticNativeRepresentationFailures, result[[1]]], Return[result, Module]];
  (* Only common native options are replayed. Their delayed values have been
     consumed once above; omitted native defaults remain the native defaults. *)
  replay = nativeHeldJoin[Join[Take[parts, 1], specifications,
    With[{a = ass}, {HoldComplete[Assumptions -> a]}],
    If[MemberQ[keys, HoldComplete[SeriesTermGoal]], With[{g = goal}, {HoldComplete[SeriesTermGoal -> g]}], {}]]];
  automaticNativeResult[replay, original, "PackageRepresentation", result]];

nativeExpansion[request_HoldComplete, backend_, original_HoldComplete] := Module[
  {call, result, normal, parts, specifications, variables, variable, conflicts, ambient},
  parts = nativeTailArguments[request];
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
    "NativeEvaluationStatus" -> nativeEvaluationStatus[result],
    "NativeRequest" -> call, "OriginalArguments" -> original,
    "ExpansionSpecifications" -> specifications, "Variable" -> variable,
    "AmbientAssumptions" -> ambient, "Assumptions" -> Missing["NativeContract"],
    "NativeKernelVersion" -> $Version, "NativeSystemID" -> $SystemID|>]];
