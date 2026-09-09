(* Diagnostic, not a claim about a previously observed Wolfram result.
   Run after package loading. Captures native representation and the old
   private fallback; the public adapter may take a different route. *)
Module[{u, ell, s2, s3, old, public, report},
 s2 = TimeConstrained[Series[EllipticK[1 - u^2], {u, 0, 2}], 30, $Aborted];
 s3 = TimeConstrained[Series[EllipticK[1 - u^2], {u, 0, 3}], 30, $Aborted];
 old = TimeConstrained[
   AsymptoticInverse`Private`catch[
    AsymptoticInverse`Private`fwdSeries[EllipticK[1 - u^2], u, ell, True, 2, 20000]],
   30, $Aborted];
 public = TimeConstrained[AsymptoticExpansion[EllipticK[1 - u^2], {u, 0, 4}], 30, $Aborted];
 report = <|"WolframVersion" -> $Version, "SystemID" -> $SystemID,
   "NativeOrder2" -> ToString[s2, InputForm], "NativeOrder3" -> ToString[s3, InputForm],
   "OldFallback" -> ToString[old, InputForm],
   "FallbackClaimsO_u4_withoutLog" -> MatchQ[old, {_List, 4, 0}],
   "PublicConstructor" -> ToString[public, InputForm],
   "ExactMathematicalBoundary" -> "(9/64) u^4 (Log[4/u]-7/6)",
   "Interpretation" -> "A false old-fallback O(u^4) claim is distinct from the public constructor, which may use the conservative native adapter."|>;
 Print[InputForm[report]];
 Put[report, "native-tail-probe.wl"];
]
