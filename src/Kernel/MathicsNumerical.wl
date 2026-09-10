(* Loaded late, only on Mathics. Mathics 10's FindRoot evaluates its seed
   and Newton updates at machine precision even when WorkingPrecision is
   supplied. Do not label such a root as a higher-precision comparison.
   An unchanged integer seed may instead be promoted to an exact root when
   direct substitution proves an exact polynomial equation. No digits are
   added to an approximate root and no nearby rational root is guessed. *)

ClearAll[mathicsNumericalFindRoot, mathicsNumericalExactIntegerSeed];

SetAttributes[mathicsNumericalExactIntegerSeed, HoldAllComplete];
mathicsNumericalExactIntegerSeed[held_HoldComplete, variable_Symbol, seed_] :=
  Block[{variable}, Module[{candidate, polynomial},
    If[! NumericQ[seed] || ! TrueQ[Im[seed] == 0], Return[$Failed, Module]];
    (* The exact candidate is the integer or rational the seed denotes
       exactly; anything else, including a rounded 1/3, is verified below by
       exact substitution and fails there (wave-5 report 45 N01). *)
    candidate = Which[IntegerQ[seed] || Head[seed] === Rational, seed,
      SameQ[seed, N[Round[seed], Precision[seed]]], Round[seed],
      True, Rationalize[seed, 0]];
    If[! (IntegerQ[candidate] || Head[candidate] === Rational), Return[$Failed, Module]];
    If[! MatchQ[held, HoldComplete[Equal[_, _]]], Return[$Failed, Module]];
    polynomial = ReleaseHold[held /. HoldPattern[Equal[left_, right_]] :>
      (left - right)];
    If[! exactQ[polynomial] || ! FreeQ[polynomial, Indeterminate | _DirectedInfinity] ||
        ! PolynomialQ[polynomial, variable], Return[$Failed, Module]];
    If[SameQ[polynomial /. variable -> candidate, 0], candidate, $Failed]]];

SetAttributes[mathicsNumericalFindRoot, HoldAll];
mathicsNumericalFindRoot[equation_, {variable_Symbol, start_}, options___] :=
  Module[{goal, seed, exact, result, root, precision},
    goal = PrecisionGoal /. {options};
    seed = start;
    exact = mathicsNumericalExactIntegerSeed[HoldComplete[equation], variable, seed];
    If[exact =!= $Failed, Return[{variable -> exact}, Module]];
    If[NumericQ[goal] && TrueQ[goal > N[MachinePrecision]],
      fail["MathicsNumericalPrecisionUnavailable",
        "Mathics FindRoot cannot supply the requested reference-root precision. No high-precision numerical comparison was produced.",
        <|"RequestedPrecisionGoal" -> goal, "AvailablePrecision" -> N[MachinePrecision],
          "ExactIntegerSeedVerified" -> False|>]];
    result = System`FindRoot[equation, {variable, seed}, options];
    If[NumericQ[goal] && ListQ[result] && Length[result] === 1 &&
        MatchQ[First[result], _Rule],
      root = variable /. result;
      If[NumericQ[root],
        precision = N[Precision[root]];
        If[! TrueQ[precision >= goal],
          fail["MathicsNumericalPrecisionUnavailable",
            "Mathics FindRoot returned fewer reference-root digits than requested. No high-precision numerical comparison was produced.",
            <|"RequestedPrecisionGoal" -> goal, "ReturnedPrecision" -> precision|>]]]];
    result];

(* These are the five package-owned numerical consumers of FindRoot.
   Symbolic construction, direct exact special-inverse evaluation, and
   caller uses of System`FindRoot keep their existing dispatch. *)
Scan[(DownValues[#] = DownValues[#] /. System`FindRoot -> mathicsNumericalFindRoot) &,
  {numericalInverseEvidence, coordinateNumericalCheck, sourceCoordinateNumericalCheck,
   gammaInverseNumerical, specialNumerical}];

(* Mathics 10 returns Indeterminate from an arbitrary-precision N of
   Log[c r] when c is an irrational constant and the rational r is below
   about 10^-17, although N[Log[c] + Log[r]] evaluates. A tail target such as
   Erfc[x] = 10^-20 reaches exactly this form. When a numerical evaluation
   comes back Indeterminate, retry with logarithms of products whose factors
   are all numerically positive split into sums; other logarithms and every
   successful first evaluation are left unchanged. *)
ClearAll[mathicsNumericalN, mathicsNumericalSplitLog, mathicsNumericalSplitLogs,
  mathicsNumericalPositiveFactorQ];
(* Splitting Log[a b] into Log[a] + Log[b] is a branch identity that needs
   every factor positive. A machine-precision sign is not such a proof: an
   exact rational below the double underflow threshold rounds to zero and
   blocks a valid split, and an exactly negative factor can round to a
   positive machine number and license a false one (wave-6 reports 48 N2 and
   54 N03). Only this exact positive grammar authorizes the split; any other
   factor leaves the logarithm unsplit. *)
mathicsNumericalPositiveFactorQ[e_] := Which[
  IntegerQ[e] || Head[e] === Rational, TrueQ[e > 0],
  MemberQ[{Pi, E, EulerGamma, Catalan, GoldenRatio, Degree, System`Glaisher, System`Khinchin}, e], True,
  Head[e] === Times || Head[e] === Plus, And @@ (mathicsNumericalPositiveFactorQ /@ List @@ e),
  Head[e] === Power && (IntegerQ[e[[2]]] || Head[e[[2]]] === Rational),
    mathicsNumericalPositiveFactorQ[e[[1]]],
  Head[e] === Power && e[[1]] === E && (IntegerQ[e[[2]]] || Head[e[[2]]] === Rational), True,
  Head[e] === Log && Length[e] === 1 && (IntegerQ[e[[1]]] || Head[e[[1]]] === Rational), TrueQ[e[[1]] > 1],
  True, False];
mathicsNumericalSplitLog[factors_List] :=
  If[And @@ (mathicsNumericalPositiveFactorQ /@ factors), Total[Log /@ factors], Log[Times @@ factors]];
(* Log[p_Times] with List @@ p: in Mathics, Times[factors__] binds the
   whole product to a single sequence element, so it never splits. The
   factors are processed first, so Log[-Log[c r]] still splits its inner
   logarithm although its own factor -1 is negative. *)
mathicsNumericalSplitLogs[expr_] := expr /. Log[product_Times] :>
  mathicsNumericalSplitLog[mathicsNumericalSplitLogs /@ (List @@ product)];
mathicsNumericalN[expr_, precision_] := Module[{value = N[expr, precision], split},
  If[FreeQ[value, Indeterminate], Return[value, Module]];
  split = mathicsNumericalSplitLogs[expr];
  If[split === expr, value, N[split, precision]]];
mathicsNumericalN[expr_] := mathicsNumericalN[expr, MachinePrecision];
Scan[(DownValues[#] = DownValues[#] /. System`N -> mathicsNumericalN) &,
  {numericalInverseEvidence, coordinateNumericalCheck, sourceCoordinateNumericalCheck,
   gammaInverseNumerical, specialNumerical}];
