(* NEVER run on the unpatched source: these are high-denominator probes.
   run_native.wl checks the patch marker before enabling this file.
   MemoryConstrained is a second line of defense, not the proposed remedy. *)
VerificationTest[Module[{x, s},
  s = MemoryConstrained[
    AsymptoticExpansion[x^(1/10007) + x^(1/10009) + x, {x, 0, 1}, "MaxTerms" -> 100],
    64*1024^2, "MemoryLimit"];
  MatchQ[s, _GeneralizedSeries] &&
    MatchQ[s["SeriesData"], Missing["DenseRepresentationTooLarge", _Association]] &&
    Length[s["Terms"]] === 2],
  True, TestID -> "audit-A02-sparse-forward-result-survives-rejected-dense-export"]

VerificationTest[Module[{y, result},
  result = MemoryConstrained[
    AsymptoticInverse`Private`makeInverseSeriesData[
      {{1/10007, 1}, {1/10009, 1}}, y, 0, 1,
      <|"Sign" -> 1, "Infinite" -> False|>, {1, 0}, 1, 0],
    64*1024^2, "MemoryLimit"];
  MatchQ[result, Missing["DenseRepresentationTooLarge", _Association]]],
  True, TestID -> "audit-A02-inverse-native-export-preflights-the-lattice"]
