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
    candidate = Round[seed];
    If[! IntegerQ[candidate] || ! (SameQ[seed, candidate] ||
        SameQ[seed, N[candidate, Precision[seed]]]), Return[$Failed, Module]];
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
