(* An exact probe may decline a nonconstant Taylor germ, but a parameter
   assumption can make the same written argument constant. Finite probes
   must continue to enforce the principal-real branch and coefficient proof. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[Module[{u, ell, a},
  AsymptoticAnalysis`Private`specialParameterizedForwardJet[
    PolyGamma[1, 1 + a u^Sqrt[2]], u, ell, a == 0, Infinity, 20000]],
  {{{0, Pi^2/6}}, Infinity, 0},
  TestID -> "composition-exact-probe-preserves-an-argument-constant-under-assumptions"]

VerificationTest[Module[{u, ell, exact, finite},
  exact = AsymptoticAnalysis`Private`specialParameterizedForwardJet[
    PolyGamma[1, 1 + u^Sqrt[2]], u, ell, True, Infinity, 20000];
  finite = AsymptoticAnalysis`Private`specialParameterizedForwardJet[
    PolyGamma[1, 1 + u^Sqrt[2]], u, ell, True, 2, 20000];
  (* Native coefficients may retain equivalent special-function forms. *)
  {exact === $Failed, TrueQ[FullSimplify[
      finite[[1]] == {{0, Pi^2/6}, {Sqrt[2], -2 Zeta[3]}}]],
    finite[[2]] >= 2, finite[[3]]}],
  {True, True, True, 0},
  TestID -> "composition-declined-exact-probe-does-not-poison-a-finite-retry"]

VerificationTest[Module[{u, ell, jet, expected},
  jet = AsymptoticAnalysis`Private`specialParameterizedForwardJet[
    PolyGamma[1, 1 + u^Sqrt[2] Log[u]], u, ell, True, 3, 20000];
  expected = Pi^2/6 - 2 Zeta[3] u^Sqrt[2] Log[u] + Pi^4 u^(2 Sqrt[2]) Log[u]^2/30;
  MatchQ[jet, {_List, _, _}] && TrueQ[FullSimplify[
    Total[(u^#[[1]] (#[[2]] /. ell -> Log[u])) & /@ jet[[1]]] == expected, 0 < u < 1]]],
  True, TestID -> "composition-finite-logarithmic-increment-keeps-real-coefficients-and-domain-proof"]

VerificationTest[Module[{u, ell},
  AsymptoticAnalysis`Private`specialParameterizedForwardJet[#, u, ell, True, 3, 20000] & /@
    {BesselJ[I, u^Sqrt[2]], BesselJ[Sqrt[2], -u^Sqrt[2]],
      PolyGamma[1, I + u^Sqrt[2]], BesselJ[0, 1/u]}],
  ConstantArray[$Failed, 4],
  TestID -> "composition-finite-probes-still-decline-complex-parameters-branches-and-centers"]
