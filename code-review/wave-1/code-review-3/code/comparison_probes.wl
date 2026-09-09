(* Load the pinned standalone first. These are coverage probes, not timing
   benchmarks; term-goal semantics are not assumed to match across systems. *)
Clear[x,y];
{
 InverseSeries[Series[x+x^2,{x,0,4}],y],
 AsymptoticSolve[x+x^2==y,x->0,y->0,Reals,SeriesTermGoal->4],
 TimeConstrained[AsymptoticSolve[x+x^Sqrt[2]==y,x->0,y->0,Reals,SeriesTermGoal->4],5,$Aborted],
 With[{s=AsymptoticInverse`AsymptoticInverse[x+x^Sqrt[2],{x,0},y,SeriesTermGoal->4]},
  {Normal[s],s["Remainder"]}],
 TimeConstrained[Asymptotic[Erfc[x],x->Infinity,SeriesTermGoal->3],5,$Aborted],
 With[{s=AsymptoticInverse`AsymptoticExpansion[Erfc[x],x->Infinity,SeriesTermGoal->3]},
  {Normal[s],s["Remainder"]}]
}
