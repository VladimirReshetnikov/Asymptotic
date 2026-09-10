(* Loaded in AsymptoticAnalysis`Private`.  This is a bounded verification of an
   already computed inverse candidate against the ORIGINAL expression.  It
   does not infer exactness from a finite forward model or solve an equation. *)

exactTerminationCoreQ[e_, x_] := Which[
  FreeQ[e, x], True,
  e === x, True,
  MemberQ[{Plus, Times}, Head[e]], And @@ (exactTerminationCoreQ[#, x] & /@ List @@ e),
  Head[e] === Power && FreeQ[e[[2]], x] && exactRealQ[e[[2]]], exactTerminationCoreQ[e[[1]], x],
  True, False];

exactInverseTermination[f_, x_, x0_, coord_Association, model_Association,
    blocks_List, ell_, ass_] := Module[
  {z = Unique["z$"], bracket, candidate, local, target, domain, verified},
  If[blocks === {} || blocks[[1]] =!= {0, 1} ||
     ! And @@ (less[0, #[[1]]] & /@ Rest[blocks]) ||
     LeafCount[f] > 300 || LeafCount[blocks] > 500, Return[None, Module]];
  bracket = Total[(z^ToRadicals[#[[1]]] (ToRadicals[#[[2]]] /. ell -> Log[z])) & /@ blocks];
  candidate = If[coord["Infinite"], coord["Sign"] bracket/z,
    x0 + coord["Sign"] z bracket];
  local = coord["LocalVariable"] /. x -> candidate;
  target = model["Limit"] + model["LeadingCoefficient"] z^ToRadicals[model["LeadingPower"]];
  domain = ass && 0 < z < 1 && local > 0;
  verified = TimeConstrained[
    Quiet[Check[FullSimplify[(f /. x -> candidate) == target, domain], False]],
    2, False];
  If[! TrueQ[verified], Return[None, Module]];
  <|"Verification" -> "Exact symbolic composition with the original forward expression",
    "Uniformizer" -> z, "Candidate" -> candidate, "Target" -> target,
    "BranchAssumptions" -> domain, "Verified" -> True|>];
