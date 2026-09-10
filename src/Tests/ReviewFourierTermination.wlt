(* W3-13 / report 24 F01: a zero homogeneous Fourier coefficient is
   absorbing, but nonzero frequency and logarithmic amplitudes generally
   prevent finite binomial termination. Exact oracles are finite products,
   elementary logarithm coefficients, and independent residual identities. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

reviewFourierCompose[u_, p_, modes_, cutoff_, ell_, ass_, limit_, frequencyLimit_: 1] :=
  Block[{$Assumptions = True}, TimeConstrained[
    AsymptoticAnalysis`Private`catch[
      AsymptoticAnalysis`Private`fourierComposeBlock[
        u, p, modes, cutoff, ell, ass, limit, frequencyLimit]], 20, $Aborted]];

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, 1}}, 5, ell, True, 3]],
  {{0, {{0, 1}}}, {1, {{0, 1}}}, {2, {{0, 1}}}},
  TestID -> "review-fourier-termination-linear-budget-three-avoids-unneeded-square"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, 0, {{0, 1}}, 5, ell, True, 1]],
  {{0, {{0, 1}}}},
  TestID -> "review-fourier-termination-constant-needs-no-first-product"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, Sqrt[2], {}, 5, ell, True, 1]],
  {}, TestID -> "review-fourier-termination-zero-modes-need-no-first-product"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, 2, {{0, 1}}, 7, ell, True, 5]],
  {{0, {{0, 1}}}, {1, {{0, 2}}}, {2, {{0, 3}}}, {3, {{0, 2}}}, {4, {{0, 1}}}},
  TestID -> "review-fourier-termination-quadratic-budget-five-avoids-unneeded-cube"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{3, {{0, 1}}}}, -1, {{0, ell}}, 3, ell, True, 1] /. ell -> \[FormalL]],
  {{0, {{0, \[FormalL]}}}},
  TestID -> "review-fourier-termination-next-support-at-exclusive-cutoff-is-exhausted"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, -1, {{0, 1}}, 5, ell, True, 3]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-fourier-termination-required-nonzero-square-keeps-pair-budget"]

VerificationTest[
  Module[{ell, a}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, a, {{0, 1}}, 5, ell, a == 1, 3]],
  {{0, {{0, 1}}}, {1, {{0, 1}}}, {2, {{0, 1}}}},
  TestID -> "review-fourier-termination-uses-fixed-parameter-assumptions"]

VerificationTest[
  Module[{ell, a}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, a, {{0, 1}}, 5, ell, Element[a, Reals], 3]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-fourier-termination-unproved-zero-does-not-skip-required-square"]

VerificationTest[
  Module[{ell},
    (* Exp[I ell] (1+w)^I: the first two nonconstant coefficients
       are I and I (I-1)/2, although the real power parameter is zero. *)
    reviewFourierCompose[{{1, {{0, 1}}}}, 0, {{1, 1}}, 3, ell, True, 3]],
  {{0, {{1, 1}}}, {1, {{1, I}}}, {2, {{1, (-1 - I)/2}}}},
  TestID -> "review-fourier-termination-nonzero-frequency-retains-complex-binomial-coefficients"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{1, 1}}, 5, ell, True, 3]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-fourier-termination-nonzero-frequency-prevents-integer-power-shortcut"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, ell}}, 5, ell, True, 3]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-fourier-termination-log-amplitude-prevents-integer-power-shortcut"]

VerificationTest[
  Module[{ell},
    (* (1+w)^2 (ell+Log[1+w]) continues after its polynomial power. *)
    reviewFourierCompose[{{1, {{0, 1}}}}, 2, {{0, ell}}, 5, ell, True, 5] /.
      ell -> \[FormalL]],
  {{0, {{0, \[FormalL]}}}, {1, {{0, 1 + 2 \[FormalL]}}},
    {2, {{0, 3/2 + \[FormalL]}}}, {3, {{0, 1/3}}}, {4, {{0, -1/12}}}},
  TestID -> "review-fourier-termination-log-amplitude-keeps-explicit-later-coefficients"]

VerificationTest[
  Module[{ell, t, polynomial, expected},
    And @@ Table[
      polynomial = Expand[(1 + t + 2 t^3)^n];
      expected = Select[Table[{k/2, {{0, Coefficient[polynomial, t, k]}}},
        {k, 0, Min[3 n, 8]}], #[[2, 1, 2]] =!= 0 &];
      reviewFourierCompose[{{1/2, {{0, 1}}}, {3/2, {{0, 2}}}},
        n, {{0, 1}}, 9/2, ell, True, 100] === expected,
      {n, 0, 4}]],
  True, TestID -> "review-fourier-termination-puiseux-collisions-match-finite-polynomial-oracle"]

VerificationTest[
  Module[{ell}, And @@ Table[
    MatchQ[reviewFourierCompose[{{1, {{0, 1}}}}, -1, {{0, 1}},
      cutoff, ell, True, 3], Failure["ResourceLimit", _Association]],
    {cutoff, {1000, Infinity}}]],
  True, TestID -> "review-fourier-termination-nonterminating-reciprocal-keeps-finite-resource-cap"]

VerificationTest[
  Module[{ell}, And @@ Table[
    MatchQ[reviewFourierCompose[{{weight, {{0, 1}}}}, 0, {{0, 1}},
      5, ell, True, 1], Failure["NonSmallJet", _Association]],
    {weight, {0, -1}}]],
  True, TestID -> "review-fourier-termination-validates-nonsmall-input-before-annihilation"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[{}, 7, {{0, 2 + ell^2}}, Infinity, ell, True, 1] /.
    ell -> \[FormalL]],
  {{0, {{0, 2 + \[FormalL]^2}}}},
  TestID -> "review-fourier-termination-empty-argument-keeps-exact-original-coefficient"]

VerificationTest[
  Module[{ell}, reviewFourierCompose[
    {{1, {{-1, 1/2}, {1, 1/2}}}}, 1, {{0, 1}}, 2, ell, True, 20, 2]],
  Failure["FrequencyLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-fourier-termination-retained-mode-union-still-observes-frequency-budget"]

VerificationTest[
  TimeConstrained[Module[{x, y, s, residual},
    s = AsymptoticFourierInverse[x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7];
    If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
    residual = FourierInverseResidual[s, Automatic, "MaxTerms" -> 7];
    AssociationQ[residual] && residual["ZeroBelowCutoff"] === True &&
      residual["ResidualBlocks"] === {} && residual["RelativeCutoff"] === 6 &&
      Expand[Normal[s] - (y - y^2 + 2 y^3 - 5 y^4 + 14 y^5 - 42 y^6)] === 0], 20, $Aborted],
  True,
  TestID -> "review-fourier-termination-public-residual-honors-explicit-budget-seven"]

VerificationTest[
  TimeConstrained[Module[{x, y, s, residual, expected},
    s = AsymptoticFourierInverse[x + x^2 Sin[Log[x]], {x, 0}, {y, 4}];
    If[! MatchQ[s, _GeneralizedSeries], Return[False, Module]];
    residual = FourierInverseResidual[s];
    expected = y - y^2 Sin[Log[y]] +
      y^3 Sin[Log[y]] (2 Sin[Log[y]] + Cos[Log[y]]);
    AssociationQ[residual] && residual["ZeroBelowCutoff"] === True &&
      {s["RemainderPower"], s["RemainderLogDegree"]} === {4, 0} &&
      TrueQ[Simplify[TrigExpand[Normal[s] - expected], y > 0] == 0]], 20, $Aborted],
  True,
  TestID -> "review-fourier-termination-public-oscillatory-coefficients-and-residual-remain-valid"]
