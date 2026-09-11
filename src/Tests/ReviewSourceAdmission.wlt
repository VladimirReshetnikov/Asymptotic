(* Source admission (register C16). The package analytic engine grants a
   power-log remainder only to sources whose heads are built-in functions
   whose regularity the native Series knows; a user-defined or undefined
   function head has no proved regularity, so a few provably real
   derivatives must not become an analytic remainder claim. A native backend
   still delegates such a source under its formal contract. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

VerificationTest[
  Module[{x, g, s},
    s = AsymptoticExpansion[g[x], {x, 0, 3}, "Backend" -> "Package",
      Assumptions -> Element[g[0], Reals] && Element[Derivative[1][g][0], Reals] &&
        Element[Derivative[2][g][0], Reals] && Element[Derivative[3][g][0], Reals] && Element[Derivative[4][g][0], Reals]];
    {FailureQ[s], s[[1]], s[[2]]["Heads"]}],
  {True, "UnsupportedSourceHead", {g}} /. g -> _Symbol, SameTest -> MatchQ,
  TestID -> "source-admission-refuses-an-opaque-head-even-with-real-derivative-assumptions"]

VerificationTest[
  Module[{x, g, s},
    s = AsymptoticExpansion[Exp[x] + Derivative[1][g][x], {x, 0, 3}, "Backend" -> "Package"];
    {FailureQ[s], s[[1]]}],
  {True, "UnsupportedSourceHead"},
  TestID -> "source-admission-refuses-a-derivative-of-an-opaque-head"]

VerificationTest[
  Module[{x, g, s},
    s = AsymptoticExpansion[g[x], {x, 0, 3}];
    {s["Kind"], s["Remainder"], s["Exact"], FreeQ[Normal[s], _GeneralizedSeries]}],
  {"Native", Missing["NativeContract"], Missing["NotEstablished"], True},
  TestID -> "source-admission-delegates-an-opaque-head-natively-under-the-formal-contract"]

VerificationTest[
  Module[{x, s, t},
    s = AsymptoticExpansion[Sin[x] + BesselJ[0, x] + Erf[x] + Sinc[x], {x, 0, 4}, "Backend" -> "Package"];
    (* The native kernel warns about a multivalued inverse while it evaluates the input; the package's own branch selection follows. *)
    t = Quiet[AsymptoticExpansion[InverseFunction[Function[u, u + Exp[u] - 1]][x], {x, 0, 3}, "Backend" -> "Package"], InverseFunction::ifun];
    {s["Kind"], Expand[Normal[s] - (2 + x (1 + 2/Sqrt[Pi]) - 5 x^2/12 - x^3 (1/6 + 2/(3 Sqrt[Pi])))],
      MatchQ[t, _GeneralizedSeries], Expand[Normal[t] - (x/2 - x^2/16)]}],
  {"Forward", 0, True, 0},
  TestID -> "source-admission-keeps-built-in-analytic-heads-and-pure-function-inverses"]

VerificationTest[
  Module[{x, h, s},
    h[v_] := Exp[v] + v^2;
    s = AsymptoticExpansion[h[x], {x, 0, 3}, "Backend" -> "Package"];
    {s["Kind"], Normal[s]}],
  {"Forward", 1 + x + 3 x^2/2} /. x -> _Symbol, SameTest -> MatchQ,
  TestID -> "source-admission-accepts-a-user-function-that-evaluates-to-built-in-heads"]
