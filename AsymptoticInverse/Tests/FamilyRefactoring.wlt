(* Branch and exact-identity boundaries shared by Gamma and Barnes products.
   Coefficient formulas remain covered by the existing family suites. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

familyRefactoringSource[head_, f_, x_, point_: Infinity, growth_: True, ass_: True, direction_: Automatic] :=
  AsymptoticInverse`Private`catch[head[f, x, ass,
    AsymptoticInverse`Private`localCoordinate[x, point, direction], 20000, growth]];

VerificationTest[Module[{x, r, gamma, barnes},
  gamma = familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource, -Gamma[x]^r, x];
  barnes = familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource, -BarnesG[x]^r, x];
  {MatchQ[gamma, Failure["UnsupportedGammaPower", _Association]],
   MatchQ[barnes, Failure["UnsupportedBarnesPower", _Association]],
   gamma[[2]]["Powers"] === {r}, barnes[[2]]["Powers"] === {r}}],
  {True, True, True, True},
  TestID -> "family-refactoring-preserves-family-power-failures-before-ordinary-sign-handling"]

VerificationTest[Module[{x, r},
  {familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource, Gamma[-x]^r, x],
   familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource, BarnesG[-x]^r, x]}],
  {$Failed, $Failed},
  TestID -> "family-refactoring-argument-positivity-is-checked-before-unproved-powers"]

VerificationTest[Module[{x, r},
  {familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource, Gamma[x + 2]^r, x, 0],
   familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource, BarnesG[x + 2]^r, x, 0],
   MatchQ[familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource,
     Gamma[x + 2]^r, x, 0, False], Failure["UnsupportedGammaPower", _Association]],
   MatchQ[familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource,
     BarnesG[x + 2]^r, x, 0, False], Failure["UnsupportedBarnesPower", _Association]]}],
  {$Failed, $Failed, True, True},
  TestID -> "family-refactoring-growth-gate-precedes-power-validation-and-is-optional-for-logarithms"]

VerificationTest[Module[{x, r, gamma, barnes, domain},
  gamma = familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource,
    Gamma[x]^r, x, Infinity, True, Element[r, Reals]];
  barnes = familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource,
    BarnesG[x + 1]^r, x, Infinity, True, Element[r, Reals]];
  domain = x > 0 && Element[r, Reals];
  {TrueQ[FullSimplify[gamma["Logarithm"] == r LogGamma[x], domain]],
   gamma["GammaFactors"] === {{x, r}}, barnes["BarnesFactors"] === {{x + 1, r}},
   barnes["GammaFactors"] === {}, gamma["Sign"], barnes["Sign"],
   TrueQ[FullSimplify[Equivalent[gamma["Domain"], domain]]],
   TrueQ[FullSimplify[Equivalent[barnes["Domain"], domain]]]}],
  {True, True, True, True, 1, 1, True, True},
  TestID -> "family-refactoring-proved-symbolic-powers-retain-factors-sign-and-domain"]

VerificationTest[Module[{x, a, r, s, f, data, reconstructed},
  f = Gamma[a] ((Gamma[x] BarnesG[2 x])^r)^s;
  data = AsymptoticInverse`Private`positiveSpecialProductData[f, x, _Gamma | _BarnesG];
  reconstructed = data[[1]] Times @@ (#[[1]]^#[[2]] & /@ data[[2]]);
  {data[[1]] === Gamma[a], FreeQ[data[[2]], a],
   MemberQ[data[[3]], r], MemberQ[data[[3]], s],
   TrueQ[FullSimplify[reconstructed == f, x > 0 && a > 0 && Element[{r, s}, Reals]]]}],
  {True, True, True, True, True},
  TestID -> "family-refactoring-nested-product-powers-preserve-constant-factors-and-original-exponents"]

VerificationTest[Module[{x, a},
  {AsymptoticInverse`Private`positiveSpecialProductData[Gamma[x] Gamma[a, x], x, _Gamma],
   AsymptoticInverse`Private`positiveSpecialProductData[BarnesG[x] Gamma[a, x], x, _Gamma | _BarnesG],
   AsymptoticInverse`Private`positiveSpecialProductData[Sin[Gamma[x]], x, _Gamma],
   AsymptoticInverse`Private`positiveSpecialProductData[2^Gamma[x], x, _Gamma]}],
  {$Failed, $Failed, $Failed, $Failed},
  TestID -> "family-refactoring-unsupported-dependent-arity-and-nonproduct-forms-remain-rejected"]

VerificationTest[Module[{x, gamma, barnes},
  gamma = familyRefactoringSource[AsymptoticInverse`Private`gammaProductLogSource,
    -2 Gamma[x + 1]/Gamma[x], x];
  barnes = familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource,
    -2 BarnesG[x + 3/2]/BarnesG[x + 1/2], x];
  {gamma["Sign"], barnes["Sign"],
   TrueQ[FullSimplify[gamma["Logarithm"] == Log[2 x], x > 0]],
   TrueQ[FullSimplify[barnes["Logarithm"] == Log[2] + LogGamma[x + 1/2], x > 0]],
   Length[gamma["GammaFactors"]], Length[barnes["BarnesFactors"]]}],
  {-1, -1, True, True, 2, 2},
  TestID -> "family-refactoring-signed-recurrence-products-retain-exact-logarithmic-identities"]

VerificationTest[Module[{x, source},
  source = familyRefactoringSource[AsymptoticInverse`Private`barnesProductLogSource,
    BarnesG[x + 2], x, 1/2, False, True, "FromBelow"];
  {AssociationQ[source], source["Domain"] /. x -> -1/2,
   source["Domain"] /. x -> -3/2, source["BarnesFactors"] === {{x + 2, 1}}}],
  {True, True, False, True},
  TestID -> "family-refactoring-Barnes-canonical-recurrence-domain-is-retained-at-finite-arguments"]

VerificationTest[Module[{x, gamma, barnes, coord},
  coord = AsymptoticInverse`Private`localCoordinate[x, Infinity, Automatic];
  gamma = AsymptoticInverse`Private`gammaLogarithmNormalize[HoldComplete[Log[Gamma[x]]], x, True, coord, 20000];
  barnes = AsymptoticInverse`Private`gammaLogarithmNormalize[HoldComplete[Log[BarnesG[x]]], x, True, coord, 20000];
  {gamma["Expression"] === HoldComplete[Log[Gamma[x]]],
   barnes["Expression"] === HoldComplete[Log[BarnesG[x]]],
   gamma["Changed"], barnes["Changed"], gamma["Domain"], barnes["Domain"]}],
  {True, True, False, False, True, True},
  TestID -> "family-refactoring-shared-product-analysis-does-not-enter-held-logarithms"]
