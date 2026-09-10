(* Regression tests for truncated sparse arithmetic and bounded enumeration. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{u = Table[{k, 1}, {k, 0, 99}], ell},
   AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`jetMul[u, u, 2, ell, True, 3]]],
  {{0, 1}, {1, 2}}, TestID -> "sparse-product-budgets-only-retained-pairs"]

VerificationTest[
  Module[{ell},
   AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`jetMul[{{0, 1}, {1, 1}}, {{0, 1}, {1, 1}}, 2, ell, True, 2]]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "sparse-product-still-enforces-retained-pair-budget"]

VerificationTest[
  Module[{ell, u, v, expected},
   u = {{-3, 1 + ell}, {-1/2, ell^2}, {2, 2 - ell}, {7, 1}};
   v = {{-2, 1 - ell}, {0, 3}, {1/2, ell}, {6, ell^3}};
   And @@ Table[
     expected = AsymptoticAnalysis`Private`jetTrim[
       Flatten[Table[{a[[1]] + b[[1]], Expand[a[[2]] b[[2]]]}, {a, u}, {b, v}], 1],
       cutoff, ell, True];
     AsymptoticAnalysis`Private`jetMul[u, v, cutoff, ell, True, 100] === expected,
     {cutoff, {-6, -5, -1/2, 0, 2, 8, Infinity}}]],
  True, TestID -> "truncated-product-agrees-with-full-convolution-including-negative-weights"]

VerificationTest[
  Module[{ell}, AsymptoticAnalysis`Private`pIntegerPower[{{{3, 1}}, Infinity, 0}, 1000000, ell, True, 1]],
  {{{3000000, 1}}, Infinity, 0}, TestID -> "large-integer-monomial-power"]

