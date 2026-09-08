(* Reproducible bounded families with an independent quadratic radical oracle.
   The oracle uses Wolfram's ordinary Taylor series, not this package's
   Lagrange, Newton, parsing, or sparse-coefficient implementations. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
 Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

BlockRandom[
 SeedRandom[236367, Method -> "MersenneTwister"];
 Do[With[{a = RandomChoice[{-3, -1, 1, 2, 5}], b = RandomChoice[{-2, -1, 0, 1, 3}],
    source = RandomChoice[{-2, 0, 3, Infinity, -Infinity}],
    side = RandomChoice[{-1, 1}], offset = RandomChoice[{-3, 0, 2}],
    power = RandomChoice[{-2, -1, 1, 2, 3}], cutoff = RandomInteger[{4, 7}], id = index},
   VerificationTest[Module[{x, y, t, u, f, endpoint, orientation, q, oracle, s, expected, actual},
     endpoint = source;
     orientation = Which[source === Infinity, 1, source === -Infinity, -1, True, side];
     u = If[MemberQ[{Infinity, -Infinity}, source], orientation/x, orientation (x - source)];
     f = offset + a u + b u^2;
     s = AsymptoticInverse[f, {x, endpoint}, {y, cutoff},
       Direction -> If[MemberQ[{Infinity, -Infinity}, source], Automatic,
         If[orientation === 1, "FromAbove", "FromBelow"]], "Power" -> power];
     If[FailureQ[s], Return[s, Module]];
     q = 2 t/(1 + Sqrt[1 + 4 b t/a]);
     oracle = If[MemberQ[{Infinity, -Infinity}, source], (orientation/q)^power,
       If[power === 1, source + orientation q, (orientation q)^power]];
     expected = Normal[Series[oracle, {t, 0, cutoff - 1}]];
     actual = Normal[s] /. y -> offset + a t;
     TrueQ[FullSimplify[actual == expected, t > 0]]],
    True, TestID -> StringJoin["generated-quadratic-oracle-", ToString[id], "-", ToString[{a,b,source,side,offset,power,cutoff}, InputForm]]]],
  {index, 1, 40}]];

Do[With[{delta = d, coefficient = b},
 VerificationTest[Module[{x, y, s, expected},
   s = AsymptoticInverse[x + coefficient x^(1 + delta), {x, 0}, {y, 1 + 3 delta}];
   expected = y - coefficient y^(1 + delta) + (1 + delta) coefficient^2 y^(1 + 2 delta);
   If[FailureQ[s], s, TrueQ[FullSimplify[Normal[s] == expected, y > 0]]]],
  True, TestID -> "generated-irrational-three-coefficients-" <> ToString[{delta,coefficient}, InputForm]]],
 {d, {Sqrt[2], Sqrt[3]/2, (1 + Sqrt[5])/2}}, {b, {-2, 3}}];
