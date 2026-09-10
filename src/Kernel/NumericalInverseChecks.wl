(* Numerical evidence for inverse objects and their power observables.
   Exact target substitution precedes numerical evaluation so large offsets
   do not erase the small target distance. This is not certification. *)

(* Shared by ordinary and coordinate-specific numerical routes. The source
   predicate is checked at the recovered source root, not at an observable
   power or at the expansion seed. This is numerical evidence only. *)
numericalSourceDomainCheck[a_, root_, target_, wp_, chart_: None] := Module[{x, y, condition, evaluated},
  x = If[MatchQ[Lookup[a, "Variables", {}], {_Symbol, _Symbol}],
    First[a["Variables"]], inverseEvidenceSourceVariable[a]];
  y = Lookup[a, "Variable", Missing["NotSpecified"]];
  condition = inverseEvidenceSourceDomain[a, x];
  (* With a local chart {u, x0 + side u, u0}, substitute the exact source
     transformation first so an affine condition such as x - x0 > 0 cancels
     symbolically to u > 0 before the numerical local root is inserted. *)
  evaluated = If[MatchQ[chart, {_Symbol, _, _}],
    (condition /. x -> chart[[2]]) /. chart[[1]] -> chart[[3]], condition /. x -> root];
  If[MatchQ[y, _Symbol] && y =!= x, evaluated = evaluated /. y -> target];
  If[! TrueQ[Quiet[Check[N[evaluated, wp + 10], False]]],
    fail["OutsideBranch", "The recovered numerical source root does not satisfy the retained source-domain condition.",
      <|"UnprovedCondition" -> condition, "ReferenceRoot" -> root, "Target" -> target|>]];
  True];

(* The solve, the branch test and the error comparison happen in the local
   displacement u with x = x0 + side u at a finite endpoint (u = side x at an
   infinite one). The exact endpoint is substituted symbolically before any
   numerical evaluation, so a small displacement at a huge source origin is
   not lost by rounding two large absolute values and subtracting them; the
   full source value is reconstructed only for presentation, with enough
   digits to show the displacement. *)
(* Endpoint-component reference for an exact numeric polynomial equation
   g(u) - target = 0 in the local displacement u > 0. The component incident
   to the endpoint is (0, u1) where u1 is the least positive critical point of
   g, or the whole ray without one; the equation's real roots inside it are
   isolated exactly and the unique one is returned. Returns
   {"Verified", root, {0, u1}, message} or {"Refused", None, {0, u1}, data};
   {"Unverified", None, "NotPolynomial", None} leaves the numerical root as
   found. *)
