(* Finite Fourier-polynomial coefficient algebra in L = Log[u].
   A coefficient is {{omega,P_omega(L)},...}, representing
   Sum[P_omega(L) Exp[I omega L]]. Source weights remain separate. *)

AsymptoticInverse`AsymptoticFourierInverse::usage =
"AsymptoticFourierInverse[f,{x,x0},{y,cutoff}] inverts a monomial leading core with strictly higher source-power perturbations having finite Fourier-polynomial coefficients in Log[u]. Frequencies are exact real numbers; MaxFrequencies is a hard budget, not a frequency truncation. The target-power cutoff is exclusive.";
AsymptoticInverse`FourierInverseResidual::usage =
"FourierInverseResidual[s] independently composes the finite Fourier forward model with its inverse jet and checks the residual below the stored relative source-weight cutoff.";
AsymptoticInverse`FourierInverseCoefficient::usage =
"FourierInverseCoefficient[s,k] returns the exact coefficient for a multi-index k, as modes and as a real trigonometric expression in the stored logarithmic variable.";

Options[AsymptoticInverse`AsymptoticFourierInverse] = Join[Options[AsymptoticInverse], {"MaxFrequencies" -> 256}];

fourierPoly[q_, ell_, ass_] := Module[{coefficients, canonical, expanded},
  expanded = Expand[Simplify[q, ass && Element[ell, Reals]]];
  If[! PolynomialQ[expanded, ell], fail["NonPolynomialFourierAmplitude", "Fourier amplitudes must be polynomials in the logarithmic variable."]];
  canonical[c_] := If[NumericQ[c] && TrueQ[Simplify[Element[c, Algebraics]]], RootReduce[c], Simplify[c, ass]];
  coefficients = canonical /@ CoefficientList[expanded, ell];
  Expand[coefficients . ell^Range[0, Length[coefficients] - 1]]];

(* The first entry is an exact source weight or frequency. Mathematical
   equality, rather than structural equality, groups algebraic resonances. *)
