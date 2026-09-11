(* Loaded last in Private, only on Mathics (wave-4 W4-15). Every late adapter
   rewrites or wraps named package definitions after they were read. This
   module states the intended targets of those rewrites and checks, once all
   adapters have run, that each target was rewritten, that nothing of the
   replaced spelling remains, and that each wrapper still reaches the
   retained original. A violated postcondition abandons the load with
   AsymptoticExpansion::adapter and the caller's context restored, rather
   than leaving a silently misinstalled adapter; the record is kept in
   AsymptoticAnalysis`Mathics`$adapterPostconditions for inspection and for
   the portable loading cases. No System definition is inspected or changed. *)

ClearAll[mathicsRewrittenQ, mathicsWrappedQ, mathicsResidualMapQ, mathicsResidualMapTargets];

(* The target has definitions, none mention the replaced spelling, and at
   least one mentions the installed replacement: a target that stopped using
   the replaced spelling is a stale adapter, reported rather than ignored. *)
SetAttributes[mathicsRewrittenQ, HoldRest];
mathicsRewrittenQ[symbol_Symbol, replaced_, installed_] := Module[{rules = DownValues[symbol]},
  rules =!= {} && FreeQ[rules, replaced] && ! FreeQ[rules, installed]];

(* The wrapper is one definition that reaches the retained original, and
   the retained original is the pre-adapter definition: it mentions neither
   the wrapper's helper nor the wrapper itself, so reloading cannot nest. *)
mathicsWrappedQ[wrapper_Symbol, original_Symbol, helper_Symbol] :=
  Length[DownValues[wrapper]] === 1 && DownValues[original] =!= {} &&
    ! FreeQ[DownValues[wrapper], original] && ! FreeQ[DownValues[wrapper], helper] &&
    FreeQ[DownValues[original], helper] && FreeQ[DownValues[original], wrapper];

(* The list installer rewrites System`Map in every package definition; the
   only permitted residuals are the adapter's own fallback clause, the
   installer that names the spelling it replaces, and this predicate.
   Symbols are inspected unevaluated, as the installer does. *)
SetAttributes[mathicsResidualMapQ, HoldAllComplete];
mathicsResidualMapQ[symbol_Symbol] :=
  ! MemberQ[{HoldComplete[mathicsMap], HoldComplete[mathicsInstallMap], HoldComplete[mathicsResidualMapQ]},
      HoldComplete[symbol]] && ! FreeQ[DownValues[symbol], System`Map];
mathicsResidualMapTargets[] := Select[
  DeleteDuplicates[Join[Names["AsymptoticAnalysis`*"], Names["AsymptoticAnalysis`Private`*"],
    Names["AsymptoticAnalysis`Mathics`*"]]],
  TrueQ[ToExpression["AsymptoticAnalysis`Private`mathicsResidualMapQ[" <> # <> "]"]] &];

AsymptoticAnalysis`Mathics`$adapterPostconditions = <|
  "CoreProductLog" -> And @@ (mathicsRewrittenQ[#, System`ProductLog, mathicsCoreProductLog] & /@
    {corePerturbationAutomaticInverse, exponentialCoreExactInverse, lambertConstruct, specialThreshold}),
  "CoreTimeConstrained" -> And @@ (mathicsRewrittenQ[#, AsymptoticAnalysis`Mathics`TimeConstrained, System`TimeConstrained] & /@
    {corePerturbationChooseInverse, exponentialCoreExactInverse, inverseFunctionApplicationData}),
  "RefinementAssociation" -> mathicsRewrittenQ[refinementLagrangeSeed, Association[_Map], mathicsRefinementAssociation] &&
    mathicsRewrittenQ[depthRegion, Association[_Part], mathicsRefinementAssociation],
  "BranchFunctionDomain" -> mathicsRewrittenQ[inverseFunctionSelectBranchInternal, System`FunctionDomain, mathicsPolynomialFunctionDomain],
  "BranchWrappers" -> mathicsWrappedQ[inverseBranchGlobalMonotonicity, mathicsOriginalGlobalMonotonicity, mathicsConvexRealDomainQ] &&
    mathicsWrappedQ[inverseBranchEventualQ, mathicsOriginalBranchEventualQ, mathicsAffineIntervalTruth] &&
    mathicsWrappedQ[inverseFunctionEventually, mathicsOriginalFunctionEventually, mathicsPolynomialEventualTruth],
  "ListMap" -> (AsymptoticAnalysis`Mathics`$adapterMapResiduals = mathicsResidualMapTargets[]) === {}|>;

AsymptoticExpansion::adapter = "The Mathics adapters `1` did not install as intended. The package is not installed; the caller's context state has been restored.";
If[! And @@ Values[AsymptoticAnalysis`Mathics`$adapterPostconditions],
  (* Select over the key list: Mathics does not select inside associations. *)
  Message[AsymptoticExpansion::adapter,
    Select[Keys[AsymptoticAnalysis`Mathics`$adapterPostconditions],
      ! TrueQ[AsymptoticAnalysis`Mathics`$adapterPostconditions[#]] &]];
  loaderRestoreEntryState[]; Abort[]];
