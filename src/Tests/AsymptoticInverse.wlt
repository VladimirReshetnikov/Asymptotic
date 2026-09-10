(* Core MUnit regression suite for AsymptoticAnalysis. From the repository root,
   run src/Tests/RunTests.wl, or use TestReport after loading
   src/Kernel/AsymptoticAnalysis.wl. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];
ClearAll[x, y, z, a, b, alpha];
eqQ[e1_, e2_, ass_: True] := TrueQ[FullSimplify[e1 - e2 == 0, ass]];
simp[e_] := FullSimplify[e, y > 0];

(* ---------- the two examples of question 236367 ---------- *)

VerificationTest[
  Normal[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}]] // Expand,
  Expand[y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3)
    - y^4 (5 Log[y]^3 + 41 Log[y]^2/2 + 27 Log[y] + 23/2)
    + y^5 (14 Log[y]^4 + 241 Log[y]^3/3 + 335 Log[y]^2/2 + 151 Log[y] + 299/6)],
  TestID -> "log-example-five-blocks"]

VerificationTest[
  AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}]["Remainder"],
  PowerLogRemainder[y, 6, 5], TestID -> "log-example-remainder"]

VerificationTest[
  AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 3}]["Remainder"],
  PowerLogRemainder[y, 3, 2], TestID -> "log-example-remainder-is-not-O-y3"]

VerificationTest[
  Expand[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 3}]["FrontierTerm"]],
  Expand[y^3 (2 Log[y]^2 + 5 Log[y] + 3)], TestID -> "log-example-frontier-term"]

VerificationTest[
  simp[Normal[AsymptoticInverse[x + x^Sqrt[2], {x, 0}, {y, 4 Sqrt[2] - 3}]]
    - (y - y^Sqrt[2] + Sqrt[2] y^(2 Sqrt[2] - 1) - (6 - Sqrt[2])/2 y^(3 Sqrt[2] - 2))],
  0, TestID -> "irrational-example-four-terms"]

VerificationTest[
  AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 4]["RemainderPower"] == 4 Sqrt[2] - 3 // FullSimplify,
  True, TestID -> "irrational-example-term-goal"]

VerificationTest[
  simp[AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y, SeriesTermGoal -> 6]["Terms"][[6, 2]] - (-305/12 + 51 Sqrt[2]/4)],
  0, TestID -> "irrational-example-sixth-coefficient"]

(* ---------- forward expansions, including the second question ---------- *)

VerificationTest[
  Module[{r = AsymptoticExpansion[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, SeriesTermGoal -> 7]},
   FullSimplify[Normal[r] - (x^2 + (13 - 9 Sqrt[2])/12 x^(6 - 4 Sqrt[2]) + (-1 + 2 Sqrt[2]/3) x^(5 - 3 Sqrt[2])
      + (2 - Sqrt[2]) x^(3 - 2 Sqrt[2]) + (1 - 1/Sqrt[2]) x^(4 - 2 Sqrt[2]) + Sqrt[2] x^(2 - Sqrt[2]) + Sqrt[2] x^(3 - Sqrt[2])), x > 0]],
  0, TestID -> "forward-irrational-exponents-at-infinity"]

VerificationTest[
  AsymptoticExpansion[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, SeriesTermGoal -> 7]["RemainderPower"] == 5 Sqrt[2] - 7 // FullSimplify,
  True, TestID -> "forward-irrational-remainder"]

VerificationTest[
  AsymptoticExpansion[Sin[x] + x^2 Log[x], {x, 0, 6}]["SeriesData"],
  SeriesData[x, 0, {1, Log[x], -1/6, 0, 1/120}, 1, 7, 1], TestID -> "forward-seriesdata-with-log"]

VerificationTest[
  Normal[AsymptoticExpansion[x^x, {x, 0}, SeriesTermGoal -> 3]],
  1 + x Log[x] + x^2 Log[x]^2/2, TestID -> "forward-x-to-the-x"]

VerificationTest[
  AsymptoticExpansion[x^x, {x, 0}, SeriesTermGoal -> 3]["Remainder"],
  PowerLogRemainder[x, 3, 3], TestID -> "forward-x-to-the-x-remainder"]

VerificationTest[
  Normal[AsymptoticExpansion[(x + Log[x])^(3/2), {x, Infinity, 2}]] - (x^(3/2) + 3 Sqrt[x] Log[x]/2 + 3 Log[x]^2/(8 Sqrt[x]) - Log[x]^3/(16 x^(3/2))) // Simplify,
  0, TestID -> "forward-log-at-infinity"]

VerificationTest[
  Module[{s = AsymptoticExpansion[Exp[-1/x], {x, 0, 2}]},
    {Normal[s], s["Remainder"], s["Exact"], s["Terms"]}],
  {Exp[-1/x], 0, True, {{0, 1}}}, TestID -> "forward-exact-decaying-exponential-prefactor"]

