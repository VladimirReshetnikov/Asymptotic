(* Reproduction of the isolated native mechanism observation.
   This is NOT the package constructor. The recurrence body comes from
   src/Kernel/CorePerturbation.wl at efa1aeec4845a9c35e140963a0333d0c9ec33b05.
   Resource failures are represented by Throw; that branch was not reached.
   The recorded observation is transcribed in evidence/native-observations.json. *)
Clear[x,y,u];
core = 1/x + Abs[y]/2;
perturbation = -Abs[y]/2;
ClearAll[corePerturbationTerm];
corePerturbationTerm[n_,rlocal_,hprime_,fprime_,u_,limit_] :=
 Module[{term,j},
  term = Together[hprime rlocal^n/fprime];
  Do[
    term = Together[D[term,u]/fprime];
    If[LeafCount[term] > limit, Throw["ResourceLimit"]],
    {j,1,n-1}];
  term = (-1)^n term/n!;
  If[LeafCount[term] > limit, Throw["ResourceLimit"]];
  term];
u0 = 1/(y-Abs[y]/2);
coeff = Table[FullSimplify[
  corePerturbationTerm[n,perturbation,1,-1/u^2,u,20000] /. u -> u0,
  y>0],{n,1,5}];
{$Version,core+perturbation,FreeQ[core+perturbation,y],
 FullSimplify[Element[perturbation,Reals]],FullSimplify[u0,y>0],
 coeff,Table[FullSimplify[u0+Total[Take[coeff,n]],y>0],{n,0,5}]}
