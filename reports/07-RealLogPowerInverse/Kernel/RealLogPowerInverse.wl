(* ::Package:: *)
(* RealLogPowerInverse 1.0.0, 2026-09-07.
   Positive-real, finite log-power germs; exact exponent cutoffs.
   See article/article.pdf for hypotheses and proof. MIT license. *)
BeginPackage["RealLogPowerInverse`"];

RealInverseExpansion::usage =
 "RealInverseExpansion[f, {x,y}, B] returns an Association describing the inverse of f at 0+ through every power y^b with b <= B. The input must be a finite sum a x + x^(1+alpha) P[Log[x]], with a>0 and alpha>0. Use exact real algebraic exponents and cutoff.";
LogPowerInverseExpansion::usage =
 "LogPowerInverseExpansion[{{alpha1,P1},...},{y,L},B] inverts a x + Sum[x^(1+alpha_j) Pj[Log[x]]]. The polynomials Pj use the symbol L. Options: \"LinearCoefficient\"->1, \"MaxMultiIndices\"->100000.";
InverseResidual::usage =
 "InverseResidual[data,B] composes the finite inverse in data with its input by independent sparse log-power arithmetic. It returns the normalized residual and whether it vanishes through absolute power B. B defaults to data[\"Cutoff\"]. This is an exact finite formal check, not a numerical interval certificate.";
InverseErrorBound::usage =
 "InverseErrorBound[data,y0] returns a rigorous conditional upper bound for the error relative to the positive root in the returned disk interval at an exact positive real y0. This is the requested inverse germ near zero. It uses a complex disk radius ratio (option \"Radius\"->1/2) and requires the returned Q<1. No floating-point enclosure is claimed.";
PurePowerInverseCoefficient::usage =
 "PurePowerInverseCoefficient[p,n] gives the coefficient of y^(1+n (p-1)) in the inverse of x+x^p, for integer n>=0.";
LogQuadraticInversePolynomial::usage =
 "LogQuadraticInversePolynomial[n,L] gives the coefficient of y^(n+1) in the inverse of x+x^2 (1+Log[x]), with L=Log[y].";

Options[LogPowerInverseExpansion] = {
 "LinearCoefficient" -> 1, "MaxMultiIndices" -> 100000};
Options[RealInverseExpansion] = {"MaxMultiIndices" -> 100000};
Options[InverseResidual] = {"MaxProducts" -> 1000000};
Options[InverseErrorBound] = {"Radius" -> 1/2};

Begin["`Private`"];

bad[tag_, text_] := Throw[Failure[tag, <|"MessageTemplate" -> text|>], errorTag];
canon[z_] := RootReduce[z];
zeroQ[z_] := TrueQ[FullSimplify[z == 0]];
leq[a_, b_] := TrueQ[FullSimplify[canon[a-b] <= 0]];
lt[a_, b_] := TrueQ[FullSimplify[canon[a-b] < 0]];
algRealQ[z_] := FreeQ[z, _Real] &&
 TrueQ[FullSimplify[Element[z, Algebraics] && Element[z, Reals]]];
realConstantQ[z_] := NumericQ[z] && FreeQ[z, _Real] &&
 TrueQ[FullSimplify[Element[z, Reals]]];
polyClean[p_, l_] := Collect[Expand[p], l, FullSimplify];

