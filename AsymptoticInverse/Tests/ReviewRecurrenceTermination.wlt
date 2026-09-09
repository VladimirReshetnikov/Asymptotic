(* Review 4 A03 and review 8 F05: the homogeneous coefficient recurrence
   stays zero after a proved polynomial identity. The oracles below come
   from finite binomial products and elementary logarithm coefficients. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

VerificationTest[
  Module[{ell},
    AsymptoticInverse`Private`jetComposeBlock[
      {{1, 1}}, 0, 1, 30, ell, True, 100]],
  {{0, 1}}, TestID -> "review-recurrence-constant-composition-terminates-exactly"]

VerificationTest[
  Module[{ell},
    AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`jetComposeBlock[
        {{1, 1}, {2, 1}}, Sqrt[2], 0, 5, ell, True, 1]]],
  {}, TestID -> "review-recurrence-zero-polynomial-needs-no-sparse-product"]

VerificationTest[
  Module[{ell},
    (* 3 (1+t+2t^2)^2, with t=u^(1/2). *)
    AsymptoticInverse`Private`jetComposeBlock[
      {{1/2, 1}, {1, 2}}, 2, 3, 5/2, ell, True, 100]],
  {{0, 3}, {1/2, 6}, {1, 15}, {3/2, 12}, {2, 12}},
  TestID -> "review-recurrence-polynomial-composition-preserves-colliding-puiseux-weights"]

VerificationTest[
  Module[{ell, t, polynomial, expected},
    And @@ Table[
      polynomial = Expand[(1 + t + 2 t^3)^n];
      expected = Select[
        Table[{k/2, Coefficient[polynomial, t, k]}, {k, 0, Min[3 n, 8]}],
        Last[#] =!= 0 &];
      AsymptoticInverse`Private`jetComposeBlock[
        {{1/2, 1}, {3/2, 2}}, n, 1, 9/2, ell, True, 100] === expected,
      {n, 0, 6}]],
  True, TestID -> "review-recurrence-integer-powers-match-independent-finite-binomial-products"]

VerificationTest[
  Module[{ell},
    AsymptoticInverse`Private`jetComposeBlock[
      {{1, 1}}, 0, ell, 5, ell, True, 100] /. ell -> \[FormalL]],
  {{0, \[FormalL]}, {1, 1}, {2, -1/2}, {3, 1/3}, {4, -1/4}},
  TestID -> "review-recurrence-logarithmic-polynomial-does-not-stop-at-zero-integer-exponent"]

VerificationTest[
  Module[{ell},
    (* (ell+Log[1+u])^2; Log[1+u]^2 starts u^2-u^3+11u^4/12. *)
    AsymptoticInverse`Private`jetComposeBlock[
      {{1, 1}}, 0, ell^2, 5, ell, True, 100] /. ell -> \[FormalL]],
  {{0, \[FormalL]^2}, {1, 2 \[FormalL]}, {2, 1 - \[FormalL]},
    {3, -1 + 2 \[FormalL]/3}, {4, 11/12 - \[FormalL]/2}},
  TestID -> "review-recurrence-quadratic-logarithmic-polynomial-preserves-all-coefficients"]

VerificationTest[
  Module[{ell},
    (* (1+u)^2 (ell+Log[1+u]) still has a nonzero u^3 coefficient. *)
    AsymptoticInverse`Private`jetComposeBlock[
      {{1, 1}}, 2, ell, 5, ell, True, 100] /. ell -> \[FormalL]],
  {{0, \[FormalL]}, {1, 1 + 2 \[FormalL]}, {2, 3/2 + \[FormalL]},
    {3, 1/3}, {4, -1/12}},
  TestID -> "review-recurrence-logarithmic-block-continues-beyond-polynomial-power-degree"]

VerificationTest[
  Module[{ell},
    (* Even the first product has two retained pairs; it is unnecessary. *)
    AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`jetComposeBlock[
        {{1, 1}, {2, 1}}, 0, 1, 5, ell, True, 1]]],
  {{0, 1}}, TestID -> "review-recurrence-initial-annihilation-precedes-unnecessary-product-budget"]

VerificationTest[
  Module[{ell},
    (* 2(1+u+u^2) is complete after one product. Forming (u+u^2)^2
       would require four retained pairs despite its zero coefficient.
       All three output terms fit the supplied budget. *)
    AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`jetComposeBlock[
        {{1, 1}, {2, 1}}, 1, 2, 5, ell, True, 3]]],
  {{0, 2}, {1, 2}, {2, 2}},
  TestID -> "review-recurrence-later-annihilation-avoids-futile-overbudget-product"]

VerificationTest[
  Module[{ell},
    AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`jetComposeBlock[
        {{1, 1}, {2, 1}}, 2, 1, 5, ell, True, 2]]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "review-recurrence-required-nonzero-product-still-observes-budget"]

VerificationTest[
  Module[{ell, a},
    AsymptoticInverse`Private`catch[
      AsymptoticInverse`Private`jetComposeBlock[
        {{1, 1}, {2, 1}}, a, 1, 5, ell, a == 0, 1]]],
  {{0, 1}}, TestID -> "review-recurrence-annihilation-uses-valid-coefficient-assumptions"]

VerificationTest[
  Module[{ell},
    And @@ Table[
      MatchQ[AsymptoticInverse`Private`catch[
        AsymptoticInverse`Private`jetComposeBlock[
          {{weight, 1}}, 0, 1, 5, ell, True, 10]],
        Failure["NonSmallJet", _Association]],
      {weight, {0, -1}}]],
  True, TestID -> "review-recurrence-nonsmall-input-check-remains-before-coefficient-termination"]

VerificationTest[
  Module[{ell},
    And @@ Table[
      MatchQ[AsymptoticInverse`Private`catch[
        AsymptoticInverse`Private`jetComposeBlock[
          {{weight, 1}}, 0, 1, Infinity, ell, True, 10]],
        Failure["InfiniteSeries", _Association]],
      {weight, {0, 1}}]],
  True, TestID -> "review-recurrence-infinite-cutoff-check-preserves-failure-precedence"]

VerificationTest[
  Module[{ell},
    {AsymptoticInverse`Private`jetComposeBlock[{}, 7, 2 + ell^2, Infinity, ell, True, 1],
      AsymptoticInverse`Private`jetComposeBlock[{}, 7, 0, Infinity, ell, True, 1]} /.
      ell -> \[FormalL]],
  {{{0, 2 + \[FormalL]^2}}, {}},
  TestID -> "review-recurrence-empty-argument-remains-an-exact-noop-before-cutoff-validation"]

VerificationTest[
  Module[{ell},
    (* A different coefficient generator may resume after a zero coefficient.
       Homogeneous-recurrence termination must not change this generic loop. *)
    AsymptoticInverse`Private`jetPowerSeries[{{1, 1}},
      Function[k, Switch[k, 1, 1, 2, 0, 3, 7, _, Null]], 5, ell, True, 10]],
  {{1, 1}, {3, 7}}, TestID -> "review-recurrence-generic-coefficient-generator-may-resume-after-zero"]

VerificationTest[
  Module[{x, y, result, polynomial},
    polynomial = y - y^2 + 2 y^3 - 5 y^4 + 14 y^5;
    result = AsymptoticInverse[x + x^2, {x, 0}, {y, 6}, Method -> "Newton"];
    {Expand[Normal[result] - polynomial] === 0, result["RemainderPower"],
      TrueQ[InverseResidual[result]["ZeroBelowCutoff"]]}],
  {True, 6, True}, TestID -> "review-recurrence-public-newton-inverse-keeps-catalan-coefficients-and-residual"]
