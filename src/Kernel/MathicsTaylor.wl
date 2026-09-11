(* Exact defining Taylor series at zero for functions missing from Mathics.
   Admit only a constant multiple of one function of a vanishing monomial.
   This restriction prevents a surrounding pole from amplifying an omitted
   coefficient. Every result carries an explicit order term.
   DLMF 16.2.1 and 25.12.10; p<=q+1 ensures a nonzero convergence radius. *)
Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`mathicsTaylorSeries,
  AsymptoticAnalysis`Mathics`mathicsDefiningTaylor, AsymptoticAnalysis`Mathics`mathicsTaylorLowerAdmissible,
  AsymptoticAnalysis`Mathics`mathicsTaylorRising];

mathicsDefiningTaylor[expression_, {t_Symbol, 0, order_Integer}, ass_] := Module[
  {atoms, atom, factor, head, argument, upper, lower, power, coefficient,
   term, index, degree, stop},
  If[order < 0 || order > 400, Return[$Failed, Module]];
  atoms = DeleteDuplicates[Cases[expression,
    node : (_System`Hypergeometric0F1 | _System`Hypergeometric1F1 |
      _System`Hypergeometric2F1 | _System`HypergeometricPFQ | _System`PolyLog) /;
      ! FreeQ[node, t], {0, Infinity}]];
  If[Length[atoms] =!= 1, Return[$Failed, Module]];
  atom = First[atoms]; factor = expression /. atom -> 1;
  If[Length[atom] =!= Switch[Head[atom],
      System`Hypergeometric0F1 | System`PolyLog, 2,
      System`Hypergeometric1F1 | System`HypergeometricPFQ, 3,
      System`Hypergeometric2F1, 4], Return[$Failed, Module]];
  If[! FreeQ[factor, t] ||
      ! TrueQ[AsymptoticAnalysis`Mathics`Simplify[expression - factor atom] === 0],
    Return[$Failed, Module]];
  head = Head[atom]; argument = Last[atom];
  If[! PolynomialQ[argument, t], Return[$Failed, Module]];
  degree = Exponent[argument, t];
  If[! IntegerQ[degree] || degree < 1, Return[$Failed, Module]];
  coefficient = Coefficient[argument, t, degree];
  If[Expand[argument - coefficient t^degree] =!= 0, Return[$Failed, Module]];
  If[head === System`PolyLog,
    power = First[atom];
    If[! FreeQ[power, t] || ! TrueQ[mathicsAssumptionSimplify[Element[power, Reals], ass]],
      Return[$Failed, Module]],
    {upper, lower} = Switch[head,
      System`Hypergeometric0F1, {{}, {atom[[1]]}},
      System`Hypergeometric1F1, {{atom[[1]]}, {atom[[2]]}},
      System`Hypergeometric2F1, {{atom[[1]], atom[[2]]}, {atom[[3]]}},
      System`HypergeometricPFQ, {atom[[1]], atom[[2]]}];
    If[! ListQ[upper] || ! ListQ[lower] || ! FreeQ[{upper, lower}, t], Return[$Failed, Module]];
    (* A nonpositive-integer upper parameter -m terminates the series at
       index m, so the sum is a polynomial whatever the rank; only a
       nonterminating series needs p <= q + 1 for a positive radius
       (wave-4 W4-08). *)
    stop = Min[Cases[upper, n_Integer /; n <= 0 :> -n]];
    If[stop === Infinity && Length[upper] > Length[lower] + 1, Return[$Failed, Module]];
    If[! And @@ (TrueQ[mathicsAssumptionSimplify[Element[#, Reals], ass]] & /@ upper),
      Return[$Failed, Module]];
    (* A lower parameter must never make a retained Pochhammer factor
       vanish: provably positive, an exact real noninteger, or, for a
       terminating sum, a nonpositive integer -n with n >= m. A nonpositive
       integer below the termination index is a pole and is refused; no
       regularization convention is applied. *)
    If[! And @@ (mathicsTaylorLowerAdmissible[#, stop, ass] & /@ lower), Return[$Failed, Module]]];
  (* Rising factorials as explicit finite products: Mathics evaluates
     Pochhammer of a rational to factorial ratios such as (-3/2)!, which the
     downstream coefficient proofs cannot handle; the products keep exact
     rational and symbolic parameters as ordinary arithmetic. *)
  term[index_Integer] := If[head === System`PolyLog,
    If[index === 0, 0, coefficient^index/index^power],
    coefficient^index (Times @@ (mathicsTaylorRising[#, index] & /@ upper))/
      (Factorial[index] Times @@ (mathicsTaylorRising[#, index] & /@ lower))];
  SeriesData[t, 0, Table[If[Mod[index, degree] === 0,
    factor term[index/degree], 0], {index, 0, order}], 0, order + 1, 1]];
mathicsDefiningTaylor[_, _, _] := $Failed;
mathicsTaylorRising[a_, 0] := 1;
mathicsTaylorRising[a_, k_Integer?Positive] := Times @@ Table[a + j, {j, 0, k - 1}];
mathicsTaylorLowerAdmissible[b_, stop_, ass_] := TrueQ[mathicsAssumptionSimplify[b > 0, ass]] ||
  (NumericQ[b] && Precision[b] === Infinity && ! IntegerQ[b] && TrueQ[mathicsAssumptionSimplify[Element[b, Reals], ass]]) ||
  (IntegerQ[b] && b <= 0 && stop =!= Infinity && -b >= stop);

mathicsTaylorSeries[expression_, specification_List, ass_] := Module[{series},
  series = mathicsDefiningTaylor[expression, specification, ass];
  If[series === $Failed,
    Block[{$Assumptions = ass}, System`Series[expression, specification]], series]];
End[];
