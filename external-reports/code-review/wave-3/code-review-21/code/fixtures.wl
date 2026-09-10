(* Audit fixtures. NOT natively executed during this audit.
   ShortTaylor is the real polynomial 1+t+t^2 for numeric t. Its custom Series
   method intentionally supplies a truthful but incomplete O(t^2) expansion.
   This is not a claim that a stock built-in currently returns this short jet. *)
ClearAll[AsymptoticAuditFixtures`ShortTaylor];
AsymptoticAuditFixtures`ShortTaylor[0] = 1;
AsymptoticAuditFixtures`ShortTaylor[t_?NumericQ] := 1 + t + t^2;
AsymptoticAuditFixtures`ShortTaylor /:
  HoldPattern[Series[AsymptoticAuditFixtures`ShortTaylor[t_],
    {v_Symbol, 0, n_Integer}, opts___]] /; t === v && n >= 2 :=
      SeriesData[v, 0, {1, 1}, 0, 2, 1];
