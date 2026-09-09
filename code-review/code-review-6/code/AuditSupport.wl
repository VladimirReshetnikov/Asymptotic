(* Proposed audit helpers. Native Wolfram execution was unavailable during
   this review. These helpers do not modify the upstream package. *)
BeginPackage["AsymptoticAudit`"];
DenseSeriesPlan::usage = "DenseSeriesPlan[terms,{rho,degree}] plans a rational-lattice export without allocating coefficients. It rejects logarithmic remainder loss and an excessive dense span.";
InverseCoefficientForPower::usage = "InverseCoefficientForPower[s,k,\"Power\"->Automatic] obtains a normalized ordinary inverse coefficient; Automatic inherits the stored source-observable power. An explicit power overrides it before source-infinity conversion.";
RequiredProductPrecision::usage = "RequiredProductPrecision[alpha,beta,H] returns minimum operand error exponents for a product of valuations alpha and beta at target error exponent H. Logarithmic degrees require a separate contract.";
Options[DenseSeriesPlan] = {"MaxDenseCoefficients" -> 200000};
Options[InverseCoefficientForPower] = {"Power" -> Automatic};
Begin["`Private`"];
rationalQ[q_] := IntegerQ[q] || Head[q] === Rational;
DenseSeriesPlan[terms_List, {rho_, degree_}, OptionsPattern[]] := Module[
  {budget = OptionValue["MaxDenseCoefficients"], exps, den, low, high, count},
  If[! IntegerQ[budget] || budget < 0,
    Return[Failure["InvalidBudget", <|"MessageTemplate" -> "Use a nonnegative integer dense-coefficient budget."|>]]];
  If[! AllTrue[terms, MatchQ[#, {_, _}] &] || ! rationalQ[rho] ||
      ! IntegerQ[degree] || degree < 0,
    Return[Failure["InvalidData", <|"MessageTemplate" -> "Use exponent/coefficient pairs and an exact rational frontier with nonnegative log degree."|>]]];
  exps = If[terms === {}, {}, terms[[All, 1]]];
  If[! AllTrue[exps, rationalQ],
    Return[<|"Admissible" -> False, "Reason" -> "NonrationalLattice"|>]];
  If[! AllTrue[exps, # < rho &],
    Return[Failure["InvalidFrontier", <|"MessageTemplate" -> "All retained exponents must lie strictly below the frontier."|>]]];
  den = LCM @@ (Denominator /@ Append[exps, rho]);
  low = If[exps === {}, rho den, Min[exps] den]; high = rho den;
  count = high - low;
  <|"Admissible" -> (degree === 0 && count <= budget),
    "Reason" -> Which[degree > 0, "LogarithmicRemainder", count > budget,
      "DenseRepresentationBudget", True, "WithinBudget"],
    "Denominator" -> den, "MinimumIndex" -> low, "MaximumIndex" -> high,
    "DenseCoefficientCount" -> count, "SparseBlockCount" -> Length[terms],
    "RemainderContractPreserved" -> (degree === 0)|>];
DenseSeriesPlan[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use DenseSeriesPlan[terms,{rho,degree}]."|>];

InverseCoefficientForPower[s_AsymptoticInverse`GeneralizedSeries, k_List,
    OptionsPattern[]] := Module[{a = s[[1]], r = OptionValue["Power"], internal},
  If[! AssociationQ[a] || Lookup[a, "Kind", None] =!= "Inverse" ||
      Lookup[a, "Scale", "PowerLog"] =!= "PowerLog" ||
      ! AssociationQ[Lookup[a, "Model", None]],
    Return[Failure["UnsupportedCoefficientKind", <|"MessageTemplate" ->
      "An ordinary power-log inverse with a stored model is required."|>]]];
  If[r === Automatic, r = Lookup[a, "Power", 1]];
  If[! NumericQ[r] || ! FreeQ[r, _Real | _Complex] ||
      ! TrueQ[FullSimplify[Element[r, Reals] && r != 0]],
    Return[Failure["InvalidPower", <|"MessageTemplate" -> "Use a nonzero exact real observable power."|>]]];
  If[! IntegerQ[r] && (Lookup[a, "ExpansionPoint", 0] === -Infinity ||
      (! MemberQ[{Infinity, -Infinity}, Lookup[a, "ExpansionPoint", 0]] &&
        Lookup[a, "Direction", "FromAbove"] === "FromBelow")),
    Return[Failure["NonrealObservable", <|"MessageTemplate" ->
      "A negative source branch requires an integer observable power."|>]]];
  internal = If[MemberQ[{Infinity, -Infinity}, Lookup[a, "ExpansionPoint", 0]], -r, r];
  AsymptoticInverse`InverseExpansionCoefficient[a["Model"], k, "Power" -> internal]];
InverseCoefficientForPower[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseCoefficientForPower[s,k]."|>];

RequiredProductPrecision[alpha_, beta_, target_] :=
  <|"LeftErrorExponentAtLeast" -> target - beta,
    "RightErrorExponentAtLeast" -> target - alpha,
    "Contract" -> "Assumes valid valuations and ordinary magnitude remainders; also check the product of the two error terms and all logarithmic degrees."|>;
End[];
EndPackage[];
