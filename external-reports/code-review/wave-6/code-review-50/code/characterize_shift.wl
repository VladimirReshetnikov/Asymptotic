(* UNRUN characterization. Load an UNPATCHED pinned package before this file.
   Output is descriptive, not an automated success/failure acceptance total. *)
Clear[x,y];
Print["Kernel: ", $Version];
Do[
  s = AsymptoticAnalysis`AsymptoticExponentialCoreInverse[
    Exp[x],1,{x,Infinity},{y,n},"SourceShift" -> -Abs[y]];
  Print["depth=",n,"; head=",Head[s]];
  If[Head[s] === AsymptoticAnalysis`GeneralizedSeries,
    Print["expression=",InputForm[FullSimplify[Normal[s],y>4]]];
    Print["scale=",InputForm[FullSimplify[s["RemainderScaleExpression"],y>4]]];
    Print["domain-at-10=",InputForm[s["TargetDomain"] /. y->10]];
    Print["ratio-at-10=",N[(Abs[Log[y-1]-Normal[s]]/
      s["RemainderScaleExpression"]) /. y->10,40]],
    Print[InputForm[s]]],
  {n,{0,1,3}}];
