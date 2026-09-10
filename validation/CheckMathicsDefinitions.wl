(* Native-only capture for check_mathics_definitions.py.  Paths come from the
   environment; this script never edits the package or System definitions. *)
Begin["MathicsNativeValidation`"];
source = Environment["ASYMPTOTIC_NATIVE_SOURCE"];
output = Environment["ASYMPTOTIC_NATIVE_OUTPUT"];
If[! StringQ[source] || ! StringQ[output] || StringContainsQ[$Version, "Mathics"], Exit[2]];

SetAttributes[definition, HoldAllComplete];
definition[s_] := <|
  "Attributes" -> ToString[Attributes[s], InputForm],
  "Options" -> ToString[Options[s], InputForm],
  "OwnValues" -> ToString[OwnValues[s], InputForm],
  "DownValues" -> ToString[DownValues[s], InputForm],
  "UpValues" -> ToString[UpValues[s], InputForm],
  "SubValues" -> ToString[SubValues[s], InputForm],
  "NValues" -> ToString[NValues[s], InputForm],
  "DefaultValues" -> ToString[DefaultValues[s], InputForm],
  "FormatValues" -> ToString[FormatValues[s], InputForm],
  "Messages" -> ToString[Messages[s], InputForm]|>;
symbolName[s_] := ToExpression[s, InputForm,
  Function[Null, Context[Unevaluated[#]] <> SymbolName[Unevaluated[#]], HoldAllComplete]];
definitions[names_] := Association[(symbolName[#] -> ToExpression[#, InputForm,
  Function[Null, definition[#], HoldAllComplete]]) & /@ names];
packageState[] := Module[{contexts = Contexts["AsymptoticAnalysis`*"]},
  <|"Contexts" -> contexts, "Definitions" -> definitions[
    Union[Flatten[Names[# <> "*"] & /@ contexts]]]|>];
builtinNames = {"System`Times", "System`Check", "System`TimeConstrained",
  "System`ProductLog", "System`Series", "System`Map"};
behavior[] := Module[{x}, {
  System`Times[2, 3] === 6,
  System`Check[2 + 3, $Failed] === 5,
  Quiet[System`Check[1/0, "caught"]] === "caught",
  System`Check[2 + 3, $Failed] === 5,
  System`TimeConstrained[2 + 3, 1, $Failed] === 5,
  System`ProductLog[0, E] === 1,
  Normal[System`Series[Exp[x], {x, 0, 2}]] === 1 + x + x^2/2,
  Module[{empty = {}, f, g},
    System`Map[f, empty] === {} && System`Map[g, empty] === {} && empty === {}]}];

(* Warm these builtins before taking their initial state: lazy native setup
   must not be mistaken for a mutation performed by the package. *)
beforeBehavior = behavior[];
beforeBuiltins = definitions[builtinNames];
beforeContext = $Context; beforePath = $ContextPath; beforePackages = $Packages;
loaded = Check[Get[source]; MemberQ[$Packages, "AsymptoticAnalysis`"], False];
afterLoad = packageState[]; loadBuiltins = definitions[builtinNames];
loadContext = $Context; loadPath = $ContextPath; loadPackages = $Packages;
loadBehavior = behavior[];
reloaded = Check[Get[source]; MemberQ[$Packages, "AsymptoticAnalysis`"], False];
afterReload = packageState[]; reloadBuiltins = definitions[builtinNames];
reloadContext = $Context; reloadPath = $ContextPath; reloadPackages = $Packages;
reloadBehavior = behavior[];
passed = TrueQ[loaded] && TrueQ[reloaded] && afterLoad === afterReload &&
  beforeBuiltins === loadBuiltins === reloadBuiltins &&
  beforeBehavior === loadBehavior === reloadBehavior === ConstantArray[True, 8] &&
  beforeContext === loadContext === reloadContext && loadPath === reloadPath;
exported = Export[output, <|"Kernel" -> $Version, "SystemID" -> $SystemID,
  "PackagePath" -> source, "LoadSucceeded" -> loaded, "ReloadSucceeded" -> reloaded,
  "AfterLoad" -> afterLoad, "AfterReload" -> afterReload,
  "BuiltinsBefore" -> beforeBuiltins, "BuiltinsAfterLoad" -> loadBuiltins,
  "BuiltinsAfterReload" -> reloadBuiltins,
  "BehaviorBefore" -> beforeBehavior, "BehaviorAfterLoad" -> loadBehavior,
  "BehaviorAfterReload" -> reloadBehavior,
  "ContextBefore" -> beforeContext, "ContextAfterLoad" -> loadContext,
  "ContextAfterReload" -> reloadContext, "ContextPathBefore" -> beforePath,
  "ContextPathAfterLoad" -> loadPath, "ContextPathAfterReload" -> reloadPath,
  "AmbientPackagesBefore" -> beforePackages, "AmbientPackagesAfterLoad" -> loadPackages,
  "AmbientPackagesAfterReload" -> reloadPackages, "Passed" -> passed|>, "RawJSON"];
Print["Native capture: ", Length[afterLoad["Definitions"]], " symbols; load/reload and builtin checks: ", passed];
Exit[If[TrueQ[passed] && StringQ[exported], 0, 1]];