numericalEndpointComponent[equation_, u_, localRoot_, wp_] := Module[
  {g, coefficients, critical, upper, roots, inside, real},
  g = Expand[equation];
  If[! PolynomialQ[g, u], Return[{"Unverified", None, "NotPolynomial", None}, Module]];
  coefficients = CoefficientList[g, u];
  If[! (And @@ (NumericQ[#] && exactQ[#] & /@ coefficients)) || ! (And @@ (TrueQ[Im[#] == 0] & /@ coefficients)),
    Return[{"Unverified", None, "NotExactNumericPolynomial", None}, Module]];
  real = Function[values, Select[values, TrueQ[Im[N[#, wp + 10]] == 0] && TrueQ[N[#, wp + 10] > 0] &]];
  critical = numericalPolynomialRoots[D[g, u], u];
  If[critical === $Failed, Return[{"Unverified", None, "CriticalPointsUnresolved", None}, Module]];
  critical = real[critical];
  upper = If[critical === {}, Infinity, First[Sort[critical, N[#1, wp + 10] < N[#2, wp + 10] &]]];
  roots = numericalPolynomialRoots[g, u];
  If[roots === $Failed, Return[{"Unverified", None, "RootsUnresolved", None}, Module]];
  roots = real[roots];
  inside = Select[roots, upper === Infinity || TrueQ[N[#, wp + 10] < N[upper, wp + 10]] &];
  Which[Length[inside] === 1,
    {"Verified", N[First[inside], wp + 10], {0, upper}, "Unique equation root inside the endpoint-incident monotone component."},
   inside === {},
    {"Refused", None, {0, upper}, <|"Reason" -> "NoRootInEndpointComponent", "EndpointComponent" -> {0, upper},
      "NumericalRoot" -> localRoot, "Explanation" -> "The equation has no root on the monotone source component incident to the endpoint; the numerical root found belongs to another branch."|>},
   True,
    {"Refused", None, {0, upper}, <|"Reason" -> "AmbiguousEndpointComponent", "EndpointComponent" -> {0, upper},
      "RootsInComponent" -> Length[inside]|>}]];

(* Exact roots of a numeric polynomial as a list, or $Failed when the solver
   returns anything but a list of substitution rules. *)
numericalPolynomialRoots[g_, u_] := Module[{solutions},
  If[FreeQ[g, u], Return[{}, Module]];
  solutions = Quiet[Check[Solve[g == 0, u], $Failed]];
  If[! MatchQ[solutions, {{_Rule} ...}], Return[$Failed, Module]];
  u /. solutions];

numericalInverseEvidence[a_, target_, wp_] := Module[
 {x, y, u, power, endpoint, side, shift, finite, domain, localApproximate, approximate,
  localSeed, localEquation, localRoot, root, observed, error, scale, remainder, gap, component},
 If[! IntegerQ[wp] || wp < 10,
  fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
 If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp),
  fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
 If[! MemberQ[{"Inverse", "CoreInverse", "ExponentialCoreInverse", "FlatInverse", "FourierInverse", "LogarithmicInverse"}, Lookup[a, "Kind", ""]],
  fail["Unsupported", "Numerical checks require an inverse expansion with a retained original equation."]];
 {x, y} = a["Variables"]; power = a["Power"]; endpoint = a["ExpansionPoint"];
 finite = ! MemberQ[{Infinity, -Infinity}, endpoint];
 side = Which[endpoint === Infinity, 1, endpoint === -Infinity, -1,
   a["Direction"] === "FromBelow", -1, True, 1];
 shift = If[finite, endpoint, 0];
 domain = Lookup[a, "TargetDomain", If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]/a["LeadingCoefficient"] > 0];
 If[! TrueQ[N[domain /. y -> target, wp + 10]],
  fail["OutsideBranch", "The target is outside the recorded real asymptotic branch domain."]];
 (* Power one: the expansion approximates x itself, so subtract the exact
    endpoint symbolically and keep the local displacement. Other powers
    already approximate the local observable (x - x0)^power. *)
 localApproximate = N[If[power === 1, side (a["Expression"] - shift), a["Expression"]] /. y -> target, wp + 10];
 If[! finiteNumericQ[localApproximate] || ! TrueQ[Im[localApproximate] == 0],
  fail["OutsideBranch", "The expansion is not real at this target."]];
 localSeed = If[power === 1, localApproximate, Abs[localApproximate]^(1/power)];
 If[! finiteNumericQ[localSeed] || ! TrueQ[Im[localSeed] == 0],
  fail["OutsideBranch", "The observable does not provide a real source seed."]];
 localEquation = (a["Function"] /. x -> shift + side u) - target;
 localRoot = With[{uu = u, eq = localEquation, start = localSeed, precision = wp + 10, goal = wp},
   Quiet[Check[uu /. FindRoot[eq == 0, {uu, start}, WorkingPrecision -> precision,
     AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
 If[localRoot === $Failed || ! finiteNumericQ[localRoot], fail["RootNotFound", "The original equation did not converge from the expansion seed."]];
 If[! TrueQ[Im[localRoot] == 0] || ! TrueQ[localRoot > 0],
  fail["OutsideBranch", "The numerical root is outside the selected original source branch."]];
 (* A root on the selected side need not lie on the inverse branch incident
    to the endpoint: the approximation can itself be an exact root of another
    monotone component. For an exact numeric polynomial source the endpoint
    component is bounded by the first positive critical point; the root is
    taken inside it, or the check refuses (wave-5 report 38 N1). *)
 component = numericalEndpointComponent[localEquation, u, localRoot, wp];
 If[component[[1]] === "Refused", fail["OutsideBranch", component[[3]], component[[4]]]];
 If[component[[1]] === "Verified", localRoot = component[[2]]];
 root = shift + side localRoot;
 numericalSourceDomainCheck[a, root, target, wp, {u, shift + side u, localRoot}];
 (* Extra presentation digits so that the reconstructed absolute source
    values still display the local displacement; local fields use wp. *)
 gap = If[shift === 0 || TrueQ[localRoot == 0], 0,
   Max[0, Ceiling[Log10[N[Abs[shift], 20]]] - Floor[Log10[N[Abs[localRoot], 20]]]]];
 (* Powered observables keep the signed displacement convention (x - x0)^power. *)
 observed = If[power === 1, localRoot, (side localRoot)^power];
 approximate = If[power === 1, shift + side localApproximate, localApproximate];
 remainder = Lookup[a, "RemainderScaleExpression", a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]];
 scale = N[remainder /. y -> target, wp];
 error = N[Abs[observed - localApproximate], wp];
 <|"ReferenceRoot" -> N[root, wp + gap], "ExactInverse" -> N[root, wp + gap],
   "ReferenceObservable" -> N[If[power === 1, root, observed], wp + gap], "Approximation" -> N[approximate, wp + gap],
   "ApproximationSourceRoot" -> N[shift + side localSeed, wp + gap], "Error" -> error, "RemainderScale" -> scale,
   "LocalRoot" -> N[localRoot, wp], "LocalApproximation" -> N[localApproximate, wp],
   "LocalReferenceObservable" -> N[observed, wp], "ObservablePower" -> power,
   "SourceOffset" -> shift, "SourceSide" -> side,
   (* LocalRoot is the positive displacement u itself for every power;
      the powered fields are values of the signed observable (SourceSide u)^Power
      (wave-6 reports 48 N3, 51 N02 and 54 N04). *)
   "LocalCoordinate" -> "x = SourceOffset + SourceSide u with u > 0. LocalRoot is always the positive source displacement u. LocalApproximation approximates u for Power 1 and (SourceSide u)^Power otherwise; LocalReferenceObservable is that observable at the recovered root.",
   "SourceDomainChecked" -> inverseEvidenceSourceDomain[a, x], "SourceDomainVerified" -> True,
   "EndpointComponent" -> component[[3]], "BranchComponentVerified" -> (component[[1]] === "Verified"),
   (* A positive test rather than an equality test: Mathics treats a
      low-precision 10^-12 as equal to 0, which made every ratio Indeterminate. *)
   "Ratio" -> If[TrueQ[scale > 0], error/scale, Indeterminate],
   "ForwardResidual" -> N[localEquation /. u -> localSeed, wp], "RootResidual" -> N[localEquation /. u -> localRoot, wp],
   "Scope" -> "Stored explicit forward equation solved in the local source coordinate; a declared input remainder is not a numerical function.",
   "Evidence" -> "High-precision numerical comparison, not an interval certificate. ExactInverse is a legacy alias for ReferenceRoot."|>];