VerificationTest[
  Module[{ell, j, old},
   j = {{{-2, 1 + ell}, {0, 2}}, 3, 2};
   And @@ Table[
     old = Nest[AsymptoticAnalysis`Private`pMul[#, j, ell, True, 10000] &,
       AsymptoticAnalysis`Private`pConst[1, ell, True], n];
     AsymptoticAnalysis`Private`pIntegerPower[j, n, ell, True, 10000] === old,
     {n, 0, 9}]],
  True, TestID -> "binary-integer-power-preserves-laurent-log-precision"]

VerificationTest[
  Module[{ell},
   AsymptoticAnalysis`Private`pIntegerPower[{{}, 2, 3}, 257, ell, True, 1]],
  {{}, 514, 771}, TestID -> "binary-power-of-pure-remainder"]

VerificationTest[
  And @@ Flatten[Table[
    AsymptoticAnalysis`Private`depthRegion[m, n, 1000] ===
      <|"Inside" -> Select[Tuples[Range[0, n], m], Total[#] <= n &],
        "Boundary" -> Select[Tuples[Range[0, n + 1], m], Total[#] == n + 1 &]|>,
    {m, 0, 4}, {n, 0, 3}]],
  True, TestID -> "direct-depth-enumeration-matches-cube-oracle"]

VerificationTest[
  Module[{r = AsymptoticAnalysis`Private`depthRegion[20, 2, 1771]},
   {Length[r["Inside"]], Length[r["Boundary"]],
     And @@ (Total[#] <= 2 & /@ r["Inside"]), And @@ (Total[#] == 3 & /@ r["Boundary"])}],
  {231, 1540, True, True}, TestID -> "depth-enumerates-high-dimensional-simplex-without-cube"]

VerificationTest[
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`depthRegion[100, 100, 20000]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "depth-preflights-combinatorial-budget"]

VerificationTest[
  Module[{x, y}, AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 20},
    "Truncation" -> "Depth", "MaxTerms" -> 5]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "public-depth-truncation-observes-maxterms"]

VerificationTest[
  Module[{d = {1/2, 1, 3/2}, expected, inside, candidates, actual, ok},
   And @@ Flatten[Table[
     ok[w_] := If[inclusive, w <= cutoff, w < cutoff];
     inside = Select[Tuples[Range[0, 7], 3], ok[# . d] &];
     candidates = DeleteDuplicates[Flatten[Table[v + UnitVector[3, j], {v, inside}, {j, 3}], 1]];
     expected = <|"Inside" -> inside, "Boundary" -> Select[candidates, ! ok[# . d] &]|>;
     actual = AsymptoticAnalysis`Private`indexRegion[d, cutoff, inclusive, 1000];
     actual === expected,
     {cutoff, {1/2, 1, 3/2, 3}}, {inclusive, {False, True}}]]],
  True, TestID -> "weighted-index-enumeration-and-boundary-match-cube-oracle"]

VerificationTest[
  Module[{r = AsymptoticAnalysis`Private`indexRegion[{1, 1}, 1, False, 3]},
    {r["Inside"], Sort[r["Boundary"]]}],
  {{{0, 0}}, {{0, 1}, {1, 0}}}, TestID -> "weighted-index-budget-counts-actual-output"]

VerificationTest[
  AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`indexRegion[{1, 1}, 1, False, 2]],
  Failure["ResourceLimit", _Association], SameTest -> MatchQ,
  TestID -> "weighted-index-budget-includes-boundary"]

VerificationTest[
  Module[{ell, u, v, boundaries, expected},
   u = {{-3, 1 + ell}, {-Sqrt[2], ell^2}, {0, ell^7}, {Sqrt[2], ell^3}, {4, ell}};
   v = {{-Sqrt[2], ell^5}, {0, 2}, {Sqrt[2], ell^4}, {4, ell^2}};
   boundaries = DeleteDuplicates[Join[{-10, 1/3, 10},
     Flatten[Table[a[[1]] + b[[1]], {a, u}, {b, v}]]]];
   And @@ Table[
     expected = Max[0, Sequence @@ Flatten[Table[
       If[RootReduce[a[[1]] + b[[1]] - boundary] === 0,
         Exponent[a[[2]], ell] + Exponent[b[[2]], ell], 0], {a, u}, {b, v}]]];
     AsymptoticAnalysis`Private`jetProductBoundaryDegree[u, v, boundary, ell] === expected &&
       AsymptoticAnalysis`Private`jetProductBoundaryDegree[v, u, boundary, ell] === expected,
     {boundary, boundaries}]],
  True, TestID -> "product-boundary-degree-matches-cartesian-oracle-with-irrational-weights"]

VerificationTest[
  Module[{ell},
   {AsymptoticAnalysis`Private`jetProductBoundaryDegree[{}, {{0, ell^3}}, 0, ell],
    AsymptoticAnalysis`Private`jetProductBoundaryDegree[{{0, ell^3}}, {}, 0, ell],
    AsymptoticAnalysis`Private`jetProductBoundaryDegree[{}, {}, 0, ell]}],
  {0, 0, 0}, TestID -> "product-boundary-degree-handles-empty-jets"]

VerificationTest[
  Module[{ell, product},
   product = AsymptoticAnalysis`Private`pMul[
     {{{0, 1}, {1, ell^5}, {2, ell^7}}, 3, 0},
     {{{0, 1}, {1, -ell^5}, {2, ell^7}}, 3, 0}, ell, True, 100];
   {product[[1]] === {{0, 1}, {2, 2 ell^7 - ell^10}}, Rest[product]}],
  {True, {3, 12}}, TestID -> "product-keeps-conservative-log-bound-when-boundary-coefficients-cancel"]

VerificationTest[
  Module[{ell}, AsymptoticAnalysis`Private`pMul[
    {{}, 2, 3}, {{{-1, ell^2}, {1, ell}}, 4, 7}, ell, True, 100]],
  {{}, 1, 5}, TestID -> "product-pure-remainder-times-laurent-logarithmic-leading-block"]

VerificationTest[
  Module[{ell}, AsymptoticAnalysis`Private`jetMerge[
    {{Sqrt[3 + 2 Sqrt[2]], 1 + ell}, {1 + Sqrt[2], -1 - ell},
     {2, (Log[4] - 2 Log[2]) ell^3}, {0, 3},
     {3, (Sqrt[5 + 2 Sqrt[6]] - Sqrt[2] - Sqrt[3]) ell^2}}, ell, True]],
  {{0, 3}}, TestID -> "jet-merge-preserves-algebraic-weight-and-logarithmic-zero-recognition"]

VerificationTest[
  Module[{ell, a, b}, AsymptoticAnalysis`Private`jetMerge[
    {{a, 1 + ell}, {b, -1 - ell}, {a + 1, 2}, {b + 1, 3}},
    ell, b == a && a > 0, True] /. a -> \[FormalA]],
  {{1 + \[FormalA], 5}}, TestID -> "jet-merge-preserves-symbolic-weight-collisions-under-assumptions"]
