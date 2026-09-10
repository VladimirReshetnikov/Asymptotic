(* Exact grouping, cancellation-aware mode budgets, and independent products. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{ell, a = Sqrt[2] + Sqrt[3], b = Sqrt[5 + 2 Sqrt[6]]},
   AsymptoticAnalysis`Private`fourierMerge[
     {{b, ell + 1}, {-a, ell^2}, {a, -ell}, {0, 2}, {-b, -ell^2}, {0, -1}},
     ell, True, 2]],
  {{0, 1}, {RootReduce[Sqrt[2] + Sqrt[3]], 1}},
  TestID -> "fourier-refactor-algebraic-mode-groups-cancel-before-frequency-budget"]

VerificationTest[
  Module[{ell, parameter},
   AsymptoticAnalysis`Private`fourierMerge[
     {{2, parameter ell}, {-1, 3}, {2, -ell}, {-1, -2}}, ell, parameter == 1, 1]],
  {{-1, 1}}, TestID -> "fourier-refactor-polynomial-cancellation-retains-parameter-assumptions"]

VerificationTest[
  Module[{ell, a = Sqrt[2] + Sqrt[3], b = Sqrt[5 + 2 Sqrt[6]]},
   AsymptoticAnalysis`Private`fourierJetMerge[
     {{b, {{10, ell}, {11, 1}}}, {1, {{0, 2}, {1, 1}}},
      {a, {{10, -ell}, {11, -1}}}, {2, {{0, 3}, {-1, 1}}}}, ell, True, 2, 3]],
  {{1, {{0, 2}, {1, 1}}}, {2, {{-1, 1}, {0, 3}}}},
  TestID -> "fourier-refactor-source-resonance-cancels-before-global-budgets"]

VerificationTest[
  Module[{ell, a = Sqrt[2] + Sqrt[3], b = Sqrt[5 + 2 Sqrt[6]], rows},
   rows = AsymptoticAnalysis`Private`fourierJetMerge[
     {{2, {{b, -2}}}, {1, {{a, 1}}}}, ell, True, 2, 1];
   {Length[rows], AsymptoticAnalysis`Private`fourierJetFrequencies[rows]}],
  {2, {RootReduce[Sqrt[2] + Sqrt[3]]}},
  TestID -> "fourier-refactor-global-union-deduplicates-equal-modes-across-source-blocks"]

VerificationTest[
  Module[{ell, failure},
   (* Each block has two modes, but their union has three. *)
   failure = AsymptoticAnalysis`Private`catch[
     AsymptoticAnalysis`Private`fourierJetMerge[
       {{1, {{0, 1}, {1, 1}}}, {2, {{0, -1}, {-1, 1}}}}, ell, True, 2, 2]];
   {failure[[1]], Lookup[failure[[2]], {"MaxFrequencies", "RequiredFrequencies"}]}],
  {"FrequencyLimit", {2, 3}},
  TestID -> "fourier-refactor-global-mode-limit-counts-union-without-cross-weight-cancellation"]

VerificationTest[
  Module[{ell, u, v, a, b, product, modePolynomial, expected, actual},
   a = {{0, {{-1, 1}, {1, 1}}}, {1, {{0, ell}}}, {3, {{2, 1}}}};
   b = {{0, {{0, 2}}}, {2, {{-1, 3}, {1, -3}}}, {4, {{0, 1}}}};
   (* The oracle multiplies Laurent polynomials in an independent Fourier
      marker and inspects the full Cartesian source-weight rectangle. *)
   modePolynomial = Function[modes, Total[(#[[2]] v^#[[1]]) & /@ modes]];
   expected = Total[Flatten[Table[
     If[aa[[1]] + bb[[1]] < 3,
       u^(aa[[1]] + bb[[1]]) modePolynomial[aa[[2]]] modePolynomial[bb[[2]]], 0],
     {aa, a}, {bb, b}]]];
   product = AsymptoticAnalysis`Private`fourierJetMul[a, b, 3, ell, True, 20, 5];
   actual = Total[(u^#[[1]] modePolynomial[#[[2]]]) & /@ product];
   {Expand[actual - expected] === 0,
    product === {{0, {{-1, 2}, {1, 2}}}, {1, {{0, 2 ell}}}, {2, {{-2, 3}, {2, -3}}}}}],
  {True, True},
  TestID -> "fourier-refactor-truncated-product-matches-independent-cartesian-laurent-oracle"]

VerificationTest[
  Module[{ell, a, b},
   a = {{-Sqrt[2], {{0, 2}}}, {0, {{0, 3}}}, {Sqrt[2], {{0, 5}}}};
   b = {{-1, {{0, 7}}}, {Sqrt[2], {{0, 11}}}, {3, {{0, 13}}}};
   AsymptoticAnalysis`Private`fourierJetMul[a, b, Sqrt[2], ell, True, 4, 1]],
  {{RootReduce[-1 - Sqrt[2]], {{0, 14}}}, {-1, {{0, 21}}},
   {0, {{0, 22}}}, {RootReduce[-1 + Sqrt[2]], {{0, 35}}}},
  TestID -> "fourier-refactor-negative-irrational-source-weights-have-exclusive-boundary"]

VerificationTest[
  Module[{ell, a, b},
   a = Table[{k, {{0, 1}}}, {k, 0, 31}]; b = a;
   AsymptoticAnalysis`Private`fourierJetMul[a, b, 2, ell, True, 3, 1]],
  {{0, {{0, 1}}}, {1, {{0, 2}}}},
  TestID -> "fourier-refactor-discarded-source-pairs-do-not-spend-retained-pair-budget"]

VerificationTest[
  Module[{ell}, AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fourierJetMul[
      {{0, {{0, 1}}}, {1, {{0, 1}}}},
      {{0, {{0, 1}}}, {1, {{0, -1}}}}, 3, ell, True, 3, 1]]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "fourier-refactor-cancelled-output-does-not-reduce-candidate-pair-budget"]

VerificationTest[
  Module[{ell}, AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`fourierJetMul[
      {{0, {{0, 1}, {1, 1}}}, {1, {{0, 1}}}, {2, {{0, 1}}}},
      {{0, {{0, 1}, {2, 1}}}, {1, {{0, 1}}}}, Infinity, ell, True, 4, 2]]],
  Failure["FrequencyLimit", _Association], SameTest -> MatchQ,
  TestID -> "fourier-refactor-earlier-coefficient-failure-precedes-later-pair-budget-failure"]

VerificationTest[
  Module[{ell, rows = {{0, {{0, 1}}}}},
   {AsymptoticAnalysis`Private`fourierJetFrequencies[{}],
    AsymptoticAnalysis`Private`fourierJetMul[{}, rows, 1, ell, True, 1, 1],
    AsymptoticAnalysis`Private`fourierJetMul[rows, {}, Infinity, ell, True, 1, 1]}],
  {{}, {}, {}}, TestID -> "fourier-refactor-empty-frequency-union-and-products"]
