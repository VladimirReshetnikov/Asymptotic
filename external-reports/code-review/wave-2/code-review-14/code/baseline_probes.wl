(* Read-only observations of the current local checkout, not pass/fail tests.
   The runner wraps each probe in limits and serializes its exact InputForm.
   All symbols used below are local to the fresh audit kernel. *)
{
 "N01-captured-parameter" -> HoldComplete[Module[{o,i,r},
   o=AsymptoticInverse`AsymptoticExpansion[1/(1+x/a),{x,0,1},Assumptions->a>0];
   i=AsymptoticInverse`AsymptoticExpansion[a,{a,0,2}];
   r=AsymptoticInverse`SeriesCompose[o,i];
   <|"Outer"->o,"Inner"->i,"Composed"->r,"ExactDiagonal"->1/2|>]],
 "N02-translated-linear-certificate" -> HoldComplete[Module[{A=2^10000+1,s},
   s=AsymptoticInverse`AsymptoticInverse[x-A,{x,A},{y,2}];
   AsymptoticInverse`InverseCertificate[s,1/2,"Interval"->{A+1/4,A+3/4},
    "Center"->A+1/2,"EnclosureOrder"->2000,"MaxRefinements"->0,"RefineExpansion"->False]]],
 "N03-translated-numerical-check" -> HoldComplete[Module[{A=10^100,s},
   s=AsymptoticInverse`AsymptoticInverse[(x-A)+(x-A)^2,{x,A},{y,4}];
   AsymptoticInverse`InverseNumericalCheck[s,1/1000,WorkingPrecision->50]]],
 "N04-inherited-Fourier-goal" -> HoldComplete[Module[{s},
   s=AsymptoticInverse`AsymptoticFourierInverse[x+x^2,{x,0},{y,4},SeriesTermGoal->1];
   <|"Result"->s,"Terms"->If[MatchQ[s,_AsymptoticInverse`GeneralizedSeries],s["Terms"],Missing["Failure"]]|>]],
 "N04-invalid-Fourier-goal" -> HoldComplete[
   AsymptoticInverse`AsymptoticFourierInverse[x+x^2,{x,0},{y,4},SeriesTermGoal->"invalid"]],
 "N05-noop-truncation-metadata" -> HoldComplete[Module[{s,r},
   s=AsymptoticInverse`AsymptoticExpansion[Zeta[x],{x,Infinity,Log[4]}];
   r=AsymptoticInverse`SeriesTruncate[s,Log[5]];
   <|"SameFiniteExpressionOnDomain"->FullSimplify[Normal[s]==Normal[r],x>1],
     "Before"->Lookup[s[[1]],{"AbsoluteRemainderBound","RemainderBoundConditions"}],
     "After"->If[MatchQ[r,_AsymptoticInverse`GeneralizedSeries],
       Lookup[r[[1]],{"AbsoluteRemainderBound","RemainderBoundConditions"}],r]|>]],
 "native-Series-fixed-parameter" -> HoldComplete[Series[1/(1+x/a),{x,0,0},Assumptions->a>0]],
 "native-exact-diagonal-first" -> HoldComplete[Series[(1/(1+x/a))/.x->a,{a,0,1}]],
 "native-ramified-reversion" -> HoldComplete[InverseSeries[Series[x^2+3x^4,{x,0,7}],y]],
 "native-implicit-inversion" -> HoldComplete[AsymptoticSolve[x+x^2==y,x,{y,0,3},Assumptions->y>0]],
 "native-local-FindRoot" -> HoldComplete[FindRoot[u+u^2==1/1000,{u,1/1000},WorkingPrecision->70,
   AccuracyGoal->60,PrecisionGoal->60]],
 "native-exact-linear-solve" -> HoldComplete[Module[{A=2^10000+1},Solve[x-A==1/2,x]]]
}
