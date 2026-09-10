(* Candidate helper excerpt. Load in the package Private context only. *)
(* Join already-evaluated proof predicates structurally. Descend through
   top-level conjunctions only; do not distribute Or, solve predicates,
   discard distinct restrictions, or walk into held predicate arguments. *)
seriesConditionClauses[c_And] := Flatten[seriesConditionClauses /@ (List @@ c), 1];
seriesConditionClauses[True] := {};
seriesConditionClauses[c_] := {c};
seriesConditionJoin[a_, b_] := And @@ DeleteDuplicates[
  Join[seriesConditionClauses[a], seriesConditionClauses[b]]];

seriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],
  <|"Assumptions" -> seriesConditionJoin[a["Assumptions"], b["Assumptions"]],
    "Domain" -> seriesConditionJoin[Lookup[a, "Domain", True], Lookup[b, "Domain", True]]|>];
