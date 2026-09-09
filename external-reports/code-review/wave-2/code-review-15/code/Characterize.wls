Get[FileNameJoin[{DirectoryName[$InputFileName], "NativeCommon.wl"}]];
results = {
  auditProbe["F01-flat-pole-original-and-derived", Module[{x,y,s,t},
    s = AsymptoticFlatInverse[1/x + Exp[-1/x], {x,0}, {y,1}];
    t = FlatSeriesTruncate[s,3];
    {auditApproach[s], auditApproach[t], AsymptoticAudit`ExpectedTargetApproach[s]}]],
  auditProbe["F01-flat-public-composite", Module[{x,y,s,t},
    s = AsymptoticFlatInverse[1/x + Exp[-1/x], {x,0}, {y,1}];
    t = SeriesAdd[s, Exp[-y]];
    If[FailureQ[t],t,{t["Scale"],t["SeriesApproach"],Normal[t]}]]],
  auditProbe["F01-negative-Erfc-tail", Module[{x,y,s},
    s = AsymptoticSpecialInverse["Erfc",{x,-Infinity},{y,2}];
    {auditApproach[s],AsymptoticAudit`ExpectedTargetApproach[s]}]],
  auditProbe["F01-downward-quadratic", Module[{x,y,s},
    s = AsymptoticSpecialInverse["QuadraticThreshold",{x,0},{y,2},"QuadraticCoefficient"->-1];
    {auditApproach[s],AsymptoticAudit`ExpectedTargetApproach[s]}]],
  auditProbe["F02-successful-but-insufficient-certificate", Module[{x,y,s,c,b},
    s = AsymptoticInverse[x^2,{x,0},{y,2}];
    c = InverseCertificate[s,2,"Interval"->{1,2},"TargetError"->10^-60,
      "EnclosureOrder"->2,"MaxRefinements"->64,"RefineExpansion"->False];
    b = If[FailureQ[c],Lookup[c[[2]],"BestCertificate",Missing["Absent"]],c];
    {c,If[AssociationQ[b],AsymptoticAudit`TightenCertificate[b],b]}]],
  auditProbe["F02-relative-only-order-seed", Module[{x,y,s,c},
    s = AsymptoticInverse[x^2,{x,0},{y,2}];
    c = InverseCertificate[s,2,"Interval"->{1,2},"RelativeError"->10^-150,
      WorkingPrecision->20,"MaxRefinements"->8,"RefineExpansion"->False];c]],
  auditProbe["F03-flat-square-baseline-and-proposal", Module[{x,y,s,a,b},
    s = AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,1}];
    a = FlatSeriesMultiply[s,s]; b = AsymptoticAudit`FlatSeriesMultiplyGraded[s,s];
    {Normal[a],auditTail[a],If[FailureQ[b],b,{Normal[b],auditTail[b]}]}]],
  auditProbe["F03-depth-three-tail", Module[{x,y,s,a,b},
    s = AsymptoticFlatInverse[x+Exp[-1/x],{x,0},{y,3}];
    a = FlatSeriesMultiply[s,s]; b = AsymptoticAudit`FlatSeriesMultiplyGraded[s,s];
    {auditTail[a],If[FailureQ[b],b,auditTail[b]]}]],
  auditProbe["F04-even-negative-source-observable", Module[{x,y,s},
    s = AsymptoticInverse[Gamma[-x],{x,-Infinity},{y,2},"Power"->2];
    {s["Power"],s["ExpansionPoint"],SeriesPower[s,1/2]}]]
};
auditWrite["native-characterization.json",Join[auditMetadata[],<|"Results"->results|>]];
