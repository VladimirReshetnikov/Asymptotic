(* Standalone, deliberately restricted N01 workaround/prototype.
   Load AsymptoticAnalysis.wl FIRST. This adds one symbol in AsymptoticAudit`;
   it changes no upstream definitions and installs no System upvalues.
   Input: c + b atom, with exactly one varying Zeta/LerchPhi atom and rational
   constants b,c. The explicit cutoff belongs to that atom's coordinate.
   The output carries an asymptotic remainder, not the atom's numerical bound.
   SeriesTermGoal is deliberately not an option of this restricted prototype. *)

AsymptoticAudit`AffineDirichletExpansion::usage =
"AffineDirichletExpansion[c+b atom,{x,x0,h}] expands one varying Zeta or LerchPhi atom with rational constants b,c, then uses existing series arithmetic and truncation. Load AsymptoticAnalysis first.";
Options[AsymptoticAudit`AffineDirichletExpansion] =
  {Assumptions -> True, Direction -> Automatic, "MaxTerms" -> 20000};

AsymptoticAudit`AffineDirichletExpansion[f_, {x_Symbol, x0_, h_}, opts : OptionsPattern[]] := Module[
  {atoms, atom, marker = Unique["dirichletAtom$"], polynomial, b, c, s, result,
   rationalQ, limit = OptionValue["MaxTerms"], ass = OptionValue[Assumptions],
   direction = OptionValue[Direction]},
  rationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  atoms = DeleteDuplicates[Cases[f,
    node : (Zeta[_] | LerchPhi[_, _, _]) /; ! FreeQ[node, x], {0, Infinity}]];
  If[Length[atoms] =!= 1,
    Return[Failure["UnsupportedAffineDirichletInput", <|
      "MessageTemplate" -> "Supply one varying Zeta or LerchPhi atom in an affine expression."|>]]];
  atom = First[atoms]; polynomial = Expand[f /. atom -> marker];
  If[! PolynomialQ[polynomial, marker] || Exponent[polynomial, marker] =!= 1,
    Return[Failure["UnsupportedAffineDirichletInput", <|
      "MessageTemplate" -> "Only degree-one dependence on the special-function atom is implemented."|>]]];
  b = Coefficient[polynomial, marker]; c = polynomial /. marker -> 0;
  If[! rationalQ[b] || ! rationalQ[c],
    Return[Failure["UnsupportedAffineDirichletCoefficient", <|
      "MessageTemplate" -> "This prototype requires rational constant affine coefficients."|>]]];
  s = AsymptoticAnalysis`AsymptoticExpansion[atom, {x, x0, h},
    "Backend" -> "Package", Assumptions -> ass, Direction -> direction,
    "MaxTerms" -> limit];
  If[! MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries], Return[s]];
  result = If[b === 1, s,
    AsymptoticAnalysis`SeriesMultiply[s, b, "MaxTerms" -> limit]];
  If[! MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries], Return[result]];
  If[c =!= 0, result = AsymptoticAnalysis`SeriesAdd[result, c, "MaxTerms" -> limit]];
  If[! MatchQ[result, _AsymptoticAnalysis`GeneralizedSeries], Return[result]];
  AsymptoticAnalysis`SeriesTruncate[result, h, "MaxTerms" -> limit]];

AsymptoticAudit`AffineDirichletExpansion[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AffineDirichletExpansion[c+b atom,{x,x0,h}] with one varying atom and rational b,c."|>];
