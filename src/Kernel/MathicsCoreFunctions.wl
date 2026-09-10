(* Loaded late in Private, only on Mathics. Mathics 10's generic SymPy
   conversion preserves Wolfram's (branch, argument) order although LambertW
   uses (argument, branch); its numerical evaluator also lacks two-argument
   support. Even N[ProductLog[0,E]] can therefore return -Infinity. The principal
   branch has the exact one-argument spelling ProductLog[z]. Normalize at
   each package construction site, before the builtin can see numeric data.
   This neither changes System definitions nor asserts a numeric evaluator
   for nonprincipal branches. Returned expressions keep the System head. *)

Clear[mathicsCoreProductLog];
mathicsCoreProductLog[0, argument_] := System`ProductLog[argument];
mathicsCoreProductLog[branch_, argument_] := System`ProductLog[branch, argument];
mathicsCoreProductLog[argument_] := System`ProductLog[argument];

Scan[(DownValues[#] = DownValues[#] /.
    System`ProductLog -> mathicsCoreProductLog) &,
  {corePerturbationAutomaticInverse, exponentialCoreExactInverse,
   lambertConstruct, specialThreshold}];

(* Preserve explicit user-selected core-check deadlines and the documented
   five-second callable-evaluation guard. Only internal proof budgets receive
   the interpreter-overhead allowance from MathicsTimeBudget.wl. *)
Scan[(DownValues[#] = DownValues[#] /.
    AsymptoticAnalysis`Mathics`TimeConstrained -> System`TimeConstrained) &,
  {corePerturbationChooseInverse, exponentialCoreExactInverse,
   inverseFunctionApplicationData}];