(* Sorted list of {exact weight, polynomial}; no floating-point ordering. *)
merge[terms_List, l_] := Module[{s, out = {}, w, p, last},
 s = Sort[({canon[#[[1]]], #[[2]]} & /@ terms),
   lt[#1[[1]], #2[[1]]] &];
 Do[
  w = z[[1]]; p = z[[2]];
  If[Length[out] > 0 && zeroQ[w - out[[-1,1]]],
   last = Length[out]; out[[last,2]] = out[[last,2]] + p,
   AppendTo[out, {w,p}]], {z,s}];
 out = ({#[[1]], polyClean[#[[2]],l]} & /@ out);
 Select[out, !zeroQ[#[[2]]] &]
];
clip[s_List, t_] := Select[s, leq[#[[1]],t] &];
scale[s_List, c_, l_] := merge[({#[[1]],c #[[2]]}& /@ s),l];
add[a_List,b_List,l_] := merge[Join[a,b],l];

(* Recursion enumerates only the bounded nonnegative lattice simplex.
   The zero index is included. Positive generators make this finite. *)
indices[aa_List, u_, cap_Integer] := Module[{walk, harvested, count=0},
 walk[j_, k_, w_] := Module[{q, m},
  If[j > Length[aa],
   count++;
   If[count > cap, bad["ResourceLimit",
     "The multi-index limit was exceeded. Reduce the cutoff or increase MaxMultiIndices."]];
   Sow[{k,w}],
   m = Floor[canon[(u-w)/aa[[j]]]];
   If[!IntegerQ[m], bad["UndecidableOrder",
     "An exact algebraic lattice bound did not simplify to an integer."]];
   Do[walk[j+1,Append[k,q],canon[w+q aa[[j]]]],{q,0,m}]
  ]
 ];
 harvested = Reap[walk[1,{},0]][[2]];
 If[harvested === {}, {}, First[harvested]]
];

eulerProduct[p_, l_, s_, n_Integer] := Module[{q=p,j},
 Do[q=Expand[(2+s+j) q + D[q,l]], {j,0,n-2}];
 polyClean[q,l]
];

LogPowerInverseExpansion[blocks_List, {y_Symbol,l_Symbol}, b_,
 OptionsPattern[]] := Catch[Module[
 {a=OptionValue["LinearCoefficient"],cap=OptionValue["MaxMultiIndices"],
  input, aa, pp, delta, d, tcut, enumeration, kept, after, next,
  correction, k, n, s, q, terms, expr, rem, t},
 If[y===l, bad["Variables","The output and logarithm symbols must be distinct."]];
 If[!algRealQ[b] || !leq[1,b],
  bad["Cutoff","The cutoff must be an exact real algebraic number at least 1."]];
 If[!realConstantQ[a] || !lt[0,a] || !FreeQ[a,y|l],
  bad["LinearCoefficient","The linear coefficient must be an exact, provably positive real constant."]];
 If[!IntegerQ[cap] || cap<1,
  bad["ResourceLimit","MaxMultiIndices must be a positive integer."]];
 If[!(And @@ (MatchQ[#, {_,_}]& /@ blocks)),
  bad["Blocks","Each input block must have the form {positive excess exponent, polynomial}."]];
 Do[
  If[!algRealQ[z[[1]]] || !lt[0,z[[1]]],
   bad["Exponent","Every excess exponent must be a positive exact real algebraic number."]];
  If[!PolynomialQ[z[[2]],l] || !FreeQ[z[[2]],y],
   bad["Polynomial","Every block coefficient must be a polynomial in the supplied logarithm symbol, independent of y."]];
  If[!(And @@ (realConstantQ /@ CoefficientList[Expand[z[[2]]],l])),
   bad["Coefficient","Polynomial coefficients must be exact, provably real constants; unresolved parameters are not accepted."]],
 {z,blocks}];
 t=y/a;
 input=merge[({#[[1]],#[[2]]/a}& /@ blocks),l];
 If[input==={},
  Return[<|"Expression"->t,"Variable"->y,"LogSymbol"->l,
   "LinearCoefficient"->a,"InputBlocks"->{},"CorrectionBlocks"->{},
   "Terms"->{{1,1}},"Cutoff"->b,"MultiIndexCount"->0,
   "Remainder"-><|"Power"->Infinity,"LogPower"->0,"Scale"->0,
    "Meaning"->"The inverse is exact."|>|>]];
 aa=input[[All,1]]; pp=input[[All,2]]; delta=First[aa];
 d=Max[Exponent[#,l]& /@ pp]; tcut=canon[b-1];
 (* There is always a semigroup point in (tcut,tcut+delta]. *)
 enumeration=indices[aa,canon[tcut+delta],cap];
 kept=Select[enumeration, leq[#[[2]],tcut] && Total[#[[1]]]>0 &];
 after=Select[enumeration, lt[tcut,#[[2]]] &];
 next=First[Sort[after[[All,2]],lt]];
 correction=Table[
  k=z[[1]]; s=z[[2]]; n=Total[k];
  q=Times@@MapThread[Power,{pp,k}];
  {s,(-1)^n eulerProduct[q,l,s,n]/(Times@@(Factorial /@ k))},
  {z,kept}];
 correction=merge[correction,l];
 terms=Join[{{1,1}},({canon[1+#[[1]]],#[[2]]}& /@ correction)];
 expr=Total[(t^#[[1]] (#[[2]] /. l->Log[t]))& /@ terms];
 rem=<|"Power"->canon[1+next],"LogPower"->d Floor[canon[next/delta]],
  "Scale"->t^(1+next) (1+Abs[Log[t]])^(d Floor[canon[next/delta]]),
  "Meaning"->"Big-O as y tends to 0 through positive real values. The constant and threshold are not supplied. The bound can be conservative after coefficient cancellation."|>;
 <|"Expression"->expr,"Variable"->y,"LogSymbol"->l,
  "LinearCoefficient"->a,"InputBlocks"->input,
  "CorrectionBlocks"->correction,"Terms"->terms,"Cutoff"->b,
  "MultiIndexCount"->Length[enumeration],"Remainder"->rem|>
],errorTag];

(* Strict syntactic front end. All branch-sensitive simplification is
   restricted to x>0; there is intentionally no PowerExpand call. *)
parseInput[expr_,x_,y_,l_] := Module[
 {e,monomials,blocks={},factors,w,c,a=0,combined},
 e=Expand[FullSimplify[expr,Assumptions->x>0] /. Log[x]->l];
 If[!FreeQ[e,y],bad["Variables","The input may not contain the output variable."]];
 monomials=If[Head[e]===Plus,List@@e,{e}];
 Do[
  factors=If[Head[mon]===Times,List@@mon,{mon}]; w=0;c=1;
  Do[
   Which[
    fac===x,w=w+1,
    MatchQ[fac,Power[x,_]] && FreeQ[fac[[2]],x|l|y],w=w+fac[[2]],
    FreeQ[fac,x],c=c fac,
    True,bad["UnsupportedInput",
     "The positive-real input is not a finite log-power sum. Use LogPowerInverseExpansion for explicit blocks."]],
   {fac,factors}];
  AppendTo[blocks,{canon[w],Expand[c]}],{mon,monomials}];
 combined=merge[blocks,l]; blocks={};
 Do[
  If[zeroQ[z[[1]]-1] && FreeQ[z[[2]],l],a=a+z[[2]],
   AppendTo[blocks,{canon[z[[1]]-1],z[[2]]}]],{z,combined}];
 {a,blocks}
];
RealInverseExpansion[expr_,{x_Symbol,y_Symbol},b_,OptionsPattern[]] :=
 Catch[Module[{l=Unique["L$"],parsed},
  If[x===y,bad["Variables","The input and output symbols must be distinct."]];
  parsed=parseInput[expr,x,y,l];
  LogPowerInverseExpansion[parsed[[2]],{y,l},b,
   "LinearCoefficient"->parsed[[1]],
   "MaxMultiIndices"->OptionValue["MaxMultiIndices"]]
 ],errorTag];

(* A second algorithm: direct sparse composition using binomial/log jets.
   This code does not call eulerProduct or the inverse coefficient formula. *)
mul[a_List,b_List,cut_,l_] := Module[{raw={},w},
 Do[
  $productCount++;
  If[$productCount>$productLimit,
   bad["ResourceLimit","The sparse composition product limit was exceeded."]];
  w=canon[u[[1]]+v[[1]]];
  If[leq[w,cut],AppendTo[raw,{w,u[[2]] v[[2]]}]],{u,a},{v,b}];
 merge[raw,l]
];
unitPower[u_List,r_,cut_,l_] := Module[{res={{0,1}},pow={{0,1}},j=1,coeff=1},
 While[True,
  pow=mul[pow,u,cut,l]; If[pow==={},Break[]];
  coeff=coeff (r-j+1)/j;
  If[zeroQ[coeff],Break[]];
  res=add[res,scale[pow,coeff,l],l];j++];res
];
unitLog[u_List,cut_,l_] := Module[{res={},pow={{0,1}},j=1},
 While[True,
  pow=mul[pow,u,cut,l];If[pow==={},Break[]];
  res=add[res,scale[pow,(-1)^(j+1)/j,l],l];j++];res
];
polySubstitute[p_,q_List,cut_,l_] := Module[{cc,res={},j},
 cc=CoefficientList[Expand[p],l];
 Do[res=add[mul[res,q,cut,l],{{0,cc[[j]]}},l],{j,Length[cc],1,-1}];res
];
InverseResidual[data_Association,b_:Automatic,OptionsPattern[]] :=
 Catch[Block[{$productCount=0,$productLimit=OptionValue["MaxProducts"]},
 Module[{required,y,l,a,cut,t,u,input,res,logu,q,pow,part,bb=b,ex},
  required={"Variable","LogSymbol","LinearCoefficient","InputBlocks",
   "CorrectionBlocks","Cutoff"};
  If[!(And @@ (KeyExistsQ[data,#]& /@ required)),
   bad["Data","The argument is not an inverse expansion Association."]];
  If[!IntegerQ[$productLimit] || $productLimit<1,
   bad["ResourceLimit","MaxProducts must be a positive integer."]];
  If[bb===Automatic,bb=data["Cutoff"]];
  If[!algRealQ[bb] || !leq[1,bb],
   bad["Cutoff","The residual cutoff must be an exact real algebraic number at least 1."]];
  y=data["Variable"];l=data["LogSymbol"];a=data["LinearCoefficient"];
  t=y/a;cut=canon[bb-1];input=data["InputBlocks"];
  u=clip[data["CorrectionBlocks"],cut];res=u;
  (* Only positive corrections are allowed: essential for termination. *)
  If[!(And @@ (lt[0,#[[1]]]& /@ u)),
   bad["Data","Correction weights must be strictly positive."]];
  logu=unitLog[u,cut,l];q=add[{{0,l}},logu,l];
  Do[
   If[leq[z[[1]],cut],
    pow=unitPower[u,1+z[[1]],canon[cut-z[[1]]],l];
    part=polySubstitute[z[[2]],q,canon[cut-z[[1]]],l];
    part=mul[pow,part,canon[cut-z[[1]]],l];
    part=({canon[z[[1]]+#[[1]]],#[[2]]}& /@ part);
    res=add[res,part,l]],{z,input}];
  res=clip[merge[res,l],cut];
  ex=Total[(t^#[[1]] (#[[2]]/.l->Log[t]))& /@ res];
  <|"NormalizedBlocks"->res,"NormalizedResidual"->ex,
   "Residual"->y ex,"Vanishes"->(res==={}),
   "VerifiedThrough"->bb,"ProductCount"->$productCount,
   "Meaning"->"Residual is f(g_B(y))-y, truncated through the stated absolute power. Vanishes is an exact finite formal check, not a numerical interval bound."|>
 ]],errorTag];

(* A priori tail majorant. An exponent cutoff B contains every total-degree
   term n<=Floor[(B-1)/alphaMax]. The remaining subset is bounded by the
   absolute sum of all higher homotopy degrees. *)
InverseErrorBound[data_Association,y0_,OptionsPattern[]] :=
 Catch[Module[{r=OptionValue["Radius"],required,t0,l,input,amax,n0,q,c,major,bound},
  required={"LinearCoefficient","InputBlocks","Cutoff","LogSymbol"};
  If[!(And @@ (KeyExistsQ[data,#]& /@ required)),
   bad["Data","The argument is not an inverse expansion Association."]];
  If[!realConstantQ[y0] || !lt[0,y0],
   bad["Argument","The evaluation point must be an exact, provably positive real constant."]];
  If[!realConstantQ[r] || !lt[0,r] || !lt[r,1],
   bad["Radius","Radius must be an exact real number strictly between 0 and 1."]];
  input=data["InputBlocks"];l=data["LogSymbol"];t0=y0/data["LinearCoefficient"];
  If[input==={},Return[<|"Q"->0,"Condition"->True,"Bound"->0,
   "SafeHomotopyDegree"->Infinity|>]];
  amax=Last[Sort[input[[All,1]],lt]];
  n0=Floor[canon[(data["Cutoff"]-1)/amax]];
  q=Total[Table[
   c=CoefficientList[z[[2]],l];
   major=Sum[Abs[c[[j+1]]] (Abs[Log[t0]]-Log[1-r])^j,{j,0,Length[c]-1}];
   t0^z[[1]] (1+r)^(1+z[[1]]) major/r,{z,input}]];
  bound=t0 r q^(n0+1)/((n0+1)(1-q));
  <|"Q"->q,"Condition"->(q<1),
   "Bound"->ConditionalExpression[bound,q<1],"SafeHomotopyDegree"->n0,
   "SelectedRootInterval"->{t0 (1-r),t0 (1+r)},
   "Meaning"->"When Q<1, Bound dominates the error relative to the unique positive root in SelectedRootInterval, selected from the linear root by homotopy. This agrees with the inverse germ near zero; a global branch needs a separate monotonicity/continuation check. This is a symbolic inequality, not an outward-rounded numerical enclosure."|>
 ],errorTag];

PurePowerInverseCoefficient[p_,0] := 1;
PurePowerInverseCoefficient[p_,n_Integer] /; n>0 :=
 (-1)^n Product[n p-j,{j,0,n-2}]/n!;
LogQuadraticInversePolynomial[0,l_Symbol] := 1;
LogQuadraticInversePolynomial[n_Integer,l_Symbol] /; n>0 :=
 (-1)^n eulerProduct[(1+l)^n,l,n,n]/n!;

End[];
EndPackage[];
