(* Numerical evidence for inverse objects and their power observables.
   Exact target substitution precedes numerical evaluation so large offsets
   do not erase the small target distance. This is not certification. *)

numericalInverseEvidence[a_, target_, wp_] := Module[
 {x, y, power, endpoint, side, domain, approximate, seed, equation, root,
  sourceDistance, observed, error, scale, remainder},
 If[! IntegerQ[wp] || wp < 10,
  fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
 If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp),
  fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
 If[! MemberQ[{"Inverse", "CoreInverse", "ExponentialCoreInverse", "FlatInverse", "FourierInverse", "LogarithmicInverse"}, Lookup[a, "Kind", ""]],
  fail["Unsupported", "Numerical checks require an inverse expansion with a retained original equation."]];
 {x, y} = a["Variables"]; power = a["Power"]; endpoint = a["ExpansionPoint"];
 side = Which[endpoint === Infinity, 1, endpoint === -Infinity, -1,
   a["Direction"] === "FromBelow", -1, True, 1];
 domain = Lookup[a, "TargetDomain", If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]/a["LeadingCoefficient"] > 0];
 If[! TrueQ[N[domain /. y -> target, wp + 10]],
  fail["OutsideBranch", "The target is outside the recorded real asymptotic branch domain."]];
 approximate = N[a["Expression"] /. y -> target, wp + 10];
 If[! NumericQ[approximate] || ! TrueQ[Im[approximate] == 0],
  fail["OutsideBranch", "The expansion is not real at this target."]];
 seed = If[power === 1, approximate,
   If[MemberQ[{Infinity, -Infinity}, endpoint], 0, endpoint] + side Abs[approximate]^(1/power)];
 If[! NumericQ[seed] || ! TrueQ[Im[seed] == 0],
  fail["OutsideBranch", "The observable does not provide a real source seed."]];
 equation = a["Function"] - target;
 root = With[{xx = x, eq = equation, start = seed, precision = wp + 10, goal = wp},
   Quiet[Check[xx /. FindRoot[eq == 0, {xx, start}, WorkingPrecision -> precision,
     AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
 If[root === $Failed || ! NumericQ[root], fail["RootNotFound", "The original equation did not converge from the expansion seed."]];
 sourceDistance = If[MemberQ[{Infinity, -Infinity}, endpoint], side root, side (root - endpoint)];
 If[! TrueQ[Im[root] == 0] || ! TrueQ[sourceDistance > 0],
  fail["OutsideBranch", "The numerical root is outside the selected original source branch."]];
 observed = Which[power === 1, root, MemberQ[{Infinity, -Infinity}, endpoint], root^power,
   True, (root - endpoint)^power];
 remainder = Lookup[a, "RemainderScaleExpression", a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]];
 scale = N[remainder /. y -> target, wp];
 error = N[Abs[observed - approximate], wp];
 <|"ReferenceRoot" -> N[root, wp], "ExactInverse" -> N[root, wp],
   "ReferenceObservable" -> N[observed, wp], "Approximation" -> N[approximate, wp],
   "ApproximationSourceRoot" -> N[seed, wp], "Error" -> error, "RemainderScale" -> scale,
   "Ratio" -> If[TrueQ[scale == 0], Indeterminate, error/scale],
   "ForwardResidual" -> N[equation /. x -> seed, wp], "RootResidual" -> N[equation /. x -> root, wp],
   "Scope" -> "Stored explicit forward equation; a declared input remainder is not a numerical function.",
   "Evidence" -> "High-precision numerical comparison, not an interval certificate. ExactInverse is a legacy alias for ReferenceRoot."|>];