VerificationTest[
  Normal[AsymptoticExpansion[1/(1 - x), {x, 1, 3}, Direction -> "FromBelow"]],
  1/(1 - x), TestID -> "forward-exact-at-finite-point"]

(* ---------- nonunit leading power, resonances, several gaps ---------- *)

VerificationTest[
  Module[{r = AsymptoticInverse[3 x^2 (1 + x (1 + Log[x])), {x, 0}, {y, 2}], z, L},
   z = Sqrt[y/3]; L = Log[y/3]/2;
   simp[Normal[r] - (z - z^2 (1 + L)/2 + z^3 (5 L^2 + 12 L + 7)/8)]],
  0, TestID -> "nonunit-leading-power"]

VerificationTest[
  Normal[AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 7}]],
  y - y^2 + y^3 - 4 y^5 + 14 y^6, TestID -> "resonance-cancels-y4"]

VerificationTest[
  {AsymptoticInverse[x + x^2 + 2 x^3, {x, 0}, {y, 3}]["FrontierTerm"], AsymptoticInverse[x + x^2 + 2 x^3, {x, 0}, {y, 3}]["Remainder"]},
  {5 y^4, PowerLogRemainder[y, 4, 0]}, TestID -> "cancelled-frontier-skipped"]

VerificationTest[
  InverseResidual[AsymptoticInverse[x + x^Sqrt[2] (1 + Log[x]) + 2 x^Sqrt[3], {x, 0}, {y, 3}]]["ZeroBelowCutoff"],
  True, TestID -> "mixed-irrational-gaps-residual"]

VerificationTest[
  Normal[AsymptoticInverse[x^2 + x^3, {x, 0}, {y, 3}]],
  Sqrt[y] - y/2 + 5 y^(3/2)/8 - y^2 + 231 y^(5/2)/128, TestID -> "ramified-inverse"]

VerificationTest[
  AsymptoticInverse[x^2 + x^3, {x, 0}, {y, 3}]["SeriesData"],
  SeriesData[y, 0, {1, -1/2, 5/8, -1, 231/128}, 1, 6, 2], TestID -> "ramified-seriesdata"]

(* ---------- symbolic coefficients and exponents ---------- *)

VerificationTest[
  Normal[AsymptoticInverse[a x + b x^2, {x, 0}, {y, 4}, Assumptions -> a > 0 && Element[b, Reals]]],
  y/a - b y^2/a^3 + 2 b^2 y^3/a^5, TestID -> "symbolic-coefficients"]

VerificationTest[
  Expand[Normal[AsymptoticInverse[x + x^alpha, {x, 0}, {y, 3}, "Truncation" -> "Depth", Assumptions -> alpha > 1]]],
  Expand[y - y^alpha + alpha y^(2 alpha - 1) - alpha (3 alpha - 1)/2 y^(3 alpha - 2)], TestID -> "symbolic-exponent-depth-truncation"]

(* ---------- methods, observables, endpoints ---------- *)

VerificationTest[
  Normal[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}, Method -> "Newton"]] - Normal[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}]] // Expand,
  0, TestID -> "newton-agrees-with-lagrange"]

VerificationTest[
  Normal[AsymptoticInverse[x + x^2, {x, 0}, {y, 5}, "Power" -> 2]],
  y^2 - 2 y^3 + 5 y^4, TestID -> "observable-power"]

VerificationTest[
  Normal[AsymptoticInverse[x + x^2, {x, 0}, {y, 4}, "Power" -> -1]],
  1 + 1/y - y + 2 y^2 - 5 y^3, TestID -> "observable-negative-power"]

VerificationTest[
  Normal[AsymptoticInverse[x + 1/x, {x, Infinity}, {y, 4}]],
  y - 1/y - 1/y^3, TestID -> "inverse-at-infinity"]

VerificationTest[
  Normal[AsymptoticInverse[Log[x] + x, {x, Infinity}, {y, 3}]],
  y - Log[y] + Log[y]/y + (Log[y]^2/2 - Log[y])/y^2, TestID -> "wright-omega-at-infinity"]

VerificationTest[
  AsymptoticInverse[Log[x] + x, {x, Infinity}, {y, 3}]["Remainder"],
  PowerLogRemainder[1/y, 3, 3], TestID -> "wright-omega-remainder"]

VerificationTest[
  Normal[AsymptoticInverse[x - x^2, {x, 1}, {y, 3}]],
  1 - y - y^2, TestID -> "inverse-at-finite-point"]

VerificationTest[
  Normal[AsymptoticInverse[x - x^2, {x, 0}, {y, 4}, Direction -> "FromBelow"]],
  y + y^2 + 2 y^3, TestID -> "inverse-from-below"]

