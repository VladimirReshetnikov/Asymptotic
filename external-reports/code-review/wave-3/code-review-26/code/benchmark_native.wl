(* Run after load_pinned.wl. ByteCount is expression size, not peak resident memory.
   Timings are workload observations, not estimates of complexity or universality. *)
Module[{x, native, normalized, object, nativeTiming, wrapperTiming, rows},
  rows = Table[
    ClearSystemCache[];
    nativeTiming = First[AbsoluteTiming[native = Series[1/(1 - x), {x, 0, n}]]];
    normalized = Normal[native];
    wrapperTiming = First[AbsoluteTiming[object = With[{order = n},
      AsymptoticAnalysis`AsymptoticExpansion[1/(1 - x), {x, 0, order}, "Backend" -> "Series"]]]];
    <|"Order" -> n, "NativeByteCount" -> ByteCount[native],
      "NormalByteCount" -> ByteCount[normalized], "ObjectByteCount" -> ByteCount[object],
      "NativeSeconds" -> nativeTiming, "WrapperSeconds" -> wrapperTiming,
      "NativeSame" -> SameQ[object["NativeResult"], native],
      "NormalSame" -> SameQ[Normal[object], normalized]|>, {n, If[ValueQ[$AuditBenchmarkOrders], $AuditBenchmarkOrders, {100, 1000}]}];
  <|"KernelVersion" -> $Version, "SystemID" -> $SystemID, "Rows" -> rows|>]
