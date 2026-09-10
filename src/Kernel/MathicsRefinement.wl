(* Mathics-only late adapter. Association holds a mapped rule list without
   evaluating it in Mathics 10. The refinement frontier must materialize its
   rules before constructing the association. The finite-depth enumerator
   needs the same evaluation order for its collected rule list. Keep these
   rewrites local; the ordinary Wolfram definitions are never changed. *)
ClearAll[mathicsRefinementAssociation];
DownValues[refinementLagrangeSeed] = DownValues[refinementLagrangeSeed] /.
  HoldPattern[Association[rules_Map]] :> mathicsRefinementAssociation[rules];
DownValues[depthRegion] = DownValues[depthRegion] /.
  HoldPattern[Association[rules_Part]] :> mathicsRefinementAssociation[rules];
mathicsRefinementAssociation[rules_List] := Association @@ rules;
