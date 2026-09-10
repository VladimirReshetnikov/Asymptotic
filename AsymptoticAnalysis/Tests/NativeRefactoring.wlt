(* Independent error-algebra and complete flat-convolution checks.
   Expected remainders are obtained from multiplication of e+O(R), not
   from a second call to the implementation or native Series. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

nativeRefactoringFlat[jets_, tail_, y_, u_, ell_] := <|
  "Variable" -> y, "LocalVariable" -> u, "LogVariable" -> ell,
  "CoreCoordinate" -> y, "CorePower" -> 1, "CoreCoefficient" -> 1,
  "TargetOffset" -> 0, "PhaseRate" -> 1, "PhasePower" -> 1,
  "Assumptions" -> True, "TargetDomain" -> y > 0,
  "SectorDepth" -> Length[jets] - 1, "SectorJets" -> jets, "SectorTail" -> tail,
  "InnerCutoff" -> Infinity, "DerivativeContract" -> False,
  "DerivativeProvenance" -> <|"Type" -> "IndependentTestEnvelopes"|>, "DerivativeOrder" -> 0|>;

VerificationTest[Module[{u, r, s, product},
  r = PowerLogRemainder[u, 3, 1]; s = PowerLogRemainder[u, 4, 0];
  product = AsymptoticAnalysis`Private`specialNativeMultiply[{-2, r}, {3, s}, u, True];
  {product[[1]], Expand[product[[2]] - (3 r + 2 s + r s)]}],
  {-6, 0}, TestID -> "native-refactoring-product-retains-both-linear-errors-and-their-product"]

VerificationTest[Module[{u, r, s, left, right, pure, zero},
  r = PowerLogRemainder[u, 2, 1]; s = PowerLogRemainder[u, 3, 2];
  left = AsymptoticAnalysis`Private`specialNativeMultiply[{-2, 0}, {3, s}, u, True];
  right = AsymptoticAnalysis`Private`specialNativeMultiply[{-2, r}, {3, 0}, u, True];
  pure = AsymptoticAnalysis`Private`specialNativeMultiply[{0, r}, {0, s}, u, True];
  zero = AsymptoticAnalysis`Private`specialNativeMultiply[{0, 0}, {3, s}, u, True];
  {left === {-6, 2 s}, right === {-6, 3 r}, pure === {0, r s}, zero === {0, 0}}],
  {True, True, True, True}, TestID -> "native-refactoring-exact-factors-and-pure-errors-have-distinct-products"]

VerificationTest[Module[{u, r, product},
  r = PowerLogRemainder[u, 3, 0];
  product = AsymptoticAnalysis`Private`specialNativeMultiply[
    {Exp[1/u], 0}, {Exp[-1/u], Exp[-1/u] r}, u, True];
  product === {1, r}],
  True, TestID -> "native-refactoring-exact-carrier-cancellation-transports-the-absolute-error"]

VerificationTest[Module[{y, u, ell, zero = {{}, Infinity, 0}, a, b, product},
  a = nativeRefactoringFlat[{
    {{{2, 1}}, Infinity, 0}, zero, {{{3, 1}}, 5, 1}, {{}, 7, 2}}, {-2, 1}, y, u, ell];
  b = nativeRefactoringFlat[{
    {{{-1, 1}, {2, 1}}, Infinity, 0}, zero, zero, zero}, {Infinity, 0}, y, u, ell];
  product = AsymptoticAnalysis`Private`flatOpsMultiplyData[a, b, 20000];
  {product["SectorJets"], product["SectorTail"]}],
  {{{{{1, 1}, {4, 1}}, Infinity, 0}, {{}, Infinity, 0},
    {{{2, 1}}, 4, 1}, {{}, 6, 2}}, {-3, 1}},
  TestID -> "native-refactoring-sparse-flat-scalar-transports-inner-and-complete-tail-orders"]

VerificationTest[Module[{y, u, ell, zero = {{}, Infinity, 0}, a, b, product},
  a = nativeRefactoringFlat[{
    {{{0, 1}}, Infinity, 0}, {{}, 2, 3}, zero}, {Infinity, 0}, y, u, ell];
  b = nativeRefactoringFlat[{
    zero, {{{-1, 1}}, Infinity, 0}, zero}, {Infinity, 0}, y, u, ell];
  product = AsymptoticAnalysis`Private`flatOpsMultiplyData[a, b, 20000];
  {product["SectorJets"], product["SectorTail"]}],
  {{{{}, Infinity, 0}, {{{-1, 1}}, Infinity, 0}, {{}, 1, 3}}, {Infinity, 0}},
  TestID -> "native-refactoring-empty-uncertain-inner-jet-is-not-pruned"]

VerificationTest[Module[{y, u, ell, zero = {{}, Infinity, 0}, a, b, product},
  a = nativeRefactoringFlat[{zero, {{}, 2, 1}}, {Infinity, 0}, y, u, ell];
  b = nativeRefactoringFlat[{zero, {{}, 3, 2}}, {Infinity, 0}, y, u, ell];
  product = AsymptoticAnalysis`Private`flatOpsMultiplyData[a, b, 20000];
  {product["SectorJets"], product["SectorTail"]}],
  {{{{}, Infinity, 0}, {{}, Infinity, 0}}, {5, 3}},
  TestID -> "native-refactoring-product-of-pure-inner-errors-reaches-the-omitted-sector"]

VerificationTest[Module[{y, u, ell, a, b, product},
  (* With E as a formal sector marker, the factors are
     1+u^-2 E+E^2 and 1+u^-2 E+(-1+u^3)E^2.
     Their E^3 coefficient is u, because the u^-2 terms cancel.
     E^4 has coefficient -1+u^3, so the complete tail has order u^0. *)
  a = nativeRefactoringFlat[{
    {{{0, 1}}, Infinity, 0}, {{{-2, 1}}, Infinity, 0},
    {{{0, 1}}, Infinity, 0}}, {Infinity, 0}, y, u, ell];
  b = nativeRefactoringFlat[{
    {{{0, 1}}, Infinity, 0}, {{{-2, 1}}, Infinity, 0},
    {{{0, -1}, {3, 1}}, Infinity, 0}}, {Infinity, 0}, y, u, ell];
  product = AsymptoticAnalysis`Private`flatOpsMultiplyData[a, b, 20000];
  {product["SectorJets"], product["SectorTail"]}],
  {{{{{0, 1}}, Infinity, 0}, {{{-2, 2}}, Infinity, 0},
    {{{-4, 1}, {3, 1}}, Infinity, 0}}, {0, 0}},
  TestID -> "native-refactoring-omitted-sector-coefficients-are-added-before-bounding"]

VerificationTest[Module[{y, u, ell, a, b, product},
  a = nativeRefactoringFlat[{
    {{{0, 1}}, Infinity, 0}, {{{1, 1}}, 3, 0}}, {Infinity, 0}, y, u, ell];
  b = nativeRefactoringFlat[{
    {{{0, 1}}, Infinity, 0}, {{{1, -1}}, 4, 0}}, {Infinity, 0}, y, u, ell];
  product = AsymptoticAnalysis`Private`flatOpsMultiplyData[a, b, 20000];
  {product["SectorJets"][[2]], product["SectorTail"]}],
  {{{}, 3, 0}, {2, 0}},
  TestID -> "native-refactoring-cancelled-flat-coefficients-keep-independent-errors"]

VerificationTest[Module[{y, u, ell, zero = {{}, Infinity, 0}, a},
  a = nativeRefactoringFlat[ConstantArray[zero, 5], {Infinity, 0}, y, u, ell];
  MatchQ[AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`flatOpsMultiplyData[a, a, 24]], Failure["ResourceLimit", _Association]]],
  True, TestID -> "native-refactoring-sparse-flat-product-preserves-original-pair-budget"]
