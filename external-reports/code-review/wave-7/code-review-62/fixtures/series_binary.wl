seriesBinary[op_, s_, t_, cut_, limit_] := Module[{a, b, af, bf, ratio, j, ell, ass, d, h, order},
  a = seriesData[s, limit]; b = seriesData[t, limit]; seriesCompatible[a, b]; b = seriesAlign[a, b];
  ell = a["LogVariable"]; ass = seriesAss[a] && seriesAss[b];
  order = Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]];
  af = seriesFlat[a, limit]; bf = seriesFlat[b, limit];
  If[af =!= $Failed && bf =!= $Failed, a = af; b = bf];
  If[op === "Add",
    ratio = seriesExpressionJet[Simplify[b["Prefactor"]/a["Prefactor"], ass], a, limit];
    If[ratio === $Failed, fail["IncompatibleCarriers", "Addition needs a power-log ratio of the exact prefactors; independent exponential sectors require separate truncation."]];
    j = pAdd[a["Jet"], pMul[ratio, b["Jet"], ell, ass, limit], ell, ass];
    d = Join[a, <|"Jet" -> j, "Offset" -> a["Offset"] + b["Offset"]|>],
    If[a["Offset"] =!= 0 || b["Offset"] =!= 0,
      fail["IncompatibleCarriers", "Multiplication of translated, non-power-log carriers requires explicit sector decomposition."]];
    j = pMul[a["Jet"], b["Jet"], ell, ass, limit];
    d = Join[a, <|"Jet" -> j, "Prefactor" -> a["Prefactor"] b["Prefactor"]|>]];
  d = Join[d, <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True], "RemainderDerivativeOrder" -> order|>];
  h = If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]];
  seriesMake[d, {op, {s, t}}, h]];

AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, t_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
