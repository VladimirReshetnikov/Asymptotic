(* Run in a fresh kernel after Get["path/to/AsymptoticAnalysis.wl"].
   Bounded structural storage measurements, not an upstream performance suite.
   This complete harness was supplied, not run; the 100000-element probe in the
   evidence file was executed separately. Do not interpret ByteCount as peak RSS. *)
Clear[NativeStorageCase];
NativeStorageCase[n_Integer?Positive] /; n <= 100000 := Module[
 {input = SparseArray[{1 -> Exp[x]}, n], native, wrapped, directTime, wrapperTime},
 {directTime, native} = AbsoluteTiming[Series[input, {x, 0, 3}]];
 {wrapperTime, wrapped} = AbsoluteTiming[
  AsymptoticAnalysis`AsymptoticExpansion[input, {x, 0, 3}, "Backend" -> "Series"]];
 <|"Length" -> n, "Kernel" -> $Version, "NativeHead" -> ToString[Head[native], InputForm],
 "NativeBytes" -> ByteCount[native], "StoredNativeBytes" -> ByteCount[wrapped["NativeResult"]],
 "ExpressionHead" -> ToString[Head[wrapped["Expression"]], InputForm],
 "ExpressionBytes" -> ByteCount[wrapped["Expression"]], "WrapperBytes" -> ByteCount[wrapped],
 "SameNativeResult" -> SameQ[native, wrapped["NativeResult"]],
 "DirectSeconds" -> directTime, "WrapperSeconds" -> wrapperTime|>];
NativeStorageMeasurements = NativeStorageCase /@ {1000, 10000, 100000};
NativeStorageMeasurements
