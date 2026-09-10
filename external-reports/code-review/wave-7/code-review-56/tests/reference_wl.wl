(* Load code/NegativeLerchInterval.wl first. This local-path wrapper was not
   separately executed; its fully qualified arithmetic was checked natively. *)
AsymptoticAudit`ReferenceChecks = Flatten[Table[
  Module[{e = AsymptoticAudit`NegativeLerchInterval[q,s,a,k], r = q/(1+q)},
    e["Lower"] <= e["Upper"] &&
      e["Width"] === r^(k+1) e["DifferenceCoefficient"] &&
      e["Width"] <= a^-s/2^(k+1)],
  {q,{0,1/2,9/10,1}}, {s,{1,2}}, {a,{1,100}}, {k,{0,1,4,8}}]];
Print[InputForm[<|"KernelVersion" -> $Version,
  "Count" -> Length[AsymptoticAudit`ReferenceChecks],
  "AllTrue" -> And @@ AsymptoticAudit`ReferenceChecks|>]];
