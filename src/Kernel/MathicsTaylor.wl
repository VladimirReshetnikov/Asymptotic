(* Exact defining Taylor series at zero for functions missing from Mathics.
   Admit only a constant multiple of one function of a vanishing monomial.
   This restriction prevents a surrounding pole from amplifying an omitted
   coefficient. Every result carries an explicit order term.
   DLMF 16.2.1 and 25.12.10; p<=q+1 ensures a nonzero convergence radius. *)
Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`mathicsTaylorSeries,
  AsymptoticAnalysis`Mathics`mathicsDefiningTaylor];

mathicsDefiningTaylor[expression_, {t_Symbol, 0, order_Integer}, ass_] := Module[
  {atoms, atom, factor, head, argument, upper, lower, power, coefficient,
   term, index, degree},
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
    If[! ListQ[upper] || ! ListQ[lower] || Length[upper] > Length[lower] + 1 ||
      ! FreeQ[{upper, lower}, t] ||
      ! And @@ (TrueQ[mathicsAssumptionSimplify[Element[#, Reals], ass]] & /@ upper) ||
      ! And @@ (TrueQ[mathicsAssumptionSimplify[# > 0, ass]] & /@ lower),
      Return[$Failed, Module]]];
  term[index_Integer] := If[head === System`PolyLog,
    If[index === 0, 0, coefficient^index/index^power],
    coefficient^index (Times @@ (Pochhammer[#, index] & /@ upper))/
      (Factorial[index] Times @@ (Pochhammer[#, index] & /@ lower))];
  SeriesData[t, 0, Table[If[Mod[index, degree] === 0,
    factor term[index/degree], 0], {index, 0, order}], 0, order + 1, 1]];
mathicsDefiningTaylor[_, _, _] := $Failed;

mathicsTaylorSeries[expression_, specification_List, ass_] := Module[{series},
  series = mathicsDefiningTaylor[expression, specification, ass];
  If[series === $Failed,
    Block[{$Assumptions = ass}, System`Series[expression, specification]], series]];
End[];
