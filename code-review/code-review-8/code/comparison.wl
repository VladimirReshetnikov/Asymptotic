(* Native/package comparisons on a verified standalone source. Not a benchmark.
   Run: wolframscript -file code/comparison.wl [source.wl] [--allow-modified] *)
$AuditCallerPath = ExpandFileName[$InputFileName];
Get[FileNameJoin[{DirectoryName[$AuditCallerPath], "load_pinned.wl"}]];
$ComparisonLoad = AuditLoadFromCommandLine[];
If[FailureQ[$ComparisonLoad], Print[InputForm[$ComparisonLoad]]; Exit[1]];
Clear[x,y,t];
$Comparison = <|
  "Environment" -> $ComparisonLoad,
  "NativePolynomial" -> InverseSeries[x + x^2 + O[x]^6, y],
  "PackagePolynomial" -> AsymptoticInverse`AsymptoticInverse[x+x^2,{x,0},{y,6}],
  "PackageIrrational" -> TimeConstrained[
    AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},y,SeriesTermGoal->3],12,$Aborted],
  "NativeIrrationalSolve" -> TimeConstrained[
    AsymptoticSolve[x+x^Sqrt[2]==y,x->0,y->0,Reals,
      SeriesTermGoal->3,Direction->"FromAbove",GenerateConditions->True],8,$Aborted],
  "NativeIrrationalOperator" -> TimeConstrained[
    Asymptotic[InverseFunction[Function[t,t+t^Sqrt[2]]][y],y->0,
      SeriesTermGoal->3,Assumptions->y>0,GenerateConditions->True],8,$Aborted],
  "NativeErfcGoal3" -> Asymptotic[Erfc[x],x->Infinity,SeriesTermGoal->3],
  "NativeErfcGoal5" -> Asymptotic[Erfc[x],x->Infinity,SeriesTermGoal->5]|>;
$Comparison = $Comparison /. s_AsymptoticInverse`GeneralizedSeries :>
  <|"Expression" -> Normal[s], "Remainder" -> s["Remainder"]|>;
Print[InputForm[$Comparison]];
