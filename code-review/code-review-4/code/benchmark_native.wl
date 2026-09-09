(* Diagnostic benchmark skeleton; NOT RUN during the audit.
   Compare only semantically matched output precision. Term goals on different
   scales are NOT automatically comparable. Run separate cold fresh kernels.
   ASYMPTOTIC_AUDIT_PACKAGE must name a local source file. *)
Module[{path, root, cases, once, rows, result, times, sample, name, held},
  path = Environment["ASYMPTOTIC_AUDIT_PACKAGE"];
  If[! StringQ[path] || ! FileExistsQ[path], Print["Set ASYMPTOTIC_AUDIT_PACKAGE."]; Exit[2]];
  root = DirectoryName[DirectoryName[$InputFileName]];
  Get[path];
  If[! MemberQ[$Packages, "AsymptoticInverse`"], Print["Package did not load."]; Exit[2]];
  cases = {
    {"package-sine-inverse-cutoff8", HoldComplete[Module[{x,y}, AsymptoticInverse`AsymptoticInverse[Sin[x], {x,0}, {y,8}]]]},
    {"native-sine-inverse-order8", HoldComplete[Module[{x,y}, InverseSeries[Series[Sin[x],{x,0,8}],y]]]},
    {"package-irrational-inverse-5blocks", HoldComplete[Module[{x,y}, AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},y,SeriesTermGoal->5]]]},
    {"native-irrational-AsymptoticSolve-5terms", HoldComplete[Module[{x,y},
      AsymptoticSolve[x+x^Sqrt[2]==y,x->0,y->0,Reals,SeriesTermGoal->5,Direction->"FromAbove"]]]},
    {"package-Erfc-5blocks", HoldComplete[Module[{x}, AsymptoticInverse`AsymptoticExpansion[Erfc[x],x->Infinity,SeriesTermGoal->5]]]},
    {"native-Erfc-5terms", HoldComplete[Module[{x}, Asymptotic[Erfc[x],x->Infinity,SeriesTermGoal->5]]]},
    {"package-small-rational-lattice", HoldComplete[Module[{x},
      AsymptoticInverse`AsymptoticExpansion[x^(1/101)+x^(1/103)+x,{x,0,1}]]]}
  };
  once[expr_HoldComplete] := Module[{elapsed, value},
    {elapsed,value} = AbsoluteTiming[TimeConstrained[
      MemoryConstrained[ReleaseHold[expr],256*1024^2,"MemoryLimit"],20,"Timeout"]];
    <|"Seconds"->elapsed,"Head"->ToString[Head[value],InputForm],
      "ResultBytes"->ByteCount[value],"ResultLeaves"->LeafCount[value],
      "ResourceExit"->MemberQ[{"MemoryLimit","Timeout"},value],
      "FailureObject"->FailureQ[value],
      "UnresolvedNativeCall"->! FreeQ[value,_Asymptotic|_AsymptoticSolve|_InverseSeries]|>
  ];
  rows = Table[
    name = First[item]; held = Last[item]; sample = once[held];
    result = Table[once[held],{3}]; times = Lookup[result,"Seconds"];
    <|"Case"->name,"ColdWithinThisProcess"->sample,"WarmSamples"->result,
      "WarmMedianSeconds"->Median[times],
      "SemanticEquivalenceVerified"->False|>, {item,cases}];
  Export[FileNameJoin[{root,"evidence","native-benchmarks.json"}],
    <|"Version"->$Version,"SystemID"->$SystemID,"Rows"->rows,
      "EntrySHA256"->IntegerString[FileHash[path,"SHA256"],16,64],
      "Warning"->"Timing is diagnostic until matching scale, cutoff, branches and output coefficients are checked. Later cases are not fresh-process cold measurements."|>,"RawJSON"];
  Print[rows];
]
