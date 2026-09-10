(* Independent ordinary inverse oracles and bounded frontier fallbacks. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{ell, region, constructed, counted},
   (* For f=x+x^2+x^3, the inverse coefficients at powers 4 and 5
      are 0 and -4. The corresponding weight layers have 2 and 3 indices. *)
   region = <|"Inside" -> {{0, 0}, {0, 1}, {1, 0}, {2, 0}},
     "Boundary" -> {{1, 1}, {0, 2}, {3, 0}, {2, 1}}|>;
   constructed = AsymptoticAnalysis`Private`inverseFrontier[
     region, {1, 2}, {1, 1}, 1, 1, ell, True, 100];
   counted = AsymptoticAnalysis`Private`refinementNewtonFrontier[
     region, {1, 2}, {1, 1}, 1, 1, ell, True, 100];
   {constructed, counted}],
  {{4, -4}, {{4, -4}, 5}}, TestID -> "core-frontier-skips-complete-cancelled-layer-and-counts-all-indices"]

VerificationTest[
  Module[{ell, region},
   region = <|"Inside" -> {{0, 0}, {0, 1}, {1, 0}, {2, 0}},
     "Boundary" -> {{1, 1}, {0, 2}, {3, 0}, {2, 1}}|>;
   AsymptoticAnalysis`Private`catch[
     AsymptoticAnalysis`Private`refinementNewtonFrontier[
       region, {1, 2}, {1, 1}, 1, 1, ell, True, 8]]],
  {{3, 0}, 2}, TestID -> "core-frontier-budget-fallback-preserves-original-cancelled-bound"]

VerificationTest[
  Module[{ell, region},
   (* The zero correction makes every tested coefficient vanish. The search
      must retain the first valid bound after its eight complete layers. *)
   region = <|"Inside" -> {{0}}, "Boundary" -> {{1}}|>;
   AsymptoticAnalysis`Private`refinementNewtonFrontier[
     region, {1}, {0}, 1, 1, ell, True, 100]],
  {{1, 0}, 8}, TestID -> "core-frontier-exhausted-cancellation-search-retains-first-bound"]

VerificationTest[
  Module[{ell},
   {AsymptoticAnalysis`Private`inverseFrontier[
      <|"Inside" -> {{}}, "Boundary" -> {}|>, {}, {}, 1, 1, ell, True, 1],
    AsymptoticAnalysis`Private`refinementNewtonFrontier[
      <|"Inside" -> {{}}, "Boundary" -> {}|>, {}, {}, 1, 1, ell, True, 1]}],
  {None, {None, 0}}, TestID -> "core-frontier-empty-model-has-no-omitted-block-or-work"]

VerificationTest[
  Module[{x, y, s, polynomial, residual},
   s = AsymptoticInverse[x + x^2 + x^3, {x, 0}, y, SeriesTermGoal -> 5];
   polynomial = y - y^2 + y^3 - 4 y^5 + 14 y^6;
   residual = Expand[polynomial + polynomial^2 + polynomial^3 - y];
   {Expand[Normal[s] - polynomial] === 0,
    Table[Coefficient[residual, y, k], {k, 0, 6}],
    s["ReturnedTermCount"], s["Cutoff"], s["RemainderPower"],
    Expand[s["FrontierTerm"] + 30 y^7] === 0,
    s["ComputationState"]["NextWeight"]}],
  {True, ConstantArray[0, 7], 5, 7, 7, True, 6},
  TestID -> "core-term-goal-uses-stored-next-weight-after-inverse-coefficient-cancellation"]

VerificationTest[
  Module[{x, y, s},
   s = AsymptoticInverse[(Sqrt[1 + 4 x] - 1)/2, {x, 0}, y, SeriesTermGoal -> 5];
   {Expand[Normal[s] - y - y^2] === 0, s["Remainder"],
    s["ReturnedTermCount"], s["Cutoff"]}],
  {True, 0, 2, Infinity}, TestID -> "core-term-goal-keeps-exact-termination-before-requested-count"]
