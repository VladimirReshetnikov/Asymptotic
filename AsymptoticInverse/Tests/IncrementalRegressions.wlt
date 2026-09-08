(* Incremental frontiers, precision doubling, and collision-grouped coefficients. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
 Module[{ell, d = {1/2, 1, 3/2}, s, region, expected, ok = True},
  s = AsymptoticInverse`Private`incrementalInverseState[d, {1 + ell, 2 - ell, ell^2}, 2, 1, ell, True, 1000];
  Do[
   s = AsymptoticInverse`Private`advanceInverseState[s];
   region = AsymptoticInverse`Private`incrementalInverseRegion[s];
   expected = AsymptoticInverse`Private`indexRegion[d, s["LastWeight"], True, 1000];
   ok = ok && Sort[region["Inside"]] === Sort[expected["Inside"]] &&
      Sort[region["Boundary"]] === Sort[expected["Boundary"]] &&
      s["CoefficientEvaluations"] == Length[region["Inside"]], {7}]; ok],
 True, TestID -> "incremental-frontier-matches-independent-region-at-every-layer"]

VerificationTest[
 Module[{ell, d = {Sqrt[2], Sqrt[3], Sqrt[5 + 2 Sqrt[6]]}, s, rows, steps = 0},
  s = AsymptoticInverse`Private`incrementalInverseState[d, {1, 1, 2 + Sqrt[2] + Sqrt[3]}, 1, 1, ell, True, 100];
  While[AsymptoticInverse`Private`leq[s["NextWeight"], Sqrt[2] + Sqrt[3]] && steps++ < 20,
   s = AsymptoticInverse`Private`advanceInverseState[s]];
  rows = Select[s["Blocks"], AsymptoticInverse`Private`equal[First[#], Sqrt[2] + Sqrt[3]] &];
  {rows, Count[s["Inside"], {1, 1, 0} | {0, 0, 1}]}],
 {{}, 2}, TestID -> "incremental-frontier-canonicalizes-and-cancels-algebraic-collisions"]

VerificationTest[
 Module[{ell, s, next},
  s = AsymptoticInverse`Private`incrementalInverseState[{}, {}, 2, -1, ell, True, 1];
  next = AsymptoticInverse`Private`advanceInverseState[s];
  {next["Blocks"], next["NextWeight"], next["CoefficientEvaluations"],
   AsymptoticInverse`Private`advanceInverseState[next] === next, s["Inside"]}],
 {{{0, 1}}, Infinity, 1, True, {}}, TestID -> "incremental-empty-model-terminates-and-preserves-input-state"]

VerificationTest[
 Module[{ell, s}, s = AsymptoticInverse`Private`incrementalInverseState[{1, 2}, {1, 1}, 1, 1, ell, True, 2];
  AsymptoticInverse`Private`catch[AsymptoticInverse`Private`advanceInverseState[s]]],
 Failure["ResourceLimit", _Association], SameTest -> MatchQ,
 TestID -> "incremental-frontier-counts-unique-inside-and-boundary-budget"]

VerificationTest[
 Module[{ell, s, expected, d = {1, 2}, b},
  b = {1 + ell, 2 - ell};
  s = AsymptoticInverse`Private`incrementalInverseState[d, b, -2, 3/2, ell, True, 1000];
  Do[s = AsymptoticInverse`Private`advanceInverseState[s], {6}];
  expected = AsymptoticInverse`Private`jetMerge[
   AsymptoticInverse`Private`lagrangeCoefficient[#, d, b, -2, 3/2, ell, True, False] & /@
    AsymptoticInverse`Private`indexRegion[d, s["LastWeight"], True, 1000]["Inside"], ell, True];
  s["Blocks"] === expected],
 True, TestID -> "incremental-coefficients-agree-for-negative-leading-power-and-fractional-observable"]

VerificationTest[
 Module[{ell, d = {1/2, 3/2}, b, s, refined, direct},
  b = {1 + ell, 2 - ell};
  s = AsymptoticInverse`Private`refineNewtonState[
    AsymptoticInverse`Private`newtonInverseState[d, b, 2, ell, True, 20000], 2];
  refined = AsymptoticInverse`Private`refineNewtonState[s, 5];
  direct = AsymptoticInverse`Private`newtonSolveDoubling[d, b, 2, 5, ell, True, 20000];
  {refined["StepCutoffs"], refined["UnitJet"] === direct,
   AsymptoticInverse`Private`jetTrim[refined["UnitJet"], 2, ell, True] === s["UnitJet"],
   s["Precision"]}],
 {{1, 2, 4, 5}, True, True, 2}, TestID -> "newton-state-refinement-reuses-exact-prefix-and-doubles-precision"]

VerificationTest[
 Module[{ell, s},
  s = AsymptoticInverse`Private`refineNewtonState[
    AsymptoticInverse`Private`newtonInverseState[{1}, {1}, 1, ell, True, 1000], 4];
  AsymptoticInverse`Private`refineNewtonState[s, 2] === s],
 True, TestID -> "newton-state-does-not-discard-certified-precision"]

VerificationTest[
 Module[{ell, d = {Sqrt[2], Sqrt[3]}, b, u, expected},
  b = {1 + ell, 2 - ell};
  u = AsymptoticInverse`Private`newtonSolveDoubling[d, b, -2, 5, ell, True, 20000];
  expected = AsymptoticInverse`Private`jetMerge[
   AsymptoticInverse`Private`lagrangeCoefficient[#, d, b, -2, 1, ell, True, False] & /@
    AsymptoticInverse`Private`indexRegion[d, 5, False, 20000]["Inside"], ell, True];
  AsymptoticInverse`Private`jetMerge[Join[u, {{0, 1}},
    AsymptoticInverse`Private`jetScale[expected, -1, ell, True]], ell, True] === {}],
 True, TestID -> "doubling-newton-agrees-with-lagrange-for-incommensurate-log-gaps"]

VerificationTest[
 Module[{ell}, {AsymptoticInverse`Private`newtonSolveDoubling[{3/2}, {ell}, 1, 1, ell, True, 20],
  AsymptoticInverse`Private`newtonSolveDoubling[{}, {}, 1, Infinity, ell, True, 20]}],
 {{}, {}}, TestID -> "doubling-newton-handles-pre-gap-and-exact-monomial-cutoffs"]

VerificationTest[
 Module[{ell, s},
  s = AsymptoticInverse`Private`newtonInverseState[{1}, {1}, 1, ell, True, 1000];
  AsymptoticInverse`Private`catch[AsymptoticInverse`Private`refineNewtonState[s, Infinity]]],
 Failure["InvalidCutoff", _Association], SameTest -> MatchQ,
 TestID -> "nontrivial-newton-state-rejects-infinite-refinement"]

VerificationTest[
 Module[{ell, d = {1, 2, 3}, b, expected},
  b = {1 + ell, 2 - ell, ell^2};
  And @@ Flatten[Table[
   expected = AsymptoticInverse`Private`jetMerge[
     AsymptoticInverse`Private`lagrangeCoefficient[#, d, b, p, r, ell, True, False] & /@
      AsymptoticInverse`Private`indexRegion[d, 6, False, 20000]["Inside"], ell, True];
   AsymptoticInverse`Private`groupedLagrangeBlocks[d, b, p, r, 6, ell, True, 20000] === expected,
   {p, {1, -2}}, {r, {1, -1, 3/2}}]]],
 True, TestID -> "grouped-lagrange-matches-individual-coefficients-with-many-resonances"]

VerificationTest[
 Module[{ell, d = {Sqrt[2], Sqrt[3]}, b, expected, grouped},
  b = {1 + ell, 2 - ell};
  expected = AsymptoticInverse`Private`newtonSolveDoubling[d, b, 3/2, 5, ell, True, 20000];
  grouped = AsymptoticInverse`Private`groupedLagrangeBlocks[d, b, 3/2, 1, 5, ell, True, 20000];
  AsymptoticInverse`Private`jetMerge[Join[grouped, {{0, -1}},
    AsymptoticInverse`Private`jetScale[expected, -1, ell, True]], ell, True] === {}],
 True, TestID -> "grouped-lagrange-agrees-with-newton-without-commensurability"]

VerificationTest[
 Module[{ell}, AsymptoticInverse`Private`groupedLagrangeBlocks[{1, 2}, {1, 2}, 1, 1, 3, ell, True, 1000]],
 {{0, 1}, {1, -1}}, TestID -> "grouped-lagrange-combines-cancellation-across-depths"]

VerificationTest[
 Module[{ell}, {AsymptoticInverse`Private`groupedLagrangeBlocks[{}, {}, 1, 1, Infinity, ell, True, 10],
   AsymptoticInverse`Private`groupedLagrangeBlocks[{1, 2}, {1, 1}, 1, 1, 1, ell, True, 10]}],
 {{{0, 1}}, {{0, 1}}}, TestID -> "grouped-lagrange-obeys-exclusive-cutoff"]

VerificationTest[
 Module[{x, y, small, large},
  small = AsymptoticInverse[x + x^2 + 2 x^3, {x, 0}, y, SeriesTermGoal -> 3];
  large = AsymptoticInverse[x + x^2 + 2 x^3, {x, 0}, y, SeriesTermGoal -> 6];
  {small["Terms"], Take[large["Terms"], 3] === small["Terms"]}],
 {{{1, 1}, {2, -1}, {4, 5}}, True},
 TestID -> "public-termgoal-counts-complete-nonzero-blocks-and-preserves-prefix"]

VerificationTest[
 Module[{x, y, expressions},
  expressions = Normal[AsymptoticInverse[x^2 + x^3 Log[x] + 2 x^4, {x, 0}, {y, 5/2},
      Method -> #]] & /@ {"Lagrange", "GroupedLagrange", "Newton"};
  And @@ (TrueQ[Simplify[# - First[expressions], y > 0] == 0] & /@ Rest[expressions])],
 True, TestID -> "public-three-inverse-engines-agree-on-resonant-logarithmic-model"]