fourierWeightGroups[rows_List] := Split[
  Sort[MapAt[canon, #, 1] & /@ rows, less[#1[[1]], #2[[1]]] &],
  equal[#1[[1]], #2[[1]]] &];
fourierFrequencyBudget[count_, limit_] := If[count > limit,
  fail["FrequencyLimit", "The exact Fourier coefficient exceeds MaxFrequencies; no modes were silently discarded.",
    <|"MaxFrequencies" -> limit, "RequiredFrequencies" -> count|>]];
fourierJetFrequencies[rows_List] := #[[1, 1]] & /@ fourierWeightGroups[
  List /@ Flatten[(#[[2, All, 1]] &) /@ rows]];

fourierMerge[rows_List, ell_, ass_, frequencyLimit_] := Module[{groups, result},
  If[rows === {}, Return[{}, Module]];
  groups = fourierWeightGroups[rows];
  result = {#[[1, 1]], fourierPoly[Total[#[[All, 2]]], ell, ass]} & /@ groups;
  result = Select[result, ! TrueQ[Simplify[#[[2]] == 0, ass && Element[ell, Reals]]] &];
  fourierFrequencyBudget[Length[result], frequencyLimit]; result];
fourierScale[a_, scalar_, ell_, ass_, limit_] := fourierMerge[{#[[1]], scalar #[[2]]} & /@ a, ell, ass, limit];
fourierAdd[a_, b_, ell_, ass_, limit_] := fourierMerge[Join[a, b], ell, ass, limit];
fourierMul[a_, b_, ell_, ass_, limit_, frequencyLimit_] := Module[{rows},
  If[Length[a] Length[b] > limit, fail["ResourceLimit", "Fourier convolution exceeded MaxTerms candidate pairs."]];
  rows = Flatten[Table[{aa[[1]] + bb[[1]], Expand[aa[[2]] bb[[2]]]}, {aa, a}, {bb, b}], 1];
  fourierMerge[rows, ell, ass, frequencyLimit]];
fourierEuler[a_, ell_, ass_, limit_] := fourierMerge[
  {#[[1]], D[#[[2]], ell] + I #[[1]] #[[2]]} & /@ a, ell, ass, limit];
fourierPower[a_, n_Integer?NonNegative, ell_, ass_, limit_, frequencyLimit_] := Module[
  {power = n, base = a, result = {{0, 1}}},
  While[power > 0,
   If[OddQ[power], result = fourierMul[result, base, ell, ass, limit, frequencyLimit]];
   power = Quotient[power, 2];
   If[power > 0, base = fourierMul[base, base, ell, ass, limit, frequencyLimit]]];
  result];
fourierRealQ[a_, ell_, ass_, limit_] := fourierMerge[Join[a,
   {-#[[1]], -Conjugate[#[[2]]]} & /@ a], ell, ass && Element[ell, Reals], limit] === {};
fourierExpression[a_, ell_, ass_] := Simplify[Expand[ExpToTrig[
   Total[(#[[2]] Exp[I #[[1]] ell]) & /@ a]]], ass && Element[ell, Reals]];
fourierDegree[a_, ell_] := If[a === {}, 0, Max[Exponent[#[[2]], ell] & /@ a]];
fourierEnvelope[a_, ell_, size_, ass_] := Total[Function[row,
   Total[MapIndexed[Simplify[Abs[#1], ass] size^(First[#2] - 1) &, CoefficientList[row[[2]], ell]]]] /@ a];

fourierReadCoefficient[expression_, ell_, ass_, frequencyLimit_] := Module[
  {expanded = Expand[TrigToExp[expression]], terms, rows = {}, frequency, polynomial, factors, exponent, omega},
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Do[
   frequency = 0; polynomial = 1; factors = If[Head[term] === Times, List @@ term, {term}];
   Do[Which[
     Head[factor] === Power && factor[[1]] === E && ! FreeQ[factor[[2]], ell],
      exponent = Expand[factor[[2]]];
      If[! PolynomialQ[exponent, ell] || Exponent[exponent, ell] > 1, Return[$Failed, Module]];
      omega = Simplify[Coefficient[exponent, ell]/I, ass];
      If[! exactRealQ[omega], Return[$Failed, Module]];
      frequency += omega; polynomial *= Exp[exponent /. ell -> 0],
     PolynomialQ[factor, ell], polynomial *= factor,
     True, Return[$Failed, Module]], {factor, factors}];
   AppendTo[rows, {frequency, polynomial}], {term, terms}];
  fourierMerge[rows, ell, ass, frequencyLimit]];

fourierJetMerge[rows_, ell_, ass_, limit_, frequencyLimit_] := Module[{groups, result},
  If[rows === {}, Return[{}, Module]];
  groups = fourierWeightGroups[rows];
  result = {#[[1, 1]], fourierMerge[Flatten[#[[All, 2]], 1], ell, ass, frequencyLimit]} & /@ groups;
  result = Select[result, #[[2]] =!= {} &];
  If[Length[result] > limit, fail["ResourceLimit", "The Fourier source-weight jet exceeds MaxTerms."]];
  fourierFrequencyBudget[Length[fourierJetFrequencies[result]], frequencyLimit]; result];
fourierJetTrim[rows_, cutoff_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetMerge[Select[rows, less[First[#], cutoff] &], ell, ass, limit, frequencyLimit];
fourierJetAdd[a_, b_, cutoff_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetTrim[Join[a, b], cutoff, ell, ass, limit, frequencyLimit];
fourierJetScale[a_, c_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetMerge[{#[[1]], fourierScale[#[[2]], c, ell, ass, frequencyLimit]} & /@ a, ell, ass, limit, frequencyLimit];
fourierJetMul[a_, b_, cutoff_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {rows = {}, count = 0, last = Length[b]},
  (* Source jets are sorted. Retain the original row-major convolution and
     failure order while skipping columns beyond the exclusive cutoff. *)
  Do[If[cutoff =!= Infinity,
    While[last > 0 && ! less[aa[[1]] + b[[last, 1]], cutoff], last--]];
   Do[count++; If[count > limit, fail["ResourceLimit", "Fourier jet multiplication exceeded MaxTerms retained pairs."]];
    AppendTo[rows, {aa[[1]] + b[[j, 1]], fourierMul[aa[[2]], b[[j, 2]], ell, ass, limit, frequencyLimit]}],
    {j, last}], {aa, a}];
  fourierJetMerge[rows, ell, ass, limit, frequencyLimit]];

fourierRead[f_, x_, coord_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {u = coord["u"], expression, terms, rows = {}, factors, weight, coefficient, modes},
  expression = Expand[Simplify[f /. x -> coord["Substitution"], ass && u > 0] /. Log[u] -> ell];
  terms = If[Head[expression] === Plus, List @@ expression, {expression}];
  Do[
   weight = 0; coefficient = 1; factors = If[Head[term] === Times, List @@ term, {term}];
   Do[Which[FreeQ[factor, u], coefficient *= factor,
     factor === u, weight++,
     Head[factor] === Power && factor[[1]] === u && exactRealQ[factor[[2]]], weight += factor[[2]],
     True, Return[$Failed, Module]], {factor, factors}];
   modes = fourierReadCoefficient[coefficient, ell, ass, frequencyLimit];
   If[modes === $Failed, Return[$Failed, Module]];
   AppendTo[rows, {weight, modes}], {term, terms}];
  fourierJetMerge[rows, ell, ass, limit, frequencyLimit]];

fourierCoefficient[k_, gaps_, coefficients_, p_, r_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {n = Total[k], weight, modes = {{0, 1}}},
  If[n === 0, Return[{0, modes}, Module]];
  If[n > limit, fail["ResourceLimit", "The Fourier coefficient depth exceeds MaxTerms."]];
  weight = canon[k . gaps];
  Do[If[k[[j]] > 0,
    modes = fourierMul[modes, fourierPower[coefficients[[j]], k[[j]], ell, ass, limit, frequencyLimit],
      ell, ass, limit, frequencyLimit]], {j, Length[k]}];
  Do[modes = fourierAdd[fourierEuler[modes, ell, ass, frequencyLimit],
     fourierScale[modes, r + weight + p j, ell, ass, frequencyLimit], ell, ass, frequencyLimit], {j, 1, n - 1}];
  {weight, fourierScale[modes, (-1)^n r/(p^n Times @@ (Factorial /@ k)), ell, ass, frequencyLimit]}];

fourierComposeBlock[u_, power_, modes_, cutoff_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {answer, product = {{0, {{0, 1}}}}, coefficient = modes, k = 0},
  answer = fourierJetTrim[{{0, modes}}, cutoff, ell, ass, limit, frequencyLimit];
  If[u === {}, Return[answer, Module]];
  If[! less[0, u[[1, 1]]], fail["NonSmallJet", "Fourier unit composition needs positive source-weight valuation."]];
  While[True,
   If[k >= limit, fail["ResourceLimit", "Fourier unit composition exceeded MaxTerms iterations."]];
   product = fourierJetMul[product, u, cutoff, ell, ass, limit, frequencyLimit];
   If[product === {}, Break[]];
   coefficient = fourierScale[fourierAdd[fourierEuler[coefficient, ell, ass, frequencyLimit],
       fourierScale[coefficient, power - k, ell, ass, frequencyLimit], ell, ass, frequencyLimit],
     1/(k + 1), ell, ass, frequencyLimit];
   If[coefficient === {}, Break[]];
   answer = fourierJetAdd[answer, fourierJetMul[product, {{0, coefficient}}, cutoff, ell, ass, limit, frequencyLimit],
     cutoff, ell, ass, limit, frequencyLimit]; k++];
  answer];

fourierConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse`AsymptoticFourierInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse`AsymptoticFourierInverse, {opts}],
   direction = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, Direction],
   r = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, "Power"],
   limit = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, "MaxTerms"],
   frequencyLimit = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, "MaxFrequencies"],
   input = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, "InputRemainder"],
   method = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, Method],
   truncation = OptionValue[AsymptoticInverse`AsymptoticFourierInverse, {opts}, "Truncation"],
   coord, ell = Unique["fourierLog$"], rows, offset = 0, p, amplitude, gaps, coefficients,
   rint, h, region, blocks, boundary, beta, degree, degrees, inputCap, inputDegree,
   sign, target, w, z, logz, terms, expression, rem, domain, frequencies},
  If[! FreeQ[f, _Real], fail["InexactInput", "Fourier input and frequencies must be exact."]];
  If[! FreeQ[f, Indeterminate | _DirectedInfinity], fail["NonfiniteInput", "The Fourier expression must contain finite constants."]];
  If[! IntegerQ[limit] || limit < 1 || ! IntegerQ[frequencyLimit] || frequencyLimit < 1,
   fail["InvalidOption", "MaxTerms and MaxFrequencies must be positive integers."]];
  If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y], fail["InvalidVariables", "Use distinct source and target symbols, and parameter-only assumptions."]];
  If[method =!= "Lagrange" || truncation =!= "Exponent",
   fail["UnsupportedOption", "The Fourier engine uses Lagrange coefficients and explicit exponent truncation."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[! exactRealQ[cutoff], fail["InvalidCutoff", "The Fourier engine requires an explicit exact target-power cutoff."]];
  coord = localCoordinate[x, x0, direction];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative source branch requires integer observable powers."]];
  rows = fourierRead[f, x, coord, ell, ass, limit, frequencyLimit];
  If[rows === $Failed, Return[$Failed, Module]];
  If[rows === {}, fail["ZeroFunction", "The Fourier expression is zero or constant."]];
  If[! And @@ (fourierRealQ[#[[2]], ell, ass, frequencyLimit] & /@ rows),
   fail["NonRealFourierCoefficient", "The Fourier coefficients do not satisfy the real conjugacy relations under the assumptions."]];
  If[rows[[1, 1]] === 0 && MatchQ[rows[[1, 2]], {{0, _}}] && FreeQ[rows[[1, 2, 1, 2]], ell],
   offset = rows[[1, 2, 1, 2]]; rows = Rest[rows]];
  If[rows === {}, fail["ZeroFunction", "The Fourier expression is constant."]];
  p = rows[[1, 1]];
  If[p === 0 || ! MatchQ[rows[[1, 2]], {{0, _}}] || ! FreeQ[rows[[1, 2, 1, 2]], ell],
   fail["OscillatoryLeadingBlock", "The Fourier engine requires a nonzero monomial leading core; oscillatory or logarithmic leading coefficients are not assigned an eventual sign."]];
  amplitude = rows[[1, 2, 1, 2]];
  If[! (provablyPositive[amplitude, ass] || provablyNegative[amplitude, ass]), fail["UnprovedSign", "The monomial leading coefficient must have a proved nonzero real sign."]];
  gaps = canon[#[[1]] - p] & /@ Rest[rows];
  coefficients = fourierScale[#[[2]], 1/amplitude, ell, ass, frequencyLimit] & /@ Rest[rows];
  rint = If[coord["Infinite"], -r, r]; h = canon[Abs[p] cutoff - rint];
  If[! less[0, h], fail["CutoffTooSmall", "The target cutoff must exceed the leading observable exponent."]];
  region = indexRegion[gaps, h, False, limit];
  blocks = fourierJetMerge[fourierCoefficient[#, gaps, coefficients, p, rint, ell, ass, limit, frequencyLimit] & /@
     region["Inside"], ell, ass, limit, frequencyLimit];
  boundary = region["Boundary"];
  beta = If[boundary === {}, Infinity, Min[canon[# . gaps] & /@ boundary]];
  degrees = fourierDegree[#, ell] & /@ coefficients;
  degree = If[boundary === {}, 0, Max[(# . degrees) & /@ boundary]];
  beta = If[beta === Infinity, Infinity, canon[(rint + beta)/Abs[p]]];
  If[! MemberQ[{None, Automatic}, input],
   If[! MatchQ[input, {_?exactRealQ, _Integer?NonNegative}] || ! less[rows[[-1, 1]], input[[1]]],
    fail["InvalidInputRemainder", "InputRemainder must have an exact exponent above all supplied source powers and a nonnegative logarithmic degree; a matching derivative bound is required."]];
   inputCap = canon[(input[[1]] - p + rint)/Abs[p]];
   If[less[inputCap, cutoff], fail["InsufficientInputOrder", "The Fourier request exceeds the transported forward precision.", <|"MaximumCutoff" -> inputCap|>]];
   If[less[inputCap, beta], beta = inputCap; degree = input[[2]],
    If[equal[inputCap, beta], degree = Max[degree, input[[2]]]]]];
  sign = If[provablyPositive[amplitude, ass], 1, -1]; target = (y - offset)/amplitude;
  w = If[less[0, p], sign (y - offset), sign/y]; z = target^(1/p); logz = Log[target]/p;
  terms = {canon[(rint + #[[1]])/Abs[p]],
      coord["Sign"]^r Abs[amplitude]^(-(rint + #[[1]])/p) (fourierExpression[#[[2]], ell, ass] /. ell -> logz)} & /@ blocks;
  expression = If[r === 1 && ! coord["Infinite"], x0, 0] + Total[(w^#[[1]] #[[2]]) & /@ terms];
  rem = If[beta === Infinity, 0, PowerLogRemainder[w, beta, degree]];
  frequencies = fourierJetFrequencies[blocks];
  domain = ass && target > 0 && 0 < z < 1;
  GeneralizedSeries[<|"Kind" -> "FourierInverse", "Scale" -> "FourierPolynomialCoefficients", "Method" -> "Lagrange",
    "Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "FourierFrequencies" -> frequencies, "MaxFrequencies" -> frequencyLimit,
    "CoefficientEnvelopes" -> ({#[[1]], fourierEnvelope[#[[2]], ell, 1 + Abs[logz], ass]} & /@ blocks),
    "Remainder" -> rem, "RemainderVariable" -> w, "RemainderPower" -> beta, "RemainderLogDegree" -> degree,
    "RemainderScaleExpression" -> If[beta === Infinity, 0, w^beta (1 + Abs[Log[w]])^degree],
    "RemainderExplanation" -> "The complete boundary is bounded with Fourier coefficient norms and polynomial envelopes; zeros of individual oscillatory factors are never used as error scales.",
    "RemainderDerivativeOrder" -> 0, "LogVariable" -> ell, "LogarithmicValue" -> logz,
    "Uniformizer" -> z, "NormalizedSourceWeightCutoff" -> h, "Cutoff" -> cutoff, "Power" -> r,
    "IndexRegion" -> region, "PowerGaps" -> gaps, "NormalizedCoefficients" -> coefficients,
    "CoefficientDegreeBounds" -> degrees, "LeadingPower" -> p, "LeadingCoefficient" -> amplitude,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "Limit" -> If[less[0, p], offset, sign Infinity], "Assumptions" -> ass, "TargetDomain" -> domain,
    "InputRemainder" -> input, "ExactModel" -> MemberQ[{None, Automatic}, input],
    "TermConvention" -> "Each {beta,C} contributes w^beta C in the positive RemainderVariable w. Blocks store source-weight corrections with finite Fourier-polynomial modes in LogVariable.",
    "ConvergenceContract" -> <|"Type" -> "FiniteAnalyticFourierLift", "NumericCertificate" -> False|>,
    "SeriesData" -> Missing["FourierCoefficientScale"]|>]];

AsymptoticInverse`AsymptoticFourierInverse[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] := catch[
  Module[{result = fourierConstruct[f, x, x0, y, cutoff, opts]},
   If[result === $Failed, fail["UnsupportedFourierScale", "The expression is not a finite power sum with Fourier-polynomial logarithmic coefficients."], result]]];
AsymptoticInverse`AsymptoticFourierInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticFourierInverse[f,{x,x0},{y,cutoff}], with an explicit exact cutoff."|>];

fourierResidual[a_, cutoff_, limit_] := Module[
  {ell = a["LogVariable"], ass = a["Assumptions"], frequencyLimit = a["MaxFrequencies"],
   h = cutoff, r, unit, answer, part, gaps = a["PowerGaps"], coefficients = a["NormalizedCoefficients"], p = a["LeadingPower"]},
  If[h === Automatic, h = a["NormalizedSourceWeightCutoff"]];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "The Fourier residual cutoff must be positive and exact."]];
  r = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  unit = Select[a["Blocks"], less[0, #[[1]]] &];
  If[r =!= 1,
   unit = fourierJetAdd[fourierComposeBlock[unit, 1/r, {{0, 1}}, h, ell, ass, limit, frequencyLimit],
     {{0, {{0, -1}}}}, h, ell, ass, limit, frequencyLimit]];
  answer = fourierJetAdd[fourierComposeBlock[unit, p, {{0, 1}}, h, ell, ass, limit, frequencyLimit],
    {{0, {{0, -1}}}}, h, ell, ass, limit, frequencyLimit];
  Do[If[less[gaps[[j]], h],
    part = fourierComposeBlock[unit, p + gaps[[j]], coefficients[[j]], h - gaps[[j]], ell, ass, limit, frequencyLimit];
    answer = fourierJetAdd[answer, {#[[1]] + gaps[[j]], #[[2]]} & /@ part, h, ell, ass, limit, frequencyLimit]], {j, Length[gaps]}];
  <|"ZeroBelowCutoff" -> (answer === {}), "ResidualBlocks" -> answer,
    "NormalizedResidual" -> Total[(a["Uniformizer"]^#[[1]] (fourierExpression[#[[2]], ell, ass] /. ell -> a["LogarithmicValue"])) & /@ answer],
    "RelativeCutoff" -> h, "Scope" -> "Exact formal composition with the stored finite Fourier forward expression; unspecified InputRemainder terms are not composed."|>];
Options[AsymptoticInverse`FourierInverseResidual] = {"MaxTerms" -> 20000};
AsymptoticInverse`FourierInverseResidual[GeneralizedSeries[a_Association], cutoff_: Automatic, OptionsPattern[]] := catch[
  If[Lookup[a, "Kind", None] =!= "FourierInverse", fail["UnsupportedResidual", "A Fourier inverse object is required."]];
  fourierResidual[a, cutoff, OptionValue["MaxTerms"]]];
AsymptoticInverse`FourierInverseResidual[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use FourierInverseResidual[FourierInverseResult] or FourierInverseResidual[result,relativeCutoff]."|>];
AsymptoticInverse`FourierInverseCoefficient[GeneralizedSeries[a_Association], k_List] := catch[Module[{r, coefficient},
  If[Lookup[a, "Kind", None] =!= "FourierInverse" || Length[k] =!= Length[a["PowerGaps"]] ||
    ! And @@ (IntegerQ[#] && NonNegative[#] & /@ k), fail["InvalidMultiIndex", "Supply a nonnegative integer multi-index of the Fourier model's dimension."]];
  r = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  coefficient = fourierCoefficient[k, a["PowerGaps"], a["NormalizedCoefficients"], a["LeadingPower"], r,
    a["LogVariable"], a["Assumptions"], 20000, a["MaxFrequencies"]];
  <|"Weight" -> coefficient[[1]], "Modes" -> coefficient[[2]],
    "Expression" -> fourierExpression[coefficient[[2]], a["LogVariable"], a["Assumptions"]],
    "LogVariable" -> a["LogVariable"]|>]];
AsymptoticInverse`FourierInverseCoefficient[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use FourierInverseCoefficient[FourierInverseResult,nonnegativeIntegerMultiIndex]."|>];