VerificationTest[
  Normal[AsymptoticInverse[1/x + 1, {x, 0}, {y, 3}]],
  1/y + 1/y^2, TestID -> "inverse-with-pole"]

VerificationTest[
  Normal[AsymptoticInverse[x + Sqrt[x], {x, Infinity}, {y, 2}]],
  y - Sqrt[y] + 1/2 - 1/(8 Sqrt[y]) + 1/(128 y^(3/2)), TestID -> "inverse-at-infinity-half-powers"]

(* ---------- automatically expanded forward functions ---------- *)

VerificationTest[
  Normal[AsymptoticInverse[Tan[x], {x, 0}, y, SeriesTermGoal -> 4]],
  y - y^3/3 + y^5/5 - y^7/7, TestID -> "arctan-from-tan"]

VerificationTest[
  Normal[AsymptoticInverse[Sin[x] + x^2 Log[x], {x, 0}, {y, 4}]] // Expand,
  Expand[y - y^2 Log[y] + y^3 (1/6 + Log[y] + 2 Log[y]^2)], TestID -> "automatic-forward-expansion-with-log"]

VerificationTest[
  AsymptoticInverse[Sin[x] + x^2 Log[x], {x, 0}, {y, 4}]["Remainder"],
  PowerLogRemainder[y, 4, 3], TestID -> "automatic-forward-remainder"]

VerificationTest[
  Module[{r = AsymptoticInverse[(1 + x + x^Sqrt[2])^Sqrt[2], {x, Infinity}, {y, 1/2}], c},
   c = InverseNumericalCheck[r, 10^8, WorkingPrecision -> 40];
   c["Error"] < 10^-3 && Abs[c["ForwardResidual"]] < 1],
  True, TestID -> "second-question-inverse-numerical"]

(* ---------- residuals, numerical checks, helpers ---------- *)

VerificationTest[
  InverseResidual[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}]]["ZeroBelowCutoff"],
  True, TestID -> "residual-log-example"]

VerificationTest[
  Module[{c = InverseNumericalCheck[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 6}], 10^-4]},
   c["Error"] < 10^-16 && c["Ratio"] < 100],
  True, TestID -> "numerical-check-log-example"]

VerificationTest[
  Expand[PerturbativeInverse[x^2 (1 + Log[x]), {x, y}, 2]],
  Expand[y - y^2 (1 + Log[y]) + y^3 (2 Log[y]^2 + 5 Log[y] + 3)], TestID -> "perturbative-inverse-identity-core"]

VerificationTest[
  PerturbativeInverse[Sqrt[y], x^3, {x, y}, 2],
  Sqrt[y] - y/2 + 5 y^(3/2)/8, TestID -> "perturbative-inverse-general-core"]

VerificationTest[
  InverseExpansionCoefficient[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 3}], {6}]["Coefficient"],
  22769/20 + 30019 \[FormalL]/6 + 9007 \[FormalL]^2 + 16979 \[FormalL]^3/2 + 52937 \[FormalL]^4/12 + 5981 \[FormalL]^5/5 + 132 \[FormalL]^6,
  TestID -> "single-multi-index-coefficient"]

VerificationTest[
  Table[Coefficient[InverseExpansionCoefficient[PowerLogModel[x + x^2 (1 + Log[x]), {x, 0}], {n}]["Coefficient"], \[FormalL], n], {n, 1, 7}],
  Table[(-1)^n CatalanNumber[n], {n, 1, 7}], TestID -> "catalan-leading-logarithms"]

(* ---------- rejected inputs ---------- *)

VerificationTest[AsymptoticInverse[x + x^1.5, {x, 0}, {y, 3}], _Failure, SameTest -> MatchQ, TestID -> "rejects-inexact-exponent"]
VerificationTest[AsymptoticInverse[x Log[x], {x, 0}, {y, 3}]["Scale"], "Logarithmic", TestID -> "supports-logarithmic-core"]
VerificationTest[AsymptoticInverse[x + x^2, {x, 0}, {y, 1/2}], _Failure, SameTest -> MatchQ, TestID -> "rejects-cutoff-below-leading-term"]
VerificationTest[AsymptoticInverse[x + x^alpha, {x, 0}, {y, 3}], _Failure, SameTest -> MatchQ, TestID -> "rejects-symbolic-exponent-in-exponent-mode"]
VerificationTest[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 4}, "InputRemainder" -> {3, 1}], _Failure, SameTest -> MatchQ, TestID -> "rejects-cutoff-beyond-input-remainder"]
VerificationTest[AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 3}, "InputRemainder" -> {3, 1}]["Remainder"], PowerLogRemainder[y, 3, 2], TestID -> "input-remainder-combined"]
