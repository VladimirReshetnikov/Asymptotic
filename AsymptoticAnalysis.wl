(* ::Package:: *)
(* GENERATED FILE. Edit src/Kernel/*.wl instead.
   Rebuild: python validation/build_standalone.py
   Verify:  python validation/build_standalone.py --check
   This file is self-contained; load a remote URL with Get[URLDownload[url]].
   SPDX-License-Identifier: MIT *)

(* BEGIN SOURCE: src/Kernel/AsymptoticAnalysis.wl
   Source SHA256 (UTF-8/LF): 368a839a6114d0a5396df3ae0a82a20e7c9cf30f06bd47d74edcc689d45acb2b *)
(* ::Package:: *)
(* AsymptoticAnalysis -- power-log asymptotic expansions of functions and of their
   inverse functions on a real branch (finite endpoints and infinity, real
   exponents, polynomial logarithmic coefficients).

   Written after analysing nine independent reports on Mathematica Stack Exchange
   question 236367 and question "Asymptotic expansion for a function containing
   irrational exponents".  Theory: docs/article/asymptotic-inverse.tex.

   SPDX-License-Identifier: MIT
*)

(* Mathics can evaluate an existing private definition while reading the
   left-hand side of its replacement. Clear implementation definitions before
   a streamed reload so held dispatch patterns are installed from clean state.
   The official Wolfram kernel keeps its established loading behavior. *)
If[StringQ[$Version] && StringContainsQ[$Version, "Mathics"],
  ClearAll["AsymptoticAnalysis`Private`*"]];

BeginPackage["AsymptoticAnalysis`"];

AsymptoticExpansion::usage =
"AsymptoticExpansion[f, {x, x0, cutoff}] gives the power-log asymptotic expansion of f \
as x -> x0 (x0 may be a real number, Infinity or -Infinity) with every block of \
exponent strictly less than cutoff in the local variable (|x - x0| or 1/|x|) retained, \
as a GeneralizedSeries object.
AsymptoticExpansion[f, {x, x0}, SeriesTermGoal -> n] retains the first n nonzero blocks.
AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n] is equivalent. A unary pure Function \
or unapplied InverseFunction is applied to x before expansion.
For supported Gamma/Barnes G products, ratios, real varying powers and elementary exponential growth, an exact prefactor is extracted; \
the cutoff and term goal apply to the power-log correction bracket.
Increasing Gamma and LogGamma inverses, their admitted affine forms and fixed powers use Scale -> \"GammaInverse\": \
each block is a complete polynomial in 1/Log[CoreInverse] at one power of 1/CoreInverse. \
Increasing BarnesG and LogBarnesG inverses use Scale -> \"BarnesGInverse\", with coefficients polynomial in 1/(Log[CoreInverse]-1). \
Real logarithms of supported positive Gamma products are normalized to LogGamma before ordinary absolute power-log expansion. \
The explicit option \"Backend\" -> \"Series\" or \"Asymptotic\" delegates the original native argument forms and options, \
using the native order convention and preserving the complete native result without asserting a package analytic remainder. \
Automatic retains successful package expansions and uses a compatible native backend for native specifications/options or selected representation failures. \
Native fallback records its own order convention; explicit direction, branch and resource constraints keep the package path. \
\"Backend\" -> \"Package\" selects the existing real expansion engines. See Documentation/UserGuide.md for the domains and contracts.";

AsymptoticExpand::usage =
"AsymptoticExpand[args] is a held alias for AsymptoticExpansion[args], with identical options and order conventions. \
Use \"Backend\" -> \"Series\" or \"Asymptotic\" for explicit native delegation.";

AsymptoticInverse::usage =
"AsymptoticInverse[f, {x, x0}, {y, cutoff}] gives the asymptotic expansion of the real \
branch of the inverse function of f near x = x0 (x0 may be a real number, Infinity or \
-Infinity) as a GeneralizedSeries object in y. Every complete block with exponent strictly \
less than cutoff in the local variable (y - y0, or 1/y when y0 is infinite) is retained.
AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n] retains the first n nonzero blocks.
Recognized leading-logarithmic and exponential cores return Scale -> \"Logarithmic\": \
the cutoff and term count apply to the unit bracket after extracting Prefactor, in \
the positive inverse-logarithmic variable LogarithmicVariable. See Documentation/UserGuide.md \
for this scale's branch and remainder conventions.
Gamma and LogGamma at a source infinity with Gamma argument tending to positive infinity use Scale -> \"GammaInverse\". \
BarnesG, LogBarnesG and the positive-real Log[BarnesG] use Scale -> \"BarnesGInverse\", with an exact Lambert core for the Barnes argument minus one. \
The cutoff is exclusive in 1/CoreInverse and the term goal counts complete polynomial inverse-logarithmic blocks. \
Power specifies a fixed real source observable, with integer powers required on negative source branches.";

GeneralizedSeries::usage =
"GeneralizedSeries[assoc] represents a generalized asymptotic expansion together with its \
remainder and provenance. StandardForm and TraditionalForm display the finite expression \
and remainder without the GeneralizedSeries head. Normal[s] drops the remainder and returns \
the ordinary finite expression. InputForm retains the complete object. s[\"Remainder\"], \
s[\"Terms\"], s[\"SeriesData\"], s[\"Properties\"] and other properties are available; \
s[value] evaluates the finite expression at a numerical value of the variable. \
Native results preserve NativeResult and display its own notation; Normal follows the native Normal operation, \
which can retain an infinite sum. A native formal order or asymptotic output does not establish an analytic remainder or exactness.";

PowerLogRemainder::usage =
"PowerLogRemainder[w, beta, k] is an inert descriptor of the remainder class \
O[w^beta (1 + Abs[Log[w]])^k] as w -> 0+.";

InverseResidual::usage =
"InverseResidual[s] composes the forward model with the truncated inverse in the exact \
power-log jet algebra and returns the normalized residual f(g(y))/(a z^p) - 1 below the \
residual cutoff; InverseResidual[s, h] uses the relative cutoff h in the uniformizer.
For GammaInverse with Power -> 1, it checks the finite Stirling residual normalized by CoreInverse Log[CoreInverse], \
reporting the separate forward-model error and the exact logarithmic equation residual expression. \
BarnesGInverse uses CoreInverse^2 CoreLogExpression and a finite Barnes logarithmic model.";

InverseNumericalCheck::usage =
"InverseNumericalCheck[s, y1] solves f(x) = y1 numerically on the selected branch and \
compares a high-precision reference root with the truncated expansion at y = y1. \
This comparison is numerical evidence, not an interval certificate.";

InverseCertificate::usage = "InverseCertificate[s,y1,\"Interval\"->{lo,hi}] proves a unique root enclosure by exact rational interval arithmetic and explicit elementary-function tail bounds. TargetError requests adaptive absolute accuracy; a rational Center may be fixed explicitly. WorkingPrecision affects seed selection only.";

PerturbativeInverse::usage =
"PerturbativeInverse[phi, h, {x, y}, n] gives the Lagrange-Buermann expansion \
phi(y) + Sum[(-1)^N/N! D^(N-1)[phi'(y) h(phi(y))^N], {N, 1, n}] of the solution x of \
F0(x) + h(x) == y, where phi is the inverse of the core F0. PerturbativeInverse[h, {x, y}, n] \
uses the identity core. It is a formula generator; no asymptotic ordering is asserted.";

InverseExpansionCoefficient::usage =
"InverseExpansionCoefficient[s, {k1, k2, ...}] gives the exact logarithmic-polynomial \
coefficient attached to one multi-index of the inverse expansion s (or of a PowerLogModel).";

PowerLogModel::usage =
"PowerLogModel[f, {x, x0}] parses f near x0 into the normalized model \
y0 + a u^p (1 + Sum[u^delta_i B_i[Log[u]]]) in the local variable u and returns an Association.";

SeriesAdd::usage = "SeriesAdd[s,t] adds compatible expansion objects, transporting both remainders. A regular real expression may replace either operand. Ordinary s+t also normalizes automatically.";
SeriesMultiply::usage = "SeriesMultiply[s,t] multiplies compatible expansion objects, transporting both remainders. A regular real expression may replace either operand. Ordinary s t also normalizes automatically.";
SeriesPower::usage = "SeriesPower[s,r] expands a real power with a proved branch and a transported remainder; SeriesPower[s,r,h] uses cutoff h.";
SeriesLog::usage = "SeriesLog[s] expands the real logarithm of an eventually positive expansion; SeriesLog[s,h] uses cutoff h.";
SeriesExp::usage = "SeriesExp[s] exponentiates an expansion with an absolute remainder tending to zero, retaining any unbounded exponential prefactor exactly; SeriesExp[s,h] uses cutoff h.";
SeriesCompose::usage = "SeriesCompose[outer,inner] composes compatible expansion objects and transports the outer and inner remainders.";
SeriesObservable::usage = "SeriesObservable[s,expr,z] applies a supported real analytic expression expr in z to the expansion s while preserving precision.";
SeriesTruncate::usage = "SeriesTruncate[s,h] discards complete blocks at or above the exclusive cutoff h, retaining a valid remainder.";
SeriesRefine::usage = "SeriesRefine[s,h] extends a compatible retained inverse computation or replays its source or operation recipe at cutoff h. A request association with AdditionalBlocks asks for more complete ordinary blocks; Target with TargetError or RelativeError and Interval returns a numerical certificate. RefinementStatistics records reused and new work; precision never improves without source evidence.";
SeriesDifferentiate::usage = "SeriesDifferentiate[s,n] differentiates n times when matching remainder derivative bounds are known. RemainderDerivativeOrder declares such bounds; a magnitude Big-O bound alone is insufficient.";

Begin["`Private`"];

(* Standalone: every companion is included below. *)

(* Bind evaluator adapters only when loading in Mathics. The official Wolfram
   kernel continues to resolve every existing definition to System` symbols. *)
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsCompatibility.wl\n   Source SHA256 (UTF-8/LF): 66ca2064646b5e0c4a9ea158d25652fa177716f7808d136beeb8c63b7fd0bba0 *)\n(* Mathics3 compatibility is isolated in its own context.  The official\n   Wolfram evaluator never adds this context to its search path, so the\n   streamed kernel sources retain their original System symbols there.\n   These are deliberately bounded helpers for the forms used by this package,\n   not replacements installed on Mathics' global System definitions. *)\n\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\n\nClearAll[AsymptoticAnalysis`Mathics`Module,\n  AsymptoticAnalysis`Mathics`Return,\n  AsymptoticAnalysis`Mathics`Lookup,\n  AsymptoticAnalysis`Mathics`FailureQ,\n  AsymptoticAnalysis`Mathics`MissingQ,\n  AsymptoticAnalysis`Mathics`KeyExistsQ,\n  AsymptoticAnalysis`Mathics`AssociateTo,\n  AsymptoticAnalysis`Mathics`KeyDrop,\n  AsymptoticAnalysis`Mathics`KeyTake,\n  AsymptoticAnalysis`Mathics`DeleteDuplicatesBy,\n  AsymptoticAnalysis`Mathics`FirstPosition,\n  AsymptoticAnalysis`Mathics`RootReduce,\n  AsymptoticAnalysis`Mathics`ToRadicals,\n  AsymptoticAnalysis`Mathics`Refine];",
"\n\n$contextPathBeforeCompatibility = $ContextPath;",
"\n$ContextPath = Prepend[DeleteCases[$ContextPath, \"AsymptoticAnalysis`Mathics`\"],\n  \"AsymptoticAnalysis`Mathics`\"];",
"\n\n(* Mathics 10 implements Return[value] but not Return[value, Module].\n   Moreover, its ordinary Return is intercepted by loop constructs.  A\n   distinct dynamic tag per invocation implements the package's explicit\n   Module destination across loops, recursion, and nested helper calls.\n   Wrapping the whole native Module also covers local initializers. *)\nSetAttributes[Module, HoldAll];",
"\nModule[locals_List, body_] := System`Block[\n  {$moduleReturnTag = System`Unique[\"mathicsModuleReturn$\"]},\n  System`Catch[System`Module[locals, body], $moduleReturnTag]];",
"\nReturn[value_, Module] := System`Throw[value, $moduleReturnTag];",
"\nReturn[value_, System`Module] := System`Throw[value, $moduleReturnTag];",
"\nReturn[value_] := System`Throw[value, $moduleReturnTag];",
"\nReturn[] := System`Throw[Null, $moduleReturnTag];",
"\n\nFailureQ[e_] := MatchQ[e, _System`Failure];",
"\nMissingQ[e_] := MatchQ[e, _System`Missing];",
"\nKeyExistsQ[a_Association, key_] := Or @@ (SameQ[#, key] & /@ Keys[a]);",
"\n\n(* Hold only the default through argument evaluation; it must not run for a\n   present key.  Mathics 10's built-in Lookup rewrites to an unevaluated\n   FirstCase and does not implement the list-of-keys form used throughout\n   the package.  Association application supplies ordinary value semantics. *)\nSetAttributes[Lookup, HoldAllComplete];",
"\nLookup[a_, key_] := lookupRequired[a, key];",
"\nLookup[a_, key_, default_] := lookupValue[a, key, HoldComplete[default]];",
"\nlookupRequired[a_Association, keys_List] := lookupRequired[a, #] & /@ keys;",
"\nlookupRequired[a_Association, key_] :=\n  If[KeyExistsQ[a, key], a[key], Missing[\"KeyAbsent\", key]];",
"\nlookupRequired[associations_List, key_] := lookupRequired[#, key] & /@ associations;",
"\nlookupValue[a_Association, keys_List, default_HoldComplete] :=\n  lookupValue[a, #, default] & /@ keys;",
"\nlookupValue[a_Association, key_, default_HoldComplete] :=\n  If[KeyExistsQ[a, key], a[key], ReleaseHold[default]];",
"\nlookupValue[associations_List, key_, default_HoldComplete] :=\n  lookupValue[#, key, default] & /@ associations;",
"\n\nSetAttributes[AssociateTo, HoldFirst];",
"\nAssociateTo[a_, rules_] := (a = Join[a, Association[rules]]);",
"\nKeyDrop[a_Association, key_] := KeyDrop[a, {key}];",
"\nKeyDrop[a_Association, keys_List] := Association @@ Select[List @@ a,\n  Function[rule, ! Or @@ (SameQ[First[rule], #] & /@ keys)]];",
"\nKeyTake[a_Association, key_] := KeyTake[a, {key}];",
"\nKeyTake[a_Association, keys_List] := Association @@ Flatten[\n  Function[key, Select[List @@ a, SameQ[First[#], key] &]] /@ keys, 1];",
"\nDeleteDuplicatesBy[items_List, function_] := First /@ GatherBy[items, function];",
"\n\n(* Mathics FirstPosition compares exact expressions instead of matching its\n   pattern and does not accept Heads.  Position supports the required forms.\n   Keep a potentially effectful default held until there is no match. *)\nSetAttributes[FirstPosition, HoldRest];",
"\nFirstPosition[expr_, pattern_] :=\n  firstPosition[expr, pattern, HoldComplete[Missing[\"NotFound\"]], {0, Infinity}, True];",
"\nFirstPosition[expr_, pattern_, default_] :=\n  firstPosition[expr, pattern, HoldComplete[default], {0, Infinity}, True];",
"\nFirstPosition[expr_, pattern_, default_, levels_, opts : OptionsPattern[]] :=\n  firstPosition[expr, pattern, HoldComplete[default], levels, OptionValue[Heads]];",
"\nOptions[FirstPosition] = {Heads -> True};",
"\nfirstPosition[expr_, pattern_, default_HoldComplete, levels_, heads_] := System`Module[{positions},\n  positions = Position[expr, pattern, levels, Heads -> heads];\n  If[positions === {}, ReleaseHold[default], First[positions]]];",
"\n\n(* The exact expression is retained when Mathics lacks Wolfram's algebraic\n   number normalizer/radical converter.  Simplify can reduce elementary exact\n   radicals without introducing approximate numbers or asserting a new root. *)\nRootReduce[e_] := System`Simplify[e];",
"\nToRadicals[e_] := e;",
"\nRefine[e_, ass_] := AsymptoticAnalysis`Mathics`Simplify[e, ass];",
"\nRefine[e_] := System`Simplify[e];",
"\n\n$ContextPath = $contextPathBeforeCompatibility;",
"\nEnd[];",
"\n\nIf[StringQ[$Version] && StringContainsQ[$Version, \"Mathics\"],\n  (* Names occurring in public inputs/options must resolve identically in the\n     caller and the package even when Mathics has no implementation for them.\n     Creating inert System names does not claim that those kernels exist. *)\n  Scan[Symbol, {\"System`SeriesTermGoal\", \"System`BarnesG\", \"System`LogBarnesG\",\n    \"System`Asymptotic\", \"System`Failure\", \"System`FunctionDomain\",\n    \"System`Reduce\", \"System`Resolve\", \"System`ForAll\", \"System`Exists\",\n    \"System`Inactive\", \"System`Activate\", \"System`Algebraics\",\n    \"System`InverseFunction\", \"System`WorkingPrecision\", \"System`\\[FormalL]\", \"System`Glaisher\",\n    \"System`BetaRegularized\", \"System`CosIntegral\", \"System`CoshIntegral\",\n    \"System`DawsonF\", \"System`EllipticTheta\", \"System`Erfi\",\n    \"System`GammaRegularized\", \"System`HurwitzZeta\", \"System`Hypergeometric0F1\",\n    \"System`Hypergeometric0F1Regularized\", \"System`Hypergeometric1F1Regularized\",\n    \"System`Hypergeometric2F1Regularized\", \"System`HypergeometricPFQRegularized\",\n    \"System`InverseGammaRegularized\", \"System`JacobiAmplitude\", \"System`JacobiCN\",\n    \"System`JacobiDN\", \"System`JacobiSN\", \"System`JacobiZeta\", \"System`LogIntegral\",\n    \"System`ParabolicCylinderD\", \"System`SinIntegral\", \"System`SinhIntegral\",\n    \"System`SpheroidalPS\", \"System`SpheroidalQS\", \"System`WhittakerM\", \"System`WhittakerW\"}];\n  $ContextPath = Prepend[DeleteCases[$ContextPath, \"AsymptoticAnalysis`Mathics`\"],\n    \"AsymptoticAnalysis`Mathics`\"]];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsTimeBudget.wl\n   Source SHA256 (UTF-8/LF): 779416eb1646b55fb77ac7210de37b177916bcdcdf1f74c666ba02cd40c4a98f *)\n(* Interpreter overhead is materially higher than the compiled Wolfram\n   evaluator. Give package-owned proof attempts four times their original\n   wall-clock budget. The expression, fallback and proof criteria are\n   unchanged; process timeouts and MaxTerms remain independent bounds.\n   User calls to System`TimeConstrained are not changed. *)\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\nClearAll[AsymptoticAnalysis`Mathics`TimeConstrained];",
"\nSetAttributes[TimeConstrained, HoldAll];",
"\nTimeConstrained[expression_, seconds_, fallback_] :=\n  System`TimeConstrained[expression, 4 seconds, fallback];",
"\nTimeConstrained[expression_, seconds_] :=\n  System`TimeConstrained[expression, 4 seconds];",
"\nEnd[];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsCalls.wl\n   Source SHA256 (UTF-8/LF): 92972e1cb515bfa95d27664c1c2fefdbdd7618b982f6b1932c43e8ef413f0c39 *)\n(* Mathics 10 implements Extract[expr,position] but not the wrapper form.\n   The package needs Extract[...,HoldComplete] to inspect named Function\n   parameters without evaluating their ownvalues. Keep every selected part\n   held throughout the traversal; never substitute into a Function body. *)\n\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\nClearAll[AsymptoticAnalysis`Mathics`Extract,\n  AsymptoticAnalysis`Mathics`mathicsExtractHeld,\n  AsymptoticAnalysis`Mathics`mathicsHeldPart,\n  AsymptoticAnalysis`Mathics`mathicsExtractWrapped];",
"\nSetAttributes[Extract, HoldAll];",
"\n\nmathicsHeldPart[HoldComplete[head_[arguments___]], 0] := HoldComplete[head];",
"\nmathicsHeldPart[HoldComplete[head_[arguments___]], index_Integer] :=\n  With[{parts = Cases[HoldComplete[arguments], item_ :> HoldComplete[item], {1}]},\n    If[index =!= 0 && -Length[parts] <= index <= Length[parts],\n      Part[parts, index], $Failed]];",
"\nmathicsHeldPart[_, _Integer] := $Failed;",
"\n\nmathicsExtractHeld[expression_, position_List] :=\n  Fold[mathicsHeldPart, With[{value = expression}, HoldComplete[value]], position];",
"\nmathicsExtractWrapped[expression_, position_List, wrapper_] :=\n  With[{held = mathicsExtractHeld[expression, position]},\n    If[MatchQ[held, HoldComplete[_]],\n      Replace[held, HoldComplete[value_] :> wrapper[value]],\n      System`Extract[expression, position, wrapper]]];",
"\n\nExtract[expression_, position : {___Integer}, wrapper_] :=\n  mathicsExtractWrapped[expression, position, wrapper];",
"\nExtract[expression_, position_List] := System`Extract[expression, position];",
"\n\nEnd[];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsAlgebra.wl\n   Source SHA256 (UTF-8/LF): fa290873bc196f6e94ae798b503c3cc8e69ee2755563e46e2c3d470a2bf77f6f *)\n(* Bounded algebraic operations needed by the package's Fourier and special\n   inverse families. Loaded early, only on Mathics, before consumer parsing.\n   These are exact identities; no branch or nonzero assumption is introduced. *)\n\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\nClearAll[AsymptoticAnalysis`Mathics`CoefficientRules,\n  AsymptoticAnalysis`Mathics`TrigToExp,\n  AsymptoticAnalysis`Mathics`ExpToTrig,\n  AsymptoticAnalysis`Mathics`Take];",
"\n\nCoefficientRules[polynomial_, variable_Symbol] /; PolynomialQ[polynomial, variable] :=\n  Reverse[Select[MapIndexed[({First[#2] - 1} -> #1) &,\n    CoefficientList[Expand[polynomial], variable]], Last[#] =!= 0 &]];",
"\nCoefficientRules[polynomial_, {variable_Symbol}] := CoefficientRules[polynomial, variable];",
"\nCoefficientRules[arguments___] := System`CoefficientRules[arguments];",
"\n\nTrigToExp[expression_] := expression //. {\n  Sin[z_] :> (Exp[I z] - Exp[-I z])/(2 I),\n  Cos[z_] :> (Exp[I z] + Exp[-I z])/2,\n  Sinh[z_] :> (Exp[z] - Exp[-z])/2,\n  Cosh[z_] :> (Exp[z] + Exp[-z])/2};",
"\n\n(* For a Fourier mode z=I omega L, this is Euler's identity directly in\n   omega L. It also remains an identity for arbitrary complex exponents. *)\nExpToTrig[expression_] := expression /. Power[E, z_] :> Cos[z/I] + I Sin[z/I];",
"\n\n(* Mathics Take does not recognize UpTo. A shorter sequence must remain a\n   sequence, including the empty case, when forming complete inverse sectors. *)\nTake[expression_, System`UpTo[n_Integer?NonNegative]] :=\n  System`Take[expression, Min[n, Length[expression]]];",
"\nTake[arguments___] := System`Take[arguments];",
"\n\nEnd[];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsAssumptions.wl\n   Source SHA256 (UTF-8/LF): f86bbb658aa5c2e76488624175cb795d84357c1e91ce6181dc586a7517ac2eea *)\n(* Conservative finite-real and sign consequences of explicit assumptions.\n   This is not quantifier elimination or a replacement for Reduce. Unknown\n   facts stay unknown; no numerical samples or PowerExpand identities are\n   used. Loaded only by the Mathics bootstrap, before the analytic modules. *)\n\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\nClearAll[AsymptoticAnalysis`Mathics`Element,\n  AsymptoticAnalysis`Mathics`mathicsAssumptionAtoms,\n  AsymptoticAnalysis`Mathics`mathicsAssumptionFacts,\n  AsymptoticAnalysis`Mathics`mathicsKnownSigns,\n  AsymptoticAnalysis`Mathics`mathicsSignsWithinQ,\n  AsymptoticAnalysis`Mathics`mathicsRealProof,\n  AsymptoticAnalysis`Mathics`mathicsSignProof,\n  AsymptoticAnalysis`Mathics`mathicsRelationProof,\n  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify];",
"\nSetAttributes[Element, HoldAll];",
"\n(* Preserve the original symbolic realness question. Mathics' native Element\n   can otherwise replace Element[Log[a],Reals] by Element[a,Reals], losing the\n   positive-domain requirement before the assumptions are considered. *)\nElement[e_, Reals] /; NumericQ[e] &&\n    MemberQ[{True, False}, System`Element[e, Reals]] := System`Element[e, Reals];",
"\nElement[e_, domain_] /; domain =!= Reals := System`Element[e, domain];",
"\n\nmathicsAssumptionAtoms[a_] := If[MemberQ[{And, List}, Head[a]],\n  Flatten[mathicsAssumptionAtoms /@ List @@ a, 1], {a}];",
"\n\nmathicsAssumptionFacts[ass_] := Module[{real = {}, constraints = {}, add, relation, atoms},\n  add[value_, signs_List] := Module[{v = value, s = signs},\n    If[Head[v] === Times && Length[v] === 2 && First[v] === -1,\n      v = -v; s = -s];\n    AppendTo[constraints, {v, Sort[s]}]];\n  relation[left_, head_, right_] := Module[{delta, signs},\n    If[! FreeQ[{left, right}, _DirectedInfinity | Indeterminate], Return[Null, Module]];\n    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head],\n      real = Join[real, {left, right}]];\n    delta = left - right;\n    signs = Switch[head, Less, {-1}, LessEqual, {-1, 0}, Greater, {1},\n      GreaterEqual, {0, 1}, Equal, {0}, _, {-1, 0, 1}];\n    If[head =!= Unequal, add[delta, signs]];\n    (* A finite numeric endpoint also supplies useful weaker sign bounds. *)\n    If[NumericQ[right] && TrueQ[System`Element[right, Reals]],\n      Which[MemberQ[{Greater, GreaterEqual}, head] && TrueQ[right > 0], add[left, {1}],\n        head === Greater && right === 0, add[left, {1}],\n        head === GreaterEqual && right === 0, add[left, {0, 1}],\n        MemberQ[{Less, LessEqual}, head] && TrueQ[right < 0], add[left, {-1}],\n        head === Less && right === 0, add[left, {-1}],\n        head === LessEqual && right === 0, add[left, {-1, 0}]]];\n    If[NumericQ[left] && ! NumericQ[right],\n      relation[right, Switch[head, Less, Greater, LessEqual, GreaterEqual,\n        Greater, Less, GreaterEqual, LessEqual, _, head], left]]];\n  atoms = mathicsAssumptionAtoms[ass];\n  Do[Which[\n    MemberQ[{Element, System`Element}, Head[atom]] && Length[atom] === 2 &&\n      MemberQ[{Reals, Rationals, Integers}, atom[[2]]],\n      real = Join[real, If[Head[atom[[1]]] === Alternatives || ListQ[atom[[1]]],\n        List @@ atom[[1]], {atom[[1]]}]],\n    MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, Head[atom]],\n      Scan[relation[#[[1]], Head[atom], #[[2]]] &, Partition[List @@ atom, 2, 1]],\n    Head[atom] === Inequality,\n      Scan[relation[#[[1]], #[[2]], #[[3]]] &, Partition[List @@ atom, 3, 2]]],\n    {atom, atoms}];\n  {DeleteDuplicates[real], constraints}];",
"\n\nmathicsKnownSigns[e_, facts_] := Module[{sets, reciprocal, signs},\n  sets = Last /@ Select[facts[[2]], SameQ[First[#], e] &];\n  If[sets =!= {}, Return[Fold[Intersection, First[sets], Rest[sets]], Module]];\n  (* Canonical evaluation distributes 1/(a b) into a^-1 b^-1. A proved\n     nonzero real product still proves its reciprocal real with the same\n     sign, without requiring either individual factor to be real. *)\n  If[MemberQ[{Times, Power}, Head[e]],\n    reciprocal = 1/e;\n    sets = Last /@ Select[facts[[2]], SameQ[First[#], reciprocal] &];\n    If[sets =!= {},\n      signs = Fold[Intersection, First[sets], Rest[sets]];\n      If[signs =!= {} && ! MemberQ[signs, 0], Return[signs, Module]]]];\n  None];",
"\nmathicsSignsWithinQ[signs_, permitted_List] := ListQ[signs] && signs =!= {} &&\n  Complement[signs, permitted] === {};",
"\n\nmathicsRealProof[e_, facts_, depth_Integer] := Module[{head = Head[e], arguments, signs, base, exponent},\n  If[depth <= 0, Return[None, Module]];\n  If[e === System`Glaisher, Return[True, Module]];\n  If[Or @@ (SameQ[#, e] & /@ facts[[1]]), Return[True, Module]];\n  signs = mathicsKnownSigns[e, facts];\n  If[ListQ[signs] && signs =!= {}, Return[True, Module]];\n  If[NumericQ[e],\n    signs = System`Element[e, Reals];\n    If[signs === True || signs === False, Return[signs, Module]]];\n  If[MemberQ[{Plus, Times, Alternatives}, head],\n    arguments = mathicsRealProof[#, facts, depth - 1] & /@ List @@ e;\n    Return[If[And @@ (TrueQ /@ arguments), True, None], Module]];\n  If[head === Power,\n    base = e[[1]]; exponent = e[[2]];\n    If[! TrueQ[mathicsRealProof[exponent, facts, depth - 1]], Return[None, Module]];\n    signs = mathicsSignProof[base, facts, depth - 1];\n    If[mathicsSignsWithinQ[signs, {1}], Return[True, Module]];\n    If[IntegerQ[exponent] && TrueQ[mathicsRealProof[base, facts, depth - 1]] &&\n      (exponent >= 0 || mathicsSignsWithinQ[signs, {-1, 1}]), Return[True, Module]];\n    If[TrueQ[exponent > 0] && mathicsSignsWithinQ[signs, {0, 1}], Return[True, Module]];\n    Return[None, Module]];\n  If[Length[e] === 1 && MemberQ[{Sin, Cos, Sinh, Cosh, Tanh, ArcTan, Abs}, head],\n    Return[If[TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]], True, None], Module]];\n  If[Length[e] === 1 && MemberQ[{Log, Gamma, LogGamma, System`BarnesG, System`LogBarnesG}, head],\n    signs = mathicsSignProof[e[[1]], facts, depth - 1];\n    If[mathicsSignsWithinQ[signs, {1}], Return[True, Module]];\n    If[head === Log && mathicsSignsWithinQ[signs, {-1, 0}], Return[False, Module]]];\n  None];",
"\n\nmathicsSignProof[e_, facts_, depth_Integer] := Module[\n  {known, head = Head[e], sets, base, exponent, signs, result},\n  If[depth <= 0, Return[None, Module]];\n  If[e === System`Glaisher, Return[{1}, Module]];\n  known = mathicsKnownSigns[e, facts];\n  If[known =!= None, Return[known, Module]];\n  If[NumericQ[e] && TrueQ[System`Element[e, Reals]],\n    Return[Which[TrueQ[e > 0], {1}, TrueQ[e < 0], {-1}, TrueQ[e == 0], {0}, True, None], Module]];\n  If[head === Plus || head === Times,\n    sets = mathicsSignProof[#, facts, depth - 1] & /@ List @@ e;\n    If[! And @@ (ListQ[#] && # =!= {} & /@ sets), Return[None, Module]];\n    If[head === Times,\n      result = {1}; Do[result = DeleteDuplicates[Flatten[Outer[Times, result, s]]], {s, sets}];\n      Return[Sort[result], Module]];\n    If[And @@ (mathicsSignsWithinQ[#, {0, 1}] & /@ sets),\n      Return[If[MemberQ[sets, {1}], {1}, {0, 1}], Module]];\n    If[And @@ (mathicsSignsWithinQ[#, {-1, 0}] & /@ sets),\n      Return[If[MemberQ[sets, {-1}], {-1}, {-1, 0}], Module]];\n    Return[{-1, 0, 1}, Module]];\n  If[head === Power,\n    base = e[[1]]; exponent = e[[2]]; signs = mathicsSignProof[base, facts, depth - 1];\n    If[mathicsSignsWithinQ[signs, {1}] && TrueQ[mathicsRealProof[exponent, facts, depth - 1]],\n      Return[{1}, Module]];\n    If[IntegerQ[exponent] && ListQ[signs] && signs =!= {} &&\n      (exponent >= 0 || ! MemberQ[signs, 0]),\n      Return[Sort[DeleteDuplicates[Sign[#^exponent] & /@ signs]], Module]];\n    If[TrueQ[exponent > 0] && mathicsSignsWithinQ[signs, {0, 1}] &&\n      TrueQ[mathicsRealProof[exponent, facts, depth - 1]], Return[signs, Module]]];\n  If[Length[e] === 1 && head === Abs && TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]],\n    signs = mathicsSignProof[e[[1]], facts, depth - 1];\n    Return[If[mathicsSignsWithinQ[signs, {-1, 1}], {1}, {0, 1}], Module]];\n  If[Length[e] === 1 && head === Cosh && TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]],\n    Return[{1}, Module]];\n  If[Length[e] === 1 && MemberQ[{Gamma, System`BarnesG}, head] &&\n    mathicsSignsWithinQ[mathicsSignProof[e[[1]], facts, depth - 1], {1}], Return[{1}, Module]];\n  If[TrueQ[mathicsRealProof[e, facts, depth - 1]], {-1, 0, 1}, None]];",
"\n\nmathicsRelationProof[left_, head_, right_, facts_] := Module[{signs, accepted},\n  If[! MemberQ[{Equal, Unequal}, head] &&\n    ! (TrueQ[mathicsRealProof[left, facts, 24]] && TrueQ[mathicsRealProof[right, facts, 24]]),\n    Return[None, Module]];\n  signs = mathicsSignProof[left - right, facts, 24];\n  accepted = Switch[head, Less, {-1}, LessEqual, {-1, 0}, Greater, {1},\n    GreaterEqual, {0, 1}, Equal, {0}, Unequal, {-1, 1}, _, {}];\n  Which[mathicsSignsWithinQ[signs, accepted], True,\n    ListQ[signs] && signs =!= {} && Intersection[signs, accepted] === {}, False, True, None]];",
"\n\nmathicsAssumptionSimplify[expression_, assumptions_] := Module[{facts, walk},\n  facts = mathicsAssumptionFacts[assumptions];\n  walk[e_] := Module[{head = Head[e], value, proof, signs, base, results},\n    If[AtomQ[e], Return[e, Module]];\n    If[MemberQ[{Element, System`Element}, head] && Length[e] === 2 && e[[2]] === Reals,\n      proof = mathicsRealProof[e[[1]], facts, 24];\n      Return[If[proof === True || proof === False, proof, e], Module]];\n    If[! MemberQ[{And, Or, Not}, head] && Head[head] === Symbol &&\n      Intersection[Attributes[head], {HoldAll, HoldAllComplete, HoldFirst, HoldRest}] =!= {}, Return[e, Module]];\n    value = Map[walk, e]; head = Head[value];\n    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head],\n      results = mathicsRelationProof[#[[1]], head, #[[2]], facts] & /@\n        If[head === Unequal, Subsets[List @@ value, {2}], Partition[List @@ value, 2, 1]];\n      If[And @@ (TrueQ /@ results), Return[True, Module]];\n      If[MemberQ[results, False], Return[False, Module]]];\n    If[MatchQ[value, Power[_, Rational[1, 2]]],\n      base = value[[1]];\n      If[! MatchQ[base, Power[_, 2]] && LeafCount[base] <= 200 &&\n          NumericQ[Denominator[Together[base]]],\n        proof = System`Factor[base];\n        If[Expand[proof - base] === 0, base = proof]];\n      If[MatchQ[base, Power[_, 2]],\n        base = base[[1]]; signs = mathicsSignProof[base, facts, 24];\n        Which[mathicsSignsWithinQ[signs, {0, 1}], Return[base, Module],\n          mathicsSignsWithinQ[signs, {-1, 0}], Return[-base, Module],\n          TrueQ[mathicsRealProof[base, facts, 24]], Return[Abs[base], Module]]]];\n    If[head === Abs && Length[value] === 1,\n      base = value[[1]]; signs = mathicsSignProof[base, facts, 24];\n      If[mathicsSignsWithinQ[signs, {0, 1}], Return[base, Module]];\n      If[mathicsSignsWithinQ[signs, {-1, 0}], Return[-base, Module]]];\n    value];\n  walk[expression]];",
"\n\nEnd[];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsTaylor.wl\n   Source SHA256 (UTF-8/LF): 3d9164af966119751802e7e9d355a9fc186d012de3ed1fbce2565071be05c1f3 *)\n(* Exact defining Taylor series at zero for functions missing from Mathics.\n   Admit only a constant multiple of one function of a vanishing monomial.\n   This restriction prevents a surrounding pole from amplifying an omitted\n   coefficient. Every result carries an explicit order term.\n   DLMF 16.2.1 and 25.12.10; p<=q+1 ensures a nonzero convergence radius. *)\nBegin[\"AsymptoticAnalysis`Mathics`\"];",
"\nClearAll[AsymptoticAnalysis`Mathics`mathicsTaylorSeries,\n  AsymptoticAnalysis`Mathics`mathicsDefiningTaylor];",
"\n\nmathicsDefiningTaylor[expression_, {t_Symbol, 0, order_Integer}, ass_] := Module[\n  {atoms, atom, factor, head, argument, upper, lower, power, coefficient,\n   term, index, degree},\n  If[order < 0 || order > 400, Return[$Failed, Module]];\n  atoms = DeleteDuplicates[Cases[expression,\n    node : (_System`Hypergeometric0F1 | _System`Hypergeometric1F1 |\n      _System`Hypergeometric2F1 | _System`HypergeometricPFQ | _System`PolyLog) /;\n      ! FreeQ[node, t], {0, Infinity}]];\n  If[Length[atoms] =!= 1, Return[$Failed, Module]];\n  atom = First[atoms]; factor = expression /. atom -> 1;\n  If[Length[atom] =!= Switch[Head[atom],\n      System`Hypergeometric0F1 | System`PolyLog, 2,\n      System`Hypergeometric1F1 | System`HypergeometricPFQ, 3,\n      System`Hypergeometric2F1, 4], Return[$Failed, Module]];\n  If[! FreeQ[factor, t] || ! TrueQ[System`Simplify[expression - factor atom] === 0],\n    Return[$Failed, Module]];\n  head = Head[atom]; argument = Last[atom];\n  If[! PolynomialQ[argument, t], Return[$Failed, Module]];\n  degree = Exponent[argument, t];\n  If[! IntegerQ[degree] || degree < 1, Return[$Failed, Module]];\n  coefficient = Coefficient[argument, t, degree];\n  If[Expand[argument - coefficient t^degree] =!= 0, Return[$Failed, Module]];\n  If[head === System`PolyLog,\n    power = First[atom];\n    If[! FreeQ[power, t] || ! TrueQ[mathicsAssumptionSimplify[Element[power, Reals], ass]],\n      Return[$Failed, Module]],\n    {upper, lower} = Switch[head,\n      System`Hypergeometric0F1, {{}, {atom[[1]]}},\n      System`Hypergeometric1F1, {{atom[[1]]}, {atom[[2]]}},\n      System`Hypergeometric2F1, {{atom[[1]], atom[[2]]}, {atom[[3]]}},\n      System`HypergeometricPFQ, {atom[[1]], atom[[2]]}];\n    If[! ListQ[upper] || ! ListQ[lower] || Length[upper] > Length[lower] + 1 ||\n      ! FreeQ[{upper, lower}, t] ||\n      ! And @@ (TrueQ[mathicsAssumptionSimplify[Element[#, Reals], ass]] & /@ upper) ||\n      ! And @@ (TrueQ[mathicsAssumptionSimplify[# > 0, ass]] & /@ lower),\n      Return[$Failed, Module]]];\n  term[index_Integer] := If[head === System`PolyLog,\n    If[index === 0, 0, coefficient^index/index^power],\n    coefficient^index (Times @@ (Pochhammer[#, index] & /@ upper))/\n      (Factorial[index] Times @@ (Pochhammer[#, index] & /@ lower))];\n  SeriesData[t, 0, Table[If[Mod[index, degree] === 0,\n    factor term[index/degree], 0], {index, 0, order}], 0, order + 1, 1]];",
"\nmathicsDefiningTaylor[_, _, _] := $Failed;",
"\n\nmathicsTaylorSeries[expression_, specification_List, ass_] := Module[{series},\n  series = mathicsDefiningTaylor[expression, specification, ass];\n  If[series === $Failed,\n    Block[{$Assumptions = ass}, System`Series[expression, specification]], series]];",
"\nEnd[];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsSimplification.wl\n   Source SHA256 (UTF-8/LF): fe95296a0ce0c13799a8f3250cf1206a78778163a9f23ce03b912e8ab318795a *)\n(* Mathics 10's two-argument simplifiers call an expression-only operation on\n   the assumptions. Atomic True/False therefore raise a Python exception.\n   A list of assumptions has the same logical meaning and keeps evaluation\n   inside the kernel's supported representation. These definitions are only\n   selected through the Mathics context during package loading. *)\n\nClearAll[AsymptoticAnalysis`Mathics`Simplify,\n  AsymptoticAnalysis`Mathics`FullSimplify,\n  AsymptoticAnalysis`Mathics`Series,\n  AsymptoticAnalysis`Mathics`Limit,\n  AsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ,\n  AsymptoticAnalysis`Mathics`mathicsSimplify];",
"\n\n(* Mathics can cancel an unknown complex offset in a real inequality before\n   checking its operands' domains (a+u>a becomes u>0). Keep unresolved\n   ordered predicates out of native simplification until every operand is\n   proved finite real. The exact assumption callback can still simplify\n   other parts and prove predicates directly. *)\nAsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ[e_, ass_] := Module[\n  {facts, predicates},\n  predicates = Cases[e, _Less | _LessEqual | _Greater | _GreaterEqual | _Inequality,\n    {0, Infinity}];\n  If[predicates === {}, Return[True, Module]];\n  facts = AsymptoticAnalysis`Mathics`mathicsAssumptionFacts[ass];\n  And @@ (Function[predicate,\n    And @@ (TrueQ[AsymptoticAnalysis`Mathics`mathicsRealProof[#, facts, 24]] & /@\n      If[Head[predicate] === Inequality, (List @@ predicate)[[1 ;; -1 ;; 2]],\n        List @@ predicate])] /@ predicates)];",
"\nAsymptoticAnalysis`Mathics`mathicsSimplify[e_, ass_, simplifier_] := Module[{prepared},\n  prepared = AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[e, ass];\n  If[! AsymptoticAnalysis`Mathics`mathicsNativeSimplificationSafeQ[prepared, ass],\n    Return[prepared, Module]];\n  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify[simplifier[prepared, {ass}], ass]];",
"\n\nAsymptoticAnalysis`Mathics`Simplify[e_] :=\n  AsymptoticAnalysis`Mathics`Simplify[e, $Assumptions];",
"\nAsymptoticAnalysis`Mathics`Simplify[e_, ass_] :=\n  AsymptoticAnalysis`Mathics`mathicsSimplify[e, ass, System`Simplify];",
"\nAsymptoticAnalysis`Mathics`FullSimplify[e_] :=\n  AsymptoticAnalysis`Mathics`FullSimplify[e, $Assumptions];",
"\nAsymptoticAnalysis`Mathics`FullSimplify[e_, ass_] :=\n  AsymptoticAnalysis`Mathics`mathicsSimplify[e, ass, System`FullSimplify];",
"\n\n(* Mathics' Series does not accept Assumptions as an option. Retain the\n   assumptions as an evaluation scope for the package's local Taylor calls. *)\nAsymptoticAnalysis`Mathics`Series[e_, spec_List, Assumptions -> ass_] :=\n  AsymptoticAnalysis`Mathics`mathicsTaylorSeries[e, spec, ass];",
"\nAsymptoticAnalysis`Mathics`Series[e_, spec_List] :=\n  AsymptoticAnalysis`Mathics`mathicsTaylorSeries[e, spec, $Assumptions];",
"\n\n(* Direction strings and the Assumptions option are absent from Mathics'\n   Limit interface. The supported integer directions have the same meaning:\n   -1 approaches from above and +1 from below. *)\nOptions[AsymptoticAnalysis`Mathics`Limit] =\n  {Direction -> Automatic, Assumptions :> $Assumptions};",
"\nAsymptoticAnalysis`Mathics`Limit[e_, spec_Rule, opts : OptionsPattern[]] :=\n  Block[{$Assumptions = OptionValue[Assumptions]},\n    System`Limit[e, spec, Direction -> Replace[OptionValue[Direction],\n      {\"FromAbove\" -> -1, \"FromBelow\" -> 1, Automatic -> 1}]]];"
}]];

(* ------------------------------------------------------------------ *)
(* Failure handling                                                     *)
(* ------------------------------------------------------------------ *)

$tag = "AsymptoticAnalysisFailure";
fail[tag_String, msg_String, extra_Association : <||>] :=
  Throw[Failure[tag, Join[<|"MessageTemplate" -> msg|>, extra]], $tag];
SetAttributes[catch, HoldAll];
(* Capture the caller context once per public request. Internal proofs use
   explicit retained hypotheses; later Assuming scopes must not specialize
   an existing result without recording the new restrictions. Nested soft
   probes and constructor replay share the original request boundary. *)
$assumptionScopeActive = False;
$entryAssumptions = True;
catch[body_] := If[TrueQ[$assumptionScopeActive],
  Block[{$Assumptions = True}, Catch[body, $tag]],
  Block[{$assumptionScopeActive = True, $entryAssumptions = $Assumptions,
    $Assumptions = True}, Catch[body, $tag]]];

(* Resolve delayed constructor defaults in the captured caller context.
   Explicit options replace that default. Only option resolution sees the
   ambient context; simplifying stored predicates under themselves loses it. *)
optionAssumptions[public_, rules_List] :=
  Block[{$Assumptions = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions]},
    OptionValue[public, rules, Assumptions]];

(* OptionsPattern admits nested lists and both immediate and delayed rules.
   Once resolved, never forward a delayed assumption into another engine. *)
withoutAssumptions[rules_List] := DeleteCases[Flatten[rules],
  HoldPattern[(Assumptions -> _) | (Assumptions :> _)]];
withAssumptions[rules_List, ass_] := Prepend[withoutAssumptions[rules], Assumptions -> ass];

(* ------------------------------------------------------------------ *)
(* Exact numbers: canonical forms, comparison, zero tests               *)
(* ------------------------------------------------------------------ *)

exactQ[e_] := FreeQ[e, _Real | _Complex];
validateInput[f_, limit_] := (
  If[! exactQ[f], fail["InexactInput", "Exact real input is required; approximate and complex constants are rejected."]];
  If[! FreeQ[f, Indeterminate | _DirectedInfinity], fail["NonfiniteInput", "The forward expression must not contain nonfinite constants."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]]);
exactRealQ[e_] := NumericQ[e] && exactQ[e] && TrueQ[FullSimplify[Element[e, Reals]]];
algebraicRealQ[e_] := exactQ[e] && NumericQ[e] && Module[{t},
   t = Quiet[Element[e, Algebraics] && Element[e, Reals]];
   If[t === True || t === False, t, TrueQ[Quiet[FullSimplify[t]]]]];

canon[Infinity] = Infinity;
canon[-Infinity] = -Infinity;
canon[e_?NumericQ] := Module[{r},
  If[! exactQ[e], fail["InexactInput", "Exact input is required; approximate real numbers are rejected."]];
  If[Head[e] === Integer || Head[e] === Rational, Return[e, Module]];
  If[algebraicRealQ[e], RootReduce[e],
   r = FullSimplify[e];
   If[NumericQ[r] && TrueQ[FullSimplify[Element[r, Reals]]], r,
    fail["UnsupportedNumber", "Cannot canonicalize the exact number.", <|"Number" -> e|>]]]];
canon[e_] := FullSimplify[e];

compare[a_, b_] := Module[{d, t},
  If[a === b, Return[0, Module]];
  If[a === Infinity, Return[1, Module]]; If[b === Infinity, Return[-1, Module]];
  If[a === -Infinity, Return[-1, Module]]; If[b === -Infinity, Return[1, Module]];
  If[(Head[a] === Integer || Head[a] === Rational) && (Head[b] === Integer || Head[b] === Rational),
   Return[Sign[a - b], Module]];
  If[NumericQ[a] && NumericQ[b],
   If[Quiet[TrueQ[a < b], {Less::meprec}], Return[-1, Module]];
   If[Quiet[TrueQ[a > b], {Greater::meprec}], Return[1, Module]]];
  d = canon[a - b];
  If[d === 0, Return[0, Module]];
  If[TrueQ[d < 0], Return[-1, Module]];
  If[TrueQ[d > 0], Return[1, Module]];
  t = FullSimplify[d < 0];
  Which[TrueQ[t], -1, TrueQ[! t], 1,
   True, fail["UndecidableOrder", "The ordering of two exact exponents could not be decided.", <|"Difference" -> d|>]]];
less[a_, b_] := compare[a, b] < 0;
leq[a_, b_] := compare[a, b] <= 0;
equal[a_, b_] := compare[a, b] == 0;
minOf[a_, b_] := If[leq[a, b], a, b];

symbolicEqualQ[a_, b_, ass_] := a === b || TrueQ[Simplify[a - b == 0, ass]];

(* ------------------------------------------------------------------ *)
(* Coefficient normalization                                            *)
(* ------------------------------------------------------------------ *)

logCanon[e_] := e /. Log[r_Rational] :> Total[(#[[2]] Log[#[[1]]]) & /@ FactorInteger[r]] /.
   Log[n_Integer] /; n > 1 :> Total[(#[[2]] Log[#[[1]]]) & /@ FactorInteger[n]];

coefCanon[c_, ass_] := Module[{e},
  If[Head[c] === Integer || Head[c] === Rational, Return[c, Module]];
  e = logCanon[Together[Expand[c]]];
  Which[e === 0, 0,
   Head[e] === Integer || Head[e] === Rational, e,
   algebraicRealQ[e], RootReduce[e],
   NumericQ[e], Simplify[e],
   True, Simplify[e, ass]]];

polyCanon[q_, ell_, ass_] := Module[{cl, e = Expand[logCanon[q]]},
  If[e === 0, Return[0, Module]];
  If[! PolynomialQ[e, ell], e = Expand[Together[e]]];
  If[! PolynomialQ[e, ell], Return[Simplify[e, ass], Module]];
  cl = coefCanon[#, ass] & /@ CoefficientList[e, ell];
  Expand[cl . ell^Range[0, Length[cl] - 1]]];
zeroQ[q_, ass_] := q === 0 || (NumericQ[q] && exactQ[q] && (algebraicRealQ[q] && RootReduce[q] === 0 || TrueQ[Simplify[q == 0]])) ||
  (! NumericQ[q] && TrueQ[Simplify[q == 0, ass]]);
polyCanonicalZeroQ[p_, ell_, ass_] :=
  p === 0 || (PolynomialQ[p, ell] && And @@ (zeroQ[#, ass] & /@ CoefficientList[p, ell]));
polyZeroQ[q_, ell_, ass_] := polyCanonicalZeroQ[polyCanon[q, ell, ass], ell, ass];
polyDegree[q_, ell_] := If[q === 0, 0, Exponent[q, ell]];

realPolynomialCondition[p_, ell_, ass_] := Module[{condition},
  condition = Simplify[And @@ (Element[#, Reals] & /@ CoefficientList[p, ell]), ass];
  If[condition === True || condition === False, condition,
    TimeConstrained[FullSimplify[condition, ass], 1, condition]]];
realPolynomialQ[p_, ell_, ass_] := PolynomialQ[p, ell] &&
  TrueQ[realPolynomialCondition[p, ell, ass]];

(* Validate complete coefficients at representation boundaries. Internal
   summands, Taylor coefficients and native phases may be complex and cancel;
   checking them before collection would reject real final expressions. *)
realCoefficientRows[rows0_List, ell_, ass_, symbolic_: False] := Module[{rows, condition},
  rows = jetMerge[rows0, ell, ass, symbolic];
  Do[
   If[! PolynomialQ[row[[2]], ell],
    fail["UnsupportedCoefficient", "Logarithmic coefficients must be polynomials.", <|"Coefficient" -> row[[2]]|>]];
   condition = realPolynomialCondition[row[[2]], ell, ass];
   If[! TrueQ[condition],
    fail["UnprovedRealCoefficient", "Every collected coefficient must be provably real under the recorded assumptions.",
     <|"Polynomial" -> row[[2]], "Weight" -> row[[1]], "Condition" -> condition,
       "Realness" -> If[condition === False, "Nonreal", "Unproved"], "Assumptions" -> ass|>]],
   {row, rows}];
  rows];

(* ------------------------------------------------------------------ *)
(* Sparse power-log jets: lists of {weight, polynomial in ell}          *)
(* ------------------------------------------------------------------ *)

(* Canonical expression trees need not identify equal exact real weights.
   First bucket identical keys, then sort representatives and join adjacent
   proved-equal buckets. Only the m structural representatives are sorted;
   at most m-1 adjacent equality checks are needed, without all-pairs proofs.
   Callers canonicalize weights and normalize coefficients in their own
   algebra; a failed order proof retains the existing UndecidableOrder exit. *)
orderedWeightGroups[rows_List] := Module[{groups},
  groups = GatherBy[rows, First];
  If[Length[groups] < 2, Return[groups, Module]];
  groups = Sort[groups, less[#1[[1, 1]], #2[[1, 1]]] &];
  Flatten[#, 1] & /@ Split[groups, equal[#1[[1, 1]], #2[[1, 1]]] &]];

jetMerge[terms_List, ell_, ass_, symbolic_: False] := Module[{groups, out},
  If[terms === {}, Return[{}, Module]];
  If[symbolic,
   out = {};
   Do[Module[{pos},
     pos = FirstPosition[out, {w_, _} /; symbolicEqualQ[w, t[[1]], ass], Missing[], {1}, Heads -> False];
     If[MissingQ[pos], AppendTo[out, {t[[1]], t[[2]]}],
      out[[pos[[1]], 2]] = out[[pos[[1]], 2]] + t[[2]]]], {t, terms}];
   out = {#[[1]], polyCanon[#[[2]], ell, ass]} & /@ out;
   Return[Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &], Module]];
  groups = GatherBy[{canon[#[[1]]], #[[2]]} & /@ terms, First];
  out = {#[[1, 1]], polyCanon[Total[#[[All, 2]]], ell, ass]} & /@ groups;
  out = Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &];
  (* Preserve cheap structural cancellation before requiring cross-weight
     order proofs, and only recanonicalize coefficients that actually merge. *)
  groups = orderedWeightGroups[out];
  out = If[Length[#] === 1, First[#],
    {#[[1, 1]], polyCanon[Total[#[[All, 2]]], ell, ass]}] & /@ groups;
  Select[out, ! polyCanonicalZeroQ[#[[2]], ell, ass] &]];

jetTrim[u_List, cut_, ell_, ass_] := jetMerge[Select[u, less[#[[1]], cut] &], ell, ass];
jetAdd[u_List, v_List, cut_, ell_, ass_] := jetTrim[Join[u, v], cut, ell, ass];
jetScale[u_List, c_, ell_, ass_] := If[zeroQ[c, ass], {}, jetMerge[{#[[1]], c #[[2]]} & /@ u, ell, ass]];
jetShift[u_List, s_] := {#[[1]] + s, #[[2]]} & /@ u;
jetMul[u_List, v_List, cut_, ell_, ass_, limit_] := Module[{raw, last = Length[v], counts, products = 0},
  If[u === {} || v === {}, Return[{}, Module]];
  (* Canonical jets are sorted by weight.  The last admissible column can only
     decrease as the row weight increases, so locate the retained products in
     linear time before multiplying any coefficient polynomials. *)
  counts = Table[
    If[cut =!= Infinity,
     While[last > 0 && ! less[a[[1]] + v[[last, 1]], cut], last--]];
    products += last;
    If[products > limit, fail["ResourceLimit", "A truncated sparse product exceeded the MaxTerms budget.",
      <|"MaxTerms" -> limit|>]];
    last, {a, u}];
  raw = Flatten[Table[
    Table[{u[[i, 1]] + v[[j, 1]], u[[i, 2]] v[[j, 2]]}, {j, counts[[i]]}],
    {i, Length[u]}], 1];
  jetMerge[raw, ell, ass]];
jetValuation[u_List] := If[u === {}, Infinity, u[[1, 1]]];
jetLeadingDegree[u_List, ell_] := If[u === {}, 0, polyDegree[u[[1, 2]], ell]];
jetMaxDegree[u_List, ell_] := If[u === {}, 0, Max[polyDegree[#[[2]], ell] & /@ u]];

(* Sum c_k U^k for k >= 1 with coefficients supplied by cf[k]; U has positive valuation.
   Stops when U^k vanishes below cut or when the coefficient generator returns Null. *)
jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},
  If[u === {}, Return[{}, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   c = cf[k];
   If[c === Null, Break[]];
   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]]];
  ans];
jetUnitPower[u_List, r_, cut_, ell_, ass_, limit_] := Module[{c = 1, last = 0},
  jetAdd[{{0, 1}}, jetPowerSeries[u, Function[k, c = c (r - k + 1)/k; If[zeroQ[c, ass], Null, c]], cut, ell, ass, limit], cut, ell, ass]];
jetUnitLog[u_List, cut_, ell_, ass_, limit_] := jetPowerSeries[u, Function[k, (-1)^(k + 1)/k], cut, ell, ass, limit];
jetUnitExp[u_List, cut_, ell_, ass_, limit_] := jetAdd[{{0, 1}}, jetPowerSeries[u, Function[k, 1/k!], cut, ell, ass, limit], cut, ell, ass];

(* (1+U)^a P(ell + log(1+U)) = Sum Q_k(ell) U^k, Q_0 = P, Q_{k+1} = ((a-k) Q_k + Q_k')/(k+1) *)
jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},
  ans = jetMerge[{{0, P}}, ell, ass];
  If[u === {}, Return[ans, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];
   k++;
   (* The recurrence is homogeneous: a zero coefficient stays zero. *)
   If[polyZeroQ[Q, ell, ass], Break[]];
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass]];
  ans];

jetReciprocalUnit[v_List, cut_, ell_, ass_, limit_] := Module[{c0, rest},
  If[v === {} || ! (v[[1, 1]] === 0) || ! FreeQ[v[[1, 2]], ell],
   fail["NotAUnit", "The jet is not a unit with constant leading term."]];
  c0 = v[[1, 2]];
  rest = jetScale[Rest[v], 1/c0, ell, ass];
  jetScale[jetUnitPower[rest, -1, cut, ell, ass, limit], 1/c0, ell, ass]];

(* ------------------------------------------------------------------ *)
(* Precision-tracked jets: {terms, P, D} means terms + O(u^P (1+|L|)^D) *)
(* ------------------------------------------------------------------ *)

pConst[c_, ell_, ass_] := (
  If[! PolynomialQ[c, ell], fail["UnsupportedCoefficient", "Logarithmic coefficients must be polynomials.", <|"Coefficient" -> c|>]];
  If[zeroQ[c, ass], {{}, Infinity, 0}, {{{0, c}}, Infinity, 0}]);
pVar = {{{1, 1}}, Infinity, 0};

combinePrecision[{P1_, D1_}, {P2_, D2_}] := Which[less[P1, P2], {P1, D1}, less[P2, P1], {P2, D2}, True, {P1, Max[D1, D2]}];

pAdd[{T1_, P1_, D1_}, {T2_, P2_, D2_}, ell_, ass_] := Module[{pd = combinePrecision[{P1, D1}, {P2, D2}]},
  If[pd[[1]] =!= Infinity,
   pd[[2]] = Max[pd[[2]], polyDegree[Total[Cases[Join[T1, T2], {w_, q_} /; equal[w, pd[[1]]] :> q]], ell]]];
  {jetTrim[Join[T1, T2], pd[[1]], ell, ass], pd[[1]], pd[[2]]}];
pScale[{T_, P_, D_}, c_, ell_, ass_] := If[zeroQ[c, ass], {{}, Infinity, 0}, {jetScale[T, c, ell, ass], P, D}];
(* Canonical jets have distinct increasing weights. Walk opposite ends to
   find every product on the boundary without inspecting the full rectangle. *)
jetProductBoundaryDegree[u_List, v_List, weight_, ell_] := Module[{i = 1, j = Length[v], degree = 0},
  While[i <= Length[u] && j > 0,
   Switch[compare[u[[i, 1]] + v[[j, 1]], weight],
    -1, i++, 1, j--,
    0, degree = Max[degree, polyDegree[u[[i, 2]], ell] + polyDegree[v[[j, 2]], ell]]; i++; j--]];
  degree];
pMul[{T1_, P1_, D1_}, {T2_, P2_, D2_}, ell_, ass_, limit_] := Module[{v1, v2, e1, e2, pd},
  If[P1 === Infinity && P2 === Infinity, Return[{jetMul[T1, T2, Infinity, ell, ass, limit], Infinity, 0}, Module]];
  v1 = If[T1 === {}, P1, jetValuation[T1]]; e1 = If[T1 === {}, D1, jetLeadingDegree[T1, ell]];
  v2 = If[T2 === {}, P2, jetValuation[T2]]; e2 = If[T2 === {}, D2, jetLeadingDegree[T2, ell]];
  pd = combinePrecision[{If[P1 === Infinity, Infinity, P1 + v2], D1 + e2}, {If[P2 === Infinity, Infinity, P2 + v1], D2 + e1}];
  If[pd[[1]] =!= Infinity, pd[[2]] = Max[pd[[2]], jetProductBoundaryDegree[T1, T2, pd[[1]], ell]]];
  {jetMul[T1, T2, pd[[1]], ell, ass, limit], pd[[1]], pd[[2]]}];
pIntegerPower[j_, n_Integer?NonNegative, ell_, ass_, limit_] := Module[{r = pConst[1, ell, ass], b = j, k = n},
  (* Binary powering also preserves the precision propagation of pMul. *)
  While[k > 0,
   If[OddQ[k], r = pMul[r, b, ell, ass, limit]];
   k = Quotient[k, 2];
   If[k > 0, b = pMul[b, b, ell, ass, limit]]];
  r];

(* tail bound of a unit series truncated at relative weight cut, with argument U known to relative precision {PU, DU} *)
unitSeriesPrecision[U_List, PU_, DU_, cut_, ell_] := Module[{c = minOf[PU, cut], Nn, d},
  If[U === {}, Return[{PU, DU}, Module]];
  If[c === Infinity, Return[{Infinity, 0}, Module]];
  Nn = Ceiling[canon[c/jetValuation[U]]];
  d = jetMaxDegree[U, ell];
  (* Discarded Taylor products still contribute at an input-limited frontier. *)
  If[less[cut, PU], {c, Nn d}, {c, Max[Nn d, DU]}]];

(* generic unit-series application: f(1+U) or f(c0+U) via coefficient generator *)
pUnitSeries[U_List, PU_, DU_, cf_, cut_, ell_, ass_, limit_] := Module[{pd, T},
  pd = unitSeriesPrecision[U, PU, DU, cut, ell];
  T = jetPowerSeries[U, cf, pd[[1]], ell, ass, limit];
  {T, pd[[1]], pd[[2]]}];

(* ------------------------------------------------------------------ *)
(* Forward expansion engine                                             *)
(* ------------------------------------------------------------------ *)

(* split a jet into weight<0 part, weight-0 polynomial, weight>0 part *)
splitJet[T_List] := {Select[T, less[#[[1]], 0] &], Total[Select[T, #[[1]] === 0 &][[All, 2]]], Select[T, less[0, #[[1]]] &]};

provablyPositive[c_, ass_] := TrueQ[Simplify[c > 0, ass]];
provablyNegative[c_, ass_] := TrueQ[Simplify[c < 0, ass]];

fwd[e_, u_, ell_, ass_, Kw_, limit_] := Module[{h = Head[e], parameterized},
  If[Length[e] > 1 && ! MemberQ[{Plus, Times, Power}, h] && ! FreeQ[e, u],
    parameterized = specialParameterizedForwardJet[e, u, ell, ass, Kw, limit];
    If[MatchQ[parameterized, {_List, _, _}], Return[parameterized, Module]]];
  Which[
   inverseFunctionApplicationQ[e], inverseFunctionForwardJet[e, u, ell, ass, Kw, limit],
   FreeQ[e, u], pConst[e, ell, ass],
   e === u, pVar,
   h === LogBarnesG,
     If[! inverseFunctionEventually[e[[1]] > 0, u, ass],
       fail["UnsupportedBarnesArgument", "The logarithmic Barnes expansion requires an eventually positive argument."]];
     barnesLogJet[e[[1]], u, ell, ass, Kw, limit],
   h === barnesLog, barnesLogJet[e[[1]], u, ell, ass, Kw, limit],
   h === Plus, Fold[pAdd[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
   h === Times, Fold[pMul[#1, fwd[#2, u, ell, ass, Kw, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
   h === Power && e[[1]] === E, fwdExp[fwd[e[[2]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Power && FreeQ[e[[2]], u], fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], e[[2]], u, ell, ass, Kw, limit],
   h === Power, fwdExp[pMul[fwd[e[[2]], u, ell, ass, Kw, limit], fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit], ell, ass, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 1, fwdLog[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Log && Length[e] == 2, fwd[Log[e[[2]]]/Log[e[[1]]], u, ell, ass, Kw, limit],
   h === Exp, fwdExp[fwd[e[[1]], u, ell, ass, Kw, limit], u, ell, ass, Kw, limit],
   h === Sqrt, fwdPower[fwd[e[[1]], u, ell, ass, Kw, limit], 1/2, u, ell, ass, Kw, limit],
   h === Abs, fwdAbs[fwd[e[[1]], u, ell, ass, Kw, limit], ell, ass],
   Length[e] == 1, fwdAnalytic[h, fwd[e[[1]], u, ell, ass, Kw, limit], e, u, ell, ass, Kw, limit],
   True, fwdSeries[e, u, ell, ass, Kw, limit]]];

fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];
  c = (-1)^degree Coefficient[q, ell, degree];
  Which[provablyPositive[c, ass], j, provablyNegative[c, ass], pScale[j, -1, ell, ass],
    True, fail["UnprovedSign", "The eventual sign of the absolute-value argument could not be proved."]]];

fwdPower[{T_, P_, D_}, r_, u_, ell_, ass_, Kw_, limit_] := Module[{alpha, Q, c, U, PU, DU, cutRel, res, rr},
  If[! (NumericQ[r] && exactQ[r]), fail["SymbolicExponent", "Exponents must be exact numbers.", <|"Exponent" -> r|>]];
  If[! TrueQ[Simplify[Element[r, Reals]]], fail["ComplexExponent", "Only real exponents are supported.", <|"Exponent" -> r|>]];
  rr = If[algebraicRealQ[r], RootReduce[r], r];
  If[IntegerQ[rr] && rr >= 0, Return[pIntegerPower[{T, P, D}, rr, ell, ass, limit], Module]];
  If[T === {},
   If[P =!= Infinity && ! IntegerQ[rr],
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],
    fail["UnknownLeadingTerm", "Cannot raise a quantity known only as a remainder to a nonpositive power; increase the working order."]]];
  {alpha, Q} = T[[1]];
  If[! FreeQ[Q, ell],
   fail["LogarithmicLeadingPower", "The leading block contains a logarithm and the exponent is not a nonnegative integer; the result is outside the power-log class.", <|"LeadingBlock" -> Q, "Exponent" -> r|>]];
  c = Q;
  If[! provablyPositive[c, ass],
   If[IntegerQ[rr] && provablyNegative[c, ass], Null,
    fail["NonpositiveBase", "The leading coefficient of the base must be provably positive for a real non-integer power.", <|"Coefficient" -> c|>]]];
  U = jetScale[jetShift[Rest[T], -alpha], 1/c, ell, ass];
  PU = If[P === Infinity, Infinity, P - alpha]; DU = D;
  cutRel = If[Kw === Infinity, Infinity, Kw - alpha rr];
  If[! less[0, cutRel] && ! (Kw === Infinity), Return[{{}, alpha rr + cutRel, 0}, Module]];
  res = If[U === {}, {{}, PU, DU},
    pUnitSeries[U, PU, DU, Module[{cc = 1}, Function[k, cc = cc (rr - k + 1)/k; If[zeroQ[cc, ass], Null, cc]]], cutRel, ell, ass, limit]];
  res = {jetAdd[{{0, 1}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]};
  {jetScale[jetShift[res[[1]], alpha rr], c^rr, ell, ass], If[res[[2]] === Infinity, Infinity, res[[2]] + alpha rr], res[[3]]}];

fwdLog[{T_, P_, D_}, u_, ell_, ass_, Kw_, limit_] := Module[{alpha, Q, c, U, PU, DU, res},
  If[T === {}, fail["UnknownLeadingTerm", "Cannot take the logarithm of a quantity known only as a remainder; increase the working order."]];
  {alpha, Q} = T[[1]];
  If[! FreeQ[Q, ell], fail["LogarithmicLeadingPower", "Log of a block with a logarithmic factor is outside the power-log class.", <|"LeadingBlock" -> Q|>]];
  c = Q;
  If[! provablyPositive[c, ass], fail["NonpositiveBase", "The leading coefficient must be provably positive to take a real logarithm.", <|"Coefficient" -> c|>]];
  U = jetScale[jetShift[Rest[T], -alpha], 1/c, ell, ass];
  PU = If[P === Infinity, Infinity, P - alpha]; DU = D;
  res = If[U === {}, {{}, PU, DU}, pUnitSeries[U, PU, DU, Function[k, (-1)^(k + 1)/k], Kw, ell, ass, limit]];
  {jetAdd[{{0, logCanon[Log[c]] + alpha ell}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]}];

fwdExp[{T_, P_, D_}, u_, ell_, ass_, Kw_, limit_] := Module[{neg, q0, U, k, c, res, cutRel},
  If[! less[0, P], fail["UnknownLeadingTerm", "The exponential argument needs positive remainder precision."]];
  {neg, q0, U} = splitJet[T];
  If[neg =!= {}, fail["ExponentialScale", "Exp of a quantity that is unbounded at the expansion point produces exponential growth or decay, which is outside the power-log class.", <|"Argument" -> neg|>]];
  If[! (PolynomialQ[q0, ell] && polyDegree[q0, ell] <= 1), fail["ExponentialScale", "Exp of a polynomial of degree > 1 in the logarithm is outside the power-log class."]];
  k = Coefficient[q0, ell, 1]; c = Coefficient[q0, ell, 0];
  If[! exactRealQ[k], fail["SymbolicExponent", "Exp[k Log[u]] needs an exact real numeric k."]];
  If[T === {}, Return[{{{0, 1}}, P, D}, Module]];
  cutRel = If[Kw === Infinity, Infinity, Kw - k];
  res = If[U === {}, {{}, P, D}, pUnitSeries[U, P, D, Function[j, 1/j!], cutRel, ell, ass, limit]];
  res = {jetAdd[{{0, 1}}, res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]};
  {jetScale[jetShift[res[[1]], k], Exp[c], ell, ass], If[res[[2]] === Infinity, Infinity, res[[2]] + k], res[[3]]}];

fwdAnalytic[h_, {T_, P_, D_}, e_, u_, ell_, ass_, Kw_, limit_] := Module[{neg, q0, U, c0, s, N0, t, coeffs, res, nmin, k, cf, sign, lc, V, rho, pd, power},
  If[! less[0, P], fail["UnknownLeadingTerm", "A function argument needs positive remainder precision."]];
  {neg, q0, U} = splitJet[T];
  If[neg =!= {} || ! FreeQ[q0, ell], Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  c0 = q0;
  If[Kw === Infinity && U =!= {}, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  N0 = If[U === {}, 1, Max[1, Ceiling[canon[minOf[If[P === Infinity, Kw, P], Kw]/jetValuation[U]]]]];
  If[N0 > 400, fail["ResourceLimit", "Too many Taylor terms are required."]];
  sign = 1;
  If[U =!= {},
   lc = U[[1, 2]];
   lc = (-1)^polyDegree[lc, ell] Coefficient[lc, ell, polyDegree[lc, ell]];
   If[provablyNegative[lc, ass], sign = -1]];
  s = Quiet[Series[h[c0 + sign t], {t, 0, N0}, Assumptions -> ass && t > 0]];
  If[! MatchQ[s, _SeriesData] || ! FreeQ[s[[3]], t] || ! less[N0, s[[5]]/s[[6]]],
   Return[fwdSeries[e, u, ell, ass, Kw, limit], Module]];
  (* Compose Laurent and Puiseux expansions in a positive local increment.
     In particular this handles poles and algebraic branch points even when
     Series cannot order the irrational powers in the original expression. *)
  If[s[[6]] =!= 1 || s[[4]] < 0,
   If[U === {}, fail["UnknownLeadingTerm", "A singular function needs a known leading increment."]];
   V = {jetScale[U, sign, ell, ass], P, D};
   res = pConst[0, ell, ass];
   Do[If[! zeroQ[s[[3, k]], ass],
     power = (s[[4]] + k - 1)/s[[6]];
     res = pAdd[res, pScale[fwdPower[V, power, u, ell, ass, Kw, limit], s[[3, k]], ell, ass], ell, ass]],
     {k, Length[s[[3]]]}];
   rho = nativeSeriesTailPrecision[s][[1]];
   pd = {canon[rho jetValuation[U]], Max[0, Ceiling[rho jetLeadingDegree[U, ell]]]};
   Return[pAdd[res, {{}, pd[[1]], pd[[2]]}, ell, ass], Module]];
  If[sign === -1, U = jetScale[U, -1, ell, ass]];
  coeffs = s[[3]]; nmin = s[[4]];
  c0 = If[nmin <= 0 && Length[coeffs] >= 1 - nmin, coeffs[[1 - nmin]], 0];
  cf = Function[j, If[j >= nmin && j - nmin + 1 <= Length[coeffs], coeffs[[j - nmin + 1]], If[j < nmin, 0, Null]]];
  If[U === {}, Return[{jetMerge[{{0, c0}}, ell, ass], P, D}, Module]];
  res = pUnitSeries[U, P, D, cf, Kw, ell, ass, limit];
  {jetAdd[jetMerge[{{0, c0}}, ell, ass], res[[1]], res[[2]], ell, ass], res[[2]], res[[3]]}];

(* Native formal order alone does not specify an analytic logarithmic degree.
   Under the admitted finite-logarithmic tail contract, a half lattice step
   absorbs any fixed degree. Retained coefficient degrees do not prove that
   contract or determine the unknown degree. Shared by both native importers. *)
nativeSeriesTailPrecision[sd_SeriesData] := {(sd[[5]] - 1/2)/sd[[6]], 0};

nativePowerLogSeries[s_, u_, ell_, ass_, Kw_, limit_] := Module[
  {parts, sd, rest, rows = {}, extra, pd},
  If[Head[s] === Series || (Head[s] =!= SeriesData && FreeQ[s, SeriesData]),
   fail["UnsupportedInput", "The native result is not a resolved power-log series."]];
  parts = If[Head[s] === Plus, List @@ s, {s}];
  sd = Select[parts, Head[#] === SeriesData &];
  rest = Select[parts, Head[#] =!= SeriesData &];
  If[Length[sd] =!= 1 || ! (sd[[1, 1]] === u && sd[[1, 2]] === 0) ||
      ! IntegerQ[sd[[1, 6]]] || sd[[1, 6]] < 1 || ! FreeQ[rest, _SeriesData | _Series],
    fail["UnsupportedInput", "The native series must use the recorded positive local variable at zero and a supported power-log form."]];
  sd = First[sd];
  Do[If[! zeroQ[sd[[3, i]], ass],
    Module[{cj = fwd[sd[[3, i]] /. Log[u] -> ell, u, ell, ass, Infinity, limit]},
     If[cj[[2]] =!= Infinity, fail["UnsupportedInput", "A Series coefficient is not a finite power-log expression.", <|"Coefficient" -> sd[[3, i]]|>]];
     rows = Join[rows, jetShift[cj[[1]], (sd[[4]] + i - 1)/sd[[6]]]]]],
   {i, Length[sd[[3]]]}];
  pd = nativeSeriesTailPrecision[sd];
  extra = If[rest === {}, pConst[0, ell, ass], fwd[Total[rest], u, ell, ass, Kw, limit]];
  pAdd[{jetMerge[rows, ell, ass], pd[[1]], pd[[2]]}, extra, ell, ass]];

(* Reconcile whole normalized probes, including their regular summands and
   coefficient power shifts. Only a strictly better, compatible second probe
   may sharpen the first error. No observed coefficient means an unknown tail,
   not exactness or a log-free bound at the second native endpoint. *)
nativeRefineSeriesTail[first_, second_, ell_, ass_] := Module[{delta, pd},
  If[! less[first[[2]], second[[2]]], Return[first, Module]];
  delta = jetAdd[second[[1]], jetScale[first[[1]], -1, ell, ass], second[[2]], ell, ass];
  If[delta =!= {} && less[delta[[1, 1]], first[[2]]], Return[first, Module]];
  pd = If[delta === {}, Rest[second],
    combinePrecision[{delta[[1, 1]], polyDegree[delta[[1, 2]], ell]}, Rest[second]]];
  If[less[pd[[1]], first[[2]]] ||
      (equal[pd[[1]], first[[2]]] && pd[[2]] > first[[3]]), Return[first, Module]];
  {first[[1]], pd[[1]], pd[[2]]}];

(* The optional extra native probe supplies evidence, never a guessed degree. *)
fwdSeries[e_, u_, ell_, ass_, Kw_, limit_] := Module[{order, s, first, s2, second},
  If[Kw === Infinity, fail["InfiniteSeries", "The expression is not a finite power-log sum and no finite working order was given.", <|"Expression" -> e|>]];
  order = Max[1, Ceiling[canon[Kw]]];
  s = Quiet[Series[e, {u, 0, order}, Assumptions -> ass && u > 0]];
  first = nativePowerLogSeries[s, u, ell, ass, Kw, limit];
  s2 = Quiet[Series[e, {u, 0, order + 1}, Assumptions -> ass && u > 0]];
  second = catch[nativePowerLogSeries[s2, u, ell, ass, Kw, limit]];
  If[FailureQ[second], first, nativeRefineSeriesTail[first, second, ell, ass]]];

(* ------------------------------------------------------------------ *)
(* Endpoint normalization                                               *)
(* ------------------------------------------------------------------ *)

localCoordinate[x_, x0_, direction_] := Module[{dir = direction, u = Unique["u$"], sub, s},
  Which[
   x0 === Infinity, If[dir === Automatic, dir = "FromBelow"];
   If[dir =!= "FromBelow", fail["InvalidDirection", "x -> Infinity is approached from below."]];
   sub = 1/u; s = 1,
   x0 === -Infinity, If[dir === Automatic, dir = "FromAbove"];
   If[dir =!= "FromAbove", fail["InvalidDirection", "x -> -Infinity is approached from above."]];
   sub = -1/u; s = -1,
   True,
   If[! (NumericQ[x0] && exactQ[x0] && TrueQ[Simplify[Element[x0, Reals]]]),
    fail["InvalidExpansionPoint", "The expansion point must be an exact real number, Infinity or -Infinity."]];
   If[dir === Automatic, dir = "FromAbove"];
   Which[dir === "FromAbove", sub = x0 + u; s = 1,
    dir === "FromBelow", sub = x0 - u; s = -1,
    True, fail["InvalidDirection", "Direction must be Automatic, \"FromAbove\" or \"FromBelow\"."]]];
  <|"u" -> u, "Substitution" -> sub, "Sign" -> s, "Direction" -> dir,
    "Infinite" -> (x0 === Infinity || x0 === -Infinity),
    (* the local variable and its logarithm in terms of x *)
    "LocalVariable" -> Which[x0 === Infinity, 1/x, x0 === -Infinity, -1/x, dir === "FromAbove", x - x0, True, x0 - x]|>];

(* Only peel outer conditions and split top-level assumption conjuncts.
   Held scopes and nested conditional expressions retain their own meaning. *)
splitApproachInput[f_, x_, ass_] := Module[{body = f, condition = True, clauses},
  While[Head[body] === ConditionalExpression,
    condition = condition && body[[2]]; body = body[[1]]];
  clauses = If[Head[ass] === And, List @@ ass, {ass}];
  {body, And @@ Select[clauses, FreeQ[#, x] &],
    condition && And @@ Select[clauses, ! FreeQ[#, x] &]}];

(* ------------------------------------------------------------------ *)
(* Forward expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticExpansion] = {Assumptions :> $Assumptions, Direction -> Automatic, SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};
SetAttributes[AsymptoticExpansion, HoldAllComplete];
AsymptoticExpansion[args___] := expansionHeldEntry[args];
(* Preserve explicit callable syntax before native evaluation can turn, for
   example, InverseFunction[Exp] into the symbol Log. All other arguments still
   receive the ordinary evaluation of forwardEntry, including option Sequences. *)
SetAttributes[{forwardHeldEntry, forwardHeldExpression, forwardCallable}, HoldAllComplete];
forwardHeldEntry[f_, args___] := forwardEntry[forwardHeldExpression[f], args];
forwardHeldEntry[args___] := forwardEntry[args];
forwardHeldExpression[f : (_InverseFunction | _Function)] := forwardCallable[f];
forwardHeldExpression[ConditionalExpression[f_, condition_]] := ConditionalExpression[forwardHeldExpression[f], condition];
forwardHeldExpression[f_] := f;
forwardApplyCallable[f_Function, x_] := Module[{arity},
  arity = catch[inverseFunctionCallableArity[f, 1]];
  If[FailureQ[arity], fail["CallableArity", "An unapplied pure Function must accept one expansion variable.", <|"Cause" -> arity|>]];
  Quiet[Check[f[x], fail["CallableArity", "An unapplied pure Function must accept one expansion variable."],
    {Function::slotn}], Function::slotn]];
forwardApplyCallable[f_, x_] := f[x];
forwardExpression[forwardCallable[f_], x_] := forwardApplyCallable[f, x];
forwardExpression[f : (_InverseFunction | _Function), x_] := forwardApplyCallable[f, x];
forwardExpression[ConditionalExpression[f_, condition_], x_] := ConditionalExpression[forwardExpression[f, x], condition];
forwardExpression[f_, x_] := f;
forwardEntry[f_, {x_Symbol, x0_, cutoff_}, opts : OptionsPattern[AsymptoticExpansion]] := forwardPublic[forwardExpression[f, x], x, x0, cutoff, opts];
forwardEntry[f_, {x_Symbol, x0_}, opts : OptionsPattern[AsymptoticExpansion]] := forwardPublic[forwardExpression[f, x], x, x0, Automatic, opts];
forwardEntry[f_, x_Symbol -> x0_, opts : OptionsPattern[AsymptoticExpansion]] := forwardEntry[f, {x, x0}, opts];
forwardEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticExpansion[f, {x, x0, cutoff}] or AsymptoticExpansion[f, x -> x0, SeriesTermGoal -> n] (also accepting {x, x0})."|>];

(* compute the forward jet of f in the local variable to absolute precision >= K *)
forwardJet[fu_, u_, ell_, ass_, K_, limit_, extra_: 1] := Module[{Kw, res, tries = 0},
  Kw = K + extra;
  While[True,
   tries++;
   res = Catch[fwd[fu, u, ell, ass, Kw, limit], $tag];
   If[FailureQ[res],
    If[res[[1]] === "UnknownLeadingTerm" && tries <= 12, Kw = Max[1, 2 Kw + 1]; Continue[]];
    Throw[res, $tag]];
   If[res[[2]] === Infinity || ! less[res[[2]], K], Break[]];
   If[tries > 8, fail["InsufficientOrder", "Could not reach the requested precision.", <|"Reached" -> res[[2]]|>]];
   Kw = Kw + (K - res[[2]]) + 1];
  res];

(* exact jet of a finite power-log expression, or $Failed when an infinite series would be needed *)
exactJet[fu_, u_, ell_, ass_, limit_] := Module[{r = Catch[fwd[fu, u, ell, ass, Infinity, limit], $tag]},
  Which[FailureQ[r] && r[[1]] === "InfiniteSeries", $Failed,
   FailureQ[r] && r[[1]] === "UnsupportedInput", $Failed,
   FailureQ[r], Throw[r, $tag],
   True, r]];

forwardCore[f_, x_, x0_, cutoff0_, opts : OptionsPattern[AsymptoticExpansion]] := Module[
  {ass = optionAssumptions[AsymptoticExpansion, {opts}], dir = OptionValue[AsymptoticExpansion, {opts}, Direction],
   goal = OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, cutoff = cutoff0, T, tries = 0, K, ex, normalized, result},
  validateInput[f, limit];
  If[! FreeQ[ass, x], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  normalized = gammaLogarithmNormalize[f, x, ass, coord, limit];
  fu = normalized["Expression"] /. x -> coord["Substitution"];
  If[cutoff === Automatic,
   If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
   ex = exactJet[fu, u, ell, ass, limit];
   If[ex =!= $Failed,
    T = ex[[1]];
    cutoff = If[Length[T] > goal, T[[goal + 1, 1]], Infinity];
    jet = ex,
    K = 1;
    While[True,
     tries++;
     jet = forwardJet[fu, u, ell, ass, K, limit, 0];
     T = jet[[1]];
     If[Length[T] > goal || jet[[2]] === Infinity, Break[]];
     If[tries > 12, fail["ResourceLimit", "SeriesTermGoal iteration did not terminate."]];
     K = 2 K + 1];
    cutoff = If[Length[T] > goal, T[[goal + 1, 1]], Infinity];
    If[cutoff =!= Infinity, jet = forwardJet[fu, u, ell, ass, cutoff, limit, 1]]],
   If[! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]];
   ex = exactJet[fu, u, ell, ass, limit];
   jet = If[ex =!= $Failed, ex, forwardJet[fu, u, ell, ass, cutoff, limit, 1]]];
  result = makeForwardObject[jet, cutoff, f, x, x0, coord, u, ell, ass, goal];
  If[! TrueQ[normalized["Changed"]], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|
    "TargetDomain" -> Lookup[result[[1]], "TargetDomain", True] && normalized["Domain"],
    "NormalizedExpression" -> normalized["Expression"],
    "Transformation" -> "Real logarithms of positive Gamma and Barnes G products are normalized before ordinary power-log expansion.",
    "AsymptoticReference" -> If[FreeQ[f, _BarnesG | _LogBarnesG], "https://dlmf.nist.gov/5.11.E1", "https://dlmf.nist.gov/5.17.E5"]|>]]];

makeForwardObject[jet_, cutoff_, f_, x_, x0_, coord_, u_, ell_, ass_, goal_] := Module[
  {T, P, D, kept, omitted, remData, wexpr, logw, expr, terms, frontier, sd},
  {T, P, D} = jet;
  T = realCoefficientRows[T, ell, ass];
  kept = Select[T, less[#[[1]], cutoff] &];
  omitted = Select[T, ! less[#[[1]], cutoff] &];
  If[IntegerQ[goal] && Length[kept] > goal, omitted = Join[Drop[kept, goal], omitted]; kept = Take[kept, goal]];
  remData = Which[
    omitted =!= {}, {omitted[[1, 1]], polyDegree[omitted[[1, 2]], ell]},
    P === Infinity, None,
    True, {P, D}];
  frontier = If[omitted =!= {}, omitted[[1]], None];
  wexpr = coord["LocalVariable"];
  logw = Which[x0 === Infinity, -Log[x], x0 === -Infinity, -Log[-x], True, Log[wexpr]];
  terms = {ToRadicals[#[[1]]], ToRadicals[#[[2]]] /. ell -> logw} & /@ kept;
  expr = Total[(Which[x0 === Infinity, x^(-#[[1]]), x0 === -Infinity, (-x)^(-#[[1]]), True, wexpr^#[[1]]] #[[2]]) & /@ terms];
  sd = makeSeriesData[terms, x, x0, coord, remData, logw];
  GeneralizedSeries[<|
    "Kind" -> "Forward",
    "Expression" -> expr,
    "Remainder" -> If[remData === None, 0, PowerLogRemainder[wexpr, ToRadicals[remData[[1]]], remData[[2]]]],
    "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderVariable" -> wexpr,
    "FrontierTerm" -> If[frontier === None, If[P === Infinity, 0, Missing["Unknown"]], wexpr^ToRadicals[frontier[[1]]] (ToRadicals[frontier[[2]]] /. ell -> logw)],
    "Terms" -> terms,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[kept],
    "TermConvention" -> "Each {beta, C} means w^beta C with w the local variable (x - x0, x0 - x, 1/x or -1/x); logarithms have been substituted.",
    "Blocks" -> kept, "LogVariable" -> ell, "LocalVariable" -> u,
    "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Cutoff" -> ToRadicals[cutoff], "Precision" -> {P, D},
    "Exact" -> (P === Infinity && omitted === {}),
    "Function" -> f, "Assumptions" -> ass,
    "SeriesData" -> sd|>]];

makeSeriesData[terms_, x_, x0_, coord_, remData_, logw_] :=
  If[(coord["Direction"] === "FromBelow" && ! coord["Infinite"]) || x0 === -Infinity,
    Missing["NotAvailable"], makeRationalSeriesData[terms, x, x0, remData]];

(* Native SeriesData is an optional dense view of the sparse result. Its
   remainder index does not require trailing zero coefficients. Bound the
   native integer fields and their order difference, then the retained
   lattice span, before allocating or scaling any coefficients. A native
   order difference outside the signed range can silently discard terms. *)
makeRationalSeriesData[terms_, x_, x0_, remData_, scale_: 1] := Module[
  {exps, den, nmin, nmax, span, count, coeffs, limit = 100000,
   nativeMax = 2^($SystemWordLength - 1) - 1},
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  If[remData[[2]] =!= 0, Return[Missing["LogarithmicRemainder",
    <|"RemainderPower" -> remData[[1]], "RemainderLogDegree" -> remData[[2]]|>], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = If[exps === {}, remData[[1]] den, Min[exps] den]; nmax = remData[[1]] den;
  span = nmax - nmin;
  If[! TrueQ[1 <= den <= nativeMax && -nativeMax - 1 <= nmin <= nativeMax &&
      -nativeMax - 1 <= nmax <= nativeMax && 0 <= span <= nativeMax],
    Return[Missing["NativeSeriesDataRange", <|"Indices" -> {nmin, nmax, den},
      "OrderSpan" -> span, "AllowedIndexRange" -> {-nativeMax - 1, nativeMax},
      "MaximumDenominator" -> nativeMax, "MaximumOrderSpan" -> nativeMax|>], Module]];
  count = If[exps === {}, 0, Max[exps] den - nmin + 1];
  If[count > limit, Return[Missing["DenseSeriesDataLimit",
    <|"RequiredCoefficients" -> count, "Limit" -> limit|>], Module]];
  coeffs = ConstantArray[0, count];
  Do[coeffs[[t[[1]] den - nmin + 1]] = scale^(-t[[1]]) t[[2]], {t, terms}];
  SeriesData[x, x0, coeffs, nmin, nmax, den]];

(* ------------------------------------------------------------------ *)
(* Model construction for the inverse                                   *)
(* ------------------------------------------------------------------ *)

rowsToModel[rows0_List, u_, ell_, ass_, symbolic_] := Module[{rows, lead, p, a, y0 = 0, rest, deltas, polys},
  rows = realCoefficientRows[rows0, ell, ass, symbolic];
  If[rows === {}, fail["ZeroFunction", "The function is constant or zero near the expansion point; no inverse branch."]];
  If[symbolic,
   Module[{cands = Select[rows, Function[r, And @@ (TrueQ[Simplify[r[[1]] <= #[[1]], ass]] & /@ rows)]]},
    If[cands === {}, fail["UndecidableLeadingTerm", "No provably least exponent under the assumptions."]];
    lead = First[cands];
    rows = Prepend[DeleteCases[rows, lead], lead]]];
  lead = First[rows];
  If[zeroQ[lead[[1]], ass],
   If[! FreeQ[lead[[2]], ell], fail["LogarithmicLimit", "The function has a logarithmic singularity at the expansion point (leading block Log[u]^k); this is outside the supported class."]];
   y0 = lead[[2]]; rows = Rest[rows];
   If[rows === {}, fail["ZeroFunction", "The function is constant near the expansion point."]];
   If[symbolic,
    Module[{cands = Select[rows, Function[r, And @@ (TrueQ[Simplify[r[[1]] <= #[[1]], ass]] & /@ rows)]]},
     If[cands === {}, fail["UndecidableLeadingTerm", "No provably least nonconstant exponent under the assumptions."]];
     lead = First[cands]; rows = Prepend[DeleteCases[rows, lead], lead]],
    lead = First[rows]]];
  p = lead[[1]]; a = lead[[2]];
  If[! FreeQ[a, ell], fail["LogarithmicLeadingTerm",
    "The ordinary power-log engine requires a constant leading coefficient. This logarithmic leading block needs an admitted Lambert or logarithmic-coordinate reduction."]];
  If[! TrueQ[Simplify[a != 0, ass]], fail["UnprovedNonzeroLeadingCoefficient", "The leading coefficient must be provably nonzero.", <|"Coefficient" -> a|>]];
  If[! TrueQ[Simplify[Element[a, Reals], ass]], fail["UnprovedRealCoefficient", "The leading coefficient must be provably real.", <|"Coefficient" -> a|>]];
  rest = Rest[rows];
  deltas = If[symbolic, Simplify[#[[1]] - p, ass], canon[#[[1]] - p]] & /@ rest;
  polys = polyCanon[#[[2]]/a, ell, ass] & /@ rest;
  Do[If[! realPolynomialQ[q, ell, ass],
     fail["UnprovedRealCoefficient", "All coefficients must be provably real under the assumptions.", <|"Polynomial" -> q|>]], {q, polys}];
  If[symbolic,
   Do[If[! TrueQ[Simplify[d > 0, ass]], fail["UnprovedPositiveGap", "A power gap could not be proved positive.", <|"Gap" -> d|>]], {d, deltas}]];
  <|"Limit" -> y0, "LeadingCoefficient" -> a, "LeadingPower" -> p, "Gaps" -> deltas,
    "Polynomials" -> polys, "LogVariable" -> ell, "Variable" -> u, "Rows" -> rows,
    "Symbolic" -> symbolic, "Assumptions" -> ass|>];

(* ------------------------------------------------------------------ *)
(* Multi-index enumeration                                              *)
(* ------------------------------------------------------------------ *)

indexRegion[d_List, W_, inclusive_, limit_] := Module[
  {m = Length[d], inside, nodes = 0, visit, boundary = <||>, ok, add, q, key, indexKey},
  If[m == 0, Return[<|"Inside" -> {{}}, "Boundary" -> {}|>, Module]];
  ok[w_] := If[inclusive, leq[w, W], less[w, W]];
  add[] := (nodes++;
    If[nodes > limit, fail["ResourceLimit", "Multi-index enumeration exceeded MaxTerms.", <|"MaxTerms" -> limit|>]]);
  visit[j_, sofar_, prefix_] := Module[{k = 0},
    If[j > m,
     add[]; Sow[prefix];
     (* Only the outside neighbors can belong to the boundary.  Deduplicate
        them as they are found, without allocating all m times Length[inside]
        neighbors.  Both retained and boundary indices consume the budget. *)
     Do[If[! ok[sofar + d[[h]]],
       q = ReplacePart[prefix, h -> prefix[[h]] + 1]; key = indexKey[q];
       If[! KeyExistsQ[boundary, key], add[]; AssociateTo[boundary, key -> q]]], {h, m}];
     Return[Null, Module]];
    While[ok[sofar + k d[[j]]],
     visit[j + 1, sofar + k d[[j]], Append[prefix, k]];
     k++]];
  inside = Reap[visit[1, 0, {}]][[2]];
  inside = If[inside === {}, {}, First[inside]];
  <|"Inside" -> inside, "Boundary" -> Values[boundary]|>];

depthRegion[m_, N_, limit_] := Module[{visit, indices, count},
  If[m == 0, Return[<|"Inside" -> {{}}, "Boundary" -> {}|>, Module]];
  (* Stars and bars counts the retained simplex and its degree-(N+1) shell.
     Check that count before allocating anything; a surrounding cube is
     exponentially larger than the requested set when there are many gaps. *)
  count = Binomial[N + m + 1, m];
  If[count > limit, fail["ResourceLimit", "Depth enumeration exceeded MaxTerms.",
    <|"MaxTerms" -> limit, "RequiredTerms" -> count|>]];
  visit[j_, remaining_, prefix_] := Module[{k},
    If[j > m, Sow[prefix, If[remaining == 0, "Boundary", "Inside"]]; Return[Null, Module]];
    Do[visit[j + 1, remaining - k, Append[prefix, k]], {k, 0, remaining}]];
  indices = Association[Reap[visit[1, N + 1, {}], _, Rule][[2]]];
  <|"Inside" -> Lookup[indices, "Inside", {}], "Boundary" -> Lookup[indices, "Boundary", {}]|>];

(* ------------------------------------------------------------------ *)
(* Lagrange coefficient for one multi-index                             *)
(* ------------------------------------------------------------------ *)

lagrangeCoefficient[k_List, d_List, polys_List, p_, r_, ell_, ass_, symbolic_] := Module[{n = Total[k], w, q},
  If[n == 0, Return[{0, 1}, Module]];
  w = If[symbolic, Simplify[k . d, ass], canon[k . d]];
  q = Expand[Times @@ MapThread[Power, {polys, k}]];
  Do[q = Expand[D[q, ell] + (r + w + p j) q], {j, 1, n - 1}];
  q = Expand[(-1)^n r q/(p^n (Times @@ (Factorial /@ k)))];
  {w, polyCanon[q, ell, ass]}];

(* ------------------------------------------------------------------ *)
(* Newton engine in the jet algebra                                     *)
(* ------------------------------------------------------------------ *)

modelEquation[U_List, d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{ans, part},
  ans = jetAdd[jetUnitPower[U, p, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
  Do[If[less[d[[i]], cut],
    part = jetComposeBlock[U, p + d[[i]], polys[[i]], cut - d[[i]], ell, ass, limit];
    ans = jetAdd[ans, jetShift[part, d[[i]]], cut, ell, ass]], {i, Length[d]}];
  ans];
modelEquationDerivative[U_List, d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{ans, part},
  ans = jetScale[jetUnitPower[U, p - 1, cut, ell, ass, limit], p, ell, ass];
  Do[If[less[d[[i]], cut],
    part = jetComposeBlock[U, p + d[[i]] - 1, Expand[(p + d[[i]]) polys[[i]] + D[polys[[i]], ell]], cut - d[[i]], ell, ass, limit];
    ans = jetAdd[ans, jetShift[part, d[[i]]], cut, ell, ass]], {i, Length[d]}];
  ans];

newtonSolve[d_List, polys_List, p_, cut_, ell_, ass_, limit_] :=
  newtonSolveDoubling[d, polys, p, cut, ell, ass, limit];

(* ------------------------------------------------------------------ *)
(* Inverse expansion: public                                            *)
(* ------------------------------------------------------------------ *)

Options[AsymptoticInverse] = {Assumptions :> $Assumptions, Direction -> Automatic, Method -> "Lagrange",
  "Power" -> 1, "InputRemainder" -> Automatic, "Truncation" -> "Exponent",
  SeriesTermGoal -> Automatic, "MaxTerms" -> 20000};

SetAttributes[AsymptoticInverse, HoldAllComplete];
AsymptoticInverse[args___] := catch[inverseEntry[args]];
inverseEntry[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, x0, y, cutoff, opts];
inverseEntry[f_, {x_Symbol, x0_}, y_Symbol, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, x0, y, Automatic, opts];
inverseEntry[f_, x_Symbol, y_Symbol, opts : OptionsPattern[AsymptoticInverse]] := inverseFunctionPublicInverse[f, x, 0, y, Automatic, opts];
inverseEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" ->
   "Use AsymptoticInverse[f, {x, x0}, {y, cutoff}] or AsymptoticInverse[f, {x, x0}, y, SeriesTermGoal -> n]."|>];

inverseDispatch[f_, x_, x0_, y_, cutoff_, opts___] := Module[{s},
  If[! FreeQ[f, _InverseFunction], Return[construct[f, x, x0, y, cutoff, opts], Module]];
  s = gammaInverseConstruct[f, x, x0, y, cutoff, opts];
  If[s =!= $Failed, Return[s, Module]];
  s = lambertConstruct[f, x, x0, y, cutoff, opts];
  If[s === $Failed, s = coordinateConstruct[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, s = sourceCoordinateConstruct[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, s = logarithmicDispatch[f, x, x0, y, cutoff, opts]];
  If[s === $Failed, construct[f, x, x0, y, cutoff, opts], s]];

inverseBlocks[d_, polys_, p_, rint_, H_, method_, ell_, ass_, limit_, region_] := Module[{U, blocks},
  If[method === "GroupedLagrange" && H =!= Infinity,
    Return[groupedLagrangeBlocks[d, polys, p, rint, H, ell, ass, limit], Module]];
  If[method === "Newton",
   U = newtonSolve[d, polys, p, H, ell, ass, limit];
   blocks = jetUnitPower[U, rint, H, ell, ass, limit];
   If[blocks === {} || ! (blocks[[1, 1]] === 0), blocks = jetMerge[Join[{{0, 1}}, blocks], ell, ass]];
   blocks,
   jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ region["Inside"], ell, ass]]];

(* Look past finitely many cancelled boundary blocks. A bounded search retains
   the original valid (possibly non-sharp) bound if no nonzero block is found. *)
inverseFrontier[region_, d_, polys_, p_, rint_, ell_, ass_, limit_] :=
  First[inverseFrontierWithCount[region, d, polys, p, rint, ell, ass, limit]];
inverseFrontierWithCount[region0_, d_, polys_, p_, rint_, ell_, ass_, limit_] := Module[
  {region = region0, ws, weight, near, poly, first = None, result = None, next, attempt, count = 0},
  If[d === {} || region["Boundary"] === {}, Return[{None, 0}, Module]];
  Do[
   ws = canon[# . d] & /@ region["Boundary"];
   weight = First[Sort[ws, leq]];
   near = Pick[region["Boundary"], equal[#, weight] & /@ ws];
   count += Length[near];
   poly = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, False] & /@ near, ell, ass];
   result = {weight, If[poly === {}, 0, poly[[1, 2]]]};
   If[first === None, first = result];
   If[poly =!= {}, Break[]];
   next = Catch[indexRegion[d, weight, True, limit], $tag];
   If[FailureQ[next] || next["Boundary"] === {}, result = first; Break[]];
   region = next,
   {attempt, 8}];
  {If[result[[2]] === 0, first, result], count}];

(* Return the real logarithm only for a proved positive monomial tree.
   Recursion preserves reciprocal/scaled bases introduced by coordinates;
   realness of an outer power cannot erase an unproved inner branch. *)
finitePositiveMonomialLog[e_, u_Symbol, ass_] := Module[{parts}, Which[
  e === u, Log[u],
  FreeQ[e, u], If[TrueQ[Simplify[e > 0, ass]], Log[e], $Failed],
  Head[e] === Power && FreeQ[e[[2]], u] &&
      TrueQ[Simplify[Element[e[[2]], Reals], ass]],
    parts = finitePositiveMonomialLog[e[[1]], u, ass];
    If[parts === $Failed, $Failed, e[[2]] parts],
  Head[e] === Times,
    parts = finitePositiveMonomialLog[#, u, ass] & /@ List @@ e;
    If[MemberQ[parts, $Failed], $Failed, Total[parts]],
  True, $Failed]];

(* finite power-log parser that tolerates symbolic exponents (used by depth truncation) *)
parseFinite[e_, u_Symbol, ell_Symbol, ass_] := Module[{ex, summands, rows = {}, ok = True},
  ex = Expand[(e /. Log[b_] :> With[{lg = finitePositiveMonomialLog[b, u, ass]},
      If[lg === $Failed, Log[b], lg]]) /. Log[u] -> ell];
  summands = If[Head[ex] === Plus, List @@ ex, {ex}];
  Do[Module[{factors, expo = 0, coef = 1},
    factors = If[Head[term] === Times, List @@ term, {term}];
    Do[Which[
       FreeQ[factor, u], coef = coef factor,
       factor === u, expo += 1,
       MatchQ[factor, Power[u, _]] && FreeQ[factor[[2]], u | ell], expo += factor[[2]],
       True, ok = False], {factor, factors}];
    If[ok && (! PolynomialQ[coef, ell] || ! FreeQ[coef, u]), ok = False];
    If[ok, AppendTo[rows, {expo, coef}]]], {term, summands}];
  If[! ok, $Failed, rows]];

(* BEGIN SOURCE: src/Kernel/ExactTermination.wl
   Source SHA256 (UTF-8/LF): 9a2ae123b5f01c40b1e70e47b93326c6ce31d2303f4b4eb94cb9e587bdd94a17 *)
(* Loaded in AsymptoticAnalysis`Private`.  This is a bounded verification of an
   already computed inverse candidate against the ORIGINAL expression.  It
   does not infer exactness from a finite forward model or solve an equation. *)

exactTerminationCoreQ[e_, x_] := Which[
  FreeQ[e, x], True,
  e === x, True,
  MemberQ[{Plus, Times}, Head[e]], And @@ (exactTerminationCoreQ[#, x] & /@ List @@ e),
  Head[e] === Power && FreeQ[e[[2]], x] && exactRealQ[e[[2]]], exactTerminationCoreQ[e[[1]], x],
  True, False];

exactInverseTermination[f_, x_, x0_, coord_Association, model_Association,
    blocks_List, ell_, ass_] := Module[
  {z = Unique["z$"], bracket, candidate, local, target, domain, verified},
  If[blocks === {} || blocks[[1]] =!= {0, 1} ||
     ! And @@ (less[0, #[[1]]] & /@ Rest[blocks]) ||
     LeafCount[f] > 300 || LeafCount[blocks] > 500, Return[None, Module]];
  bracket = Total[(z^ToRadicals[#[[1]]] (ToRadicals[#[[2]]] /. ell -> Log[z])) & /@ blocks];
  candidate = If[coord["Infinite"], coord["Sign"] bracket/z,
    x0 + coord["Sign"] z bracket];
  local = coord["LocalVariable"] /. x -> candidate;
  target = model["Limit"] + model["LeadingCoefficient"] z^ToRadicals[model["LeadingPower"]];
  domain = ass && 0 < z < 1 && local > 0;
  verified = TimeConstrained[
    Quiet[Check[FullSimplify[(f /. x -> candidate) == target, domain], False]],
    2, False];
  If[! TrueQ[verified], Return[None, Module]];
  <|"Verification" -> "Exact symbolic composition with the original forward expression",
    "Uniformizer" -> z, "Candidate" -> candidate, "Target" -> target,
    "BranchAssumptions" -> domain, "Verified" -> True|>];
(* END SOURCE: src/Kernel/ExactTermination.wl *)


construct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   method = OptionValue[AsymptoticInverse, {opts}, Method], r = OptionValue[AsymptoticInverse, {opts}, "Power"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"], trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   coord, u, ell = Unique["ell$"], fu, jet, rows, model, p, a, d, polys, y0, symbolic, H, cutoff = cutoff0,
   region, blocks, frontier, rem, inputCap, v, z, expr, terms, wexpr, rint, obj, remData, forwardRem, depth, exactModel, Kf, tries, gexpr, logw, need,
   termination = None, terminationTried = Missing["NotTried"], terminationEligible, reliableBlocks, computationState = None},
  validateInput[f, limit];
  If[x === y, fail["InvalidVariables", "Source and target variables must be distinct symbols."]];
  If[! FreeQ[f, y], fail["InvalidVariables", "The forward expression must not contain the target variable."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only; positivity of the local variable is built in."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  symbolic = (trunc === "Depth");
  If[! MemberQ[{"Exponent", "Depth"}, trunc], fail["InvalidOption", "Truncation must be \"Exponent\" or \"Depth\"."]];
  If[! MemberQ[{"Lagrange", "Newton", "GroupedLagrange"}, method], fail["InvalidOption", "Method must be Lagrange, Newton or GroupedLagrange."]];
  If[! (NumericQ[r] && exactQ[r] && TrueQ[Simplify[Element[r, Reals]]] && r =!= 0), fail["InvalidOption", "\"Power\" must be a nonzero exact real number."]];
  If[cutoff =!= Automatic && ! symbolic && ! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]];
  If[cutoff === Automatic && ! (IntegerQ[goal] && goal >= 1), fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  If[r =!= 1 && coord["Sign"] =!= 1 && ! IntegerQ[r], fail["InvalidOption", "\"Power\" -> r with non-integer r requires a positive local variable (x -> x0 from above or x -> +Infinity)."]];
  rint = If[coord["Infinite"], -r, r];
  terminationEligible = r === 1 && cutoff0 === Automatic && MemberQ[{Automatic, None}, inputRem] && exactTerminationCoreQ[f, x];
  fu = f /. x -> coord["Substitution"];
  (* ---------------- depth truncation with possibly symbolic exponents ---------------- *)
  If[symbolic,
   rows = parseFinite[fu, u, ell, ass];
   If[rows === $Failed, fail["UnsupportedInput", "Depth truncation requires a finite power-log expression."]];
   model = rowsToModel[rows, u, ell, ass, True];
   p = model["LeadingPower"]; a = model["LeadingCoefficient"]; d = model["Gaps"]; polys = model["Polynomials"]; y0 = model["Limit"];
   If[! TrueQ[Simplify[Element[p, Reals], ass]] || ! (provablyPositive[p, ass] || provablyNegative[p, ass]),
    fail["UnprovedLeadingPower", "The leading power must be provably real with a known nonzero sign."]];
   If[method =!= "Lagrange", fail["UnsupportedOption", "Depth truncation uses the Lagrange method."]];
   depth = cutoff; If[cutoff === Automatic, depth = goal];
   If[! IntegerQ[depth] || depth < 0, fail["InvalidCutoff", "Depth truncation needs a nonnegative integer cutoff."]];
   If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Explicit InputRemainder is currently supported with exponent truncation only."]];
   region = depthRegion[Length[d], depth, limit];
   blocks = jetMerge[lagrangeCoefficient[#, d, polys, p, rint, ell, ass, True] & /@ region["Inside"], ell, ass, True];
   If[Length[blocks] > 1, blocks = Quiet[Check[Sort[blocks, TrueQ[Simplify[#1[[1]] <= #2[[1]], ass]] &], blocks]]];
   frontier = Missing["Depth"]; exactModel = True; forwardRem = None; H = Missing["Depth"];
   remData = If[d === {}, None, {Simplify[(rint + (depth + 1) Min @@ d)/Abs[p], ass], (depth + 1) Max @@ (polyDegree[#, ell] & /@ polys)}],
   (* ---------------- exponent truncation ---------------- *)
   Kf = 2; tries = 0;
   jet = exactJet[fu, u, ell, ass, limit];
   While[True,
    tries++;
    If[jet === $Failed || tries > 1, jet = forwardJet[fu, u, ell, ass, Kf, limit, 0]];
    rows = jet[[1]]; exactModel = (jet[[2]] === Infinity);
    If[! exactModel && (rows === {} || (Length[rows] === 1 && rows[[1, 1]] === 0 && FreeQ[rows[[1, 2]], ell])),
     If[tries >= 12, fail["InsufficientForwardOrder", "No nonconstant leading block was found within the working-order budget."]];
     Kf = Max[Kf + 1, 2 Kf]; Continue[]];
    model = rowsToModel[rows, u, ell, ass, False];
    p = model["LeadingPower"]; a = model["LeadingCoefficient"]; d = model["Gaps"]; polys = model["Polynomials"]; y0 = model["Limit"];
    If[! (NumericQ[p] && exactQ[p]), fail["SymbolicExponent", "The leading power must be an exact number; use \"Truncation\" -> \"Depth\" for symbolic exponents."]];
    If[p === 0, fail["ZeroLeadingPower", "The leading power is zero."]];
    Do[If[! (NumericQ[dd] && exactQ[dd]), fail["SymbolicExponent", "Exponents must be exact numbers; use \"Truncation\" -> \"Depth\" with Assumptions for symbolic exponents.", <|"Exponent" -> dd|>]], {dd, d}];
    If[cutoff === Automatic,
     (* term goal: enlarge the inclusive weight bound until goal blocks are present *)
     Module[{count = 0, tries2 = 0},
      computationState = incrementalInverseState[d, polys, p, rint, ell, ass, limit];
      While[True,
       tries2++; If[tries2 > 50 goal + 10, fail["ResourceLimit", "SeriesTermGoal iteration did not terminate."]];
       computationState = advanceInverseState[computationState];
       blocks = computationState["Blocks"];
       count = Length[blocks];
       If[terminationEligible,
        reliableBlocks = If[exactModel, blocks, Select[blocks, less[#[[1]], jet[[2]] - p] &]];
        If[reliableBlocks =!= terminationTried,
         terminationTried = reliableBlocks;
         termination = exactInverseTermination[f, x, x0, coord, model, reliableBlocks, ell, ass];
         If[AssociationQ[termination], blocks = reliableBlocks; Break[]]]];
       If[count >= goal || computationState["NextWeight"] === Infinity, Break[]]];
      region = incrementalInverseRegion[computationState]];
     H = If[AssociationQ[termination], Infinity, computationState["NextWeight"]];
     cutoff = If[H === Infinity, Infinity, canon[(rint + H)/Abs[p]]],
     H = canon[Abs[p] cutoff - rint];
     If[! less[0, H], fail["CutoffTooSmall", "The cutoff must exceed the leading exponent r/|p| of the inverse.", <|"LeadingExponent" -> ToRadicals[rint/Abs[p]]|>]]];
    (* u^rint has error O(z^(P-p+rint)); transport includes the observable derivative. *)
    If[exactModel || AssociationQ[termination], Break[]];
    If[tries > 8, fail["InsufficientForwardOrder", "Could not obtain a forward expansion of sufficient order.", <|"Reached" -> ToRadicals[jet[[2]]]|>]];
    If[cutoff === Infinity,
     (* the truncated forward jet has too few blocks for the requested number of terms *)
     Kf = Max[Kf + 1, 2 Kf]; cutoff = cutoff0; Continue[]];
    need = canon[Abs[p] cutoff + p - rint];
    If[! less[jet[[2]], need], Break[]];
    Kf = Max[Kf + 1, Ceiling[need] + 1];
    cutoff = cutoff0];
   forwardRem = If[exactModel, None, {jet[[2]], jet[[3]]}];
   If[! MemberQ[{None, Automatic}, inputRem],
    If[! MatchQ[inputRem, {_, _Integer?NonNegative}] || ! exactRealQ[inputRem[[1]]],
     fail["InvalidOption", "InputRemainder must be None, Automatic or {rho, k} with exact real rho and nonnegative integer k."]];
    forwardRem = If[forwardRem === None, inputRem, combinePrecision[forwardRem, inputRem]]];
   inputCap = If[AssociationQ[termination] || forwardRem === None, None,
     If[! MatchQ[forwardRem, {_, _Integer?NonNegative}], fail["InvalidOption", "\"InputRemainder\" must be None, Automatic or {rho, k}."]];
     If[! less[Last[model["Rows"]][[1]], forwardRem[[1]]], fail["InvalidOption", "The input remainder power must exceed every supplied forward power."]];
     canon[(forwardRem[[1]] - p + rint)/Abs[p]]];
   If[inputCap =!= None && (cutoff === Infinity || less[inputCap, cutoff]),
    If[cutoff0 === Automatic && Length[Select[blocks, less[(rint + #[[1]])/Abs[p], inputCap] &]] >= goal,
     cutoff = inputCap; H = canon[Abs[p] cutoff - rint];
     region = indexRegion[d, H, False, limit];
     blocks = inverseBlocks[d, polys, p, rint, H, method, ell, ass, limit, region],
     fail["InsufficientInputOrder", "The request exceeds the precision transported from the forward remainder.", <|"MaximumCutoff" -> ToRadicals[inputCap]|>]]];
   If[! AssociationQ[termination] && (cutoff0 =!= Automatic || MemberQ[{"Newton", "GroupedLagrange"}, method]),
    region = If[H === Infinity, indexRegion[d, 1 + If[d === {}, 0, Max[d]], False, limit], indexRegion[d, H, False, limit]];
    blocks = If[H === Infinity && method === "Newton", inverseBlocks[d, polys, p, rint, 1 + If[d === {}, 0, Max[d]], "Lagrange", ell, ass, limit, region],
      inverseBlocks[d, polys, p, rint, H, method, ell, ass, limit, region]]];
   (* frontier: complete coefficient at the first omitted weight *)
   frontier = If[AssociationQ[termination], None, inverseFrontier[region, d, polys, p, rint, ell, ass, limit]];
   remData = If[frontier === None, None, {canon[(rint + frontier[[1]])/Abs[p]], polyDegree[frontier[[2]], ell]}];
   If[inputCap =!= None,
    remData = Which[remData === None, {inputCap, forwardRem[[2]]},
      less[inputCap, remData[[1]]], {inputCap, forwardRem[[2]]},
      equal[inputCap, remData[[1]]], {remData[[1]], Max[remData[[2]], forwardRem[[2]]]},
      True, remData]]];
  (* ---------------- assemble the expression in y ---------------- *)
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The sign of the leading coefficient must be provable.", <|"Coefficient" -> a|>]];
  If[! symbolic && less[p, 0], y0 = If[provablyPositive[a, ass], Infinity, -Infinity]];
  If[symbolic && TrueQ[Simplify[p < 0, ass]], y0 = If[provablyPositive[a, ass], Infinity, -Infinity]];
  v = If[y0 === Infinity || y0 === -Infinity, y, y - y0];
  wexpr = Which[y0 === Infinity, 1/y, y0 === -Infinity, -1/y, provablyPositive[a, ass], v, True, -v];
  z = (v/a)^(1/p);
  logw = Log[v/a]/p;
  terms = Table[{ToRadicals[If[symbolic, Simplify[(rint + b[[1]])/p, ass], canon[(rint + b[[1]])/p]]], ToRadicals[b[[2]]] /. ell -> logw}, {b, blocks}];
  gexpr = Total[((v/a)^#[[1]] #[[2]]) & /@ terms];
  expr = Which[
    coord["Infinite"], coord["Sign"]^r gexpr,
    r === 1, x0 + coord["Sign"] gexpr,
    True, coord["Sign"]^r gexpr];
  rem = If[remData === None, 0, PowerLogRemainder[wexpr, ToRadicals[remData[[1]]], remData[[2]]]];
  obj = <|
    "Kind" -> "Inverse",
    "Scale" -> "PowerLog",
    "Expression" -> expr,
    "Remainder" -> rem,
    "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderVariable" -> wexpr,
    "FrontierTerm" -> Which[frontier === None, 0, MissingQ[frontier], frontier,
      True, coord["Sign"]^r (v/a)^ToRadicals[canon[(rint + frontier[[1]])/p]] (ToRadicals[frontier[[2]]] /. ell -> logw)],
    "Terms" -> terms,
    "TermConvention" -> "Each {beta, C} means (v/a)^beta C with v = y - y0 (or y when y0 is infinite) and C already containing Log[v/a]/p; the sum is the expansion of (x - x0)^r, of (x0 - x)^r, or of x^r.",
    "Blocks" -> blocks, "LogVariable" -> ell,
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Limit" -> y0, "LeadingCoefficient" -> a, "LeadingPower" -> p,
    "Uniformizer" -> z, "Power" -> r, "Cutoff" -> If[cutoff === Infinity || symbolic, cutoff, ToRadicals[cutoff]],
    "Truncation" -> trunc, "Method" -> method,
    "Model" -> model,
    "ForwardExpansion" -> (model["Limit"] + Total[(coord["LocalVariable"]^ToRadicals[#[[1]]] (ToRadicals[#[[2]]] /. ell -> Log[coord["LocalVariable"]])) & /@ model["Rows"]]),
    "LocalVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "ExactModel" -> exactModel, "InputRemainder" -> forwardRem,
    "DeclaredInputRemainder" -> inputRem,
    "ExactTerminationCertificate" -> termination,
    "ComputationState" -> computationState,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[blocks],
    "Function" -> f, "Assumptions" -> ass,
    "Branch" -> "the inverse tends to the expansion point with " <> ToString[coord["LocalVariable"], InputForm] <> " ~ " <> ToString[z, InputForm],
    "SeriesData" -> makeInverseSeriesData[terms, y, y0, a, coord, remData, r, x0]
    |>;
  GeneralizedSeries[obj]];

makeInverseSeriesData[terms_, y_, y0_, a_, coord_, remData_, r_, x0_] :=
  If[r =!= 1 || coord["Sign"] =!= 1 || coord["Infinite"] || x0 =!= 0 ||
      y0 === Infinity || y0 === -Infinity, Missing["NotAvailable"],
    makeRationalSeriesData[terms, y, y0, remData, a]];

(* ------------------------------------------------------------------ *)
(* The GeneralizedSeries object                                            *)
(* ------------------------------------------------------------------ *)

GeneralizedSeries /: Normal[GeneralizedSeries[a_Association]] := a["Expression"];
GeneralizedSeries[a_Association]["Properties"] := Keys[a];
GeneralizedSeries[a_Association][key_String] := Lookup[a, key, Missing["KeyAbsent", key]];
GeneralizedSeries[a_Association][val_?NumericQ] :=
  If[Lookup[a, "Kind", None] === "Native", nativeSeriesValue[a, val], a["Expression"] /. a["Variable"] -> val];
remainderScale[PowerLogRemainder[w_, b_, k_]] := Module[{base, lg},
  {base, lg} = If[MatchQ[w, Power[_, -1]], {w[[1]]^(-b), Log[w[[1]]]}, {w^b, Log[w]}];
  If[k === 0, base, base (1 + Abs[lg])^k]];
(* Interpretation supplies the displayed expression's precedence as well as
   the original object. Keep both held: formatting must not evaluate payloads.
   Read-only boxes prevent edited coefficients from retaining stale metadata. *)
seriesInterpretationBoxes[HoldComplete[display_], HoldComplete[original_], fmt_] :=
  MakeBoxes[Interpretation[display, original], fmt] /.
    box_InterpretationBox :> Append[box, Editable -> False];
heldSeriesSum[HoldComplete[Plus[e___]], HoldComplete[Plus[r___]]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[Plus[e___]], HoldComplete[r_]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[e_], HoldComplete[Plus[r___]]] := HoldComplete[Plus[e, r]];
heldSeriesSum[HoldComplete[e_], HoldComplete[r_]] := HoldComplete[e + r];

GeneralizedSeries /: MakeBoxes[GeneralizedSeries[a_Association], fmt : StandardForm | TraditionalForm] :=
  generalizedSeriesBoxes[HoldComplete[GeneralizedSeries[a]], fmt];
generalizedSeriesBoxes[held : HoldComplete[GeneralizedSeries[a_Association]], fmt_] := Module[{rules, fields, native},
  (* Matching the association's rules works for both evaluated associations and
     raw associations inside MakeBoxes; ordinary Lookup would evaluate them. *)
  rules = Replace[held, HoldComplete[GeneralizedSeries[Association[r___]]] :> HoldComplete[r]];
  native = Cases[rules, HoldPattern[(Rule | RuleDelayed)["Kind", "Native"]], {1}];
  If[native =!= {},
    native = Cases[rules, HoldPattern[(Rule | RuleDelayed)["NativeResult", value_]] :> HoldComplete[value], {1}];
    If[Length[native] === 1, Return[seriesInterpretationBoxes[First[native], held, fmt], Module]]];
  fields = (Cases[rules, HoldPattern[(Rule | RuleDelayed)[#, value_]] :> HoldComplete[value], {1}] &) /@
    {"Expression", "Remainder"};
  Replace[fields, {
    {{HoldComplete[e_]}, {HoldComplete[0]}} :> seriesInterpretationBoxes[HoldComplete[e], held, fmt],
    {{HoldComplete[0]}, {HoldComplete[r_]}} :> seriesInterpretationBoxes[HoldComplete[r], held, fmt],
    {{HoldComplete[e_]}, {HoldComplete[r_]}} :>
      seriesInterpretationBoxes[heldSeriesSum[HoldComplete[e], HoldComplete[r]], held, fmt],
    _ :> RowBox[{"GeneralizedSeries", "[", MakeBoxes[a, fmt], "]"}]}]];
Format[GeneralizedSeries[a_Association], OutputForm] :=
  If[Lookup[a, "Kind", None] === "Native", a["NativeResult"], GeneralizedSeries[a["Expression"], a["Remainder"]]];

(* Small syntactic reductions keep scales readable without evaluating symbols
   or arbitrary expressions supplied to a held MakeBoxes call. *)
heldScaleNegate[HoldComplete[n_Integer]] := With[{negative = -n}, HoldComplete[negative]];
heldScaleNegate[HoldComplete[Rational[n_Integer, d_Integer]]] :=
  With[{negative = -Rational[n, d]}, HoldComplete[negative]];
heldScaleNegate[HoldComplete[Times[-1, e_]]] := HoldComplete[e];
heldScaleNegate[HoldComplete[e_]] := HoldComplete[-e];
heldScalePower[_, HoldComplete[0]] := HoldComplete[1];
heldScalePower[HoldComplete[w_], HoldComplete[1]] := HoldComplete[w];
heldScalePower[HoldComplete[w_], HoldComplete[b_]] := HoldComplete[w^b];
heldScaleTimes[HoldComplete[1], factor_] := factor;
heldScaleTimes[base_, HoldComplete[1]] := base;
heldScaleTimes[HoldComplete[b_], HoldComplete[f_]] := HoldComplete[b f];
heldRemainderScale[HoldComplete[PowerLogRemainder[w_, b_, k_]]] := Module[{base, log, factor},
  {base, log} = Replace[HoldComplete[w], {
    HoldComplete[Power[z_, -1]] :> {heldScalePower[HoldComplete[z], heldScaleNegate[HoldComplete[b]]], HoldComplete[Log[z]]},
    _ :> {heldScalePower[HoldComplete[w], HoldComplete[b]], HoldComplete[Log[w]]}}];
  factor = Replace[log, HoldComplete[l_] :> heldScalePower[HoldComplete[1 + Abs[l]], HoldComplete[k]]];
  heldScaleTimes[base, factor]];
PowerLogRemainder /: MakeBoxes[r : PowerLogRemainder[_, _, _], fmt : StandardForm | TraditionalForm] :=
  Replace[heldRemainderScale[HoldComplete[r]],
    HoldComplete[scale_] :> seriesInterpretationBoxes[HoldComplete[O[scale]], HoldComplete[r], fmt]];
If[! (StringQ[$Version] && StringContainsQ[$Version, "Mathics"]),
  Format[r_PowerLogRemainder, OutputForm] := With[{sc = remainderScale[r]}, HoldForm[O[sc]]]
];

(* ------------------------------------------------------------------ *)
(* Residual check                                                       *)
(* ------------------------------------------------------------------ *)

Options[InverseResidual] = {"MaxTerms" -> 200000};
InverseResidual[GeneralizedSeries[a_Association], opts : OptionsPattern[]] := catch[residual[a, Automatic, OptionValue["MaxTerms"]]];
InverseResidual[GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[residual[a, h, OptionValue["MaxTerms"]]];
InverseResidual[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseResidual[expansion] or InverseResidual[expansion, relativeCutoff]."|>];

residual[a_Association, h_, limit_] := Module[{model = a["Model"], blocks = a["Blocks"], ell = a["LogVariable"], ass = a["Assumptions"],
   p, d, polys, r = a["Power"], cut, U, res, y, v, aa, rint},
  If[Lookup[a, "Kind", ""] === "GammaInverse", Return[gammaInverseResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "BarnesGInverse", Return[barnesInverseResidual[a, h, limit], Module]];
  If[Lookup[a, "Scale", "PowerLog"] === "Transformed", Return[coordinateResidual[a, h, limit], Module]];
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic", Return[lambertResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "LogarithmicInverse", Return[logarithmicResidual[a, h, limit], Module]];
  If[Lookup[a, "Kind", ""] === "FourierInverse", Return[fourierResidual[a, h, limit], Module]];
  If[a["Kind"] =!= "Inverse", fail["Unsupported", "Residuals are computed for inverse expansions only."]];
  If[a["Truncation"] === "Depth", fail["Unsupported", "Residuals are computed for exponent truncation only."]];
  p = model["LeadingPower"]; d = model["Gaps"]; polys = model["Polynomials"]; aa = model["LeadingCoefficient"];
  rint = If[a["ExpansionPoint"] === Infinity || a["ExpansionPoint"] === -Infinity, -r, r];
  cut = If[h === Automatic, If[a["Cutoff"] === Infinity, 1 + If[d === {}, 0, Max[d]], canon[Abs[p] a["Cutoff"] - rint]], h];
  If[! (NumericQ[cut] && exactQ[cut] && less[0, cut]), fail["InvalidCutoff", "The residual cutoff must be a positive exact number."]];
  U = jetTrim[Select[blocks, less[0, #[[1]]] &], cut, ell, ass];
  If[rint =!= 1, U = jetAdd[jetUnitPower[U, 1/rint, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass]];
  res = modelEquation[U, d, polys, p, cut, ell, ass, limit];
  y = a["Variable"];
  v = If[a["Limit"] === Infinity || a["Limit"] === -Infinity, y, y - a["Limit"]];
  <|"ZeroBelowCutoff" -> (res === {}),
    "NormalizedResidual" -> Total[((v/aa)^ToRadicals[canon[#[[1]]/p]] (ToRadicals[#[[2]]] /. ell -> Log[v/aa]/p)) & /@ res],
    "ResidualBlocks" -> res, "RelativeCutoff" -> ToRadicals[cut],
    "Normalization" -> "f(g(y))/(a z^p) - 1 with z the uniformizer; blocks are in z",
    "Scope" -> "Formal composition with the finite forward model only."|>];

(* ------------------------------------------------------------------ *)
(* Numerical check                                                      *)
(* ------------------------------------------------------------------ *)

Options[InverseNumericalCheck] = {WorkingPrecision -> 50};
InverseNumericalCheck[GeneralizedSeries[a_Association], yv_, OptionsPattern[]] := catch[Module[
  {wp = OptionValue[WorkingPrecision], result, root},
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]], Return[gammaInverseNumerical[a, yv, wp], Module]];
  If[Lookup[a, "Kind", ""] === "SpecialInverse" || Lookup[a, "Scale", "PowerLog"] === "Transformed",
    result = If[Lookup[a, "Kind", ""] === "SpecialInverse", specialNumerical[a, yv, wp], coordinateNumericalCheck[a, yv, wp]];
    If[FailureQ[result], Return[result, Module]];
    root = Lookup[result, "ReferenceRoot", Lookup[result, "ExactInverse", Missing["NotAvailable"]]];
    If[KeyExistsQ[a, "SourceDomain"] && ! MissingQ[root], numericalSourceDomainCheck[a, root, yv, wp]];
    Return[result, Module]];
  numericalInverseEvidence[a, yv, wp]]];
InverseNumericalCheck[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseNumericalCheck[expansion, yvalue]."|>];

lambertNumericalCheck[a_Association, yv_, wp_] := numericalInverseEvidence[a, yv, wp];

(* ------------------------------------------------------------------ *)
(* Perturbative (Lagrange-Buermann) formula generator                   *)
(* ------------------------------------------------------------------ *)

PerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := Module[{hy},
  If[x === y || ! FreeQ[h, y], Return[Failure["InvalidVariables", <|"MessageTemplate" -> "Use distinct symbols; h must not contain y."|>]]];
  hy = h /. x -> phi;
  phi + Sum[(-1)^k/k! D[D[phi, y] hy^k, {y, k - 1}], {k, 1, n}]];
PerturbativeInverse[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] := PerturbativeInverse[y, h, {x, y}, n];
PerturbativeInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PerturbativeInverse[phi, h, {x, y}, n] or PerturbativeInverse[h, {x, y}, n]."|>];

(* ------------------------------------------------------------------ *)
(* Model access and single coefficients                                 *)
(* ------------------------------------------------------------------ *)

Options[PowerLogModel] = {Assumptions :> $Assumptions, Direction -> Automatic, "MaxTerms" -> 20000};
SetAttributes[PowerLogModel, HoldAllComplete];
PowerLogModel[args___] := catch[powerLogModelEntry[args]];
powerLogModelEntry[f_, {x_Symbol, x0_}, opts : OptionsPattern[PowerLogModel]] := Module[
   {coord, u, ell = Unique["ell$"], jet, ass = optionAssumptions[PowerLogModel, {opts}],
    body = f, condition, parameterAss, limit = OptionValue[PowerLogModel, {opts}, "MaxTerms"]},
   validateInput[f, limit];
   {body, parameterAss, condition} = splitApproachInput[body, x, ass];
   coord = localCoordinate[x, x0, OptionValue[PowerLogModel, {opts}, Direction]]; u = coord["u"];
   If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], u, parameterAss],
     fail["IncompatibleSourceCondition", "The model condition must hold eventually on the requested real source approach."]];
   jet = exactJet[body /. x -> coord["Substitution"], u, ell, parameterAss, limit];
   If[jet === $Failed, fail["UnsupportedInput", "The expression is not a finite power-log sum in the local variable."]];
   Join[rowsToModel[jet[[1]], u, ell, parameterAss, False], <|"SourceDomain" -> condition, "SourceVariable" -> x|>]];
powerLogModelEntry[f_, x_Symbol, opts : OptionsPattern[PowerLogModel]] := powerLogModelEntry[f, {x, 0}, opts];
powerLogModelEntry[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use PowerLogModel[f,{x,x0}] or PowerLogModel[f,x]."|>];

Options[InverseExpansionCoefficient] = {"Power" -> 1};
InverseExpansionCoefficient[model_Association, k_List, OptionsPattern[]] := catch[Module[
   {r = OptionValue["Power"], c, ass = Lookup[model, "Assumptions", True]},
   If[Length[k] =!= Length[model["Gaps"]] || ! (And @@ (IntegerQ[#] && # >= 0 & /@ k)),
    fail["InvalidMultiIndex", "Give one nonnegative integer per correction block of the model."]];
   c = lagrangeCoefficient[k, model["Gaps"], model["Polynomials"], model["LeadingPower"], r, model["LogVariable"], ass, model["Symbolic"]];
   <|"Weight" -> ToRadicals[c[[1]]], "Exponent" -> ToRadicals[canon[(r + c[[1]])/model["LeadingPower"]]],
     "Coefficient" -> (ToRadicals[c[[2]]] /. model["LogVariable"] -> \[FormalL]),
     "UniformizerExponent" -> ToRadicals[r + c[[1]]], "Assumptions" -> ass,
     "Meaning" -> "(v/a)^Exponent Coefficient[\[FormalL]] with z = (v/a)^(1/p), \[FormalL] = Log[z]"|>]];
InverseExpansionCoefficient[GeneralizedSeries[a_Association], k_List, opts : OptionsPattern[]] :=
  If[Lookup[a, "Kind", None] === "Native",
   Failure["NativeSeriesContract", <|"MessageTemplate" -> "Native results do not supply an inverse coefficient model."|>],
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic",
   Failure["Unsupported", <|"MessageTemplate" -> "Lambert coefficients are listed in the logarithmic expansion's Terms property; they have no power-gap multi-index."|>],
   InverseExpansionCoefficient[Join[a["Model"], <|"Assumptions" -> Lookup[a, "Assumptions", Lookup[a["Model"], "Assumptions", True]]|>],
    k, "Power" -> If[a["ExpansionPoint"] === Infinity || a["ExpansionPoint"] === -Infinity, -a["Power"], a["Power"]], opts]]];
InverseExpansionCoefficient[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use InverseExpansionCoefficient[expansion, {k1, k2, ...}]."|>];

(* The logarithmic-scale engine shares the exact jet algebra above. *)
(* BEGIN SOURCE: src/Kernel/LambertInverse.wl
   Source SHA256 (UTF-8/LF): 58f5b8eaaefac7413cd127a94ec5d613b8774d9d955366c1508700f97fbbb0a4 *)
(* Loaded in AsymptoticAnalysis`Private`.  Inverse-logarithmic expansions of
   real Lambert-W cores.  The finite bracket is an actual power-log jet in
   t = 1/A, with an exact, separately recorded leading prefactor. *)

lambertMonomial[e_, u_, ass_] := Module[{a = 1, p = 0, factors},
  factors = If[Head[e] === Times, List @@ e, {e}];
  Do[Which[
    FreeQ[v, u], a *= v,
    v === u, p++,
    Head[v] === Power && v[[1]] === u && FreeQ[v[[2]], u], p += v[[2]],
    True, Return[$Failed, Module]], {v, factors}];
  If[! exactRealQ[p], Return[$Failed, Module]];
  {Simplify[a, ass], canon[p]}];

lambertLogProduct[e_, u_, ell_, ass_] := Module[
  {a = 1, p = 0, b = 0, c = 0, q = 0, factors, base, power, lb},
  factors = If[Head[e] === Times, List @@ e, {e}];
  Do[Which[
    FreeQ[v, u], a *= v,
    v === u, p++,
    Head[v] === Power && v[[1]] === u && FreeQ[v[[2]], u], p += v[[2]],
    True,
    {base, power} = If[Head[v] === Power, {v[[1]], v[[2]]}, {v, 1}];
    lb = Expand[base /. Log[u] -> ell];
    If[q =!= 0 || ! FreeQ[lb, u] || ! PolynomialQ[lb, ell] || Exponent[lb, ell] =!= 1 || ! exactRealQ[power],
      Return[$Failed, Module]];
    b = Coefficient[lb, ell, 0]; c = Coefficient[lb, ell, 1]; q = power], {v, factors}];
  If[q === 0 || ! exactRealQ[p] || p === 0, Return[$Failed, Module]];
  <|"a" -> Simplify[a, ass], "p" -> canon[p], "b" -> b, "c" -> c, "q" -> canon[q]|>];

lambertLogCore[fu_, u_, ell_, ass_] := Module[{rows, y0 = 0, nonconstant, p, poly, q, a, b, core, parts, v, coefficients},
  rows = parseFinite[fu, u, ell, ass];
  If[rows =!= $Failed && And @@ (exactRealQ[#[[1]]] & /@ rows),
    rows = jetMerge[rows, ell, ass];
    y0 = Total[Cases[rows, {0, cc_} /; FreeQ[cc, ell] :> cc]];
    nonconstant = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
    If[nonconstant === {}, Return[$Failed, Module]];
    {p, poly} = First[nonconstant]; q = Exponent[poly, ell];
    If[p === 0 || ! IntegerQ[q] || q < 1, Return[$Failed, Module]];
    a = Coefficient[poly, ell, q]; b = Simplify[Coefficient[poly, ell, q - 1]/(q a), ass];
    Do[If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[row[[2]], ell]),
      fail["UnprovedRealCoefficient", "All coefficients of a real logarithmic model, including discarded higher-power terms, must be provably real.",
        <|"Polynomial" -> row[[2]]|>]], {row, rows}];
    coefficients = CoefficientList[Expand[v^q (poly /. ell -> -1/v - b)/(a (-1)^q)], v];
    coefficients = coefCanon[#, ass] & /@ coefficients;
    Return[<|"a" -> a, "p" -> p, "b" -> b, "c" -> 1, "q" -> q,
      "LogPolynomial" -> poly, "LogVariable" -> ell, "ResidualCoefficients" -> coefficients,
      "AffinePower" -> And @@ (zeroQ[#, ass] & /@ Rest[coefficients]),
      "Offset" -> y0, "Exact" -> (Length[nonconstant] === 1)|>, Module]];
  parts = If[Head[fu] === Plus, List @@ fu, {fu}];
  y0 = Total[Select[parts, FreeQ[#, u] &]];
  nonconstant = Select[parts, ! FreeQ[#, u] &];
  If[Length[nonconstant] =!= 1, Return[$Failed, Module]];
  core = lambertLogProduct[First[nonconstant], u, ell, ass];
  If[core === $Failed, Return[$Failed, Module]];
  Join[core, <|"Offset" -> y0, "Exact" -> True|>]];

lambertExponentialTerm[e_, x_, ass_] := Module[
  {parts, ef, rest, mono, arg, args, constant, dependent, emono},
  parts = If[Head[e] === Times, List @@ e, {e}];
  ef = Select[parts, Head[#] === Power && #[[1]] === E && ! FreeQ[#[[2]], x] &];
  If[Length[ef] =!= 1, Return[$Failed, Module]];
  rest = Times @@ DeleteCases[parts, First[ef]];
  mono = lambertMonomial[rest, x, ass]; If[mono === $Failed, Return[$Failed, Module]];
  arg = Expand[First[ef][[2]]]; args = If[Head[arg] === Plus, List @@ arg, {arg}];
  constant = Total[Select[args, FreeQ[#, x] &]];
  dependent = Select[args, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  emono = lambertMonomial[First[dependent], x, ass];
  If[emono === $Failed || ! less[0, emono[[2]]], Return[$Failed, Module]];
  <|"a" -> Simplify[mono[[1]] Exp[constant], ass], "b" -> mono[[2]],
    "c" -> emono[[1]], "p" -> emono[[2]]|>];

lambertExponentialCore[f_, x_, ass_] := Module[{parts, y0, dependent, candidates, core, rest, u, ell, rows},
  parts = If[Head[f] === Plus, List @@ f, {f}];
  y0 = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  candidates = Select[dependent, ! FreeQ[#, Power[E, ee_] /; ! FreeQ[ee, x]] &];
  If[Length[candidates] =!= 1, Return[$Failed, Module]];
  core = lambertExponentialTerm[First[candidates], x, ass];
  If[core === $Failed, Return[$Failed, Module]];
  rest = Total[DeleteCases[dependent, First[candidates]]];
  If[rest =!= 0,
    If[! provablyPositive[core["c"], ass], Return[$Failed, Module]];
    rows = parseFinite[rest /. x -> 1/u, u, ell, ass];
    If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
    Do[If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ CoefficientList[row[[2]], ell]),
      fail["UnprovedRealCoefficient", "Discarded power-log perturbations of a real exponential core must have provably real coefficients.",
        <|"Polynomial" -> row[[2]]|>]], {row, rows}]];
  Join[core, <|"Offset" -> y0, "Exact" -> (rest === 0)|>]];

lambertRemainderJet[v_, coefficients_, scale_, cut_, ell_, ass_, limit_] := Module[{ans = {{0, 1}}, part},
  Do[If[less[j, cut] && ! zeroQ[coefficients[[j + 1]], ass],
    part = jetUnitPower[v, -j, cut - j, ell, ass, limit];
    ans = jetAdd[ans, jetScale[jetShift[part, j], coefficients[[j + 1]] scale^j, ell, ass], cut, ell, ass]],
    {j, Length[coefficients] - 1}];
  jetTrim[ans, cut, ell, ass]];

lambertCorrection[sign_, cut_, ell_, ass_, limit_, coefficients_: {1}, scale_: 1, degree_: 1] :=
 Module[{v = {}, next, iterations, extra},
  iterations = Ceiling[cut];
  If[iterations > limit, fail["ResourceLimit", "The logarithmic expansion exceeded MaxTerms.", <|"MaxTerms" -> limit|>]];
  Do[
    extra = jetAdd[lambertRemainderJet[v, coefficients, scale, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
    next = jetAdd[jetUnitLog[v, cut, ell, ass, limit], jetScale[jetUnitLog[extra, cut, ell, ass, limit], 1/degree, ell, ass], cut, ell, ass];
    next = jetScale[jetShift[jetAdd[{{0, -ell}}, next, cut, ell, ass], 1], -sign, ell, ass];
    next = jetTrim[next, cut, ell, ass];
    If[next === v, Break[]]; v = next,
    {iterations}];
  v];

lambertConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal], limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"], method = OptionValue[AsymptoticInverse, {opts}, Method],
   trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"], inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   coord, u, ell = Unique["ell$"], fu, core, kind, a, p, b, c, q, offset, amplitude, amplitudeSign, target,
   positiveTarget, Y, k, s, branch, argument, A, t, relativePower, prefactor, exactLocal, exactX, exactObservable,
   cutoff = cutoff0, work, v, allBlocks, blocks, omitted, beta, degree, terms, expression, remainder,
   domain, targetLimit, leadingCore, perturbation, frontier, pure = False, affineSign, rint,
   coefficients = {1}, polynomialCore = False, remainderJet, closedForm = True},
  core = $Failed;
  If[x0 === Infinity && ! FreeQ[f, Power[E, ee_] /; ! FreeQ[ee, x]],
    core = lambertExponentialCore[f, x, ass]; kind = "Exponential"];
  If[core === $Failed,
    If[FreeQ[f, Log], Return[$Failed, Module]];
    coord = localCoordinate[x, x0, dir]; u = coord["u"];
    fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
    core = lambertLogCore[fu, u, ell, ass]; kind = "PowerLog"];
  If[core === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target variables must be distinct, and the target must not occur in the forward expression."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[! MemberQ[{"Lagrange", "Newton", "Lambert"}, method], fail["InvalidOption", "Method must be Lagrange, Newton, or Lambert."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Lambert cores use exponent truncation in the inverse-logarithmic variable."]];
  If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Lambert cores currently require an explicit expression, without InputRemainder."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive logarithmic cutoff or SeriesTermGoal -> n."]];
    cutoff = goal];
  If[! exactRealQ[cutoff] || ! less[0, cutoff], fail["InvalidCutoff", "A Lambert logarithmic cutoff must be a positive exact real number."]];
  {a, p, b, c} = Lookup[core, {"a", "p", "b", "c"}]; offset = core["Offset"];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ {a, b, c, offset}),
    fail["UnprovedRealCoefficient", "The amplitude, logarithmic shift, exponential coefficient, and target offset must be provably real."]];
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]) ||
     ! (provablyPositive[c, ass] || provablyNegative[c, ass]), Return[$Failed, Module]];
  If[kind === "PowerLog",
    q = core["q"];
    coefficients = Lookup[core, "ResidualCoefficients", {1}];
    polynomialCore = ! TrueQ[Lookup[core, "AffinePower", True]]; closedForm = ! polynomialCore;
    If[provablyPositive[c, ass] && ! IntegerQ[q],
      fail["NonrealLambertCore", "A negative eventual logarithmic base requires an integer power on the real branch."]];
    amplitude = Simplify[a (-c)^q, ass];
    If[! (provablyPositive[amplitude, ass] || provablyNegative[amplitude, ass]), Return[$Failed, Module]];
    amplitudeSign = If[provablyPositive[amplitude, ass], 1, -1];
    target = y - offset; positiveTarget = amplitudeSign target; Y = target/amplitude;
    k = -p/q; s = If[less[0, k], 1, -1]; branch = If[s === 1, 0, -1];
    argument = k Y^(1/q) Exp[p b/(c q)];
    A = s (Log[Abs[k]] + Log[Y]/q + p b/(c q)); t = 1/A;
    rint = If[coord["Infinite"], -r, r];
    relativePower = -q rint/p;
    prefactor = Y^(rint/p) (A/Abs[k])^(-q rint/p);
    exactLocal = Y^(1/p) (ProductLog[branch, argument]/k)^(-q/p);
    affineSign = coord["Sign"];
    If[affineSign === -1 && ! IntegerQ[r], fail["InvalidOption", "Noninteger observable powers require a positive local branch."]];
    exactX = If[coord["Infinite"], affineSign/exactLocal, x0 + affineSign exactLocal];
    exactObservable = If[r === 1, exactX, affineSign^r exactLocal^rint];
    prefactor *= affineSign^r;
    targetLimit = If[less[0, p], offset, amplitudeSign Infinity];
    leadingCore = If[polynomialCore, offset + u^p (core["LogPolynomial"] /. core["LogVariable"] -> Log[u]),
      offset + a u^p (b + c Log[u])^q] /. u -> coord["LocalVariable"],
    coord = localCoordinate[x, x0, dir]; u = coord["u"];
    amplitude = a; amplitudeSign = If[provablyPositive[a, ass], 1, -1];
    target = y - offset; positiveTarget = amplitudeSign target; Y = target/a;
    If[b === 0,
      pure = True; A = If[provablyPositive[c, ass], Log[Y], -Log[Y]]; t = 1/A;
      prefactor = (Log[Y]/c)^(r/p); relativePower = 0; exactX = (Log[Y]/c)^(1/p);
      exactObservable = (Log[Y]/c)^(r/p); s = 0; branch = Missing["Elementary"]; argument = Missing["Elementary"],
      k = c p/b;
      If[! (provablyPositive[k, ass] || provablyNegative[k, ass]), Return[$Failed, Module]];
      s = If[provablyPositive[k, ass], 1, -1]; branch = If[s === 1, 0, -1];
      argument = k Y^(p/b); A = s (Log[Abs[k]] + (p/b) Log[Y]); t = 1/A;
      relativePower = r/p; prefactor = (A/Abs[k])^(r/p);
      exactX = (ProductLog[branch, argument]/k)^(1/p); exactObservable = (ProductLog[branch, argument]/k)^(r/p)];
    targetLimit = If[provablyPositive[c, ass], amplitudeSign Infinity, offset];
    leadingCore = offset + a x^b Exp[c x^p]];
  domain = ass && positiveTarget > 0 && A > 0;
  If[s === -1, domain = domain && argument >= -1/E && argument < 0];
  work = Ceiling[cutoff] + 2;
  If[pure,
    v = {}; allBlocks = {{0, 1}}; blocks = allBlocks;
    beta = If[TrueQ[core["Exact"]], Infinity, cutoff]; degree = 0; frontier = 0,
    v = If[kind === "PowerLog", lambertCorrection[s, work, ell, ass, limit, coefficients, Abs[k], q],
      lambertCorrection[s, work, ell, ass, limit]];
    allBlocks = jetUnitPower[v, relativePower, work, ell, ass, limit];
    If[polynomialCore,
      remainderJet = jetAdd[lambertRemainderJet[v, coefficients, Abs[k], work, ell, ass, limit], {{0, -1}}, work, ell, ass];
      allBlocks = jetMul[allBlocks, jetUnitPower[remainderJet, -rint/p, work, ell, ass, limit], work, ell, ass, limit]];
    blocks = Select[allBlocks, less[#[[1]], cutoff] &];
    omitted = Select[allBlocks, ! less[#[[1]], cutoff] &];
    If[omitted === {}, beta = Ceiling[cutoff]; degree = Ceiling[cutoff],
      beta = omitted[[1, 1]]; degree = polyDegree[omitted[[1, 2]], ell]];
    frontier = If[omitted === {}, Missing["NotComputed"], prefactor t^beta (omitted[[1, 2]] /. ell -> Log[t])]];
  terms = {#[[1]], #[[2]] /. ell -> Log[t]} & /@ blocks;
  expression = prefactor Total[(t^#[[1]] #[[2]]) & /@ terms];
  If[kind === "PowerLog" && r === 1 && ! coord["Infinite"], expression += x0];
  remainder = If[beta === Infinity, 0, Abs[prefactor] PowerLogRemainder[t, beta, degree]];
  perturbation = Simplify[f - leadingCore, ass];
  GeneralizedSeries[<|
    "Kind" -> "Inverse", "Scale" -> "Logarithmic", "Method" -> "Lambert", "RequestedMethod" -> method,
    "Expression" -> expression, "Prefactor" -> prefactor, "Terms" -> terms, "Blocks" -> blocks,
    "TermConvention" -> "Each {n,C} contributes Prefactor t^n C with t=LogarithmicVariable; a finite source endpoint is added when Power is 1. Cutoff bounds n in the normalized bracket.",
    "Remainder" -> remainder, "RemainderPower" -> beta, "RemainderLogDegree" -> degree,
    "RemainderVariable" -> t, "RemainderScaleExpression" -> If[beta === Infinity, 0, Abs[prefactor] t^beta (1 + Abs[Log[t]])^degree],
    "FrontierTerm" -> frontier, "LogarithmicVariable" -> t, "Uniformizer" -> t, "LogVariable" -> ell,
    "LambertSign" -> s, "LambertBranch" -> branch, "LambertArgument" -> argument, "LambertLogMagnitude" -> A,
    "LambertCorrectionBlocks" -> jetTrim[v, cutoff, ell, ass], "LambertUnitPower" -> relativePower,
    "LambertResidualCutoff" -> cutoff, "LambertCoreType" -> kind, "CoreParameters" -> core,
    "LambertPolynomialLog" -> polynomialCore, "LambertResidualCoefficients" -> coefficients,
    "LambertLocalObservablePower" -> If[kind === "PowerLog", rint, r],
    "LambertLogDegree" -> If[kind === "PowerLog", q, 0], "LambertScaleFactor" -> If[pure, 0, Abs[k]],
    "ExactInverseExpression" -> If[TrueQ[core["Exact"]] && closedForm, exactX, Missing["NoClosedFormInverse"]],
    "ExactObservableExpression" -> If[TrueQ[core["Exact"]] && closedForm, exactObservable, Missing["NoClosedFormInverse"]],
    "CoreInverseExpression" -> If[closedForm, exactX, Missing["NoClosedFormInverse"]],
    "CoreObservableExpression" -> If[closedForm, exactObservable, Missing["NoClosedFormInverse"]],
    "LambertSeedExpression" -> exactX,
    "LeadingCore" -> leadingCore, "LeadingCoreOnly" -> ! TrueQ[core["Exact"]], "BeyondLogarithmicOrders" -> perturbation,
    "RemainderExplanation" -> If[TrueQ[core["Exact"]], "Truncation of the analytic logarithmic unit expansion in t and t Log[t].",
      "The omitted higher-power terms change the inverse by less than its prefactor times every fixed power of t; the stated finite-order remainder also covers them."],
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Limit" -> targetLimit, "TargetDomain" -> domain,
    "TargetDomainMeaning" -> "Necessary real coordinate conditions for the selected asymptotic source neighborhood; this is not a global injectivity certificate.",
    "LeadingCoefficient" -> amplitude, "LeadingPower" -> p,
    "Power" -> r, "Cutoff" -> cutoff, "Truncation" -> "Exponent", "Model" -> Missing["LogarithmicScale"],
    "ForwardExpansion" -> leadingCore, "Function" -> f, "Assumptions" -> ass,
    "LocalVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "ExactModel" -> TrueQ[core["Exact"]], "InputRemainder" -> None,
    "Branch" -> Which[pure, "The positive real elementary inverse tending to the source endpoint.",
      polynomialCore, "The asymptotic real inverse normalized about ProductLog branch " <> ToString[branch] <>
        "; lower logarithmic powers are included by the unit equation, and the inverse tends to the source endpoint.",
      True, "The real ProductLog branch " <> ToString[branch] <> " tending to the source endpoint; TargetDomain records necessary real coordinate conditions."],
    "SeriesData" -> Missing["LogarithmicScale"]|>]];

lambertResidual[a_Association, h_, limit_] := Module[
  {cut = If[h === Automatic, a["Cutoff"], h], ell = a["LogVariable"], ass = a["Assumptions"],
   power = a["LambertUnitPower"], sign = a["LambertSign"], t = a["LogarithmicVariable"], unit, v, res,
   localPower, logDegree, p, scale, rjet},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! exactRealQ[cut] || ! less[0, cut], fail["InvalidCutoff", "The logarithmic residual cutoff must be a positive exact real number."]];
  If[power === 0,
    res = {},
    unit = Select[a["Blocks"], less[0, #[[1]]] &];
    If[TrueQ[Lookup[a, "LambertPolynomialLog", False]],
      localPower = a["LambertLocalObservablePower"]; logDegree = a["LambertLogDegree"];
      p = a["LeadingPower"]; scale = a["LambertScaleFactor"];
      (* Recover -Log[u]-b from the returned bracket itself.  This includes
         the polynomial R factor and checks actual source composition. *)
      v = jetShift[jetAdd[{{0, sign ell}}, jetScale[jetUnitLog[unit, cut, ell, ass, limit],
        -scale/localPower, ell, ass], cut, ell, ass], 1];
      rjet = lambertRemainderJet[v, a["LambertResidualCoefficients"], scale, cut, ell, ass, limit];
      res = jetMul[jetUnitPower[unit, p/localPower, cut, ell, ass, limit],
        jetMul[jetUnitPower[v, logDegree, cut, ell, ass, limit], rjet, cut, ell, ass, limit], cut, ell, ass, limit];
      res = jetAdd[res, {{0, -1}}, cut, ell, ass],
      v = jetAdd[jetUnitPower[unit, 1/power, cut, ell, ass, limit], {{0, -1}}, cut, ell, ass];
      res = jetAdd[v, jetScale[jetShift[jetAdd[{{0, -ell}}, jetUnitLog[v, cut, ell, ass, limit],
        cut, ell, ass], 1], sign, ell, ass], cut, ell, ass]]];
  <|"ZeroBelowCutoff" -> (res === {}),
    "NormalizedResidual" -> Total[(t^#[[1]] (#[[2]] /. ell -> Log[t])) & /@ res],
    "ResidualBlocks" -> res, "RelativeCutoff" -> cut,
    "Normalization" -> Which[power === 0, "The elementary exponential core is inverted exactly.",
      TrueQ[Lookup[a, "LambertPolynomialLog", False]], "(f_core(g)-offset)/(y-offset)-1, composed through the logarithm of the returned observable bracket.",
      True, "V + s t (-Log[t] + Log[1+V]); V is reconstructed from the returned truncated observable bracket."],
    "Scope" -> Which[TrueQ[a["LeadingCoreOnly"]],
      "Formal residual of the logarithmic leading core; higher-power perturbations are beyond every inverse-logarithmic order.",
      TrueQ[Lookup[a, "LambertPolynomialLog", False]], "Formal composition with the complete leading polynomial in the logarithm, in the inverse-logarithmic variable.",
      True, "Formal residual of the exact Lambert core in the inverse-logarithmic variable."]|>];
(* END SOURCE: src/Kernel/LambertInverse.wl *)

(* BEGIN SOURCE: src/Kernel/CoordinateInverse.wl
   Source SHA256 (UTF-8/LF): db983454b4c6ab9c5ed0bf3c389ce482adc6adecefbd9cc3f8ac608d074b7a1c *)
(* Exact changes of coordinates around the existing inverse engines.
   Loaded inside AsymptoticAnalysis`Private`. *)

coordinateExponentialPhase[f_, x_, x0_, dir_, ass_, limit_] := Module[
  {coord, u, ell = Unique["ell$"], parts, offset, dependent, factors, exponentials,
   exponent, amplitude, jet, coefficient, degree, sign, phase, argumentJet, scale},
  If[FreeQ[f, Power[_, e_] /; ! FreeQ[e, x]], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  factors = If[Head[First[dependent]] === Times, List @@ First[dependent], dependent];
  exponentials = Select[factors, MatchQ[#, Power[_, e_] /; ! FreeQ[e, x]] &];
  If[exponentials === {}, Return[$Failed, Module]];
  exponent = Total[If[#[[1]] === E, #[[2]], #[[2]] Log[#[[1]]]] & /@ exponentials];
  amplitude = Times @@ Select[factors, ! MemberQ[exponentials, #] &];
  argumentJet = catch[forwardJet[exponent /. x -> coord["Substitution"], u, ell, ass, 1, limit]];
  If[FailureQ[argumentJet] || argumentJet[[1]] === {} || ! less[argumentJet[[1, 1, 1]], 0],
    Return[$Failed, Module]];
  jet = forwardJet[amplitude /. x -> coord["Substitution"], u, ell, ass, 1, limit];
  If[jet[[1]] === {}, Return[$Failed, Module]];
  degree = polyDegree[jet[[1, 1, 2]], ell];
  coefficient = (-1)^degree Coefficient[jet[[1, 1, 2]], ell, degree];
  sign = Which[provablyPositive[coefficient, ass], 1, provablyNegative[coefficient, ass], -1,
    True, fail["UnprovedSign", "The exponential amplitude must have a provable eventual real sign."]];
  scale = Simplify[Abs[Times @@ Select[If[Head[amplitude] === Times, List @@ amplitude, {amplitude}], FreeQ[#, x] &]], ass];
  If[! TrueQ[Simplify[Element[offset, Reals], ass]],
    fail["UnprovedRealCoefficient", "The target offset must be provably real."]];
  phase = exponent + Log[sign amplitude/scale];
  <|"Phase" -> phase, "AmplitudeSign" -> sign, "AmplitudeScale" -> scale, "Offset" -> offset,
    "Coordinate" -> coord, "PositiveAmplitude" -> sign amplitude|>];

coordinateConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   data, target = Unique["phaseTarget$"], targetExpression, base, a, sub, domain, targetLimit},
  data = coordinateExponentialPhase[f, x, x0, dir, ass, limit];
  If[data === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target symbols must be distinct, and the target must not occur in the input."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[! MemberQ[{Automatic, None}, inputRem],
    fail["UnsupportedOption", "An additive input remainder must be transported through the logarithmic target coordinate before inversion."]];
  targetExpression = Log[data["AmplitudeSign"] (y - data["Offset"])/data["AmplitudeScale"]];
  base = inverseDispatch[data["Phase"], x, x0, target, cutoff, Sequence @@ withAssumptions[{opts}, ass]];
  If[FailureQ[base], Return[base, Module]];
  sub = target -> targetExpression;
  a = base[[1]] /. sub;
  (* The source positivity is an eventual hypothesis, not a target predicate. *)
  domain = data["AmplitudeSign"] (y - data["Offset"]) > 0 &&
    If[KeyExistsQ[base[[1]], "TargetDomain"], base["TargetDomain"] /. sub,
      If[MemberQ[{Infinity, -Infinity}, base["Limit"]], targetExpression, targetExpression - base["Limit"]]/base["LeadingCoefficient"] > 0];
  targetLimit = Which[base["Limit"] === Infinity, data["AmplitudeSign"] Infinity,
    base["Limit"] === -Infinity, data["Offset"], True, data["Offset"] + data["AmplitudeSign"] data["AmplitudeScale"] Exp[base["Limit"]]];
  GeneralizedSeries[Join[a, <|"Scale" -> "Transformed", "CoordinateKind" -> "TargetLog",
    "CoordinateSeries" -> base, "CoordinateSubstitution" -> {sub},
    "TargetCoordinateExpression" -> targetExpression, "TransformedFunction" -> data["Phase"],
    "SourceDomain" -> data["PositiveAmplitude"] > 0,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "Limit" -> targetLimit,
    "TargetDomain" -> domain, "RemainderScaleExpression" -> (a["Remainder"] /. q_PowerLogRemainder :> remainderScale[q]),
    "SeriesData" -> Missing["TransformedCoordinate"],
    "TermConvention" -> "Terms and cutoff use the underlying inverse coordinate, composed with TargetCoordinateExpression; CoordinateSeries records that convention.",
    "Transformations" -> {<|"Type" -> "TargetLog", "Expression" -> targetExpression,
      "InverseMap" -> data["Offset"] + data["AmplitudeSign"] data["AmplitudeScale"] Exp[target]|>}|>]]];

coordinateResidual[a_, h_, limit_] := Module[{result},
  If[MemberQ[{"SourceExp", "SourceLog"}, Lookup[a, "CoordinateKind", ""]],
    Return[sourceCoordinateResidual[a, h, limit], Module]];
  result = residual[a["CoordinateSeries"][[1]], h, limit] /. a["CoordinateSubstitution"];
  Join[result, <|"TargetCoordinate" -> a["TargetCoordinateExpression"],
    "Scope" -> "Formal composition with the transformed forward model in the logarithmic target coordinate.",
    "OriginalFunction" -> a["Function"]|>]];

coordinateNumericalCheck[a_, yv_, wp_] := Module[
  {x = a["Variables"][[1]], y = a["Variable"], yy, approx, seed, xr, local,
   base = a["CoordinateSeries"], phase, target, r = a["Power"], observed, err, scale, z},
  If[MemberQ[{"SourceExp", "SourceLog"}, Lookup[a, "CoordinateKind", ""]],
    Return[sourceCoordinateNumericalCheck[a, yv, wp], Module]];
  If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[yv] || (! exactQ[yv] && Precision[yv] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  yy = yv;
  If[! TrueQ[N[a["TargetDomain"] /. y -> yy, wp + 10]], fail["OutsideBranch", "The target is outside the transformed real branch domain."]];
  approx = N[a["Expression"] /. y -> yy, wp + 10];
  seed = If[r === 1, approx,
    With[{side = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
        a["Direction"] === "FromBelow", -1, True, 1]},
      If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], 0, a["ExpansionPoint"]] + side Abs[approx]^(1/r)]];
  phase = a["TransformedFunction"]; target = N[a["TargetCoordinateExpression"] /. y -> yy, wp + 10];
  xr = With[{xx = x, ff = phase, tt = target, start = seed, prec = wp + 10, goal = wp},
    Quiet[Check[xx /. FindRoot[ff == tt, {xx, start}, WorkingPrecision -> prec,
      AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[xr === $Failed || ! NumericQ[xr], fail["RootNotFound", "The transformed equation did not converge from the asymptotic seed."]];
  local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
  If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The numerical root is outside the selected source branch."]];
  observed = Which[r === 1, xr, MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], xr^r,
    True, (xr - a["ExpansionPoint"])^r];
  err = N[Abs[observed - approx], wp]; scale = N[a["RemainderScaleExpression"] /. y -> yy, wp];
  <|"ReferenceRoot" -> N[xr, wp], "ExactInverse" -> N[xr, wp], "ReferenceObservable" -> N[observed, wp],
    "Approximation" -> N[approx, wp], "Error" -> err, "RemainderScale" -> scale,
    "Ratio" -> If[TrueQ[scale == 0], Indeterminate, err/scale],
    "PhaseResidual" -> N[(phase /. x -> xr) - target, wp],
    "Evidence" -> "High-precision numerical comparison; no interval certificate."|>];
(* END SOURCE: src/Kernel/CoordinateInverse.wl *)

(* BEGIN SOURCE: src/Kernel/IncrementalInverse.wl
   Source SHA256 (UTF-8/LF): a410833cc04cfb857eeafe07072e39846e9df4bbb68089c870810b4e973c6e00 *)
(* Incremental exact-weight inversion helpers. Loaded in the package's Private
   context. State is returned by value; no process-global coefficient cache is
   retained, and a failed refinement does not alter its input state. *)

incrementalIndexKey[k_List] := ToString[k, InputForm];

incrementalInverseState[d_List, polys_List, p_, r_, ell_, ass_, limit_] := Module[{zero},
  zero = ConstantArray[0, Length[d]];
  <|"Gaps" -> d, "Polynomials" -> polys, "LeadingPower" -> p, "Power" -> r,
    "LogVariable" -> ell, "Assumptions" -> ass, "MaxTerms" -> limit,
    "Inside" -> {}, "Boundary" -> <|incrementalIndexKey[zero] -> {0, zero}|>,
    "Blocks" -> {}, "LastWeight" -> -Infinity, "NextWeight" -> 0,
    "CoefficientEvaluations" -> 0, "Layers" -> 0,
    "PolynomialPowerCache" -> ({1, #} & /@ polys),
    "PolynomialPowerCacheEntries" -> 0, "PolynomialPowerCacheCapacity" -> Max[0, limit - 1],
    "PolynomialPowerRequests" -> 0, "PolynomialPowerCacheHits" -> 0,
    "PolynomialPowerEvaluations" -> 0, "PolynomialPowerCacheEvictions" -> 0|>];

(* Only powers >=2 of nonconstant logarithmic polynomials occupy cache slots.
   Powers 0 and 1 merely refer to 1 and the already stored model coefficient.
   The optional cache uses spare index-budget slots and is trimmed before a
   larger frontier is admitted, so it cannot reduce the usable index region. *)
incrementalResizePolynomialCache[state_Association] := Module[
  {s = state, cache, capacity, entries, lengths, position, evictions = 0},
  cache = Lookup[s, "PolynomialPowerCache", ({1, #} & /@ s["Polynomials"])];
  capacity = Max[0, s["MaxTerms"] - Length[s["Inside"]] - Length[s["Boundary"]]];
  entries = Total[Length /@ cache] - 2 Length[cache];
  While[entries > capacity,
    lengths = Length /@ cache; position = First[FirstPosition[lengths, Max[lengths]]];
    cache[[position]] = Most[cache[[position]]]; entries--; evictions++];
  Join[s, <|"PolynomialPowerCache" -> cache, "PolynomialPowerCacheEntries" -> entries,
    "PolynomialPowerCacheCapacity" -> capacity,
    "PolynomialPowerRequests" -> Lookup[s, "PolynomialPowerRequests", 0],
    "PolynomialPowerCacheHits" -> Lookup[s, "PolynomialPowerCacheHits", 0],
    "PolynomialPowerEvaluations" -> Lookup[s, "PolynomialPowerEvaluations", 0],
    "PolynomialPowerCacheEvictions" -> Lookup[s, "PolynomialPowerCacheEvictions", 0] + evictions|>]];

incrementalPolynomialProduct[state_Association, k_List] := Module[
  {s = state, cache = state["PolynomialPowerCache"], polys = state["Polynomials"], ell = state["LogVariable"],
   entries = state["PolynomialPowerCacheEntries"], capacity = state["PolynomialPowerCacheCapacity"],
   requests = 0, hits = 0, evaluations = 0, factors, power, value, available, missing, j},
  factors = Table[power = k[[j]];
    If[power < 2 || FreeQ[polys[[j]], ell], polys[[j]]^power,
      requests++; available = Length[cache[[j]]] - 1;
      If[power <= available, hits++; cache[[j, power + 1]],
        While[available < power && entries < capacity,
          value = Expand[Last[cache[[j]]] polys[[j]]]; evaluations++;
          cache[[j]] = Append[cache[[j]], value]; available++; entries++];
        If[available === power, Last[cache[[j]]],
          (* A full cache is a performance condition, never an input failure. *)
          evaluations++; Expand[Last[cache[[j]]] polys[[j]]^(power - available)]]]],
    {j, Length[k]}];
  s = Join[s, <|"PolynomialPowerCache" -> cache, "PolynomialPowerCacheEntries" -> entries,
    "PolynomialPowerRequests" -> state["PolynomialPowerRequests"] + requests,
    "PolynomialPowerCacheHits" -> state["PolynomialPowerCacheHits"] + hits,
    "PolynomialPowerEvaluations" -> state["PolynomialPowerEvaluations"] + evaluations|>];
  {s, Expand[Times @@ factors]}];

(* Apply the Euler coefficient formula to a product supplied by the cache.
   lagrangeCoefficient remains the independent uncached reference route. *)
incrementalCoefficientFromProduct[k_, d_, p_, r_, ell_, ass_, product_] := Module[{n = Total[k], weight, q = product},
  If[n === 0, Return[{0, 1}, Module]];
  weight = canon[k . d];
  Do[q = Expand[D[q, ell] + (r + weight + p j) q], {j, 1, n - 1}];
  {weight, polyCanon[Expand[(-1)^n r q/(p^n (Times @@ (Factorial /@ k)))], ell, ass]}];

incrementalInverseRegion[state_Association] :=
  <|"Inside" -> state["Inside"], "Boundary" -> (Last /@ Values[state["Boundary"]])|>;

advanceInverseState[state_Association] := Module[
  {s = state, boundary, weight, layer, keys, inside, additions, d, ell, ass, limit,
   index, neighbor, key, nextWeight, coefficients, product},
  boundary = state["Boundary"];
  If[Length[boundary] == 0, Return[state, Module]];
  d = state["Gaps"]; ell = state["LogVariable"]; ass = state["Assumptions"];
  limit = state["MaxTerms"]; weight = state["NextWeight"];
  (* Positive gaps imply that every predecessor of an index of this weight has
     already been retained. All collisions are therefore present in this layer. *)
  layer = Select[Values[boundary], equal[First[#], weight] &];
  keys = incrementalIndexKey[Last[#]] & /@ layer;
  boundary = KeyDrop[boundary, keys];
  additions = Last /@ layer;
  inside = Join[state["Inside"], additions];
  Do[
   index = item[[2]];
   Do[
    neighbor = ReplacePart[index, j -> index[[j]] + 1];
    key = incrementalIndexKey[neighbor];
    If[! KeyExistsQ[boundary, key],
     AssociateTo[boundary, key -> {canon[weight + d[[j]]], neighbor}];
     If[Length[inside] + Length[boundary] > limit,
      fail["ResourceLimit", "Incremental multi-index enumeration exceeded MaxTerms.",
       <|"MaxTerms" -> limit|>]]],
    {j, Length[d]}],
   {item, layer}];
  If[Length[inside] + Length[boundary] > limit,
   fail["ResourceLimit", "Incremental multi-index enumeration exceeded MaxTerms.",
    <|"MaxTerms" -> limit|>]];
  s = incrementalResizePolynomialCache[Join[s, <|"Inside" -> inside, "Boundary" -> boundary|>]];
  coefficients = Table[
    {s, product} = incrementalPolynomialProduct[s, index];
    incrementalCoefficientFromProduct[index, d, state["LeadingPower"], state["Power"], ell, ass, product],
    {index, additions}];
  nextWeight = If[Length[boundary] == 0, Infinity,
    First[Sort[First /@ Values[boundary], leq]]];
  AssociateTo[s, {"Inside" -> inside, "Boundary" -> boundary,
    "Blocks" -> Join[state["Blocks"], jetMerge[coefficients, ell, ass]],
    "LastWeight" -> weight, "NextWeight" -> nextWeight,
    "CoefficientEvaluations" -> state["CoefficientEvaluations"] + Length[additions],
    "Layers" -> state["Layers"] + 1}];
  s];

(* Newton states certify correctness strictly below Precision. The initial
   zero jet is correct below the least gap, even when that weight cancels. *)
newtonInverseState[d_List, polys_List, p_, ell_, ass_, limit_] :=
  <|"Gaps" -> d, "Polynomials" -> polys, "LeadingPower" -> p,
    "LogVariable" -> ell, "Assumptions" -> ass, "MaxTerms" -> limit,
    "UnitJet" -> {}, "Precision" -> If[d === {}, Infinity, First[Sort[d, leq]]],
    "StepCutoffs" -> {}|>;

refineNewtonState[state_Association, cut_] := Module[
  {s = state, precision = state["Precision"], U = state["UnitJet"], d, polys,
   p, ell, ass, limit, work, residual, derivative, check, steps},
  If[leq[cut, precision], Return[state, Module]];
  If[cut === Infinity,
   fail["InvalidCutoff", "Newton refinement requires a finite exact cutoff for a nontrivial model."]];
  d = state["Gaps"]; polys = state["Polynomials"]; p = state["LeadingPower"];
  ell = state["LogVariable"]; ass = state["Assumptions"]; limit = state["MaxTerms"];
  steps = state["StepCutoffs"];
  While[less[precision, cut],
   work = minOf[canon[2 precision], cut];
   residual = modelEquation[U, d, polys, p, work, ell, ass, limit];
   If[residual =!= {},
    derivative = modelEquationDerivative[U, d, polys, p, work, ell, ass, limit];
    U = jetAdd[U,
      jetScale[jetMul[residual,
        jetReciprocalUnit[derivative, work, ell, ass, limit],
        work, ell, ass, limit], -1, ell, ass], work, ell, ass];
   (* This is an exact symbolic residual check, not a floating-point stopping
      criterion. It also catches a broken precision invariant in reused states. *)
    check = modelEquation[U, d, polys, p, work, ell, ass, limit];
    If[check =!= {}, fail["NewtonFailure", "Newton refinement left a residual below its claimed precision.",
      <|"Cutoff" -> work, "Residual" -> check|>]]];
   precision = work; AppendTo[steps, work]];
  AssociateTo[s, {"UnitJet" -> U, "Precision" -> precision, "StepCutoffs" -> steps}];
  s];

newtonSolveDoubling[d_List, polys_List, p_, cut_, ell_, ass_, limit_] := Module[{state},
  state = refineNewtonState[newtonInverseState[d, polys, p, ell, ass, limit], cut];
  jetTrim[state["UnitJet"], cut, ell, ass]];

(* If H(z,L)^n = Sum[z^w A[n,w](L)], the multinomial factor in A[n,w]
   replaces the individual k! denominator by n!. At fixed (n,w), all Euler
   operators are identical, so combine before differentiating. *)
groupedLagrangeBlocks[d_List, polys_List, p_, r_, cut_, ell_, ass_, limit_] := Module[
  {perturbation, powers = {{0, 1}}, result, n = 0, rows, q, weight},
  If[! less[0, cut], Return[{}, Module]];
  result = {{0, 1}};
  If[d === {}, Return[result, Module]];
  If[cut === Infinity,
   fail["InvalidCutoff", "Grouped Lagrange inversion requires a finite cutoff for a nontrivial model."]];
  perturbation = jetTrim[Transpose[{d, polys}], cut, ell, ass];
  While[powers =!= {} && perturbation =!= {},
   powers = jetMul[powers, perturbation, cut, ell, ass, limit];
   If[powers === {}, Break[]];
   n++;
   If[n > limit, fail["ResourceLimit", "Grouped Lagrange inversion exceeded MaxTerms.",
     <|"MaxTerms" -> limit|>]];
   rows = Table[
     weight = term[[1]]; q = term[[2]];
     Do[q = Expand[D[q, ell] + (r + weight + p j) q], {j, 1, n - 1}];
     {weight, polyCanon[(-1)^n r q/(p^n n!), ell, ass]},
     {term, powers}];
   result = jetAdd[result, rows, cut, ell, ass]];
  result];
(* END SOURCE: src/Kernel/IncrementalInverse.wl *)

(* BEGIN SOURCE: src/Kernel/SeriesOperations.wl
   Source SHA256 (UTF-8/LF): 9256520b4e979cab89989428b57e27ac8f7fe8aacab9c46861c7894cf8b889b4 *)
(* Explicit calculus for expansions.  A representation means
   Offset + Prefactor (Jet + remainder), in the positive ScaleVariable.
   The prefactor is exact; the jet precision is relative to that prefactor. *)

Scan[(Options[#] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000}) &,
  {AsymptoticAnalysis`SeriesAdd, AsymptoticAnalysis`SeriesMultiply,
   AsymptoticAnalysis`SeriesPower, AsymptoticAnalysis`SeriesLog,
   AsymptoticAnalysis`SeriesExp, AsymptoticAnalysis`SeriesCompose,
   AsymptoticAnalysis`SeriesObservable}];
Options[AsymptoticAnalysis`SeriesTruncate] = {"MaxTerms" -> 20000};
Options[AsymptoticAnalysis`SeriesRefine] = {"MaxTerms" -> 20000, "MaxRefinements" -> 128};
Options[AsymptoticAnalysis`SeriesDifferentiate] = {
  "Cutoff" -> Automatic, "MaxTerms" -> 20000,
  "RemainderDerivativeOrder" -> Automatic};

seriesAss[d_] := d["Assumptions"] && Lookup[d, "Domain", True] && d["ScaleVariable"] > 0;
seriesJetExpression[j_, w_, ell_] := Total[(w^#[[1]] (#[[2]] /. ell -> Log[w])) & /@ j[[1]]];
seriesBound[a_Association] := Lookup[a, "RemainderScaleExpression",
  a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]];

seriesTrim[j : {rows_, p_, deg_}, h_, ell_, ass_] := Module[{omitted, pd = {p, deg}},
  If[h === Infinity, Return[j, Module]];
  omitted = Select[rows, ! less[#[[1]], h] &];
  If[omitted =!= {}, pd = combinePrecision[pd, {omitted[[1, 1]], polyDegree[omitted[[1, 2]], ell]}]];
  {jetTrim[rows, minOf[h, pd[[1]]], ell, ass], pd[[1]], pd[[2]]}];

seriesWorkingCut[d_, requested_] := Module[{h = requested, p = d["Jet"][[2]], rows = d["Jet"][[1]]},
  If[h === Automatic, h = Lookup[d, "Cutoff", Automatic]];
  If[h === Automatic || h === Infinity,
    h = If[p =!= Infinity, p, If[rows === {}, 1, Max[1, Last[rows][[1]] + 1]]]];
  If[! exactRealQ[h], fail["InvalidCutoff", "A series operation cutoff must be an exact real number."]]; h];

seriesData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {d, base, rules, ell, w, j, var, off = 0, pref = 1, u, rows, coord},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  (* Missing native order metadata must not become an infinite-precision jet. *)
  requireAnalyticSeries[s];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]],
    fail["UnsupportedScale", "This operation requires polynomial logarithmic coefficients. The Gamma/Barnes inverse scales support SeriesTruncate, SeriesRefine, SeriesPower, inverse checks, and the constructor's Power observable."]];
  If[AssociationQ[Lookup[a, "SeriesRepresentation", None]], Return[a["SeriesRepresentation"], Module]];
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _GeneralizedSeries],
    base = seriesData[a["CoordinateSeries"], limit]; rules = Lookup[a, "CoordinateSubstitution", {}];
    d = base /. rules; Return[Join[d, <|"Variable" -> a["Variable"],
      "Domain" -> Lookup[a, "TargetDomain", Lookup[d, "Domain", True]]|>], Module]];
  If[Lookup[a, "Truncation", "Exponent"] === "Depth",
    fail["UnsupportedScale", "Series calculus requires a provably ordered exponent scale; refine a depth expansion with parameter values first."]];
  var = a["Variable"]; ell = Unique["ell$"]; w = Lookup[a, "RemainderVariable", Missing["Scale"]];
  If[MissingQ[w], fail["UnsupportedScale", "This result has no single power-log scale."]];
  If[Lookup[a, "Scale", "PowerLog"] === "Logarithmic",
    pref = a["Prefactor"];
    If[Lookup[a, "LambertCoreType", ""] === "PowerLog" && Lookup[a, "Power", 1] === 1 &&
       ! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], off = a["ExpansionPoint"]];
    rows = a["Blocks"] /. a["LogVariable"] -> ell,
    If[Lookup[a, "Kind", ""] === "Forward", rows = a["Blocks"] /. a["LogVariable"] -> ell,
      d = <|"Variable" -> var, "ScaleVariable" -> w, "LogVariable" -> ell,
        "Assumptions" -> Lookup[a, "Assumptions", True], "Domain" -> Lookup[a, "TargetDomain", True]|>;
      j = seriesExpressionJet[a["Expression"], d, limit];
      If[j === $Failed, fail["UnsupportedScale", "The finite expression could not be expressed in its recorded power-log coordinate."]];
      rows = j[[1]]]];
  <|"Variable" -> var, "ScaleVariable" -> w, "LogVariable" -> ell,
    "Prefactor" -> pref, "Offset" -> off,
    "Jet" -> {rows, Lookup[a, "RemainderPower", Infinity], Lookup[a, "RemainderLogDegree", 0]},
    "Assumptions" -> Lookup[a, "Assumptions", True], "Domain" -> Lookup[a, "TargetDomain", True],
    "Cutoff" -> Lookup[a, "Cutoff", Automatic],
    "RemainderDerivativeOrder" -> Which[a["Remainder"] === 0, Infinity,
      Lookup[a, "Kind", ""] === "Forward" && MatchQ[Lookup[a, "Precision", None], {Infinity, _}], Infinity,
      True, Lookup[a, "RemainderDerivativeOrder", 0]]|>];

(* Only invert the explicitly recorded coordinate. No inversion of the unknown
   function represented by the expansion is attempted here. *)
seriesCoordinateRule[d_, u_] := Module[{w = d["ScaleVariable"], x = d["Variable"], offset, sol},
  If[w === x, Return[x -> u, Module]];
  If[w === 1/x, Return[x -> 1/u, Module]];
  If[w === -1/x, Return[x -> -1/u, Module]];
  (* Standard charts have exact real offsets. Leave parameter-dependent
     and other coordinates to the real solver's existing branch checks. *)
  offset = w - x;
  If[FreeQ[offset, x] && exactRealQ[offset], Return[x -> u - offset, Module]];
  offset = w + x;
  If[FreeQ[offset, x] && exactRealQ[offset], Return[x -> offset - u, Module]];
  sol = Quiet[TimeConstrained[Solve[w == u, x, Reals], 3, $Failed]];
  If[! ListQ[sol] || Length[sol] =!= 1 || ! MatchQ[First[sol], {_Rule}], Return[$Failed, Module]];
  First[First[sol]]];

seriesExpressionJet[e_, d_, limit_] := Module[{u = Unique["w$"], rule, q, probe, ass = seriesAss[d], ell = d["LogVariable"]},
  If[FreeQ[e, d["Variable"]], Return[pConst[e, ell, ass], Module]];
  rule = seriesCoordinateRule[d, u]; If[rule === $Failed, Return[$Failed, Module]];
  q = Simplify[e /. rule, (ass /. rule) && u > 0];
  probe = catch[exactJet[q, u, ell, ass /. rule, limit]];
  If[FailureQ[probe],
    If[MatchQ[probe, Failure["ResourceLimit", _Association]], Throw[probe, $tag], $Failed], probe]];

seriesFlat[d_, limit_] := Module[{p, b, j, ass = seriesAss[d], ell = d["LogVariable"]},
  If[d["Prefactor"] === 1 && d["Offset"] === 0, Return[d, Module]];
  p = seriesExpressionJet[d["Prefactor"], d, limit];
  b = seriesExpressionJet[d["Offset"], d, limit];
  If[p === $Failed || b === $Failed, Return[$Failed, Module]];
  j = pAdd[pMul[p, d["Jet"], ell, ass, limit], b, ell, ass];
  Join[d, <|"Prefactor" -> 1, "Offset" -> 0, "Jet" -> j|>]];

seriesMake[d0_, recipe_, cutoff_: Automatic] := Module[{d = d0, j, w, ell, p, off, expr, rem, terms},
  {j, w, ell, p, off} = Lookup[d, {"Jet", "ScaleVariable", "LogVariable", "Prefactor", "Offset"}];
  j = {realCoefficientRows[j[[1]], ell, seriesAss[d]], j[[2]], j[[3]]};
  If[cutoff =!= Automatic, j = seriesTrim[j, cutoff, ell, seriesAss[d]]];
  If[j[[1]] === {} && j[[2]] === Infinity, p = 1];
  d = Join[d, <|"Jet" -> j, "Prefactor" -> p, "Cutoff" -> cutoff,
    "RemainderDerivativeOrder" -> If[j[[2]] === Infinity, Infinity, Lookup[d, "RemainderDerivativeOrder", 0]]|>];
  expr = off + p seriesJetExpression[j, w, ell];
  rem = If[j[[2]] === Infinity, 0, Abs[p] PowerLogRemainder[w, j[[2]], j[[3]]]];
  terms = {#[[1]], #[[2]] /. ell -> Log[w]} & /@ j[[1]];
  GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> If[p === 1, "PowerLog", "Factored"],
    "Expression" -> expr, "Remainder" -> rem,
    "RemainderScaleExpression" -> If[rem === 0, 0, Abs[p] w^j[[2]] (1 + Abs[Log[w]])^j[[3]]],
    "RemainderPower" -> j[[2]], "RemainderLogDegree" -> j[[3]], "RemainderVariable" -> w,
    "Prefactor" -> p, "Offset" -> off, "Blocks" -> j[[1]], "Terms" -> terms,
    "TermConvention" -> "Offset + Prefactor Sum[w^beta C[Log[w]]]; the cutoff applies inside the prefactor.",
    "LogVariable" -> ell, "Variable" -> d["Variable"], "Assumptions" -> d["Assumptions"],
    "TargetDomain" -> Lookup[d, "Domain", True], "Cutoff" -> cutoff,
    "Exact" -> (rem === 0), "RemainderDerivativeOrder" -> Lookup[d, "RemainderDerivativeOrder", 0],
    "SeriesRepresentation" -> d, "SeriesRecipe" -> recipe,
    "SeriesData" -> Missing["ExplicitCalculus"]|>]];

seriesCompatible[a_, b_] := Module[{ass = seriesAss[a] && seriesAss[b]},
  If[TrueQ[Simplify[Not[ass]]], fail["IncompatibleDomains", "The operands have conflicting branch domains."]];
  If[a["Variable"] =!= b["Variable"] ||
    ! TrueQ[Simplify[a["ScaleVariable"] == b["ScaleVariable"], ass]],
    fail["IncompatibleScales", "The operands must use the same variable and positive asymptotic coordinate."]]];

seriesAlign[a_, b_] := Join[b /. b["LogVariable"] -> a["LogVariable"],
  <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True]|>];

seriesBinary[op_, s_, t_, cut_, limit_] := Module[{a, b, af, bf, ratio, j, ell, ass, d, h, order},
  a = seriesData[s, limit]; b = seriesData[t, limit]; seriesCompatible[a, b]; b = seriesAlign[a, b];
  ell = a["LogVariable"]; ass = seriesAss[a] && seriesAss[b];
  order = Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]];
  af = seriesFlat[a, limit]; bf = seriesFlat[b, limit];
  If[af =!= $Failed && bf =!= $Failed, a = af; b = bf];
  If[op === "Add",
    ratio = seriesExpressionJet[Simplify[b["Prefactor"]/a["Prefactor"], ass], a, limit];
    If[ratio === $Failed, fail["IncompatibleCarriers", "Addition needs a power-log ratio of the exact prefactors; independent exponential sectors require separate truncation."]];
    j = pAdd[a["Jet"], pMul[ratio, b["Jet"], ell, ass, limit], ell, ass];
    d = Join[a, <|"Jet" -> j, "Offset" -> a["Offset"] + b["Offset"]|>],
    If[a["Offset"] =!= 0 || b["Offset"] =!= 0,
      fail["IncompatibleCarriers", "Multiplication of translated, non-power-log carriers requires explicit sector decomposition."]];
    j = pMul[a["Jet"], b["Jet"], ell, ass, limit];
    d = Join[a, <|"Jet" -> j, "Prefactor" -> a["Prefactor"] b["Prefactor"]|>]];
  d = Join[d, <|"Assumptions" -> a["Assumptions"] && b["Assumptions"],
    "Domain" -> Lookup[a, "Domain", True] && Lookup[b, "Domain", True], "RemainderDerivativeOrder" -> order|>];
  h = If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]];
  seriesMake[d, {op, {s, t}}, h]];

AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, t_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesMultiply[s_GeneralizedSeries, t_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, t, OptionValue["Cutoff"], OptionValue["MaxTerms"]];

seriesConstant[c_, s_, limit_] := Module[{d = seriesData[s, limit]},
  If[! FreeQ[c, d["Variable"]], fail["InvalidConstant", "The scalar must be independent of the expansion variable."]];
  validateInput[c, limit];
  If[! TrueQ[Simplify[Element[c, Reals], seriesAss[d]]], fail["UnprovedRealCoefficient", "The scalar must be provably real under the series assumptions."]];
  seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> 1,
    "Jet" -> pConst[c, d["LogVariable"], seriesAss[d]], "RemainderDerivativeOrder" -> Infinity|>], {"Constant", {s}, c}]];
AsymptoticAnalysis`SeriesAdd[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Add", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesAdd[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`SeriesAdd[s, c, opts];
AsymptoticAnalysis`SeriesMultiply[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], opts : OptionsPattern[]] :=
  seriesArithmeticPublicBinary["Multiply", s, c, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesMultiply[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`SeriesMultiply[s, c, opts];

seriesPower[s_, r_, cut_, limit_, truncate_: True] := Module[{d, flat, ell, ass, h, j, alpha},
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[s[[1]], "Kind", ""]],
    Return[gammaInverseSeriesPower[s, r, cut, limit], Module]];
  If[! exactRealQ[r], fail["InvalidPower", "The power must be an exact real number."]];
  d = seriesData[s, limit]; flat = seriesFlat[d, limit]; If[flat =!= $Failed, d = flat];
  If[d["Offset"] =!= 0, fail["UnsupportedScale", "First separate the finite offset from this non-power-log carrier."]];
  If[r === 0 && d["Jet"][[1]] === {}, fail["IndeterminatePower", "A zeroth power requires a known nonzero leading term."]];
  If[! IntegerQ[r] && d["Jet"][[1]] === {} && d["Jet"][[2]] =!= Infinity,
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  alpha = If[d["Jet"][[1]] === {}, d["Jet"][[2]], jetValuation[d["Jet"][[1]]]];
  If[cut === Automatic && d["Jet"][[2]] =!= Infinity,
    h = canon[d["Jet"][[2]] + alpha (r - 1)]];
  If[! TrueQ[truncate] && alpha =!= Infinity,
    h = Max[h, alpha r + 1];
    If[d["Jet"][[2]] =!= Infinity, h = Max[h, d["Jet"][[2]] + alpha (r - 1)]]];
  If[! IntegerQ[r] && ! provablyPositive[d["Prefactor"], ass],
    fail["NonpositiveBase", "A fractional observable power needs a provably positive exact prefactor."]];
  j = fwdPower[d["Jet"], r, Unique["w$"], ell, ass, h, limit];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> d["Prefactor"]^r|>], {"Power", {s}, r},
    If[cut === Automatic || ! TrueQ[truncate], Automatic, h]]];
AsymptoticAnalysis`SeriesPower[s_GeneralizedSeries, r_, opts : OptionsPattern[]] :=
  seriesArithmeticPublicPower[s, r, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesPower[s_GeneralizedSeries, r_, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicPower[s, r, h, OptionValue["MaxTerms"]];

seriesLog[s_, cut_, limit_] := Module[{d, flat, ell, ass, h, j, p},
  d = seriesData[s, limit]; flat = seriesFlat[d, limit]; If[flat =!= $Failed, d = flat];
  If[d["Offset"] =!= 0, fail["UnsupportedScale", "First separate the finite offset from this non-power-log carrier."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  If[! provablyPositive[d["Prefactor"], ass], fail["NonpositiveBase", "A real logarithm needs a provably positive prefactor."]];
  j = fwdLog[d["Jet"], Unique["w$"], ell, ass, h, limit];
  (* A positive prefactor can combine powers and exponentials (for example
     Stirling's factor); simplify its real logarithm before parsing the jet. *)
  p = seriesExpressionJet[FullSimplify[Log[d["Prefactor"]], ass], d, limit];
  If[p === $Failed, fail["UnsupportedScale", "The logarithm of the carrier is outside the recorded power-log coordinate."]];
  j = pAdd[p, j, ell, ass];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> 1|>], {"Log", {s}}, h]];
AsymptoticAnalysis`SeriesLog[s_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Log, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesLog[s_GeneralizedSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Log, s, h, OptionValue["MaxTerms"]];

seriesExp[s_, cut_, limit_] := Module[{d, ell, ass, h, rows, big, small, carrier, j},
  d = seriesFlat[seriesData[s, limit], limit];
  If[d === $Failed, fail["UnsupportedScale", "Exponentiation needs its argument in a single power-log coordinate."]];
  ell = d["LogVariable"]; ass = seriesAss[d]; h = seriesWorkingCut[d, cut];
  If[! less[0, d["Jet"][[2]]],
    fail["InsufficientObservablePrecision", "Exponentiating an asymptotic approximation requires an absolute remainder tending to zero; refine the argument first."]];
  rows = d["Jet"][[1]]; big = Select[rows, ! less[0, #[[1]]] &]; small = Select[rows, less[0, #[[1]]] &];
  carrier = Exp[seriesJetExpression[{big, Infinity, 0}, d["ScaleVariable"], ell]];
  j = fwdExp[{small, d["Jet"][[2]], d["Jet"][[3]]}, Unique["w$"], ell, ass, h, limit];
  seriesMake[Join[d, <|"Jet" -> j, "Prefactor" -> carrier|>], {"Exp", {s}}, h]];
AsymptoticAnalysis`SeriesExp[s_GeneralizedSeries, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Exp, s, OptionValue["Cutoff"], OptionValue["MaxTerms"]];
AsymptoticAnalysis`SeriesExp[s_GeneralizedSeries, h_?exactRealQ, opts : OptionsPattern[]] :=
  seriesArithmeticPublicUnary[Exp, s, h, OptionValue["MaxTerms"]];

(* Apply an expression to a precision-tracked jet. A unary Taylor germ is
   admitted only at a finite constant argument; its coefficients, including
   the precision of the inner argument, are composed by pUnitSeries. *)
seriesIndependentJet[e_, d_, cut_, limit_] := Module[{u, rule},
  If[FreeQ[e, d["Variable"]], Return[pConst[e, d["LogVariable"], seriesAss[d]], Module]];
  u = Unique["coefficientScale$"]; rule = seriesCoordinateRule[d, u];
  If[rule === $Failed, fail["UnsupportedObservableCoefficient", "A coefficient depending on the expansion variable needs its exact local coordinate."]];
  If[cut === Infinity, fwd[e /. rule, u, d["LogVariable"], seriesAss[d] /. rule, cut, limit],
    forwardJet[e /. rule, u, d["LogVariable"], seriesAss[d] /. rule, cut, limit]]];

(* Check the returned chart and known coefficient interval, independently of
   the order requested from Series. This preserves the existing analytic
   source-admission contract; formal SeriesData alone is not its proof. *)
seriesObservableTaylorData[h_, c_, sign_, n_, ass_] := Module[{u = Unique["v$"], native},
  native = Quiet[Series[h[c + sign u], {u, 0, n}, Assumptions -> ass && u > 0]];
  If[! MatchQ[native, _SeriesData] || Length[native] =!= 6 || ! ListQ[native[[3]]],
    fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];
  If[native[[1]] =!= u || native[[2]] =!= 0,
    fail["InvalidObservableNativeChart", "The observable Taylor result must use the requested local variable at zero.",
      <|"ExpectedVariable" -> u, "ExpectedCenter" -> 0, "NativeResult" -> native|>]];
  If[! IntegerQ[native[[4]]] || ! IntegerQ[native[[5]]] || native[[4]] < 0 ||
      native[[5]] < native[[4]] || native[[6]] =!= 1 || ! FreeQ[native[[3]], u],
    fail["UnsupportedObservable", "The observable must have a regular Taylor expansion at the limiting argument."]];
  If[native[[5]] < n,
    fail["InsufficientObservableNativeOrder", "The observable Taylor result does not cover the required coefficients.",
      <|"RequiredExclusiveOrder" -> n, "NativeExclusiveOrder" -> native[[5]], "NativeResult" -> native|>]];
  native];

seriesObservableTaylorCoefficient[native_, k_] := (
  If[k >= native[[5]],
    fail["InsufficientObservableNativeOrder", "The requested observable coefficient is beyond the returned Taylor endpoint.",
      <|"CoefficientOrder" -> k, "NativeExclusiveOrder" -> native[[5]]|>]];
  If[k >= native[[4]] && k - native[[4]] + 1 <= Length[native[[3]]],
    native[[3, k - native[[4]] + 1]], 0]);

seriesObservableIncrementSign[rows_, precision_, ell_, ass_] := Module[{lc},
  If[rows === {} || ! less[jetValuation[rows], precision], Return[0, Module]];
  lc = rows[[1, 2]];
  lc = (-1)^polyDegree[lc, ell] Coefficient[lc, ell, polyDegree[lc, ell]];
  Which[provablyPositive[lc, ass], 1, provablyNegative[lc, ass], -1, True, 0]];

(* A real-axis Taylor bound needs a real complete argument, even when an
   imaginary term is beyond the retained jet. Rename the formal input value
   without renaming assumptions about the actual expansion coordinate. *)
seriesObservableArgumentRealQ[argument_, x_, input_, d_] := Module[
  {value = Unique["observableValue$"], u = Unique["observableDomain$"], expression,
   ass = seriesAss[d], ell = d["LogVariable"], parameters, parts, center, sign, charts},
  expression = argument /. x -> value;
  If[TrueQ[Quiet[TimeConstrained[
      FullSimplify[Element[expression, Reals], ass && Element[value, Reals]], 2, False]]],
    Return[True, Module]];
  (* A shrinking value neighborhood with the source coordinate fixed would
     not prove a uniform bound on their joint path. The global proof above
     is sufficient in that case; this local fallback deliberately refuses. *)
  If[! FreeQ[expression, d["Variable"]], Return[False, Module]];
  parameters = DeleteDuplicates[Cases[expression,
    p_Symbol /; p =!= value && ! NumericQ[p], {0, Infinity}]];
  If[! TrueQ[Quiet[TimeConstrained[
      AllTrue[parameters, TrueQ[FullSimplify[Element[#, Reals], ass]] &], 2, False]]],
    Return[False, Module]];
  parts = splitJet[input[[1]]];
  If[parts[[1]] === {} && FreeQ[parts[[2]], ell],
    center = parts[[2]];
    If[! FreeQ[center, d["Variable"]], Return[False, Module]];
    sign = seriesObservableIncrementSign[parts[[3]], input[[2]], ell, ass];
    charts = If[sign === 0, {center, center + u, center - u}, {center + sign u}],
    sign = seriesObservableIncrementSign[input[[1]], input[[2]], ell, ass];
    If[sign === 0, Return[False, Module]];
    charts = {sign/u}];
  And @@ (TrueQ[Quiet[TimeConstrained[
      logarithmicRealCondition[Element[expression /. value -> #, Reals], ass, <|"u" -> u|>],
      2, False]]] & /@ charts)];

seriesJetApply[e_, x_, input_, d_, cut_, limit_] := Module[{h = Head[e], ell = d["LogVariable"], ass = seriesAss[d], j, parts, c, native, opposite, n, cf, res, sign, c0, point, compatible},
  Which[inverseFunctionApplicationQ[e], inverseFunctionJetApply[e, x, input, d, cut, limit],
    FreeQ[e, x], seriesIndependentJet[e, d, cut, limit], e === x, input,
    h === Plus, Fold[pAdd[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass] &, pConst[0, ell, ass], List @@ e],
    h === Times, Fold[pMul[#1, seriesJetApply[#2, x, input, d, cut, limit], ell, ass, limit] &, pConst[1, ell, ass], List @@ e],
    h === Power && e[[1]] === E, fwdExp[seriesJetApply[e[[2]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Power && FreeQ[e[[2]], x], fwdPower[seriesJetApply[e[[1]], x, input, d, cut, limit], e[[2]], x, ell, ass, cut, limit],
    h === Log && Length[e] === 1, fwdLog[seriesJetApply[e[[1]], x, input, d, cut, limit], x, ell, ass, cut, limit],
    h === Abs, fwdAbs[seriesJetApply[e[[1]], x, input, d, cut, limit], ell, ass],
    Length[e] === 1,
      j = seriesJetApply[e[[1]], x, input, d, cut, limit]; parts = splitJet[j[[1]]];
      If[parts[[1]] =!= {} || ! FreeQ[parts[[2]], ell] || ! less[0, j[[2]]],
        fail["UnsupportedObservable", "A general analytic observable needs an argument tending to a finite constant."]];
      c = parts[[2]];
      (* An exact point uses the point value. A punctured germ instead uses
         its Taylor constant, which can differ at a jump discontinuity. *)
      If[parts[[3]] === {} && j[[2]] === Infinity, Return[pConst[h[c], ell, ass], Module]];
      If[! seriesObservableArgumentRealQ[e[[1]], x, input, d],
        fail["UnprovedObservableArgument", "A real-sided observable Taylor expansion requires its complete argument to be proved real on the input germ.",
          <|"Argument" -> e[[1]], "InputVariable" -> x|>]];
      n = If[parts[[3]] === {}, 1, Max[1, Ceiling[minOf[cut, j[[2]]]/jetValuation[parts[[3]]]]]];
      If[n > limit, fail["ResourceLimit", "Observable Taylor expansion exceeded MaxTerms."]];
      sign = seriesObservableIncrementSign[parts[[3]], j[[2]], ell, ass];
      native = seriesObservableTaylorData[h, c, If[sign === 0, 1, sign], n, ass];
      c0 = seriesObservableTaylorCoefficient[native, 0];
      If[sign === 0,
        opposite = seriesObservableTaylorData[h, c, -1, n, ass];
        point = h[c];
        (* An uncertain side can include visits to the center. With no
           retained increment only the common O(displacement) bound is used;
           otherwise both sides must supply the same Taylor polynomial. *)
        compatible = TimeConstrained[
          zeroQ[c0 - point, ass] && zeroQ[c0 - seriesObservableTaylorCoefficient[opposite, 0], ass] &&
            (parts[[3]] === {} || And @@ Table[
              zeroQ[seriesObservableTaylorCoefficient[native, k] -
                (-1)^k seriesObservableTaylorCoefficient[opposite, k], ass], {k, 1, n - 1}]),
          2, False];
        If[! TrueQ[compatible], fail["UnprovedObservableApproach",
          "The input has no proved side and the observable has no compatible Taylor bound on both sides and at the limiting point.",
          <|"LimitingArgument" -> c, "PositiveGermConstant" -> c0,
            "NegativeGermConstant" -> seriesObservableTaylorCoefficient[opposite, 0], "PointValue" -> point|>]]];
      (* The completed observable is checked by seriesMake after collection;
         separate analytic summands can have cancelling imaginary parts. *)
      cf = Function[k, seriesObservableTaylorCoefficient[native, k]];
      If[parts[[3]] === {}, Return[{jetMerge[{{0, c0}}, ell, ass], j[[2]], j[[3]]}, Module]];
      If[sign === -1, parts[[3]] = jetScale[parts[[3]], -1, ell, ass]];
      res = pUnitSeries[parts[[3]], j[[2]], j[[3]], cf, cut, ell, ass, limit];
      pAdd[pConst[c0, ell, ass], res, ell, ass],
    True, fail["UnsupportedObservable", "This observable is not in the supported algebra of regular unary analytic functions, powers, logarithms and exponentials."]]];

AsymptoticAnalysis`SeriesObservable[s_GeneralizedSeries, e_, x_Symbol, opts : OptionsPattern[]] := catch[Block[
  {$inverseFunctionBranchSelections = OptionValue["InverseFunctionBranches"], $inverseFunctionProvenance = {},
    $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>},
  Module[{d, h, j, body = e, condition = True, result, limit = OptionValue["MaxTerms"]},
  requireAnalyticSeries[s];
  validateInput[e, limit];
  If[e === Log[x], Return[seriesLog[s, OptionValue["Cutoff"], limit], Module]];
  If[e === Exp[x], Return[seriesExp[s, OptionValue["Cutoff"], limit], Module]];
  If[Head[e] === Power && e[[1]] === x && FreeQ[e[[2]], x], Return[seriesPower[s, e[[2]], OptionValue["Cutoff"], limit], Module]];
  d = seriesFlat[seriesData[s, limit], limit];
  If[d === $Failed, fail["UnsupportedScale", "This observable requires a single power-log representation of its argument."]];
  h = seriesWorkingCut[d, OptionValue["Cutoff"]];
  While[Head[body] === ConditionalExpression, condition = condition && body[[2]]; body = body[[1]]];
  If[! TrueQ[inverseFunctionConditionOnJet[condition, x, d["Jet"], d, h, limit]],
    fail["IncompatibleObservableCondition", "The observable condition is not proved on the precision-tracked input germ.", <|"Condition" -> condition|>]];
  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];
  GeneralizedSeries[Join[result[[1]], <|"InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> DeleteDuplicates[$inverseFunctionProvenance]|>]]]]];

(* The coefficients alone do not record all fixed data of a remainder: a
   parameter may occur only in the discarded source or an operand recipe.
   Source variables of inverse equations and operand variables are bound. *)
seriesCompositionScope[s : GeneralizedSeries[data_Association], variable_] := Module[
  {outerVariable = Lookup[data, "Variable", None], sourceVariable, dependencies,
   source, recipe, operands = {}, extra = {}, scopes, known, captured},
  If[outerVariable === variable, Return[{True, False}, Module]];
  sourceVariable = Lookup[data, "SourceVariable",
    Replace[Lookup[data, "Variables", {}], {{x_Symbol, _Symbol} :> x, _ :> outerVariable}]];
  dependencies = KeyTake[data, {"Expression", "Assumptions", "TargetDomain", "Remainder",
    "RemainderScaleExpression", "RemainderPower", "RemainderLogDegree", "Prefactor", "Offset",
    "ExpansionPoint", "FixedParameters"}];
  source = If[sourceVariable === variable, {}, KeyTake[data, {"Function", "SourceDomain",
    "ConditionalSourceReplay", "ForwardModel", "InputRemainder", "DeclaredInputRemainder", "InputDomains"}]];
  recipe = Lookup[data, "SeriesRecipe", None];
  If[ListQ[recipe] && Length[recipe] >= 2 && ListQ[recipe[[2]]],
    operands = Select[recipe[[2]], MatchQ[#, _GeneralizedSeries] &];
    extra = Drop[recipe, 2];
    If[recipe[[1]] === "Observable" && Length[recipe] >= 4,
      extra = If[recipe[[4]] === variable, {}, {recipe[[3]]}]]];
  If[MatchQ[Lookup[data, "CoordinateSeries", None], _GeneralizedSeries],
    AppendTo[operands, data["CoordinateSeries"]];
    extra = {extra, Last /@ Lookup[data, "CoordinateSubstitution", {}]}];
  scopes = seriesCompositionScope[#, variable] & /@ DeleteDuplicates[operands];
  known = Lookup[data, "Remainder", None] === 0 || KeyExistsQ[data, "Function"] ||
    (scopes =!= {} && And @@ scopes[[All, 1]]);
  captured = ! FreeQ[{dependencies, source, extra}, variable] ||
    (scopes =!= {} && Or @@ scopes[[All, 2]]);
  {known, captured}];

seriesCompositionJointData[a_, b_, limit_] := Module[{ignored, ass, condition, u, rule, d},
  {ignored, ass, condition} = splitApproachInput[True, b["Variable"],
    a["Assumptions"] && b["Assumptions"]];
  If[TrueQ[Simplify[Not[ass]]], fail["IncompatibleDomains", "The operands have conflicting parameter assumptions."]];
  d = Join[b, <|"Assumptions" -> ass|>];
  u = Unique["jointScale$"]; rule = seriesCoordinateRule[d, u];
  If[rule === $Failed || ! inverseFunctionEventually[condition /. rule, u, ass],
    fail["IncompatibleCompositionParameters", "The outer parameter assumptions are not proved along the inner approach.",
      <|"Condition" -> condition, "Variable" -> b["Variable"]|>]];
  Join[d, <|"Domain" -> Lookup[d, "Domain", True] && condition|>]];

seriesCompositionCoordinate[a_, b_, h_, limit_, ass_] := Module[{wj, lc, ell = b["LogVariable"]},
  wj = seriesJetApply[a["ScaleVariable"], a["Variable"], b["Jet"], b, h, limit];
  If[wj[[1]] === {} || ! less[0, jetValuation[wj[[1]]]],
    fail["IncompatibleLimits", "The inner expansion must approach the outer expansion point from its recorded positive local side."]];
  lc = wj[[1, 1, 2]];
  If[! FreeQ[lc, ell] || ! provablyPositive[lc, ass],
    fail["UnsupportedCompositionScale", "Composition requires a positive monomial leading block for the outer local coordinate."]];
  wj];

(* Replay only a complete forward source along an exact forward inner germ.
   The old outer tail is discarded, not relabeled as uniform. The strict
   analytic constructor rechecks all original conditions in the new regime. *)
seriesCompositionSourceReplay[outer_, inner_, cut_, limit_] := Module[
  {oa = outer[[1]], ia = inner[[1]], source, a, b, h, expression, condition, result},
  If[Lookup[oa, "Kind", None] =!= "Forward" || ! KeyExistsQ[oa, "Function"] ||
     Lookup[ia, "Kind", None] =!= "Forward" || Lookup[ia, "Remainder", None] =!= 0 ||
     ! TrueQ[Lookup[ia, "Exact", False]], Return[$Failed, Module]];
  source = oa["Function"];
  If[! FreeQ[source, _PowerLogRemainder | _GeneralizedSeries | _SeriesData | _InverseFunction],
    Return[$Failed, Module]];
  a = seriesFlat[seriesData[outer, limit], limit]; b = seriesFlat[seriesData[inner, limit], limit];
  If[a === $Failed || b === $Failed, Return[$Failed, Module]];
  b = seriesCompositionJointData[a, b, limit]; h = seriesWorkingCut[b, cut];
  seriesCompositionCoordinate[a, b, h, limit, seriesAss[b]];
  If[! TrueQ[inverseFunctionConditionOnJet[Lookup[oa, "TargetDomain", True],
      oa["Variable"], b["Jet"], b, h, limit]],
    fail["IncompatibleTargetCondition", "The outer source condition is not proved on the joint approach.",
      <|"Condition" -> Lookup[oa, "TargetDomain", True]|>]];
  expression = Normal[inner];
  condition = Lookup[ia, "TargetDomain", True] && (Lookup[oa, "TargetDomain", True] /. oa["Variable"] -> expression);
  result = AsymptoticExpansion[ConditionalExpression[source /. oa["Variable"] -> expression, condition],
    {ia["Variable"], ia["ExpansionPoint"], h}, Assumptions -> (oa["Assumptions"] && ia["Assumptions"]),
    Direction -> ia["Direction"], "Backend" -> "Package", "MaxTerms" -> limit];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"CompositionScope" -> <|
    "Method" -> "ReplayExactForwardSources", "CapturedParameter" -> ia["Variable"],
    "OuterVariable" -> oa["Variable"], "OriginalOuterRemainderTransported" -> False,
    "UniformParameterBoundAsserted" -> False|>|>]]];

seriesCompositionAdmission[outer_, inner_, cut_, limit_, replay_: True] := Module[{scope, captured, result},
  requireAnalyticSeries[outer]; requireAnalyticSeries[inner];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "A series operation cutoff must be an exact real number."]];
  scope = seriesCompositionScope[outer, Lookup[inner[[1]], "Variable", None]]; captured = scope[[2]];
  If[Lookup[outer[[1]], "Remainder", None] =!= 0,
    If[captured,
      result = If[TrueQ[replay], seriesCompositionSourceReplay[outer, inner, cut, limit], $Failed];
      If[result =!= $Failed, Return[{True, result}, Module]];
      fail["ParameterCapture", "The inner variable was fixed data of the outer remainder. A joint source expansion or a separately proved uniform bound is required.",
        <|"OuterVariable" -> outer["Variable"], "CapturedParameter" -> inner["Variable"], "UniformityEstablished" -> False|>]];
    If[! TrueQ[scope[[1]]], fail["MissingParameterScope", "The outer remainder has no retained source or operation provenance establishing its fixed-parameter scope."]]];
  {captured, $Failed}];

AsymptoticAnalysis`SeriesCompose[outer_GeneralizedSeries, inner_GeneralizedSeries, opts : OptionsPattern[]] := catch[Module[
  {a, b, wj, term, result, p, deg, alpha, ell, ass, h, captured,
   cut = OptionValue["Cutoff"], limit = OptionValue["MaxTerms"]},
  {captured, result} = seriesCompositionAdmission[outer, inner, cut, limit];
  If[result =!= $Failed, Return[result, Module]];
  If[! captured,
    result = reciprocalLogCompose[outer, inner, cut, limit];
    If[result =!= $Failed, Return[result, Module]]];
  a = seriesFlat[seriesData[outer, limit], limit]; b = seriesFlat[seriesData[inner, limit], limit];
  If[a === $Failed || b === $Failed, fail["UnsupportedScale", "Composition currently requires a single power-log representation of both operands."]];
  If[captured, b = seriesCompositionJointData[a, b, limit]];
  ell = b["LogVariable"]; ass = If[captured, seriesAss[b], seriesAss[a] && seriesAss[b]];
  h = seriesWorkingCut[b, cut];
  wj = seriesCompositionCoordinate[a, b, h, limit, ass]; alpha = jetValuation[wj[[1]]];
  If[captured && ! TrueQ[inverseFunctionConditionOnJet[Lookup[a, "Domain", True],
      a["Variable"], b["Jet"], b, h, limit]],
    fail["IncompatibleCompositionParameters", "The exact outer expression's domain is not proved on the joint approach."]];
  result = pConst[0, ell, ass];
  Do[term = pMul[fwdPower[wj, row[[1]], Unique["w$"], ell, ass, h, limit],
      seriesJetApply[row[[2]], a["LogVariable"], fwdLog[wj, Unique["w$"], ell, ass, h, limit], b, h, limit], ell, ass, limit];
    result = pAdd[result, term, ell, ass], {row, a["Jet"][[1]]}];
  {p, deg} = a["Jet"][[{2, 3}]];
  If[p =!= Infinity, result = pAdd[result, {{}, canon[alpha p], deg}, ell, ass]];
  seriesMake[Join[b, <|"Jet" -> result,
    "Assumptions" -> If[captured, b["Assumptions"], a["Assumptions"] && b["Assumptions"]],
    "Domain" -> Lookup[b, "Domain", True] && (Lookup[a, "Domain", True] /.
      a["Variable"] -> seriesJetExpression[b["Jet"], b["ScaleVariable"], b["LogVariable"]]),
    "RemainderDerivativeOrder" -> Min[Lookup[a, "RemainderDerivativeOrder", 0], Lookup[b, "RemainderDerivativeOrder", 0]]|>], {"Compose", {outer, inner}}, h]]];

AsymptoticAnalysis`SeriesTruncate[s_GeneralizedSeries, h_, opts : OptionsPattern[]] := catch[Module[{d},
  requireAnalyticSeries[s];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[s[[1]], "Kind", ""]], Return[gammaInverseTruncate[s, h, OptionValue["MaxTerms"]], Module]];
  d = seriesData[s, OptionValue["MaxTerms"]];
  If[! exactRealQ[h], fail["InvalidCutoff", "The truncation cutoff must be an exact real number."]];
  seriesMake[d, {"Truncate", {s}}, h]]];

seriesDerivative[s_, n_, declared_, cut_, limit_] := Module[{d, contract, ell, ass, j, q, wprime, pprime, first, second, result, k},
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The derivative order must be a nonnegative integer."]];
  If[n =!= 0 || cut =!= Automatic, requireAnalyticSeries[s]];
  result = reciprocalLogDifferentiate[s, n, declared, cut, limit];
  If[result =!= $Failed, Return[result, Module]];
  If[n === 0, Return[s, Module]];
  d = seriesData[s, limit]; contract = Lookup[d, "RemainderDerivativeOrder", 0];
  If[declared =!= Automatic,
    If[declared =!= Infinity && (! IntegerQ[declared] || declared < 0), fail["InvalidDerivativeContract", "RemainderDerivativeOrder must be a nonnegative integer or Infinity."]];
    contract = Max[contract, declared]];
  If[contract < n, fail["UnprovedRemainderDerivative", "A magnitude Big-O bound cannot be differentiated. Supply RemainderDerivativeOrder -> n only when the corresponding derivative bounds are known.", <|"AvailableDerivativeOrder" -> contract, "RequestedDerivativeOrder" -> n|>]];
  result = s;
  Do[d = seriesData[result, limit]; ell = d["LogVariable"]; ass = seriesAss[d]; j = d["Jet"];
    q = {jetMerge[({#[[1]] - 1, #[[1]] #[[2]] + D[#[[2]], ell]} & /@ j[[1]]), ell, ass],
      If[j[[2]] === Infinity, Infinity, j[[2]] - 1], j[[3]]};
    wprime = D[d["ScaleVariable"], d["Variable"]]; pprime = D[d["Prefactor"], d["Variable"]];
    first = seriesMake[Join[d, <|"Jet" -> q, "Prefactor" -> d["Prefactor"] wprime,
      "Offset" -> D[d["Offset"], d["Variable"]], "RemainderDerivativeOrder" -> contract - k|>], {"DerivativeStep", {result}}];
    result = If[pprime === 0, first,
      second = seriesMake[Join[d, <|"Prefactor" -> pprime, "Offset" -> 0, "RemainderDerivativeOrder" -> contract - k|>], {"DerivativeStep", {result}}];
      seriesBinary["Add", first, second, Automatic, limit]], {k, n}];
  d = seriesData[result, limit];
  seriesMake[d, {"Differentiate", {s}, n, declared}, If[cut === Automatic, Automatic, seriesWorkingCut[d, cut]]]];
AsymptoticAnalysis`SeriesDifferentiate[s_GeneralizedSeries, n_Integer : 1, opts : OptionsPattern[]] :=
  catch[seriesDerivative[s, n, OptionValue["RemainderDerivativeOrder"], OptionValue["Cutoff"], OptionValue["MaxTerms"]]];

seriesRefinementResult[result_, original_, cutoff_] := Module[{data, stats},
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  data = result[[1]];
  If[MemberQ[{"GammaInverse", "BarnesGInverse"}, Lookup[original[[1]], "Kind", ""]],
    data = Join[data, <|"TargetDomain" -> Lookup[original[[1]], "TargetDomain", True] &&
      Lookup[data, "TargetDomain", True]|>]];
  If[KeyExistsQ[data, "RefinementStatistics"], Return[GeneralizedSeries[data], Module]];
  stats = <|"Strategy" -> If[Lookup[original[[1]], "Kind", ""] === "Derived" &&
      KeyExistsQ[original[[1]], "SeriesRecipe"], "ReplayOperationRecipe", "ReplayOriginalSource"],
    "SourceCutoff" -> Lookup[original[[1]], "Cutoff", Missing["NotAvailable"]], "RequestedCutoff" -> cutoff,
    "ModelReused" -> False, "ReusedBlocks" -> 0,
    "NewCoefficientEvaluations" -> Missing["ReplayNotInstrumented"],
    "Evidence" -> "Recomputed from retained source or operation recipe; no coefficient reuse or work count is claimed."|>;
  GeneralizedSeries[Join[data, <|"RefinementStatistics" -> stats,
    "RefinementHistory" -> Append[Lookup[original[[1]], "RefinementHistory", {}], stats]|>]]];

AsymptoticAnalysis`SeriesRefine[s : GeneralizedSeries[a_Association], h_, opts : OptionsPattern[]] := catch[seriesRefinementResult[Module[
  {recipe, args, operands, r, limit = OptionValue["MaxTerms"], rules, base, x, y, sourceOptions, declared},
  requireAnalyticSeries[s];
  If[! exactRealQ[h], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];
  If[KeyExistsQ[a, "InverseFunctionExpression"],
    Return[AsymptoticExpansion[a["InverseFunctionExpression"], {a["Variable"], a["InverseFunctionExpansionPoint"], h},
      Assumptions -> a["Assumptions"], Direction -> a["InverseFunctionExpansionDirection"],
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  r = refineStoredInverse[s, h, limit];
  If[r =!= $Failed, Return[r, Module]];
  If[KeyExistsQ[a, "ConditionalSourceReplay"] && MatchQ[Lookup[a, "Variables", None], {_Symbol, _Symbol}],
    {x, y} = a["Variables"];
    Return[AsymptoticInverse[a["ConditionalSourceReplay"], {x, a["ExpansionPoint"]}, {y, h},
      Assumptions -> a["Assumptions"], Direction -> a["Direction"],
      Method -> Lookup[a, "RequestedMethod", Lookup[a, "Method", "Lagrange"]],
      "Power" -> Lookup[a, "Power", 1], "InputRemainder" -> Lookup[a, "DeclaredInputRemainder", Automatic],
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "SpecialInverse" && ListQ[Lookup[a, "AdapterOptions", None]],
    {x, y} = a["Variables"];
    Return[AsymptoticAnalysis`AsymptoticSpecialInverse[a["Adapter"], {x, a["ExpansionPoint"]}, {y, h},
      Sequence @@ a["AdapterOptions"], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "LogarithmicInverse",
    {x, y} = a["Variables"];
    Return[AsymptoticAnalysis`AsymptoticLogarithmicInverse[a["Function"], {x, a["ExpansionPoint"]}, {y, h},
      Assumptions -> a["Assumptions"], Direction -> a["Direction"], "Power" -> a["Power"],
      "LogarithmicLevels" -> a["LogarithmicLevels"], "MaxTerms" -> limit], Module]];
  If[Lookup[a, "Kind", ""] === "Forward", Return[AsymptoticExpansion[a["Function"], {a["Variable"], a["ExpansionPoint"], h},
    Assumptions -> a["Assumptions"], Direction -> a["Direction"],
    "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit], Module]];
  If[MemberQ[{"Inverse", "GammaInverse", "BarnesGInverse"}, Lookup[a, "Kind", ""]] && MatchQ[Lookup[a, "Variables", None], {_Symbol, _Symbol}],
    {x, y} = a["Variables"];
    sourceOptions = {Assumptions -> a["Assumptions"], Direction -> a["Direction"],
      Method -> Lookup[a, "RequestedMethod", a["Method"]], "Power" -> a["Power"],
      "Truncation" -> Lookup[a, "Truncation", "Exponent"], "MaxTerms" -> limit};
    declared = Lookup[a, "DeclaredInputRemainder", Lookup[a, "InputRemainder", Automatic]];
    If[MemberQ[{None, Automatic}, declared] || ListQ[declared],
      AppendTo[sourceOptions, "InputRemainder" -> declared]];
    Return[AsymptoticInverse[a["Function"], {x, a["ExpansionPoint"]}, {y, h}, Sequence @@ sourceOptions], Module]];
  If[MatchQ[Lookup[a, "CoordinateSeries", None], _GeneralizedSeries],
    base = AsymptoticAnalysis`SeriesRefine[a["CoordinateSeries"], h, "MaxTerms" -> limit];
    If[FailureQ[base], Return[base, Module]];
    rules = Lookup[a, "CoordinateSubstitution", {}]; r = seriesData[base, limit] /. rules;
    Return[seriesMake[Join[r, <|"Variable" -> a["Variable"]|>], {"CoordinateRefine", {s}}, h], Module]];
  recipe = Lookup[a, "SeriesRecipe", Missing["NoRecipe"]];
  If[MissingQ[recipe], fail["MissingRefinementSource", "The expansion has no retained source or operation recipe; its existing remainder cannot be improved by truncation."]];
  operands = recipe[[2]];
  (* Recompute operands with a guard margin. The final operation still clips
     to its actual transported precision, so this never invents coefficients. *)
  args = AsymptoticAnalysis`SeriesRefine[#, h + 2 + Abs[Min[0, Lookup[seriesData[#, limit], "Jet"][[2]] /. Infinity -> 0]], "MaxTerms" -> limit] & /@ operands;
  If[AnyTrue[args, FailureQ], Return[First[Select[args, FailureQ]], Module]];
  Switch[recipe[[1]],
    "Add", seriesBinary["Add", args[[1]], args[[2]], h, limit],
    "Multiply", seriesBinary["Multiply", args[[1]], args[[2]], h, limit],
    "Power", seriesPower[First[args], recipe[[3]], h, limit],
    "Log", seriesLog[First[args], h, limit],
    "Exp", seriesExp[First[args], h, limit],
    "Observable", AsymptoticAnalysis`SeriesObservable[First[args], recipe[[3]], recipe[[4]], "Cutoff" -> h,
      "InverseFunctionBranches" -> Lookup[a, "InverseFunctionBranches", Automatic], "MaxTerms" -> limit],
    "Compose", AsymptoticAnalysis`SeriesCompose[args[[1]], args[[2]], "Cutoff" -> h, "MaxTerms" -> limit],
    "Truncate", AsymptoticAnalysis`SeriesTruncate[First[args], h, "MaxTerms" -> limit],
    "Constant", seriesConstant[recipe[[3]], First[args], limit],
    "RegularOperand", seriesRegularOperand[recipe[[3]], First[args], recipe[[4]], h, limit],
    "Differentiate", If[recipe[[4]] =!= Automatic &&
      Lookup[seriesData[First[args], limit], "RemainderDerivativeOrder", 0] < recipe[[3]],
        fail["UnprovedRefinedDerivative", "A derivative bound declared for the old remainder does not establish the stronger bound for the refined remainder. Refine the source first, then supply its derivative contract."]];
      seriesDerivative[First[args], recipe[[3]], Automatic, h, limit],
    _, fail["MissingRefinementSource", "This internal derived representation has no replayable public recipe."]]], s, h]];
(* END SOURCE: src/Kernel/SeriesOperations.wl *)

(* BEGIN SOURCE: src/Kernel/RefinementState.wl
   Source SHA256 (UTF-8/LF): 57a3cb48f34cd09a9aef5d2411221c323f78fe3e3c9745a50fcd29c26435693c *)
(* Reuse of ordinary inverse coefficient prefixes. No global cache is used.
   $Failed requests the existing source-replay path (for example when a new
   automatic forward expansion is needed). All returned states are values. *)

refinementInternalPower[a_] := If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
refinementSignature[a_] := Module[{m = a["Model"], ell},
  ell = m["LogVariable"];
  IntegerString[Hash[{m["LeadingPower"], m["Gaps"], m["Polynomials"] /. ell -> $refinementLogMarker,
    refinementInternalPower[a], a["Assumptions"], a["Function"], a["Variables"],
    a["ExpansionPoint"], a["Direction"], a["LeadingCoefficient"]}, "SHA256"], 16, 64]];

refinementEqualJets[x_, y_, ell_, ass_] :=
  jetMerge[Join[x, jetScale[y, -1, ell, ass]], ell, ass] === {};

refinementCompatibleState[state_, a_, signature_] := Module[{m = a["Model"], aligned},
  If[KeyExistsQ[state, "ModelSignature"] && state["ModelSignature"] =!= signature,
    fail["StaleComputationState", "The retained state belongs to a different model, branch or assumptions."]];
  aligned = state /. state["LogVariable"] -> a["LogVariable"];
  If[aligned["Gaps"] =!= m["Gaps"] || aligned["Polynomials"] =!= m["Polynomials"] ||
    aligned["LeadingPower"] =!= m["LeadingPower"] || aligned["Assumptions"] =!= a["Assumptions"],
    fail["StaleComputationState", "The retained state does not match the stored inverse model."]];
  aligned];

refinementLagrangeSeed[a_, limit_, signature_] := Module[
  {state = Lookup[a, "ComputationState", None], m = a["Model"], ell = a["LogVariable"],
   ass = a["Assumptions"], hold, region, boundary, weights, rint, origin},
  rint = refinementInternalPower[a]; hold = canon[Abs[m["LeadingPower"]] a["Cutoff"] - rint];
  If[AssociationQ[state] && KeyExistsQ[state, "Boundary"],
    state = refinementCompatibleState[state, a, signature];
    If[state["Power"] =!= rint || ! refinementEqualJets[jetTrim[state["Blocks"], hold, ell, ass], a["Blocks"], ell, ass],
      fail["StaleComputationState", "The retained coefficient prefix does not match the displayed complete blocks."]];
    origin = "RetainedLagrangeState",
    region = indexRegion[m["Gaps"], hold, False, limit];
    boundary = Association[(incrementalIndexKey[#] -> {canon[# . m["Gaps"]], #}) & /@ region["Boundary"]];
    weights = canon[# . m["Gaps"]] & /@ region["Inside"];
    state = Join[incrementalInverseState[m["Gaps"], m["Polynomials"], m["LeadingPower"], rint, ell, ass, limit],
      <|"Inside" -> region["Inside"], "Boundary" -> boundary, "Blocks" -> a["Blocks"],
        "LastWeight" -> If[weights === {}, -Infinity, Last[Sort[weights, leq]]],
        "NextWeight" -> If[Length[boundary] === 0, Infinity, First[Sort[First /@ Values[boundary], leq]]],
        "CoefficientEvaluations" -> Length[region["Inside"]], "Layers" -> Length[DeleteDuplicates[weights]]|>];
    origin = "StoredCompleteBlocks"];
  If[Length[state["Inside"]] + Length[state["Boundary"]] > limit,
    fail["ResourceLimit", "The retained index region and boundary exceed the requested MaxTerms budget."]];
  {incrementalResizePolynomialCache[Join[state, <|"MaxTerms" -> limit,
    "ModelSignature" -> signature, "StateType" -> "Lagrange"|>]], origin}];

refinementLagrangeAdvance[state0_, cut_] := Module[{state = state0, omitted, first, attempts = 0, candidate, fallback, uncached = 0},
  While[state["NextWeight"] =!= Infinity && less[state["NextWeight"], cut], state = advanceInverseState[state]];
  omitted = Select[state["Blocks"], ! less[#[[1]], cut] &];
  first = state["NextWeight"];
  (* A frontier layer is evaluated as a whole, including every resonant index.
     Keep these extra coefficients in the state for the next refinement. *)
  While[omitted === {} && state["NextWeight"] =!= Infinity && attempts < 8,
    attempts++; candidate = catch[advanceInverseState[state]];
    If[FailureQ[candidate],
      If[candidate[[1]] =!= "ResourceLimit", Throw[candidate, $tag]];
      fallback = refinementNewtonFrontier[incrementalInverseRegion[state], state["Gaps"], state["Polynomials"],
        state["LeadingPower"], state["Power"], state["LogVariable"], state["Assumptions"], state["MaxTerms"]];
      Return[{state, fallback[[1]], fallback[[2]]}, Module]];
    state = candidate;
    omitted = Select[state["Blocks"], ! less[#[[1]], cut] &]];
  {state, Which[omitted =!= {}, First[omitted], first === Infinity, None, True, {first, 0}], uncached}];

refinementNewtonSeed[a_, limit_, signature_] := Module[
  {state = Lookup[a, "ComputationState", None], m = a["Model"], ell = a["LogVariable"],
   ass = a["Assumptions"], hold, rint, unit, observed, precision, origin, check},
  rint = refinementInternalPower[a]; hold = canon[Abs[m["LeadingPower"]] a["Cutoff"] - rint];
  If[AssociationQ[state] && KeyExistsQ[state, "UnitJet"],
    state = refinementCompatibleState[state, a, signature];
    If[less[state["Precision"], hold], fail["StaleComputationState", "The retained Newton state has insufficient precision for the displayed inverse."]];
    observed = jetUnitPower[state["UnitJet"], rint, hold, ell, ass, limit];
    If[! refinementEqualJets[observed, a["Blocks"], ell, ass],
      fail["StaleComputationState", "The retained Newton unit does not reproduce the displayed observable."]];
    origin = "RetainedNewtonState",
    observed = jetAdd[a["Blocks"], {{0, -1}}, hold, ell, ass];
    unit = If[rint === 1, observed,
      jetAdd[jetUnitPower[observed, 1/rint, hold, ell, ass, limit], {{0, -1}}, hold, ell, ass]];
    state = newtonInverseState[m["Gaps"], m["Polynomials"], m["LeadingPower"], ell, ass, limit];
    precision = If[state["Precision"] === Infinity, Infinity, If[less[hold, state["Precision"]], state["Precision"], hold]];
    check = If[precision === Infinity, {}, modelEquation[unit, m["Gaps"], m["Polynomials"], m["LeadingPower"], precision, ell, ass, limit]];
    If[check =!= {}, fail["StaleComputationState", "The unit recovered from the stored observable has a nonzero residual below its claimed precision."]];
    state = Join[state, <|"UnitJet" -> unit, "Precision" -> precision, "SeedPrecision" -> precision|>];
    origin = "StoredObservableUnit"];
  {Join[state, <|"MaxTerms" -> limit, "ModelSignature" -> signature, "StateType" -> "Newton",
    "ObservablePower" -> rint, "ResidualVerified" -> True|>], origin}];

(* Same complete-boundary convention as inverseFrontier, with an explicit
   count of the independent Euler-coefficient work used for the remainder. *)
refinementNewtonFrontier[region_, d_, polys_, p_, r_, ell_, ass_, limit_] :=
  inverseFrontierWithCount[region, d, polys, p, r, ell, ass, limit];

refinementAssemble[a_, cutoff_, blocks_, frontier_, state_, statistics_] := Module[
  {p = a["LeadingPower"], leading = a["LeadingCoefficient"], r = a["Power"], rint,
   ell = a["LogVariable"], ass = a["Assumptions"], y = a["Variable"], x, coord, v, logw,
   terms, expression, localExpression, remData, input = a["InputRemainder"], cap, remainder, frontierTerm},
  x = a["Variables"][[1]]; coord = localCoordinate[x, a["ExpansionPoint"], a["Direction"]];
  rint = refinementInternalPower[a];
  remData = If[frontier === None, None, {canon[(rint + frontier[[1]])/Abs[p]], polyDegree[frontier[[2]], ell]}];
  If[ListQ[input], cap = canon[(input[[1]] - p + rint)/Abs[p]];
    remData = If[remData === None, {cap, input[[2]]}, combinePrecision[remData, {cap, input[[2]]}]]];
  v = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]; logw = Log[v/leading]/p;
  terms = {ToRadicals[canon[(rint + #[[1]])/p]], ToRadicals[#[[2]]] /. ell -> logw} & /@ blocks;
  localExpression = Total[((v/leading)^#[[1]] #[[2]]) & /@ terms];
  expression = Which[coord["Infinite"], coord["Sign"]^r localExpression,
    r === 1, a["ExpansionPoint"] + coord["Sign"] localExpression,
    True, coord["Sign"]^r localExpression];
  remainder = If[remData === None, 0, PowerLogRemainder[a["RemainderVariable"], ToRadicals[remData[[1]]], remData[[2]]]];
  frontierTerm = If[frontier === None, 0, coord["Sign"]^r (v/leading)^ToRadicals[canon[(rint + frontier[[1]])/p]]
    (ToRadicals[frontier[[2]]] /. ell -> logw)];
  GeneralizedSeries[Join[a, <|"Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "Remainder" -> remainder, "RemainderPower" -> If[remData === None, Infinity, ToRadicals[remData[[1]]]],
    "RemainderLogDegree" -> If[remData === None, 0, remData[[2]]],
    "RemainderScaleExpression" -> If[remainder === 0, 0, remainderScale[remainder]],
    "FrontierTerm" -> frontierTerm, "Cutoff" -> ToRadicals[cutoff], "RequestedTermGoal" -> Automatic,
    "ReturnedTermCount" -> Length[blocks], "ComputationState" -> state,
    "RefinementStatistics" -> statistics,
    "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], statistics],
    "SeriesData" -> makeInverseSeriesData[terms, y, a["Limit"], leading, coord, remData, r, a["ExpansionPoint"]]|>]]];

refineStoredInverse[s : GeneralizedSeries[a_Association], cutoff_, limit_] := Module[
  {m, method, p, rint, cut, oldCut, cap, declared, signature, state, origin, before, after, blocks,
   frontier, stats, region, frontierWork = 0, pair, result, exactStats},
  If[Lookup[a, "Kind", ""] =!= "Inverse" || Lookup[a, "Scale", "PowerLog"] =!= "PowerLog" ||
    Lookup[a, "Truncation", "Exponent"] =!= "Exponent" || ! AssociationQ[Lookup[a, "Model", None]], Return[$Failed, Module]];
  method = a["Method"]; If[! MemberQ[{"Lagrange", "Newton"}, method], Return[$Failed, Module]];
  If[! exactRealQ[cutoff], fail["InvalidCutoff", "The refinement cutoff must be an exact real number."]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  m = a["Model"]; p = m["LeadingPower"]; rint = refinementInternalPower[a];
  cut = canon[Abs[p] cutoff - rint];
  If[! less[0, cut], fail["CutoffTooSmall", "The cutoff must exceed the leading exponent of the inverse observable.", <|"LeadingExponent" -> ToRadicals[rint/Abs[p]]|>]];
  If[ListQ[a["InputRemainder"]], cap = canon[(a["InputRemainder"][[1]] - p + rint)/Abs[p]];
    If[less[cap, cutoff],
      declared = Lookup[a, "DeclaredInputRemainder", a["InputRemainder"]];
      If[MemberQ[{Automatic, None}, declared] && ! TrueQ[a["ExactModel"]], Return[$Failed, Module]];
      fail["InsufficientInputOrder", "The requested refinement exceeds the precision transported from the declared forward remainder.", <|"MaximumCutoff" -> ToRadicals[cap]|>]]];
  If[a["Cutoff"] =!= Infinity && equal[cutoff, a["Cutoff"]],
    exactStats = <|"Strategy" -> "UnchangedCutoff", "SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
      "ModelReused" -> True, "NewCoefficientEvaluations" -> 0, "NewNewtonSteps" -> {}, "ReusedBlocks" -> Length[a["Blocks"]]|>;
    Return[GeneralizedSeries[Join[a, <|"RefinementStatistics" -> exactStats,
      "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], exactStats]|>]], Module]];
  If[a["Remainder"] === 0 && And @@ (less[#[[1]], cut] & /@ a["Blocks"]),
    exactStats = <|"Strategy" -> "ExactFiniteInverse", "SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
      "ModelReused" -> True, "NewCoefficientEvaluations" -> 0, "NewNewtonSteps" -> {}, "ReusedBlocks" -> Length[a["Blocks"]]|>;
    Return[GeneralizedSeries[Join[a, <|"Cutoff" -> cutoff, "RefinementStatistics" -> exactStats,
      "RefinementHistory" -> Append[Lookup[a, "RefinementHistory", {}], exactStats]|>]], Module]];
  If[a["Cutoff"] === Infinity, Return[$Failed, Module]];
  signature = refinementSignature[a];
  If[method === "Lagrange",
    {state, origin} = refinementLagrangeSeed[a, limit, signature]; before = state;
    {state, frontier, frontierWork} = refinementLagrangeAdvance[state, cut];
    blocks = jetTrim[state["Blocks"], cut, a["LogVariable"], a["Assumptions"]];
    stats = <|"Strategy" -> "IncrementalLagrange", "StateOrigin" -> origin,
      "ReusedCoefficientEvaluations" -> before["CoefficientEvaluations"],
      "NewCoefficientEvaluations" -> state["CoefficientEvaluations"] - before["CoefficientEvaluations"] + frontierWork,
      "UncachedFrontierCoefficientEvaluations" -> frontierWork,
      "TotalCachedCoefficientEvaluations" -> state["CoefficientEvaluations"],
      "NewCompleteWeightLayers" -> state["Layers"] - before["Layers"],
      "AvailablePolynomialPowers" -> before["PolynomialPowerCacheEntries"],
      "ReusedPolynomialPowerRequests" -> state["PolynomialPowerCacheHits"] - before["PolynomialPowerCacheHits"],
      "NewPolynomialPowerEvaluations" -> state["PolynomialPowerEvaluations"] - before["PolynomialPowerEvaluations"],
      "RetainedPolynomialPowers" -> state["PolynomialPowerCacheEntries"],
      "PolynomialPowerCacheCapacity" -> state["PolynomialPowerCacheCapacity"],
      "PolynomialPowerCacheEvictions" -> state["PolynomialPowerCacheEvictions"] -
        If[AssociationQ[Lookup[a, "ComputationState", None]], Lookup[a["ComputationState"], "PolynomialPowerCacheEvictions", 0], 0],
      "PolynomialPowerCountingScope" -> "Incremental coefficient generation only. Independent uncached frontier work is counted separately by UncachedFrontierCoefficientEvaluations.",
      "CachedThroughWeight" -> state["LastWeight"], "NextWeight" -> state["NextWeight"], "NewNewtonSteps" -> {}|>,
    {state, origin} = refinementNewtonSeed[a, limit, signature]; before = state;
    state = refineNewtonState[state, cut];
    blocks = jetUnitPower[state["UnitJet"], rint, cut, a["LogVariable"], a["Assumptions"], limit];
    region = indexRegion[m["Gaps"], cut, False, limit];
    {frontier, frontierWork} = refinementNewtonFrontier[region, m["Gaps"], m["Polynomials"], p, rint,
      a["LogVariable"], a["Assumptions"], limit];
    stats = <|"Strategy" -> "IncrementalNewton", "StateOrigin" -> origin,
      "NewtonPrecisionBefore" -> before["Precision"], "NewtonPrecisionAfter" -> state["Precision"],
      "NewNewtonSteps" -> Drop[state["StepCutoffs"], Length[before["StepCutoffs"]]],
      "RecordedPriorNewtonSteps" -> before["StepCutoffs"], "VerifiedNewtonResidual" -> True,
      "NewCoefficientEvaluations" -> frontierWork, "FrontierCoefficientEvaluations" -> frontierWork|>];
  stats = Join[stats, <|"SourceCutoff" -> a["Cutoff"], "RequestedCutoff" -> cutoff,
    "ModelReused" -> True, "ModelSignature" -> signature,
    "ReusedBlocks" -> Length[Select[a["Blocks"], less[#[[1]], cut] &]], "AvailableSourceBlocks" -> Length[a["Blocks"]],
    "CountingConvention" -> "ReusedCoefficientEvaluations counts available individual index contributions, reconstructed from the stored complete region when necessary; seeding does not reevaluate them. NewCoefficientEvaluations counts actual new Lagrange calls, including uncached frontier work. Newton reports new step cutoffs and independent frontier Euler evaluations. ReusedBlocks counts source blocks retained below the requested cutoff.",
    "Evidence" -> "Exact complete-block reuse and symbolic Newton residual invariants; no runtime claim is implied."|>];
  refinementAssemble[a, cutoff, blocks, frontier, state, stats]];
(* END SOURCE: src/Kernel/RefinementState.wl *)

(* BEGIN SOURCE: src/Kernel/SourceCoordinates.wl
   Source SHA256 (UTF-8/LF): d79d7d82152835aa5a804a9ab41a60ff77572f002b1a4135a7c0d19d917c0086 *)
(* Exact source charts, loaded in AsymptoticAnalysis`Private` after the series
   calculus. Each underlying inverse is for the chart variable itself; the
   requested original observable is reconstructed with transported precision. *)

$sourceCoordinateDepth = 0;

sourceLogChart[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, u, h, fu, phase},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"]; h = Unique["logSource$"];
  fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
  phase = Simplify[fu /. u -> Exp[-h], ass && h > 0];
  If[FreeQ[phase, h] || ! FreeQ[phase, Power[E, e_] /; ! FreeQ[e, h]], Return[$Failed, Module]];
  <|"Kind" -> "SourceExp", "Coordinate" -> coord, "ChartVariable" -> h,
    "ChartEndpoint" -> Infinity, "ChartDirection" -> "FromBelow", "Phase" -> phase,
    "SourceCoordinateExpression" -> -Log[coord["LocalVariable"]],
    "SourceTransformExpression" -> If[coord["Infinite"], coord["Sign"] Exp[h], x0 + coord["Sign"] Exp[-h]],
    "Scale" -> 1|>];

sourceExponentialChart[f_, x_, x0_, dir_, ass_, limit_] := Module[{coord, u, phase, ell, rows, active, side},
  If[! MemberQ[{Infinity, -Infinity}, x0] ||
    FreeQ[f, Power[b_, e_] /; FreeQ[b, x] && ! FreeQ[e, x]], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; side = coord["Sign"]; u = Unique["expSource$"]; ell = Unique["ell$"];
  phase = Simplify[f /. x -> -side Log[u], ass && u > 0];
  rows = parseFinite[phase, u, ell, ass];
  If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
  rows = jetMerge[rows, ell, ass];
  active = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
  If[active === {} || active[[1, 1]] === 0, Return[$Failed, Module]];
  <|"Kind" -> "SourceLog", "Coordinate" -> coord, "ChartVariable" -> u,
    "ChartEndpoint" -> 0, "ChartDirection" -> "FromAbove", "Phase" -> phase,
    "SourceCoordinateExpression" -> Exp[-side x], "SourceTransformExpression" -> -side Log[u],
    "Scale" -> 1|>];

sourceExactObservable[base_, expression_, limit_, certificate_] := Module[{d = seriesData[base, limit], s},
  s = seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> expression,
    "Jet" -> {{{0, 1}}, Infinity, 0}, "RemainderDerivativeOrder" -> Infinity|>], {"ExactSourceObservable", {base}}];
  GeneralizedSeries[Join[s[[1]], <|"ExactSourceCertificate" -> certificate|>]]];

sourceBaseDomain[base_] := Module[{a = base[[1]], y = base["Variable"]},
  Lookup[a, "TargetDomain", If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]/a["LeadingCoefficient"] > 0]];

sourceReconstruct[base_, chart_, r_, cutoff_, ass_, limit_] := Module[
  {coord = chart["Coordinate"], side, offset, coefficient, b = base, answer, exact, source, obs, d, powerResult, check, certificate},
  side = coord["Sign"]; offset = If[! coord["Infinite"] && r === 1, coord["Substitution"] /. coord["u"] -> 0, 0];
  exact = Which[base["Remainder"] === 0, Normal[base],
    TrueQ[Lookup[base[[1]], "ExactModel", False]] && ! TrueQ[Lookup[base[[1]], "LeadingCoreOnly", False]],
      Lookup[base[[1]], "ExactInverseExpression", Missing["NoExactInverse"]],
    True, Missing["NoExactInverse"]];
  certificate = <|"Type" -> If[base["Remainder"] === 0, "ExactInnerSeries", "ExactInnerInverse"],
    "Domain" -> sourceBaseDomain[base]|>;
  If[MissingQ[exact] && LeafCount[Normal[base]] <= 250 && LeafCount[chart["Phase"]] <= 200,
    check = Quiet[TimeConstrained[Simplify[(chart["Phase"] /. chart["ChartVariable"] -> Normal[base]) - base["Variable"],
      ass && sourceBaseDomain[base]], 2, $Failed]];
    If[check === 0, exact = Normal[base]; certificate = <|"Type" -> "SymbolicChartComposition",
      "ChartResidual" -> 0, "ChartInverse" -> Normal[base], "Domain" -> sourceBaseDomain[base]|>]];
  (* An exact chart inverse may be retained as an exact carrier. This also
     handles repeated exact logarithmic charts without a false finite-scale
     approximation to an exponentially amplified intermediate remainder. *)
  If[! MissingQ[exact],
    source = chart["SourceTransformExpression"] /. chart["ChartVariable"] -> exact;
    obs = Which[r === 1, source, coord["Infinite"], source^r,
      True, (source - (coord["Substitution"] /. coord["u"] -> 0))^r];
    obs = Simplify[obs, ass && sourceBaseDomain[base]];
    Return[sourceExactObservable[base, obs, limit, certificate], Module]];
  If[chart["Kind"] === "SourceExp",
    coefficient = If[coord["Infinite"], r, -r];
    b = seriesMake[Join[seriesData[base, limit], <|"Domain" -> sourceBaseDomain[base]|>], {"SourceBase", {base}}];
    answer = catch[seriesExp[seriesBinary["Multiply", b, seriesConstant[coefficient, b, limit], Automatic, limit], cutoff, limit]];
    If[FailureQ[answer], Return[answer, Module]];
    answer = seriesBinary["Multiply", answer, seriesConstant[side^r, answer, limit], Automatic, limit];
    If[offset =!= 0, d = seriesData[answer, limit];
      answer = seriesMake[Join[d, <|"Offset" -> d["Offset"] + offset|>], {"SourceOffset", {answer}, offset}]],
    answer = catch[seriesLog[base, cutoff, limit]]; If[FailureQ[answer], Return[answer, Module]];
    answer = seriesBinary["Multiply", answer, seriesConstant[-side, answer, limit], Automatic, limit];
    If[r =!= 1,
      powerResult = catch[seriesPower[answer, r, cutoff, limit]];
      If[FailureQ[powerResult] && MemberQ[{"LogarithmicLeadingPower", "UnsupportedScale"}, powerResult[[1]]],
        (* Keep the finite logarithmic approximation inside the exact observable
           carrier. Since x~c Log[w], its relative error is no larger than the
           absolute power-log remainder already available for x. *)
        d = seriesFlat[seriesData[answer, limit], limit];
        If[d === $Failed || d["Jet"][[1]] === {} || d["Jet"][[1, 1, 1]] =!= 0 ||
          ! less[0, d["Jet"][[2]]], Return[powerResult, Module]];
        obs = side^r (side Normal[answer])^r;
        answer = seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> obs,
          "Jet" -> {{{0, 1}}, d["Jet"][[2]], d["Jet"][[3]]}, "RemainderDerivativeOrder" -> 0|>],
          {"SourcePowerCarrier", {answer}, r}, cutoff],
        If[FailureQ[powerResult], Return[powerResult, Module]]; answer = powerResult]]];
  answer];

sourceCoordinateConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}], dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"], trunc = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   inputRem = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"], goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"], method = OptionValue[AsymptoticInverse, {opts}, Method],
   chart, coord, q = cutoff0, working, base, result, underlyingOptions, originalOptions, tries = 0,
   a, d, obs = Unique["observable$"], restore, positive, offset, coefficient, domain, exact, count, finalCut},
  If[$sourceCoordinateDepth >= 6, Return[$Failed, Module]];
  chart = sourceLogChart[f, x, x0, dir, ass, limit];
  If[chart === $Failed, chart = sourceExponentialChart[f, x, x0, dir, ass, limit]];
  If[chart === $Failed, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Source and target variables must be distinct, and the target must not occur in the forward expression."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Source-chart reconstruction needs an exponent cutoff in its recorded target coordinate."]];
  If[! MemberQ[{Automatic, None}, inputRem], fail["UnsupportedOption", "Transport an omitted forward remainder into the source chart before declaring it; source-coordinate inversion currently requires the explicit forward expression."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  coord = chart["Coordinate"];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["InvalidOption", "A noninteger observable power requires a positive real source branch."]];
  If[q === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive source-chart cutoff or SeriesTermGoal -> n."]]; q = Max[1, goal]];
  If[cutoff0 === Automatic && chart["Kind"] === "SourceLog" && !(IntegerQ[r] && r > 0),
    fail["UnsupportedTermGoal", "A non-polynomial power of a logarithmic source reconstruction retains its finite approximation as a carrier; request an explicit cutoff instead of a unit term count."]];
  If[! exactRealQ[q] || ! less[0, q], fail["InvalidCutoff", "A source-chart reconstruction cutoff must be a positive exact real number."]];
  originalOptions = withAssumptions[{opts}, ass];
  underlyingOptions = Select[originalOptions, ! MemberQ[{"Power", Direction, SeriesTermGoal, "Truncation"}, First[#]] &];
  If[method === "Lambert", underlyingOptions = DeleteCases[underlyingOptions, Rule[Method, _]]; AppendTo[underlyingOptions, Method -> "Lagrange"]];
  underlyingOptions = Join[underlyingOptions, {"Power" -> 1, Direction -> chart["ChartDirection"], "Truncation" -> "Exponent"}];
  working = q + 2;
  While[True,
    tries++;
    base = Block[{$sourceCoordinateDepth = $sourceCoordinateDepth + 1},
      inverseDispatch[chart["Phase"], chart["ChartVariable"], chart["ChartEndpoint"], y, working, Sequence @@ underlyingOptions]];
    If[FailureQ[base], Return[base, Module]];
    result = sourceReconstruct[base, chart, r, q, ass, limit];
    If[FailureQ[result],
      If[MemberQ[{"InsufficientObservablePrecision", "UnsupportedScale"}, result[[1]]],
        fail["InsufficientSourceReconstructionPrecision", "The chart inverse is not known to a vanishing absolute error in a representable scale. A finite logarithmic-depth approximation cannot be exponentiated at this accuracy.", <|"ChartFailure" -> result|>], Return[result, Module]]];
    d = seriesData[result, limit]; count = Length[d["Jet"][[1]]];
    If[result["Remainder"] === 0 ||
      (! less[d["Jet"][[2]], q] && (cutoff0 =!= Automatic || count >= goal)), Break[]];
    If[tries >= 8, fail["InsufficientOrder", "Source reconstruction did not reach the requested transported precision."]];
    working = 2 working + 1; If[cutoff0 === Automatic, q = 2 q + 1]];
  finalCut = q;
  If[cutoff0 === Automatic && count > goal, finalCut = d["Jet"][[1, goal + 1, 1]]; result = seriesMake[d, {"SourceReconstruction", {base}}, finalCut]];
  a = result[[1]]; offset = If[! coord["Infinite"] && r === 1, x0, 0];
  coefficient = If[coord["Infinite"], r, -r];
  restore = If[chart["Kind"] === "SourceExp", Log[(obs - offset)/coord["Sign"]^r]/coefficient,
    If[r === 1, Exp[-coord["Sign"] obs], Exp[-(obs/coord["Sign"]^r)^(1/r)]]];
  domain = ass && sourceBaseDomain[base];
  positive = If[chart["ChartEndpoint"] === 0, Normal[base] > 0, True];
  exact = If[a["Remainder"] === 0 && r === 1, a["Expression"], Missing["NonexactSourceReconstruction"]];
  GeneralizedSeries[Join[a, <|"Kind" -> "Inverse", "Scale" -> "Transformed", "CoordinateKind" -> chart["Kind"],
    "CoordinateSeries" -> base, "CoordinateSubstitution" -> {}, "ReconstructedSeries" -> result,
    "SourceCoordinateVariable" -> chart["ChartVariable"], "SourceCoordinateEndpoint" -> chart["ChartEndpoint"],
    "SourceCoordinateDirection" -> chart["ChartDirection"], "SourceCoordinateExpression" -> chart["SourceCoordinateExpression"],
    "SourceTransformExpression" -> chart["SourceTransformExpression"], "SourceScale" -> chart["Scale"],
    "ObservableToCoordinateVariable" -> obs, "ObservableToCoordinateExpression" -> restore,
    "TransformedFunction" -> chart["Phase"], "TargetCoordinateExpression" -> y,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "Limit" -> base["Limit"], "Power" -> r,
    "Assumptions" -> ass, "Cutoff" -> finalCut,
    "Method" -> "SourceCoordinates", "RequestedMethod" -> method, "Truncation" -> "Exponent", "InputRemainder" -> inputRem,
    "TargetDomain" -> domain && positive, "SourceDomain" -> coord["LocalVariable"] > 0,
    "LeadingCoefficient" -> base["LeadingCoefficient"], "LeadingPower" -> base["LeadingPower"],
    "ExactModel" -> Lookup[base[[1]], "ExactModel", False], "Model" -> Missing["SourceCoordinate"],
    "ExactInverseExpression" -> exact, "ExactObservableExpression" -> If[a["Remainder"] === 0, a["Expression"], Missing["NonexactObservable"]],
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[a["Blocks"]],
    "SeriesData" -> Missing["SourceCoordinate"],
    "Transformations" -> {<|"Type" -> chart["Kind"], "Expression" -> chart["SourceCoordinateExpression"],
      "InverseMap" -> chart["SourceTransformExpression"]|>},
    "Branch" -> "The selected real source branch reconstructed from the positive source chart; TargetDomain contains necessary coordinate conditions."|>]]];

sourceResidualJet[a_, cutoff_, limit_] := Module[
  {s = a["ReconstructedSeries"], d, exact, chartSeries, side, r = a["Power"], offset, coefficient,
   work = cutoff + 6, phaseSeries, pd, ell, ass, targetJet, normalizer, normalizerJet, result},
  d = seriesData[s, limit];
  (* Compose the displayed finite expression. Its stored approximation error
     is not an extra unknown in this formal residual calculation. *)
  d = Join[d, <|"Jet" -> {d["Jet"][[1]], Infinity, 0}, "RemainderDerivativeOrder" -> Infinity,
    "Domain" -> a["TargetDomain"]|>];
  side = Which[a["ExpansionPoint"] === -Infinity, -1, a["ExpansionPoint"] === Infinity, 1,
    a["Direction"] === "FromBelow", -1, True, 1];
  If[a["CoordinateKind"] === "SourceExp",
    offset = If[! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]] && r === 1, a["ExpansionPoint"], 0];
    d = Join[d, <|"Offset" -> (d["Offset"] - offset)/side^r,
      "Jet" -> pScale[d["Jet"], side^(-r), d["LogVariable"], seriesAss[d]]|>];
    exact = seriesMake[d, {"ResidualFinitePart", {s}}];
    chartSeries = seriesLog[exact, work, limit];
    coefficient = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], r, -r];
    chartSeries = seriesBinary["Multiply", chartSeries, seriesConstant[1/coefficient, chartSeries, limit], Automatic, limit],
    If[r =!= 1, fail["UnsupportedObservableResidual", "The exact source residual is available, but its fractional reconstruction requires logarithmic coefficient arithmetic for a jet-order check."]];
    exact = seriesMake[d, {"ResidualFinitePart", {s}}];
    chartSeries = seriesExp[seriesBinary["Multiply", exact, seriesConstant[-side, exact, limit], Automatic, limit], work, limit]];
  phaseSeries = AsymptoticAnalysis`SeriesObservable[chartSeries, a["TransformedFunction"], a["SourceCoordinateVariable"],
    "Cutoff" -> work, "MaxTerms" -> limit];
  If[FailureQ[phaseSeries], Throw[phaseSeries, $tag]];
  pd = seriesFlat[seriesData[phaseSeries, limit], limit];
  If[pd === $Failed, fail["UnsupportedResidualScale", "The reconstructed chart residual has no single power-log representation."]];
  ell = pd["LogVariable"]; ass = seriesAss[pd];
  targetJet = seriesExpressionJet[a["Variable"], pd, limit];
  normalizer = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], a["Variable"], a["Variable"] - a["Limit"]];
  normalizerJet = seriesExpressionJet[normalizer, pd, limit];
  If[targetJet === $Failed || normalizerJet === $Failed, fail["UnsupportedResidualScale", "The target normalization is outside the chart's power-log algebra."]];
  result = pAdd[pd["Jet"], pScale[targetJet, -1, ell, ass], ell, ass];
  result = pMul[result, fwdPower[normalizerJet, -1, Unique["w$"], ell, ass, work, limit], ell, ass, limit];
  result = seriesTrim[result, cutoff, ell, ass];
  If[less[result[[2]], cutoff], fail["InsufficientResidualPrecision", "Reconstruction precision did not reach the requested residual cutoff."]];
  <|"ZeroBelowCutoff" -> (result[[1]] === {}),
    "NormalizedResidual" -> seriesJetExpression[result, pd["ScaleVariable"], ell],
    "ResidualBlocks" -> result[[1]], "RelativeCutoff" -> cutoff,
    "ResidualVariable" -> pd["ScaleVariable"],
    "Normalization" -> "(F_chart(chart(returned observable))-y)/(y-limit), or division by y at an infinite target.",
    "Scope" -> "Formal composition of the returned finite observable, reconstructed in the exact source chart."|>];

sourceCoordinateResidual[a_, h_, limit_] := Module[{q, chartValue, raw, normalized, normalizer, ass, attempt},
  q = If[h === Automatic, a["Cutoff"], h];
  If[! exactRealQ[q] || ! less[0, q], fail["InvalidCutoff", "A source-chart residual cutoff must be a positive exact real number."]];
  ass = a["Assumptions"] && a["TargetDomain"] && Element[a["Variable"], Reals];
  chartValue = a["ObservableToCoordinateExpression"] /. a["ObservableToCoordinateVariable"] -> a["Expression"];
  raw = (a["TransformedFunction"] /. a["SourceCoordinateVariable"] -> chartValue) - a["Variable"];
  normalizer = If[MemberQ[{Infinity, -Infinity}, a["Limit"]], a["Variable"], a["Variable"] - a["Limit"]];
  normalized = Quiet[TimeConstrained[Simplify[raw/normalizer, ass], 2, raw/normalizer]];
  If[normalized === 0, Return[<|"ZeroBelowCutoff" -> True, "NormalizedResidual" -> 0,
    "ExactResidualExpression" -> 0, "ResidualBlocks" -> {}, "RelativeCutoff" -> q,
    "Scope" -> "Exact symbolic composition of the returned observable through the source chart."|>, Module]];
  attempt = catch[sourceResidualJet[a, q, limit]];
  If[FailureQ[attempt],
    If[attempt[[1]] === "ResourceLimit", Throw[attempt, $tag]];
    Return[<|"ZeroBelowCutoff" -> Missing["NotComputed"], "NormalizedResidual" -> normalized,
      "ExactResidualExpression" -> normalized, "RelativeCutoff" -> q,
      "FormalSeriesUnavailable" -> attempt,
      "Scope" -> "Exact residual expression of the returned observable; no power-log jet-order assertion is made for this reconstruction."|>, Module]];
  Join[attempt, <|"ExactResidualExpression" -> normalized, "OriginalFunction" -> a["Function"]|>]];

sourceCoordinateNumericalCheck[a_, yv_, wp_] := Module[
  {z = a["SourceCoordinateVariable"], y = a["Variable"], x = a["Variables"][[1]], yy, seed, zr, xr,
   approx, observed, error, scale, local, phase = a["TransformedFunction"], r = a["Power"]},
  If[! IntegerQ[wp] || wp < 10, fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[yv] || (! exactQ[yv] && Precision[yv] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  yy = yv;
  If[! TrueQ[N[a["TargetDomain"] /. y -> yy, wp + 10]], fail["OutsideBranch", "The target is outside the recorded real source-chart domain."]];
  seed = N[Normal[a["CoordinateSeries"]] /. y -> yy, wp + 10];
  zr = With[{zz = z, ff = phase, target = yy, start = seed, prec = wp + 10, goal = wp},
    Quiet[Check[zz /. FindRoot[ff == target, {zz, start}, WorkingPrecision -> prec,
      AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[zr === $Failed || ! NumericQ[zr], fail["RootNotFound", "The source-chart equation did not converge from its asymptotic seed."]];
  If[! TrueQ[Im[zr] == 0] || ! TrueQ[zr > 0], fail["OutsideBranch", "The numerical chart root is outside the selected positive source chart."]];
  xr = N[a["SourceTransformExpression"] /. z -> zr, wp + 10];
  local = Which[a["ExpansionPoint"] === Infinity, 1/xr, a["ExpansionPoint"] === -Infinity, -1/xr,
    a["Direction"] === "FromAbove", xr - a["ExpansionPoint"], True, a["ExpansionPoint"] - xr];
  If[! TrueQ[Im[xr] == 0] || ! TrueQ[local > 0], fail["OutsideBranch", "The reconstructed numerical root is outside the selected original source branch."]];
  approx = N[a["Expression"] /. y -> yy, wp + 10];
  observed = Which[r === 1, xr, MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], xr^r,
    True, (xr - a["ExpansionPoint"])^r];
  error = N[Abs[observed - approx], wp]; scale = N[a["RemainderScaleExpression"] /. y -> yy, wp];
  <|"ReferenceRoot" -> N[xr, wp], "ExactInverse" -> N[xr, wp], "ReferenceObservable" -> N[observed, wp],
    "Approximation" -> N[approx, wp], "Error" -> error, "RemainderScale" -> scale,
    "Ratio" -> If[TrueQ[scale == 0], Indeterminate, error/scale],
    "ChartRoot" -> N[zr, wp], "ChartResidual" -> N[(phase /. z -> zr) - yy, wp],
    "Evidence" -> "High-precision comparison in the exact source chart; no interval certificate."|>];
(* END SOURCE: src/Kernel/SourceCoordinates.wl *)

(* BEGIN SOURCE: src/Kernel/CorePerturbation.wl
   Source SHA256 (UTF-8/LF): db58afaeed4cda7b3e9f5dfaaf682465db1b2fcb9bdc0a0e61f00a7a43759b95 *)
(* Exact-core marker expansions with a proved asymptotic contract for finite
   power-log cores and higher-power perturbations. Loaded in Private`. *)

AsymptoticAnalysis`AsymptoticCoreInverse::usage =
"AsymptoticCoreInverse[core, perturbation, {x,x0}, {y,n}, \"CoreInverse\"->phi] expands the selected real inverse of core+perturbation through marker degree n while retaining the exact core inverse phi. Supported finite power-log data have a nonzero leading source power and perturbation exponents strictly larger than that leading power. The nonzero exact real option Power returns x for r=1, (x-x0)^r at finite endpoints for r!=1, and x^r at infinity; a negative source side requires integer r. Marker terms are not an exponent-sorted power-log jet; the result records a proved asymptotic remainder and a separate first omitted marker term. CoreInverse->Automatic recognizes monomial, affine-log-power, and divergent power-plus-log cores.";

Options[AsymptoticAnalysis`AsymptoticCoreInverse] = {
  Assumptions :> $Assumptions, Direction -> Automatic, "Power" -> 1, "CoreInverse" -> Automatic,
  "InputRemainder" -> None, "MaxTerms" -> 20000,
  "CoreCheckTimeConstraint" -> 3, "SourceRadius" -> 1/E};

corePerturbationRealPolynomialQ[p_, ell_, ass_] := realPolynomialQ[p, ell, ass];

corePerturbationModel[core_, perturbation_, x_, coord_, ell_, ass_] := Module[
  {u = coord["u"], f0, rr, rows, remainderRows, offset, nonconstant,
   p, q, a, polynomial, gaps, d, b, simple, powerPlusLog, logarithmicCoefficient},
  f0 = Simplify[core /. x -> coord["Substitution"], ass && u > 0];
  rr = Simplify[perturbation /. x -> coord["Substitution"], ass && u > 0];
  rows = parseFinite[f0, u, ell, ass];
  remainderRows = parseFinite[rr, u, ell, ass];
  If[rows === $Failed || remainderRows === $Failed,
    fail["UnsupportedCorePerturbation", "The core and perturbation must be finite power-log expressions in the positive source coordinate."]];
  rows = jetMerge[rows, ell, ass]; remainderRows = jetMerge[remainderRows, ell, ass];
  If[! And @@ (exactRealQ[#[[1]]] && corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ Join[rows, remainderRows]),
    fail["UnprovedCoreData", "Exponents must be exact real numbers and every coefficient must be provably real."]];
  offset = Total[Cases[rows, {0, c_} :> Coefficient[c, ell, 0]]];
  nonconstant = jetMerge[({#[[1]], If[#[[1]] === 0, #[[2]] - offset, #[[2]]]} & /@ rows), ell, ass];
  If[nonconstant === {}, fail["ConstantCore", "A constant core has no local inverse."]];
  {p, polynomial} = First[nonconstant];
  If[p === 0, fail["UnsupportedCorePerturbation", "A purely logarithmic leading core needs a separate error-transport contract."]];
  q = polyDegree[polynomial, ell]; a = Coefficient[polynomial, ell, q];
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]),
    fail["UnprovedSign", "The eventual core sign must be provable from its leading logarithmic coefficient."]];
  gaps = canon[#[[1]] - p] & /@ remainderRows;
  If[! And @@ (less[0, #] & /@ gaps),
    fail["NonSmallCorePerturbation", "Every perturbation exponent must be strictly larger than the core's leading source exponent."]];
  d = If[remainderRows === {}, 0, Max[0, Max[polyDegree[#[[2]], ell] & /@ remainderRows] - q]];
  b = If[q === 0, 0, Simplify[Coefficient[polynomial, ell, q - 1]/(q a), ass]];
  simple = Length[nonconstant] === 1 && polyZeroQ[polynomial - a (ell + b)^q, ell, ass];
  logarithmicCoefficient = Total[Cases[nonconstant, {0, c_} :> Coefficient[c, ell, 1]]];
  powerPlusLog = less[p, 0] && q === 0 && Length[nonconstant] === 2 &&
    Last[nonconstant][[1]] === 0 &&
    polyZeroQ[Last[nonconstant][[2]] - logarithmicCoefficient ell, ell, ass] &&
    (provablyPositive[a p/logarithmicCoefficient, ass] || provablyNegative[a p/logarithmicCoefficient, ass]);
  <|"CoreLocal" -> f0, "PerturbationLocal" -> rr, "CoreRows" -> rows,
    "PerturbationRows" -> remainderRows, "Offset" -> offset, "LeadingPower" -> p,
    "LeadingLogDegree" -> q, "LeadingCoefficient" -> a,
    "Amplitude" -> Simplify[a (-1)^q, ass], "AffineLogShift" -> b,
    "AutomaticCore" -> (simple || powerPlusLog),
    "AutomaticCoreType" -> Which[simple, "MonomialOrAffineLogPower", powerPlusLog, "PowerPlusLog", True, Missing["UserCore"]],
    "AdditiveLogCoefficient" -> logarithmicCoefficient, "Gaps" -> gaps,
    "MinimumGap" -> If[gaps === {}, Infinity, Min[gaps]], "RelativeLogDegree" -> d|>];

corePerturbationAutomaticInverse[model_, coord_, y_, x0_, ass_] := Module[
  {p = model["LeadingPower"], q = model["LeadingLogDegree"], a = model["LeadingCoefficient"],
   amp = model["Amplitude"], b = model["AffineLogShift"], v, u0, k, branch, argument, phi, d},
  If[! TrueQ[model["AutomaticCore"]], Return[$Failed, Module]];
  v = y - model["Offset"];
  If[model["AutomaticCoreType"] === "PowerPlusLog",
    d = model["AdditiveLogCoefficient"]/p; k = a/d;
    branch = If[provablyPositive[k, ass], 0, -1];
    argument = k Exp[v/d];
    u0 = (ProductLog[branch, argument]/k)^(1/p),
  If[q === 0,
    u0 = (v/a)^(1/p); branch = Missing["Monomial"]; argument = Missing["Monomial"],
    k = -p/q; branch = If[less[0, k], 0, -1];
    argument = k (v/amp)^(1/q) Exp[p b/q];
    u0 = (v/amp)^(1/p) (ProductLog[branch, argument]/k)^(-q/p)]];
  phi = If[coord["Infinite"], coord["Sign"]/u0, x0 + coord["Sign"] u0];
  <|"Inverse" -> phi, "LocalInverse" -> u0, "LambertBranch" -> branch,
    "LambertArgument" -> argument,
    "Certificate" -> <|"Type" -> "RecognizedExactCore", "CoreIdentity" -> True,
      "CoreType" -> model["AutomaticCoreType"],
      "BranchConstruction" -> If[MatchQ[branch, _Missing], "Positive monomial root", "Real Lambert branch with positive source coordinate tending to zero"]|>|>];

corePerturbationChooseInverse[model_, requested_, core_, x_, x0_, y_, coord_, ass_, radius_, seconds_] := Module[
  {automatic, phi, u0, u = coord["u"], identity, comparison, certificate, conditions},
  automatic = corePerturbationAutomaticInverse[model, coord, y, x0, ass];
  If[requested === Automatic,
    If[automatic === $Failed, fail["CoreInverseRequired", "Supply an exact CoreInverse for this core; automatic inversion recognizes monomial, affine-log-power, and divergent power-plus-log cores."]];
    Return[automatic, Module]];
  If[! FreeQ[requested, x] || ! exactQ[requested] || ! FreeQ[requested, Indeterminate | _DirectedInfinity],
    fail["InvalidCoreInverse", "CoreInverse must be an exact finite expression in the target and parameters, independent of the source symbol."]];
  phi = requested;
  If[automatic =!= $Failed,
    comparison = Quiet[TimeConstrained[FullSimplify[phi == automatic["Inverse"],
      ass && (y - model["Offset"])/model["Amplitude"] > 0], seconds, $Failed]];
    If[TrueQ[comparison], Return[Join[automatic, <|"Inverse" -> phi,
      "LocalInverse" -> If[coord["Infinite"], coord["Sign"]/phi, coord["Sign"] (phi - x0)]|>], Module]]];
  conditions = ass && 0 < u < radius;
  identity = Quiet[TimeConstrained[FullSimplify[
    (phi /. y -> model["CoreLocal"]) == coord["Substitution"], conditions], seconds, $Failed]];
  If[! TrueQ[identity],
    fail["UnverifiedCoreInverse", "The supplied inverse could not be proved to recover the selected source branch under the stated source-radius assumptions.",
      <|"Identity" -> identity, "SourceAssumptions" -> conditions|>]];
  u0 = If[coord["Infinite"], coord["Sign"]/phi, coord["Sign"] (phi - x0)];
  certificate = <|"Type" -> "SymbolicLeftInverse", "CoreIdentity" -> True,
    "SourceAssumptions" -> conditions, "SourceRadius" -> radius,
    "CheckedIdentity" -> HoldForm[phi /. y -> model["CoreLocal"]]|>;
  <|"Inverse" -> phi, "LocalInverse" -> u0, "Certificate" -> certificate,
    "LambertBranch" -> Missing["UserCore"], "LambertArgument" -> Missing["UserCore"]|>];

corePerturbationTerm[n_, rlocal_, hprime_, fprime_, u_, limit_] := Module[{term, j},
  term = Together[hprime rlocal^n/fprime];
  Do[
    term = Together[D[term, u]/fprime];
    If[LeafCount[term] > limit, fail["ResourceLimit", "An exact-core derivative exceeded MaxTerms expression leaves."]],
    {j, 1, n - 1}];
  term = (-1)^n term/n!;
  If[LeafCount[term] > limit, fail["ResourceLimit", "An exact-core marker coefficient exceeded MaxTerms expression leaves."]];
  term];

corePerturbationConstruct[core_, perturbation_, x_, x0_, y_, depth_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticCoreInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}],
   dir = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, Direction],
   r = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "Power"],
   requested = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "CoreInverse"],
   input = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "InputRemainder"],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "MaxTerms"],
   seconds = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "CoreCheckTimeConstraint"],
   radius = OptionValue[AsymptoticAnalysis`AsymptoticCoreInverse, {opts}, "SourceRadius"],
   coord, u, ell = Unique["ell$"], model, inverse, phi, u0, fp, hp, localTerms, markerTerms,
   expression, firstOmitted, n, p, q, delta, degree, rint, pd, truncationPair,
   inputPair = None, rho, logdegree, domain, side, targetLimit, rem, scale,
   exactPerturbation, majorant, sourceAssumptions, observable, coreObservable},
  validateInput[core + perturbation, limit];
  If[x === y || ! FreeQ[core + perturbation, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the forward data."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters; the source branch is specified by endpoint and direction."]];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "The marker depth must be a nonnegative integer."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[depth + 1 > limit, fail["ResourceLimit", "Marker depth and its first omitted coefficient exceed MaxTerms."]];
  If[! NumericQ[seconds] || ! TrueQ[seconds > 0] || ! exactRealQ[radius] || ! less[0, radius],
    fail["InvalidOption", "CoreCheckTimeConstraint and the exact real SourceRadius must be positive."]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  If[coord["Sign"] =!= 1 && ! IntegerQ[r],
    fail["InvalidOption", "A noninteger Power requires a positive source displacement at a finite endpoint, or the positive infinite endpoint."]];
  model = corePerturbationModel[core, perturbation, x, coord, ell, ass];
  inverse = corePerturbationChooseInverse[model, requested, core, x, x0, y, coord, ass, radius, seconds];
  phi = inverse["Inverse"]; u0 = inverse["LocalInverse"];
  {p, q, delta, degree} = Lookup[model, {"LeadingPower", "LeadingLogDegree", "MinimumGap", "RelativeLogDegree"}];
  rint = If[coord["Infinite"], -r, r];
  observable = If[r === 1, coord["Substitution"], coord["Sign"]^r u^rint];
  coreObservable = If[r === 1, phi, coord["Sign"]^r u0^rint];
  exactPerturbation = model["PerturbationRows"] === {};
  fp = D[model["CoreLocal"], u]; hp = D[observable, u];
  localTerms = If[exactPerturbation, {}, Table[
    {n, corePerturbationTerm[n, model["PerturbationLocal"], hp, fp, u, limit]}, {n, 1, depth + 1}]];
  markerTerms = Join[{{0, coreObservable}}, ({#[[1]], #[[2]] /. u -> u0} & /@ Take[localTerms, UpTo[depth]])];
  expression = Total[markerTerms[[All, 2]]];
  firstOmitted = If[exactPerturbation, 0, localTerms[[-1, 2]] /. u -> u0];
  truncationPair = If[exactPerturbation, {Infinity, 0},
    {canon[rint + (depth + 1) delta], (depth + 1) degree}];
  pd = truncationPair;
  If[! MemberQ[{None, Automatic}, input],
    If[! MatchQ[input, {_, _Integer?NonNegative}] || ! exactRealQ[input[[1]]] || ! less[p, input[[1]]],
      fail["InvalidInputRemainder", "InputRemainder must be {rho,k}, with exact real rho larger than the core leading power and nonnegative integer k; a matching derivative bound is required."]];
    {rho, logdegree} = input;
    inputPair = {canon[rint + rho - p], Max[0, logdegree - q]};
    pd = combinePrecision[pd, inputPair]];
  side = If[provablyPositive[model["Amplitude"], ass], 1, -1];
  targetLimit = If[less[0, p], model["Offset"], side Infinity];
  domain = ass && (y - model["Offset"])/model["Amplitude"] > 0 &&
    Element[u0, Reals] && 0 < u0 < radius;
  If[inverse["LambertBranch"] === -1,
    domain = domain && -1/E <= inverse["LambertArgument"] < 0];
  rem = If[pd[[1]] === Infinity, 0, PowerLogRemainder[u0, pd[[1]], pd[[2]]]];
  scale = If[rem === 0, 0, u0^pd[[1]] (1 + Abs[Log[u0]])^pd[[2]]];
  majorant = <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
    "RelativeSmallScale" -> If[exactPerturbation, 0, u0^delta (1 + Abs[Log[u0]])^degree],
    "Statement" -> "For fixed data there are C,K>0 and a source threshold such that the omitted marker tail is bounded by C u0^rint (K chi)^(n+1)/(1-K chi) whenever K chi<1. The constants and threshold are not computed numerical bounds.",
    "LocalObservablePower" -> rint, "MarkerDepth" -> depth,
    "Justification" -> "Joint analytic implicit function theorem in reciprocal logarithm, fixed core parameters and finite higher-power perturbation parameters."|>;
  sourceAssumptions = ass && 0 < u < radius;
  GeneralizedSeries[<|"Kind" -> "CoreInverse", "Scale" -> "ExactCorePerturbation",
    "Expression" -> expression, "Variable" -> y, "Variables" -> {x, y},
    "Function" -> core + perturbation, "Core" -> core, "Perturbation" -> perturbation,
    "CoreInverse" -> phi, "CoreLocalInverse" -> u0, "CoreCertificate" -> inverse["Certificate"],
    "CoreObservableExpression" -> coreObservable, "LocalObservableExpression" -> observable,
    "LocalObservablePower" -> rint,
    "ObservableExpression" -> If[r === 1, x, If[coord["Infinite"], x^r, (x - x0)^r]],
    "ObservableConvention" -> "Power 1 returns the source x; any other power returns (x-x0)^r at a finite endpoint and x^r at an infinite endpoint.",
    "CoreModel" -> model, "MarkerTerms" -> markerTerms, "Terms" -> markerTerms,
    "LocalMarkerTerms" -> localTerms, "FirstOmittedMarkerTerm" -> firstOmitted,
    "FirstOmittedMarkerDegree" -> depth + 1, "MarkerDepth" -> depth,
    "TermConvention" -> "Each {n,c} is one complete coefficient of the perturbation marker lambda^n, evaluated at lambda=1; these coefficients are not exponent-sorted power-log blocks.",
    "Remainder" -> rem, "RemainderScaleExpression" -> scale,
    "RemainderVariable" -> u0, "RemainderPower" -> pd[[1]], "RemainderLogDegree" -> pd[[2]],
    "TruncationRemainderPair" -> truncationPair, "InputRemainderPair" -> inputPair,
    "InputRemainder" -> input, "MajorantContract" -> majorant,
    "RemainderExplanation" -> "The analytic marker majorant bounds the complete omitted tail independently of cancellation in the first omitted coefficient. A declared input remainder is separately transported and may coarsen the bound.",
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "LocalVariable" -> u,
    "LocalSubstitution" -> (x -> coord["Substitution"]), "Limit" -> targetLimit,
    "TargetDomain" -> domain, "SourceAssumptions" -> sourceAssumptions,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> model["Amplitude"],
    "ExactModel" -> MemberQ[{None, Automatic}, input], "ExactInverse" -> (rem === 0),
    "Truncation" -> "Depth", "Power" -> r, "Cutoff" -> Missing["MarkerDepth"],
    "SeriesData" -> Missing["ExactCoreMarkerScale"],
    "RemainderDerivativeOrder" -> 0|>]];

AsymptoticAnalysis`AsymptoticCoreInverse[core_, perturbation_, {x_Symbol, x0_}, {y_Symbol, depth_},
  opts : OptionsPattern[]] := catch[corePerturbationConstruct[core, perturbation, x, x0, y, depth, opts]];
AsymptoticAnalysis`AsymptoticCoreInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticCoreInverse[core, perturbation, {x,x0}, {y,depth}, CoreInverse->phi], with CoreInverse written as a string option."|>];
(* END SOURCE: src/Kernel/CorePerturbation.wl *)

(* BEGIN SOURCE: src/Kernel/InverseCertificates.wl
   Source SHA256 (UTF-8/LF): d01d9efa24865548b96876f9fddce752584e73285caf3dc87521a3a2cf93eedc *)
(* Exact rational residual certificates. Decimal arithmetic is used only to
   choose a center; every successful proof uses rational interval endpoints. *)

certFail[tag_, message_, data_: <||>] := fail[tag, message, Join[<|"Certified" -> False|>, data]];
certRationalQ[q_] := IntegerQ[q] || Head[q] === Rational;

(* Directed rounding to a dyadic grid with a fixed number of significant bits.
   Floor and Ceiling act on exact rationals. No floating-point predicate enters
   interval arithmetic or the final containment test. *)
certRound[q_, bits_, upper_] := Module[{a, exponent, grid},
  If[q === 0, Return[0, Module]];
  a = Abs[q];
  exponent = IntegerLength[Numerator[a], 2] - IntegerLength[Denominator[a], 2];
  If[a < 2^exponent, exponent--];
  grid = 2^(exponent - bits + 1);
  grid If[upper, Ceiling[q/grid], Floor[q/grid]]];
certRoundInterval[{lo_, hi_}, ctx_] :=
  {certRound[lo, ctx["Bits"], False], certRound[hi, ctx["Bits"], True]};
certAdd[a_, b_, ctx_] := certRoundInterval[a + b, ctx];
certNeg[{lo_, hi_}] := {-hi, -lo};
certMul[a_, b_, ctx_] := Module[{products = Flatten[Outer[Times, a, b]]},
  certRoundInterval[{Min[products], Max[products]}, ctx]];
certReciprocal[{lo_, hi_}, ctx_] := (
  If[lo <= 0 <= hi, certFail["IntervalSingularity", "An interval reciprocal contains zero.",
    <|"UnprovedCondition" -> (hi < 0 || lo > 0), "ArgumentEnclosure" -> {lo, hi}|>]];
  certRoundInterval[{1/hi, 1/lo}, ctx]);
certIntegerPower[a_, n_Integer, ctx_] := Module[{base = a, power = Abs[n], answer = {1, 1}},
  If[power > 100000, certFail["CertificateResourceLimit", "The integer power exceeds the certificate arithmetic budget."]];
  If[n < 0, base = certReciprocal[base, ctx]];
  While[power > 0,
   If[OddQ[power], answer = certMul[answer, base, ctx]];
   power = Quotient[power, 2];
   If[power > 0,
    (* Squaring a real interval is tighter than multiplying independent copies. *)
    base = certRoundInterval[If[base[[1]] <= 0 <= base[[2]],
       {0, Max[base[[1]]^2, base[[2]]^2]}, Sort[base^2]], ctx]]];
  answer];

certExpPoint[q_?certRationalQ, ctx_] := Module[{z, reductions = 0, n, sum, tail, answer},
  If[q === 0, Return[{1, 1}, Module]];
  If[Abs[q] > ctx["ExponentMagnitudeLimit"],
   certFail["CertificateResourceLimit", "The exponential argument exceeds the exact enclosure budget; use a logarithmic phase when available.",
    <|"Argument" -> q, "ExponentMagnitudeLimit" -> ctx["ExponentMagnitudeLimit"]|>]];
  If[q < 0, Return[certReciprocal[certExpPoint[-q, ctx], ctx], Module]];
  z = q;
  While[z > 1/2, z /= 2; reductions++];
  n = ctx["SeriesOrder"];
  sum = Sum[z^k/k!, {k, 0, n}];
  tail = z^(n + 1)/(n + 1)!/(1 - z/(n + 2));
  answer = certRoundInterval[{sum, sum + tail}, ctx];
  Do[answer = certIntegerPower[answer, 2, ctx], {reductions}];
  answer];
certExp[a_, ctx_] := {certExpPoint[a[[1]], ctx][[1]], certExpPoint[a[[2]], ctx][[2]]};

certLogUnit[q_?certRationalQ, ctx_] := Module[{u, n, sum, tail},
  If[q === 1, Return[{0, 0}, Module]];
  u = (q - 1)/(q + 1); n = ctx["SeriesOrder"];
  (* This helper is used only for 1 <= q <= 2, hence 0 <= u <= 1/3. *)
  sum = 2 Sum[u^(2 k + 1)/(2 k + 1), {k, 0, n - 1}];
  tail = 2 u^(2 n + 1)/((2 n + 1) (1 - u^2));
  certRoundInterval[{sum, sum + tail}, ctx]];
certLogPoint[q_?certRationalQ, ctx_] := Module[{exponent, z, unit, logTwo},
  If[q <= 0, certFail["IntervalDomain", "A logarithm argument is not strictly positive.",
    <|"UnprovedCondition" -> (q > 0), "Argument" -> q|>]];
  If[q === 1, Return[{0, 0}, Module]];
  exponent = IntegerLength[Numerator[q], 2] - IntegerLength[Denominator[q], 2];
  If[q < 2^exponent, exponent--];
  z = q/2^exponent;
  unit = certLogUnit[z, ctx];
  If[exponent === 0, Return[unit, Module]];
  logTwo = certLogUnit[2, ctx];
  certAdd[unit, certMul[{exponent, exponent}, logTwo, ctx], ctx]];
certLog[a_, ctx_] := (
  If[a[[1]] <= 0, certFail["IntervalDomain", "The logarithm enclosure reaches a nonpositive argument.",
    <|"UnprovedCondition" -> (a[[1]] > 0), "ArgumentEnclosure" -> a|>]];
  {certLogPoint[a[[1]], ctx][[1]], certLogPoint[a[[2]], ctx][[2]]});

(* Apply logarithmic identities only after each factor has acquired a real
   logarithm enclosure. No unrestricted PowerExpand is used. *)
certLogExpression[argument_, x_, interval_, ctx_] := Module[{candidate},
  If[argument === E, Return[{1, 1}, Module]];
  If[Head[argument] === Power && argument[[1]] === E,
   Return[certEnclose[argument[[2]], x, interval, ctx], Module]];
  If[Head[argument] === Times,
   candidate = catch[Fold[certAdd[#1, #2, ctx] &, {0, 0},
      certLogExpression[#, x, interval, ctx] & /@ (List @@ argument)]];
   If[ListQ[candidate], Return[candidate, Module]]];
  If[Head[argument] === Power,
   candidate = catch[certMul[certEnclose[argument[[2]], x, interval, ctx],
      certLogExpression[argument[[1]], x, interval, ctx], ctx]];
   If[ListQ[candidate], Return[candidate, Module]]];
  (* A positive product can have negative factors: retain the direct route. *)
  certLog[certEnclose[argument, x, interval, ctx], ctx]];

certEnclose[expression_, x_Symbol, interval_, ctx_] := Module[{args, base, exponent, upper},
  Which[
   expression === x, interval,
   certRationalQ[expression], {expression, expression},
   expression === E, certExpPoint[1, ctx],
   Head[expression] === Plus,
    Fold[certAdd[#1, #2, ctx] &, {0, 0}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)],
   Head[expression] === Times,
    Fold[certMul[#1, #2, ctx] &, {1, 1}, certEnclose[#, x, interval, ctx] & /@ (List @@ expression)],
   Head[expression] === Log && Length[expression] == 1,
    certLogExpression[expression[[1]], x, interval, ctx],
   Head[expression] === Log && Length[expression] == 2,
    certMul[certLogExpression[expression[[2]], x, interval, ctx],
     certReciprocal[certLogExpression[expression[[1]], x, interval, ctx], ctx], ctx],
   Head[expression] === Power && expression[[1]] === E,
    certExp[certEnclose[expression[[2]], x, interval, ctx], ctx],
   Head[expression] === Power && IntegerQ[expression[[2]]],
    certIntegerPower[certEnclose[expression[[1]], x, interval, ctx], expression[[2]], ctx],
   Head[expression] === Power,
    base = certEnclose[expression[[1]], x, interval, ctx];
    exponent = certEnclose[expression[[2]], x, interval, ctx];
    If[base[[1]] === 0 && certRationalQ[expression[[2]]] && expression[[2]] > 0,
     If[base[[2]] === 0, {0, 0},
      upper = certExp[certMul[exponent, certLog[{base[[2]], base[[2]]}, ctx], ctx], ctx];
      {0, upper[[2]]}],
     If[base[[1]] <= 0,
      certFail["IntervalDomain", "A noninteger real power needs a strictly positive base on the certificate interval.",
       <|"UnprovedCondition" -> (base[[1]] > 0), "ArgumentEnclosure" -> base|>]];
     certExp[certMul[exponent, certLog[base, ctx], ctx], ctx]],
   True, certFail["UnsupportedEnclosure", "The exact interval evaluator does not support this expression.",
     <|"Expression" -> expression, "SupportedOperations" -> {"Rational constants", "Plus", "Times", "Power on a positive base", "Exp", "Log"}|>]]];

(* Conditions may use an explicitly named source symbol or a legacy local
   coordinate. Normalize both to the source variable used by the equation.
   The logarithmic hierarchy stores its domain in LocalVariable; its inverse
   chart is the same real local coordinate recorded by the constructor. *)
inverseEvidenceSourceVariable[a_] := Module[{variables, source},
  source = Lookup[a, "SourceVariable", Missing["NotSpecified"]];
  If[MatchQ[source, _Symbol], Return[source, Module]];
  variables = Lookup[a, "Variables", {}];
  If[MatchQ[variables, {_Symbol, _Symbol}], First[variables], Lookup[a, "Variable", source]]];

inverseEvidenceSourceDomain[a_, x_] := Module[
  {condition = Lookup[a, "SourceDomain", True], source, local, coordinate, endpoint, direction},
  source = inverseEvidenceSourceVariable[a];
  If[MatchQ[source, _Symbol] && source =!= x, condition = condition /. source -> x];
  local = Lookup[a, "LocalVariable", Missing["NotSpecified"]];
  If[MatchQ[local, _Symbol] && local =!= x && ! FreeQ[condition, local],
    endpoint = Lookup[a, "ExpansionPoint", Missing["NotSpecified"]];
    direction = Lookup[a, "Direction", "FromAbove"];
    coordinate = Which[endpoint === Infinity, 1/x, endpoint === -Infinity, -1/x,
      direction === "FromBelow", endpoint - x, True, x - endpoint];
    condition = condition /. local -> coordinate];
  condition];

(* Prove a Boolean domain on the entire CLOSED verification interval.
   Strict inequalities therefore exclude equality at either endpoint. Real
   source identities (Im[x]==0, Element[x,Reals]) are simplified exactly;
   the remaining comparisons use outward rational interval bounds. An
   unrecognized predicate is unproved, never silently discarded. *)
certPositiveCondition[condition_, x_, interval_, ctx_] := Module[{c, bound, parts, relation, proof, difference},
  c = TimeConstrained[Quiet[Refine[condition, Element[x, Reals]]], 1, condition];
  Which[c === True, True, c === False, False,
   Head[c] === And, And @@ (certPositiveCondition[#, x, interval, ctx] & /@ List @@ c),
   Head[c] === Or,
    AnyTrue[List @@ c, TrueQ[catch[certPositiveCondition[#, x, interval, ctx]]] &],
   Head[c] === Not,
    parts = First[c];
    relation = Switch[Head[parts], Greater, LessEqual, GreaterEqual, Less,
      Less, GreaterEqual, LessEqual, Greater, Equal, Unequal, Unequal, Equal, _, None];
    If[relation === None || Length[parts] =!= 2, False,
      certPositiveCondition[Apply[relation, parts], x, interval, ctx]],
   Head[c] === Inequality,
    parts = List @@ c;
    And @@ Table[certPositiveCondition[parts[[i + 1]][parts[[i]], parts[[i + 2]]],
      x, interval, ctx], {i, 1, Length[parts] - 2, 2}],
   MemberQ[{Greater, GreaterEqual, Less, LessEqual, Equal, Unequal}, Head[c]] && Length[c] >= 2,
    relation = Head[c]; parts = List @@ c;
    If[Length[parts] > 2,
      Return[If[relation === Unequal,
        And @@ (certPositiveCondition[Apply[relation, #], x, interval, ctx] & /@ Subsets[parts, {2}]),
        And @@ (certPositiveCondition[Apply[relation, #], x, interval, ctx] & /@ Partition[parts, 2, 1])], Module]];
    difference = Expand[parts[[1]] - parts[[2]]];
    (* Preserve exact contact with a rational interval endpoint. Rounding
       the two sides of x-a independently loses the equality at x=a,
       regardless of precision; an affine range is attained at endpoints. *)
    proof = If[PolynomialQ[difference, x] && Exponent[difference, x] <= 1 &&
        And @@ (certRationalQ /@ CoefficientList[difference, x]),
      Sort[(difference /. x -> #) & /@ interval],
      catch[certEnclose[difference, x, interval, ctx]]];
    If[! MatchQ[proof, {_, _}], Return[False, Module]];
    bound = proof;
    Switch[relation, Greater, bound[[1]] > 0, GreaterEqual, bound[[1]] >= 0,
      Less, bound[[2]] < 0, LessEqual, bound[[2]] <= 0,
      Equal, bound === {0, 0}, Unequal, bound[[1]] > 0 || bound[[2]] < 0],
   True, False]];

certSourceInterval[a_, interval_, x_, ctx_] := Module[{endpoint, side},
  Which[a["ExpansionPoint"] === Infinity, interval[[1]] > 0,
   a["ExpansionPoint"] === -Infinity, interval[[2]] < 0,
   True,
    endpoint = certEnclose[a["ExpansionPoint"], x, interval, ctx];
    If[a["Direction"] === "FromBelow", interval[[2]] < endpoint[[1]], interval[[1]] > endpoint[[2]]]]];

certSeed[a_, yv_, wp_] := Module[{value, power, side, endpoint},
  value = Quiet[Check[N[a["Expression"] /. a["Variable"] -> yv, wp], $Failed]];
  If[value === $Failed || ! NumericQ[value] || ! TrueQ[Im[value] == 0], Return[$Failed, Module]];
  power = Lookup[a, "Power", 1];
  If[power =!= 1,
   side = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
     a["Direction"] === "FromBelow", -1, True, 1];
   endpoint = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], 0, a["ExpansionPoint"]];
   value = N[endpoint + side Abs[value]^(1/power), wp]];
  If[NumericQ[value] && TrueQ[Im[value] == 0], Rationalize[Re[value], 0], $Failed]];

certRefinedSeed[a_, yv_, iteration_, wp_] := Module[{s, goal, x, y, options},
  x = a["Variables"][[1]]; y = a["Variable"];
  If[Lookup[a, "Kind", None] === "CoreInverse",
   s = Quiet[TimeConstrained[catch[AsymptoticAnalysis`AsymptoticCoreInverse[
       a["Core"], a["Perturbation"], {x, a["ExpansionPoint"]}, {y, a["MarkerDepth"] + iteration},
       "CoreInverse" -> a["CoreInverse"], Assumptions -> Lookup[a, "Assumptions", True],
       Direction -> a["Direction"], "InputRemainder" -> Lookup[a, "InputRemainder", None],
       "SourceRadius" -> Lookup[a["CoreCertificate"], "SourceRadius", 1/E],
       "CoreCheckTimeConstraint" -> 1]], 5, $Failed]];
   Return[If[MatchQ[s, _GeneralizedSeries], certSeed[s[[1]], yv, wp], $Failed], Module]];
  goal = Max[2, Lookup[a, "ReturnedTermCount", 1] + 2 iteration];
  options = {Assumptions -> Lookup[a, "Assumptions", True], Direction -> a["Direction"],
    Method -> If[Lookup[a, "Method", "Lagrange"] === "Lambert", "Lagrange", a["Method"]],
    "Power" -> 1, SeriesTermGoal -> goal};
  s = Quiet[TimeConstrained[catch[AsymptoticInverse[a["Function"], {x, a["ExpansionPoint"]}, y,
      Sequence @@ options]], 5, $Failed]];
  If[MatchQ[s, _GeneralizedSeries], certSeed[s[[1]], yv, wp], $Failed]];

certAttempt[a_, function_, target_, x_, interval_, center_, ctx_, route_, knownRoot_: False] := Module[
  {forward, derivative, derivativeExpression, residual, epsilon, mu, radius, bracket, correction, sharp, domain,
   leftResidual, rightResidual, endpointBracket = False},
  If[! certSourceInterval[a, interval, x, ctx],
   certFail["OutsideBranch", "The certificate interval is not proved to lie on the selected source side.",
    <|"Interval" -> interval, "ExpansionPoint" -> a["ExpansionPoint"], "Direction" -> a["Direction"]|>]];
  domain = inverseEvidenceSourceDomain[a, x];
  If[! TrueQ[certPositiveCondition[domain, x, interval, ctx]],
   certFail["OutsideBranch", "The retained source-domain condition is not proved on the whole closed verification interval.",
    <|"UnprovedCondition" -> domain, "Interval" -> interval,
      "ConditionScope" -> "EntireClosedVerificationInterval"|>]];
  (* Successful structural evaluation also proves continuity on this interval. *)
  forward = certEnclose[function, x, interval, ctx];
  derivativeExpression = D[function, x];
  derivative = certEnclose[derivativeExpression, x, interval, ctx];
  mu = Which[derivative[[1]] > 0, derivative[[1]], derivative[[2]] < 0, -derivative[[2]], True, 0];
  If[mu === 0, certFail["DerivativeNotSeparated", "The derivative enclosure is not separated from zero.",
    <|"DerivativeEnclosure" -> derivative, "Interval" -> interval|>]];
  residual = certEnclose[function - target, x, {center, center}, ctx];
  epsilon = Max[Abs[residual]];
  radius = epsilon/mu;
  bracket = {center - radius, center + radius};
  If[! knownRoot && (bracket[[1]] < interval[[1]] || bracket[[2]] > interval[[2]]),
   leftResidual = certEnclose[function - target, x, ConstantArray[interval[[1]], 2], ctx];
   rightResidual = certEnclose[function - target, x, ConstantArray[interval[[2]], 2], ctx];
   endpointBracket = If[derivative[[1]] > 0,
     leftResidual[[2]] <= 0 && rightResidual[[1]] >= 0,
     leftResidual[[1]] >= 0 && rightResidual[[2]] <= 0];
   If[! endpointBracket,
    certFail["ResidualBracketOutsideInterval", "Neither residual containment nor exact endpoint signs establish a root in the verification interval.",
     <|"ResidualEnclosure" -> residual, "DerivativeLowerBound" -> mu,
       "ProposedRootBracket" -> bracket, "Interval" -> interval,
       "DefinitiveNoRoot" -> ((leftResidual[[1]] > 0 && rightResidual[[1]] > 0) ||
         (leftResidual[[2]] < 0 && rightResidual[[2]] < 0)),
       "EndpointResidualEnclosures" -> {leftResidual, rightResidual}|>]]];
  (* The root now exists. Apply the mean-value identity once more with the
     full signed derivative enclosure to obtain a sharper root interval. *)
  correction = certMul[residual, certReciprocal[derivative, ctx], ctx];
  sharp = {Max[interval[[1]], bracket[[1]], center - correction[[2]]],
    Min[interval[[2]], bracket[[2]], center - correction[[1]]]};
  If[sharp[[1]] > sharp[[2]], certFail["CertificateInvariant", "The exact root enclosure became empty."]];
  <|"Certified" -> True, "RootEnclosure" -> sharp, "Center" -> center,
    "CertifiedErrorBound" -> Max[Abs[sharp - center]], "ResidualRadius" -> radius,
    "CertifiedErrorLowerBound" -> If[residual[[1]] <= 0 <= residual[[2]], 0,
      Min[Abs[residual]]/Max[Abs[derivative]]], "ResidualEnclosure" -> residual,
    "ResidualAbsoluteBound" -> epsilon, "DerivativeEnclosure" -> derivative,
    "DerivativeLowerBound" -> mu, "DerivativeSign" -> If[derivative[[1]] > 0, 1, -1],
    "VerificationInterval" -> interval, "CertifiedFunction" -> function,
    "CertifiedSourceDomain" -> domain, "SourceDomainVerified" -> True,
    "CertifiedTarget" -> target, "Route" -> route,
    "ExistenceEvidence" -> Which[knownRoot, "The preceding certificate enclosed a root in this interval",
      endpointBracket, "Exact endpoint signs and continuity", True, "Residual bracket containment"],
    "EndpointResidualEnclosures" -> If[endpointBracket, {leftResidual, rightResidual}, Missing["NotNeeded"]],
    "OriginalForwardFunction" -> a["Function"], "SeedKind" -> a["Kind"],
    "InputRemainder" -> Lookup[a, "InputRemainder", None],
    "FunctionScope" -> If[MemberQ[{None, Automatic}, Lookup[a, "InputRemainder", None]],
      "ExplicitFunction", "StoredExpressionOnly"],
    "CertifiesInputRemainderFamily" -> False,
    "Arithmetic" -> "Exact rational intervals with directed dyadic rounding and explicit exponential/logarithm series tails",
    "Scope" -> "A unique real root of the stored explicit Function in VerificationInterval, on the selected source side and within every retained source-domain condition. Unspecified terms represented by InputRemainder are not enclosed, and no global inverse-branch certificate is asserted."|>];

Options[AsymptoticAnalysis`InverseCertificate] = {"Interval" -> Automatic, "Center" -> Automatic,
  "TargetError" -> Automatic, "RelativeError" -> Automatic, WorkingPrecision -> 50, "EnclosureOrder" -> Automatic,
  "MaxRefinements" -> 6, "RefineExpansion" -> True, "ExponentMagnitudeLimit" -> 10000};

(* This is a starting heuristic only. Exact certified bounds decide whether
   the requested accuracy has been reached, even when this estimate is capped. *)
certToleranceDigits[t_] := If[t === Automatic, 0,
  Max[0, IntegerLength[Denominator[t]] - IntegerLength[Numerator[t]]]];

(* Increase arithmetic work when its point-residual uncertainty materially
   limits the new enclosure. This plans work only; it is not an error theorem.
   Comparing against the old center error would delay a necessary increase
   until too little refinement budget remains for the next recentering. *)
certArithmeticLimitedQ[result_Association] := Module[
  {residualWidth = result["ResidualEnclosure"][[2]] - result["ResidualEnclosure"][[1]],
   rootWidth = result["RootEnclosure"][[2]] - result["RootEnclosure"][[1]]},
  TrueQ[residualWidth > 0 && 2 residualWidth >= result["DerivativeLowerBound"] rootWidth]];
certProgressStalledQ[history_List] := Module[{previous, current},
  If[Length[history] < 2, Return[False, Module]];
  {previous, current} = Take[history, -2];
  TrueQ[previous["Outcome"] === "Certified" && current["Outcome"] === "Certified" &&
    previous["EnclosureOrder"] === current["EnclosureOrder"] &&
    current["RootEnclosureWidth"] >= previous["RootEnclosureWidth"] &&
    current["CertifiedErrorBound"] >= previous["CertifiedErrorBound"]]];

(* Compare proof quality against this request, then break ties by the absolute
   error and interval width. A relative-only interval crossing zero has no
   positive sufficient absolute tolerance and therefore an infinite ratio. *)
certAccuracyKey[result_Association] := Module[{goal = result["SufficientAbsoluteTolerance"], error = result["CertifiedErrorBound"]},
  {Which[goal === Infinity, 0, goal > 0, error/goal, True, Infinity],
    error, result["RootEnclosure"][[2]] - result["RootEnclosure"][[1]]}];
certBetterCertificateQ[candidate_Association, best_] := Module[{left, right},
  If[! AssociationQ[best], Return[True, Module]];
  left = certAccuracyKey[candidate]; right = certAccuracyKey[best];
  Which[left[[1]] =!= right[[1]], TrueQ[left[[1]] < right[[1]]],
    left[[2]] =!= right[[2]], TrueQ[left[[2]] < right[[2]]],
    True, TrueQ[left[[3]] < right[[3]]]]];

AsymptoticAnalysis`InverseCertificate[GeneralizedSeries[a_Association], yv_, opts : OptionsPattern[]] := catch[Module[
  {interval = OptionValue["Interval"], center = OptionValue["Center"], tolerance = OptionValue["TargetError"],
   relative = OptionValue["RelativeError"], lowerMagnitude, upperMagnitude, goalBound, floorBound, absoluteTolerance,
   wp = OptionValue[WorkingPrecision], order = OptionValue["EnclosureOrder"],
   maximum = OptionValue["MaxRefinements"], refine = OptionValue["RefineExpansion"],
   magnitude = OptionValue["ExponentMagnitudeLimit"], fixed, x, y, f, target, route, ctx,
   result, best = Missing["NotCertified"], iteration = 0, seed, history = {}, initial, digits, knownRoot = False,
   certificateModel = a, phaseData, accuracyReached, completion,
   bestCriterion = {"CertifiedErrorBound/SufficientAbsoluteTolerance", "CertifiedErrorBound", "RootEnclosureWidth"}},
  If[! MemberQ[{"Inverse", "CoreInverse"}, Lookup[a, "Kind", None]],
   certFail["Unsupported", "Certificates require an inverse or exact-core inverse expansion."]];
  If[! exactQ[yv] || ! NumericQ[yv], certFail["InexactTarget", "The certificate target must be an exact numeric expression."]];
  If[! MatchQ[interval, {_?certRationalQ, _?certRationalQ}] || ! TrueQ[interval[[1]] < interval[[2]]],
   certFail["InvalidInterval", "Supply Interval -> {lo, hi} with ordered exact rational endpoints."]];
  If[! IntegerQ[wp] || wp < 10 || ! IntegerQ[maximum] || maximum < 0 ||
    ! MemberQ[{True, False}, refine] || ! IntegerQ[magnitude] || magnitude < 1,
   certFail["InvalidOption", "WorkingPrecision must be at least 10, MaxRefinements nonnegative, RefineExpansion Boolean, and ExponentMagnitudeLimit a positive integer."]];
  If[tolerance =!= Automatic && (! certRationalQ[tolerance] || ! TrueQ[tolerance > 0]),
   certFail["InvalidTolerance", "TargetError must be a positive exact rational number."]];
  If[relative =!= Automatic && (! certRationalQ[relative] || ! TrueQ[relative > 0]),
   certFail["InvalidTolerance", "RelativeError must be a positive exact rational number."]];
  If[order === Automatic,
   digits = Max[certToleranceDigits[tolerance], certToleranceDigits[relative]];
   order = Min[2000, Max[wp + 10, digits + 15]]];
  If[! IntegerQ[order] || order < 2 || order > 2000,
   certFail["InvalidOption", "EnclosureOrder must be an integer between 2 and 2000."]];
  x = a["Variables"][[1]]; y = a["Variable"]; f = a["Function"]; target = yv; route = "OriginalFunction";
  If[Lookup[a, "CoordinateKind", None] === "TargetLog",
   f = a["TransformedFunction"]; target = a["TargetCoordinateExpression"] /. y -> yv;
   route = "LogarithmicPhase"];
  If[route === "OriginalFunction" && Lookup[a, "LambertCoreType", None] === "Exponential",
   phaseData = catch[coordinateExponentialPhase[a["Function"], x, a["ExpansionPoint"], a["Direction"],
      Lookup[a, "Assumptions", True], 20000]];
   If[AssociationQ[phaseData],
    f = phaseData["Phase"];
    target = Log[phaseData["AmplitudeSign"] (yv - phaseData["Offset"])/phaseData["AmplitudeScale"]];
    certificateModel = Join[a, <|"SourceDomain" -> (inverseEvidenceSourceDomain[a, x] && phaseData["PositiveAmplitude"] > 0),
      "SourceVariable" -> x|>];
    route = "LogarithmicPhase"]];
  fixed = center =!= Automatic;
  If[! fixed,
   center = certSeed[a, yv, wp];
   If[center === $Failed || ! TrueQ[interval[[1]] < center < interval[[2]]], center = Mean[interval]]];
  If[! certRationalQ[center] || ! TrueQ[interval[[1]] < center < interval[[2]]],
   certFail["InvalidCenter", "Center must be an exact rational strictly inside the certificate interval."]];
  initial = interval;
  While[True,
   ctx = <|"SeriesOrder" -> order, "Bits" -> 4 (order + 10), "ExponentMagnitudeLimit" -> magnitude|>;
   result = catch[certAttempt[certificateModel, f, target, x, interval, center, ctx, route, knownRoot]];
   If[AssociationQ[result], result = Join[result, <|"OriginalTarget" -> yv|>]];
   AppendTo[history, <|"Iteration" -> iteration, "EnclosureOrder" -> order, "Center" -> center,
      "Outcome" -> If[AssociationQ[result], "Certified", result[[1]]]|>];
   If[FailureQ[result] && TrueQ[Lookup[result[[2]], "DefinitiveNoRoot", False]],
    Return[Failure[result[[1]], Join[result[[2]], <|"History" -> history|>]], Module]];
   If[AssociationQ[result],
    lowerMagnitude = If[result["RootEnclosure"][[1]] <= 0 <= result["RootEnclosure"][[2]], 0,
      Min[Abs[result["RootEnclosure"]]]];
    upperMagnitude = Max[Abs[result["RootEnclosure"]]];
    absoluteTolerance = If[tolerance === Automatic, 0, tolerance];
    goalBound = If[relative === Automatic, If[tolerance === Automatic, Infinity, tolerance],
      Max[absoluteTolerance, relative lowerMagnitude]];
    floorBound = If[relative === Automatic, goalBound, Max[absoluteTolerance, relative upperMagnitude]];
    accuracyReached = TrueQ[result["CertifiedErrorBound"] <= goalBound] &&
      ! (relative =!= Automatic && tolerance === Automatic && upperMagnitude === 0);
    result = Join[result, <|"RelativeError" -> relative, "ProvedRootMagnitudeLowerBound" -> lowerMagnitude,
      "CertifiedRelativeErrorBound" -> If[lowerMagnitude > 0, result["CertifiedErrorBound"]/lowerMagnitude,
        Missing["RootNotSeparatedFromZero"]], "SufficientAbsoluteTolerance" -> goalBound,
      "AccuracyGoalReached" -> accuracyReached, "EnclosureOrder" -> order,
      "EnclosureOrderLimitReached" -> (order === 2000), "Refinements" -> iteration,
      "BestCertificateCriterion" -> bestCriterion|>];
    result = Join[result, <|"AccuracyComparisonKey" -> certAccuracyKey[result]|>];
    history[[-1]] = Join[Last[history], KeyTake[result,
      {"CertifiedErrorBound", "ResidualRadius", "SufficientAbsoluteTolerance", "AccuracyGoalReached", "AccuracyComparisonKey"}],
      <|"RootEnclosureWidth" -> result["RootEnclosure"][[2]] - result["RootEnclosure"][[1]],
        "ResidualEnclosureWidth" -> result["ResidualEnclosure"][[2]] - result["ResidualEnclosure"][[1]]|>];
    If[certBetterCertificateQ[result, best], best = result];
    If[relative =!= Automatic && tolerance === Automatic && upperMagnitude === 0,
     certFail["RelativeAccuracyAtZero", "A relative accuracy request at a zero root requires an explicit positive TargetError absolute fallback.",
       <|"BestCertificate" -> result, "History" -> history|>]];
    If[accuracyReached,
     Return[Join[result, <|"OriginalTarget" -> yv, "TargetError" -> tolerance, "AccuracyGoalReached" -> True,
        "Refinements" -> iteration, "History" -> history|>], Module]];
    If[fixed && result["CertifiedErrorLowerBound"] > floorBound,
     certFail["AccuracyFloor", "The fixed center's certified error lower bound exceeds the requested absolute or relative tolerance.",
      <|"TargetError" -> tolerance, "RelativeError" -> relative, "BestCertificate" -> best,
        "AccuracyFloorCertificate" -> result, "History" -> history,
        "CenterWasFixed" -> True|>]]];
   If[iteration >= maximum, Break[]];
   iteration++;
   (* Useful geometric contraction does not itself require more arithmetic.
      At the arithmetic cap, retain all remaining interval-contraction steps. *)
   If[! AssociationQ[result] || fixed || certArithmeticLimitedQ[result] || certProgressStalledQ[history],
     order = Min[2000, 2 order]];
   If[AssociationQ[result] && ! fixed,
    knownRoot = True;
    If[result["RootEnclosure"][[1]] < result["RootEnclosure"][[2]],
     interval = result["RootEnclosure"]; center = Mean[interval],
     center = First[result["RootEnclosure"]]; interval = initial];
    If[refine,
     seed = certRefinedSeed[a, yv, iteration, wp + 10 iteration];
     If[certRationalQ[seed] && TrueQ[interval[[1]] < seed < interval[[2]]], center = seed]]]];
  completion = <|"StoppingReason" -> "RefinementBudgetExhausted", "MaxRefinements" -> maximum,
    "Refinements" -> iteration, "EnclosureOrderLimit" -> 2000, "FinalEnclosureOrder" -> order,
    "EnclosureOrderLimitReached" -> (order === 2000), "AccuracyGoalReached" -> False,
    "BestCertificateCriterion" -> bestCriterion|>;
  If[AssociationQ[best],
   certFail["AccuracyNotReached", "The requested error was not certified within the refinement budget.",
    Join[completion, <|"TargetError" -> tolerance, "RelativeError" -> relative,
      "BestCertificate" -> best, "History" -> history, "CenterWasFixed" -> fixed|>]],
   If[FailureQ[result], Return[Failure[result[[1]], Join[result[[2]], completion, <|"History" -> history|>]], Module]];
   certFail["CertificateFailure", "No residual certificate was established."]]]];

AsymptoticAnalysis`InverseCertificate[___] := Failure["InvalidArguments", <|"Certified" -> False,
  "MessageTemplate" -> "Use InverseCertificate[expansion, exactTarget, Interval -> {lo, hi}]."|>];
(* END SOURCE: src/Kernel/InverseCertificates.wl *)

(* BEGIN SOURCE: src/Kernel/LogarithmicScales.wl
   Source SHA256 (UTF-8/LF): 14626230208ac7d1f1606bb9768bb563916639867fb1ef704bea4748b20d3d09 *)
(* Finite logarithmic hierarchies. Loaded in AsymptoticAnalysis`Private`.
   Exact source-coordinate charts live separately in SourceCoordinates.wl. *)

AsymptoticAnalysis`AsymptoticLogarithmicInverse::usage =
"AsymptoticLogarithmicInverse[f,{x,x0},{y,cutoff}] inverts supported finite logarithmic hierarchies. Reciprocal-logarithmic units and leading logarithmic monomials use a positive exclusive relative cutoff in the recorded inverse-logarithmic coordinate. Generalized logarithmic coefficients use an exact target-power cutoff above the leading observable power, which may be negative at infinity. AsymptoticLogarithmicInverse[f,{x,x0},y,SeriesTermGoal->n] retains the first n complete nonzero blocks, or a certified exact terminating expansion, subject to MaxTerms and a bounded refinement search. LogarithmicLevels bounds the explicitly represented positive logarithmic hierarchy.";
AsymptoticAnalysis`LogarithmicInverseResidual::usage =
"LogarithmicInverseResidual[result] checks a logarithmic-unit inverse by exact formal composition of its normalized forward equation. Generalized logarithmic coefficients currently return UnsupportedResidual; their retained coefficients and original equation remain available on the expansion object for independent checking.";

Options[AsymptoticAnalysis`AsymptoticLogarithmicInverse] = Join[Options[AsymptoticInverse], {"LogarithmicLevels" -> 3}];

logarithmicMerge[rows_, ass_] := Module[{g, merged},
  g = GatherBy[({canon[#[[1]]], #[[2]]} & /@ rows), First];
  merged = ({#[[1, 1]], Simplify[Total[#[[All, 2]]], ass]} & /@ g);
  g = orderedWeightGroups[Select[merged, ! zeroQ[#[[2]], ass] &]];
  merged = If[Length[#] === 1, First[#],
    {#[[1, 1]], Simplify[Total[#[[All, 2]]], ass]}] & /@ g;
  Select[merged, ! zeroQ[#[[2]], ass] &]];

logarithmicLevels[u_, n_] := NestList[Log, -Log[u], n - 1];

(* Each listed coordinate is strictly positive on the admitted local
   branch. Consequently a positive monomial can be extracted from an exact
   real power: (M c)^r = M^r c^r for M > 0. The constant c keeps its principal
   power and must independently pass the real-coefficient check below. This
   handles Simplify combining Sqrt[u] Sqrt[level] without PowerExpand. *)
logarithmicMonomialFactor[e_, variables_List] := Module[{parts, part, position},
  Which[
    FreeQ[e, Alternatives @@ variables], {e, ConstantArray[0, Length[variables]]},
    MemberQ[variables, e],
      position = First[FirstPosition[variables, e]];
      {1, UnitVector[Length[variables], position]},
    Head[e] === Times,
      parts = logarithmicMonomialFactor[#, variables] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Total[parts[[All, 2]]]}],
    Head[e] === Power && exactRealQ[e[[2]]],
      part = logarithmicMonomialFactor[e[[1]], variables];
      If[part === $Failed, $Failed, {part[[1]]^e[[2]], e[[2]] part[[2]]}],
    True, $Failed]];

logarithmicRead[f_, x_, coord_, levels_, ass_] := Module[
  {u = coord["u"], fu, mapped, terms, rows = {}, part, j},
  fu = Simplify[f /. x -> coord["Substitution"], ass && u > 0];
  mapped = fu /. Log[u] -> -First[levels];
  Do[mapped = mapped /. Log[levels[[j]]] -> levels[[j + 1]], {j, Length[levels] - 1}];
  mapped = Expand[mapped]; terms = If[Head[mapped] === Plus, List @@ mapped, {mapped}];
  Do[
    part = logarithmicMonomialFactor[term, {u}];
    If[part === $Failed, Return[$Failed, Module]];
    AppendTo[rows, {First[part[[2]]], part[[1]]}], {term, terms}];
  If[! And @@ (exactRealQ[#[[1]]] & /@ rows), Return[$Failed, Module]];
  <|"LocalFunction" -> fu, "MappedFunction" -> mapped,
    "Rows" -> logarithmicMerge[rows, ass]|>];

(* Every accepted coefficient is a finite generalized Laurent polynomial
   in the positive levels. Its Euler derivative stays in the same algebra. *)
logarithmicMonomials[e_, levels_, ass_] := Module[
  {expanded = Expand[e], terms, rows = {}, coefficient, powers, part},
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Do[
    part = logarithmicMonomialFactor[term, levels];
    If[part === $Failed, Return[$Failed, Module]];
    {coefficient, powers} = part;
    If[! TrueQ[Simplify[Element[coefficient, Reals], ass]], Return[$Failed, Module]];
    If[! zeroQ[coefficient, ass], AppendTo[rows, {coefficient, powers}]], {term, terms}];
  rows];

logarithmicCoefficientBound[e_, levels_, ass_] := Module[{monomials, rational, numerator, denominator},
  monomials = logarithmicMonomials[e, levels, ass];
  If[monomials =!= $Failed,
    Return[If[monomials === {}, 0, Ceiling[Max[Total[Max[0, #] & /@ #[[2]]] & /@ monomials]]], Module]];
  If[! FreeQ[e, Alternatives @@ Rest[levels]], Return[$Failed, Module]];
  rational = Together[e]; numerator = Numerator[rational]; denominator = Denominator[rational];
  If[! PolynomialQ[numerator, First[levels]] || ! PolynomialQ[denominator, First[levels]], Return[$Failed, Module]];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@
       Join[CoefficientList[numerator, First[levels]], CoefficientList[denominator, First[levels]]]), Return[$Failed, Module]];
  If[! TrueQ[Simplify[Last[CoefficientList[denominator, First[levels]]] != 0, ass]], Return[$Failed, Module]];
  Max[0, Exponent[numerator, First[levels]] - Exponent[denominator, First[levels]]]];

logarithmicEuler[e_, levels_] := -Sum[D[e, levels[[j]]]/(Times @@ Take[levels, j - 1]), {j, Length[levels]}];

logarithmicTaylor[e_, t_, degree_, ass_, limit_] := Module[{result},
  result = Quiet[Check[Normal[Series[e, {t, 0, degree}]], $Failed]];
  If[result === $Failed || ! FreeQ[result, _SeriesData | Indeterminate | _DirectedInfinity],
    fail["LogarithmicSeriesFailure", "The normalized logarithmic unit could not be expanded on the selected branch."]];
  result = Expand[result];
  If[LeafCount[result] > limit, fail["ResourceLimit", "The logarithmic coefficient expression exceeded MaxTerms leaves."]];
  result];

logarithmicUnitSolve[rhs_, w_, t_, degree_, ass_, limit_] := Module[{current = 1, next},
  If[degree + 2 > limit, fail["ResourceLimit", "The logarithmic iteration count exceeds MaxTerms."]];
  Do[
    next = logarithmicTaylor[rhs /. w -> current, t, degree, ass, limit];
    If[next === current, Break[]]; current = next,
    {degree + 2}]; current];

logarithmicUnitData[coefficient_, levels_, p_, ass_] := Module[
  {rational, numerator, denominator, a, h, t = Unique["logt$"], w = Unique["logw$"],
   monomials, powers, reciprocals, shift = Unique["logshift$"], ratios, rhs},
  If[FreeQ[coefficient, Alternatives @@ Rest[levels]],
    rational = Together[coefficient]; numerator = Numerator[rational]; denominator = Denominator[rational];
    If[PolynomialQ[numerator, First[levels]] && PolynomialQ[denominator, First[levels]] &&
       Exponent[numerator, First[levels]] === Exponent[denominator, First[levels]],
      a = Simplify[Last[CoefficientList[numerator, First[levels]]]/Last[CoefficientList[denominator, First[levels]]], ass];
      h = Together[(coefficient /. First[levels] -> 1/t)/a];
      If[! TrueQ[Simplify[h == 1, ass]],
        rhs = (h /. t -> t/(1 - t Log[w]))^(-1/p);
        Return[<|"Type" -> "ReciprocalLogUnit", "Amplitude" -> a,
          "FormalVariable" -> t, "UnitVariable" -> w, "UnitRightHandSide" -> rhs,
          "NormalizedForward" -> w^p (h /. t -> t/(1 - t Log[w])) - 1,
          "LeadingLogPowers" -> ConstantArray[0, Length[levels]], "LogarithmicUnit" -> h|>, Module]]]];
  monomials = logarithmicMonomials[coefficient, levels, ass];
  If[monomials === $Failed || Length[monomials] =!= 1, Return[$Failed, Module]];
  {a, powers} = First[monomials];
  If[And @@ (zeroQ[#, ass] & /@ powers), Return[$Failed, Module]];
  reciprocals = Table[Unique["inverseLogLevel$"], {Length[levels] - 1}];
  ratios = FoldList[1 + #2 Log[#1] &, 1 + t (shift - Log[w]), reciprocals];
  rhs = Times @@ MapThread[Power, {ratios, -powers/p}];
  <|"Type" -> "LeadingLogMonomial", "Amplitude" -> a, "FormalVariable" -> t,
    "UnitVariable" -> w, "UnitRightHandSide" -> rhs,
    "NormalizedForward" -> w^p (Times @@ MapThread[Power, {ratios, powers}]) - 1,
    "LeadingLogPowers" -> powers, "ShiftVariable" -> shift,
    "ReciprocalLevelVariables" -> reciprocals|>];

logarithmicUnitConstruct[data_, rows_, offset_, p_, levels_, f_, x_, x0_, y_, coord_, cutoff_, r_, ass_, limit_] := Module[
  {a = data["Amplitude"], t = data["FormalVariable"], w = data["UnitVariable"],
   target, baseLevels, z, variable, substitutions = {}, shift, unit, observable, degree,
   blocks, omitted, beta, logdegree, powers = data["LeadingLogPowers"], rint,
   prefactor, expression, rem, remainderScale, domain, sign, finiteOffset,
   extra, extraBounds, gap, beyondScale, representation, targetScale, targetLimit,
   allCoefficients, terms, formalAssumptions, inputKind, sourceLevels},
  If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The leading logarithmic amplitude must have a provable nonzero real sign."]];
  sign = If[provablyPositive[a, ass], 1, -1]; target = (y - offset)/a;
  rint = If[coord["Infinite"], -r, r]; finiteOffset = If[r === 1 && ! coord["Infinite"], x0, 0];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative selected source branch requires integer observable powers."]];
  If[data["Type"] === "ReciprocalLogUnit",
    z = target^(1/p); variable = -1/Log[z]; domain = target > 0 && 0 < z < 1;
    logdegree = 0; formalAssumptions = ass,
    targetScale = -Log[target]/p;
    baseLevels = NestList[Log, targetScale, Length[levels] - 1];
    shift = Total[MapThread[#1 Log[#2] &, {powers, baseLevels}]]/p;
    z = target^(1/p) (Times @@ MapThread[Power, {baseLevels, -powers/p}]);
    variable = 1/targetScale;
    substitutions = Join[{data["ShiftVariable"] -> shift},
      Thread[data["ReciprocalLevelVariables"] -> (1/Rest[baseLevels])]];
    domain = target > 0 && And @@ (# > 1 & /@ baseLevels);
    logdegree = Ceiling[cutoff]; formalAssumptions = ass];
  degree = Ceiling[cutoff] + 1;
  unit = logarithmicUnitSolve[data["UnitRightHandSide"], w, t, degree, formalAssumptions, limit];
  observable = logarithmicTaylor[unit^rint, t, degree, formalAssumptions, limit];
  allCoefficients = Select[Table[{n, Simplify[Coefficient[observable, t, n], ass]}, {n, 0, degree}], ! zeroQ[#[[2]], ass] &];
  blocks = Select[allCoefficients, less[#[[1]], cutoff] &];
  omitted = Select[allCoefficients, ! less[#[[1]], cutoff] &];
  beta = If[omitted === {}, Ceiling[cutoff], omitted[[1, 1]]];
  If[data["Type"] =!= "ReciprocalLogUnit", logdegree = beta];
  prefactor = coord["Sign"]^r z^rint;
  terms = blocks /. substitutions;
  expression = finiteOffset + prefactor Total[(variable^#[[1]] #[[2]]) & /@ terms];
  extra = Rest[rows]; extraBounds = logarithmicCoefficientBound[#[[2]], levels, ass] & /@ extra;
  If[MemberQ[extraBounds, $Failed], Return[$Failed, Module]];
  beyondScale = If[extra === {}, 0,
    gap = Min[canon[#[[1]] - p] & /@ extra];
    Abs[prefactor] z^gap (1 + Abs[Log[z]])^(Max[extraBounds] + Ceiling[Total[Abs /@ powers]])];
  rem = Abs[prefactor] PowerLogRemainder[variable, beta, logdegree];
  remainderScale = Abs[prefactor] variable^beta (1 + Abs[Log[variable]])^logdegree;
  targetLimit = If[less[0, p], offset, sign Infinity];
  representation = If[data["Type"] === "ReciprocalLogUnit",
    <|"Variable" -> y, "ScaleVariable" -> variable, "LogVariable" -> Unique["ell$"],
      "Offset" -> finiteOffset, "Prefactor" -> prefactor, "Jet" -> {blocks, beta, 0},
      "Assumptions" -> ass, "Domain" -> domain, "Cutoff" -> cutoff, "RemainderDerivativeOrder" -> 0|>,
    Missing["NestedLogarithmicCoefficients"]];
  sourceLevels = logarithmicLevels[coord["u"], Length[levels]];
  GeneralizedSeries[<|"Kind" -> "LogarithmicInverse", "Scale" -> data["Type"],
    "Expression" -> expression, "Remainder" -> rem, "RemainderScaleExpression" -> remainderScale,
    "RemainderVariable" -> variable, "RemainderPower" -> beta, "RemainderLogDegree" -> logdegree,
    "Prefactor" -> prefactor, "Offset" -> finiteOffset, "Terms" -> terms, "Blocks" -> blocks,
    "Uniformizer" -> variable, "LogarithmicVariable" -> variable, "LogarithmicLevels" -> Length[levels],
    "CoefficientLevelSubstitutions" -> substitutions, "LeadingLocalApproximation" -> z,
    "LogarithmicEquationData" -> data, "LogarithmicUnitPolynomial" -> unit,
    "LogarithmicObservablePolynomial" -> observable, "FormalVariable" -> t,
    "TermConvention" -> "Offset + Prefactor Sum[t^n C_n], with the displayed positive inverse-logarithmic t. Cutoff is exclusive in n. Nested lower-logarithmic coefficients are retained exactly.",
    "Cutoff" -> cutoff, "Truncation" -> "LogarithmicExponent", "Power" -> r,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"],
    "LocalSubstitution" -> (x -> coord["Substitution"]), "SourceLogarithmicLevels" -> sourceLevels,
    "SourceDomain" -> And @@ (# > 1 & /@ sourceLevels),
    "TargetDomain" -> (ass && domain), "Limit" -> targetLimit,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> a,
    "LeadingCoreOnly" -> (extra =!= {}), "ExactModel" -> (extra === {}),
    "BeyondLogarithmicOrders" -> Total[(coord["u"]^#[[1]] (#[[2]] /. Thread[levels -> sourceLevels])) & /@ extra],
    "BeyondLogarithmicRemainderScale" -> beyondScale,
    "RemainderExplanation" -> "A joint analytic implicit equation bounds the complete logarithmic tail. Higher positive source-power gaps are smaller than every fixed inverse-logarithmic order and are recorded separately. Constants and source threshold are not computed numerical certificates.",
    "ConvergenceContract" -> <|"Type" -> "AnalyticImplicitFunction", "NumericCertificate" -> False,
      "Parameters" -> If[data["Type"] === "ReciprocalLogUnit", {variable},
        Join[{variable, variable shift}, 1/Rest[baseLevels]]]|>,
    "SeriesRepresentation" -> representation, "SeriesData" -> Missing["LogarithmicScale"],
    "RemainderDerivativeOrder" -> 0|>]];

logarithmicCoefficient[k_, gaps_, coefficients_, p_, r_, levels_, ass_, limit_] := Module[{n = Total[k], weight, c},
  If[n === 0, Return[{0, 1}, Module]];
  weight = canon[k . gaps]; c = Expand[Times @@ MapThread[Power, {coefficients, k}]];
  Do[c = Expand[logarithmicEuler[c, levels] + (r + weight + p j) c];
    If[LeafCount[c] > limit, fail["ResourceLimit", "The generalized logarithmic coefficient exceeded MaxTerms leaves."]], {j, 1, n - 1}];
  {weight, Simplify[(-1)^n r c/(p^n (Times @@ (Factorial /@ k))), ass && And @@ (# > 1 & /@ levels)]}];

(* One builder belongs to one constructor call and its fixed logarithmic
   symbols. Cache complete multi-indices, including zero coefficients;
   regions and merged blocks are rebuilt when the goal changes the cutoff. *)
logarithmicPowerBuilder[rows_, offset_, p_, levels_, f_, x_, x0_, y_, coord_, r_, ass_, limit_] := Module[
  {a = rows[[1, 2]], gaps, coefficients, monomials, degreeBounds, rint, coefficient, prepared = False},
  coefficient[k_] := coefficient[k] = logarithmicCoefficient[k, gaps, coefficients, p, rint, levels, ass, limit];
  Function[cutoff, Module[{h, region, blocks, boundary, beta, degree, z, target, sign,
    w, levelValues, terms, expression, domain, offsetValue},
  (* Keep preparation lazy so public option and goal checks still run first. *)
  If[! prepared,
    If[! FreeQ[a, Alternatives @@ levels] || ! TrueQ[Simplify[Element[a, Reals], ass]], Return[$Failed, Module]];
    If[! (provablyPositive[a, ass] || provablyNegative[a, ass]), fail["UnprovedSign", "The leading source coefficient must have a provable nonzero real sign."]];
    coefficients = Simplify[#[[2]]/a, ass] & /@ Rest[rows];
    monomials = logarithmicMonomials[#, levels, ass] & /@ coefficients;
    If[MemberQ[monomials, $Failed], Return[$Failed, Module]];
    If[FreeQ[coefficients, Alternatives @@ Rest[levels]] &&
       And @@ (PolynomialQ[#, First[levels]] & /@ coefficients), Return[$Failed, Module]];
    gaps = canon[#[[1]] - p] & /@ Rest[rows];
    rint = If[coord["Infinite"], -r, r]; prepared = True];
  h = Abs[p] cutoff - rint;
  If[! less[0, h], fail["CutoffTooSmall", "The cutoff must exceed the leading target power of the requested observable."]];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative selected source branch requires integer observable powers."]];
  region = indexRegion[gaps, h, False, limit];
  blocks = logarithmicMerge[coefficient /@ region["Inside"], ass];
  boundary = region["Boundary"];
  beta = If[boundary === {}, Infinity, Min[canon[# . gaps] & /@ boundary]];
  If[! ListQ[degreeBounds], degreeBounds = logarithmicCoefficientBound[#, levels, ass] & /@ coefficients];
  degree = If[boundary === {}, 0, Max[(# . degreeBounds) & /@ boundary]];
  sign = If[provablyPositive[a, ass], 1, -1]; target = (y - offset)/a;
  z = target^(1/p); w = If[less[0, p], sign (y - offset), sign/(y - offset)];
  levelValues = logarithmicLevels[z, Length[levels]];
  terms = {canon[(rint + #[[1]])/Abs[p]],
      coord["Sign"]^r Abs[a]^(-(rint + #[[1]])/p) (#[[2]] /. Thread[levels -> levelValues])} & /@ blocks;
  offsetValue = If[r === 1 && ! coord["Infinite"], x0, 0];
  expression = offsetValue + Total[(w^#[[1]] #[[2]]) & /@ terms];
  domain = ass && target > 0 && And @@ (# > 1 & /@ levelValues);
  GeneralizedSeries[<|"Kind" -> "LogarithmicInverse", "Scale" -> "GeneralizedLogarithmicCoefficients",
    "Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "Remainder" -> If[beta === Infinity, 0, PowerLogRemainder[w, (rint + beta)/Abs[p], degree]],
    "RemainderScaleExpression" -> If[beta === Infinity, 0, w^((rint + beta)/Abs[p]) (1 + Abs[Log[w]])^degree],
    "RemainderVariable" -> w, "RemainderPower" -> (rint + beta)/Abs[p], "RemainderLogDegree" -> degree,
    "Uniformizer" -> z, "LogarithmicLevels" -> Length[levels], "CoefficientLevels" -> levels,
    "CoefficientLevelValues" -> levelValues, "IndexRegion" -> region, "PowerGaps" -> gaps,
    "NormalizedCoefficients" -> coefficients, "CoefficientDegreeBounds" -> degreeBounds,
    "TermConvention" -> "Each {beta,C} contributes w^beta C, with w the recorded positive target coordinate. C is an exact generalized Laurent polynomial in the finite positive logarithmic hierarchy of Uniformizer. Cutoff is exclusive in beta.",
    "Cutoff" -> cutoff, "NormalizedSourceWeightCutoff" -> h, "Truncation" -> "Exponent", "Power" -> r,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "Limit" -> If[less[0, p], offset, sign Infinity], "TargetDomain" -> domain,
    "Assumptions" -> ass, "LeadingPower" -> p, "LeadingCoefficient" -> a,
    "ExactModel" -> True, "LeadingCoreOnly" -> False,
    "RemainderExplanation" -> "The complete multi-index tail is bounded by the least excluded source weight and a conservative logarithmic envelope over the finite boundary. Exact nonpolynomial logarithmic coefficients remain unexpanded.",
    "ConvergenceContract" -> <|"Type" -> "FiniteAnalyticLogarithmicLift", "NumericCertificate" -> False|>,
    "SeriesData" -> Missing["GeneralizedLogarithmicCoefficients"], "RemainderDerivativeOrder" -> 0|>]]]];

(* A finite zero prefix is not an exact-termination certificate. Verify a
   candidate against the original equation, with the already selected real
   source branch, before removing a remainder. Failure or timeout only means
   that the bounded term search must continue. *)
logarithmicGoalTermination[GeneralizedSeries[a_Association]] := Module[
  {x, y, rint, sign, magnitude, candidate, domain, verified, representation},
  If[! TrueQ[Lookup[a, "ExactModel", False]] || LeafCount[a["Function"]] > 300 ||
     LeafCount[a["Expression"]] > 500, Return[None, Module]];
  {x, y} = a["Variables"];
  rint = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  sign = Which[a["ExpansionPoint"] === Infinity, 1, a["ExpansionPoint"] === -Infinity, -1,
    a["Direction"] === "FromBelow", -1, True, 1];
  magnitude = (a["Expression"] - Lookup[a, "Offset", If[a["Power"] === 1 &&
      ! MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], a["ExpansionPoint"], 0]])/sign^a["Power"];
  candidate = a["LocalSubstitution"][[2]] /. a["LocalVariable"] -> magnitude^(1/rint);
  domain = a["TargetDomain"] && magnitude > 0;
  verified = TimeConstrained[
    Quiet[Check[FullSimplify[(a["Function"] /. x -> candidate) == y, domain], False]], 2, False];
  If[! TrueQ[verified], Return[None, Module]];
  representation = Lookup[a, "SeriesRepresentation", Missing["Unavailable"]];
  If[AssociationQ[representation], representation = Join[representation,
    <|"Jet" -> {a["Blocks"], Infinity, 0}|>]];
  GeneralizedSeries[Join[a, <|"Remainder" -> 0, "RemainderScaleExpression" -> 0,
    "RemainderPower" -> Infinity, "RemainderLogDegree" -> 0,
    "SeriesRepresentation" -> representation,
    "ExactTerminationCertificate" -> <|"Verified" -> True,
      "Verification" -> "Exact symbolic composition with the original forward expression",
      "Candidate" -> candidate, "Target" -> y, "BranchAssumptions" -> domain|>|>]]];

(* All constructor calls retain complete weight blocks. A goal advances past
   cancellations; it is never used as an exponent cutoff. Generalized-power
   searches may cross several weights at once, in which case rebuilding at
   the next excluded weight keeps exactly the first requested blocks. *)
logarithmicGoalConstruct[make_, unitQ_, rows_, p_, rint_, goal_, limit_] := Module[
  {cutoff, gaps, step, result = None, next, count, tries = 0, previousCount = -1, nextCutoff,
   maximum = Min[limit, 50 goal + 10], termination, triedBlocks = None, boundary},
  If[goal > limit, fail["ResourceLimit", "SeriesTermGoal exceeds MaxTerms.",
    <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit|>]];
  If[unitQ, cutoff = goal,
    gaps = canon[#[[1]] - p] & /@ Rest[rows];
    step = If[gaps === {}, 1, Min[gaps]]/2;
    cutoff = canon[(rint + step)/Abs[p]]];
  While[True,
    If[tries >= maximum,
      fail["ResourceLimit", "The logarithmic nonzero-block search exceeded its bounded refinement budget.",
        <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit,
          "ConstructionCalls" -> tries, "BestExpansion" -> result|>]];
    tries++; next = catch[make[cutoff]];
    If[FailureQ[next], Throw[Failure[next[[1]], Join[next[[2]],
      <|"RequestedTermGoal" -> goal, "ConstructionCalls" -> tries,
        "BestExpansion" -> result|>]], $tag]];
    If[next === $Failed, Return[$Failed, Module]];
    result = next; count = Length[result["Blocks"]];
    If[count > goal,
      cutoff = result["Terms"][[goal + 1, 1]];
      Continue[]];
    If[count === goal || result["Remainder"] === 0, Break[]];
    If[result["Blocks"] =!= triedBlocks,
      triedBlocks = result["Blocks"]; termination = logarithmicGoalTermination[result];
      If[MatchQ[termination, GeneralizedSeries[_Association]], result = termination; Break[]]];
    If[unitQ,
      nextCutoff = If[count === previousCount, Min[2 cutoff, limit - 3], cutoff + 1];
      If[! less[cutoff, nextCutoff], fail["ResourceLimit", "The logarithmic search cannot advance within MaxTerms.",
        <|"RequestedTermGoal" -> goal, "MaxTerms" -> limit,
          "ConstructionCalls" -> tries, "BestExpansion" -> result|>]];
      cutoff = nextCutoff; previousCount = count,
      boundary = result["IndexRegion"]["Boundary"];
      If[boundary === {}, Break[]];
      cutoff = canon[(rint + Min[canon[# . gaps] & /@ boundary] + step)/Abs[p]]]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[result["Blocks"]],
    "TermGoalReached" -> (Length[result["Blocks"]] === goal),
    "TermSelection" -> "CompleteNonzeroBlocks", "TermGoalConstructionCalls" -> tries|>]]];

logarithmicConstruct[f_, x_, x0_, y_, cutoff0_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticLogarithmicInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}],
   dir = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, Direction],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, "MaxTerms"],
   depth = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, "LogarithmicLevels"],
   r = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, "Power"],
   method = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, Method], result,
   input = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, "InputRemainder"],
   trunc = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, "Truncation"],
   goal = OptionValue[AsymptoticAnalysis`AsymptoticLogarithmicInverse, {opts}, SeriesTermGoal],
   coord, levels, read, rows, offset, p, data, cutoff = cutoff0, bounds, used, make},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  validateInput[f, limit];
  If[! MemberQ[{"Lagrange", "Newton", "Lambert", "GroupedLagrange"}, method],
    fail["InvalidOption", "Method must be Lagrange, Newton, Lambert or GroupedLagrange; the logarithmic algebra records its own selected algorithm."]];
  If[! IntegerQ[depth] || depth < 1 || depth > 8, fail["InvalidLogarithmicDepth", "LogarithmicLevels must be an integer from 1 through 8."]];
  If[x === y || ! FreeQ[f, y], fail["InvalidVariables", "Use distinct source and target symbols, with no target symbol in the input."]];
  If[! FreeQ[ass, x | y], fail["InvalidAssumptions", "Assumptions concern parameters only."]];
  coord = localCoordinate[x, x0, dir]; levels = Table[Unique["loglevel$"], {depth}];
  read = logarithmicRead[f, x, coord, levels, ass]; If[read === $Failed, Return[$Failed, Module]];
  rows = read["Rows"];
  used = Select[Range[depth], ! FreeQ[rows, levels[[#]]] &];
  If[used === {}, Return[$Failed, Module]];
  levels = Take[levels, Max[used]];
  bounds = logarithmicCoefficientBound[#[[2]], levels, ass] & /@ rows;
  If[MemberQ[bounds, $Failed], Return[$Failed, Module]];
  offset = Total[Cases[rows, {0, c_} /; FreeQ[c, Alternatives @@ levels] :> c]];
  rows = Select[rows, ! (#[[1]] === 0 && FreeQ[#[[2]], Alternatives @@ levels]) &];
  If[rows === {}, Return[$Failed, Module]];
  p = rows[[1, 1]]; If[p === 0, Return[$Failed, Module]];
  data = logarithmicUnitData[rows[[1, 2]], levels, p, ass];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[trunc =!= "Exponent", fail["UnsupportedOption", "Finite logarithmic hierarchies require an explicit exponent cutoff, not marker-depth truncation."]];
  If[! MemberQ[{None, Automatic}, input], fail["UnsupportedOption", "InputRemainder for this logarithmic hierarchy requires a separately supplied transport contract."]];
  make = If[data =!= $Failed,
    Function[h, logarithmicUnitConstruct[data, rows, offset, p, levels, f, x, x0, y, coord, h, r, ass, limit]],
    logarithmicPowerBuilder[rows, offset, p, levels, f, x, x0, y, coord, r, ass, limit]];
  result = If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a positive logarithmic cutoff or SeriesTermGoal -> n."]];
    logarithmicGoalConstruct[make, data =!= $Failed, rows, p, If[coord["Infinite"], -r, r], goal, limit],
    If[! exactRealQ[cutoff] || (data =!= $Failed && ! less[0, cutoff]),
      fail["InvalidCutoff", "The cutoff must be an exact real number, positive for a logarithmic unit. A target-power cutoff must exceed the leading observable power."]];
    make[cutoff]];
  If[result === $Failed, Return[$Failed, Module]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedMethod" -> method,
    "Method" -> If[data === $Failed, "GeneralizedLogarithmicLagrange", "LogarithmicFixedPoint"]|>]]];

logarithmicPublic[f_, x_, x0_, y_, cutoff_, opts___] := Module[{result = logarithmicConstruct[f, x, x0, y, cutoff, opts]},
  If[result === $Failed, fail["UnsupportedLogarithmicScale", "The expression is outside the admitted finite real logarithmic hierarchy or its selected sign domain."], result]];

(* Preserve the established ordinary engine for polynomial log coefficients.
   The automatic hook handles only expressions that need the larger algebra. *)
logarithmicDispatch[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {coord, u, ell = Unique["ell$"], ordinary,
   ass = optionAssumptions[AsymptoticInverse, {opts}],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction]},
  If[FreeQ[f, Log], Return[$Failed, Module]];
  coord = localCoordinate[x, x0, dir]; u = coord["u"];
  ordinary = parseFinite[Simplify[f /. x -> coord["Substitution"], ass && u > 0], u, ell, ass];
  If[ordinary =!= $Failed, Return[$Failed, Module]];
  logarithmicConstruct[f, x, x0, y, cutoff, Sequence @@ withAssumptions[{opts}, ass]]];

AsymptoticAnalysis`AsymptoticLogarithmicInverse[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] :=
  catch[logarithmicPublic[f, x, x0, y, cutoff, opts]];
AsymptoticAnalysis`AsymptoticLogarithmicInverse[f_, {x_Symbol, x0_}, y_Symbol, opts : OptionsPattern[]] :=
  catch[logarithmicPublic[f, x, x0, y, Automatic, opts]];
AsymptoticAnalysis`AsymptoticLogarithmicInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticLogarithmicInverse[f,{x,x0},{y,cutoff}]."|>];

logarithmicResidual[a_, requested_, limit_] := Module[{data, t, w, polynomial, order, residual},
  If[! MemberQ[{"ReciprocalLogUnit", "LeadingLogMonomial"}, Lookup[a, "Scale", ""]],
    fail["UnsupportedResidual", "This helper checks normalized logarithmic-unit equations. Generalized logarithmic coefficient jets require an independent coefficient-algebra composition."]];
  data = a["LogarithmicEquationData"]; t = data["FormalVariable"]; w = data["UnitVariable"];
  order = If[requested === Automatic, a["Cutoff"], requested];
  If[! exactRealQ[order] || ! less[0, order] || less[a["Cutoff"], order],
    fail["InvalidCutoff", "Residual order must be positive and cannot exceed the returned logarithmic cutoff."]];
  polynomial = Total[(t^#[[1]] #[[2]]) & /@ Select[
    Table[{n, Coefficient[a["LogarithmicUnitPolynomial"], t, n]}, {n, 0, Ceiling[a["Cutoff"]]}], less[#[[1]], a["Cutoff"]] &]];
  residual = logarithmicTaylor[data["NormalizedForward"] /. w -> polynomial, t, Ceiling[order] - 1, a["Assumptions"], limit];
  <|"Residual" -> Simplify[residual /. a["CoefficientLevelSubstitutions"], a["Assumptions"]],
    "Vanishes" -> zeroQ[residual, a["Assumptions"]],
    "ZeroBelowCutoff" -> zeroQ[residual, a["Assumptions"]], "Cutoff" -> order,
    "Scope" -> "Exact formal composition of the normalized leading logarithmic core; separately recorded higher source-power sectors are beyond this logarithmic cutoff.",
    "OriginalFunction" -> a["Function"], "LeadingCoreOnly" -> a["LeadingCoreOnly"]|>];

AsymptoticAnalysis`LogarithmicInverseResidual[GeneralizedSeries[a_Association]] := catch[logarithmicResidual[a, Automatic, 200000]];
AsymptoticAnalysis`LogarithmicInverseResidual[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Supply a logarithmic-unit expansion object."|>];
(* END SOURCE: src/Kernel/LogarithmicScales.wl *)

(* BEGIN SOURCE: src/Kernel/FlatSectors.wl
   Source SHA256 (UTF-8/LF): ea3f7f6fea967ec56b54da2931a9d72ee695c6454f6c1da79dd5e35cf432ff8a *)
(* Finite commensurate flat sectors around an exact monomial core.
   This module is loaded in Private` and uses a separate exponential degree.
   It never represents a finite power-log truncation as an exact zero sector. *)

AsymptoticAnalysis`AsymptoticFlatInverse::usage =
"AsymptoticFlatInverse[f,{x,x0},{y,n}] inverts an exact monomial core plus finite commensurate flat exponentials, retaining complete exponential sectors through degree n. Coefficients remain finite exact power-log expressions in the monomial core inverse; the full omitted tail has a separate asymptotic contract.";
Options[AsymptoticAnalysis`AsymptoticFlatInverse] = {
 Assumptions :> $Assumptions, Direction -> Automatic, "Power" -> 1, "MaxTerms" -> 20000};

flatTrim[expression_, z_, n_, limit_] := Module[{v = Expand[expression], result},
 If[! PolynomialQ[v, z], fail["FlatSectorInvariant", "An exponential-sector coefficient ceased to be polynomial in its marker."]];
 result = Sum[Coefficient[v, z, k] z^k, {k, 0, Min[n, Exponent[v, z]]}];
 If[LeafCount[result] > limit, fail["ResourceLimit", "The finite flat-sector polynomial exceeded MaxTerms expression leaves."]];
 result];

flatModel[f_, x_, coord_, ell_, ass_, limit_] := Module[
 {u = coord["u"], local, terms, ordinary = 0, rows = {}, factors, exponentials,
   exp, parsed, c, p, coefficient, powers, rates, base, degrees, coreRows,
   active, offset, q, a, z = Unique["flat$"], rr, coeffRows, realQ},
 local = Expand[Simplify[f /. x -> coord["Substitution"], ass && u > 0]];
 terms = If[Head[local] === Plus, List @@ local, {local}];
 Do[
  factors = If[Head[term] === Times, List @@ term, {term}];
  exponentials = Select[factors, MatchQ[#, Power[E, _]] && ! FreeQ[#[[2]], u] &];
  If[exponentials === {}, ordinary += term,
   exp = Total[#[[2]] & /@ exponentials];
   parsed = parseFinite[exp, u, ell, ass];
   If[parsed === $Failed || Length[parsed] =!= 1 || ! FreeQ[parsed[[1, 2]], ell],
    fail["UnsupportedFlatPhase", "Each flat phase must be -c/u^p with positive exact real c and p."]];
   {p, c} = {-parsed[[1, 1]], -parsed[[1, 2]]};
   If[! exactRealQ[p] || ! exactRealQ[c] || ! less[0, p] || ! less[0, c],
    fail["UnsupportedFlatPhase", "Each flat phase must have positive exact numeric c and p."]];
   coefficient = Simplify[term/(Times @@ exponentials), ass && u > 0];
   coeffRows = parseFinite[coefficient, u, ell, ass];
   If[coeffRows === $Failed || ! And @@ (exactRealQ[#[[1]]] &&
      corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ coeffRows),
    fail["UnsupportedFlatCoefficient", "Flat-sector coefficients must be finite real power-log expressions."]];
   AppendTo[rows, {c, p, coefficient, coeffRows}]], {term, terms}];
 If[rows === {}, fail["NoFlatSectors", "The forward expression contains no supported flat exponential."]];
 powers = DeleteDuplicates[rows[[All, 2]], equal];
 If[Length[powers] =!= 1, fail["IncompatibleFlatScales", "This finite sector engine requires a common positive phase power."]];
 p = First[powers]; rates = rows[[All, 1]]; base = First[Sort[rates, leq]];
 degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase rate must be an integer multiple of the smallest rate."]];
 coreRows = parseFinite[ordinary, u, ell, ass];
 If[coreRows === $Failed, fail["UnsupportedFlatCore", "The nonflat part must be an exact shifted monomial core."]];
 coreRows = jetMerge[coreRows, ell, ass];
 offset = Total[Cases[coreRows, {0, b_} /; FreeQ[b, ell] :> b]];
 If[! TrueQ[Simplify[Element[offset, Reals], ass]],
  fail["UnprovedRealOffset", "The target offset must be provably real under the parameter assumptions."]];
 active = Select[coreRows, ! (#[[1]] === 0 && FreeQ[#[[2]], ell]) &];
 If[Length[active] =!= 1 || ! FreeQ[active[[1, 2]], ell],
  fail["UnsupportedFlatCore", "A truncated algebraic inverse cannot serve as the exact zero sector; use an exact shifted monomial core."]];
 {q, a} = First[active];
 If[! exactRealQ[q] || q === 0 || ! (provablyPositive[a, ass] || provablyNegative[a, ass]),
  fail["UnsupportedFlatCore", "The exact monomial core needs a nonzero exact leading power and a provable real sign."]];
 rr = Total[MapThread[#1[[3]] z^#2 &, {rows, degrees}]];
 <|"PhasePower" -> p, "PhaseRate" -> base, "SectorDegrees" -> degrees,
   "FlatRows" -> rows, "CorePower" -> q, "CoreCoefficient" -> a, "Offset" -> offset,
   "Marker" -> z, "PerturbationPolynomial" -> flatTrim[rr, z, Max[degrees], limit]|>];

flatConstruct[f_, x_, x0_, y_, n_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticFlatInverse]] := Module[
 {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}],
  dir = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, Direction],
  r = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, "Power"],
  limit = OptionValue[AsymptoticAnalysis`AsymptoticFlatInverse, {opts}, "MaxTerms"],
  coord, u, ell = Unique["ell$"], model, z, q, a, p, c, fp, hp, rr,
  u0, rint, polynomial, term, k, j, sectors, allSectors, expression, zero,
  rem, tail, rowBounds, b, d, envelope, phase, powerPolynomial, boundBase},
 validateInput[f, limit];
 If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y],
  fail["InvalidVariables", "Use distinct source and target symbols and parameter-only assumptions."]];
 If[! IntegerQ[n] || n < 1 || n + 1 > limit,
  fail["InvalidSectorDepth", "The sector depth must be a positive integer below MaxTerms."]];
 If[! exactRealQ[r] || r === 0, fail["InvalidPower", "Power must be a nonzero exact real number."]];
 coord = localCoordinate[x, x0, dir]; u = coord["u"];
 If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative source branch requires an integer observable power."]];
 model = flatModel[f, x, coord, ell, ass, limit];
 {z, q, a, p, c, rr} = Lookup[model, {"Marker", "CorePower", "CoreCoefficient", "PhasePower", "PhaseRate", "PerturbationPolynomial"}];
 rint = If[coord["Infinite"], -r, r];
 u0 = ((y - model["Offset"])/a)^(1/q);
 fp = a q u^(q - 1); hp = coord["Sign"]^r rint u^(rint - 1);
 zero = If[r === 1 && ! coord["Infinite"], x0, 0] + coord["Sign"]^r u0^rint;
 polynomial = 0; powerPolynomial = 1;
 Do[
  powerPolynomial = flatTrim[powerPolynomial rr, z, n + 1, limit];
  term = flatTrim[hp powerPolynomial/fp, z, n + 1, limit];
  Do[term = flatTrim[(D[term, u] + c p u^(-p - 1) z D[term, z])/fp, z, n + 1, limit], {j, 1, k - 1}];
  polynomial = flatTrim[polynomial + (-1)^k term/k!, z, n + 1, limit], {k, 1, n + 1}];
 phase = Exp[-c/u0^p];
 allSectors = Table[{k, Simplify[Coefficient[polynomial, z, k], ass && u > 0] /. u -> u0}, {k, 1, n + 1}];
 sectors = Select[Take[allSectors, n], ! zeroQ[#[[2]], ass] &];
 expression = zero + Total[(#[[2]] phase^#[[1]]) & /@ sectors];
 (* A common analytic majorant uses |u-u0| = O(u0^(p+1)).
    Choose an envelope R/(u^q u^p) = O(u^-b M^d E), b,d >= 0. *)
 rowBounds = Flatten[model["FlatRows"][[All, 4]], 1];
 b = Max[0, Max[(q + p - #[[1]]) & /@ rowBounds]];
 d = Max[0, Max[polyDegree[#[[2]], ell] & /@ rowBounds]];
 envelope = u0^(-b) (1 + Abs[Log[u0]])^d;
 rem = phase^(n + 1) PowerLogRemainder[u0, canon[rint + p - (n + 1) b], (n + 1) d];
 GeneralizedSeries[<|"Kind" -> "FlatInverse", "Scale" -> "FiniteFlatSectors",
  "Expression" -> expression, "Variable" -> y, "Variables" -> {x, y}, "Function" -> f,
  "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "Power" -> r,
  "Assumptions" -> ass, "TargetDomain" -> ass && (y - model["Offset"])/a > 0,
  "CoreInverseCoordinate" -> u0, "ZeroSector" -> zero, "FlatScale" -> phase,
  "SectorDepth" -> n, "Sectors" -> sectors, "Terms" -> Join[{{0, zero}}, sectors],
  "TermConvention" -> "Each {k,C} contributes C FlatScale^k; SectorDepth includes k<=n. The zero sector is exact.",
  "FirstOmittedSector" -> Last[allSectors], "Remainder" -> rem,
  "RemainderScaleExpression" -> phase^(n + 1) u0^(rint + p - (n + 1) b) (1 + Abs[Log[u0]])^((n + 1) d),
  "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
    "SmallScale" -> envelope phase, "ObservableScale" -> u0^(rint + p),
    "Statement" -> "For fixed data, the complete omitted sector tail is at most C u0^(rint+p) (K chi)^(n+1)/(1-K chi) for chi=u0^(-b) M^d E sufficiently small. Constants and threshold are existential."|>,
  "ExactModel" -> True, "Model" -> model, "RemainderDerivativeOrder" -> 0,
  "FlatAnalyticRemainder" -> <|"Type" -> "ExactMonomialFlatIFT", "SourceDiskRadiusPower" -> 1 + p,
    "TargetDerivativePowerLoss" -> p + q, "AllFixedOrders" -> True|>,
  "SeriesData" -> Missing["IndependentFlatSectorTruncation"]|>]];

AsymptoticAnalysis`AsymptoticFlatInverse[f_, {x_Symbol, x0_}, {y_Symbol, n_}, opts : OptionsPattern[]] :=
 catch[flatConstruct[f, x, x0, y, n, opts]];
AsymptoticAnalysis`AsymptoticFlatInverse[___] := Failure["InvalidArguments", <|
 "MessageTemplate" -> "Use AsymptoticFlatInverse[f,{x,x0},{y,positiveIntegerSectorDepth}]."|>];
(* END SOURCE: src/Kernel/FlatSectors.wl *)

(* BEGIN SOURCE: src/Kernel/FlatSectorOperations.wl
   Source SHA256 (UTF-8/LF): 3bbcc50a0c5ca167800ef29f3318235eccfb04b38f5ace0b6e5c215b06274d28 *)
(* Two independent truncations: inclusive exponential degree and exclusive
   inner power. A discarded inner coefficient remains in its own sector. *)

AsymptoticAnalysis`FlatSeriesTruncate::usage =
"FlatSeriesTruncate[s,h] truncates each positive exponential sector at the exclusive inner power h in the positive monomial core coordinate. It preserves the exact zero sector and records separate inner and exponential-sector remainders.";
AsymptoticAnalysis`FlatSeriesMultiply::usage =
"FlatSeriesMultiply[s,t] multiplies finite flat-sector expansions in the same exact monomial target chart and phase. Unknown inner errors and the complete sector tail are propagated separately. An exact finite power-log scalar is also accepted.";
AsymptoticAnalysis`FlatSeriesObservable::usage =
"FlatSeriesObservable[s,H,z] substitutes s into an exact polynomial H in z. Its coefficients may be finite real power-log expressions in the common target chart. The zero sector is evaluated exactly.";
AsymptoticAnalysis`FlatSeriesDifferentiate::usage =
"FlatSeriesDifferentiate[s,n] differentiates n times with respect to the target variable, including the derivative of the flat exponential. Nonzero remainders require the qualified exact-flat-IFT analytic derivative contract.";

Options[AsymptoticAnalysis`FlatSeriesTruncate] = {"MaxTerms" -> 20000};
Options[AsymptoticAnalysis`FlatSeriesMultiply] = {"InnerCutoff" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticAnalysis`FlatSeriesObservable] = {"InnerCutoff" -> Automatic,
  "MaxTerms" -> 20000, "MaxPolynomialDegree" -> 32};
Options[AsymptoticAnalysis`FlatSeriesDifferentiate] = {"InnerCutoff" -> Automatic, "MaxTerms" -> 20000};

flatOpsAss[d_] := d["Assumptions"] && d["LocalVariable"] > 0;
flatOpsZero[ell_, ass_] := pConst[0, ell, ass];
flatOpsExactZeroQ[j_] := j[[1]] === {} && j[[2]] === Infinity;
flatOpsBudget[d_, limit_] := Module[{jets = d["SectorJets"]},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[Length[jets] > limit || LeafCount[jets] > limit,
    fail["ResourceLimit", "The retained flat-sector coefficient representation exceeded MaxTerms."]]; d];

flatOpsParse[e_, d_, limit_] := Module[{u = d["LocalVariable"], ell = d["LogVariable"], q, rows},
  validateInput[e, limit];
  q = Simplify[e /. d["Variable"] -> d["TargetOffset"] + d["CoreCoefficient"] u^d["CorePower"], flatOpsAss[d]];
  rows = parseFinite[q, u, ell, d["Assumptions"]];
  If[rows === $Failed || ! And @@ (exactRealQ[#[[1]]] &&
      corePerturbationRealPolynomialQ[#[[2]], ell, d["Assumptions"]] & /@ rows),
    fail["UnsupportedFlatCoefficient", "The exact coefficient must be a finite real power-log expression in the monomial core coordinate."]];
  {jetMerge[rows, ell, d["Assumptions"]], Infinity, 0}];

flatOpsData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {d, model, u = Unique["flatCoordinate$"], ell = Unique["flatLog$"], n, jets, tail, proof},
  If[AssociationQ[Lookup[a, "FlatRepresentation", None]],
    Return[flatOpsBudget[a["FlatRepresentation"], limit], Module]];
  If[Lookup[a, "Kind", ""] =!= "FlatInverse" || Lookup[a, "Scale", ""] =!= "FiniteFlatSectors" ||
     ! TrueQ[Lookup[a, "ExactModel", False]],
    fail["UnsupportedFlatSeries", "Use an exact-model AsymptoticFlatInverse or an expansion produced by the explicit flat-series operations."]];
  model = a["Model"]; n = a["SectorDepth"];
  If[! AssociationQ[model] || ! IntegerQ[n] || n < 1,
    fail["InvalidFlatRepresentation", "The flat inverse has no valid monomial model or sector depth."]];
  proof = Lookup[a, "FlatAnalyticRemainder", <||>];
  d = <|"Variable" -> a["Variable"], "LocalVariable" -> u, "LogVariable" -> ell,
    "CoreCoordinate" -> a["CoreInverseCoordinate"], "CorePower" -> model["CorePower"],
    "CoreCoefficient" -> model["CoreCoefficient"], "TargetOffset" -> model["Offset"],
    "PhaseRate" -> model["PhaseRate"], "PhasePower" -> model["PhasePower"],
    "Assumptions" -> a["Assumptions"], "TargetDomain" -> a["TargetDomain"], "SectorDepth" -> n,
    "InnerCutoff" -> Infinity, "DerivativeContract" -> (AssociationQ[proof] &&
      Lookup[proof, "Type", ""] === "ExactMonomialFlatIFT" && TrueQ[Lookup[proof, "AllFixedOrders", False]]),
    "DerivativeProvenance" -> proof, "DerivativeOrder" -> 0|>;
  jets = Table[flatOpsZero[ell, a["Assumptions"]], {n + 1}];
  jets[[1]] = flatOpsParse[a["ZeroSector"], d, limit];
  Do[jets[[row[[1]] + 1]] = flatOpsParse[row[[2]], d, limit], {row, a["Sectors"]}];
  tail = Cases[a["Remainder"], PowerLogRemainder[_, rho_, degree_] :> {rho, degree}, Infinity];
  If[Length[tail] =!= 1,
    fail["InvalidFlatRepresentation", "The original flat inverse must carry one complete omitted-sector bound."]];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> First[tail]|>], limit]];

flatOpsAlign[a_, b_] := Module[{ass = a["Assumptions"] && b["Assumptions"], aligned},
  If[a["Variable"] =!= b["Variable"] ||
    ! TrueQ[Simplify[a["CoreCoefficient"] == b["CoreCoefficient"] &&
      a["TargetOffset"] == b["TargetOffset"], ass]] ||
    ! equal[a["CorePower"], b["CorePower"]] || ! equal[a["PhasePower"], b["PhasePower"]] ||
    ! equal[a["PhaseRate"], b["PhaseRate"]],
    fail["IncompatibleFlatScales", "Flat-series operations require the same target variable, monomial chart, phase rate and phase power."]];
  aligned = b /. {b["LocalVariable"] -> a["LocalVariable"], b["LogVariable"] -> a["LogVariable"]};
  {Join[a, <|"Assumptions" -> ass, "TargetDomain" -> a["TargetDomain"] && b["TargetDomain"]|>],
   Join[aligned, <|"Assumptions" -> ass, "TargetDomain" -> a["TargetDomain"] && b["TargetDomain"]|>]}];

(* Bound a whole coefficient, including an unknown inner remainder. A finite
   exact zero has no magnitude contribution. Bounds never cancel by addition. *)
flatOpsJetBound[j_, ell_] := Module[{bound = j[[{2, 3}]]},
  If[j[[1]] =!= {}, bound = combinePrecision[bound,
    {j[[1, 1, 1]], polyDegree[j[[1, 1, 2]], ell]}]]; bound];
flatOpsBoundProduct[a_, b_] := If[a[[1]] === Infinity || b[[1]] === Infinity,
  {Infinity, 0}, {canon[a[[1]] + b[[1]]], a[[2]] + b[[2]]}];
flatOpsTailAdd[a_, b_] := combinePrecision[a, b];

flatOpsTruncateData[d0_, h_, limit_] := Module[{d = d0, jets, ell = d0["LogVariable"]},
  If[h === Automatic, Return[d, Module]];
  If[h =!= Infinity && ! exactRealQ[h], fail["InvalidCutoff", "The inner flat-sector cutoff must be an exact real number or Infinity."]];
  jets = d["SectorJets"];
  (* Sector zero remains exact, even when one of its powers exceeds h. *)
  Do[jets[[k + 1]] = seriesTrim[jets[[k + 1]], h, ell, d["Assumptions"]], {k, 1, d["SectorDepth"]}];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "InnerCutoff" -> h|>], limit]];

flatOpsMultiplyData[a0_, b0_, limit_] := Module[
  {a, b, n, na, nb, ell, ass, convolution, term, tail = {Infinity, 0}, aj, bj,
   aIndices, bIndices, data},
  {a, b} = flatOpsAlign[a0, b0];
  {na, nb} = {a["SectorDepth"], b["SectorDepth"]}; n = Min[na, nb];
  ell = a["LogVariable"]; ass = a["Assumptions"]; aj = a["SectorJets"]; bj = b["SectorJets"];
  If[(na + 1) (nb + 1) > limit,
    fail["ResourceLimit", "The complete flat-sector convolution exceeds MaxTerms pair products."]];
  (* Only exact zeros annihilate a pair. An empty finite part with an
     unknown inner remainder still contributes in its convolution sector. *)
  aIndices = Select[Range[na + 1], ! flatOpsExactZeroQ[aj[[#]]] &];
  bIndices = Select[Range[nb + 1], ! flatOpsExactZeroQ[bj[[#]]] &];
  convolution = Table[flatOpsZero[ell, ass], {na + nb + 1}];
  Do[term = pMul[aj[[i]], bj[[j]], ell, ass, limit];
    convolution[[i + j - 1]] = pAdd[convolution[[i + j - 1]], term, ell, ass],
    {i, aIndices}, {j, bIndices}];
  (* E^(k-N-1)<=1 for k>N. Keeping the coefficient's algebraic bound is
     conservative; it does not move an inner error to a later sector. *)
  Do[tail = flatOpsTailAdd[tail, flatOpsJetBound[convolution[[k + 1]], ell]], {k, n + 1, na + nb}];
  Do[tail = flatOpsTailAdd[tail, flatOpsBoundProduct[a["SectorTail"], flatOpsJetBound[j, ell]]], {j, bj}];
  Do[tail = flatOpsTailAdd[tail, flatOpsBoundProduct[b["SectorTail"], flatOpsJetBound[j, ell]]], {j, aj}];
  tail = flatOpsTailAdd[tail, flatOpsBoundProduct[a["SectorTail"], b["SectorTail"]]];
  data = Join[a, <|"SectorDepth" -> n, "SectorJets" -> Take[convolution, n + 1], "SectorTail" -> tail,
    "InnerCutoff" -> Automatic, "DerivativeContract" -> (TrueQ[a["DerivativeContract"]] && TrueQ[b["DerivativeContract"]]),
    "DerivativeProvenance" -> <|"Type" -> "ClosedUnderFlatOperations",
      "Inputs" -> {a["DerivativeProvenance"], b["DerivativeProvenance"]}|>|>];
  flatOpsBudget[data, limit]];

flatOpsConstantData[e_, d_, limit_] := Module[{j = flatOpsParse[e, d, limit], jets},
  jets = Prepend[Table[flatOpsZero[d["LogVariable"], d["Assumptions"]], {d["SectorDepth"]}], j];
  flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> {Infinity, 0},
    "InnerCutoff" -> Infinity, "DerivativeContract" -> True,
    "DerivativeProvenance" -> <|"Type" -> "ExactFinitePowerLogCoefficient"|>|>], limit]];

flatOpsAddData[a0_, b0_, limit_] := Module[{a, b, jets},
  {a, b} = flatOpsAlign[a0, b0];
  If[a["SectorDepth"] =!= b["SectorDepth"], fail["FlatSectorInvariant", "Internal polynomial addition requires equal retained sector depths."]];
  jets = MapThread[pAdd[#1, #2, a["LogVariable"], a["Assumptions"]] &, {a["SectorJets"], b["SectorJets"]}];
  flatOpsBudget[Join[a, <|"SectorJets" -> jets, "SectorTail" -> flatOpsTailAdd[a["SectorTail"], b["SectorTail"]],
    "InnerCutoff" -> Automatic, "DerivativeContract" -> (TrueQ[a["DerivativeContract"]] && TrueQ[b["DerivativeContract"]]),
    "DerivativeProvenance" -> <|"Type" -> "ClosedUnderFlatOperations",
      "Inputs" -> {a["DerivativeProvenance"], b["DerivativeProvenance"]}|>|>], limit]];

flatOpsObservableData[d_, h_, z_, degreeLimit_, limit_] := Module[{coefficients, result, degree},
  validateInput[h, limit];
  If[z === d["Variable"] || ! PolynomialQ[h, z],
    fail["UnsupportedFlatObservable", "The observable must be polynomial in a separate formal variable."]];
  If[! IntegerQ[degreeLimit] || degreeLimit < 0,
    fail["InvalidOption", "MaxPolynomialDegree must be a nonnegative integer."]];
  degree = If[h === 0, 0, Exponent[h, z]];
  If[degree > degreeLimit || degree + 1 > limit,
    fail["ResourceLimit", "The polynomial flat observable exceeds its degree budget."]];
  coefficients = CoefficientList[Expand[h], z]; If[coefficients === {}, coefficients = {0}];
  result = flatOpsConstantData[Last[coefficients], d, limit];
  Do[result = flatOpsAddData[flatOpsMultiplyData[result, d, limit],
      flatOpsConstantData[coefficients[[j]], d, limit], limit], {j, Length[coefficients] - 1, 1, -1}];
  result];

flatOpsDerivativeJet[j_, k_, d_, limit_] := Module[
  {q = d["CorePower"], a = d["CoreCoefficient"], p = d["PhasePower"], c = d["PhaseRate"],
   ell = d["LogVariable"], ass = d["Assumptions"], rows, rho, degree = j[[3]], boundary},
  rows = ({canon[#[[1]] - q], (#[[1]] #[[2]] + D[#[[2]], ell])/(a q)} &) /@ j[[1]];
  If[k > 0, rows = Join[rows, ({canon[#[[1]] - p - q], k c p #[[2]]/(a q)} &) /@ j[[1]]]];
  rho = If[j[[2]] === Infinity, Infinity, canon[j[[2]] - q - If[k > 0, p, 0]]];
  rows = jetMerge[rows, ell, ass];
  If[rho =!= Infinity,
    boundary = Select[rows, equal[#[[1]], rho] &];
    If[boundary =!= {}, degree = Max[degree, polyDegree[Total[boundary[[All, 2]]], ell]]]];
  {jetTrim[rows, rho, ell, ass], rho, degree}];

flatOpsDifferentiateData[d0_, n_, limit_] := Module[{d = d0, jets, tail, loss, hasError},
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The flat derivative order must be a nonnegative integer."]];
  If[n > limit, fail["ResourceLimit", "The flat derivative order exceeds MaxTerms."]];
  hasError = d["SectorTail"][[1]] =!= Infinity || AnyTrue[d["SectorJets"], #[[2]] =!= Infinity &];
  If[n > 0 && hasError && ! TrueQ[d["DerivativeContract"]],
    fail["UnprovedFlatRemainderDerivative", "Differentiating a nonzero flat remainder requires the exact monomial flat-IFT analytic derivative contract."]];
  loss = canon[d["PhasePower"] + d["CorePower"]];
  Do[jets = MapIndexed[flatOpsDerivativeJet[#1, First[#2] - 1, d, limit] &, d["SectorJets"]];
    tail = d["SectorTail"]; If[tail[[1]] =!= Infinity, tail = {canon[tail[[1]] - loss], tail[[2]]}];
    d = flatOpsBudget[Join[d, <|"SectorJets" -> jets, "SectorTail" -> tail,
      "InnerCutoff" -> Automatic, "DerivativeOrder" -> d["DerivativeOrder"] + 1|>], limit], {n}]; d];

flatOpsMake[d_, recipe_] := Module[
  {u0 = d["CoreCoordinate"], ell = d["LogVariable"], phase, jets = d["SectorJets"], sectors, zero,
   inner, tail = d["SectorTail"], sectorRemainder, remainder, envelope, expression, coefficient},
  phase = Exp[-d["PhaseRate"]/u0^d["PhasePower"]];
  coefficient[j_] := Total[(u0^#[[1]] (#[[2]] /. ell -> Log[u0])) & /@ j[[1]]];
  zero = coefficient[First[jets]];
  sectors = Select[Table[{k, coefficient[jets[[k + 1]]]}, {k, d["SectorDepth"]}], ! zeroQ[#[[2]], d["Assumptions"]] &];
  expression = zero + Total[(#[[2]] phase^#[[1]]) & /@ sectors];
  inner = Select[Table[{k, If[jets[[k + 1, 2]] === Infinity, 0,
    PowerLogRemainder[u0, jets[[k + 1, 2]], jets[[k + 1, 3]]]]}, {k, 1, d["SectorDepth"]}], #[[2]] =!= 0 &];
  sectorRemainder = If[tail[[1]] === Infinity, 0,
    phase^(d["SectorDepth"] + 1) PowerLogRemainder[u0, tail[[1]], tail[[2]]]];
  remainder = sectorRemainder + Total[(phase^#[[1]] #[[2]]) & /@ inner];
  envelope = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  GeneralizedSeries[<|"Kind" -> "FlatDerived", "Scale" -> "FiniteFlatSectors", "Variable" -> d["Variable"],
    "Expression" -> expression, "Assumptions" -> d["Assumptions"], "TargetDomain" -> d["TargetDomain"],
    "CoreInverseCoordinate" -> u0, "FlatScale" -> phase, "ZeroSector" -> zero, "Sectors" -> sectors,
    "Terms" -> Join[{{0, zero}}, sectors], "SectorDepth" -> d["SectorDepth"], "InnerCutoff" -> d["InnerCutoff"],
    "TermConvention" -> "Sector degrees k<=N are inclusive; positive-sector inner powers alpha<h are exclusive. Sector zero remains exact.",
    "InnerRemainders" -> inner, "SectorRemainder" -> sectorRemainder, "Remainder" -> remainder,
    "RemainderScaleExpression" -> envelope, "Exact" -> (remainder === 0),
    "RetainedCoefficientPrecision" -> Table[{k, jets[[k + 1, {2, 3}]]}, {k, 1, d["SectorDepth"]}],
    "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
      "Statement" -> "The sum of the recorded positive-sector inner bounds and the separately recorded complete sector-tail bound is valid for fixed data sufficiently near the branch endpoint. Unknown bounds do not cancel."|>,
    "FlatAnalyticRemainder" -> d["DerivativeProvenance"], "RemainderDerivativeOrder" -> If[remainder === 0 || TrueQ[d["DerivativeContract"]], Infinity, 0],
    "FlatRepresentation" -> d, "FlatRecipe" -> recipe, "SeriesData" -> Missing["IndependentFlatSectorTruncations"]|>]];

AsymptoticAnalysis`FlatSeriesTruncate[s_GeneralizedSeries, h_, OptionsPattern[]] :=
  catch[flatOpsMake[flatOpsTruncateData[flatOpsData[s, OptionValue["MaxTerms"]], h, OptionValue["MaxTerms"]], {"Truncate", {s}, h}]];
AsymptoticAnalysis`FlatSeriesMultiply[s_GeneralizedSeries, t_GeneralizedSeries, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsMultiplyData[flatOpsData[s, OptionValue["MaxTerms"]], flatOpsData[t, OptionValue["MaxTerms"]], OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"Multiply", {s, t}}]]];
AsymptoticAnalysis`FlatSeriesMultiply[s_GeneralizedSeries, c_ /; FreeQ[c, _GeneralizedSeries], OptionsPattern[]] := catch[Module[{d},
  d = flatOpsData[s, OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[flatOpsMultiplyData[d, flatOpsConstantData[c, d, OptionValue["MaxTerms"]], OptionValue["MaxTerms"]],
    OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"MultiplyScalar", {s}, c}]]];
AsymptoticAnalysis`FlatSeriesMultiply[c_ /; FreeQ[c, _GeneralizedSeries], s_GeneralizedSeries, opts : OptionsPattern[]] :=
  AsymptoticAnalysis`FlatSeriesMultiply[s, c, opts];
AsymptoticAnalysis`FlatSeriesObservable[s_GeneralizedSeries, h_, z_Symbol, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsObservableData[flatOpsData[s, OptionValue["MaxTerms"]], h, z,
    OptionValue["MaxPolynomialDegree"], OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"PolynomialObservable", {s}, h, z}]]];
AsymptoticAnalysis`FlatSeriesDifferentiate[s_GeneralizedSeries, n_Integer : 1, OptionsPattern[]] := catch[Module[{d},
  d = flatOpsDifferentiateData[flatOpsData[s, OptionValue["MaxTerms"]], n, OptionValue["MaxTerms"]];
  flatOpsMake[flatOpsTruncateData[d, OptionValue["InnerCutoff"], OptionValue["MaxTerms"]], {"Differentiate", {s}, n}]]];

AsymptoticAnalysis`FlatSeriesTruncate[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesTruncate[flatSeries,exactInnerCutoff]."|>];
AsymptoticAnalysis`FlatSeriesMultiply[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesMultiply[flatSeries,flatSeriesOrExactScalar]."|>];
AsymptoticAnalysis`FlatSeriesObservable[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesObservable[flatSeries,polynomial,formalVariable]."|>];
AsymptoticAnalysis`FlatSeriesDifferentiate[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use FlatSeriesDifferentiate[flatSeries,nonnegativeIntegerOrder]."|>];
(* END SOURCE: src/Kernel/FlatSectorOperations.wl *)

(* BEGIN SOURCE: src/Kernel/FourierCoefficients.wl
   Source SHA256 (UTF-8/LF): 0d2351bf891ccce10c3a62ed07c5e2847ad8c90cdd08f2fcdd23fda4f62e615b *)
(* Finite Fourier-polynomial coefficient algebra in L = Log[u].
   A coefficient is {{omega,P_omega(L)},...}, representing
   Sum[P_omega(L) Exp[I omega L]]. Source weights remain separate. *)

AsymptoticAnalysis`AsymptoticFourierInverse::usage =
"AsymptoticFourierInverse[f,{x,x0},{y,cutoff}] inverts a monomial leading core with strictly higher source-power perturbations having finite Fourier-polynomial coefficients in Log[u]. Frequencies are exact real numbers; MaxFrequencies is a hard budget, not a frequency truncation. The target-power cutoff is exclusive.";
AsymptoticAnalysis`FourierInverseResidual::usage =
"FourierInverseResidual[s] independently composes the finite Fourier forward model with its inverse jet and checks the residual below the stored relative source-weight cutoff.";
AsymptoticAnalysis`FourierInverseCoefficient::usage =
"FourierInverseCoefficient[s,k] returns the exact coefficient for a multi-index k, as modes and as a real trigonometric expression in the stored logarithmic variable.";

Options[AsymptoticAnalysis`AsymptoticFourierInverse] = Join[Options[AsymptoticInverse], {"MaxFrequencies" -> 256}];

fourierPoly[q_, ell_, ass_] := Module[{coefficients, canonical, expanded},
  expanded = Expand[Simplify[q, ass && Element[ell, Reals]]];
  If[! PolynomialQ[expanded, ell], fail["NonPolynomialFourierAmplitude", "Fourier amplitudes must be polynomials in the logarithmic variable."]];
  canonical[c_] := If[NumericQ[c] && TrueQ[Simplify[Element[c, Algebraics]]], RootReduce[c], Simplify[c, ass]];
  coefficients = canonical /@ CoefficientList[expanded, ell];
  Expand[coefficients . ell^Range[0, Length[coefficients] - 1]]];

(* The first entry is an exact source weight or frequency. Mathematical
   equality, rather than structural equality, groups algebraic resonances. *)
fourierWeightGroups[rows_List] := orderedWeightGroups[MapAt[canon, #, 1] & /@ rows];
fourierFrequencyBudget[count_, limit_] := If[count > limit,
  fail["FrequencyLimit", "The exact Fourier coefficient exceeds MaxFrequencies; no modes were silently discarded.",
    <|"MaxFrequencies" -> limit, "RequiredFrequencies" -> count|>]];
fourierJetFrequencies[rows_List] := #[[1, 1]] & /@ fourierWeightGroups[
  List /@ Flatten[(#[[2, All, 1]] &) /@ rows]];

fourierMerge[rows_List, ell_, ass_, frequencyLimit_] := Module[{groups, result},
  If[rows === {}, Return[{}, Module]];
  groups = fourierWeightGroups[rows];
  result = {#[[1, 1]], fourierPoly[Total[#[[All, 2]]], ell, ass]} & /@ groups;
  result = Select[result, ! TrueQ[Simplify[#[[2]] == 0, ass && Element[ell, Reals]]] &];
  fourierFrequencyBudget[Length[result], frequencyLimit]; result];
fourierScale[a_, scalar_, ell_, ass_, limit_] := fourierMerge[{#[[1]], scalar #[[2]]} & /@ a, ell, ass, limit];
fourierAdd[a_, b_, ell_, ass_, limit_] := fourierMerge[Join[a, b], ell, ass, limit];
fourierMul[a_, b_, ell_, ass_, limit_, frequencyLimit_] := Module[{rows},
  If[Length[a] Length[b] > limit, fail["ResourceLimit", "Fourier convolution exceeded MaxTerms candidate pairs."]];
  rows = Flatten[Table[{aa[[1]] + bb[[1]], Expand[aa[[2]] bb[[2]]]}, {aa, a}, {bb, b}], 1];
  fourierMerge[rows, ell, ass, frequencyLimit]];
fourierEuler[a_, ell_, ass_, limit_] := fourierMerge[
  {#[[1]], D[#[[2]], ell] + I #[[1]] #[[2]]} & /@ a, ell, ass, limit];
fourierPower[a_, n_Integer?NonNegative, ell_, ass_, limit_, frequencyLimit_] := Module[
  {power = n, base = a, result = {{0, 1}}},
  While[power > 0,
   If[OddQ[power], result = fourierMul[result, base, ell, ass, limit, frequencyLimit]];
   power = Quotient[power, 2];
   If[power > 0, base = fourierMul[base, base, ell, ass, limit, frequencyLimit]]];
  result];
fourierRealQ[a_, ell_, ass_, limit_] := fourierMerge[Join[a,
   {-#[[1]], -Conjugate[#[[2]]]} & /@ a], ell, ass && Element[ell, Reals], limit] === {};
fourierExpression[a_, ell_, ass_] := Simplify[Expand[ExpToTrig[
   Total[(#[[2]] Exp[I #[[1]] ell]) & /@ a]]], ass && Element[ell, Reals]];
fourierDegree[a_, ell_] := If[a === {}, 0, Max[Exponent[#[[2]], ell] & /@ a]];
fourierEnvelope[a_, ell_, size_, ass_] := Total[Function[row,
   Total[MapIndexed[Simplify[Abs[#1], ass] size^(First[#2] - 1) &, CoefficientList[row[[2]], ell]]]] /@ a];

fourierReadCoefficient[expression_, ell_, ass_, frequencyLimit_] := Module[
  {expanded = Expand[TrigToExp[expression]], terms, rows = {}, frequency, polynomial, factors, exponent, omega},
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Do[
   frequency = 0; polynomial = 1; factors = If[Head[term] === Times, List @@ term, {term}];
   Do[Which[
     Head[factor] === Power && factor[[1]] === E && ! FreeQ[factor[[2]], ell],
      exponent = Expand[factor[[2]]];
      If[! PolynomialQ[exponent, ell] || Exponent[exponent, ell] > 1, Return[$Failed, Module]];
      omega = Simplify[Coefficient[exponent, ell]/I, ass];
      If[! exactRealQ[omega], Return[$Failed, Module]];
      frequency += omega; polynomial *= Exp[exponent /. ell -> 0],
     PolynomialQ[factor, ell], polynomial *= factor,
     True, Return[$Failed, Module]], {factor, factors}];
   AppendTo[rows, {frequency, polynomial}], {term, terms}];
  fourierMerge[rows, ell, ass, frequencyLimit]];

fourierJetMerge[rows_, ell_, ass_, limit_, frequencyLimit_] := Module[{groups, result},
  If[rows === {}, Return[{}, Module]];
  groups = fourierWeightGroups[rows];
  result = {#[[1, 1]], fourierMerge[Flatten[#[[All, 2]], 1], ell, ass, frequencyLimit]} & /@ groups;
  result = Select[result, #[[2]] =!= {} &];
  If[Length[result] > limit, fail["ResourceLimit", "The Fourier source-weight jet exceeds MaxTerms."]];
  fourierFrequencyBudget[Length[fourierJetFrequencies[result]], frequencyLimit]; result];
fourierJetTrim[rows_, cutoff_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetMerge[Select[rows, less[First[#], cutoff] &], ell, ass, limit, frequencyLimit];
fourierJetAdd[a_, b_, cutoff_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetTrim[Join[a, b], cutoff, ell, ass, limit, frequencyLimit];
fourierJetScale[a_, c_, ell_, ass_, limit_, frequencyLimit_] :=
  fourierJetMerge[{#[[1]], fourierScale[#[[2]], c, ell, ass, frequencyLimit]} & /@ a, ell, ass, limit, frequencyLimit];
fourierJetMul[a_, b_, cutoff_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {rows = {}, count = 0, last = Length[b]},
  (* Source jets are sorted. Retain the original row-major convolution and
     failure order while skipping columns beyond the exclusive cutoff. *)
  Do[If[cutoff =!= Infinity,
    While[last > 0 && ! less[aa[[1]] + b[[last, 1]], cutoff], last--]];
   Do[count++; If[count > limit, fail["ResourceLimit", "Fourier jet multiplication exceeded MaxTerms retained pairs."]];
    AppendTo[rows, {aa[[1]] + b[[j, 1]], fourierMul[aa[[2]], b[[j, 2]], ell, ass, limit, frequencyLimit]}],
    {j, last}], {aa, a}];
  fourierJetMerge[rows, ell, ass, limit, frequencyLimit]];

fourierRead[f_, x_, coord_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {u = coord["u"], expression, terms, rows = {}, factors, weight, coefficient, modes},
  expression = Expand[Simplify[f /. x -> coord["Substitution"], ass && u > 0] /. Log[u] -> ell];
  terms = If[Head[expression] === Plus, List @@ expression, {expression}];
  Do[
   weight = 0; coefficient = 1; factors = If[Head[term] === Times, List @@ term, {term}];
   Do[Which[FreeQ[factor, u], coefficient *= factor,
     factor === u, weight++,
     Head[factor] === Power && factor[[1]] === u && exactRealQ[factor[[2]]], weight += factor[[2]],
     True, Return[$Failed, Module]], {factor, factors}];
   modes = fourierReadCoefficient[coefficient, ell, ass, frequencyLimit];
   If[modes === $Failed, Return[$Failed, Module]];
   AppendTo[rows, {weight, modes}], {term, terms}];
  fourierJetMerge[rows, ell, ass, limit, frequencyLimit]];

fourierCoefficient[k_, gaps_, coefficients_, p_, r_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {n = Total[k], weight, modes = {{0, 1}}},
  If[n === 0, Return[{0, modes}, Module]];
  If[n > limit, fail["ResourceLimit", "The Fourier coefficient depth exceeds MaxTerms."]];
  weight = canon[k . gaps];
  Do[If[k[[j]] > 0,
    modes = fourierMul[modes, fourierPower[coefficients[[j]], k[[j]], ell, ass, limit, frequencyLimit],
      ell, ass, limit, frequencyLimit]], {j, Length[k]}];
  Do[modes = fourierAdd[fourierEuler[modes, ell, ass, frequencyLimit],
     fourierScale[modes, r + weight + p j, ell, ass, frequencyLimit], ell, ass, frequencyLimit], {j, 1, n - 1}];
  {weight, fourierScale[modes, (-1)^n r/(p^n Times @@ (Factorial /@ k)), ell, ass, frequencyLimit]}];

fourierComposeBlock[u_, power_, modes_, cutoff_, ell_, ass_, limit_, frequencyLimit_] := Module[
  {answer, product = {{0, {{0, 1}}}}, coefficient = modes, k = 0},
  answer = fourierJetTrim[{{0, modes}}, cutoff, ell, ass, limit, frequencyLimit];
  If[u === {}, Return[answer, Module]];
  If[! less[0, u[[1, 1]]], fail["NonSmallJet", "Fourier unit composition needs positive source-weight valuation."]];
  While[True,
   (* Positive valuation makes exhausted support permanent. The homogeneous
      recurrence likewise stays zero after complete coefficient cancellation;
      establish both facts before spending a further product budget. *)
   If[! less[product[[1, 1]] + u[[1, 1]], cutoff], Break[]];
   coefficient = fourierScale[fourierAdd[fourierEuler[coefficient, ell, ass, frequencyLimit],
       fourierScale[coefficient, power - k, ell, ass, frequencyLimit], ell, ass, frequencyLimit],
     1/(k + 1), ell, ass, frequencyLimit];
   If[coefficient === {}, Break[]];
   If[k >= limit, fail["ResourceLimit", "Fourier unit composition exceeded MaxTerms iterations."]];
   product = fourierJetMul[product, u, cutoff, ell, ass, limit, frequencyLimit];
   If[product === {}, Break[]];
   answer = fourierJetAdd[answer, fourierJetMul[product, {{0, coefficient}}, cutoff, ell, ass, limit, frequencyLimit],
     cutoff, ell, ass, limit, frequencyLimit]; k++];
  answer];

fourierConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticFourierInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}],
   direction = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, Direction],
   r = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, "Power"],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, "MaxTerms"],
   frequencyLimit = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, "MaxFrequencies"],
   input = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, "InputRemainder"],
   method = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, Method],
   truncation = OptionValue[AsymptoticAnalysis`AsymptoticFourierInverse, {opts}, "Truncation"],
   coord, ell = Unique["fourierLog$"], rows, offset = 0, p, amplitude, gaps, coefficients,
   rint, h, region, blocks, boundary, beta, degree, degrees, inputCap, inputDegree,
   sign, target, w, z, logz, terms, expression, rem, domain, frequencies},
  If[! FreeQ[f, _Real], fail["InexactInput", "Fourier input and frequencies must be exact."]];
  If[! FreeQ[f, Indeterminate | _DirectedInfinity], fail["NonfiniteInput", "The Fourier expression must contain finite constants."]];
  If[! IntegerQ[limit] || limit < 1 || ! IntegerQ[frequencyLimit] || frequencyLimit < 1,
   fail["InvalidOption", "MaxTerms and MaxFrequencies must be positive integers."]];
  If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y], fail["InvalidVariables", "Use distinct source and target symbols, and parameter-only assumptions."]];
  If[method =!= "Lagrange" || truncation =!= "Exponent",
   fail["UnsupportedOption", "The Fourier engine uses Lagrange coefficients and explicit exponent truncation."]];
  If[! exactRealQ[r] || r === 0, fail["InvalidOption", "Power must be a nonzero exact real number."]];
  If[! exactRealQ[cutoff], fail["InvalidCutoff", "The Fourier engine requires an explicit exact target-power cutoff."]];
  coord = localCoordinate[x, x0, direction];
  If[coord["Sign"] === -1 && ! IntegerQ[r], fail["NonrealObservable", "A negative source branch requires integer observable powers."]];
  rows = fourierRead[f, x, coord, ell, ass, limit, frequencyLimit];
  If[rows === $Failed, Return[$Failed, Module]];
  If[rows === {}, fail["ZeroFunction", "The Fourier expression is zero or constant."]];
  If[! And @@ (fourierRealQ[#[[2]], ell, ass, frequencyLimit] & /@ rows),
   fail["NonRealFourierCoefficient", "The Fourier coefficients do not satisfy the real conjugacy relations under the assumptions."]];
  If[rows[[1, 1]] === 0 && MatchQ[rows[[1, 2]], {{0, _}}] && FreeQ[rows[[1, 2, 1, 2]], ell],
   offset = rows[[1, 2, 1, 2]]; rows = Rest[rows]];
  If[rows === {}, fail["ZeroFunction", "The Fourier expression is constant."]];
  p = rows[[1, 1]];
  If[p === 0 || ! MatchQ[rows[[1, 2]], {{0, _}}] || ! FreeQ[rows[[1, 2, 1, 2]], ell],
   fail["OscillatoryLeadingBlock", "The Fourier engine requires a nonzero monomial leading core; oscillatory or logarithmic leading coefficients are not assigned an eventual sign."]];
  amplitude = rows[[1, 2, 1, 2]];
  If[! (provablyPositive[amplitude, ass] || provablyNegative[amplitude, ass]), fail["UnprovedSign", "The monomial leading coefficient must have a proved nonzero real sign."]];
  gaps = canon[#[[1]] - p] & /@ Rest[rows];
  coefficients = fourierScale[#[[2]], 1/amplitude, ell, ass, frequencyLimit] & /@ Rest[rows];
  rint = If[coord["Infinite"], -r, r]; h = canon[Abs[p] cutoff - rint];
  If[! less[0, h], fail["CutoffTooSmall", "The target cutoff must exceed the leading observable exponent."]];
  region = indexRegion[gaps, h, False, limit];
  blocks = fourierJetMerge[fourierCoefficient[#, gaps, coefficients, p, rint, ell, ass, limit, frequencyLimit] & /@
     region["Inside"], ell, ass, limit, frequencyLimit];
  boundary = region["Boundary"];
  beta = If[boundary === {}, Infinity, Min[canon[# . gaps] & /@ boundary]];
  degrees = fourierDegree[#, ell] & /@ coefficients;
  degree = If[boundary === {}, 0, Max[(# . degrees) & /@ boundary]];
  beta = If[beta === Infinity, Infinity, canon[(rint + beta)/Abs[p]]];
  If[! MemberQ[{None, Automatic}, input],
   If[! MatchQ[input, {_?exactRealQ, _Integer?NonNegative}] || ! less[rows[[-1, 1]], input[[1]]],
    fail["InvalidInputRemainder", "InputRemainder must have an exact exponent above all supplied source powers and a nonnegative logarithmic degree; a matching derivative bound is required."]];
   inputCap = canon[(input[[1]] - p + rint)/Abs[p]];
   If[less[inputCap, cutoff], fail["InsufficientInputOrder", "The Fourier request exceeds the transported forward precision.", <|"MaximumCutoff" -> inputCap|>]];
   If[less[inputCap, beta], beta = inputCap; degree = input[[2]],
    If[equal[inputCap, beta], degree = Max[degree, input[[2]]]]]];
  sign = If[provablyPositive[amplitude, ass], 1, -1]; target = (y - offset)/amplitude;
  w = If[less[0, p], sign (y - offset), sign/y]; z = target^(1/p); logz = Log[target]/p;
  terms = {canon[(rint + #[[1]])/Abs[p]],
      coord["Sign"]^r Abs[amplitude]^(-(rint + #[[1]])/p) (fourierExpression[#[[2]], ell, ass] /. ell -> logz)} & /@ blocks;
  expression = If[r === 1 && ! coord["Infinite"], x0, 0] + Total[(w^#[[1]] #[[2]]) & /@ terms];
  rem = If[beta === Infinity, 0, PowerLogRemainder[w, beta, degree]];
  frequencies = fourierJetFrequencies[blocks];
  domain = ass && target > 0 && 0 < z < 1;
  GeneralizedSeries[<|"Kind" -> "FourierInverse", "Scale" -> "FourierPolynomialCoefficients", "Method" -> "Lagrange",
    "Expression" -> expression, "Terms" -> terms, "Blocks" -> blocks,
    "FourierFrequencies" -> frequencies, "MaxFrequencies" -> frequencyLimit,
    "CoefficientEnvelopes" -> ({#[[1]], fourierEnvelope[#[[2]], ell, 1 + Abs[logz], ass]} & /@ blocks),
    "Remainder" -> rem, "RemainderVariable" -> w, "RemainderPower" -> beta, "RemainderLogDegree" -> degree,
    "RemainderScaleExpression" -> If[beta === Infinity, 0, w^beta (1 + Abs[Log[w]])^degree],
    "RemainderExplanation" -> "The complete boundary is bounded with Fourier coefficient norms and polynomial envelopes; zeros of individual oscillatory factors are never used as error scales.",
    "RemainderDerivativeOrder" -> 0, "LogVariable" -> ell, "LogarithmicValue" -> logz,
    "Uniformizer" -> z, "NormalizedSourceWeightCutoff" -> h, "Cutoff" -> cutoff, "Power" -> r,
    "IndexRegion" -> region, "PowerGaps" -> gaps, "NormalizedCoefficients" -> coefficients,
    "CoefficientDegreeBounds" -> degrees, "LeadingPower" -> p, "LeadingCoefficient" -> amplitude,
    "Function" -> f, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> x0,
    "Direction" -> coord["Direction"], "LocalVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "Limit" -> If[less[0, p], offset, sign Infinity], "Assumptions" -> ass, "TargetDomain" -> domain,
    "InputRemainder" -> input, "ExactModel" -> MemberQ[{None, Automatic}, input],
    "TermConvention" -> "Each {beta,C} contributes w^beta C in the positive RemainderVariable w. Blocks store source-weight corrections with finite Fourier-polynomial modes in LogVariable.",
    "ConvergenceContract" -> <|"Type" -> "FiniteAnalyticFourierLift", "NumericCertificate" -> False|>,
    "SeriesData" -> Missing["FourierCoefficientScale"]|>]];

AsymptoticAnalysis`AsymptoticFourierInverse[f_, {x_Symbol, x0_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] := catch[
  Module[{result = fourierConstruct[f, x, x0, y, cutoff, opts]},
   If[result === $Failed, fail["UnsupportedFourierScale", "The expression is not a finite power sum with Fourier-polynomial logarithmic coefficients."], result]]];
AsymptoticAnalysis`AsymptoticFourierInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticFourierInverse[f,{x,x0},{y,cutoff}], with an explicit exact cutoff."|>];

fourierResidual[a_, cutoff_, limit_] := Module[
  {ell = a["LogVariable"], ass = a["Assumptions"], frequencyLimit = a["MaxFrequencies"],
   h = cutoff, r, unit, answer, part, gaps = a["PowerGaps"], coefficients = a["NormalizedCoefficients"], p = a["LeadingPower"]},
  If[h === Automatic, h = a["NormalizedSourceWeightCutoff"]];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "The Fourier residual cutoff must be positive and exact."]];
  r = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  unit = Select[a["Blocks"], less[0, #[[1]]] &];
  If[r =!= 1,
   unit = fourierJetAdd[fourierComposeBlock[unit, 1/r, {{0, 1}}, h, ell, ass, limit, frequencyLimit],
     {{0, {{0, -1}}}}, h, ell, ass, limit, frequencyLimit]];
  answer = fourierJetAdd[fourierComposeBlock[unit, p, {{0, 1}}, h, ell, ass, limit, frequencyLimit],
    {{0, {{0, -1}}}}, h, ell, ass, limit, frequencyLimit];
  Do[If[less[gaps[[j]], h],
    part = fourierComposeBlock[unit, p + gaps[[j]], coefficients[[j]], h - gaps[[j]], ell, ass, limit, frequencyLimit];
    answer = fourierJetAdd[answer, {#[[1]] + gaps[[j]], #[[2]]} & /@ part, h, ell, ass, limit, frequencyLimit]], {j, Length[gaps]}];
  <|"ZeroBelowCutoff" -> (answer === {}), "ResidualBlocks" -> answer,
    "NormalizedResidual" -> Total[(a["Uniformizer"]^#[[1]] (fourierExpression[#[[2]], ell, ass] /. ell -> a["LogarithmicValue"])) & /@ answer],
    "RelativeCutoff" -> h, "Scope" -> "Exact formal composition with the stored finite Fourier forward expression; unspecified InputRemainder terms are not composed."|>];
Options[AsymptoticAnalysis`FourierInverseResidual] = {"MaxTerms" -> 20000};
AsymptoticAnalysis`FourierInverseResidual[GeneralizedSeries[a_Association], cutoff_: Automatic, OptionsPattern[]] := catch[
  If[Lookup[a, "Kind", None] =!= "FourierInverse", fail["UnsupportedResidual", "A Fourier inverse object is required."]];
  fourierResidual[a, cutoff, OptionValue["MaxTerms"]]];
AsymptoticAnalysis`FourierInverseResidual[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use FourierInverseResidual[FourierInverseResult] or FourierInverseResidual[result,relativeCutoff]."|>];
AsymptoticAnalysis`FourierInverseCoefficient[GeneralizedSeries[a_Association], k_List] := catch[Module[{r, coefficient},
  If[Lookup[a, "Kind", None] =!= "FourierInverse" || Length[k] =!= Length[a["PowerGaps"]] ||
    ! And @@ (IntegerQ[#] && NonNegative[#] & /@ k), fail["InvalidMultiIndex", "Supply a nonnegative integer multi-index of the Fourier model's dimension."]];
  r = If[MemberQ[{Infinity, -Infinity}, a["ExpansionPoint"]], -a["Power"], a["Power"]];
  coefficient = fourierCoefficient[k, a["PowerGaps"], a["NormalizedCoefficients"], a["LeadingPower"], r,
    a["LogVariable"], a["Assumptions"], 20000, a["MaxFrequencies"]];
  <|"Weight" -> coefficient[[1]], "Modes" -> coefficient[[2]],
    "Expression" -> fourierExpression[coefficient[[2]], a["LogVariable"], a["Assumptions"]],
    "LogVariable" -> a["LogVariable"]|>]];
AsymptoticAnalysis`FourierInverseCoefficient[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use FourierInverseCoefficient[FourierInverseResult,nonnegativeIntegerMultiIndex]."|>];
(* END SOURCE: src/Kernel/FourierCoefficients.wl *)

(* BEGIN SOURCE: src/Kernel/SpecialFunctionAdapters.wl
   Source SHA256 (UTF-8/LF): 374d1c7007a1736568fc52d2840b44840cacfbcce8441340d73f8f79c14b639a *)
(* Real special-function adapters with explicit forward-model provenance.
   Finite Poincare models are never labelled convergent exact forward data. *)

AsymptoticAnalysis`AsymptoticSpecialInverse::usage =
"AsymptoticSpecialInverse[family,{x,x0},{y,cutoff}] supports Erfc, LogGamma, Gamma, LambertThreshold and QuadraticThreshold. Erfc uses a power cutoff in its logarithmic target coordinate; gamma adapters use an integer exact-core marker depth; threshold adapters use a local target-power cutoff. ModelTerms controls the finite asymptotic forward model. TargetOffset and TargetScale apply an exact real affine change of target.";
AsymptoticAnalysis`SpecialInverseNumericalCheck::usage =
"SpecialInverseNumericalCheck[result,target] compares an adapter with the original special-function equation at high precision, using logarithmic equations for gamma and erfc tails. This is numerical evidence, not an interval certificate.";

Options[AsymptoticAnalysis`AsymptoticSpecialInverse] = {
  Assumptions :> $Assumptions, Direction -> Automatic, "ModelTerms" -> Automatic,
  "TargetOffset" -> 0, "TargetScale" -> 1, "QuadraticCoefficient" -> 1,
  "LambertBranch" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticAnalysis`SpecialInverseNumericalCheck] = {WorkingPrecision -> 60};

specialModelTerms[requested_, default_, limit_] := Module[{m = If[requested === Automatic, default, requested]},
  If[! IntegerQ[m] || m < 1, fail["InvalidModelTerms", "ModelTerms must be a positive integer or Automatic."]];
  If[m > limit, fail["ResourceLimit", "The special-function forward model exceeds MaxTerms."]]; m];

specialErfc[fam_, x_, endpoint_, y_, cutoff_, ass_, direction_, modelTerms_, offset_, scale_, limit_] := Module[
  {m, v = Unique["erfcTarget$"], z = Unique["erfcSource$"], w = Unique["erfcPower$"],
   s, polynomial, phase, inner, target, positiveTail, sign, alpha, delta,
   exactPhase, forwardBound, derivativeBound, phaseBound, phaseDerivativeBound,
   expression, remainder, tailScale, domain, original, innerData, terms, tailModel, representation},
  If[! MemberQ[{Infinity, -Infinity}, endpoint], fail["UnsupportedEndpoint", "The Erfc tail adapter requires a source infinity."]];
  localCoordinate[x, endpoint, direction];
  If[! exactRealQ[cutoff] || ! less[0, cutoff], fail["InvalidCutoff", "The Erfc logarithmic-target cutoff must be a positive exact real number."]];
  m = specialModelTerms[modelTerms, Max[1, Ceiling[cutoff + 1/2]], limit];
  If[less[m + 1/2, cutoff], fail["InsufficientModelOrder", "The Erfc model transports inverse precision only through ModelTerms+1/2.", <|"MaximumCutoff" -> m + 1/2|>]];
  s = Sum[(-1)^k Pochhammer[1/2, k] w^k, {k, 0, m - 1}];
  polynomial = Expand[Normal[Series[-Log[s], {w, 0, m - 1}]]];
  phase = z^2 + Log[z] + (polynomial /. w -> z^-2);
  inner = construct[phase, z, Infinity, v, cutoff, Assumptions -> ass,
    "InputRemainder" -> {2 m, 0}, "MaxTerms" -> limit];
  If[FailureQ[inner], Return[inner, Module]];
  sign = If[endpoint === Infinity, 1, -1];
  positiveTail = If[sign === 1, (y - offset)/scale, 2 - (y - offset)/scale];
  target = -Log[Sqrt[Pi] positiveTail];
  innerData = inner[[1]] /. v -> target;
  expression = sign innerData["Expression"]; remainder = innerData["Remainder"];
  tailScale = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  alpha = Pochhammer[1/2, m]; delta = alpha z^(-2 m); s = s /. w -> z^-2;
  forwardBound = Exp[-z^2] delta/(Sqrt[Pi] z);
  derivativeBound = 2 m alpha z^(-2 m - 1);
  exactPhase = z^2 + Log[z] - Log[s];
  phaseBound = delta/(s - delta) + Abs[exactPhase - phase];
  phaseDerivativeBound = derivativeBound/(s - delta) + Abs[D[s, z]] delta/(s (s - delta)) + Abs[D[exactPhase - phase, z]];
  domain = ass && 0 < positiveTail < 1 && target > 1;
  original = offset + scale Erfc[x];
  tailModel = Exp[-z^2] s/(Sqrt[Pi] z);
  terms = ({#[[1]], sign #[[2]]} & /@ innerData["Terms"]);
  representation = seriesData[inner, limit] /. v -> target;
  representation = Join[representation, <|"Variable" -> y, "Domain" -> domain,
    "Prefactor" -> sign representation["Prefactor"], "Offset" -> sign representation["Offset"]|>];
  GeneralizedSeries[Join[innerData, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction",
    "Adapter" -> "Erfc", "Expression" -> expression, "Terms" -> terms,
    "SeriesRepresentation" -> representation,
    "Remainder" -> remainder, "RemainderScaleExpression" -> tailScale,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y},
    "ExpansionPoint" -> endpoint, "Direction" -> If[sign === 1, "FromBelow", "FromAbove"],
    "Limit" -> If[sign === 1, offset, offset + 2 scale], "TargetDomain" -> domain,
    "TargetOffset" -> offset, "TargetScale" -> scale, "TargetCoordinateExpression" -> target,
    "PositiveTailExpression" -> positiveTail, "SourceSign" -> sign,
    "SourceDomain" -> sign x > 0, "CoordinateSeries" -> inner,
    "CoordinateSubstitution" -> {v -> target}, "CoordinateSourceSign" -> sign,
    "TransformedFunction" -> (phase /. z -> sign x),
    "ExactTransformedFunction" -> -Log[Sqrt[Pi] Erfc[sign x]],
    "ForwardModel" -> (offset + scale If[sign === 1, tailModel, 2 - tailModel] /. z -> sign x),
    "NormalizedTailPolynomial" -> (s /. z -> sign x), "ModelTerms" -> m,
    "ForwardRemainderBound" -> (Abs[scale] forwardBound /. z -> sign x),
    "NormalizedTailRemainderBound" -> (delta /. z -> sign x),
    "NormalizedTailDerivativeRemainderBound" -> (derivativeBound /. z -> sign x),
    "PhaseRemainderBound" -> (phaseBound /. z -> sign x),
    "PhaseDerivativeRemainderBound" -> (phaseDerivativeBound /. z -> sign x),
    "ForwardBoundConditions" -> sign x > 0,
    "PhaseBoundConditions" -> (z > 0 && s > delta /. z -> sign x),
    "ForwardRemainderContract" -> <|"Type" -> "PoincareWithFirstNeglectedTermBound", "ConvergentForwardSeries" -> False,
      "PhaseAsymptoticPair" -> {2 m, 0}, "MatchingDerivativePair" -> {2 m + 1, 0},
      "Reference" -> "https://dlmf.nist.gov/7.12.i",
      "BoundMeaning" -> "For positive source magnitude the erfc remainder is bounded by the first neglected term. Phase bounds additionally require the finite normalized polynomial to exceed that error bound."|>,
    "ExactModel" -> False, "InputRemainder" -> {2 m, 0},
    "AccuracyFloor" -> <|"Coordinate" -> 1/target, "Power" -> m + 1/2|>,
    "TermConvention" -> "An ordinary inverse expansion in v=-Log[Sqrt[Pi] positiveTail], composed with its exact target transformation; cutoff is exclusive in the positive coordinate 1/v.",
    "SeriesData" -> Missing["SpecialFunctionTargetCoordinate"],
    "SwitchingContract" -> "Explicit tail adapter. No automatic numerical crossover threshold is asserted."|>]]];

specialGamma[fam_, x_, endpoint_, y_, depth_, ass_, direction_, modelTerms_, offset_, scale_, limit_] := Module[
  {m, v = Unique["gammaTarget$"], core, perturbation, inner, data, target, alpha, rho, original, domain},
  If[endpoint =!= Infinity, fail["UnsupportedEndpoint", "Gamma adapters currently use the increasing positive branch at +Infinity."]];
  localCoordinate[x, endpoint, direction];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "Gamma adapters use a nonnegative integer exact-core marker depth."]];
  m = specialModelTerms[modelTerms, Max[1, Ceiling[(depth + 1)/2]], limit];
  core = x (Log[x] - 1);
  perturbation = -Log[x]/2 + Log[2 Pi]/2 + Sum[BernoulliB[2 k]/(2 k (2 k - 1) x^(2 k - 1)), {k, 1, m - 1}];
  rho = 2 m - 1; alpha = Abs[BernoulliB[2 m]]/(2 m (2 m - 1));
  inner = AsymptoticAnalysis`AsymptoticCoreInverse[core, perturbation, {x, Infinity}, {v, depth},
    Assumptions -> ass, "InputRemainder" -> {rho, 0}, "MaxTerms" -> limit];
  If[FailureQ[inner], Return[inner, Module]];
  target = If[fam === "Gamma", Log[(y - offset)/scale], (y - offset)/scale];
  data = inner[[1]] /. v -> target;
  original = offset + scale If[fam === "Gamma", Gamma[x], LogGamma[x]];
  domain = ass && If[fam === "Gamma", (y - offset)/scale > 1, (y - offset)/scale > 0];
  GeneralizedSeries[Join[data, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction", "Adapter" -> fam,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y}, "TargetDomain" -> domain,
    "ExpansionPoint" -> Infinity, "Direction" -> "FromBelow", "Limit" -> If[provablyPositive[scale, ass], Infinity, -Infinity],
    "TargetOffset" -> offset, "TargetScale" -> scale, "TargetCoordinateExpression" -> target,
    "SourceDomain" -> x > 2, "CoordinateSeries" -> inner, "CoordinateSubstitution" -> {v -> target},
    "ExactTransformedFunction" -> LogGamma[x], "TransformedFunction" -> core + perturbation,
    "ForwardModel" -> core + perturbation, "ForwardModelScope" -> "LogGamma in the exact transformed target equation", "ModelTerms" -> m,
    "ForwardRemainderBound" -> alpha x^-rho,
    "ForwardDerivativeRemainderBound" -> rho alpha x^(-rho - 1),
    "ForwardBoundConditions" -> x > 0,
    "OriginalDerivativeLowerBound" -> Log[x] - 1/(2 x) - 1/(12 x^2),
    "ForwardRemainderContract" -> <|"Type" -> "StirlingPoincareWithFirstNeglectedTermBound",
      "ConvergentForwardSeries" -> False, "BoundAppliesTo" -> "LogGamma in the transformed target equation",
      "Reference" -> "https://dlmf.nist.gov/5.11.ii", "InputRemainderPair" -> {rho, 0},
      "DerivativeRemainderPair" -> {rho + 1, 0}|>,
    "ExactModel" -> False, "InputRemainder" -> {rho, 0},
    "AccuracyFloor" -> <|"Coordinate" -> data["CoreLocalInverse"], "Power" -> rho|>,
    "AdapterCutoffMeaning" -> "Inclusive marker depth around the retained exact Lambert inverse of x(Log[x]-1). It is not an exponent-sorted jet; the Stirling input remainder may coarsen the marker-tail bound.",
    "SeriesData" -> Missing["RetainedExactCoreSpecialFunction"],
    "SwitchingContract" -> "The increasing real source branch x>2 is selected explicitly; no automatic near-minimum or crossover adapter is asserted."|>]]];

specialThreshold[fam_, x_, endpoint_, y_, cutoff_, ass_, direction_, branch_, offset_, scale_, quadratic_, limit_] := Module[
  {dir = direction, chosen = branch, v = Unique["thresholdTarget$"], inner, data, target, domain,
   original, exactInverse, coefficient, sign},
  If[! exactRealQ[cutoff] || ! less[1/2, cutoff], fail["InvalidCutoff", "A threshold cutoff must exceed the leading square-root power 1/2."]];
  If[fam === "LambertThreshold",
    If[endpoint =!= -1, fail["UnsupportedEndpoint", "The real Lambert threshold is centered at the source point -1."]];
    If[chosen === Automatic, chosen = If[dir === "FromBelow", -1, 0]];
    If[! MemberQ[{0, -1}, chosen], fail["InvalidLambertBranch", "The real threshold branches are 0 and -1."]];
    If[dir === Automatic, dir = If[chosen === 0, "FromAbove", "FromBelow"]];
    If[dir =!= If[chosen === 0, "FromAbove", "FromBelow"], fail["ConflictingBranch", "LambertBranch and source Direction select different real branches."]];
    inner = construct[x Exp[x], x, -1, v, cutoff, Assumptions -> ass, Direction -> dir, "MaxTerms" -> limit];
    If[FailureQ[inner], Return[inner, Module]];
    target = (y - offset)/scale; data = inner[[1]] /. v -> target;
    domain = ass && -1/E < target < 0; original = offset + scale x Exp[x];
    exactInverse = ProductLog[chosen, target],
    If[! exactRealQ[endpoint], fail["UnsupportedEndpoint", "The quadratic vertex must be an exact real finite source point."]];
    If[! (provablyPositive[quadratic, ass] || provablyNegative[quadratic, ass]), fail["UnprovedSign", "QuadraticCoefficient needs a provable nonzero real sign."]];
    If[dir === Automatic, dir = "FromAbove"];
    localCoordinate[x, endpoint, dir]; sign = If[dir === "FromAbove", 1, -1];
    coefficient = scale quadratic; original = offset + coefficient (x - endpoint)^2;
    inner = construct[original, x, endpoint, y, cutoff, Assumptions -> ass, Direction -> dir, "MaxTerms" -> limit];
    If[FailureQ[inner], Return[inner, Module]];
    data = inner[[1]]; target = (y - offset)/coefficient;
    domain = ass && target > 0; exactInverse = endpoint + sign Sqrt[target]; chosen = Missing["QuadraticSourceDirection"]];
  GeneralizedSeries[Join[data, <|"Kind" -> "SpecialInverse", "Scale" -> "SpecialFunction", "Adapter" -> fam,
    "Function" -> original, "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> endpoint,
    "Direction" -> dir, "TargetDomain" -> domain, "TargetOffset" -> offset, "TargetScale" -> scale,
    "ExactInverseExpression" -> exactInverse, "ThresholdBranch" -> chosen,
    "Limit" -> If[fam === "LambertThreshold", offset - scale/E, offset],
    "ThresholdTarget" -> If[fam === "LambertThreshold", offset - scale/E, offset],
    "ThresholdUniformizer" -> If[fam === "LambertThreshold", Sqrt[2 (1 + E target)], Sqrt[target]],
    "CoordinateSeries" -> inner, "CoordinateSubstitution" -> If[fam === "LambertThreshold", {v -> target}, {}],
    "ForwardRemainderContract" -> <|"Type" -> "ExactLocalRamifiedEquation", "ConvergentForwardSeries" -> True,
      "Reference" -> If[fam === "LambertThreshold", "https://dlmf.nist.gov/4.13", "Exact quadratic formula"]|>,
    "ExactForwardModel" -> True, "SeriesData" -> Missing["ExplicitThresholdCoordinate"],
    "SwitchingContract" -> "Explicit real local branch. Neighboring representations can be compared at a user-selected overlap point; no unproved automatic switching threshold is used."|>]]];

specialConstruct[fam_, x_, endpoint_, y_, cutoff_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticSpecialInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}],
   dir = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, Direction],
   m = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "ModelTerms"],
   offset = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "TargetOffset"],
   scale = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "TargetScale"],
   q = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "QuadraticCoefficient"],
   branch = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "LambertBranch"],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticSpecialInverse, {opts}, "MaxTerms"], result},
  validateInput[{offset, scale, q}, limit];
  If[x === y || ! FreeQ[{offset, scale, q, ass}, x | y], fail["InvalidVariables", "Source and target symbols must be distinct, with parameter-only options and assumptions."]];
  If[! TrueQ[Simplify[Element[offset, Reals], ass]] ||
     ! (provablyPositive[scale, ass] || provablyNegative[scale, ass]), fail["UnprovedSign", "TargetOffset must be provably real and TargetScale must have a provable nonzero real sign."]];
  result = Switch[fam,
    "Erfc", specialErfc[fam, x, endpoint, y, cutoff, ass, dir, m, offset, scale, limit],
    "LogGamma" | "Gamma", specialGamma[fam, x, endpoint, y, cutoff, ass, dir, m, offset, scale, limit],
    "LambertThreshold" | "QuadraticThreshold", specialThreshold[fam, x, endpoint, y, cutoff, ass, dir, branch, offset, scale, q, limit],
    _, fail["UnknownSpecialFunctionAdapter", "Available adapters are Erfc, LogGamma, Gamma, LambertThreshold and QuadraticThreshold."]];
  If[FailureQ[result], Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"RequestedCutoff" -> cutoff,
    "AdapterOptions" -> {Assumptions -> ass, Direction -> dir, "ModelTerms" -> m,
      "TargetOffset" -> offset, "TargetScale" -> scale, "QuadraticCoefficient" -> q,
      "LambertBranch" -> branch}|>]]];

AsymptoticAnalysis`AsymptoticSpecialInverse[fam_String, {x_Symbol, endpoint_}, {y_Symbol, cutoff_}, opts : OptionsPattern[]] :=
  catch[specialConstruct[fam, x, endpoint, y, cutoff, opts]];
AsymptoticAnalysis`AsymptoticSpecialInverse[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use AsymptoticSpecialInverse[family,{x,endpoint},{y,cutoff}]."|>];

specialNumerical[a_, target_, wp_] := Module[{x, y, approximate, reference, equation, tt, bound},
  If[! IntegerQ[wp] || wp < 20, fail["InvalidPrecision", "WorkingPrecision must be an integer of at least 20 digits."]];
  If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp), fail["InsufficientPrecision", "Supply an exact target or enough input precision."]];
  {x, y} = a["Variables"];
  If[! TrueQ[N[a["TargetDomain"] /. y -> target, wp + 20]], fail["OutsideBranch", "The target is outside the adapter's selected real branch."]];
  (* Substitute exact target expressions before N so small reflected erfc
     tails and Log[Exp[v]] do not lose digits by subtracting rounded values. *)
  approximate = N[a["Expression"] /. y -> target, wp + 20];
  If[! NumericQ[approximate] || ! TrueQ[Im[approximate] == 0], fail["InvalidSeed", "The adapter did not produce a real numerical seed."]];
  If[MemberQ[{"LambertThreshold", "QuadraticThreshold"}, a["Adapter"]],
    reference = N[a["ExactInverseExpression"] /. y -> target, wp + 20],
    equation = a["ExactTransformedFunction"]; tt = N[a["TargetCoordinateExpression"] /. y -> target, wp + 20];
    If[Precision[tt] < wp, fail["InsufficientPrecision", "The transformed target lost precision through cancellation; supply a more precise or exact target."]];
    reference = With[{xx = x, ff = equation, rhs = tt, start = approximate, precision = wp + 20, goal = wp},
      Quiet[Check[xx /. FindRoot[ff == rhs, {xx, start}, WorkingPrecision -> precision,
        AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 200], $Failed]]]];
  If[reference === $Failed || ! NumericQ[reference] || ! TrueQ[Im[reference] == 0], fail["ReferenceRootNotFound", "The original special-function equation did not yield a real numerical reference."]];
  If[KeyExistsQ[a, "SourceDomain"] && ! TrueQ[a["SourceDomain"] /. x -> reference], fail["OutsideBranch", "The numerical reference left the selected source branch."]];
  bound = N[Lookup[a, "RemainderScaleExpression", a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]] /. y -> target, wp];
  <|"ReferenceRoot" -> N[reference, wp], "Approximation" -> N[approximate, wp],
    "Error" -> N[Abs[reference - approximate], wp], "RemainderScale" -> bound,
    "Ratio" -> If[TrueQ[bound == 0], Indeterminate, N[Abs[reference - approximate]/bound, wp]],
    "Evidence" -> "High-precision comparison with the original special-function equation or exact local inverse; no interval certificate.",
    "Adapter" -> a["Adapter"], "Certified" -> False|>];

AsymptoticAnalysis`SpecialInverseNumericalCheck[GeneralizedSeries[a_Association], target_, opts : OptionsPattern[]] :=
  catch[If[Lookup[a, "Kind", None] =!= "SpecialInverse", fail["InvalidAdapterObject", "Supply a special-function adapter result."]]; specialNumerical[a, target, OptionValue[WorkingPrecision]]];
AsymptoticAnalysis`SpecialInverseNumericalCheck[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use SpecialInverseNumericalCheck[adapterResult,target]."|>];
(* END SOURCE: src/Kernel/SpecialFunctionAdapters.wl *)

(* BEGIN SOURCE: src/Kernel/ExponentialCorePerturbation.wl
   Source SHA256 (UTF-8/LF): 8c5e8bcc4f87f6ce37d86f88d9d1dad81ae3e0ec0654d4f5bcb4a821b01f9f2a *)
(* Exact growing exponential cores with finite power-log perturbations.
   Loaded in Private`.  Exact Lambert/elementary cores remain unexpanded. *)

AsymptoticAnalysis`AsymptoticExponentialCoreInverse::usage =
"AsymptoticExponentialCoreInverse[core,perturbation,{x,x0},{y,n}] retains the exact inverse of a growing exponential core a v^b Exp[c v^p]+offset, c,p>0, and computes complete corrections through exponential degree n for a finite power-log perturbation. The positive v tends to Infinity. At source infinities SourceShift may translate v; finite endpoints use reciprocal source distance. InputRemainder->{rho,k} declares O(v^-rho (1+Log[v])^k) with matching derivative control and is transported as a separate first-sector error.";
Options[AsymptoticAnalysis`AsymptoticExponentialCoreInverse] = {
  Assumptions :> $Assumptions, Direction -> Automatic, "SourceShift" -> Automatic,
  "CoreInverse" -> Automatic, "CoreCheckTimeConstraint" -> 3,
  "InputRemainder" -> None, "MaxTerms" -> 20000};

exponentialCoreShifts[core_, x_, ass_] := Module[{candidates},
  candidates = Cases[core, e_Plus /; PolynomialQ[e, x] && Exponent[e, x] === 1 :>
    Simplify[-Coefficient[e, x, 0]/Coefficient[e, x, 1], ass], {0, Infinity}];
  DeleteDuplicates[Prepend[Select[candidates, FreeQ[#, x] && TrueQ[Simplify[Element[#, Reals], ass]] &], 0]]];

exponentialCoreCoordinates[core_, x_, endpoint_, direction_, shift_, ass_] := Module[
  {coord, v = Unique["exponentialCoreSource$"], shifts, source, normalized, parsed, selected},
  coord = localCoordinate[x, endpoint, direction];
  If[coord["Infinite"],
    shifts = If[shift === Automatic, exponentialCoreShifts[core, x, ass], {shift}];
    If[! And @@ (exactQ[#] && FreeQ[#, x] && TrueQ[Simplify[Element[#, Reals], ass]] & /@ shifts),
      fail["InvalidSourceShift", "SourceShift must be an exact provably real parameter independent of the source."]];
    selected = $Failed;
    Do[
      source = candidate + coord["Sign"] v;
      normalized = Simplify[core /. x -> source, ass && v > 0];
      parsed = lambertExponentialCore[normalized, v, ass];
      If[AssociationQ[parsed] && TrueQ[parsed["Exact"]] && provablyPositive[parsed["c"], ass],
        selected = <|"Variable" -> v, "Reconstruction" -> source, "SourceShift" -> candidate,
          "CoreLocal" -> normalized, "CoreParameters" -> parsed,
          "Direction" -> coord["Direction"], "Sign" -> coord["Sign"], "ObservablePower" -> 1,
          "InfiniteSource" -> True|>; Break[]], {candidate, shifts}];
    selected,
    If[shift =!= Automatic && shift =!= 0, fail["UnsupportedSourceShift", "At a finite source endpoint the endpoint itself fixes the source distance."]];
    source = endpoint + coord["Sign"]/v;
    normalized = Simplify[core /. x -> source, ass && v > 0];
    parsed = lambertExponentialCore[normalized, v, ass];
    If[! AssociationQ[parsed] || ! TrueQ[parsed["Exact"]] || ! provablyPositive[parsed["c"], ass], Return[$Failed, Module]];
    <|"Variable" -> v, "Reconstruction" -> source, "SourceShift" -> endpoint,
      "CoreLocal" -> normalized, "CoreParameters" -> parsed, "Direction" -> coord["Direction"],
      "Sign" -> coord["Sign"], "ObservablePower" -> -1, "InfiniteSource" -> False|>]];

exponentialCoreExactInverse[coordinates_, y_, requested_, ass_, seconds_] := Module[
  {parameters = coordinates["CoreParameters"], a, b, c, p, offset, positiveTarget,
   v0, argument, branch, exactSource, base, domain, equality},
  {a, b, c, p, offset} = Lookup[parameters, {"a", "b", "c", "p", "Offset"}];
  If[! And @@ (TrueQ[Simplify[Element[#, Reals], ass]] & /@ {a, c, offset}) ||
     ! (provablyPositive[a, ass] || provablyNegative[a, ass]),
    fail["UnprovedExponentialCoreData", "The core amplitude and offset must be provably real, and the amplitude must have a provable nonzero sign."]];
  positiveTarget = (y - offset)/a;
  If[b === 0,
    v0 = (Log[positiveTarget]/c)^(1/p); branch = Missing["Elementary"];
    argument = Missing["Elementary"]; domain = positiveTarget > 1,
    argument = (c p/b) positiveTarget^(p/b);
    branch = If[less[0, b], 0, -1];
    base = (b/(c p)) ProductLog[branch, argument];
    v0 = base^(1/p); domain = positiveTarget > 0 && base > 0;
    If[branch === -1, domain = domain && -1/E < argument < 0]];
  domain = ass && domain && Element[v0, Reals] && v0 > 1 && b + c p v0^p > 0;
  exactSource = coordinates["Reconstruction"] /. coordinates["Variable"] -> v0;
  If[requested =!= Automatic,
    If[! exactQ[requested] || ! FreeQ[requested, coordinates["Variable"] | Indeterminate | _DirectedInfinity],
      fail["InvalidCoreInverse", "CoreInverse must be a finite exact target expression."]];
    equality = Quiet[TimeConstrained[FullSimplify[requested == exactSource, domain], seconds, $Failed]];
    If[! TrueQ[equality], fail["UnverifiedCoreInverse", "The supplied expression could not be proved equal to the selected exact exponential-core inverse."]];
    exactSource = requested];
  <|"LocalInverse" -> v0, "SourceInverse" -> exactSource, "PositiveTarget" -> positiveTarget,
    "TargetDomain" -> domain, "LambertBranch" -> branch, "LambertArgument" -> argument,
    "Certificate" -> <|"Type" -> "RecognizedExactGrowingExponentialCore",
      "Identity" -> True, "Branch" -> branch,
      "Statement" -> "The positive local inverse tends to Infinity on the eventually monotone branch of a v^b Exp[c v^p], c,p>0."|>|>];

exponentialCoreCoefficient[n_, perturbation_, hprime_, denominator_, v_, c_, p_, ass_, limit_] := Module[{q, j},
  q = Together[hprime perturbation^n/denominator];
  Do[
    q = Together[(D[q, v] - j c p v^(p - 1) q)/denominator];
    If[LeafCount[q] > limit, fail["ResourceLimit", "An exponential-core coefficient derivative exceeded MaxTerms leaves."]],
    {j, 1, n - 1}];
  q = Simplify[(-1)^n q/n!, ass && v > 0];
  If[LeafCount[q] > limit, fail["ResourceLimit", "An exponential-core coefficient exceeded MaxTerms leaves."]]; q];

exponentialCoreConstruct[core_, perturbation_, x_, endpoint_, y_, depth_, opts : OptionsPattern[AsymptoticAnalysis`AsymptoticExponentialCoreInverse]] := Module[
  {ass = optionAssumptions[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}],
   direction = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, Direction],
   shift = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, "SourceShift"],
   requested = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, "CoreInverse"],
   seconds = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, "CoreCheckTimeConstraint"],
   input = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, "InputRemainder"],
   limit = OptionValue[AsymptoticAnalysis`AsymptoticExponentialCoreInverse, {opts}, "MaxTerms"],
   coordinates, parameters, v, ell = Unique["ell$"], localPerturbation, rows,
   a, b, c, p, offset, inverse, v0, exactSource, denominator, hprime, localCoefficients,
   coefficients, sectors, exponential, targetSector, expression, d, k, rint, envelope,
   sectorRemainder, sectorScale, inputRemainder = 0, inputScale = 0, inputContract = None,
   rho, logdegree, remainder, coefficientList, exact, targetLimit},
  validateInput[{core, perturbation}, limit];
  If[x === y || ! FreeQ[{core, perturbation}, y] || ! FreeQ[ass, x | y] || ! FreeQ[{shift, requested}, x],
    fail["InvalidVariables", "Use distinct source and target symbols, parameter-only assumptions, and a source-independent CoreInverse and SourceShift."]];
  If[! IntegerQ[depth] || depth < 0, fail["InvalidDepth", "Exponential sector depth must be a nonnegative integer."]];
  If[depth + 1 > limit, fail["ResourceLimit", "The requested depth and first omitted coefficient exceed MaxTerms."]];
  If[! NumericQ[seconds] || ! TrueQ[seconds > 0], fail["InvalidOption", "CoreCheckTimeConstraint must be positive."]];
  coordinates = exponentialCoreCoordinates[core, x, endpoint, direction, shift, ass];
  If[coordinates === $Failed, fail["UnsupportedExponentialCore", "The selected source chart must expose an exact growing core a v^b Exp[c v^p]+offset with c,p>0; additional core terms are not silently truncated."]];
  v = coordinates["Variable"]; parameters = coordinates["CoreParameters"];
  {a, b, c, p, offset} = Lookup[parameters, {"a", "b", "c", "p", "Offset"}];
  localPerturbation = Simplify[perturbation /. x -> coordinates["Reconstruction"], ass && v > 0];
  rows = parseFinite[localPerturbation, v, ell, ass];
  If[rows === $Failed, fail["UnsupportedExponentialPerturbation", "The perturbation must be a finite power-log expression in the positive divergent core coordinate."]];
  rows = jetMerge[rows, ell, ass];
  If[! And @@ (exactRealQ[#[[1]]] && corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ rows),
    fail["UnprovedPerturbationData", "Perturbation exponents must be exact real constants and all logarithmic coefficients must be provably real."]];
  inverse = exponentialCoreExactInverse[coordinates, y, requested, ass, seconds];
  v0 = inverse["LocalInverse"]; exactSource = inverse["SourceInverse"];
  denominator = a v^(b - 1) (b + c p v^p); hprime = D[coordinates["Reconstruction"], v];
  exact = rows === {};
  localCoefficients = If[exact, {}, Table[{n,
    exponentialCoreCoefficient[n, localPerturbation, hprime, denominator, v, c, p, ass, limit]}, {n, 1, depth + 1}]];
  coefficients = localCoefficients /. v -> v0; sectors = Take[coefficients, UpTo[depth]];
  exponential = Exp[-c v0^p]; targetSector = v0^b/inverse["PositiveTarget"];
  expression = exactSource + Total[(#[[2]] targetSector^#[[1]]) & /@ sectors];
  rint = coordinates["ObservablePower"];
  d = If[exact, 0, Max[0, Max[#[[1]] - b & /@ rows]]];
  k = If[exact, 0, Max[polyDegree[#[[2]], ell] & /@ rows]];
  envelope = v0^d (1 + Abs[Log[v0]])^k;
  sectorRemainder = If[exact, 0, targetSector^(depth + 1)
    PowerLogRemainder[1/v0, canon[p - rint - (depth + 1) d], (depth + 1) k]];
  sectorScale = If[exact, 0, targetSector^(depth + 1)
    v0^(rint - p + (depth + 1) d) (1 + Abs[Log[v0]])^((depth + 1) k)];
  If[! MemberQ[{None, Automatic}, input],
    If[! MatchQ[input, {_, _Integer?NonNegative}] || ! exactRealQ[input[[1]]],
      fail["InvalidInputRemainder", "InputRemainder must be {rho,k}: O(v^-rho M(v)^k) with matching derivative O(v^-rho-1 M(v)^k)."]];
    {rho, logdegree} = input;
    inputRemainder = targetSector PowerLogRemainder[1/v0, canon[b + p + rho - rint], logdegree];
    inputScale = targetSector v0^(rint - b - p - rho) (1 + Abs[Log[v0]])^logdegree;
    inputContract = <|"ForwardPair" -> {rho, logdegree}, "DerivativePair" -> {rho + 1, logdegree},
      "Coordinate" -> 1/v, "InverseSector" -> 1,
      "Statement" -> "A declared unknown polynomial-scale forward error induces a first-exponential-sector inverse error. This accuracy ceiling is independent of the retained model's sector depth."|>];
  remainder = sectorRemainder + inputRemainder;
  targetLimit = If[provablyPositive[a, ass], Infinity, -Infinity];
  GeneralizedSeries[<|"Kind" -> "ExponentialCoreInverse", "Scale" -> "ExactExponentialCoreSectors",
    "Expression" -> expression, "Remainder" -> remainder, "RemainderScaleExpression" -> sectorScale + inputScale,
    "Core" -> core, "Perturbation" -> perturbation, "Function" -> core + perturbation,
    "Variable" -> y, "Variables" -> {x, y}, "ExpansionPoint" -> endpoint, "Direction" -> coordinates["Direction"],
    "SourceShift" -> coordinates["SourceShift"], "SourceCoordinate" -> coordinates,
    "LocalVariable" -> v, "LocalSubstitution" -> (x -> coordinates["Reconstruction"]),
    "CoreInverse" -> exactSource, "CoreLocalInverse" -> v0, "CoreParameters" -> parameters,
    "CoreCertificate" -> inverse["Certificate"], "LambertBranch" -> inverse["LambertBranch"],
    "LambertArgument" -> inverse["LambertArgument"], "Limit" -> targetLimit,
    "TargetDomain" -> inverse["TargetDomain"], "Assumptions" -> ass,
    "ExactExponentialScale" -> exponential, "SectorVariable" -> targetSector,
    "SectorVariableIdentity" -> "Exp[-c v0^p] = v0^b/((y-offset)/a), by the exact core inverse identity.",
    "Sectors" -> sectors, "Terms" -> Join[{{0, exactSource}}, sectors],
    "LocalSectorCoefficients" -> localCoefficients, "SectorDepth" -> depth,
    "FirstOmittedSector" -> If[exact, {depth + 1, 0}, Last[coefficients]],
    "TermConvention" -> "The zero term is the exact selected core inverse. Each {n,Cn}, n>=1, contributes Cn SectorVariable^n; coefficients retain the exact core inverse and sector depth is inclusive.",
    "SectorRemainder" -> sectorRemainder, "SectorRemainderScale" -> sectorScale,
    "InputRemainder" -> input, "InputRemainderContract" -> inputContract,
    "InputRemainderTerm" -> inputRemainder, "InputRemainderScale" -> inputScale,
    "MajorantContract" -> <|"Type" -> "AsymptoticExistence", "NumericCertificate" -> False,
      "Envelope" -> envelope, "SmallScale" -> envelope targetSector,
      "ObservableScale" -> v0^(rint - p), "EnvelopePower" -> d, "EnvelopeLogDegree" -> k,
      "Statement" -> "For fixed data, the complete omitted model tail is at most C v0^(rint-p) (K chi)^(N+1)/(1-K chi), chi=v0^d M(v0)^k Exp[-c v0^p], sufficiently near the endpoint. Constants and threshold are existential."|>,
    "RemainderExplanation" -> "The model's complete sector tail is bounded independently of its first omitted coefficient. A declared unknown input error is transported separately and can dominate every additional retained model sector.",
    "ExactModel" -> MemberQ[{None, Automatic}, input], "ExactInverse" -> (remainder === 0),
    "Power" -> 1, "Truncation" -> "ExponentialSectorDepth", "SeriesData" -> Missing["ExactExponentialCoreScale"],
    "RemainderDerivativeOrder" -> 0|>]];

AsymptoticAnalysis`AsymptoticExponentialCoreInverse[core_, perturbation_, {x_Symbol, endpoint_}, {y_Symbol, depth_}, opts : OptionsPattern[]] :=
  catch[exponentialCoreConstruct[core, perturbation, x, endpoint, y, depth, opts]];
AsymptoticAnalysis`AsymptoticExponentialCoreInverse[___] := Failure["InvalidArguments", <|
  "MessageTemplate" -> "Use AsymptoticExponentialCoreInverse[core,perturbation,{x,endpoint},{y,depth}]."|>];
(* END SOURCE: src/Kernel/ExponentialCorePerturbation.wl *)

(* BEGIN SOURCE: src/Kernel/NumericalInverseChecks.wl
   Source SHA256 (UTF-8/LF): a3f1fd51ff3232b01025ed59eff3628cf1e693533f0a8627f439f32768f656d5 *)
(* Numerical evidence for inverse objects and their power observables.
   Exact target substitution precedes numerical evaluation so large offsets
   do not erase the small target distance. This is not certification. *)

(* Shared by ordinary and coordinate-specific numerical routes. The source
   predicate is checked at the recovered source root, not at an observable
   power or at the expansion seed. This is numerical evidence only. *)
numericalSourceDomainCheck[a_, root_, target_, wp_] := Module[{x, y, condition, evaluated},
  x = If[MatchQ[Lookup[a, "Variables", {}], {_Symbol, _Symbol}],
    First[a["Variables"]], inverseEvidenceSourceVariable[a]];
  y = Lookup[a, "Variable", Missing["NotSpecified"]];
  condition = inverseEvidenceSourceDomain[a, x];
  evaluated = condition /. x -> root;
  If[MatchQ[y, _Symbol] && y =!= x, evaluated = evaluated /. y -> target];
  If[! TrueQ[Quiet[Check[N[evaluated, wp + 10], False]]],
    fail["OutsideBranch", "The recovered numerical source root does not satisfy the retained source-domain condition.",
      <|"UnprovedCondition" -> condition, "ReferenceRoot" -> root, "Target" -> target|>]];
  True];

numericalInverseEvidence[a_, target_, wp_] := Module[
 {x, y, power, endpoint, side, domain, approximate, seed, equation, root,
  sourceDistance, observed, error, scale, remainder},
 If[! IntegerQ[wp] || wp < 10,
  fail["InvalidOption", "WorkingPrecision must be an integer of at least 10 digits."]];
 If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp),
  fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
 If[! MemberQ[{"Inverse", "CoreInverse", "ExponentialCoreInverse", "FlatInverse", "FourierInverse", "LogarithmicInverse"}, Lookup[a, "Kind", ""]],
  fail["Unsupported", "Numerical checks require an inverse expansion with a retained original equation."]];
 {x, y} = a["Variables"]; power = a["Power"]; endpoint = a["ExpansionPoint"];
 side = Which[endpoint === Infinity, 1, endpoint === -Infinity, -1,
   a["Direction"] === "FromBelow", -1, True, 1];
 domain = Lookup[a, "TargetDomain", If[MemberQ[{Infinity, -Infinity}, a["Limit"]], y, y - a["Limit"]]/a["LeadingCoefficient"] > 0];
 If[! TrueQ[N[domain /. y -> target, wp + 10]],
  fail["OutsideBranch", "The target is outside the recorded real asymptotic branch domain."]];
 approximate = N[a["Expression"] /. y -> target, wp + 10];
 If[! NumericQ[approximate] || ! TrueQ[Im[approximate] == 0],
  fail["OutsideBranch", "The expansion is not real at this target."]];
 seed = If[power === 1, approximate,
   If[MemberQ[{Infinity, -Infinity}, endpoint], 0, endpoint] + side Abs[approximate]^(1/power)];
 If[! NumericQ[seed] || ! TrueQ[Im[seed] == 0],
  fail["OutsideBranch", "The observable does not provide a real source seed."]];
 equation = a["Function"] - target;
 root = With[{xx = x, eq = equation, start = seed, precision = wp + 10, goal = wp},
   Quiet[Check[xx /. FindRoot[eq == 0, {xx, start}, WorkingPrecision -> precision,
     AccuracyGoal -> Infinity, PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
 If[root === $Failed || ! NumericQ[root], fail["RootNotFound", "The original equation did not converge from the expansion seed."]];
 sourceDistance = If[MemberQ[{Infinity, -Infinity}, endpoint], side root, side (root - endpoint)];
 If[! TrueQ[Im[root] == 0] || ! TrueQ[sourceDistance > 0],
  fail["OutsideBranch", "The numerical root is outside the selected original source branch."]];
 numericalSourceDomainCheck[a, root, target, wp];
 observed = Which[power === 1, root, MemberQ[{Infinity, -Infinity}, endpoint], root^power,
   True, (root - endpoint)^power];
 remainder = Lookup[a, "RemainderScaleExpression", a["Remainder"] /. rr_PowerLogRemainder :> remainderScale[rr]];
 scale = N[remainder /. y -> target, wp];
 error = N[Abs[observed - approximate], wp];
 <|"ReferenceRoot" -> N[root, wp], "ExactInverse" -> N[root, wp],
   "ReferenceObservable" -> N[observed, wp], "Approximation" -> N[approximate, wp],
   "ApproximationSourceRoot" -> N[seed, wp], "Error" -> error, "RemainderScale" -> scale,
   "SourceDomainChecked" -> inverseEvidenceSourceDomain[a, x], "SourceDomainVerified" -> True,
   "Ratio" -> If[TrueQ[scale == 0], Indeterminate, error/scale],
   "ForwardResidual" -> N[equation /. x -> seed, wp], "RootResidual" -> N[equation /. x -> root, wp],
   "Scope" -> "Stored explicit forward equation; a declared input remainder is not a numerical function.",
   "Evidence" -> "High-precision numerical comparison, not an interval certificate. ExactInverse is a legacy alias for ReferenceRoot."|>];
(* END SOURCE: src/Kernel/NumericalInverseChecks.wl *)

(* BEGIN SOURCE: src/Kernel/RefinementRequests.wl
   Source SHA256 (UTF-8/LF): d07fd2048c224b6a147f0b3e9a8b913527b337174c52363018b83fd11bd9b41c *)
(* Structured refinement requests keep coefficient goals distinct from
   certified numerical tolerances. Resource failures preserve the last object. *)

refinementRequest[s : GeneralizedSeries[a_Association], request_, limit_, maximum_] := Module[
 {unknown, extra, desired, count, current = s, next, step, cutoff, iterations = 0, certificate, options},
 If[! IntegerQ[limit] || limit < 1 || ! IntegerQ[maximum] || maximum < 0,
  fail["InvalidOption", "MaxTerms must be positive and MaxRefinements nonnegative integers."]];
 If[KeyExistsQ[request, "AdditionalBlocks"],
  unknown = Complement[Keys[request], {"AdditionalBlocks"}];
  If[unknown =!= {}, fail["InvalidRefinementRequest", "AdditionalBlocks cannot be mixed with another refinement goal."]];
  extra = request["AdditionalBlocks"];
  If[! IntegerQ[extra] || extra < 0, fail["InvalidRefinementRequest", "AdditionalBlocks must be a nonnegative integer."]];
  If[Lookup[a, "Kind", ""] =!= "Inverse" || Lookup[a, "Scale", "PowerLog"] =!= "PowerLog" ||
    Lookup[a, "Truncation", ""] =!= "Exponent",
   fail["UnsupportedRefinementRequest", "Additional complete blocks currently require an ordinary exponent-truncated inverse."]];
  count = Length[a["Blocks"]]; desired = count + extra;
  step = If[a["Model"]["Gaps"] === {}, 1, Min[a["Model"]["Gaps"]]]/Abs[a["LeadingPower"]];
  While[Length[current["Blocks"]] < desired && current["Remainder"] =!= 0,
   If[iterations >= maximum,
    fail["RefinementGoalNotReached", "The additional-block goal exceeded MaxRefinements.",
     <|"BestExpansion" -> current, "RequestedBlocks" -> desired, "ReturnedBlocks" -> Length[current["Blocks"]]|>]];
   iterations++; cutoff = canon[current["Cutoff"] + step];
   next = AsymptoticAnalysis`SeriesRefine[current, cutoff, "MaxTerms" -> limit];
   If[FailureQ[next], Throw[Failure[next[[1]], Join[next[[2]], <|"BestExpansion" -> current,
     "RequestedBlocks" -> desired, "ReturnedBlocks" -> Length[current["Blocks"]]|>]], $tag]];
   current = next];
  Return[GeneralizedSeries[Join[current[[1]], <|"RefinementRequest" -> <|
    "AdditionalBlocks" -> extra, "InitialBlocks" -> count, "RequestedBlocks" -> desired,
    "ReturnedBlocks" -> Length[current["Blocks"]], "GoalReached" -> (Length[current["Blocks"]] >= desired),
    "ExactTermination" -> (current["Remainder"] === 0), "RefinementCalls" -> iterations|>|>]], Module]];
 If[! KeyExistsQ[request, "Target"] || ! AnyTrue[{"TargetError", "RelativeError"}, KeyExistsQ[request, #] &],
  fail["InvalidRefinementRequest", "Use AdditionalBlocks, or Target with TargetError or RelativeError and the certificate options."]];
 unknown = Complement[Keys[request], Join[{"Target"}, First /@ Options[AsymptoticAnalysis`InverseCertificate]]];
 If[unknown =!= {}, fail["InvalidRefinementRequest", "The request contains unknown certificate options.", <|"UnknownKeys" -> unknown|>]];
 options = Normal[KeyDrop[request, "Target"]];
 If[! KeyExistsQ[request, "MaxRefinements"], AppendTo[options, "MaxRefinements" -> maximum]];
 certificate = AsymptoticAnalysis`InverseCertificate[s, request["Target"], Sequence @@ options];
 If[FailureQ[certificate], Return[certificate, Module]];
 Join[certificate, <|"ResultType" -> "NumericalCertificate", "SourceExpansion" -> s,
   "RefinementRequest" -> request,
   "RefinementMeaning" -> "Certified accuracy of the returned rational center. This does not change the symbolic expansion remainder."|>]];

AsymptoticAnalysis`SeriesRefine[s : GeneralizedSeries[_Association], request_Association, opts : OptionsPattern[]] :=
 catch[refinementRequest[s, request, OptionValue["MaxTerms"], OptionValue["MaxRefinements"]]];
(* END SOURCE: src/Kernel/RefinementRequests.wl *)

(* BEGIN SOURCE: src/Kernel/ReciprocalLogOperations.wl
   Source SHA256 (UTF-8/LF): 68a6c6a1aee21c0ababaadd221de24e16e87cb15be17a91ffb0b527cfa8a1af3 *)
(* Analytic calculus for C y^alpha A(epsilon/Log[y]), epsilon = +/-1.
   Hooks return $Failed outside their proved reciprocal-log scope. *)

AsymptoticAnalysis`ReciprocalLogCompose::usage =
"ReciprocalLogCompose[outer,inner] composes supported positive-target reciprocal-log inverse carriers, transporting both analytic logarithmic remainders. The inner carrier must approach the outer target endpoint with a positive constant unit.";
AsymptoticAnalysis`ReciprocalLogDifferentiate::usage =
"ReciprocalLogDifferentiate[s,n] differentiates a supported reciprocal-log carrier n times. Its exact rational-log implicit model proves all fixed derivative orders; omitted higher-power sectors and declared unknown errors are excluded.";
Options[AsymptoticAnalysis`ReciprocalLogCompose] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};
Options[AsymptoticAnalysis`ReciprocalLogDifferentiate] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};

reciprocalLogData[s : GeneralizedSeries[a_Association], limit_] := Module[
  {stored, y, p, power, endpoint, rint, alpha, coefficient, epsilon, t, scale,
   beta, polynomial, rows, ass, side, expected, exactRechart = False, originalCutoff},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  stored = Lookup[a, "ReciprocalLogRepresentation", None];
  If[AssociationQ[stored], Return[stored, Module]];
  If[Lookup[a, "Kind", ""] =!= "LogarithmicInverse" ||
     Lookup[a, "Scale", ""] =!= "ReciprocalLogUnit" ||
     ! TrueQ[Lookup[a, "ExactModel", False]] ||
     TrueQ[Lookup[a, "LeadingCoreOnly", True]], Return[$Failed, Module]];
  endpoint = a["ExpansionPoint"];
  If[! MemberQ[{0, Infinity, -Infinity}, endpoint] || ! MemberQ[{0, Infinity}, a["Limit"]] ||
     a["Offset"] =!= 0, Return[$Failed, Module]];
  y = a["Variable"]; ass = a["Assumptions"]; p = a["LeadingPower"]; power = a["Power"];
  If[! provablyPositive[a["LeadingCoefficient"], ass], Return[$Failed, Module]];
  expected = (y/a["LeadingCoefficient"])^(1/p);
  If[! TrueQ[FullSimplify[a["LeadingLocalApproximation"] == expected, ass && y > 0]], Return[$Failed, Module]];
  rint = If[MemberQ[{Infinity, -Infinity}, endpoint], -power, power];
  alpha = canon[rint/p]; epsilon = If[less[0, p], -1, 1];
  side = Which[endpoint === Infinity, 1, endpoint === -Infinity, -1,
    a["Direction"] === "FromBelow", -1, True, 1];
  coefficient = Simplify[side^power a["LeadingCoefficient"]^(-alpha), ass];
  If[! provablyPositive[coefficient, ass], Return[$Failed, Module]];
  t = Unique["reciprocalLog$"]; beta = a["RemainderPower"];
  If[beta === Infinity,
    If[a["Remainder"] =!= 0 ||
       ! TrueQ[Lookup[Lookup[a, "ExactTerminationCertificate", <||>], "Verified", False]],
      Return[$Failed, Module]];
    originalCutoff = a["Cutoff"];
    If[! exactRealQ[originalCutoff] || ! less[0, originalCutoff],
      fail["InvalidCutoff", "Recharting an exact reciprocal-log Taylor unit requires a positive finite cutoff."]];
    (* Even a finite exact polynomial in the old reciprocal coordinate can
       have an infinite Taylor series after an affine logarithmic shift.
       Keep a conservative analytic tail, including for a polynomial rechart. *)
    beta = Ceiling[originalCutoff]; exactRechart = True];
  If[! IntegerQ[beta] || beta < 1 || beta + 1 > limit,
    fail["ResourceLimit", "The analytic reciprocal-log conversion exceeds MaxTerms or lacks a positive integer Taylor remainder."]];
  scale = Abs[p] t/(1 - epsilon Log[a["LeadingCoefficient"]] t);
  polynomial = logarithmicTaylor[Total[(scale^#[[1]] #[[2]]) & /@ a["Blocks"]],
    t, beta - 1, ass, limit];
  rows = jetMerge[Table[{k, Coefficient[polynomial, t, k]}, {k, 0, beta - 1}], t, ass];
  <|"Variable" -> y, "EndpointSign" -> epsilon, "CarrierConstant" -> coefficient,
    "CarrierPower" -> alpha, "Jet" -> {rows, beta, 0}, "LogVariable" -> t,
    "Assumptions" -> ass, "Domain" -> (a["TargetDomain"] && y > 0 && epsilon Log[y] > 0), "Cutoff" -> a["Cutoff"],
    "AnalyticRemainder" -> True, "InputDomains" -> {a["TargetDomain"]},
    "RechartPrecisionSource" -> If[exactRechart,
      "ConservativeTaylorTruncationOfExactUnit", "TransportedAnalyticTaylorRemainder"],
    "Origin" -> "Exact rational reciprocal-log implicit inverse"|>];
reciprocalLogData[_, _] := $Failed;

reciprocalLogMake[d0_, recipe_, cut_, limit_] := Module[
  {d = d0, y, epsilon, alpha, c, ell, t, j, h, representation, result},
  {y, epsilon, alpha, c, ell, j} = Lookup[d,
    {"Variable", "EndpointSign", "CarrierPower", "CarrierConstant", "LogVariable", "Jet"}];
  h = If[cut === Automatic, Lookup[d, "Cutoff", j[[2]]], cut];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "A reciprocal-log cutoff must be a positive exact real number."]];
  j = seriesTrim[j, h, ell, d["Assumptions"]];
  If[LeafCount[j] > limit, fail["ResourceLimit", "The reciprocal-log result exceeded MaxTerms expression leaves."]];
  t = epsilon/Log[y];
  d = Join[d, <|"Jet" -> j, "Cutoff" -> h|>];
  representation = <|"Variable" -> y, "ScaleVariable" -> t, "LogVariable" -> ell,
    "Prefactor" -> c y^alpha, "Offset" -> 0, "Jet" -> j,
    "Assumptions" -> d["Assumptions"], "Domain" -> d["Domain"], "Cutoff" -> h,
    "RemainderDerivativeOrder" -> Infinity|>;
  result = seriesMake[representation, recipe, h];
  GeneralizedSeries[Join[result[[1]], <|"Scale" -> "ReciprocalLogCalculus",
    "ReciprocalLogRepresentation" -> d,
    "AnalyticRemainderContract" -> <|"Type" -> "HolomorphicReciprocalLogarithmicUnit",
      "AllFixedDerivativeOrders" -> True, "NumericCertificate" -> False,
      "Statement" -> "The exact carrier is retained and the coefficient function is holomorphic near t=0. An omitted O(t^beta) Taylor tail has derivatives O(t^(beta-j)) for each fixed j. Composition and differentiation preserve this contract; constants and a source threshold are existential."|>,
    "TermConvention" -> "CarrierConstant y^CarrierPower times a Taylor jet in t=EndpointSign/Log[y]>0. Cutoff is exclusive in the coefficient jet. A requested cutoff does not override operand precision.",
    "InputDomains" -> d["InputDomains"]|>]]];

reciprocalLogCompose[outer_, inner_, cut_, limit_] := Module[
  {a, b, ass, ell, y, epsilon, outerSign, alpha, bpower, ca, cb, ja, jb,
   constant, logarithm, denominator, coordinate, composed, unitPower, result,
   h, tjet, d, outerPolynomial, formal},
  a = reciprocalLogData[outer, limit]; b = reciprocalLogData[inner, limit];
  If[a === $Failed || b === $Failed, Return[$Failed, Module]];
  ass = a["Assumptions"] && b["Assumptions"]; ell = b["LogVariable"];
  y = b["Variable"]; epsilon = b["EndpointSign"]; outerSign = a["EndpointSign"];
  alpha = a["CarrierPower"]; bpower = b["CarrierPower"];
  If[bpower === 0 || ! less[0, outerSign bpower epsilon],
    fail["IncompatibleLimits", "The positive inner carrier must approach the outer reciprocal-log target endpoint."]];
  ja = a["Jet"] /. a["LogVariable"] -> ell; jb = b["Jet"];
  If[jb[[1]] === {} || jb[[1, 1, 1]] =!= 0 ||
     ! provablyPositive[jb[[1, 1, 2]], ass],
    fail["UnsupportedReciprocalLogComposition", "The inner coefficient jet must have a proved positive nonzero constant term; additional powers of log-log require a larger composition scale."]];
  constant = jb[[1, 1, 2]]; ca = a["CarrierConstant"]; cb = b["CarrierConstant"] constant;
  jb = pMul[pConst[1/constant, ell, ass], jb, ell, ass, limit];
  h = If[cut === Automatic, minOf[a["Cutoff"], b["Cutoff"]], cut];
  If[! exactRealQ[h] || ! less[0, h], fail["InvalidCutoff", "A reciprocal-log composition cutoff must be positive and exact."]];
  tjet = {{{1, 1}}, Infinity, 0};
  logarithm = fwdLog[jb, Unique["t$"], ell, ass, h, limit];
  denominator = pAdd[pConst[bpower epsilon, ell, ass],
    pMul[tjet, pAdd[pConst[Log[cb], ell, ass], logarithm, ell, ass], ell, ass, limit], ell, ass];
  coordinate = pMul[{{{1, outerSign}}, Infinity, 0},
    fwdPower[denominator, -1, Unique["t$"], ell, ass, h + 1, limit], ell, ass, limit];
  formal = Unique["outerLog$"];
  outerPolynomial = Total[(formal^#[[1]] #[[2]]) & /@ ja[[1]]];
  d = <|"Variable" -> y, "ScaleVariable" -> epsilon/Log[y], "LogVariable" -> ell,
    "Assumptions" -> ass, "Domain" -> (b["Domain"] && y > 0 && epsilon Log[y] > 0)|>;
  composed = seriesJetApply[outerPolynomial, formal, coordinate, d, h, limit];
  If[ja[[2]] =!= Infinity, composed = pAdd[composed, {{}, ja[[2]], ja[[3]]}, ell, ass]];
  unitPower = fwdPower[jb, alpha, Unique["t$"], ell, ass, h, limit];
  result = pMul[unitPower, composed, ell, ass, limit];
  reciprocalLogMake[Join[b, <|"Assumptions" -> ass, "Domain" -> d["Domain"],
    "CarrierConstant" -> Simplify[ca cb^alpha, ass], "CarrierPower" -> canon[alpha bpower],
    "Jet" -> result, "Cutoff" -> h,
    "InputDomains" -> Join[a["InputDomains"], b["InputDomains"]],
    "Origin" -> "Analytic reciprocal-log composition with both operand remainders"|>],
    {"Compose", {outer, inner}}, h, limit]];

reciprocalLogDifferentiate[s_, n_, declared_, cut_, limit_] := Module[
  {d, j, ell, ass, alpha, epsilon, derivative, ordinary, k, h},
  d = reciprocalLogData[s, limit]; If[d === $Failed, Return[$Failed, Module]];
  If[! IntegerQ[n] || n < 0, fail["InvalidDerivativeOrder", "The derivative order must be a nonnegative integer."]];
  If[n > limit, fail["ResourceLimit", "The derivative order exceeds MaxTerms."]];
  If[declared =!= Automatic && declared =!= Infinity && (! IntegerQ[declared] || declared < 0),
    fail["InvalidDerivativeContract", "RemainderDerivativeOrder must be nonnegative or Infinity."]];
  If[n === 0, Return[s, Module]];
  j = d["Jet"]; ell = d["LogVariable"]; ass = d["Assumptions"];
  alpha = d["CarrierPower"]; epsilon = d["EndpointSign"];
  Do[
    derivative = {jetMerge[({#[[1]] - 1, #[[1]] #[[2]]} & /@ j[[1]]), ell, ass],
      If[j[[2]] === Infinity, Infinity, j[[2]] - 1], j[[3]]};
    ordinary = If[zeroQ[alpha - k, ass], pConst[0, ell, ass],
      pMul[pConst[alpha - k, ell, ass], j, ell, ass, limit]];
    j = pAdd[ordinary, pMul[{{{2, -epsilon}}, Infinity, 0}, derivative, ell, ass, limit], ell, ass];
    If[LeafCount[j] > limit, fail["ResourceLimit", "A reciprocal-log derivative exceeded MaxTerms expression leaves."]],
    {k, 0, n - 1}];
  h = If[cut === Automatic, d["Cutoff"], cut];
  reciprocalLogMake[Join[d, <|"CarrierPower" -> canon[alpha - n], "Jet" -> j,
    "Origin" -> "Exact carrier differentiation with a holomorphic Taylor remainder"|>],
    {"Differentiate", {s}, n, Automatic}, h, limit]];

AsymptoticAnalysis`ReciprocalLogCompose[outer_GeneralizedSeries, inner_GeneralizedSeries, opts : OptionsPattern[]] := catch[
  Module[{result, captured, cut = OptionValue["Cutoff"], limit = OptionValue["MaxTerms"]},
    {captured, result} = seriesCompositionAdmission[outer, inner, cut, limit, False];
    If[result =!= $Failed, Return[result, Module]];
    If[captured, fail["ParameterCapture", "A moving reciprocal-log carrier parameter requires a separately proved joint expansion."]];
    result = reciprocalLogCompose[outer, inner, cut, limit];
    If[result === $Failed, fail["UnsupportedReciprocalLogComposition", "Use exact reciprocal-log-unit inverse carriers with zero offsets and positive monomial prefactors."], result]]];
AsymptoticAnalysis`ReciprocalLogDifferentiate[s_GeneralizedSeries, n_Integer : 1, opts : OptionsPattern[]] := catch[
  Module[{result = reciprocalLogDifferentiate[s, n, Automatic, OptionValue["Cutoff"], OptionValue["MaxTerms"]]},
    If[result === $Failed, fail["UnsupportedReciprocalLogDerivative", "A retained exact reciprocal-log implicit model or its supported calculus result is required; unknown and omitted higher-power input sectors are excluded."], result]]];
(* END SOURCE: src/Kernel/ReciprocalLogOperations.wl *)

(* BEGIN SOURCE: src/Kernel/InverseFunctionSyntax.wl
   Source SHA256 (UTF-8/LF): cee9ea02101c02f5e72476de2589beafb9d150383719258453b7ca124c48973e *)
(* Loaded in AsymptoticAnalysis`Private`.

   Parse an applied ACTIVE InverseFunction after ordinary Wolfram evaluation.
   The expression dispatcher must visit heads as well as arguments: an inverse
   application can itself occur in the head of a larger expression.  Already
   simplified native inverses belong to that dispatcher's ordinary route.

   InverseFunction[f,k,n][a1,...,an] replaces argument k of f by its inverse:
   f[a1,...,x,...,an] == ak.  See the selected-argument example at
   https://reference.wolfram.com/language/ref/InverseFunction.html .
   Applying Function, rather than replacing its slots or formal parameters,
   retains its documented lexical-renaming and nested-scoping behavior:
   https://reference.wolfram.com/language/ref/Function.html .
*)

inverseFunctionApplicationQ[e_] := ! AtomQ[e] && Head[Head[e]] === InverseFunction;
inverseFunctionApplicationQ[___] := False;

inverseFunctionSyntaxBudget[e_, limit_, stage_] :=
  If[LeafCount[e] > limit,
    fail["ResourceLimit", "InverseFunction syntax exceeded the MaxTerms expression-size budget.",
      <|"Stage" -> stage, "LeafCount" -> LeafCount[e], "MaxTerms" -> limit|>]];

(* Hold the formal-parameter declaration while inspecting it: an OwnValue on
   a global symbol used as a formal parameter must not change its arity. *)
inverseFunctionCallableArity[callable_, n_Integer] := Module[
  {size, declaration, arity, formals},
  If[Head[callable] === Symbol, Return[Null, Module]];
  If[Head[callable] =!= Function,
    fail["UnsupportedInverseFunction", "The forward callable must be a symbol or a pure Function.",
      <|"ForwardFunction" -> callable|>]];
  size = Length[callable];
  If[! MemberQ[{1, 2, 3}, size],
    fail["MalformedInverseFunction", "The pure Function has an invalid number of parts."]];
  If[size === 1, Return[Null, Module]];
  declaration = Extract[callable, {1}, HoldComplete];
  If[declaration === HoldComplete[Null], Return[Null, Module]];
  arity = Which[
    MatchQ[declaration, HoldComplete[_Symbol]], 1,
    MatchQ[declaration, HoldComplete[{___Symbol}]],
      declaration /. HoldComplete[{parameters___}] :> Length[HoldComplete[parameters]],
    True, fail["MalformedInverseFunction", "Named Function parameters must be a symbol or a list of distinct symbols."]];
  If[MatchQ[declaration, HoldComplete[{___Symbol}]],
    formals = Table[Extract[declaration, {1, j}, HoldComplete], {j, arity}];
    If[Length[DeleteDuplicates[formals]] =!= arity,
      fail["MalformedInverseFunction", "Named Function parameters must be distinct."]]];
  If[arity =!= n,
    fail["InverseFunctionArity", "The declared inverse arity does not match the named Function parameters.",
      <|"ExpectedArguments" -> arity, "DeclaredArguments" -> n|>]];
  Null];

(* ConditionalExpression normally propagates to the outside of mathematical
   expressions.  This walk also handles nested conditions and conditions in
   non-holding symbolic heads.  Do not hoist a condition out of an unevaluated
   binder or a control branch; doing that would change its logical meaning. *)
inverseFunctionConditions[e_, limit_] := Module[
  {conditions = {}, visited = 0, walk, body, condition, forbidden},
  forbidden = {Function, Module, Block, With, DynamicModule, Hold, HoldForm,
    HoldComplete, Unevaluated, Defer, Inactive, InverseFunction, Piecewise,
    If, Which, Switch, Condition, RuleDelayed, SetDelayed, ForAll, Exists};
  walk[expr_] := Module[{head, result, c},
    visited++;
    If[visited > limit,
      fail["ResourceLimit", "ConditionalExpression extraction exceeded MaxTerms.",
        <|"MaxTerms" -> limit|>]];
    If[AtomQ[expr], Return[expr, Module]];
    head = Head[expr];
    If[head === ConditionalExpression,
      If[Length[expr] =!= 2,
        fail["MalformedInverseFunction", "A forward ConditionalExpression must have two arguments."]];
      result = walk[expr[[1]]]; c = walk[expr[[2]]];
      AppendTo[conditions, c]; Return[result, Module]];
    If[FreeQ[expr, _ConditionalExpression], Return[expr, Module]];
    If[MemberQ[forbidden, head] ||
        (Head[head] === Symbol &&
          Intersection[Attributes[head], {HoldAll, HoldAllComplete, HoldFirst, HoldRest}] =!= {}),
      fail["ScopedInverseCondition", "A condition remains inside an unevaluated binding, holding, or control construct; its domain cannot be hoisted safely.",
        <|"Expression" -> expr|>]];
    If[! FreeQ[head, _ConditionalExpression],
      fail["ScopedInverseCondition", "ConditionalExpression in an unevaluated function head is unsupported.",
        <|"Expression" -> expr|>]];
    Map[walk, expr]];
  body = walk[e]; condition = And @@ conditions;
  If[body === Undefined || condition === False,
    fail["EmptyInverseDomain", "The forward function has an explicitly false domain condition."]];
  <|"Body" -> body, "Condition" -> condition|>];

inverseFunctionApplicationData[e_, parameterAss_, limit_] := Module[
  {operator, parts, callable, k, n, arguments, source, sourceArguments,
    parameterPositions, body, extracted, original = e},
  If[! inverseFunctionApplicationQ[e], Return[$Failed, Module]];
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  inverseFunctionSyntaxBudget[e, limit, "AppliedInverse"];
  operator = Head[e]; parts = List @@ operator;
  Switch[Length[parts],
    1, callable = parts[[1]]; k = 1; n = 1,
    3, callable = parts[[1]]; k = parts[[2]]; n = parts[[3]],
    _, fail["MalformedInverseFunction", "Use InverseFunction[f] or InverseFunction[f,k,n].",
      <|"OriginalOperator" -> operator|>]];
  If[! IntegerQ[n] || n < 1 || ! IntegerQ[k] || k < 1 || k > n,
    fail["InverseFunctionArity", "The selected argument and total arity must be integers satisfying 1 <= k <= n.",
      <|"ArgumentIndex" -> k, "ArgumentCount" -> n|>]];
  arguments = List @@ e;
  If[Length[arguments] =!= n,
    fail["InverseFunctionArity", "The inverse application must supply its declared number of arguments.",
      <|"ExpectedArguments" -> n, "SuppliedArguments" -> Length[arguments]|>]];
  inverseFunctionCallableArity[callable, n];
  source = Unique["inverseSource$"];
  sourceArguments = ReplacePart[arguments, k -> source];
  (* Evaluate exactly one ordinary callable application.  This is neither
     textual substitution into Function nor string evaluation.  The finite
     guard protects this parser from recursive user-defined callables. *)
  body = TimeConstrained[Quiet[Check[Apply[callable, sourceArguments], $Failed]], 5,
    fail["ResourceLimit", "Applying the forward callable exceeded the five-second syntax-evaluation limit.",
      <|"Stage" -> "ForwardFunctionApplication", "TimeLimit" -> 5|>]];
  If[FailureQ[body], Throw[body, $tag]];
  If[body === $Failed || body === $Aborted,
    fail["InverseFunctionApplication", "The forward callable could not be applied to its scalar source arguments.",
      <|"ForwardFunction" -> callable, "SourceArguments" -> sourceArguments|>]];
  inverseFunctionSyntaxBudget[body, limit, "ForwardFunctionApplication"];
  If[MemberQ[{List, Association, Function}, Head[body]] ||
      ! FreeQ[body /. _Function -> inverseFunctionBoundCallable, _Slot | _SlotSequence],
    fail["UnsupportedInverseFunction", "The forward callable must produce a scalar expression with all formal slots resolved.",
      <|"ForwardExpression" -> body|>]];
  extracted = inverseFunctionConditions[body, limit];
  If[MemberQ[{List, Association, Function}, Head[extracted["Body"]]],
    fail["UnsupportedInverseFunction", "The conditional forward callable must produce a scalar expression.",
      <|"ForwardExpression" -> extracted["Body"]|>]];
  parameterPositions = Delete[Range[n], k];
  <|"Body" -> extracted["Body"], "SourceVariable" -> source,
    "Condition" -> extracted["Condition"], "TargetExpression" -> arguments[[k]],
    "Parameters" -> arguments[[parameterPositions]],
    "ParameterPositions" -> parameterPositions, "ParameterAssumptions" -> parameterAss,
    "SourceArguments" -> sourceArguments, "ArgumentIndex" -> k, "ArgumentCount" -> n,
    "OriginalExpression" -> original, "OriginalOperator" -> operator|>];

inverseFunctionApplicationData[___] :=
  fail["InvalidArguments", "InverseFunction syntax parsing requires an expression, parameter assumptions, and MaxTerms."];
(* END SOURCE: src/Kernel/InverseFunctionSyntax.wl *)

(* BEGIN SOURCE: src/Kernel/InverseFunctionBranches.wl
   Source SHA256 (UTF-8/LF): 727c43fd3e873a3853caa82ddbbd83be18d1923353e8be62f154e904e804eafe *)
(* Real local branches for unevaluated InverseFunction nodes. This module
   never equates a bounded candidate search with a completeness proof. *)

SetAttributes[inverseBranchTry, HoldAll];
inverseBranchTry[expression_] := Quiet[TimeConstrained[Check[expression, $Failed], 2, $Failed]];
inverseBranchResolvedQ[e_] := e =!= $Failed &&
  FreeQ[e, _Reduce | _Resolve | _Solve | _FunctionDomain | _Limit | _ConditionalExpression | _C];

inverseBranchFiniteRoots[condition_, x_, ass_] := Module[{reduced, points, equality},
  reduced = inverseBranchTry[Reduce[ass && condition, x, Reals]];
  If[! inverseBranchResolvedQ[reduced], Return[<|"Points" -> {}, "Complete" -> False|>, Module]];
  points = Join[Cases[reduced, Equal[x, c_] /; FreeQ[c, x] && exactRealQ[c] :> c, {0, Infinity}],
    Cases[reduced, Equal[c_, x] /; FreeQ[c, x] && exactRealQ[c] :> c, {0, Infinity}]];
  points = DeleteDuplicates[canon /@ points, equal];
  equality = Or @@ ((x == #) & /@ points);
  <|"Points" -> points,
    "Complete" -> TrueQ[inverseBranchTry[FullSimplify[Equivalent[reduced, equality], ass]]],
    "ReducedCondition" -> reduced|>];

inverseBranchBoundaryData[domain_, x_, ass_] := Module[
  {atoms, points = {}, complete = True, sides, expressions, roots, atom, expression},
  atoms = Cases[domain, a_ /; ! FreeQ[a, x] &&
    MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal, Inequality, Element}, Head[a]], {0, Infinity}];
  Do[
    If[Head[atom] === Element,
      If[atom =!= Element[x, Reals], complete = False]; Continue[]];
    sides = If[Head[atom] === Inequality, (List @@ atom)[[1 ;; -1 ;; 2]], List @@ atom];
    expressions = (Subtract @@ #) & /@ Partition[sides, 2, 1];
    Do[
      expression = Together[expression];
      If[! PolynomialQ[Numerator[expression], x] || ! PolynomialQ[Denominator[expression], x],
        complete = False; Continue[]];
      roots = inverseBranchFiniteRoots[Numerator[expression] == 0 || Denominator[expression] == 0, x, ass];
      points = Join[points, roots["Points"]]; complete = complete && roots["Complete"],
      {expression, expressions}], {atom, atoms}];
  If[! FreeQ[domain, _C | _Exists | _ForAll] ||
    (! FreeQ[domain, x] && atoms === {}), complete = False];
  <|"Points" -> DeleteDuplicates[points, equal], "Complete" -> TrueQ[complete]|>];

inverseBranchRealQ[value_, ass_] := exactQ[value] &&
  TrueQ[inverseBranchTry[FullSimplify[Element[value, Reals], ass]]];

inverseBranchContinuousQ[body_, x_] := Module[{heads},
  heads = DeleteDuplicates[Head /@ Cases[body, e_ /; ! AtomQ[e] && ! FreeQ[e, x], {0, Infinity}]];
  FreeQ[body, ArcTan[_, _]] &&
  And @@ (MemberQ[{Plus, Times, Power, Log, Exp, Abs, Sin, Cos, Tan, Cot, Sec, Csc,
    Sinh, Cosh, Tanh, Coth, Sech, Csch, ArcSin, ArcCos, ArcTan,
    ArcSinh, ArcCosh, ArcTanh, Erf, Erfc, Gamma, LogGamma, BarnesG, LogBarnesG, ProductLog}, #] & /@ heads)];

inverseBranchGlobalMonotonicity[body_, x_, domain_, ass_] := Module[
  {left = Unique["left$"], right = Unique["right$"], middle = Unique["middle$"],
   convex, derivative, positive, negative, ratio},
  If[! inverseBranchContinuousQ[body, x], Return[None, Module]];
  convex = inverseBranchTry[Reduce[ass && (domain /. x -> left) && (domain /. x -> right) &&
    left < middle < right && ! (domain /. x -> middle), {left, middle, right}, Reals]];
  If[convex =!= False, Return[None, Module]];
  derivative = D[body, x];
  positive = inverseBranchTry[FullSimplify[derivative > 0, ass && domain && Element[x, Reals]]];
  If[! TrueQ[positive], positive = inverseBranchTry[Reduce[ass && domain && derivative <= 0, x, Reals]] === False];
  If[TrueQ[positive], Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> 1,
    "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  negative = inverseBranchTry[FullSimplify[derivative < 0, ass && domain && Element[x, Reals]]];
  If[! TrueQ[negative], negative = inverseBranchTry[Reduce[ass && domain && derivative >= 0, x, Reals]] === False];
  If[TrueQ[negative], Return[<|"Type" -> "StrictDerivativeOnRealInterval", "Sign" -> -1,
    "Domain" -> domain, "Derivative" -> derivative|>, Module]];
  (* Article Proposition 4.2: x(3+2 Log[x]) has minimum -2 Exp[-5/2]
     on x>0. A nonzero real scalar preserves strict monotonicity. *)
  If[TrueQ[inverseBranchTry[FullSimplify[x > 0, ass && domain && Element[x, Reals]]]],
    ratio = inverseBranchTry[FullSimplify[derivative/(1 + x (3 + 2 Log[x])), ass && x > 0]];
    If[ratio =!= $Failed && FreeQ[ratio, x] &&
       (provablyPositive[ratio, ass] || provablyNegative[ratio, ass]),
      Return[<|"Type" -> "OriginalLogarithmicExampleSlopeLemma",
        "Sign" -> If[provablyPositive[ratio, ass], 1, -1], "Domain" -> domain,
        "DerivativeLowerAbsoluteBound" -> Abs[ratio] (1 - 2 Exp[-5/2]),
        "Proof" -> "The derivative of x(3+2 Log[x]) is 5+2 Log[x], so its global minimum on x>0 is -2 Exp[-5/2]."|>, Module]]];
  None];

inverseBranchRadius[point_, boundaries_] := Module[{distances},
  If[MemberQ[{Infinity, -Infinity}, point],
    Return[1/(2 + 2 If[boundaries === {}, 0, Max[Abs /@ boundaries]]), Module]];
  distances = Select[Abs[point - #] & /@ boundaries, less[0, #] &];
  If[distances === {}, 1/2, Min[1/2, Min[distances]/2]]];

(* True/False prove truth/falsity throughout this deleted interval; None is
   inconclusive. In particular, a failed proof is never a rejected branch. *)
inverseBranchEventualQ[predicate_, u_, ass_, radius_] := Module[{simple, bad, good},
  simple = inverseBranchTry[FullSimplify[predicate, ass && 0 < u < radius]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  bad = inverseBranchTry[Reduce[ass && 0 < u < radius && ! predicate, u, Reals]];
  If[bad === False, Return[True, Module]];
  good = inverseBranchTry[Reduce[ass && 0 < u < radius && predicate, u, Reals]];
  If[good === False, False, None]];

inverseBranchSign[expression_, u_, ass_, radius_, limit_] := Module[{ell = Unique["branchLog$"], jet, row, degree, leading},
  jet = inverseBranchTry[catch[forwardJet[expression, u, ell, ass, 1, limit]]];
  If[ListQ[jet] && Length[jet] === 3 && jet[[1]] =!= {},
    row = First[jet[[1]]]; degree = polyDegree[row[[2]], ell];
    leading = (-1)^degree Coefficient[row[[2]], ell, degree];
    If[provablyPositive[leading, ass], Return[<|"Sign" -> 1, "Type" -> "LeadingPowerLogBlock", "Block" -> row|>, Module]];
    If[provablyNegative[leading, ass], Return[<|"Sign" -> -1, "Type" -> "LeadingPowerLogBlock", "Block" -> row|>, Module]]];
  If[TrueQ[inverseBranchEventualQ[expression > 0, u, ass, radius]],
    Return[<|"Sign" -> 1, "Type" -> "ExactSignOnDeletedNeighborhood", "Radius" -> radius|>, Module]];
  If[TrueQ[inverseBranchEventualQ[expression < 0, u, ass, radius]],
    Return[<|"Sign" -> -1, "Type" -> "ExactSignOnDeletedNeighborhood", "Radius" -> radius|>, Module]];
  None];

inverseBranchValidate[body_, x_, domain_, point_, direction_, target_, targetSide_, ass_, boundaries_, limit_] := Module[
  {coord, u, radius, localDomain, domainTruth, localBody, value, matches, sign, derivative, derivativeSign},
  coord = catch[localCoordinate[x, point, direction]];
  If[FailureQ[coord], Return[None, Module]];
  u = coord["u"]; radius = inverseBranchRadius[point, boundaries];
  localDomain = domain /. x -> coord["Substitution"];
  domainTruth = inverseBranchEventualQ[localDomain, u, ass, radius];
  If[domainTruth === False, Return[False, Module]];
  If[! TrueQ[domainTruth], Return[None, Module]];
  localBody = inverseBranchTry[FullSimplify[body /. x -> coord["Substitution"], ass && u > 0]];
  If[localBody === $Failed, Return[None, Module]];
  value = inverseBranchTry[Limit[localBody, u -> 0, Direction -> -1, Assumptions -> ass]];
  If[! inverseBranchResolvedQ[value] ||
     (! MemberQ[{Infinity, -Infinity}, value] && ! inverseBranchRealQ[value, ass]), Return[None, Module]];
  matches = inverseBranchTry[FullSimplify[value == target, ass]];
  If[matches === False, Return[False, Module]];
  If[! TrueQ[matches], Return[None, Module]];
  If[! MemberQ[{Infinity, -Infinity}, target],
    sign = inverseBranchSign[localBody - target, u, ass, radius, limit];
    If[! AssociationQ[sign], Return[None, Module]];
    If[sign["Sign"] =!= targetSide, Return[False, Module]],
    sign = <|"Type" -> "ProvedInfiniteLimit", "Sign" -> If[target === Infinity, 1, -1]|>];
  derivative = D[body, x] /. x -> coord["Substitution"];
  derivativeSign = inverseBranchSign[derivative, u, ass, radius, limit];
  If[! AssociationQ[derivativeSign],
    Return[If[TrueQ[inverseBranchEventualQ[derivative == 0, u, ass, radius]], False, None], Module]];
  <|"SourcePoint" -> point, "Direction" -> coord["Direction"], "SourceDomain" -> domain,
    "SourceCondition" -> domain, "TargetLimit" -> target, "TargetSide" -> targetSide,
    "LocalSourceVariable" -> u, "LocalSubstitution" -> (x -> coord["Substitution"]),
    "DeletedNeighborhood" -> (0 < u < radius), "ConditionalDomainVerified" -> True,
    "LimitVerified" -> True, "TargetSideProof" -> sign, "MonotonicityProof" -> derivativeSign,
    "BranchProofScope" -> "Unique inverse germ on the selected sufficiently small deleted real source neighborhood. The recorded condition radius is not a computed power-log asymptotic threshold."|>];

inverseFunctionSelectBranchInternal[data_, target_, targetSide_, ass_, limit_, selection_] := Module[
  {body, x, condition, realDomain, domain, domainReduced, boundary, roots,
   candidates, points, monotonicity, complete, choices = {}, unresolved = {}, choice,
   directions, point, mode, sourceDirection},
  If[! AssociationQ[data] || ! And @@ (KeyExistsQ[data, #] & /@ {"Body", "SourceVariable", "Condition"}),
    fail["InvalidInverseFunctionData", "The inverse node needs a Body, SourceVariable and Condition."]];
  {body, x, condition} = Lookup[data, {"Body", "SourceVariable", "Condition"}];
  If[Head[x] =!= Symbol || ! FreeQ[ass, x],
    fail["InvalidInverseFunctionData", "Use a source symbol and parameter-only assumptions."]];
  validateInput[body, limit];
  If[! MemberQ[{Infinity, -Infinity}, target] && (! inverseBranchRealQ[target, ass] || ! MemberQ[{-1, 1}, targetSide]),
    fail["UnprovedInverseTargetLimit", "The inverse argument needs an exact real endpoint and a proved one-sided approach, or a signed infinity."]];
  choice = barnesInverseBranch[data, target, targetSide, ass, limit, selection];
  If[AssociationQ[choice], Return[choice, Module]];
  If[! inverseBranchContinuousQ[body, x],
    fail["UnsupportedInverseFunctionBody", "Branch inference requires an explicit supported continuous elementary or special-function body."]];
  realDomain = inverseBranchTry[FunctionDomain[body, x, Reals]];
  If[! inverseBranchResolvedQ[realDomain],
    fail["UnprovedInverseRealDomain", "The real domain of the principal forward expression could not be established; no branch was guessed."]];
  domain = inverseBranchTry[FullSimplify[condition && realDomain, ass && Element[x, Reals]]];
  If[domain === $Failed, domain = condition && realDomain];
  domainReduced = inverseBranchTry[Reduce[ass && domain, x, Reals]];
  If[inverseBranchResolvedQ[domainReduced], domain = domainReduced];
  If[domain === False, fail["EmptyInverseFunctionDomain", "The conditional real source domain is empty under the assumptions."]];
  boundary = inverseBranchBoundaryData[domain, x, ass];
  If[selection =!= Automatic,
    If[! AssociationQ[selection] || ! KeyExistsQ[selection, "SourcePoint"] ||
       Complement[Keys[selection], {"SourcePoint", "Direction"}] =!= {},
      fail["InvalidInverseBranchSelection", "Use an association with SourcePoint and optional Direction."]];
    point = selection["SourcePoint"]; sourceDirection = Lookup[selection, "Direction", Automatic];
    If[! MemberQ[{Automatic, "FromAbove", "FromBelow", -1, 1}, sourceDirection],
      fail["InvalidInverseBranchSelection", "Direction must be Automatic, FromAbove, FromBelow, -1 or 1."]];
    sourceDirection = sourceDirection /. {-1 -> "FromAbove", 1 -> "FromBelow"};
    If[! MemberQ[{Infinity, -Infinity}, point] && ! exactRealQ[point],
      fail["InvalidInverseBranchSelection", "The selected source endpoint must be an exact real constant or a signed infinity."]];
    directions = If[sourceDirection === Automatic && ! MemberQ[{Infinity, -Infinity}, point],
      {"FromAbove", "FromBelow"}, {sourceDirection}];
    Do[choice = inverseBranchValidate[body, x, domain, point, direction, target, targetSide, ass, boundary["Points"], limit];
      If[AssociationQ[choice], AppendTo[choices, choice],
        If[choice =!= False, AppendTo[unresolved, {point, direction}]]], {direction, directions}];
    mode = "ExplicitEndpointAndValidatedLocalBranch"; complete = unresolved === {},
    roots = If[MemberQ[{Infinity, -Infinity}, target], <|"Points" -> {}, "Complete" -> True|>,
      inverseBranchFiniteRoots[domain && body == target, x, ass]];
    points = DeleteDuplicates[Join[{0}, roots["Points"], boundary["Points"]], equal];
    candidates = Join[Flatten[({{#, "FromAbove"}, {#, "FromBelow"}} &) /@ points, 1],
      {{Infinity, "FromBelow"}, {-Infinity, "FromAbove"}}];
    If[Length[candidates] > Min[limit, 64],
      fail["ResourceLimit", "The inverse branch candidate set exceeds its bounded search budget.",
        <|"CandidateCount" -> Length[candidates], "MaxCandidates" -> Min[limit, 64]|>]];
    Do[choice = inverseBranchValidate[body, x, domain, candidate[[1]], candidate[[2]], target, targetSide,
        ass, boundary["Points"], limit];
      If[AssociationQ[choice], AppendTo[choices, choice],
        If[choice =!= False, AppendTo[unresolved, candidate]]], {candidate, candidates}];
    complete = TrueQ[boundary["Complete"] && roots["Complete"]] && unresolved === {};
    mode = "CompleteRealFiberAndBoundaryEnumeration";
    If[Length[choices] == 1 && ! complete,
      monotonicity = inverseBranchGlobalMonotonicity[body, x, domain, ass];
      If[AssociationQ[monotonicity], complete = True; mode = "StrictMonotonicityOnConnectedRealDomain"]]];
  If[Length[choices] > 1,
    fail["AmbiguousInverseFunctionBranch", "Several real source germs have the requested target limit and side; restrict the function domain or select SourcePoint and Direction.",
      <|"Candidates" -> choices, "SourceDomain" -> domain, "TargetLimit" -> target|>]];
  If[! TrueQ[complete],
    fail["IncompleteInverseBranchInference", "A bounded candidate search did not prove completeness or unique monotonic selection; supply an explicit source branch.",
      <|"Candidates" -> choices, "UnresolvedCandidates" -> unresolved,
        "SourceDomain" -> domain, "BoundaryInference" -> boundary|>]];
  If[choices === {},
    fail["NoInverseFunctionBranch", "No selected real source neighborhood satisfies the target limit, approach side and conditional domain.",
      <|"SourceDomain" -> domain, "TargetLimit" -> target, "TargetSide" -> targetSide|>]];
  Join[First[choices], <|"SelectionMethod" -> mode, "ParameterAssumptions" -> ass,
    "InferenceComplete" -> True, "GlobalMonotonicityProof" -> If[AssociationQ[monotonicity], monotonicity, Missing["NotRequired"]],
    "OriginalCondition" -> condition, "RealFunctionDomain" -> realDomain,
    "OriginalInverseExpression" -> Lookup[data, "OriginalExpression", Missing["NotRecorded"]]|>]];

inverseFunctionSelectBranch[data_, target_, targetSide_, ass_, limit_, selection_: Automatic] :=
  catch[inverseFunctionSelectBranchInternal[data, target, targetSide, ass, limit, selection]];
(* END SOURCE: src/Kernel/InverseFunctionBranches.wl *)

(* BEGIN SOURCE: src/Kernel/InverseFunctionFamilies.wl
   Source SHA256 (UTF-8/LF): d7c6d4c1acf616bdf990e44c2f8729a583b836cd757a95e64d81ed65ead3abe0 *)
(* Loaded in AsymptoticAnalysis`Private`.

   Exact scalar family reduction, before choosing a source inverse branch:
       A(x) F(t) + B(x) == Y(x)  <=>  F(t) == (Y(x)-B(x))/A(x).
   The equivalence requires A(x) != 0.  This helper has no endpoint or approach
   direction, so it records that obligation explicitly; its caller MUST prove
   eventual nonvanishing of Amplitude in the requested target germ.  The
   algebraic decomposition is independently verified without assuming A != 0.
   No varying parameter is replaced by a limiting or numerical value. *)

SetAttributes[inverseFamilyTry, HoldAll];
inverseFamilyTry[expr_] := TimeConstrained[Quiet[Check[expr, $Failed]], 2,
  fail["ResourceLimit", "Exact inverse-family reduction exceeded its two-second algebraic-operation limit.",
    <|"Stage" -> "InverseFunctionFamilyReduction", "TimeLimit" -> 2|>]];

(* Bound the number of terms before Expand can distribute a large product.
   A power of a sum of m terms has at most Binomial[n+m-1,m-1] distinct
   commutative products.  This is an upper bound, not an exact support count. *)
inverseFamilyExpansionCount[e_, limit_] := Module[{head = Head[e], counts, m, n},
  Which[
    head === Plus,
      Min[limit + 1, Total[inverseFamilyExpansionCount[#, limit] & /@ (List @@ e)]],
    head === Times,
      counts = inverseFamilyExpansionCount[#, limit] & /@ (List @@ e);
      Fold[Min[limit + 1, #1 #2] &, 1, counts],
    head === Power && IntegerQ[e[[2]]] && e[[2]] >= 0,
      n = e[[2]]; m = inverseFamilyExpansionCount[e[[1]], limit];
      Which[n === 0 || m === 1, 1, m > limit || n >= limit, limit + 1,
        True, Min[limit + 1, Binomial[n + m - 1, m - 1]]],
    True, 1]];

inverseFunctionSeparateFamily[data_Association, x_Symbol, ass_, limit_] := Module[
  {source, body, condition, parameters, positions, expanded, terms, offset,
    dependent, pairs, factors, sourceFactors, sourcePart, coefficient,
    groups, rows, factored, amplitude, ratios, core, identity, target,
    fixed, removed, reduction},
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! And @@ (KeyExistsQ[data, #] & /@
      {"Body", "SourceVariable", "Condition", "TargetExpression", "Parameters"}),
    fail["InvalidInverseFunctionData", "A scalar inverse family needs parsed body, source, condition, target and parameter data."]];
  {body, source, condition, parameters} = Lookup[data,
    {"Body", "SourceVariable", "Condition", "Parameters"}];
  If[Head[source] =!= Symbol || source === x || ! ListQ[parameters],
    fail["InvalidInverseFunctionData", "The inverse family needs a distinct source symbol and a list of frozen argument values."]];
  If[FreeQ[parameters, x] || ! FreeQ[condition, x], Return[$Failed, Module]];
  If[! FreeQ[ass, source],
    fail["InvalidAssumptions", "Inverse-family parameter assumptions must not contain the fresh source variable."]];
  inverseFunctionSyntaxBudget[body, limit, "InverseFunctionFamilyInput"];
  If[inverseFamilyExpansionCount[body, limit] > limit,
    fail["ResourceLimit", "Distributing the inverse-family expression would exceed the MaxTerms support budget.",
      <|"Stage" -> "InverseFunctionFamilyExpansion", "MaxTerms" -> limit|>]];
  expanded = inverseFamilyTry[Expand[body]];
  If[expanded === $Failed, Return[$Failed, Module]];
  inverseFunctionSyntaxBudget[expanded, limit, "InverseFunctionFamilyExpansion"];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  offset = Total[Select[terms, FreeQ[#, source] &]];
  dependent = Select[terms, ! FreeQ[#, source] &];
  If[dependent === {}, Return[$Failed, Module]];
  pairs = {};
  Do[
    factors = If[Head[term] === Times, List @@ term, {term}];
    sourceFactors = Select[factors, ! FreeQ[#, source] &];
    sourcePart = Times @@ sourceFactors;
    If[! FreeQ[sourcePart, x], Return[$Failed, Module]];
    coefficient = Times @@ Select[factors, FreeQ[#, source] &];
    AppendTo[pairs, {sourcePart, coefficient}], {term, dependent}];
  (* Group first: Expand[(1+x) F(t)] produces separate constant and x
     terms, which must be recombined before extracting their common factor. *)
  groups = GatherBy[pairs, First];
  rows = Table[{group[[1, 1]], inverseFamilyTry[FullSimplify[Total[group[[All, 2]]], ass]]},
    {group, groups}];
  If[AnyTrue[rows, Last[#] === $Failed &], Return[$Failed, Module]];
  rows = Select[rows, Last[#] =!= 0 &];
  If[rows === {}, Return[$Failed, Module]];
  factored = inverseFamilyTry[Factor[rows[[1, 2]]]];
  If[factored === $Failed, Return[$Failed, Module]];
  factors = If[Head[factored] === Times, List @@ factored, {factored}];
  (* Strip source-independent FIXED factors from the chosen amplitude.  In
     a(1+x) t+b(1+x) t^2 this chooses A=1+x, avoiding an unnecessary a!=0. *)
  amplitude = Times @@ Select[factors, ! FreeQ[#, x] &];
  If[amplitude === 0 || ! FreeQ[amplitude, source], Return[$Failed, Module]];
  ratios = inverseFamilyTry[FullSimplify[Cancel[#[[2]]/amplitude], ass]] & /@ rows;
  If[MemberQ[ratios, $Failed] || ! FreeQ[ratios, x], Return[$Failed, Module]];
  core = Total[MapThread[Times, {rows[[All, 1]], ratios}]];
  If[! FreeQ[core, x] || FreeQ[core, source] || ! FreeQ[offset, source], Return[$Failed, Module]];
  identity = inverseFamilyTry[FullSimplify[body == amplitude core + offset, ass]];
  If[! TrueQ[identity], Return[$Failed, Module]];
  target = inverseFamilyTry[Cancel[(data["TargetExpression"] - offset)/amplitude]];
  If[target === $Failed, Return[$Failed, Module]];
  inverseFunctionSyntaxBudget[{core, target, amplitude, offset}, limit, "InverseFunctionFamilyResult"];
  positions = Lookup[data, "ParameterPositions", Range[Length[parameters]]];
  If[! ListQ[positions] || Length[positions] =!= Length[parameters],
    fail["InvalidInverseFunctionData", "Inverse-family parameter positions must match their values."]];
  fixed = Select[Range[Length[parameters]], FreeQ[parameters[[#]], x] &];
  removed = Complement[Range[Length[parameters]], fixed];
  reduction = <|"Type" -> "ExactAffineOutputFamily", "OriginalBody" -> body,
    "Core" -> core, "Amplitude" -> amplitude, "Offset" -> offset,
    "OriginalTargetExpression" -> data["TargetExpression"], "TransformedTargetExpression" -> target,
    "OriginalParameters" -> parameters, "RemovedParameterPositions" -> positions[[removed]],
    "RequiredCondition" -> (amplitude != 0), "IdentityVerified" -> True,
    "IdentityAssumptions" -> ass,
    "Proof" -> "Exact symbolic identity Body == Amplitude Core + Offset; inverse equivalence additionally requires eventual Amplitude != 0."|>;
  Join[data, <|"Body" -> core, "TargetExpression" -> target,
    "Parameters" -> parameters[[fixed]], "ParameterPositions" -> positions[[fixed]],
    "Amplitude" -> amplitude, "ExactFamilyReduction" -> reduction|>]];

inverseFunctionSeparateFamily[___] :=
  fail["InvalidArguments", "Inverse-family separation requires parsed inverse data, an expansion symbol, parameter assumptions and MaxTerms."];
(* END SOURCE: src/Kernel/InverseFunctionFamilies.wl *)

(* BEGIN SOURCE: src/Kernel/InverseFunctionExpressions.wl
   Source SHA256 (UTF-8/LF): edbce75c731a9575761f729ec3f1a4a54f2b11c96fcd1a59122ce8ee1301f07d *)
(* Applied inverse functions are implicit scalar germs.  Parse their callable,
   establish its real source branch, then compose the existing inverse with
   the precision-tracked target argument.  Never use native Series on an
   unevaluated InverseFunction as the coefficient oracle. *)

$inverseFunctionProvenance = None;
$inverseFunctionBranchSelections = Automatic;
$inverseFunctionSyntaxCache = None;
$inverseFunctionBranchCache = None;

inverseFunctionParsedData[e_, ass_, limit_] := Module[{key = HoldComplete[e, ass, limit], data},
  If[AssociationQ[$inverseFunctionSyntaxCache] && KeyExistsQ[$inverseFunctionSyntaxCache, key],
    Return[$inverseFunctionSyntaxCache[key], Module]];
  data = inverseFunctionApplicationData[e, ass, limit];
  If[AssociationQ[$inverseFunctionSyntaxCache], AssociateTo[$inverseFunctionSyntaxCache, key -> data]];
  data];

inverseFunctionSelectedBranch[data_, target_, side_, ass_, limit_] := Module[{selection, key, branch},
  selection = inverseFunctionSelection[data];
  key = With[{body = data["Body"], source = data["SourceVariable"], condition = data["Condition"], chosen = selection},
    HoldComplete[body, source, condition, target, side, ass, limit, chosen]];
  If[AssociationQ[$inverseFunctionBranchCache] && KeyExistsQ[$inverseFunctionBranchCache, key],
    Return[$inverseFunctionBranchCache[key], Module]];
  branch = inverseFunctionSelectBranch[data, target, side, ass, limit, selection];
  If[FailureQ[branch], Throw[branch, $tag]];
  If[AssociationQ[$inverseFunctionBranchCache], AssociateTo[$inverseFunctionBranchCache, key -> branch]];
  branch];

inverseFunctionEventually[condition_, u_, ass_] := Module[{simple, delta, proof},
  simple = Quiet[FullSimplify[condition, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  delta = Unique["inverseRadius$"];
  proof = Quiet[TimeConstrained[Resolve[Exists[delta, delta > 0 &&
      ForAll[u, Implies[0 < u < delta, condition]]], Reals], 5, $Failed]];
  TrueQ[Quiet[FullSimplify[proof, ass]]]];

(* HoldAllComplete at the public boundary prevents Wolfram's automatic
   ConditionalExpression propagation from rewriting Assumptions before this
   check.  The private entry evaluates arguments normally, including Sequence
   and native closed-form inverse evaluation. *)
forwardPublic[f_, x_, x0_, cutoff_, opts : OptionsPattern[AsymptoticExpansion]] := Block[
  {$inverseFunctionProvenance = {}, $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>, $inverseFunctionBranchSelections =
    OptionValue[AsymptoticExpansion, {opts}, "InverseFunctionBranches"]}, Module[
  {body = f, condition, ass, parameterAss, coord, result, rules, records, targetDomain},
  ass = optionAssumptions[AsymptoticExpansion, {opts}];
  {body, parameterAss, condition} = splitApproachInput[body, x, ass];
  coord = localCoordinate[x, x0, OptionValue[AsymptoticExpansion, {opts}, Direction]];
  If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], coord["u"], parameterAss],
    fail["IncompatibleTargetCondition", "The expression's condition must hold eventually on the requested real approach.",
      <|"Condition" -> condition, "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"]|>]];
  rules = DeleteCases[withoutAssumptions[{opts}], HoldPattern[("InverseFunctionBranches" -> _) | ("InverseFunctionBranches" :> _)]];
  result = inverseFunctionDirectExpansion[body, x, x0, cutoff, parameterAss, coord,
    OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]];
  If[result === $Failed,
    result = dirichletSpecialForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = specialFunctionForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = barnesForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = gammaForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = exponentialForwardExpansion[body, x, x0, cutoff, parameterAss, coord,
      OptionValue[AsymptoticExpansion, {opts}, SeriesTermGoal], OptionValue[AsymptoticExpansion, {opts}, "MaxTerms"]]];
  If[result === $Failed,
    result = forwardCore[body, x, x0, cutoff, Assumptions -> parameterAss, Sequence @@ rules]];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  records = DeleteDuplicates[$inverseFunctionProvenance];
  targetDomain = condition && coord["LocalVariable"] > 0 && Lookup[result[[1]], "TargetDomain", True];
  GeneralizedSeries[Join[result[[1]],
    If[AssociationQ[Lookup[result[[1]], "SeriesRepresentation", None]],
      <|"SeriesRepresentation" -> Join[result["SeriesRepresentation"],
        <|"Domain" -> targetDomain && Lookup[result["SeriesRepresentation"], "Domain", True]|>]|>, <||>],
    If[Lookup[result[[1]], "Kind", ""] === "Forward", <|"Function" -> ConditionalExpression[body, condition]|>, <||>],
    If[KeyExistsQ[result[[1]], "InverseFunctionExpression"],
      <|"InverseFunctionExpression" -> ConditionalExpression[body, condition]|>, <||>], <|
    "TargetDomain" -> targetDomain,
    "InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> records|>]]]];

Options[AsymptoticExpansion] = Append[Options[AsymptoticExpansion], "InverseFunctionBranches" -> Automatic];
Options[AsymptoticInverse] = Append[Options[AsymptoticInverse], "InverseFunctionBranches" -> Automatic];
Options[AsymptoticAnalysis`SeriesObservable] = Append[Options[AsymptoticAnalysis`SeriesObservable], "InverseFunctionBranches" -> Automatic];

(* Decide relational conditions using the available input jet, including its
   remainder. An unknown zero block cannot prove equality or a sign. *)
inverseFunctionConditionOnJet[c_, x_, input_, d_, cut_, limit_] := Module[
  {head = Head[c], values, pairs, j, row, degree, coefficient, sign, scalar},
  If[FreeQ[c, x], Return[TrueQ[Quiet[FullSimplify[c, seriesAss[d]]]], Module]];
  If[MemberQ[{And, Or}, head],
    values = inverseFunctionConditionOnJet[#, x, input, d, cut, limit] & /@ List @@ c;
    Return[If[head === And, And @@ values, Or @@ values], Module]];
  If[head === Inequality,
    pairs = Partition[List @@ c, 3, 2];
    Return[And @@ (inverseFunctionConditionOnJet[#[[2]][#[[1]], #[[3]]], x, input, d, cut, limit] & /@ pairs), Module]];
  If[head === Element && c[[2]] === Reals,
    j = seriesJetApply[c[[1]], x, input, d, cut, limit];
    Return[And @@ (TrueQ[FullSimplify[Element[#[[2]], Reals], seriesAss[d] && Element[d["LogVariable"], Reals]]] & /@ j[[1]]), Module]];
  If[! MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head], Return[False, Module]];
  If[Length[c] > 2,
    pairs = If[head === Unequal, Subsets[List @@ c, {2}], Partition[List @@ c, 2, 1]];
    Return[And @@ (inverseFunctionConditionOnJet[Apply[head, #], x, input, d, cut, limit] & /@ pairs), Module]];
  j = seriesJetApply[c[[1]] - c[[2]], x, input, d, cut, limit];
  If[j[[1]] === {},
    Return[j[[2]] === Infinity && MemberQ[{Equal, LessEqual, GreaterEqual}, head], Module]];
  row = First[j[[1]]]; degree = polyDegree[row[[2]], d["LogVariable"]];
  coefficient = (-1)^degree Coefficient[row[[2]], d["LogVariable"], degree];
  sign = Which[provablyPositive[coefficient, seriesAss[d]], 1,
    provablyNegative[coefficient, seriesAss[d]], -1, True, 0];
  Which[MemberQ[{Less, LessEqual}, head], sign === -1,
    MemberQ[{Greater, GreaterEqual}, head], sign === 1, head === Unequal, sign =!= 0,
    True, False]];

inverseFunctionDirectExpansion[e_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {data, branch, result, source, record, base = e, power = 1, model},
  If[Head[e] === Power && FreeQ[e[[2]], x] && inverseFunctionApplicationQ[e[[1]]],
    base = e[[1]]; power = e[[2]]];
  data = If[inverseFunctionApplicationQ[base], inverseFunctionParsedData[base, ass, limit],
    inverseFunctionNativeLambertData[base, x]];
  If[data === $Failed, Return[$Failed, Module]];
  If[data["TargetExpression"] =!= x || ! FreeQ[data["Parameters"], x], Return[$Failed, Module]];
  branch = inverseFunctionSelectedBranch[data, x0, If[coord["Infinite"], 0, coord["Sign"]], ass, limit];
  source = data["SourceVariable"];
  (* Gamma inversion at a source infinity supports powers of the source
     itself. Other inverse charts may instead represent a displacement
     from a finite endpoint, so their outer powers use the ordinary path. *)
  If[power =!= 1,
    model = gammaInverseModel[data["Body"], source, ass];
    If[model === $Failed || branch["SourcePoint"] =!=
        If[provablyPositive[model["SourceScale"], ass], Infinity, -Infinity],
      Return[$Failed, Module]]];
  result = inverseDispatch[data["Body"], source, branch["SourcePoint"], x, cut,
    Assumptions -> ass, Direction -> branch["Direction"], SeriesTermGoal -> goal,
    "Power" -> power, "MaxTerms" -> limit];
  If[FailureQ[result], Throw[result, $tag]];
  result = GeneralizedSeries[Join[result[[1]], <|"SourceVariable" -> source,
    "SourceDomain" -> branch["SourceDomain"] && inverseEvidenceSourceDomain[result[[1]], source], "InverseFunctionSyntax" -> data,
    "InverseFunctionBranch" -> branch, "InverseFunctionExpression" -> e,
    "InverseFunctionExpansionPoint" -> x0, "InverseFunctionExpansionDirection" -> coord["Direction"]|>]];
  record = <|"Expression" -> e, "Syntax" -> data, "Branch" -> branch, "InverseSeries" -> result|>;
  If[ListQ[$inverseFunctionProvenance], AppendTo[$inverseFunctionProvenance, record]];
  result];

(* Native evaluation of an inverse of t Exp[t] can erase the InverseFunction
   head. Recover its documented real branch from ProductLog itself, retaining
   that branch rather than applying a principal-root convention afterwards. *)
inverseFunctionNativeLambertData[e_, x_] := Module[{k, argument, source},
  If[Head[e] =!= ProductLog || ! MemberQ[{1, 2}, Length[e]], Return[$Failed, Module]];
  k = If[Length[e] === 1, 0, e[[1]]]; argument = Last[e];
  If[! MemberQ[{0, -1}, k] || argument =!= x, Return[$Failed, Module]];
  source = Unique["inverseSource$"];
  <|"Body" -> source Exp[source], "SourceVariable" -> source,
    "Condition" -> If[k === 0, source >= -1, source <= -1],
    "TargetExpression" -> argument, "Parameters" -> {}, "ParameterPositions" -> {},
    "SourceArguments" -> {source}, "ArgumentIndex" -> 1, "ArgumentCount" -> 1,
    "OriginalExpression" -> e, "OriginalOperator" -> ProductLog,
    "NativeRealBranch" -> k, "NativeIdentity" -> "ProductLog[k,z] Exp[ProductLog[k,z]] == z"|>];

inverseFunctionPublicInverse[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Block[
  {$inverseFunctionProvenance = {}, $inverseFunctionSyntaxCache = <||>, $inverseFunctionBranchCache = <||>, $inverseFunctionBranchSelections =
    OptionValue[AsymptoticInverse, {opts}, "InverseFunctionBranches"]}, Module[
  {body = f, condition, ass, parameterAss, coord, result, rules},
  ass = optionAssumptions[AsymptoticInverse, {opts}];
  {body, parameterAss, condition} = splitApproachInput[body, x, ass];
  coord = localCoordinate[x, x0, OptionValue[AsymptoticInverse, {opts}, Direction]];
  If[! inverseFunctionEventually[condition /. x -> coord["Substitution"], coord["u"], parameterAss],
    fail["IncompatibleSourceCondition", "The forward expression's condition must hold eventually on the requested real source approach.",
      <|"Condition" -> condition, "Variable" -> x, "ExpansionPoint" -> x0, "Direction" -> coord["Direction"]|>]];
  rules = DeleteCases[withoutAssumptions[{opts}], HoldPattern[("InverseFunctionBranches" -> _) | ("InverseFunctionBranches" :> _)]];
  result = inverseDispatch[body, x, x0, y, cutoff, Assumptions -> parameterAss, Sequence @@ rules];
  If[! MatchQ[result, _GeneralizedSeries], Return[result, Module]];
  If[condition === True && $inverseFunctionProvenance === {} && $inverseFunctionBranchSelections === Automatic,
    Return[result, Module]];
  GeneralizedSeries[Join[result[[1]], <|"OriginalExpression" -> f,
    "ConditionalSourceReplay" -> ConditionalExpression[body, condition],
    "SourceVariable" -> x, "SourceDomain" -> condition &&
      inverseEvidenceSourceDomain[result[[1]], x],
    "InverseFunctionBranches" -> $inverseFunctionBranchSelections,
    "InverseFunctionProvenance" -> DeleteDuplicates[$inverseFunctionProvenance]|>]]]];

inverseFunctionTargetGerm[j_, ell_, ass_] := Module[{parts, eta, rest, row, degree, sign},
  If[j[[1]] === {}, fail["UnknownLeadingTerm", "The inverse target is known only through a remainder."]];
  parts = splitJet[j[[1]]];
  If[parts[[1]] =!= {},
    row = First[parts[[1]]]; degree = polyDegree[row[[2]], ell];
    sign = (-1)^degree Coefficient[row[[2]], ell, degree];
    Return[<|"Limit" -> Which[provablyPositive[sign, ass], Infinity,
      provablyNegative[sign, ass], -Infinity,
      True, fail["UnprovedSign", "The inverse target's infinite limit has no proved sign."]],
      "Side" -> 0, "Order" -> -row[[1]]|>, Module]];
  eta = parts[[2]];
  If[! FreeQ[eta, ell],
    fail["UnsupportedInverseTargetScale", "A purely logarithmically divergent target requires a logarithmic composition chart."]];
  rest = parts[[3]];
  If[rest === {}, fail["UnknownLeadingTerm", "No nonconstant inverse target block is available; increase its precision."]];
  row = First[rest]; degree = polyDegree[row[[2]], ell];
  sign = (-1)^degree Coefficient[row[[2]], ell, degree];
  <|"Limit" -> eta, "Side" -> Which[provablyPositive[sign, ass], 1,
    provablyNegative[sign, ass], -1,
    True, fail["UnprovedSign", "The inverse target's one-sided approach has no proved sign."]],
    "Order" -> row[[1]]|>];

inverseFunctionSelection[data_] := Which[
  $inverseFunctionBranchSelections === Automatic, Automatic,
  AssociationQ[$inverseFunctionBranchSelections],
    Lookup[$inverseFunctionBranchSelections, data["OriginalOperator"], Automatic],
  True, fail["InvalidOption", "InverseFunctionBranches must be Automatic or an association from inverse operators to source-point/direction associations."]];

inverseFunctionForwardJet[e_, u_, ell_, ass_, cut_, limit_] :=
  inverseFunctionJetApply[e, u, pVar,
    <|"Variable" -> u, "ScaleVariable" -> u, "LogVariable" -> ell,
      "Assumptions" -> ass, "Domain" -> u > 0, "Prefactor" -> 1, "Offset" -> 0,
      "Jet" -> pVar, "Cutoff" -> cut, "RemainderDerivativeOrder" -> Infinity|>, cut, limit];

inverseFunctionJetApply[e_, x_, input_, d_, cut_, limit_] := Module[
  {data, reduced, target, germ, branch, source, v, outer, inner, composed, flat, outerCut, record, ass},
  If[cut === Infinity, fail["InfiniteSeries", "An implicit inverse generally needs a finite working precision."]];
  ass = d["Assumptions"];
  data = inverseFunctionParsedData[e, ass, limit];
  If[! FreeQ[data["Parameters"], x],
    reduced = inverseFunctionSeparateFamily[data, x, ass, limit];
    If[reduced === $Failed,
      fail["VaryingInverseParameters", "The varying non-inverted arguments do not reduce to a proved affine output family and need a coupled implicit expansion.",
        <|"ParameterPositions" -> data["ParameterPositions"], "Parameters" -> data["Parameters"]|>]];
    If[! TrueQ[inverseFunctionConditionOnJet[reduced["Amplitude"] != 0, x, input, d, cut, limit]],
      fail["UnprovedInverseFamilyAmplitude", "The exact inverse-family reduction requires an eventually nonzero amplitude.",
        <|"Amplitude" -> reduced["Amplitude"]|>]];
    data = Join[reduced, <|"AmplitudeNonvanishingVerified" -> True|>]];
  target = seriesJetApply[data["TargetExpression"], x, input, d, cut, limit];
  germ = inverseFunctionTargetGerm[target, d["LogVariable"], seriesAss[d]];
  branch = inverseFunctionSelectedBranch[data, germ["Limit"], germ["Side"], ass, limit];
  source = data["SourceVariable"]; v = Unique["inverseTarget$"];
  outerCut = Max[2, Ceiling[Abs[cut]/germ["Order"]] + 2];
  outer = inverseDispatch[data["Body"], source, branch["SourcePoint"], v, outerCut,
    Assumptions -> ass, Direction -> branch["Direction"], "MaxTerms" -> limit];
  If[FailureQ[outer], Throw[outer, $tag]];
  outer = GeneralizedSeries[Join[outer[[1]], <|"SourceVariable" -> source,
    "SourceDomain" -> branch["SourceDomain"] && inverseEvidenceSourceDomain[outer[[1]], source], "InverseFunctionSyntax" -> data,
    "InverseFunctionBranch" -> branch|>]];
  inner = seriesMake[Join[d, <|"Jet" -> target, "Prefactor" -> 1, "Offset" -> 0|>], {"InverseTarget", {}, e}];
  composed = AsymptoticAnalysis`SeriesCompose[outer, inner, "Cutoff" -> cut, "MaxTerms" -> limit];
  If[FailureQ[composed], Throw[composed, $tag]];
  flat = seriesFlat[seriesData[composed, limit], limit];
  If[flat === $Failed, fail["UnsupportedInverseCompositionScale", "The selected inverse does not flatten to the enclosing power-log coordinate."]];
  record = <|"Expression" -> e, "Syntax" -> data, "Branch" -> branch, "InverseSeries" -> outer|>;
  If[ListQ[$inverseFunctionProvenance], AppendTo[$inverseFunctionProvenance, record]];
  flat["Jet"] /. flat["LogVariable"] -> d["LogVariable"]];
(* END SOURCE: src/Kernel/InverseFunctionExpressions.wl *)

(* BEGIN SOURCE: src/Kernel/GammaForward.wl
   Source SHA256 (UTF-8/LF): f9fb80f55892521f0150bca280d448e53c1aa3c3dcb5b1d542a45642a61e5d40 *)
(* Combine real Gamma products in the logarithmic domain. Stirling's
   expansion is Poincare asymptotic, not a convergent series:
   https://dlmf.nist.gov/5.11.E3 and https://dlmf.nist.gov/5.11.ii . *)

(* Separate ordinary factors before distributing powers over positive
   special-function factors. Keep whole atoms and original exponents:
   constant factors remain ordinary, and powers still require realness
   even if their products simplify. The family pattern includes every
   arity so an unsupported dependent Gamma[a,x] cannot become ordinary. *)
positiveSpecialProductData[e_, x_, family_] := Module[{parts, base, r},
  If[FreeQ[e, family] || FreeQ[e, x], Return[{e, {}, {}}, Module]];
  Which[
    MatchQ[e, family] && Length[e] === 1, {1, {{e, 1}}, {}},
    Head[e] === Times,
      parts = positiveSpecialProductData[#, x, family] & /@ List @@ e;
      If[MemberQ[parts, $Failed], $Failed,
        {Times @@ parts[[All, 1]], Join @@ parts[[All, 2]], Join @@ parts[[All, 3]]}],
    Head[e] === Power,
      base = positiveSpecialProductData[e[[1]], x, family]; r = e[[2]];
      If[base === $Failed || base[[2]] === {}, $Failed,
        {base[[1]]^r, {#[[1]], r #[[2]]} & /@ base[[2]], Append[base[[3]], r]}],
    True, $Failed]];

(* Positivity and optional growth precede the power checks; the ordinary
   coefficient is checked last. Gamma and Barnes keep their own power
   failure tags and construct their logarithms only after these proofs. *)
positiveSpecialProductSource[e_, x_, family_, ass_, coord_, requireGrowth_, powerFailure_] := Module[
  {product, factors, arguments, powers, localArg, growing = False, ordinary},
  product = positiveSpecialProductData[e, x, family];
  If[product === $Failed || product[[2]] === {}, Return[$Failed, Module]];
  factors = product[[2]]; arguments = DeleteDuplicates[factors[[All, 1, 1]]];
  Do[
    localArg = arg /. x -> coord["Substitution"];
    If[! inverseFunctionEventually[localArg > 0, coord["u"], ass], Return[$Failed, Module]];
    If[TrueQ[requireGrowth] && inverseBranchTry[Limit[localArg, coord["u"] -> 0,
        Direction -> "FromAbove", Assumptions -> ass]] === Infinity, growing = True], {arg, arguments}];
  If[TrueQ[requireGrowth] && ! growing, Return[$Failed, Module]];
  powers = DeleteDuplicates[Join[product[[3]], factors[[All, 2]]]];
  If[! AllTrue[powers, logarithmicRealCondition[Element[# /. x -> coord["Substitution"], Reals], ass, coord] &],
    fail[powerFailure[[1]], powerFailure[[2]], <|"Powers" -> powers|>]];
  ordinary = logarithmicProductSource[product[[1]], x, ass, coord];
  <|"Factors" -> factors, "Sign" -> ordinary["Sign"], "OrdinaryLogarithm" -> ordinary["Logarithm"],
    "Domain" -> ordinary["Domain"] && And @@ (# > 0 & /@ arguments) &&
      And @@ (Element[#, Reals] & /@ powers)|>];

gammaRelatedExpression[e_] := e /. {
  HoldPattern[Factorial[z_]] :> Gamma[z + 1],
  HoldPattern[Binomial[n_, k_]] :> Gamma[n + 1]/(Gamma[k + 1] Gamma[n - k + 1]),
  HoldPattern[Beta[a_, b_]] :> Gamma[a] Gamma[b]/Gamma[a + b],
  HoldPattern[Pochhammer[a_, n_]] :> Gamma[a + n]/Gamma[a]};

(* The logarithmic identity also applies at finite positive arguments.
   Growing arguments are required only when extracting a Gamma carrier. *)
gammaProductLogSource[f_, x_, ass_, coord_, limit_, requireGrowth_] := Module[
  {lowered, source, factors, logFunction, simplified, domain},
  If[FreeQ[f, _Gamma | _Factorial | _Binomial | _Beta | _Pochhammer], Return[$Failed, Module]];
  validateInput[f, limit];
  lowered = gammaRelatedExpression[f];
  source = positiveSpecialProductSource[lowered, x, _Gamma, ass, coord, requireGrowth,
    {"UnsupportedGammaPower", "Gamma powers require exact exponents that are eventually real."}];
  If[source === $Failed, Return[$Failed, Module]];
  factors = {#[[1, 1]], #[[2]]} & /@ source["Factors"]; domain = source["Domain"];
  logFunction = Total[#[[2]] LogGamma[#[[1]]] & /@ factors];
  simplified = TimeConstrained[FullSimplify[logFunction, ass && domain], 3, logFunction];
  (* FullSimplify can recombine LogGamma into Log[Gamma]. Keep only
     simplifications the power-log parser can still expand, such as Log[x]
     from the exact recurrence. Finite Stirling cancellation is not an
     exact identity of the original functions. *)
  If[FreeQ[simplified, _Gamma], logFunction = simplified];
  logFunction += source["OrdinaryLogarithm"];
  <|"Logarithm" -> logFunction, "Sign" -> source["Sign"], "Domain" -> domain,
    "GammaFactors" -> factors, "GammaExpression" -> lowered|>];

gammaForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[{source, factors},
  source = gammaProductLogSource[f, x, ass, coord, limit, True];
  If[source === $Failed, Return[$Failed, Module]];
  factors = source["GammaFactors"];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit, <|
      "GammaPower" -> If[Length[factors] === 1, factors[[1, 2]], Missing["NotSingleGamma"]],
      "GammaFactors" -> factors, "GammaExpression" -> source["GammaExpression"],
      "Transformation" -> "A signed product of positive Gamma factors with real powers equals Sign[coefficient] Exp[Log[Abs[coefficient]] + Sum[power LogGamma[arg]]].",
      "AsymptoticReference" -> "https://dlmf.nist.gov/5.11.E3"|>]];

(* Rewrite scalar logarithms before expanding their rapidly growing arguments.
   Bound function bodies and held expressions have different variable scopes.
   A positive Gamma value at a negative argument is deliberately left to the
   ordinary local parser: its real Log need not equal analytic LogGamma. *)
gammaLogarithmNormalize[f_, x_, ass_, coord_, limit_] := Module[
  {walk, changed = False, analyticLogarithm = False, domains = {}, normalized, simplified, reduced},
  walk[e_] := Module[{value, source},
    If[AtomQ[e] || FreeQ[e, _Log | _LogGamma | _LogBarnesG] ||
       FreeQ[e, _Gamma | _LogGamma | _BarnesG | _LogBarnesG | _Factorial | _Binomial | _Beta | _Pochhammer] ||
       ! MatchQ[Head[e], _Symbol] || MemberQ[{Piecewise, ConditionalExpression}, Head[e]] ||
       ! FreeQ[With[{head = Head[e]}, Attributes[head]], HoldAll | HoldAllComplete | HoldFirst | HoldRest],
      Return[e, Module]];
    value = Map[walk, e];
    If[Head[value] === LogBarnesG && Length[value] === 1 && ! FreeQ[value, x] &&
       inverseFunctionEventually[(First[value] /. x -> coord["Substitution"]) > 0, coord["u"], ass],
      changed = True; AppendTo[domains, First[value] > 0];
      value = barnesLogShift[First[value], x, ass, coord, limit];
      AppendTo[domains, barnesLogDomain[value]]];
    If[Head[value] === LogGamma && Length[value] === 1 &&
       inverseFunctionEventually[(First[value] /. x -> coord["Substitution"]) > 0, coord["u"], ass],
      analyticLogarithm = True; AppendTo[domains, First[value] > 0]];
    If[Head[value] === Log && Length[value] === 1,
      source = barnesProductLogSource[First[value], x, ass, coord, limit, False];
      If[source === $Failed, source = gammaProductLogSource[First[value], x, ass, coord, limit, False]];
      If[AssociationQ[source],
        If[source["Sign"] =!= 1,
          fail["NonpositiveGammaLogarithm", "A real logarithm requires an eventually positive Gamma or Barnes G product."]];
        changed = True; AppendTo[domains, source["Domain"]];
        value = source["Logarithm"]]];
    value];
  normalized = walk[f];
  If[changed || analyticLogarithm,
    reduced = barnesLogReduce[normalized, x, ass, coord, limit];
    normalized = reduced["Expression"]; AppendTo[domains, reduced["Domain"]];
    (* Exact Gamma recurrences must be simplified across separate logarithms
       before finite Stirling tails can cancel. Do not infer exactness from
       a cancelled finite asymptotic model. *)
    simplified = TimeConstrained[FullSimplify[normalized, ass && And @@ domains], 3, normalized];
    If[FreeQ[simplified, _Gamma | _BarnesG] && simplified =!= normalized,
      normalized = simplified; changed = True];
    validateInput[normalized, limit]];
  <|"Expression" -> normalized, "Changed" -> changed, "Domain" -> And @@ domains|>];

(* Absolute vanishing logarithmic errors become relative errors. Extract
   every nonvanishing logarithmic block into the exact prefactor before
   counting correction terms. *)
logarithmicForwardExpansion[f_, logFunction_, sign_, domain_, x_, x0_, cutoff0_, ass_, coord_, goal_, limit_, metadata_] := Module[
  {cutoff = cutoff0, working, tries = 0, logarithmic, expanded, data, rows,
   omitted, frontier, prefactor, result, magnitude, normalized, exactCorrection},
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1,
      fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]];
    If[goal + 1 > limit, fail["ResourceLimit", "The normalized term goal and its frontier exceed MaxTerms."]],
    If[! exactRealQ[cutoff], fail["InvalidCutoff", "The cutoff must be an exact real number."]]];
  working = If[cutoff === Automatic, 1, Max[1, cutoff]];
  While[True,
    If[++tries > 12 || Ceiling[working] + 2 > limit,
      fail["ResourceLimit", "Logarithmic normalization exceeded its working-order budget."]];
    logarithmic = forwardCore[logFunction, x, x0, working + 1,
      Assumptions -> ass, Direction -> coord["Direction"], "MaxTerms" -> limit];
    expanded = seriesExp[logarithmic, working + 1, limit];
    data = seriesData[expanded, limit];
    (* A finite exact factor can disappear into Log and acquire a spurious
       Taylor tail. Recover it from the exact logarithmic identity, never
       from cancellation in a finite asymptotic model. *)
    If[tries === 1 && FreeQ[logFunction, _LogGamma | _Gamma | _barnesLog | _BarnesG | _LogBarnesG],
      normalized = TimeConstrained[FullSimplify[Exp[logFunction]/data["Prefactor"], ass && domain], 3, $Failed];
      If[normalized =!= $Failed,
        (* Simplification can reintroduce separately unbounded factors.
           Failure of this optional exactness probe must not discard the
           valid logarithmic expansion already computed above. *)
        exactCorrection = Catch[exactJet[normalized /. x -> coord["Substitution"],
          coord["u"], data["LogVariable"], ass, limit], $tag];
        If[MatchQ[exactCorrection, {_List, Infinity, _}],
          data = Join[data, <|"Jet" -> exactCorrection|>]]]];
    rows = data["Jet"][[1]];
    If[cutoff =!= Automatic || Length[rows] > goal || data["Jet"][[2]] === Infinity, Break[]];
    working = 2 working + 1];
  If[cutoff === Automatic, cutoff = If[Length[rows] > goal, rows[[goal + 1, 1]], Infinity]];
  If[IntegerQ[goal] && goal > 0 && Length[Select[rows, less[#[[1]], cutoff] &]] > goal,
    cutoff = rows[[goal + 1, 1]]];
  omitted = Select[rows, ! less[#[[1]], cutoff] &];
  prefactor = TimeConstrained[FullSimplify[sign data["Prefactor"], ass && domain], 3, sign data["Prefactor"]];
  data = Join[data, <|"Prefactor" -> prefactor, "Domain" -> domain,
    "RemainderDerivativeOrder" -> 0|>];
  result = seriesMake[data, {"LogarithmicForward", {}}, cutoff];
  (* The carrier is the exponential of a real logarithmic expansion;
     its only sign is the separately proved sign of the coefficient. *)
  magnitude = sign prefactor;
  frontier = If[omitted === {}, If[result["Remainder"] === 0, 0, Missing["Unknown"]],
    prefactor seriesJetExpression[{{First[omitted]}, Infinity, 0}, data["ScaleVariable"], data["LogVariable"]]];
  GeneralizedSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "Remainder" -> If[result["Remainder"] === 0, 0,
      magnitude PowerLogRemainder[data["ScaleVariable"], result["RemainderPower"], result["RemainderLogDegree"]]],
    "RemainderScaleExpression" -> If[result["Remainder"] === 0, 0,
      magnitude data["ScaleVariable"]^result["RemainderPower"]
        (1 + Abs[Log[data["ScaleVariable"]]])^result["RemainderLogDegree"]],
    "FrontierTerm" -> frontier, "RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[result["Terms"]], "LogarithmicExpansion" -> logarithmic,
    "ExactModel" -> TrueQ[result["Exact"]], "ExpansionNature" -> "Poincare",
    "LogarithmicFunction" -> logFunction|>, metadata]]];
(* END SOURCE: src/Kernel/GammaForward.wl *)

(* BEGIN SOURCE: src/Kernel/BarnesForward.wl
   Source SHA256 (UTF-8/LF): 036ec4a1255e77b866e52d07994535f1a8d7283a4ad3a5e024f6d9e6301aa479 *)
(* Positive-real Barnes G products use the same logarithmic carrier calculus
   as Gamma products. barnesLog is an exact internal logarithm, not a finite
   asymptotic surrogate. Its parser always attaches the Bernoulli tail.
   https://dlmf.nist.gov/5.17.E5 *)

(* Canonicalize bounded integer shifts before any finite tails are formed.
   Choosing the shift +1 also preserves the even correction lattice of G(x+1).
   Every intermediate Gamma argument must lie on the positive real branch. *)
barnesLogShift[arg_, x_, ass_, coord_, limit_] := Module[
  {terms, constant, shift, base, arguments},
  terms = If[Head[Expand[arg]] === Plus, List @@ Expand[arg], {arg}];
  constant = Total[Select[terms, FreeQ[#, x] &]];
  If[! IntegerQ[constant], Return[barnesLog[arg], Module]];
  shift = constant - 1;
  If[shift === 0 || Abs[shift] > Min[32, limit], Return[barnesLog[arg], Module]];
  base = Expand[arg - shift];
  arguments = If[shift > 0, Table[base + j, {j, 0, shift - 1}],
    Table[base - j, {j, 1, -shift}]];
  If[! AllTrue[arguments, inverseFunctionEventually[(# /. x -> coord["Substitution"]) > 0,
      coord["u"], ass] &], Return[barnesLog[arg], Module]];
  barnesLog[base] + Sign[shift] Total[LogGamma /@ arguments]];

(* Common offsets may be fractional or symbolic. Their difference, rather
   than either constant part separately, determines an exact recurrence. *)
barnesLogReduce[e_, x_, ass_, coord_, limit_] := Module[
  {atoms, bases = {}, rules = {}, domains = {}, replacement, shift, arguments, base},
  atoms = DeleteDuplicates[Cases[e, _barnesLog, {0, Infinity}]];
  Do[
    replacement = atom;
    Do[
      shift = Simplify[atom[[1]] - base, ass];
      If[! IntegerQ[shift] || Abs[shift] > Min[32, limit], Continue[]];
      arguments = If[shift >= 0, Table[base + j, {j, 0, shift - 1}],
        Table[base - j, {j, 1, -shift}]];
      If[! AllTrue[Prepend[arguments, base],
          inverseFunctionEventually[(# /. x -> coord["Substitution"]) > 0, coord["u"], ass] &], Continue[]];
      replacement = barnesLog[base] + Sign[shift] Total[LogGamma /@ arguments];
      AppendTo[domains, And @@ (# > 0 & /@ Prepend[arguments, base])];
      Break[], {base, bases}];
    If[replacement === atom, AppendTo[bases, atom[[1]]], AppendTo[rules, atom -> replacement]],
    {atom, atoms}];
  <|"Expression" -> (e /. rules), "Domain" -> And @@ domains|>];

barnesLogDomain[e_] := And @@ (First[#] > 0 & /@
  DeleteDuplicates[Cases[e, _barnesLog | _LogGamma, {0, Infinity}]]);

barnesProductLogSource[f_, x_, ass_, coord_, limit_, requireGrowth_] := Module[
  {lowered, source, factors, domain, logFunction, simplified, reduced},
  If[FreeQ[f, _BarnesG], Return[$Failed, Module]];
  validateInput[f, limit];
  lowered = gammaRelatedExpression[f];
  source = positiveSpecialProductSource[lowered, x, _Gamma | _BarnesG, ass, coord, requireGrowth,
    {"UnsupportedBarnesPower", "Barnes G products require exact exponents that are eventually real."}];
  If[source === $Failed, Return[$Failed, Module]];
  factors = source["Factors"]; domain = source["Domain"];
  logFunction = Total[#[[2]] If[Head[#[[1]]] === BarnesG,
      barnesLogShift[#[[1, 1]], x, ass, coord, limit], LogGamma[#[[1, 1]]]] & /@ factors];
  domain = domain && barnesLogDomain[logFunction];
  reduced = barnesLogReduce[logFunction, x, ass, coord, limit];
  logFunction = reduced["Expression"]; domain = domain && reduced["Domain"];
  simplified = TimeConstrained[FullSimplify[logFunction, ass && domain], 3, logFunction];
  If[FreeQ[simplified, _Gamma | _BarnesG], logFunction = simplified];
  <|"Logarithm" -> logFunction + source["OrdinaryLogarithm"], "Sign" -> source["Sign"],
    "Domain" -> domain, "BarnesExpression" -> lowered,
    "BarnesFactors" -> ({#[[1, 1]], #[[2]]} & /@ Select[factors, Head[#[[1]]] === BarnesG &]),
    "GammaFactors" -> ({#[[1, 1]], #[[2]]} & /@ Select[factors, Head[#[[1]]] === Gamma &])|>];

barnesForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[{source},
  source = barnesProductLogSource[f, x, ass, coord, limit, True];
  If[source === $Failed, Return[$Failed, Module]];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit, <|
      "BarnesFactors" -> source["BarnesFactors"], "GammaFactors" -> source["GammaFactors"],
      "BarnesExpression" -> source["BarnesExpression"],
      "Transformation" -> "Positive Barnes G and Gamma factors are combined in the real logarithmic domain, using exact positive integer-shift recurrences before expansion.",
      "AsymptoticReference" -> "https://dlmf.nist.gov/5.17.E5"|>]];

barnesLogJet[arg_, u_, ell_, ass_, Kw_, limit_] := Module[
  {z = arg - 1, leading, rate, count, model, result},
  If[Kw === Infinity, fail["InfiniteSeries", "The Barnes logarithm requires a finite Poincare working order."]];
  If[! inverseFunctionEventually[z > 0, u, ass] ||
      inverseBranchTry[Limit[z, u -> 0, Direction -> "FromAbove", Assumptions -> ass]] =!= Infinity,
    Return[fwdSeries[LogBarnesG[arg], u, ell, ass, Kw, limit], Module]];
  leading = fwd[z, u, ell, ass, Max[1, Kw], limit][[1]];
  If[leading === {} || ! less[leading[[1, 1]], 0] || ! FreeQ[leading[[1, 2]], ell],
    fail["UnsupportedBarnesArgument", "The growing Barnes argument must have a pure-power leading block."]];
  rate = -leading[[1, 1]];
  count = Max[0, Ceiling[Kw/(2 rate)] - 1];
  If[count + 1 > limit, fail["ResourceLimit", "The Barnes Bernoulli tail exceeds MaxTerms."]];
  model = (z^2/2 - 1/12) Log[z] - 3 z^2/4 + z Log[2 Pi]/2 + 1/12 - Log[Glaisher] +
    Sum[BernoulliB[2 k + 2]/(2 k (2 k + 2) z^(2 k)), {k, 1, count}];
  result = fwd[model, u, ell, ass, Kw, limit];
  pAdd[result, {{}, 2 (count + 1) rate, 0}, ell, ass]];
(* END SOURCE: src/Kernel/BarnesForward.wl *)

(* BEGIN SOURCE: src/Kernel/GammaInverse.wl
   Source SHA256 (UTF-8/LF): 646aa421554e971c09a4c51ad47b3e873e94aecf26042796937c74921b26a729 *)
(* Ordered inverse-Gamma corrections around an exact Lambert core.
   The coefficients are polynomials in q=1/Log[X], retained whole at each
   power of t=1/X. Stirling is used only to a finite, justified order. *)

gammaInverseModel[f_, x_, ass_] := Module[
  {parts, offset, dependent, factors, constant, variable, factor, family, power = 1,
   argument, slope, shift, barnes, logarithmic},
  If[FreeQ[f, _Gamma | _LogGamma | _BarnesG | _LogBarnesG], Return[$Failed, Module]];
  parts = If[Head[f] === Plus, List @@ f, {f}];
  offset = Total[Select[parts, FreeQ[#, x] &]];
  dependent = Select[parts, ! FreeQ[#, x] &];
  If[Length[dependent] =!= 1, Return[$Failed, Module]];
  factors = If[Head[First[dependent]] === Times, List @@ First[dependent], dependent];
  constant = Times @@ Select[factors, FreeQ[#, x] &];
  variable = Select[factors, ! FreeQ[#, x] &];
  If[Length[variable] =!= 1, Return[$Failed, Module]];
  factor = First[variable];
  If[MatchQ[factor, Power[_Gamma | _BarnesG, p_] /; FreeQ[p, x]],
    power = factor[[2]]; factor = factor[[1]]];
  If[! MatchQ[factor, Gamma[_] | LogGamma[_] | BarnesG[_] | LogBarnesG[_] | Log[BarnesG[_]]], Return[$Failed, Module]];
  barnes = MatchQ[factor, BarnesG[_] | LogBarnesG[_] | Log[BarnesG[_]]];
  logarithmic = MemberQ[{Log, LogGamma, LogBarnesG}, Head[factor]];
  family = If[barnes, If[logarithmic, "LogBarnesG", "BarnesG"],
    If[logarithmic, "LogGamma", "Gamma"]];
  argument = If[Head[factor] === Log, factor[[1, 1]], First[factor]];
  If[! PolynomialQ[argument, x] || Exponent[argument, x] =!= 1, Return[$Failed, Module]];
  slope = Coefficient[argument, x]; shift = argument /. x -> 0;
  If[! And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ {offset, shift}) ||
     ! (provablyPositive[constant, ass] || provablyNegative[constant, ass]) ||
     ! (provablyPositive[slope, ass] || provablyNegative[slope, ass]) ||
     ! (provablyPositive[power, ass] || provablyNegative[power, ass]),
    fail["UnprovedGammaInverseParameters", "Gamma/Barnes inverse affine parameters must be real, with proved nonzero source/target scales and a fixed nonzero real forward-function power."]];
  <|"Family" -> family, "Argument" -> argument, "SourceScale" -> slope,
    "SourceOffset" -> shift, "TargetScale" -> constant, "TargetOffset" -> offset,
    "IsBarnes" -> barnes, "Logarithmic" -> logarithmic,
    "CoreArgumentOffset" -> If[barnes, 1, 0], "SourceThreshold" -> If[barnes, 3, 2],
    "InverseScale" -> If[barnes, "BarnesGInverse", "GammaInverse"],
    "GammaPower" -> power|>];

gammaInverseUnit[n_Integer, t_, q_, limit_] := Module[
  {unit = 0, phase, coefficient, k, j, c = Log[2 Pi]},
  Do[
    phase = unit + q ((1 + unit) Log[1 + unit] - unit) - t/2 + c t q/2
      - t q Log[1 + unit]/2
      + Sum[BernoulliB[2 k] q t^(2 k) (1 + unit)^(-(2 k - 1))/(2 k (2 k - 1)),
          {k, 1, Floor[j/2]}];
    coefficient = Expand[-Coefficient[Normal[Series[phase, {t, 0, j}]], t, j]];
    unit += coefficient t^j;
    If[LeafCount[unit] > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G coefficient expansion exceeds MaxTerms."]],
    {j, 1, n}];
  unit];

gammaInverseRows[n_, r_, slope_, shift_, t_, q_, ass_, limit_, barnes_: False] := Module[{unit, observable, rows},
  unit = If[barnes, barnesInverseUnit[n, t, q, limit], gammaInverseUnit[n, t, q, limit]];
  observable = Normal[Series[(1 + unit + (If[barnes, 1, 0] - shift) t)^r, {t, 0, n}]];
  rows = Table[{canon[j - r], Expand[Coefficient[observable, t, j]/slope^r]}, {j, 0, n}];
  rows = Select[rows, ! TrueQ[FullSimplify[#[[2]] == 0, ass]] &];
  If[LeafCount[rows] > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G observable exceeds MaxTerms."]];
  rows];

gammaInverseBound[frontier_, core_, q_, ass_, coefficientLog_: Automatic] := Module[{poly, degree, log},
  poly = Expand[frontier[[2]]];
  degree = Min[First /@ (First /@ CoefficientRules[poly, q])];
  log = If[coefficientLog === Automatic, Log[core], coefficientLog];
  <|"RemainderPower" -> frontier[[1]], "RemainderLogDegree" -> 0,
    "RemainderInverseLogPower" -> degree, "RemainderVariable" -> 1/core,
    "Remainder" -> PowerLogRemainder[1/core, frontier[[1]], 0]/log^degree,
    "RemainderScaleExpression" -> core^(-frontier[[1]])/log^degree|>];

gammaInverseConstruct[f_, x_, x0_, y_, cutoff_, opts : OptionsPattern[AsymptoticInverse]] := Module[
  {ass = optionAssumptions[AsymptoticInverse, {opts}],
   dir = OptionValue[AsymptoticInverse, {opts}, Direction],
   goal = OptionValue[AsymptoticInverse, {opts}, SeriesTermGoal],
   limit = OptionValue[AsymptoticInverse, {opts}, "MaxTerms"],
   r = OptionValue[AsymptoticInverse, {opts}, "Power"],
   method = OptionValue[AsymptoticInverse, {opts}, Method],
   input = OptionValue[AsymptoticInverse, {opts}, "InputRemainder"],
   truncation = OptionValue[AsymptoticInverse, {opts}, "Truncation"],
   model, coord, target, core, q = Unique["inverseLog$"], t = Unique["inversePower$"],
   n, rows, retained, frontier, requested = cutoff, bound, expression, sourceSign, targetLimit,
   barnes, scale, coefficientLog, modelTerms, contract},
  model = gammaInverseModel[f, x, ass];
  If[model === $Failed, Return[$Failed, Module]];
  barnes = model["IsBarnes"]; scale = model["InverseScale"];
  sourceSign = If[provablyPositive[model["SourceScale"], ass], 1, -1];
  If[x0 =!= sourceSign Infinity, Return[$Failed, Module]];
  validateInput[f, limit];
  If[x === y || ! FreeQ[f, y] || ! FreeQ[ass, x | y],
    fail["InvalidVariables", "Use distinct source and target variables, a target-free forward expression, and parameter-only assumptions."]];
  coord = localCoordinate[x, x0, dir];
  If[! exactRealQ[r] || r === 0 || (sourceSign === -1 && ! IntegerQ[r]),
    fail["InvalidPower", "The inverse observable needs a nonzero exact real power; a negative source branch requires an integer power."]];
  If[! MemberQ[{"Lagrange", "Newton", "GroupedLagrange"}, method],
    fail["UnsupportedMethod", "These inverse families use ordered reversion of their logarithmic asymptotic model; the requested method is not supported."]];
  If[! MemberQ[{Automatic, None}, input],
    fail["UnsupportedInputRemainder", "A declared additive error must first be transported to the logarithmic Gamma or Barnes equation."]];
  If[truncation =!= "Exponent", fail["UnsupportedTruncation", "These inverse families use an exclusive core-power cutoff."]];
  If[cutoff === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a core-power cutoff or a positive integer SeriesTermGoal."]]; n = goal,
    If[! exactRealQ[cutoff] || ! less[-r, cutoff], fail["InvalidCutoff", "The core-power cutoff must exceed the leading exponent -Power."]];
    n = Ceiling[cutoff + r]];
  If[! IntegerQ[n] || n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G order exceeds MaxTerms."]];
  rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes];
  If[cutoff === Automatic,
    While[Length[rows] < goal + 1,
      n++; If[n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G nonzero-block search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes]];
    retained = Take[rows, goal]; frontier = rows[[goal + 1]]; requested = frontier[[1]],
    retained = Select[rows, less[#[[1]], cutoff] &];
    While[Select[rows, ! less[#[[1]], cutoff] &] === {},
      n++; If[n > limit, fail["ResourceLimit", "The inverse Gamma/Barnes G frontier search exceeds MaxTerms."]];
      rows = gammaInverseRows[n, r, model["SourceScale"], model["SourceOffset"], t, q, ass, limit, barnes]];
    frontier = First[Select[rows, ! less[#[[1]], cutoff] &]]];
  target = If[! model["Logarithmic"],
    Log[(y - model["TargetOffset"])/model["TargetScale"]]/model["GammaPower"],
    (y - model["TargetOffset"])/model["TargetScale"]];
  core = If[barnes, Sqrt[4 target/ProductLog[4 target/E^3]], target/ProductLog[target/E]];
  coefficientLog = Log[core] - If[barnes, 1, 0];
  expression = Total[(core^(-#[[1]]) (#[[2]] /. q -> 1/coefficientLog)) & /@ retained];
  bound = gammaInverseBound[frontier, core, q, ass, coefficientLog];
  targetLimit = If[! model["Logarithmic"] && provablyNegative[model["GammaPower"], ass],
    model["TargetOffset"], If[provablyPositive[model["TargetScale"], ass], Infinity, -Infinity]];
  modelTerms = If[barnes, Max[0, Floor[(n - 2)/2]], Floor[n/2]];
  contract = If[barnes, <|"Type" -> "FiniteBarnesPoincare", "ConvergentForwardSeries" -> False,
      "LogBarnesRemainderPower" -> 2 modelTerms + 2, "Reference" -> "https://dlmf.nist.gov/5.17.E5"|>,
    <|"Type" -> "FiniteStirlingPoincare", "ConvergentForwardSeries" -> False,
      "LogGammaRemainderPower" -> 2 modelTerms + 1, "Reference" -> "https://dlmf.nist.gov/5.11.ii"|>];
  GeneralizedSeries[Join[<|"Kind" -> scale, "Scale" -> scale,
    "Expression" -> expression, "Terms" -> retained, "Blocks" -> retained,
    "CoreInverse" -> core, "CoreLogExpression" -> coefficientLog,
    "CoreArgumentOffset" -> model["CoreArgumentOffset"],
    "RootSeedExpression" -> (core + model["CoreArgumentOffset"] - model["SourceOffset"])/model["SourceScale"],
    "CoefficientVariable" -> q, "CoefficientSubstitution" -> {q -> 1/coefficientLog},
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. q -> 1/coefficientLog),
    "Function" -> f, "Variables" -> {x, y}, "Variable" -> y, "SourceVariable" -> x,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"], "Limit" -> targetLimit,
    "Assumptions" -> ass, "SourceDomain" -> model["Argument"] > model["SourceThreshold"],
    (* Express the logarithmic target condition using real inequalities
       before evaluating a logarithm, including on invalid target values. *)
    "TargetDomain" -> ass && If[! model["Logarithmic"],
      If[provablyPositive[model["GammaPower"], ass],
        (y - model["TargetOffset"])/model["TargetScale"] > 1,
        0 < (y - model["TargetOffset"])/model["TargetScale"] < 1], target > 0],
    "TargetCoordinateExpression" -> target,
    "ExactTransformedFunction" -> If[barnes, LogBarnesG[model["Argument"]], LogGamma[model["Argument"]]],
    "SourceScale" -> model["SourceScale"], "SourceOffset" -> model["SourceOffset"],
    "TargetScale" -> model["TargetScale"], "TargetOffset" -> model["TargetOffset"],
    "Power" -> r, "Method" -> If[barnes, "OrderedBarnesReversion", "OrderedStirlingReversion"], "RequestedMethod" -> method,
    "Cutoff" -> requested, "RequestedCutoff" -> cutoff, "Truncation" -> "Exponent",
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Length[retained],
    "ModelTerms" -> modelTerms, "Exact" -> False, "ExactModel" -> False,
    "DeclaredInputRemainder" -> input,
    "ForwardRemainderContract" -> contract,
    "SeriesData" -> Missing["PolynomialInverseLogCoefficients"],
    "TermConvention" -> "Complete polynomials in 1/CoreLogExpression at each power of 1/CoreInverse. The cutoff is exclusive in that coordinate; SeriesTermGoal counts nonzero complete blocks.",
    "RemainderExplanation" -> "Finite logarithmic asymptotic errors, a uniform finite-model implicit-function argument, and a derivative lower bound justify the first omitted core-power block. This is a Poincare expansion, not a convergence or pointwise certificate."|>,
    If[barnes, <|"BarnesFamily" -> model["Family"], "BarnesPower" -> model["GammaPower"]|>,
      <|"GammaFamily" -> model["Family"], "GammaPower" -> model["GammaPower"]|>], bound]]];

gammaInverseTruncate[s : GeneralizedSeries[a_Association], h_, limit_] := Module[{kept, omitted, frontier, q, core, bound},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  validateInput[{a["Terms"], h}, limit];
  If[! exactRealQ[h], fail["InvalidCutoff", "The core-power cutoff must be an exact real number."]];
  kept = Select[a["Terms"], less[#[[1]], h] &];
  omitted = Select[a["Terms"], ! less[#[[1]], h] &];
  If[omitted === {}, Return[s, Module]];
  frontier = First[omitted]; q = a["CoefficientVariable"]; core = a["CoreInverse"];
  bound = gammaInverseBound[frontier, core, q, a["Assumptions"], a["CoreLogExpression"]];
  GeneralizedSeries[Join[a, <|"Terms" -> kept, "Blocks" -> kept, "Cutoff" -> h,
    "Expression" -> Total[(core^(-#[[1]]) (#[[2]] /. a["CoefficientSubstitution"])) & /@ kept],
    "CoefficientFrontier" -> frontier,
    "FrontierTerm" -> core^(-frontier[[1]]) (frontier[[2]] /. a["CoefficientSubstitution"]),
    "ReturnedTermCount" -> Length[kept]|>, bound]]];
(* END SOURCE: src/Kernel/GammaInverse.wl *)

(* BEGIN SOURCE: src/Kernel/BarnesInverse.wl
   Source SHA256 (UTF-8/LF): 56b824260f4c7165576a305082c5682d5347445256c0eb73d080993bb9059500 *)
(* Reversion about H(X)=X^2 (Log[X]-3/2)/2, with the Barnes argument
   equal to 1+X(1+U). q=1/(Log[X]-1) normalizes H'(X)=X/q.
   Each finite coefficient is polynomial in q. The Bernoulli model is
   used only to its stated Poincare order, never as an exact equation. *)

barnesInverseUnit[n_Integer, t_, q_, limit_] := Module[
  {unit = 0, phase, coefficient, j, k},
  Do[
    phase = unit + unit^2/2 + q ((1 + unit)^2 Log[1 + unit] - unit - unit^2/2)/2 +
      Log[2 Pi] q t (1 + unit)/2 - t^2 (1/12 + Log[Glaisher] q) -
      q t^2 Log[1 + unit]/12 +
      q Sum[BernoulliB[2 k + 2] t^(2 k + 2) (1 + unit)^(-2 k)/(2 k (2 k + 2)),
        {k, 1, Max[0, Floor[(j - 2)/2]]}];
    coefficient = Expand[-Coefficient[Normal[Series[phase, {t, 0, j}]], t, j]];
    unit += coefficient t^j;
    If[LeafCount[unit] > limit,
      fail["ResourceLimit", "The inverse-Barnes coefficient expansion exceeds MaxTerms."]],
    {j, 1, n}];
  unit];

(* On v>3, put z=v-1>2. The digamma midpoint bound
     psi(z+1)>Log[z+1/2]
   gives (Log G)'(v)>z(Log[z+1/2]-1)+(Log[2 Pi]-1)/2>1/9.
   The last expression increases for z>=2. Elementary logarithm bounds
   Log[5/2]>8/9 and Log[2 Pi]>5/3 prove its lower bound at z=2.
   See the article's Barnes inverse section and DLMF 5.17.4.
   Automatic selection requires a condition contained in this branch;
   explicit endpoint selection validates the retained source tail. *)
barnesInverseBranch[data_, target_, targetSide_, ass_, limit_, selection_] := Module[
  {body, x, condition, model, implication, sourceSign, point, coord, expected,
   side, derivativeSign, selectionDirection, radius, boundary, domain, proof},
  {body, x, condition} = Lookup[data, {"Body", "SourceVariable", "Condition"}];
  If[FreeQ[body, _BarnesG | _LogBarnesG], Return[$Failed, Module]];
  model = gammaInverseModel[body, x, ass];
  If[model === $Failed || ! TrueQ[model["IsBarnes"]], Return[$Failed, Module]];
  implication = inverseBranchTry[FullSimplify[Implies[condition, model["Argument"] > 3],
    ass && Element[x, Reals]]];
  If[! TrueQ[implication],
    implication = inverseBranchTry[Reduce[ass && condition && model["Argument"] <= 3, x, Reals]] === False];
  If[selection === Automatic && ! TrueQ[implication], Return[$Failed, Module]];
  sourceSign = If[provablyPositive[model["SourceScale"], ass], 1, -1];
  point = sourceSign Infinity; coord = localCoordinate[x, point, Automatic];
  If[! inverseFunctionEventually[(condition && model["Argument"] > 3) /. x -> coord["Substitution"], coord["u"], ass],
    Return[$Failed, Module]];
  side = If[provablyPositive[model["TargetScale"], ass], 1, -1];
  expected = If[! model["Logarithmic"] && provablyNegative[model["GammaPower"], ass],
    model["TargetOffset"], side Infinity];
  If[! TrueQ[inverseBranchTry[FullSimplify[target == expected, ass]]] ||
      (! MemberQ[{Infinity, -Infinity}, expected] && targetSide =!= side), Return[$Failed, Module]];
  If[selection =!= Automatic,
    If[! AssociationQ[selection] || ! KeyExistsQ[selection, "SourcePoint"] ||
        Complement[Keys[selection], {"SourcePoint", "Direction"}] =!= {},
      fail["InvalidInverseBranchSelection", "Use an association with SourcePoint and optional Direction."]];
    selectionDirection = Lookup[selection, "Direction", Automatic] /. {-1 -> "FromAbove", 1 -> "FromBelow"};
    If[! MemberQ[{Automatic, "FromAbove", "FromBelow"}, selectionDirection],
      fail["InvalidInverseBranchSelection", "Direction must be Automatic, FromAbove, FromBelow, -1 or 1."]];
    If[selection["SourcePoint"] =!= point || ! MemberQ[{Automatic, coord["Direction"]}, selectionDirection],
      fail["NoInverseFunctionBranch", "The selected endpoint or direction does not describe the increasing positive-argument Barnes branch."]]];
  domain = condition && model["Argument"] > 3;
  boundary = inverseBranchBoundaryData[domain, x, ass];
  radius = inverseBranchRadius[point, boundary["Points"]];
  (* The condition proof is eventual; record a fixed radius only when it
     has also been verified throughout that particular neighborhood. *)
  derivativeSign = sourceSign side If[provablyPositive[model["GammaPower"], ass], 1, -1];
  proof = <|"Type" -> "PositiveBarnesLogarithmicDerivative", "Sign" -> derivativeSign,
    "Domain" -> domain, "LogBarnesDerivativeLowerBound" -> 1/9,
    "Reference" -> "https://dlmf.nist.gov/5.17.E4",
    "Proof" -> "For Barnes argument v>3, the exact logarithmic derivative and the digamma midpoint inequality give d Log[G(v)]/dv>1/9. Positive G, fixed real powers, and proved affine scale signs preserve strict monotonicity on the retained domain."|>;
  <|"SourcePoint" -> point, "Direction" -> coord["Direction"], "SourceDomain" -> domain,
    "SourceCondition" -> condition, "TargetLimit" -> expected, "TargetSide" -> targetSide,
    "LocalSourceVariable" -> coord["u"], "LocalSubstitution" -> (x -> coord["Substitution"]),
    "DeletedNeighborhood" -> If[TrueQ[inverseBranchEventualQ[domain /. x -> coord["Substitution"],
        coord["u"], ass, radius]], 0 < coord["u"] < radius, Missing["UncomputedEventualRadius"]],
    "ConditionalDomainVerified" -> True, "LimitVerified" -> True,
    "TargetSideProof" -> <|"Type" -> "PositiveBarnesGrowthAndExactTargetTransformation", "Sign" -> side|>,
    "MonotonicityProof" -> proof, "GlobalMonotonicityProof" -> proof,
    "SelectionMethod" -> If[selection === Automatic, "ProvedPositiveBarnesBranch", "ExplicitEndpointAndValidatedLocalBranch"],
    "InferenceComplete" -> True, "ParameterAssumptions" -> ass,
    "OriginalCondition" -> condition, "RealFunctionDomain" -> model["Argument"] > 3,
    "RealFunctionDomainScope" -> If[selection === Automatic,
      "A proved sufficient real domain containing the entire retained source condition, not the maximal real domain of Barnes G.",
      "A proved sufficient real domain containing the explicitly selected source tail; the original condition is retained separately."],
    "OriginalInverseExpression" -> Lookup[data, "OriginalExpression", Missing["NotRecorded"]],
    "BranchProofScope" -> "Strict monotonicity on the positive Barnes branch and the verified source tail establish its unique inverse germ. No asymptotic validity threshold is claimed."|>];
(* END SOURCE: src/Kernel/BarnesInverse.wl *)

(* BEGIN SOURCE: src/Kernel/GammaInverseChecks.wl
   Source SHA256 (UTF-8/LF): 4a51a03be40b24a6d454d24ae5b717aacdc58a249bdf54974ab32c03a9050a8e *)
(* Checks for inverse Gamma expansions in powers of the retained Lambert
   core. Numerical comparisons use the original logarithmic equation.
   Formal residuals independently expand a finite Stirling model; they do
   not turn that Poincare model into an exact defining equation. *)

gammaInverseNumerical[a_Association, target_, wp_] := Module[
  {x, y, power, scale, offset, coordinate, equation, approximate, seed, root,
   observed, error, remainder, phaseResidual, rootResidual},
  If[! IntegerQ[wp] || wp < 10,
    fail["InvalidPrecision", "WorkingPrecision must be an integer of at least 10 digits."]];
  If[! NumericQ[target] || (! exactQ[target] && Precision[target] < wp),
    fail["InsufficientPrecision", "Supply an exact target or at least WorkingPrecision digits."]];
  {x, y} = a["Variables"]; power = a["Power"];
  scale = N[a["SourceScale"] /. y -> target, wp + 20];
  offset = N[a["SourceOffset"] /. y -> target, wp + 20];
  If[! And @@ (NumericQ /@ {scale, offset, power}),
    fail["UnresolvedParameters", "Substitute numerical values for the expansion's fixed parameters before numerical checking."]];
  If[! TrueQ[Quiet[Check[N[a["TargetDomain"] /. y -> target, wp + 20], False]]],
    fail["OutsideBranch", "The target does not satisfy the retained real inverse Gamma/Barnes G branch conditions."]];
  (* Substitute the exact target before numerical evaluation, preserving
     identities such as Log[Exp[v]] == v for a real exact v. *)
  coordinate = N[a["TargetCoordinateExpression"] /. y -> target, wp + 20];
  If[! NumericQ[coordinate] || ! TrueQ[Im[coordinate] == 0],
    fail["UnresolvedParameters", "The logarithmic target coordinate must have a real numerical value."]];
  If[Precision[coordinate] < wp,
    fail["InsufficientPrecision", "The transformed target lost precision through cancellation; supply a more precise or exact target."]];
  approximate = N[a["Expression"] /. y -> target, wp + 20];
  seed = N[Lookup[a, "RootSeedExpression", (a["CoreInverse"] - a["SourceOffset"])/a["SourceScale"]] /. y -> target, wp + 20];
  If[! And @@ (NumericQ /@ {approximate, seed}) ||
     ! TrueQ[Im[approximate] == 0 && Im[seed] == 0],
    fail["InvalidSeed", "The inverse Gamma/Barnes G expansion and retained core must give real numerical values."]];
  equation = a["ExactTransformedFunction"];
  root = With[{xx = x, ff = equation, rhs = coordinate, start = seed,
      precision = wp + 20, goal = wp},
    Quiet[Check[xx /. FindRoot[ff == rhs, {xx, start},
      WorkingPrecision -> precision, AccuracyGoal -> Infinity,
      PrecisionGoal -> goal, MaxIterations -> 500], $Failed]]];
  If[root === $Failed || ! NumericQ[root] || ! TrueQ[Im[root] == 0],
    fail["ReferenceRootNotFound", "The exact logarithmic Gamma/Barnes equation did not yield a real numerical reference."]];
  numericalSourceDomainCheck[a, root, target, wp];
  observed = N[root^power, wp + 20];
  If[! NumericQ[observed] || ! TrueQ[Im[observed] == 0],
    fail["OutsideBranch", "The requested power observable is not real at the recovered source root."]];
  remainder = N[a["RemainderScaleExpression"] /. y -> target, wp];
  If[! NumericQ[remainder] || ! TrueQ[Im[remainder] == 0 && remainder >= 0],
    fail["InvalidRemainderScale", "The stored absolute remainder scale must evaluate to a nonnegative real value."]];
  error = N[Abs[observed - approximate], wp];
  phaseResidual = N[(equation /. x -> seed) - coordinate, wp];
  rootResidual = N[(equation /. x -> root) - coordinate, wp];
  Join[<|"ReferenceRoot" -> N[root, wp], "ExactInverse" -> N[root, wp],
    "ReferenceObservable" -> N[observed, wp], "Approximation" -> N[approximate, wp],
    "RootSeed" -> N[seed, wp], "Error" -> error,
    "RemainderScale" -> remainder,
    "Ratio" -> If[TrueQ[remainder == 0], Indeterminate, error/remainder],
    "SourceDomainChecked" -> inverseEvidenceSourceDomain[a, x],
    "SourceDomainVerified" -> True, "SeedPhaseResidual" -> phaseResidual,
    "RootResidual" -> rootResidual, "Certified" -> False,
    "Scope" -> "The exact logarithmic " <> If[a["Kind"] === "BarnesGInverse", "Barnes G", "Gamma"] <> " equation on the retained real source branch.",
    "Evidence" -> "High-precision numerical comparison, not an interval certificate. ExactInverse is a legacy alias for ReferenceRoot."|>,
    If[power === 1, <|"ApproximationSourceRoot" -> N[approximate, wp],
      "PhaseResidual" -> N[(equation /. x -> approximate) - coordinate, wp]|>, <||>]]];

(* The two residuals share their input checks and coefficient bookkeeping.
   Their finite phase formulas below and in BarnesInverseChecks remain
   independent of the inverse constructors and their coefficient recurrences. *)
inverseCoreResidualSize[expression_, limit_, family_] := If[LeafCount[expression] > limit,
  fail["ResourceLimit", "An intermediate exact " <> family <> " residual expression exceeded MaxTerms."], expression];

inverseCoreResidualSetup[a_Association, h_, limit_, family_, argumentOffset_] := Module[
  {cut, order, t = Unique[ToLowerCase[family] <> "ResidualPower$"], q, ass, rows, source, unit},
  If[Lookup[a, "Power", 1] =!= 1,
    fail["UnsupportedObservable", If[family === "Gamma",
      "A Gamma/Barnes inverse residual currently requires the source-point observable Power -> 1; a finite powered approximation is not inverted to recover a source root.",
      "A Barnes-inverse residual requires the source-point observable Power -> 1."]]];
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  cut = If[h === Automatic, a["RemainderPower"] + 1, h];
  If[! exactRealQ[cut] || ! less[0, cut],
    fail["InvalidCutoff", "The normalized " <> family <> " residual cutoff must be a positive exact real number."]];
  order = Ceiling[cut] - 1;
  If[order + 2 > limit,
    fail["ResourceLimit", "The " <> If[family === "Gamma", "requested ", ""] <>
      "normalized " <> family <> " residual order exceeds MaxTerms."]];
  q = a["CoefficientVariable"]; ass = a["Assumptions"]; rows = a["Terms"];
  validateInput[rows, limit];
  If[! ListQ[rows] || ! And @@ (MatchQ[#, {_Integer, _}] && #[[1]] >= -1 & /@ rows),
    fail["UnsupportedResidualScale", "The source-point " <> family <>
      " residual requires integer powers of the reciprocal Lambert core."]];
  source = Total[(t^#[[1]] #[[2]]) & /@ rows];
  unit = inverseCoreResidualSize[FullSimplify[
    Expand[t (a["SourceScale"] source + a["SourceOffset"] - argumentOffset)], ass], limit, family];
  If[! PolynomialQ[unit, t] || ! TrueQ[FullSimplify[(unit /. t -> 0) == 1, ass]],
    fail["Invalid" <> family <> "InverseNormalization", If[family === "Gamma",
      "The retained source approximation must give a Gamma argument whose ratio to its Lambert core tends to one.",
      "The Barnes argument minus one must have ratio one to its Lambert core."]]];
  <|"Cutoff" -> cut, "Order" -> order, "PowerVariable" -> t, "CoefficientVariable" -> q,
    "Assumptions" -> ass, "Unit" -> unit, "Family" -> family, "MaxTerms" -> limit,
    "Logarithm" -> inverseCoreResidualSize[Normal[Series[Log[unit], {t, 0, order}]], limit, family]|>];

inverseCoreResidualReport[a_Association, data_, polynomial_, modelTerms_, modelPower_, normalizer_, tailLog_, metadata_] := Module[
  {t, q, ass, order, limit, family, coefficient, blocks, residual, x},
  {t, q, ass, order, limit, family} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Assumptions", "Order", "MaxTerms", "Family"}];
  blocks = Reap[Do[
    coefficient = inverseCoreResidualSize[FullSimplify[Coefficient[polynomial, t, n], ass], limit, family];
    If[! TrueQ[coefficient === 0], Sow[{n, coefficient}]], {n, 0, order}]][[2]];
  blocks = If[blocks === {}, {}, First[blocks]];
  residual = Total[(t^#[[1]] #[[2]]) & /@ blocks] /.
    Join[{t -> 1/a["CoreInverse"]}, a["CoefficientSubstitution"]];
  x = First[a["Variables"]];
  <|"ZeroBelowCutoff" -> (blocks === {}), "Residual" -> residual,
    "NormalizedResidual" -> residual, "ResidualBlocks" -> blocks,
    "Cutoff" -> data["Cutoff"], "RelativeCutoff" -> data["Cutoff"],
    "ScaleVariable" -> 1/a["CoreInverse"], "CoefficientVariable" -> q,
    "CoefficientSubstitution" -> a["CoefficientSubstitution"],
    "ExactEquationResidualExpression" -> ((a["ExactTransformedFunction"] /. x -> a["Expression"]) -
      a["TargetCoordinateExpression"])/normalizer,
    "Normalization" -> metadata["Normalization"],
    "ForwardModelTerms" -> modelTerms, "ModelRemainderPower" -> modelPower,
    "ModelRemainderScaleExpression" -> 1/(a["CoreInverse"]^modelPower tailLog),
    "ForwardRemainderContract" -> metadata["ForwardRemainderContract"],
    "ExactModel" -> False, "Scope" -> metadata["Scope"]|>];

gammaInverseResidual[a_Association, h_, limit_] := Module[
  {data, t, q, unit, logarithm, order, correction = 0, polynomial, modelTerms, checkSize},
  data = inverseCoreResidualSetup[a, h, limit, "Gamma", 0];
  {t, q, unit, logarithm, order} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Unit", "Logarithm", "Order"}];
  checkSize[expression_] := inverseCoreResidualSize[expression, limit, "Gamma"];
  modelTerms = Floor[order/2];
  Do[
    correction = checkSize[Expand[correction +
      BernoulliB[2 k] t^(2 k)/(2 k (2 k - 1))
        Normal[Series[unit^(1 - 2 k), {t, 0, order - 2 k}]]]],
    {k, 1, modelTerms}];
  (* With Gamma argument = unit/t and Log[t] = -1/q, this is
     q t (StirlingPhase - (1/t)(1/q - 1)). *)
  polynomial = checkSize[Expand[Normal[Series[
    (1 - q) (unit - 1) - t/2 + q (unit - t/2) logarithm +
      q t Log[2 Pi]/2 + q correction, {t, 0, order}]]]];
  inverseCoreResidualReport[a, data, polynomial, modelTerms, 2 modelTerms + 2,
    a["CoreInverse"] Log[a["CoreInverse"]], Log[a["CoreInverse"]],
    <|"Normalization" -> "(LogGamma[SourceScale source + SourceOffset] - targetCoordinate)/(CoreInverse Log[CoreInverse]).",
      "ForwardRemainderContract" -> <|"Type" -> "StirlingPoincareAtFixedOrder",
        "ConvergentForwardSeries" -> False, "Reference" -> "https://dlmf.nist.gov/5.11.ii"|>,
      "Scope" -> "Formal normalized residual of a finite Stirling model evaluated at the retained source approximation. ZeroBelowCutoff means cancellation only below the stated cutoff; it does not assert that the exact Gamma equation is solved identically. The first omitted Stirling term has the separately reported normalized remainder scale."|>]];
(* END SOURCE: src/Kernel/GammaInverseChecks.wl *)

(* BEGIN SOURCE: src/Kernel/BarnesInverseChecks.wl
   Source SHA256 (UTF-8/LF): 70de0268030051fefa1c9c323036488936a84fd309689c22abea51f179b0f6f0 *)
(* Independently evaluate the retained source in a finite Barnes phase.
   The normalization is X^2(Log[X]-1), so a source error at power P
   first appears at normalized residual power P+1. *)
barnesInverseResidual[a_Association, h_, limit_] := Module[
  {data, t, q, unit, logarithm, order, correction = 0, polynomial, modelTerms, checkSize},
  data = inverseCoreResidualSetup[a, h, limit, "Barnes", 1];
  {t, q, unit, logarithm, order} = Lookup[data,
    {"PowerVariable", "CoefficientVariable", "Unit", "Logarithm", "Order"}];
  checkSize[expression_] := inverseCoreResidualSize[expression, limit, "Barnes"];
  modelTerms = Max[0, Floor[(order - 2)/2]];
  Do[
    correction = checkSize[Expand[correction + BernoulliB[2 k + 2] t^(2 k + 2)/(2 k (2 k + 2))
      Normal[Series[unit^(-2 k), {t, 0, order - 2 k - 2}]]]], {k, 1, modelTerms}];
  polynomial = checkSize[Expand[Normal[Series[
    (1/2 - q/4) (unit^2 - 1) + q unit^2 logarithm/2 + Log[2 Pi] q t unit/2 -
      t^2 (1 + q)/12 - q t^2 logarithm/12 + (1/12 - Log[Glaisher]) q t^2 + q correction,
    {t, 0, order}]]]];
  inverseCoreResidualReport[a, data, polynomial, modelTerms, 2 modelTerms + 4,
    a["CoreInverse"]^2 a["CoreLogExpression"], a["CoreLogExpression"],
    <|"Normalization" -> "(LogBarnesG[SourceScale source+SourceOffset]-targetCoordinate)/(CoreInverse^2 CoreLogExpression).",
      "ForwardRemainderContract" -> <|"Type" -> "BarnesPoincareAtFixedOrder",
        "ConvergentForwardSeries" -> False, "Reference" -> "https://dlmf.nist.gov/5.17.E5"|>,
      "Scope" -> "Formal normalized residual of a finite Barnes model at the retained source approximation. ZeroBelowCutoff asserts cancellation only below the stated cutoff; the omitted Barnes tail is reported separately. This is not an exact identity or an interval certificate."|>]];
(* END SOURCE: src/Kernel/BarnesInverseChecks.wl *)

(* BEGIN SOURCE: src/Kernel/GammaInverseOperations.wl
   Source SHA256 (UTF-8/LF): c449679dd9b8686a15fb985c5e6304a492ed350bddbcedcd12b66af98e484062 *)
(* A power of an inverse-Gamma observable is another observable of the
   same source root. Replaying its exact defining equation determines the
   coefficients, while the operand's error still caps output precision. *)

gammaInverseSeriesPower[s : GeneralizedSeries[a_Association], k_, cut_, limit_] := Module[
  {x, y, ass, oldPower, newPower, alpha, precision, propagated, requested,
   effective, sourceDomain, targetDomain, result, data, inverseLogDegree,
   resultPower, resultDegree, core, bounded, operation, direction, representation, coefficientLog, kind},
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[! exactRealQ[k],
    fail["InvalidPower", "A Gamma/Barnes inverse series power must be an exact real number."]];
  If[cut =!= Automatic && ! exactRealQ[cut],
    fail["InvalidCutoff", "A Gamma/Barnes inverse operation cutoff must be an exact real number or Automatic."]];
  {x, y} = a["Variables"]; ass = a["Assumptions"]; kind = a["Kind"];
  oldPower = a["Power"]; targetDomain = a["TargetDomain"];
  If[! exactRealQ[oldPower] || oldPower === 0,
    fail["InvalidGammaInverseObservable", "The operand must retain a nonzero exact real source power."]];
  If[a["ExpansionPoint"] =!= Infinity && ! IntegerQ[k],
    fail["UnsupportedPowerBranch", "A noninteger power of a Gamma/Barnes inverse observable requires a positive source branch; powers on a negative source branch are supported only for integer exponents."]];
  If[k === 0,
    direction = Which[a["Limit"] === Infinity || a["Limit"] === -Infinity, Automatic,
      provablyPositive[a["TargetScale"], ass], "FromAbove", True, "FromBelow"];
    result = forwardCore[1, y, a["Limit"], 1, Assumptions -> ass,
      Direction -> direction, "MaxTerms" -> limit];
    If[FailureQ[result], Return[result, Module]];
    representation = seriesData[result, limit];
    Return[GeneralizedSeries[Join[result[[1]], <|"TargetDomain" -> targetDomain,
      "Function" -> ConditionalExpression[1, targetDomain],
      "SeriesRepresentation" -> Join[representation, <|"Domain" -> targetDomain && representation["Domain"]|>],
      (kind <> "Operation") -> <|"Operation" -> "Power", "Exponent" -> 0,
        "InputPower" -> oldPower, "OutputPower" -> 0,
        "PrecisionMeaning" -> "The constant observable is exact and independent of the operand remainder."|>|>]], Module]];
  If[! ListQ[a["Terms"]] || a["Terms"] === {},
    fail["UnknownLeadingTerm", "The Gamma/Barnes inverse operand must retain its leading source-power block before taking a nonzero power."]];
  alpha = First[a["Terms"]][[1]];
  If[! equal[alpha, -oldPower],
    fail["InvalidGammaInverseObservable", "The operand's leading core exponent must equal minus its retained source power."]];
  newPower = canon[oldPower k]; precision = a["RemainderPower"];
  If[! exactRealQ[precision] || ! less[alpha, precision],
    fail["InsufficientInputPrecision", "A Gamma/Barnes inverse power requires a remainder strictly smaller than the operand's leading block."]];
  propagated = canon[precision + alpha (k - 1)];
  requested = If[cut === Automatic, propagated, cut];
  effective = minOf[requested, propagated];
  If[! less[-newPower, effective],
    fail["InvalidCutoff", "The output core-power cutoff must exceed the powered observable's leading exponent."]];
  sourceDomain = inverseEvidenceSourceDomain[a, x];
  validateInput[{a["Function"], sourceDomain, newPower}, limit];
  result = With[{function = a["Function"], domain = sourceDomain, source = x,
      endpoint = a["ExpansionPoint"], target = y, cutoff = effective,
      power = newPower, assumptions = ass, direction = a["Direction"],
      method = Lookup[a, "RequestedMethod", "Lagrange"], budget = limit},
    AsymptoticInverse[ConditionalExpression[function, domain],
      {source, endpoint}, {target, cutoff}, "Power" -> power,
      Assumptions -> assumptions, Direction -> direction, Method -> method,
      "MaxTerms" -> budget]];
  If[FailureQ[result], Return[result, Module]];
  If[! MatchQ[result, GeneralizedSeries[_Association]] || result["Kind"] =!= kind,
    fail["UnsupportedGammaInverseReplay", "The retained source equation did not reconstruct a Gamma/Barnes inverse observable."]];
  data = result[[1]]; core = data["CoreInverse"]; coefficientLog = data["CoreLogExpression"];
  inverseLogDegree = Lookup[a, "RemainderInverseLogPower", 0];
  resultPower = data["RemainderPower"];
  resultDegree = Lookup[data, "RemainderInverseLogPower", 0];
  (* A cancelled first omitted coefficient in the reconstructed exact source
     cannot improve the uncertainty inherited from the operand. At equal
     core powers, a smaller reciprocal-log power is the coarser bound. *)
  bounded = If[less[propagated, resultPower] ||
      (equal[propagated, resultPower] && less[inverseLogDegree, resultDegree]),
    <|"RemainderPower" -> propagated, "RemainderLogDegree" -> 0,
      "RemainderInverseLogPower" -> inverseLogDegree,
      "RemainderVariable" -> 1/core,
      "Remainder" -> PowerLogRemainder[1/core, propagated, 0]/coefficientLog^inverseLogDegree,
      "RemainderScaleExpression" -> core^(-propagated)/coefficientLog^inverseLogDegree|>, <||>];
  operation = <|"Operation" -> "Power", "Exponent" -> k,
    "InputPower" -> oldPower, "OutputPower" -> newPower,
    "OperandRemainderPower" -> precision,
    "PropagatedRemainderPower" -> propagated,
    "RequestedCutoff" -> cut, "EffectiveCutoff" -> effective,
    "CoefficientConstruction" -> "Replay of the retained exact source equation with its original source-domain condition.",
    "PrecisionMeaning" -> "For operand valuation alpha and error power P, the output error power is capped by P+alpha(Exponent-1). Source replay supplies coefficients only below the clipped cutoff; it does not improve inherited uncertainty. Later refinement may replay the exact source for additional information."|>;
  GeneralizedSeries[Join[data, bounded, <|
    "TargetDomain" -> targetDomain && data["TargetDomain"],
    (kind <> "Operation") -> operation|>]]];
(* END SOURCE: src/Kernel/GammaInverseOperations.wl *)

(* BEGIN SOURCE: src/Kernel/ExponentialForward.wl
   Source SHA256 (UTF-8/LF): f92c050fc4cd3216a08fd7aafceef4202a8aad070f33402959434053195da345 *)
(* Normalize multiplicative elementary factors without asking Log to
   rediscover the exponent of Exp. A varying real power uses its positive
   base; ordinary factors retain a separately proved eventual sign. *)
logarithmicProductData[e_, x_] := Module[{parts},
  Which[
    FreeQ[e, x], {e, 0, True, {}},
    Head[e] === Times,
      parts = logarithmicProductData[#, x] & /@ List @@ e;
      {Times @@ parts[[All, 1]], Total[parts[[All, 2]]],
        And @@ parts[[All, 3]], Join @@ parts[[All, 4]]},
    MatchQ[e, Power[E, _]], {1, e[[2]], Element[e[[2]], Reals], {e[[2]]}},
    Head[e] === Power && (! FreeQ[e[[2]], x] || ! FreeQ[e[[1]], Power[E, _]]),
      {1, e[[2]] Log[e[[1]]], e[[1]] > 0 && Element[e[[2]], Reals], {e[[2]] Log[e[[1]]]}},
    True, {e, 0, True, {}}]];

logarithmicRealCondition[condition_, ass_, coord_] := Module[{simple, expression, parameters, domain},
  simple = FullSimplify[condition, ass && coord["u"] > 0];
  (* Keep inequalities describing a smaller real tail, but do not let
     quantifier elimination assume undeclared parameters are real. *)
  If[! FreeQ[simple, _Element],
    expression = condition[[1]];
    parameters = DeleteDuplicates[Cases[expression,
      z_ /; FreeQ[z, coord["u"]] && ! NumericQ[z], {0, Infinity}]];
    If[! AllTrue[parameters, TrueQ[FullSimplify[Element[#, Reals], ass]] &], Return[False, Module]];
    domain = Quiet[TimeConstrained[FunctionDomain[expression, coord["u"], Reals], 3, $Failed]];
    If[domain === $Failed || domain === False ||
      ! TrueQ[FullSimplify[condition, ass && coord["u"] > 0 && domain]], Return[False, Module]];
    simple = domain];
  inverseFunctionEventually[simple, coord["u"], ass]];

logarithmicProductSource[e_, x_, ass_, coord_, parsed_: Automatic] := Module[
  {parts = If[parsed === Automatic, logarithmicProductData[e, x], parsed], coefficient, sign, domain, condition, logarithm, simplified},
  coefficient = parts[[1]];
  condition = parts[[3]] /. x -> coord["Substitution"];
  (* Resolve[..., Reals] would silently treat free parameters as real.
     Discharge realness from explicit assumptions before that fallback. *)
  condition = condition /. HoldPattern[Element[z_, Reals]] :>
    logarithmicRealCondition[Element[z, Reals], ass, coord];
  If[! inverseFunctionEventually[condition, coord["u"], ass],
    fail["UnprovedLogarithmicDomain", "Exponential arguments must be real and varying powers need positive real bases."]];
  sign = Which[
    inverseFunctionEventually[(coefficient /. x -> coord["Substitution"]) > 0, coord["u"], ass], 1,
    inverseFunctionEventually[(coefficient /. x -> coord["Substitution"]) < 0, coord["u"], ass], -1,
    True, fail["UnprovedLogarithmicCoefficientSign", "The ordinary multiplicative factor must have an eventual real nonzero sign.",
      <|"Coefficient" -> coefficient|>]];
  domain = coord["LocalVariable"] > 0 && parts[[3]] && sign coefficient > 0;
  logarithm = parts[[2]] + FullSimplify[Log[sign coefficient], ass && domain];
  simplified = TimeConstrained[FullSimplify[logarithm, ass && domain], 3, logarithm];
  If[FreeQ[simplified, _Gamma], logarithm = simplified];
  <|"Sign" -> sign, "Domain" -> domain, "Logarithm" -> logarithm|>];

exponentialForwardExpansion[f_, x_, x0_, cutoff_, ass_, coord_, goal_, limit_] := Module[
  {parts, growing = False, localSource, sourceLimit, source},
  parts = logarithmicProductData[f, x];
  If[parts[[4]] === {}, Return[$Failed, Module]];
  validateInput[f, limit];
  Do[
    localSource = exponent /. x -> coord["Substitution"];
    sourceLimit = inverseBranchTry[Limit[localSource/Log[coord["u"]], coord["u"] -> 0,
      Direction -> "FromAbove", Assumptions -> ass]];
    If[MemberQ[{Infinity, -Infinity}, sourceLimit], growing = True], {exponent, parts[[4]]}];
  (* A merely logarithmic source represents an ordinary power-law factor.
     Require growth beyond Log[u] so regular Laurent/Puiseux germs keep
     their absolute cutoff convention, even when written using Exp. *)
  If[! growing, Return[$Failed, Module]];
  source = logarithmicProductSource[f, x, ass, coord, parts];
  logarithmicForwardExpansion[f, source["Logarithm"], source["Sign"], source["Domain"],
    x, x0, cutoff, ass, coord, goal, limit,
    <|"Transformation" -> "The expression equals Sign[coefficient] Exp[LogarithmicFunction] on the proved real domain."|>]];
(* END SOURCE: src/Kernel/ExponentialForward.wl *)

(* BEGIN SOURCE: src/Kernel/SeriesEnvelopeArithmetic.wl
   Source SHA256 (UTF-8/LF): 2cde86032fe867c7c59049e3f36c72f06ea25beb4f22aeb971f660651885a86a *)
(* Conservative arithmetic when no common ordered coefficient algebra applies.
   Each input denotes e + O(R), with R a nonnegative asymptotic envelope.
   Separate error summands are retained; cancellation of finite expressions
   does not cancel independent errors or create a single-scale precision. *)

SetAttributes[seriesEnvelopeTry, HoldAllComplete];
seriesEnvelopeTry[e_] := Quiet[TimeConstrained[e, 3, $Failed]];

seriesEnvelopeBudget[e_, limit_] := (
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[LeafCount[e] > limit,
    fail["ResourceLimit", "The composite expression and remainder exceed MaxTerms expression leaves."]]; e);

seriesEnvelopeOptions[cut_, limit_] := (
  If[! IntegerQ[limit] || limit < 1,
    fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic,
    fail["UnsupportedCompositeCutoff", "A composite expansion retains separate error scales; an exponent cutoff requires a compatible ordered series representation."]]);

seriesEnvelopeAssociation[a_, key_] := Replace[Lookup[a, key, <||>], Except[_Association] -> <||>];

seriesEnvelopeSmallCoordinates[a_] := DeleteDuplicates[DeleteCases[
  Join[{Lookup[a, "RemainderVariable", Missing["Absent"]],
    Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "ScaleVariable", Missing["Absent"]],
    Lookup[a, "CoreInverseCoordinate", Missing["Absent"]]},
    Cases[Lookup[a, "Remainder", 0], PowerLogRemainder[w_, _, _] :> w, {0, Infinity}]],
  _Missing]];

seriesEnvelopeSubstitution[approach_, u_] := Switch[approach["Point"],
  Infinity, 1/u, -Infinity, -1/u,
  _, approach["Point"] + If[approach["Direction"] === "FromAbove", u, -u]];

seriesEnvelopeTailQ[condition_, variable_, approach_, assumptions_] := Module[{u, local, ass, simple},
  u = Unique["envelopeTail$"];
  local = condition /. variable -> seriesEnvelopeSubstitution[approach, u];
  ass = assumptions /. variable -> seriesEnvelopeSubstitution[approach, u];
  simple = seriesEnvelopeTry[FullSimplify[local, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === False, Return[False, Module]];
  TrueQ[seriesEnvelopeTry[inverseFunctionEventually[local, u, ass]]]];

seriesEnvelopeLimit[e_, variable_, approach_, assumptions_, domain_: True] := Module[
  {u, substitution, simplified, direct, clauses, parameterAssumptions},
  simplified = seriesEnvelopeTry[Refine[e, assumptions && domain]];
  If[simplified === $Failed, simplified = e];
  clauses = If[Head[assumptions && domain] === And, List @@ (assumptions && domain), {assumptions && domain}];
  parameterAssumptions = And @@ Select[clauses, FreeQ[#, variable] &];
  (* Native limits of Lambert cores are substantially easier in the recorded
     target variable than after introducing a reciprocal of that variable.
     Limit ignores assumptions involving its variable; the recorded direction
     supplies that approach, while independent parameter conditions remain. *)
  direct = Quiet[TimeConstrained[Limit[simplified, variable -> approach["Point"],
    Direction -> If[MemberQ[{Infinity, -Infinity}, approach["Point"]], Automatic, approach["Direction"]],
    Assumptions -> parameterAssumptions], 10, $Failed]];
  If[direct =!= $Failed && FreeQ[direct, _Limit], Return[direct, Module]];
  u = Unique["envelopeLimit$"]; substitution = variable -> seriesEnvelopeSubstitution[approach, u];
  seriesEnvelopeTry[Limit[simplified /. substitution, u -> 0, Direction -> "FromAbove",
    Assumptions -> parameterAssumptions]]];

seriesEnvelopeApproach[a_, limit_] := Module[
  {stored, variable, point, direction = Automatic, ass, domain, coordinates, candidates,
   valid, coefficient, u, rule, endpoint, d},
  variable = Lookup[a, "Variable", Missing["Variable"]];
  If[! MatchQ[variable, _Symbol],
    fail["InvalidCompositeOperand", "A series operand must retain its target variable."]];
  stored = Lookup[a, "SeriesApproach", None];
  If[AssociationQ[stored] && Lookup[stored, "Variable", variable] === variable &&
      KeyExistsQ[stored, "Point"] && MemberQ[{"FromAbove", "FromBelow"}, Lookup[stored, "Direction", None]],
    Return[stored, Module]];
  ass = Lookup[a, "Assumptions", True];
  domain = Lookup[a, "TargetDomain", Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "Domain", True]];
  coordinates = Select[seriesEnvelopeSmallCoordinates[a], ! FreeQ[#, variable] &];
  point = Which[
    KeyExistsQ[a, "InverseFunctionExpansionPoint"],
      direction = Lookup[a, "InverseFunctionExpansionDirection", Automatic]; a["InverseFunctionExpansionPoint"],
    Lookup[a, "Kind", ""] === "Forward", direction = Lookup[a, "Direction", Automatic]; a["ExpansionPoint"],
    KeyExistsQ[a, "Limit"], a["Limit"],
    AssociationQ[Lookup[a, "FlatRepresentation", None]], a["FlatRepresentation"]["TargetOffset"],
    Lookup[a, "Kind", ""] === "FlatInverse" && AssociationQ[Lookup[a, "Model", None]], a["Model"]["Offset"],
    True, Missing["UnknownEndpoint"]];
  If[MissingQ[point],
    (* Invert only a recorded independent coordinate, never the represented
       unknown function. This also recognizes reciprocal-log derived charts. *)
    Do[
      u = Unique["envelopeCoordinate$"];
      d = <|"Variable" -> variable, "ScaleVariable" -> coordinate|>;
      rule = seriesCoordinateRule[d, u];
      If[rule === $Failed, Continue[]];
      endpoint = seriesEnvelopeTry[Limit[variable /. rule, u -> 0,
        Direction -> "FromAbove", Assumptions -> ass]];
      If[MemberQ[{Infinity, -Infinity}, endpoint], point = endpoint; Break[]];
      If[endpoint === $Failed || ! FreeQ[endpoint, u | _Limit] ||
          ! TrueQ[seriesEnvelopeTry[FullSimplify[Element[endpoint, Reals], ass]]], Continue[]];
      If[TrueQ[seriesEnvelopeTry[inverseFunctionEventually[(variable /. rule) > endpoint, u, ass]]],
        point = endpoint; direction = "FromAbove"; Break[]];
      If[TrueQ[seriesEnvelopeTry[inverseFunctionEventually[(variable /. rule) < endpoint, u, ass]]],
        point = endpoint; direction = "FromBelow"; Break[]], {coordinate, coordinates}]];
  If[MissingQ[point],
    fail["UnknownCompositeApproach", "The operand does not retain a recoverable target approach."]];
  If[MemberQ[{Infinity, -Infinity}, point],
    direction = If[point === Infinity, "FromBelow", "FromAbove"]];
  If[direction === Automatic,
    coefficient = Lookup[a, "TargetScale", Lookup[a, "LeadingCoefficient",
      Lookup[seriesEnvelopeAssociation[a, "FlatRepresentation"], "CoreCoefficient",
        Lookup[seriesEnvelopeAssociation[a, "Model"], "CoreCoefficient", Missing["Coefficient"]]]]];
    If[! MissingQ[coefficient],
      If[TrueQ[seriesEnvelopeTry[FullSimplify[coefficient > 0, ass]]], direction = "FromAbove"];
      If[TrueQ[seriesEnvelopeTry[FullSimplify[coefficient < 0, ass]]], direction = "FromBelow"]]];
  If[direction === Automatic,
    candidates = (<|"Variable" -> variable, "Point" -> point, "Direction" -> #|> &) /@
      {"FromAbove", "FromBelow"};
    valid = Select[candidates, Function[candidate,
      seriesEnvelopeTailQ[domain && And @@ (# > 0 & /@ coordinates), variable, candidate, ass] &&
        AllTrue[coordinates, seriesEnvelopeLimit[#, variable, candidate, ass, domain] === 0 &]]];
    If[Length[valid] =!= 1,
      fail["UnknownCompositeApproach", "The target side could not be recovered uniquely from the operand's domain and positive coordinates."]];
    direction = First[valid]["Direction"]];
  If[! MemberQ[{"FromAbove", "FromBelow"}, direction],
    fail["InvalidCompositeApproach", "The retained target approach is not a supported real one-sided approach."]];
  <|"Variable" -> variable, "Point" -> point, "Direction" -> direction|>];

(* Each summand is a nonnegative coefficient times a product of inert O terms.
   Multiplication combines only literally identical positive coordinates. *)
seriesEnvelopeErrorTerm[term_] := Module[{factors, errors, ordinary, groups},
  factors = If[Head[term] === Times, List @@ term, {term}];
  factors = factors /. HoldPattern[Power[PowerLogRemainder[w_, p_, k_], n_Integer?Positive]] :>
    PowerLogRemainder[w, n p, n k];
  errors = Select[factors, MatchQ[#, PowerLogRemainder[_, _, _]] &];
  ordinary = Select[factors, FreeQ[#, _PowerLogRemainder] &];
  If[Length[errors] + Length[ordinary] =!= Length[factors] || errors === {},
    fail["UnsupportedCompositeRemainder", "A nonzero remainder must be a sum of exact coefficients times inert power-log remainder factors."]];
  groups = GatherBy[errors, First];
  Abs[Times @@ ordinary] Times @@ (PowerLogRemainder[#[[1, 1]], Total[#[[All, 2]]],
      Total[#[[All, 3]]]] & /@ groups)];

seriesEnvelopeErrorExpansionSize[e_, limit_] := Module[{sizes, size, power},
  If[FreeQ[e, _PowerLogRemainder], Return[1, Module]];
  Which[Head[e] === Plus,
    Min[limit + 1, Total[seriesEnvelopeErrorExpansionSize[#, limit] & /@ List @@ e]],
    Head[e] === Times,
    sizes = seriesEnvelopeErrorExpansionSize[#, limit] & /@ List @@ e;
    Fold[Min[limit + 1, #1 #2] &, 1, sizes],
    Head[e] === Power && IntegerQ[e[[2]]] && e[[2]] > 0,
    size = seriesEnvelopeErrorExpansionSize[e[[1]], limit]; power = e[[2]];
    If[size <= 1, 1, If[power > IntegerLength[limit, 2], limit + 1, Min[limit + 1, size^power]]],
    True, 1]];

seriesEnvelopeErrorNormalize[remainder_, limit_] := Module[{expanded, terms},
  If[remainder === 0, Return[0, Module]];
  seriesEnvelopeBudget[remainder, limit];
  If[seriesEnvelopeErrorExpansionSize[remainder, limit] > limit,
    fail["ResourceLimit", "The composite remainder product exceeds MaxTerms distributed error summands."]];
  (* Treat ordinary coefficients as exact atoms. Only distribute factors
     containing the inert remainder head. *)
  expanded = seriesEnvelopeTry[Expand[remainder, _PowerLogRemainder]];
  If[expanded === $Failed,
    fail["ResourceLimit", "Normalizing the composite error product exceeded the symbolic time budget."]];
  seriesEnvelopeBudget[expanded, limit];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  Total[seriesEnvelopeErrorTerm /@ terms]];

seriesEnvelopeData[s : GeneralizedSeries[a_Association], limit_] := Module[{expression, remainder, bound, assumptions, domain, approach},
  requireAnalyticSeries[s];
  If[! KeyExistsQ[a, "Expression"] || ! KeyExistsQ[a, "Remainder"],
    fail["InvalidCompositeOperand", "A series operand must retain both its finite expression and its remainder."]];
  expression = a["Expression"]; remainder = a["Remainder"];
  validateInput[{expression, remainder}, limit];
  seriesEnvelopeBudget[{expression, remainder}, limit];
  If[! FreeQ[{expression, remainder}, _GeneralizedSeries],
    fail["InvalidCompositeOperand", "Normalize nested series operands before constructing a composite envelope."]];
  remainder = seriesEnvelopeErrorNormalize[remainder, limit];
  bound = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  assumptions = Lookup[a, "Assumptions", True];
  domain = Lookup[a, "TargetDomain", Lookup[seriesEnvelopeAssociation[a, "SeriesRepresentation"], "Domain", True]];
  If[seriesEnvelopeTry[FullSimplify[assumptions && domain]] === False,
    fail["IncompatibleDomains", "The series operand has a contradictory target domain."]];
  approach = seriesEnvelopeApproach[a, limit];
  <|"Expression" -> expression, "Remainder" -> remainder, "Bound" -> bound,
    "Variable" -> a["Variable"], "Assumptions" -> assumptions, "Domain" -> domain,
    "Approach" -> approach|>];

seriesEnvelopeMake[expression_, remainder0_, data_, recipe_, limit_] := Module[{remainder, bound, domain},
  remainder = seriesEnvelopeErrorNormalize[remainder0, limit];
  bound = remainder /. rr_PowerLogRemainder :> remainderScale[rr];
  domain = data["Domain"];
  validateInput[{expression, remainder, bound}, limit];
  seriesEnvelopeBudget[{expression, remainder, bound}, limit];
  GeneralizedSeries[<|"Kind" -> "Derived", "Scale" -> "Composite",
    "Expression" -> expression, "Remainder" -> remainder, "RemainderScaleExpression" -> bound,
    "Variable" -> data["Variable"], "Assumptions" -> data["Assumptions"],
    "TargetDomain" -> domain, "SeriesApproach" -> data["Approach"],
    "Exact" -> (remainder === 0), "RemainderDerivativeOrder" -> If[remainder === 0, Infinity, 0],
    "CompositeRecipe" -> recipe,
    "MajorantContract" -> <|"Type" -> "CompositeAsymptoticEnvelope", "NumericCertificate" -> False,
      "Statement" -> "For fixed data on the retained common target approach, the exact represented function differs from Expression by O(RemainderScaleExpression). Separate error summands are preserved; cancellation of finite expressions does not cancel unknown errors."|>,
    "TermConvention" -> "The finite expression is retained exactly and the remainder is a sum of envelopes in possibly different positive coordinates; no single exponent cutoff is asserted.",
    "SeriesData" -> Missing["CompositeErrorScales"]|>]];

seriesEnvelopeBinary[op_String, s_GeneralizedSeries, t_, cut_, limit_] := Module[
  {a, b, assumptions, domain, expression, remainder, exact = t, condition = True, compatible},
  seriesEnvelopeOptions[cut, limit];
  If[! MemberQ[{"Add", "Multiply"}, op],
    fail["UnsupportedCompositeOperation", "Composite binary arithmetic supports addition and multiplication."]];
  a = seriesEnvelopeData[s, limit];
  If[MatchQ[t, _GeneralizedSeries],
    b = If[s === t, a, seriesEnvelopeData[t, limit]];
    assumptions = a["Assumptions"] && b["Assumptions"];
    compatible = a["Variable"] === b["Variable"] &&
      a["Approach"]["Direction"] === b["Approach"]["Direction"] &&
      (a["Approach"]["Point"] === b["Approach"]["Point"] ||
       TrueQ[seriesEnvelopeTry[FullSimplify[a["Approach"]["Point"] == b["Approach"]["Point"], assumptions]]]);
    If[! TrueQ[compatible],
      fail["IncompatibleApproaches", "Composite arithmetic requires the same target variable, endpoint, and real approach side."]];
    domain = a["Domain"] && b["Domain"],
    If[! FreeQ[t, _GeneralizedSeries],
      fail["UnsupportedCompositeOperand", "Normalize nested series before combining them with another series."]];
    While[Head[exact] === ConditionalExpression, condition = condition && exact[[2]]; exact = exact[[1]]];
    validateInput[exact, limit]; seriesEnvelopeBudget[exact, limit];
    assumptions = a["Assumptions"]; domain = a["Domain"] && condition;
    If[! seriesEnvelopeTailQ[condition && Element[exact, Reals], a["Variable"], a["Approach"],
        assumptions && a["Domain"]],
      fail["UnprovedRealCoefficient", "The ordinary operand must be exact and eventually real on the series target approach."]];
    b = <|"Expression" -> exact, "Remainder" -> 0|>];
  (* seriesEnvelopeData already checked this exact predicate locally. New
     conditions still require the combined-domain check. *)
  If[(assumptions && domain) =!= (a["Assumptions"] && a["Domain"]) &&
      seriesEnvelopeTry[FullSimplify[assumptions && domain]] === False,
    fail["IncompatibleDomains", "The series operands have incompatible target domains."]];
  If[op === "Add",
    expression = a["Expression"] + b["Expression"];
    remainder = a["Remainder"] + b["Remainder"],
    expression = a["Expression"] b["Expression"];
    remainder = Abs[a["Expression"]] b["Remainder"] +
      Abs[b["Expression"]] a["Remainder"] + a["Remainder"] b["Remainder"]];
  seriesEnvelopeMake[expression, remainder,
    Join[a, <|"Assumptions" -> assumptions, "Domain" -> domain|>],
    <|"Operation" -> op, "Operands" -> {s, t}|>, limit]];

seriesEnvelopePower[s_GeneralizedSeries, r_, cut_, limit_] := Module[
  {a, expression, remainder, domain, nonzero, positive, relative, result},
  seriesEnvelopeOptions[cut, limit];
  If[! exactRealQ[r], fail["InvalidPower", "A composite series power must be an exact real number."]];
  If[r === 1, Return[s, Module]];
  a = seriesEnvelopeData[s, limit]; expression = a["Expression"]; domain = a["Domain"];
  (* Polynomial powers need no nonvanishing or relative-error hypothesis.
     This also admits positive integer powers of a pure remainder. *)
  If[IntegerQ[r] && r > 0,
    If[r > limit, fail["ResourceLimit", "The composite polynomial power exceeds MaxTerms."]];
    remainder = If[a["Remainder"] === 0, 0,
      Total[Table[Binomial[r, k] If[k === r, 1, Abs[expression]^(r - k)] a["Remainder"]^k, {k, 1, r}]]];
    Return[seriesEnvelopeMake[expression^r, remainder, a,
      <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r|>, limit], Module]];
  If[expression === 0,
    If[a["Remainder"] === 0 && TrueQ[r > 0],
      Return[seriesEnvelopeMake[0, 0, a,
        <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r|>, limit], Module]];
    fail["UnknownLeadingTerm", "This power requires a proved nonzero leading approximation; a pure remainder cannot supply it."]];
  nonzero = seriesEnvelopeTailQ[Element[expression, Reals] && expression != 0,
    a["Variable"], a["Approach"], a["Assumptions"] && domain];
  If[! nonzero,
    fail["UnprovedNonzeroBase", "The finite approximation must be eventually real and nonzero before this power can transport its error."]];
  positive = IntegerQ[r] || seriesEnvelopeTailQ[expression > 0,
    a["Variable"], a["Approach"], a["Assumptions"] && domain];
  If[! positive,
    fail["NonpositiveBase", "A noninteger composite power requires an eventually positive real approximation."]];
  relative = If[a["Remainder"] === 0, 0,
    seriesEnvelopeLimit[a["Bound"]/Abs[expression], a["Variable"], a["Approach"], a["Assumptions"], domain]];
  If[relative =!= 0,
    fail["InsufficientRelativePrecision", "This power requires a remainder proved smaller than the finite approximation on the retained target approach."]];
  domain = domain && If[IntegerQ[r], expression != 0, expression > 0];
  remainder = If[r === 0, 0, Abs[expression]^(r - 1) a["Remainder"]];
  result = If[r === 0, 1, expression^r];
  seriesEnvelopeMake[result, remainder, Join[a, <|"Domain" -> domain|>],
    <|"Operation" -> "Power", "Operands" -> {s}, "Exponent" -> r,
      "RelativeRemainderLimit" -> 0|>, limit]];

(* These bounds use only the stated scalar inequalities, not an unproved
   Taylor expansion of a multiscale remainder. Abs, Sin and Cos are globally
   1-Lipschitz on the real line. Log requires relative smallness, whereas
   Exp requires absolute smallness of the unknown perturbation. *)
seriesEnvelopeUnary[head_, s_GeneralizedSeries, cut_, limit_] := Module[
  {a, expression, domain, remainder, boundLimit, transport, evidence = <||>},
  seriesEnvelopeOptions[cut, limit];
  If[! MemberQ[{Log, Exp, Abs, Sin, Cos}, head],
    fail["UnsupportedCompositeObservable", "Composite unary bounds support Log, Exp, Abs, Sin and Cos on their proved real domains."]];
  a = seriesEnvelopeData[s, limit]; expression = a["Expression"]; domain = a["Domain"];
  If[head === Log,
    If[! seriesEnvelopeTailQ[expression > 0, a["Variable"], a["Approach"], a["Assumptions"] && domain],
      fail["NonpositiveBase", "A real logarithm of a composite expansion requires an eventually positive finite approximation."]],
    If[! seriesEnvelopeTailQ[Element[expression, Reals], a["Variable"], a["Approach"], a["Assumptions"] && domain],
      fail["UnprovedRealCoefficient", "This composite observable requires an eventually real finite approximation."]]];
  Switch[head,
    Log,
      domain = domain && expression > 0;
      boundLimit = If[a["Remainder"] === 0, 0,
        seriesEnvelopeLimit[a["Bound"]/expression, a["Variable"], a["Approach"], a["Assumptions"], domain]];
      If[boundLimit =!= 0,
        fail["InsufficientRelativePrecision", "Taking this logarithm requires a remainder proved smaller than the positive finite approximation."]];
      remainder = a["Remainder"]/Abs[expression];
      transport = "For a positive e and R/e tending to zero, Log[e+O(R)] = Log[e] + O(R/e).";
      evidence = <|"RelativeRemainderLimit" -> 0|>,
    Exp,
      boundLimit = If[a["Remainder"] === 0, 0,
        seriesEnvelopeLimit[a["Bound"], a["Variable"], a["Approach"], a["Assumptions"], domain]];
      If[boundLimit =!= 0,
        fail["InsufficientObservablePrecision", "Exponentiating a composite expansion requires an absolute remainder proved to tend to zero."]];
      remainder = Exp[expression] a["Remainder"];
      transport = "For real e and R tending to zero, Exp[e+O(R)] = Exp[e] + Exp[e] O(R).";
      evidence = <|"AbsoluteRemainderLimit" -> 0|>,
    Abs | Sin | Cos,
      remainder = a["Remainder"];
      transport = "The real scalar function is globally 1-Lipschitz, so its output error is O(R) without a smallness or nonvanishing hypothesis.";
      evidence = <|"LipschitzConstant" -> 1|>];
  seriesEnvelopeMake[head[expression], remainder, Join[a, <|"Domain" -> domain|>],
    Join[<|"Operation" -> "Unary", "FunctionHead" -> head, "Operands" -> {s},
      "ErrorTransport" -> transport|>, evidence], limit]];
(* END SOURCE: src/Kernel/SeriesEnvelopeArithmetic.wl *)

(* BEGIN SOURCE: src/Kernel/SeriesArithmetic.wl
   Source SHA256 (UTF-8/LF): 642401b840307a543801b5d121b26dac9c22e5daf1f756c74c840103625b73ef *)
(* Ordinary arithmetic is a thin, guarded entry to the precision calculus.
   The explicit normalizer holds the expression tree before evaluation so that
   a reciprocal is checked before Times can cancel its denominator. *)

AsymptoticAnalysis`SeriesNormalize::usage =
"SeriesNormalize[expr] merges arithmetic expressions containing GeneralizedSeries objects and regular functions, transporting all operand remainders. SeriesNormalize[expr, \"Cutoff\" -> h] truncates the normalized result at h without improving operand precision. The expression is held before automatic arithmetic. Compatible scales use ordered jets; other compatible approaches retain a composite error bound.";
Options[AsymptoticAnalysis`SeriesNormalize] = {"Cutoff" -> Automatic, "MaxTerms" -> 20000};
SetAttributes[AsymptoticAnalysis`SeriesNormalize, HoldAllComplete];
$seriesArithmeticEnabled = True;

seriesArithmeticObjectQ[GeneralizedSeries[a_Association]] :=
  KeyExistsQ[a, "Variable"] && KeyExistsQ[a, "Expression"] && KeyExistsQ[a, "Remainder"];
seriesArithmeticObjectQ[_] := False;
seriesArithmeticFlatQ[GeneralizedSeries[a_Association]] := Lookup[a, "Scale", ""] === "FiniteFlatSectors";
seriesArithmeticFlatQ[_] := False;
seriesArithmeticCompositeQ[GeneralizedSeries[a_Association]] := Lookup[a, "Scale", ""] === "Composite";
seriesArithmeticCompositeQ[_] := False;

seriesArithmeticFallbackQ[Failure[tag_, _]] := MemberQ[{
  "UnsupportedScale", "IncompatibleScales", "IncompatibleCarriers", "UnsupportedInput", "UnsupportedObservableCoefficient",
  "UnsupportedFlatCoefficient", "UnsupportedFlatSeries", "IncompatibleFlatScales", "LogarithmicLeadingPower", "ExponentialScale"}, tag];
seriesArithmeticFallbackQ[_] := False;

seriesArithmeticCheck[result_] := If[FailureQ[result], Throw[result, $tag], result];
seriesArithmeticOperationCheck[Failure["UnknownLeadingTerm", data_Association], s_GeneralizedSeries] :=
  Throw[Failure["UnknownLeadingTerm", Join[data, <|"OperandExpression" -> Normal[s],
    "OperandRemainderPower" -> Lookup[s[[1]], "RemainderPower", Missing["CompositePrecision"]]|>]], $tag];
seriesArithmeticOperationCheck[result_, _] := seriesArithmeticCheck[result];
seriesArithmeticFinish[result_List, cut_, limit_] := seriesArithmeticFinish[#, cut, limit] & /@ result;
seriesArithmeticFinish[result_, cut_, limit_] := If[cut === Automatic || ! MatchQ[result, _GeneralizedSeries], result,
  requireAnalyticSeries[result];
  If[seriesArithmeticCompositeQ[result], fail["UnsupportedCompositeCutoff", "A composite bound has no single exponent cutoff; truncate its operands in their own scales first."]];
  If[seriesArithmeticFlatQ[result], AsymptoticAnalysis`FlatSeriesTruncate[result, cut, "MaxTerms" -> limit],
    AsymptoticAnalysis`SeriesTruncate[result, cut, "MaxTerms" -> limit]]];
seriesArithmeticPublicBinary[op_, s_, t_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  seriesArithmeticFinish[seriesArithmeticBinary[op, s, t, Automatic, limit], cut, limit]]];
seriesArithmeticPublicPower[s_, r_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[Module[{result},
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  result = seriesArithmeticPower[s, r, cut, limit, True];
  If[seriesArithmeticFlatQ[result], seriesArithmeticFinish[result, cut, limit], result]]]];
seriesArithmeticPublicUnary[head_, s_, cut_, limit_] := Block[{$seriesArithmeticEnabled = False}, catch[
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  seriesArithmeticUnary[head, s, cut, limit]]];

(* Exact finite coefficients are never truncated before an operation. An
   infinite coefficient expansion is computed to the precision needed after
   multiplication, including the operand's leading valuation. *)
seriesRegularOperand[e_, s_GeneralizedSeries, op_, working_, limit_] := Module[
  {d = seriesData[s, limit], j, h, alpha, beta, needed, precision, attempts = 0, ass, ell},
  validateInput[e, limit]; ass = seriesAss[d]; ell = d["LogVariable"];
  j = seriesExpressionJet[e, d, limit];
  If[j === $Failed,
    h = Max[1, seriesWorkingCut[d, working]];
    j = seriesIndependentJet[e, d, h, limit];
    While[j[[1]] === {} && j[[2]] =!= Infinity && attempts < 8,
      attempts++; h = 2 h + 1; j = seriesIndependentJet[e, d, h, limit]];
    precision = d["Jet"][[2]];
    alpha = If[d["Jet"][[1]] === {}, precision, jetValuation[d["Jet"][[1]]]];
    beta = If[j[[1]] === {}, j[[2]], jetValuation[j[[1]]]];
    needed = If[precision === Infinity, h, precision];
    If[op === "Multiply" && alpha =!= Infinity && beta =!= Infinity,
      needed = needed + beta - alpha];
    If[working =!= Automatic, needed = Max[needed, working]];
    If[j[[2]] =!= Infinity && less[j[[2]], needed], j = seriesIndependentJet[e, d, needed, limit]]];
  If[! And @@ (corePerturbationRealPolynomialQ[#[[2]], ell, ass] & /@ j[[1]]),
    fail["UnprovedRealCoefficient", "The regular operand must have provably real coefficients on the series branch."]];
  seriesMake[Join[d, <|"Offset" -> 0, "Prefactor" -> 1, "Jet" -> j,
    "RemainderDerivativeOrder" -> If[j[[2]] === Infinity, Infinity, 0]|>],
    {"RegularOperand", {s}, e, op}]];

seriesArithmeticBinary[op_, s_GeneralizedSeries, t_, working_, limit_] := Module[{result, operand = t, data, z},
  If[FailureQ[t], Throw[t, $tag]];
  requireAnalyticSeries[s];
  If[MatchQ[t, _GeneralizedSeries], requireAnalyticSeries[t]];
  If[seriesArithmeticCompositeQ[s] || seriesArithmeticCompositeQ[t],
    Return[seriesEnvelopeBinary[op, s, t, Automatic, limit], Module]];
  If[seriesArithmeticFlatQ[s] || seriesArithmeticFlatQ[t],
    If[! seriesArithmeticFlatQ[s] && MatchQ[t, _GeneralizedSeries],
      Return[seriesArithmeticBinary[op, t, s, working, limit], Module]];
    result = catch[If[op === "Multiply",
      AsymptoticAnalysis`FlatSeriesMultiply[s, t, "MaxTerms" -> limit],
      If[! MatchQ[t, _GeneralizedSeries],
        z = Unique["flatOperand$"];
        AsymptoticAnalysis`FlatSeriesObservable[s, z + t, z, "MaxTerms" -> limit],
        fail["UnsupportedScale", "Addition needs compatible flat-sector data or a composite bound."]]]];
    If[! seriesArithmeticFallbackQ[result], Return[seriesArithmeticCheck[result], Module]];
    Return[seriesEnvelopeBinary[op, s, t, Automatic, limit], Module]];
  result = catch[
    If[! MatchQ[operand, _GeneralizedSeries], operand = seriesRegularOperand[t, s, op, working, limit]];
    seriesBinary[op, s, operand, Automatic, limit]];
  If[seriesArithmeticFallbackQ[result], seriesEnvelopeBinary[op, s, t, Automatic, limit], seriesArithmeticCheck[result]]];

seriesArithmeticPower[s_GeneralizedSeries, r_, working_, limit_, truncate_: False] := Module[{result, z, powerCut},
  requireAnalyticSeries[s];
  If[! exactRealQ[r],
    If[! FreeQ[r, _GeneralizedSeries] || ! FreeQ[r, s["Variable"]],
      result = seriesArithmeticUnary[Log, s, working, limit];
      result = seriesArithmeticNary[Times, {r, result}, working, limit];
      Return[seriesArithmeticUnary[Exp, result, working, limit], Module]];
    fail["InvalidPower", "The exponent must be an exact real number or a supported real varying expression."]];
  If[seriesArithmeticCompositeQ[s], Return[seriesEnvelopePower[s, r, working, limit], Module]];
  If[seriesArithmeticFlatQ[s],
    If[IntegerQ[r] && r >= 0,
      z = Unique["flatPower$"];
      Return[seriesArithmeticCheck[AsymptoticAnalysis`FlatSeriesObservable[s, z^r, z,
        "MaxPolynomialDegree" -> Max[32, r], "MaxTerms" -> limit]], Module]];
    Return[seriesEnvelopePower[s, r, working, limit], Module]];
  powerCut = If[IntegerQ[r] && r >= 0 && ! TrueQ[truncate], Automatic, working];
  result = catch[seriesPower[s, r, powerCut, limit, truncate]];
  If[seriesArithmeticFallbackQ[result], seriesEnvelopePower[s, r, working, limit], seriesArithmeticOperationCheck[result, s]]];

seriesArithmeticUnary[head_, s_GeneralizedSeries, working_, limit_] := Module[{z = Unique["observable$"], result},
  requireAnalyticSeries[s];
  result = catch[Switch[head,
    Log, seriesLog[s, working, limit],
    Exp, seriesExp[s, working, limit],
    _, AsymptoticAnalysis`SeriesObservable[s, head[z], z, "Cutoff" -> working, "MaxTerms" -> limit]]];
  If[(seriesArithmeticFallbackQ[result] || MatchQ[result, Failure["UnsupportedObservable", _Association]]) &&
      MemberQ[{Log, Exp, Abs, Sin, Cos}, head],
    seriesEnvelopeUnary[head, s, working, limit], seriesArithmeticOperationCheck[result, s]]];

seriesArithmeticNary[head_, args_List, working_, limit_] := Module[{objects, regular, result, op},
  If[Length[args] > limit, fail["ResourceLimit", "The arithmetic expression exceeds MaxTerms operands."]];
  If[AnyTrue[args, FailureQ], Throw[First[Select[args, FailureQ]], $tag]];
  objects = Select[args, MatchQ[#, _GeneralizedSeries] &];
  regular = Select[args, ! MatchQ[#, _GeneralizedSeries] &];
  If[objects === {}, Return[Apply[head, args], Module]];
  If[! FreeQ[regular, _GeneralizedSeries], fail["UnnormalizedSeriesExpression", "An operand contains a series inside an unsupported expression."]];
  op = If[head === Plus, "Add", "Multiply"];
  result = First[objects];
  Do[result = seriesArithmeticCheck[seriesArithmeticBinary[op, result, t, working, limit]], {t, Rest[objects]}];
  If[regular =!= {}, result = seriesArithmeticCheck[seriesArithmeticBinary[op, result, Apply[head, regular], working, limit]]];
  result];

seriesHeldArguments[HoldComplete[args___]] := Apply[List, Map[HoldComplete, HoldComplete[args]]];
seriesHeldNormalize[HoldComplete[s_Symbol], working_, limit_] := Module[{definitions = OwnValues[s], held},
  If[definitions === {}, Return[s, Module]];
  held = Replace[definitions, {HoldPattern[RuleDelayed[_, value_]]} :> HoldComplete[value]];
  If[! MatchQ[held, _HoldComplete], fail["UnsupportedSeriesAlias", "The symbol does not have one ordinary stored value."]];
  seriesHeldNormalize[held, working, limit]];
seriesHeldNormalize[HoldComplete[s_GeneralizedSeries], working_, limit_] := s;
seriesHeldNormalize[HoldComplete[Plus[args___]], working_, limit_] :=
  seriesArithmeticNary[Plus, seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]], working, limit];
seriesHeldNormalize[HoldComplete[Times[args___]], working_, limit_] :=
  seriesArithmeticNary[Times, seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]], working, limit];
seriesHeldNormalize[HoldComplete[Power[b_, r_]], working_, limit_] := Module[{base, exponent, logarithm},
  base = seriesHeldNormalize[HoldComplete[b], working, limit];
  exponent = seriesHeldNormalize[HoldComplete[r], working, limit];
  If[FailureQ[base] || FailureQ[exponent], Throw[If[FailureQ[base], base, exponent], $tag]];
  Which[MatchQ[base, _GeneralizedSeries], seriesArithmeticPower[base, exponent, working, limit],
    MatchQ[exponent, _GeneralizedSeries],
      logarithm = If[base === E, exponent, seriesArithmeticBinary["Multiply", exponent, Log[base], working, limit]];
      seriesArithmeticUnary[Exp, logarithm, working, limit],
    True, base^exponent]];
seriesHeldNormalize[HoldComplete[(head : Log | Exp | Abs | Sin | Cos | Tan | Sinh | Cosh | Tanh | ArcSin | ArcCos | ArcTan)[arg_]], working_, limit_] :=
  Module[{value = seriesHeldNormalize[HoldComplete[arg], working, limit]},
    If[MatchQ[value, _GeneralizedSeries], seriesArithmeticUnary[head, value, working, limit], head[value]]];
seriesHeldNormalize[HoldComplete[List[args___]], working_, limit_] :=
  seriesHeldNormalize[#, working, limit] & /@ seriesHeldArguments[HoldComplete[args]];
seriesHeldNormalize[held_HoldComplete, working_, limit_] := Module[{value, next},
  value = ReleaseHold[held];
  If[FailureQ[value], Throw[value, $tag]];
  If[MatchQ[value, _GeneralizedSeries] || FreeQ[value, _GeneralizedSeries], Return[value, Module]];
  next = With[{v = value}, HoldComplete[v]];
  If[next === held, fail["UnsupportedSeriesExpression", "Use arithmetic or a supported analytic function around series objects; use Normal to discard their remainders."]];
  seriesHeldNormalize[next, working, limit]];

seriesArithmeticAutomatic[held_HoldComplete] := Block[{$seriesArithmeticEnabled = False},
  catch[seriesHeldNormalize[held, Automatic, 20000]]];

(* Mathics rejects a named whole-expression pattern in TagSetDelayed's tag
   search. Its equivalent rules are installed by MathicsFormatting.wl. *)
If[! (StringQ[$Version] && StringContainsQ[$Version, "Mathics"]),
GeneralizedSeries /: expression : Plus[___, s_GeneralizedSeries, ___] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Times[___, s_GeneralizedSeries, ___] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Power[s_GeneralizedSeries, _] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
GeneralizedSeries /: expression : Power[_, s_GeneralizedSeries] /;
    TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
  seriesArithmeticAutomatic[HoldComplete[expression]];
Scan[Function[head, With[{h = head},
  GeneralizedSeries /: expression : h[s_GeneralizedSeries] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s] :=
    seriesArithmeticAutomatic[HoldComplete[expression]]]],
  {Log, Exp, Abs, Sin, Cos, Tan, Sinh, Cosh, Tanh, ArcSin, ArcCos, ArcTan}]
];

AsymptoticAnalysis`SeriesNormalize[expr_, OptionsPattern[]] := Block[{$seriesArithmeticEnabled = False}, catch[Module[
  {cut = OptionValue["Cutoff"], limit = OptionValue["MaxTerms"], result, candidate, precision, next, working, tries = 0},
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[cut =!= Automatic && ! exactRealQ[cut], fail["InvalidCutoff", "Cutoff must be an exact real number or Automatic."]];
  result = catch[seriesHeldNormalize[HoldComplete[expr], Automatic, limit]];
  working = If[cut === Automatic, 1, Max[1, cut]];
  While[MatchQ[result, Failure["UnknownLeadingTerm", _Association]] && tries < 8,
    tries++; working = 2 working + 1;
    candidate = catch[seriesHeldNormalize[HoldComplete[expr], working, limit]];
    If[candidate === result, Break[]]; result = candidate];
  seriesArithmeticCheck[result];
  (* Recompute only operations on the supplied operands. A larger work order
     can expose coefficients of an exact regular function or a newly formed
     reciprocal, but can never improve an operand's unknown remainder. *)
  If[cut =!= Automatic && MatchQ[result, _GeneralizedSeries] &&
      ! seriesArithmeticCompositeQ[result] && ! seriesArithmeticFlatQ[result],
    requireAnalyticSeries[result];
    precision = Lookup[result[[1]], "RemainderPower", Infinity]; working = Max[working, cut];
    While[precision =!= Infinity && less[precision, cut] && tries < 8,
      tries++; working = working + cut - precision + 1;
      candidate = seriesHeldNormalize[HoldComplete[expr], working, limit];
      If[! MatchQ[candidate, _GeneralizedSeries] || seriesArithmeticCompositeQ[candidate], Break[]];
      next = Lookup[candidate[[1]], "RemainderPower", Infinity]; result = candidate;
      If[! less[precision, next], Break[]]; precision = next]];
  seriesArithmeticFinish[result, cut, limit]]]];
AsymptoticAnalysis`SeriesNormalize[___] := Failure["InvalidArguments", <|"MessageTemplate" -> "Use SeriesNormalize[expression, options]."|>];
(* END SOURCE: src/Kernel/SeriesArithmetic.wl *)

(* BEGIN SOURCE: src/Kernel/SpecialFunctionRealDomain.wl
   Source SHA256 (UTF-8/LF): 6e04dd0b41b1ef182afe45bb76d798500bbb4bccd6133b5cc34d95b9b115096c *)
(* Sufficient real domains for the original function, before a native
   asymptotic expansion is projected onto its real part. This is not an
   asymptotic validity or continuity certificate. In particular it neither
   removes Stokes terms nor assigns errors to an unevaluated native result.

   Every successful result describes an eventually valid real domain in
   both the source variable and the positive local coordinate. Failure to
   prove a sufficient domain returns $Failed without throwing. *)

SetAttributes[specialFunctionDomainTry, HoldAll];
specialFunctionDomainTry[e_] := Quiet[TimeConstrained[Check[e, $Failed], 1, $Failed]];

specialFunctionDomainParametersRealQ[e_, u_, ass_] := Module[{parameters},
  parameters = DeleteDuplicates[Cases[e, s_Symbol /;
    s =!= u && Context[s] =!= "System`", {0, Infinity}]];
  AllTrue[parameters,
    TrueQ[specialFunctionDomainTry[FullSimplify[Element[#, Reals], ass]]] &]];

specialFunctionDomainEventuallyQ[condition_, u_, ass_, source_] := Module[{simple},
  simple = specialFunctionDomainTry[FullSimplify[condition, ass && u > 0]];
  If[TrueQ[simple], Return[True, Module]];
  If[simple === $Failed || simple === False || ! FreeQ[simple, _Element] ||
     ! specialFunctionDomainParametersRealQ[source, u, ass], Return[False, Module]];
  (* Resolve[..., Reals] must not supply missing real parameter assumptions.
     Integer membership and other unresolved Element predicates are also
     discharged before calling the shared eventual-neighborhood prover. *)
  TrueQ[TimeConstrained[inverseFunctionEventually[simple, u, ass], 2, False]]];

specialFunctionRealDomain[f_, x_, coord_, ass_, limit_] := Module[{result},
  If[! AssociationQ[coord] || ! AllTrue[{"u", "Substitution", "LocalVariable"},
      KeyExistsQ[coord, #] &] || Head[x] =!= Symbol ||
     ! IntegerQ[limit] || limit < 1 || ! exactQ[f] ||
     ! FreeQ[f, Indeterminate | _DirectedInfinity] ||
     LeafCount[f] > Max[64, Min[4096, limit]], Return[$Failed, Module]];
  result = Quiet[TimeConstrained[
    specialFunctionRealDomainCore[f, x, coord, ass], 8, $Failed]];
  If[AssociationQ[result], result, $Failed]];

specialFunctionRealDomainCore[f_, x_, coord_, ass_] := Module[
  {u = coord["u"], local, condition, domain, references = {},
   walk, allReal, fixedRealQ, validDenominatorQ, record, generic,
   method = "PrincipalRealDomainContracts"},
  local = f /. x -> coord["Substitution"];
  generic = specialFunctionDomainTry[FullSimplify[Element[local, Reals], ass && u > 0]];
  If[TrueQ[generic],
    Return[<|"Domain" -> (coord["LocalVariable"] > 0), "LocalDomain" -> (u > 0),
      "RealFunctionVerified" -> True, "Method" -> "SymbolicRealnessProof",
      "References" -> {}, "Assumptions" -> ass|>, Module]];

  fixedRealQ[values_List] := FreeQ[values, u] && AllTrue[values,
    TrueQ[specialFunctionDomainTry[FullSimplify[Element[#, Reals], ass]]] &];
  validDenominatorQ[b_] := TrueQ[specialFunctionDomainTry[
    FullSimplify[b > 0 || ! Element[b, Integers], ass]]];
  allReal[values_List] := Module[{parts = walk /@ values},
    If[MemberQ[parts, $Failed], $Failed, And @@ parts]];
  record[values_List, restriction_, reference_] := Module[{real = allReal[values]},
    If[real === $Failed, Return[$Failed, Module]];
    If[reference =!= None, AppendTo[references, reference]];
    real && restriction];

  walk[e_] := walk[e] = Module[{a, head = Head[e], n},
    If[e === u, Return[True, Module]];
    If[FreeQ[e, u], Return[If[TrueQ[specialFunctionDomainTry[
      FullSimplify[Element[e, Reals], ass]]], True, $Failed], Module]];
    If[AtomQ[e], Return[$Failed, Module]];
    a = List @@ e; n = Length[a];
    Which[
      MemberQ[{Plus, Times}, head], allReal[a],
      head === Power && n === 2,
        If[IntegerQ[a[[2]]], record[{a[[1]]}, If[a[[2]] < 0, a[[1]] != 0, True], None],
          record[a, a[[1]] > 0, None]],
      head === Log && n === 1, record[a, a[[1]] > 0, None],
      MemberQ[{Sin, Cos, Sinh, Cosh, Tanh, ArcTan, ArcSinh, Abs}, head] && n === 1,
        record[a, True, None],
      MemberQ[{ArcSin, ArcCos}, head] && n === 1,
        record[a, -1 <= a[[1]] <= 1, None],
      head === ArcCosh && n === 1, record[a, a[[1]] >= 1, None],
      head === ArcTanh && n === 1, record[a, -1 < a[[1]] < 1, None],
      MemberQ[{Tan, Sec}, head] && n === 1, record[a, Cos[a[[1]]] != 0, None],
      MemberQ[{Cot, Csc}, head] && n === 1, record[a, Sin[a[[1]]] != 0, None],
      MemberQ[{Coth, Csch}, head] && n === 1, record[a, a[[1]] != 0, None],
      head === Sech && n === 1, record[a, True, None],

      (* Defining real integrals / real initial data establish entire
         real-valued restrictions: https://dlmf.nist.gov/7.2 and /9.2. *)
      MemberQ[{Erf, Erfc, Erfi, DawsonF, FresnelC, FresnelS}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/7.2"],
      head === Erf && n === 2, record[a, True, "https://dlmf.nist.gov/7.2"],
      MemberQ[{AiryAi, AiryBi, AiryAiPrime, AiryBiPrime}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/9.2"],
      (* Positive arguments avoid the principal logarithmic cuts of Ci,
         Chi and Ei. Si and Shi have real entire continuations. *)
      MemberQ[{SinIntegral, SinhIntegral}, head] && n === 1,
        record[a, True, "https://dlmf.nist.gov/6.2"],
      MemberQ[{CosIntegral, CoshIntegral, ExpIntegralEi}, head] && n === 1,
        record[a, a[[1]] > 0, "https://dlmf.nist.gov/6.2"],
      head === LogIntegral && n === 1,
        record[a, a[[1]] > 0 && a[[1]] != 1, "https://dlmf.nist.gov/6.2"],
      head === ExpIntegralE && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/8.19"],

      (* DLMF 10.2(ii), 10.25(ii), and 11.2: the principal cylinder and
         Struve functions are real for real order and positive argument.
         Integer J/I orders additionally give an entire real restriction. *)
      MemberQ[{BesselJ, BesselI}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, If[TrueQ[specialFunctionDomainTry[
          FullSimplify[Element[a[[1]], Integers], ass]]], True, a[[2]] > 0],
          If[head === BesselJ, "https://dlmf.nist.gov/10.2", "https://dlmf.nist.gov/10.25"]],
      MemberQ[{BesselY, BesselK}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0,
          If[head === BesselY, "https://dlmf.nist.gov/10.2", "https://dlmf.nist.gov/10.25"]],
      MemberQ[{StruveH, StruveL}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/11.2"],
      head === ParabolicCylinderD && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, True, "https://dlmf.nist.gov/12.2"],

      (* Positive-axis gamma integrals and real analytic continuation in
         fixed parameters: https://dlmf.nist.gov/8.2. No assertion is made
         across infinitely many negative-axis gamma poles or Barnes zeros. *)
      MemberQ[{Gamma, LogGamma, BarnesG, LogBarnesG}, head] && n === 1,
        record[a, a[[1]] > 0, If[MemberQ[{BarnesG, LogBarnesG}, head],
          "https://dlmf.nist.gov/5.17", "https://dlmf.nist.gov/5.2"]],
      head === PolyGamma && n === 2 && fixedRealQ[{a[[1]]}] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/5.15"],
      head === Gamma && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] > 0, "https://dlmf.nist.gov/8.2"],
      head === Gamma && n === 3 && fixedRealQ[{a[[1]]}],
        record[Rest[a], (a[[2]] > 0 && a[[3]] > 0) ||
          (a[[1]] > 0 && a[[2]] >= 0 && a[[3]] >= 0), "https://dlmf.nist.gov/8.2"],
      head === GammaRegularized && MemberQ[{2, 3}, n] && fixedRealQ[{a[[1]]}],
        record[Rest[a], a[[1]] > 0 && And @@ (# >= 0 & /@ Rest[a]), "https://dlmf.nist.gov/8.2"],
      head === Beta && n === 2, record[a, And @@ (# > 0 & /@ a), "https://dlmf.nist.gov/5.12"],
      MemberQ[{Beta, BetaRegularized}, head] && n === 3 && fixedRealQ[Rest[a]],
        record[{a[[1]]}, 0 < a[[1]] < 1 && a[[2]] > 0 && a[[3]] > 0,
          "https://dlmf.nist.gov/8.17"],

      (* Real Taylor coefficients and continuation avoiding [1,Infinity)
         give the hypergeometric principal real branch. Denominator poles
         are excluded explicitly; regularized functions remove them.
         https://dlmf.nist.gov/13.2 and https://dlmf.nist.gov/16.2. *)
      MemberQ[{Hypergeometric0F1, Hypergeometric0F1Regularized}, head] && n === 2 &&
        fixedRealQ[{a[[1]]}] && (head === Hypergeometric0F1Regularized || validDenominatorQ[a[[1]]]),
        record[{a[[2]]}, True, "https://dlmf.nist.gov/16.2"],
      MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized}, head] && n === 3 &&
        fixedRealQ[Most[a]] && (head === Hypergeometric1F1Regularized || validDenominatorQ[a[[2]]]),
        record[{a[[3]]}, True, "https://dlmf.nist.gov/13.2"],
      MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized}, head] && n === 4 &&
        fixedRealQ[Most[a]] && (head === Hypergeometric2F1Regularized || validDenominatorQ[a[[3]]]),
        record[{a[[4]]}, a[[4]] < 1, "https://dlmf.nist.gov/16.2"],
      MemberQ[{HypergeometricPFQ, HypergeometricPFQRegularized}, head] && n === 3 &&
        ListQ[a[[1]]] && ListQ[a[[2]]] && fixedRealQ[Join[a[[1]], a[[2]]]] &&
        Length[a[[1]]] <= Length[a[[2]]] + 1 &&
        (head === HypergeometricPFQRegularized || AllTrue[a[[2]], validDenominatorQ]),
        record[{a[[3]]}, If[Length[a[[1]]] <= Length[a[[2]]], True, a[[3]] < 1],
          "https://dlmf.nist.gov/16.2"],
      head === HypergeometricU && n === 3 && fixedRealQ[Most[a]],
        record[{a[[3]]}, a[[3]] > 0, "https://dlmf.nist.gov/13.2"],
      MemberQ[{WhittakerM, WhittakerW}, head] && n === 3 && fixedRealQ[Most[a]] &&
        (head === WhittakerW || validDenominatorQ[2 a[[2]] + 1]),
        record[{a[[3]]}, a[[3]] > 0, "https://dlmf.nist.gov/13.14"],

      (* Hurwitz zeta is meromorphic in s with its sole pole at 1 for
         positive a. Polylogarithms use the cut [1,Infinity). The Lerch
         contract uses its convergent real defining series. *)
      head === Zeta && n === 1,
        record[a, a[[1]] != 1, "https://dlmf.nist.gov/25.2"],
      MemberQ[{Zeta, HurwitzZeta}, head] && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[1]] != 1 && a[[2]] > 0, "https://dlmf.nist.gov/25.11"],
      head === PolyLog && n === 2 && fixedRealQ[{a[[1]]}],
        record[{a[[2]]}, a[[2]] < 1, "https://dlmf.nist.gov/25.12"],
      head === LerchPhi && n === 3 && fixedRealQ[{a[[2]]}],
        record[{a[[1]], a[[3]]}, -1 < a[[1]] < 1 && a[[3]] > 0,
          "https://dlmf.nist.gov/25.14"],

      (* Wolfram uses the parameter m=k^2. The sufficient conditions m<1
         and n<1 keep the defining elliptic integrands real and finite on
         every real amplitude interval: https://dlmf.nist.gov/19.2. *)
      MemberQ[{EllipticK, EllipticE}, head] && n === 1,
        record[a, a[[1]] < 1, "https://dlmf.nist.gov/19.2"],
      MemberQ[{EllipticF, EllipticE}, head] && n === 2,
        record[a, a[[2]] < 1, "https://dlmf.nist.gov/19.2"],
      head === EllipticPi && n === 2,
        record[a, a[[1]] < 1 && a[[2]] < 1, "https://dlmf.nist.gov/19.2"],
      head === EllipticPi && n === 3,
        record[a, a[[1]] < 1 && a[[3]] < 1, "https://dlmf.nist.gov/19.2"],

      (* Nonnegative integral degrees give real polynomials; general
         Legendre Q and associated/type-dependent branches are not covered.
         Polynomial formulas: https://dlmf.nist.gov/18.5. *)
      MemberQ[{ChebyshevT, ChebyshevU, HermiteH, LaguerreL, LegendreP}, head] && n === 2 &&
        fixedRealQ[{a[[1]]}] && TrueQ[specialFunctionDomainTry[
          FullSimplify[Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[2]]}, True, "https://dlmf.nist.gov/18.5"],
      MemberQ[{LaguerreL, GegenbauerC}, head] && n === 3 && fixedRealQ[Most[a]] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[3]]}, If[head === GegenbauerC, a[[2]] > 0, True],
          "https://dlmf.nist.gov/18.5"],
      head === JacobiP && n === 4 && fixedRealQ[Most[a]] &&
        TrueQ[specialFunctionDomainTry[FullSimplify[
          Element[a[[1]], Integers] && a[[1]] >= 0, ass]]],
        record[{a[[4]]}, True, "https://dlmf.nist.gov/18.5"],
      True,
        If[TrueQ[specialFunctionDomainTry[FullSimplify[Element[e, Reals], ass && u > 0]]],
          True, $Failed]
    ]
  ];

  condition = walk[local];
  If[condition === $Failed ||
     ! specialFunctionDomainEventuallyQ[condition, u, ass, local],
    (* FunctionDomain is a final generic route, after explicit parameter
       reality. Rechecking Element under the returned domain prevents a
       domain merely assumed by the symbolic solver from becoming proof. *)
    If[! specialFunctionDomainParametersRealQ[local, u, ass], Return[$Failed, Module]];
    domain = specialFunctionDomainTry[FunctionDomain[local, u, Reals]];
    If[domain === $Failed || ! FreeQ[domain, _FunctionDomain | _ConditionalExpression | _Element] ||
       ! specialFunctionDomainEventuallyQ[domain, u, ass, local] ||
       ! TrueQ[specialFunctionDomainTry[FullSimplify[Element[local, Reals], ass && u > 0 && domain]]],
      Return[$Failed, Module]];
    condition = domain; references = {}; method = "SymbolicFunctionDomainProof"];
  condition = u > 0 && condition;
  <|"Domain" -> (condition /. u -> coord["LocalVariable"]),
    "LocalDomain" -> condition, "RealFunctionVerified" -> True,
    "Method" -> method, "References" -> DeleteDuplicates[references], "Assumptions" -> ass|>
];
(* END SOURCE: src/Kernel/SpecialFunctionRealDomain.wl *)

(* BEGIN SOURCE: src/Kernel/SpecialFunctionIdentities.wl
   Source SHA256 (UTF-8/LF): 58fb678b206eac2ae77d107456b375908f2c75e7fdf1d7b867d4bf02b7051da4 *)
(* Exact special-function identities applied before any finite asymptotic
   expansion. A terminating dominant expansion need not be the exact function:
   I_(1/2)(z), for example, contains both exp(z) and exp(-z).
   This module never derives an identity from a truncated asymptotic series. *)

specialIdentityRecord[expression_, domain_, references_, limit_] :=
  If[LeafCount[expression] > limit, $Failed,
    <|"Expression" -> expression, "Domain" -> domain, "References" -> references|>];

specialIdentityProve[condition_, ass_] :=
  TrueQ[inverseBranchTry[FullSimplify[condition, ass]]];

(* This only discharges a side condition of an exact identity. The caller's
   separate real-domain analysis remains responsible for the original input. *)
specialIdentityTailQ[condition_, x_, coord_, ass_] := Module[{parameters, local},
  parameters = DeleteDuplicates[Cases[{condition},
    p_Symbol /; p =!= x && Context[p] =!= "System`", Infinity]];
  If[! AllTrue[parameters, specialIdentityProve[Element[#, Reals], ass] &],
    Return[False, Module]];
  local = condition /. x -> coord["Substitution"];
  TrueQ[inverseBranchTry[inverseFunctionEventually[local, coord["u"], ass]]]];

(* DLMF 10.39.1--2, 10.29.1 and 10.27.2--3. Recurrence is performed on
   finite expressions in the two exponentials, with the square root outside. *)
specialFunctionHalfBessel[head_, order_, z_, limit_] := Module[
  {n = Abs[order] - 1/2, previous, current, next, k, result},
  If[! IntegerQ[n] || n < 0 || n > Min[32, limit], Return[$Failed, Module]];
  If[head === BesselK,
    result = Sqrt[Pi/2] Exp[-z]/Sqrt[z] Sum[
      Factorial[n + k]/(Factorial[k] Factorial[n - k] (2 z)^k), {k, 0, n}],
    If[head =!= BesselI, Return[$Failed, Module]];
    previous = (Exp[z] + Exp[-z])/2; current = (Exp[z] - Exp[-z])/2;
    Do[next = Expand[previous - (2 k - 1) current/z];
      previous = current; current = next;
      If[LeafCount[current] > limit, Return[$Failed, Module]], {k, 1, n}];
    result = Sqrt[2/Pi] current/Sqrt[z];
    If[order < 0, result += 2 (-1)^n/Pi specialFunctionHalfBessel[BesselK, -order, z, limit]]];
  If[! FreeQ[result, $Failed] || LeafCount[result] > limit, $Failed, result]];

(* Finite defining hypergeometric sums. Ordinary denominator parameters are
   excluded from their poles even when a numerator also terminates. Such
   simultaneous singular parameter limits must be specified separately.
   Regularized functions instead have reciprocal-Gamma coefficients. *)
specialFunctionTerminatingHypergeometric[upper_List, lower_List, z_, regularized_, ass_, limit_] := Module[
  {degrees, n, condition, coefficients, k, polynomial},
  degrees = Cases[upper, (a_Integer /; a <= 0) :> -a];
  If[degrees === {}, Return[$Failed, Module]];
  n = Min[degrees];
  If[n > Min[32, limit], Return[$Failed, Module]];
  condition = If[TrueQ[regularized], True,
    And @@ ((# > 0 || ! Element[#, Integers]) & /@ lower)];
  If[! specialIdentityProve[condition, ass], Return[$Failed, Module]];
  coefficients = Table[(Times @@ (Pochhammer[#, k] & /@ upper))/Factorial[k] *
    If[TrueQ[regularized], Times @@ (1/Gamma[# + k] & /@ lower),
      1/(Times @@ (Pochhammer[#, k] & /@ lower))], {k, 0, n}];
  polynomial = Total[MapIndexed[#1 z^(First[#2] - 1) &, coefficients]];
  specialIdentityRecord[polynomial, condition, {"https://dlmf.nist.gov/16.2"}, limit]];

specialFunctionIdentity[e_, x_, coord_, ass_, limit_] := Module[
  {head = Head[e], z, a, b, c, n, upper, lower, regularized, result, condition, endpoint},
  If[MemberQ[{BesselI, BesselK}, head] && Length[e] === 2,
    {a, z} = List @@ e;
    If[FreeQ[a, x] && IntegerQ[2 a] && OddQ[2 a] &&
        specialIdentityTailQ[z > 0, x, coord, ass],
      result = specialFunctionHalfBessel[head, a, z, limit];
      If[result =!= $Failed, Return[specialIdentityRecord[result, z > 0,
        {"https://dlmf.nist.gov/10.39", "https://dlmf.nist.gov/10.29", "https://dlmf.nist.gov/10.27"}, limit], Module]]]];

  If[MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized,
      Hypergeometric2F1, Hypergeometric2F1Regularized, HypergeometricPFQ, HypergeometricPFQRegularized}, head],
    regularized = MemberQ[{Hypergeometric1F1Regularized, Hypergeometric2F1Regularized, HypergeometricPFQRegularized}, head];
    Which[
      MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized}, head] && Length[e] === 3,
        upper = {e[[1]]}; lower = {e[[2]]}; z = e[[3]],
      MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized}, head] && Length[e] === 4,
        upper = {e[[1]], e[[2]]}; lower = {e[[3]]}; z = e[[4]],
      MemberQ[{HypergeometricPFQ, HypergeometricPFQRegularized}, head] && Length[e] === 3 &&
          MatchQ[e[[1]], _List] && MatchQ[e[[2]], _List],
        upper = e[[1]]; lower = e[[2]]; z = e[[3]],
      True, Return[$Failed, Module]];
    If[! FreeQ[{upper, lower}, x], Return[$Failed, Module]];
    result = specialFunctionTerminatingHypergeometric[upper, lower, z, regularized, ass, limit];
    If[result =!= $Failed, Return[result, Module]];
    (* Nonterminating elementary cases below use ordinary normalization. *)
    If[TrueQ[regularized], Return[$Failed, Module]];
    condition = And @@ ((# > 0 || ! Element[#, Integers]) & /@ lower);
    If[! specialIdentityProve[condition, ass], Return[$Failed, Module]];
    If[head === Hypergeometric1F1,
      {a, b} = {First[upper], First[lower]};
      If[specialIdentityProve[a == b, ass],
        Return[specialIdentityRecord[Exp[z], condition, {"https://dlmf.nist.gov/13.6.E1"}, limit], Module]];
      (* Repeated integration by parts in M(n,n+1,z)=n Integrate[
         Exp[z t] t^(n-1),{t,0,1}] retains the endpoint contribution at t=0. *)
      If[IntegerQ[a] && 0 < a <= Min[32, limit] && b === a + 1 &&
          specialIdentityTailQ[z != 0, x, coord, ass],
        result = (-1)^(a - 1) Factorial[a]/z^a *
          (Exp[z] Sum[(-z)^n/Factorial[n], {n, 0, a - 1}] - 1);
        Return[specialIdentityRecord[result, condition && z != 0,
          {"https://dlmf.nist.gov/13.4.E1", "https://dlmf.nist.gov/13.6.E2"}, limit], Module]]];
    If[head === Hypergeometric2F1,
      {a, b, c} = {upper[[1]], upper[[2]], First[lower]};
      If[specialIdentityTailQ[1 - z > 0, x, coord, ass],
        If[specialIdentityProve[c == a, ass],
          Return[specialIdentityRecord[(1 - z)^(-b), condition && 1 - z > 0,
            {"https://dlmf.nist.gov/15.4.E6"}, limit], Module]];
        If[specialIdentityProve[c == b, ass],
          Return[specialIdentityRecord[(1 - z)^(-a), condition && 1 - z > 0,
            {"https://dlmf.nist.gov/15.4.E6"}, limit], Module]];
        If[{a, b, c} === {1, 1, 2} && specialIdentityTailQ[z != 0, x, coord, ass],
          Return[specialIdentityRecord[-Log[1 - z]/z, condition && 1 - z > 0 && z != 0,
            {"https://dlmf.nist.gov/15.4.E1"}, limit], Module]]]]];

  If[head === HypergeometricU && Length[e] === 3,
    {a, b, z} = List @@ e;
    If[FreeQ[{a, b}, x],
      If[IntegerQ[a] && -Min[32, limit] <= a <= 0,
        n = -a;
        result = Sum[(-1)^(n + k) Binomial[n, k] Pochhammer[b + k, n - k] z^k, {k, 0, n}];
        Return[specialIdentityRecord[result, True, {"https://dlmf.nist.gov/13.6.E19"}, limit], Module]];
      If[specialIdentityProve[b == a + 1, ass] && specialIdentityTailQ[z > 0, x, coord, ass],
        Return[specialIdentityRecord[z^(-a), z > 0, {"https://dlmf.nist.gov/13.6.E4"}, limit], Module]]]];

  If[head === Gamma && Length[e] === 2 && IntegerQ[e[[1]]] && 0 < e[[1]] <= Min[32, limit],
    {n, z} = List @@ e;
    Return[specialIdentityRecord[Factorial[n - 1] Exp[-z] Sum[z^k/Factorial[k], {k, 0, n - 1}],
      True, {"https://dlmf.nist.gov/8.4.E8"}, limit], Module]];
  If[head === ExpIntegralE && Length[e] === 2 && IntegerQ[e[[1]]] &&
      -Min[32, limit] <= e[[1]] <= 0 && specialIdentityTailQ[e[[2]] > 0, x, coord, ass],
    n = -e[[1]]; z = e[[2]];
    Return[specialIdentityRecord[Exp[-z] Sum[Factorial[n]/(Factorial[n - k] z^(k + 1)), {k, 0, n}],
      z > 0, {"https://dlmf.nist.gov/8.19.E1", "https://dlmf.nist.gov/8.4.E8"}, limit], Module]];
  If[head === ExpIntegralEi && Length[e] === 1 && specialIdentityTailQ[First[e] < 0, x, coord, ass],
    Return[specialIdentityRecord[-ExpIntegralE[1, -First[e]], First[e] < 0,
      {"https://dlmf.nist.gov/6.2.E6"}, limit], Module]];

  If[MemberQ[{Erf, Erfc, Erfi}, head] && Length[e] === 1 &&
      specialIdentityTailQ[First[e] < 0, x, coord, ass],
    z = -First[e]; result = If[head === Erfc, 2 - Erfc[z], -head[z]];
    Return[specialIdentityRecord[result, First[e] < 0, {"https://dlmf.nist.gov/7.4.i"}, limit], Module]];
  (* Native evaluation of half-integer I may already have produced Sinh/Cosh.
     Keep the exact second exponential instead of expanding only the dominant one. *)
  If[MemberQ[{Sinh, Cosh}, head] && Length[e] === 1,
    z = First[e]; endpoint = inverseBranchTry[Limit[z /. x -> coord["Substitution"],
      coord["u"] -> 0, Direction -> "FromAbove", Assumptions -> ass]];
    If[MemberQ[{Infinity, -Infinity}, endpoint],
      Return[specialIdentityRecord[(Exp[z] + If[head === Sinh, -1, 1] Exp[-z])/2,
        True, {"https://dlmf.nist.gov/4.28"}, limit], Module]]];
  $Failed];

specialFunctionNormalize[f_, x_, coord_, ass_, limit_] := Module[
  {walk, domains = {}, references = {}, normalized},
  validateInput[f, limit];
  If[LeafCount[f] > limit, fail["ResourceLimit", "Exact special-function normalization exceeds MaxTerms expression leaves."]];
  walk[e_] := Module[{value, identity},
    If[AtomQ[e] || FreeQ[e, x] || ! MatchQ[Head[e], _Symbol] ||
        MemberQ[{Piecewise, ConditionalExpression}, Head[e]] ||
        ! FreeQ[With[{h = Head[e]}, Attributes[h]], HoldAll | HoldAllComplete | HoldFirst | HoldRest],
      Return[e, Module]];
    value = Map[walk, e]; identity = specialFunctionIdentity[value, x, coord, ass, limit];
    If[AssociationQ[identity] && identity["Expression"] =!= value,
      AppendTo[domains, identity["Domain"]]; references = Join[references, identity["References"]];
      value = identity["Expression"]];
    value];
  normalized = walk[f];
  validateInput[normalized, limit];
  If[LeafCount[normalized] > limit,
    fail["ResourceLimit", "Exact special-function normalization exceeds MaxTerms expression leaves."]];
  <|"Expression" -> normalized, "Domain" -> And @@ domains,
    "Changed" -> (normalized =!= f), "References" -> DeleteDuplicates[references]|>];
(* END SOURCE: src/Kernel/SpecialFunctionIdentities.wl *)

(* BEGIN SOURCE: src/Kernel/ParameterizedSpecialFunctions.wl
   Source SHA256 (UTF-8/LF): 19370b301debf8107b96e356b00bc06a6c4bf04ee7aa9bab3060fff822afa204 *)
(* Fixed-parameter special functions in the finite-argument composition
   calculus. Realness of the original expression is checked independently;
   a successful native series still has to satisfy fwdAnalytic's existing
   coefficient and precision checks. No definitions are installed on a
   temporary function symbol. *)

specialParameterizedArgumentPosition[e_, u_] := Module[{h = Head[e], n, varying, allowed},
  If[AtomQ[e] || Head[h] =!= Symbol || Context[Evaluate[h]] =!= "System`", Return[$Failed, Module]];
  n = Length[e];
  varying = Select[Range[n], ! FreeQ[e[[#]], u] &];
  If[Length[varying] =!= 1, Return[$Failed, Module]];
  allowed = Which[
    MemberQ[{BesselJ, BesselI, BesselY, BesselK, StruveH, StruveL,
      ParabolicCylinderD, PolyGamma, PolyLog, ExpIntegralE,
      Zeta, HurwitzZeta, Hypergeometric0F1, Hypergeometric0F1Regularized,
      ChebyshevT, ChebyshevU, HermiteH, LaguerreL, LegendreP}, h] && n === 2, {2},
    MemberQ[{Gamma, GammaRegularized}, h] && MemberQ[{2, 3}, n], Range[2, n],
    MemberQ[{Hypergeometric1F1, Hypergeometric1F1Regularized, HypergeometricU,
      HypergeometricPFQ, HypergeometricPFQRegularized, WhittakerM, WhittakerW,
      LaguerreL, GegenbauerC}, h] && n === 3, {3},
    MemberQ[{Hypergeometric2F1, Hypergeometric2F1Regularized, JacobiP}, h] && n === 4, {4},
    MemberQ[{Beta, BetaRegularized}, h] && n === 3, {1},
    h === LerchPhi && n === 3, {1, 3},
    MemberQ[{EllipticF, EllipticE, EllipticPi, Erf}, h] && n === 2, {1, 2},
    h === EllipticPi && n === 3, {1, 2, 3},
    True, {}];
  If[MemberQ[allowed, First[varying]], First[varying], $Failed]];

(* At zero the displayed special function can have an irrational leading
   power outside SeriesData. These defining-series identities separate that
   power from an analytic function with ordinary integer Taylor exponents.
   The result is {power, analytic body, constant offset, multiplier}.
   Positive arguments make every power identity a principal-real identity.
   References: DLMF 10.2.2, 10.25.2, 11.2.1-2, and 8.7.1. *)
specialParameterizedFrobenius[e_, position_, z_, ass_] := Module[
  {h = Head[e], a = e[[1]], mu, body, offset = 0, multiplier = 1, fixed},
  If[! exactRealQ[a], Return[$Failed, Module]];
  Which[
    MemberQ[{BesselJ, BesselI}, h] && position === 2 && provablyPositive[a + 1, ass],
      mu = a;
      body = Hypergeometric0F1[1 + a, If[h === BesselJ, -1, 1] z^2/4]/
        (2^a Gamma[1 + a]),
    MemberQ[{StruveH, StruveL}, h] && position === 2 && provablyPositive[a + 3/2, ass],
      mu = a + 1;
      body = HypergeometricPFQ[{1}, {3/2, a + 3/2},
        If[h === StruveH, -1, 1] z^2/4]/(2^(a + 1) Gamma[3/2] Gamma[a + 3/2]),
    MemberQ[{Gamma, GammaRegularized}, h] && provablyPositive[a, ass],
      mu = a; body = Hypergeometric1F1[a, a + 1, -z]/a;
      If[h === GammaRegularized, body = body/Gamma[a]];
      If[Length[e] === 2,
        offset = If[h === Gamma, Gamma[a], 1]; multiplier = -1,
        fixed = e[[If[position === 2, 3, 2]]];
        multiplier = If[position === 2, -1, 1];
        offset = -multiplier If[h === Gamma, Gamma[a, 0, fixed], GammaRegularized[a, 0, fixed]]],
    True, Return[$Failed, Module]];
  {mu, body, offset, multiplier}];

specialParameterizedForwardJet[e_, u_, ell_, ass_, Kw_, limit_] := Module[
  {position, result},
  If[TrueQ[$specialParameterizedForwardActive] || ! IntegerQ[limit] || limit < 1 ||
    ! exactQ[e] || ! FreeQ[e, Indeterminate | _DirectedInfinity] ||
    LeafCount[e] > Max[64, Min[4096, limit]], Return[$Failed, Module]];
  position = specialParameterizedArgumentPosition[e, u];
  If[position === $Failed, Return[$Failed, Module]];
  result = Quiet[TimeConstrained[Catch[
    specialParameterizedForwardJetCore[e, position, u, ell, ass, Kw, limit], $tag], 30, $Failed]];
  (* Let the ordinary dispatcher handle inapplicable input and finite-order
     failures. In particular an exact-jet probe is never made artificially
     finite here. The re-entry guard prevents fallback composition cycles. *)
  If[MatchQ[result, {_List, _, _}], result, $Failed]];

specialParameterizedForwardJetCore[e_, position_, u_, ell_, ass_, Kw_, limit_] := Module[
  {domain, argument, jet, negative, center, small, z = Unique["specialArgument$"],
   body, unary, normalized, factor, regular, result, relativeCut, weight},
  argument = e[[position]];
  jet = fwd[argument, u, ell, ass, Kw, limit];
  If[! MatchQ[jet, {_List, _, _}] || ! less[0, jet[[2]]], Return[$Failed, Module]];
  {negative, center, small} = splitJet[jet[[1]]];
  If[negative =!= {} || ! FreeQ[center, ell] ||
    ! TrueQ[TimeConstrained[FullSimplify[Element[center, Reals], ass], 1, False]],
    Return[$Failed, Module]];
  (* fwdAnalytic cannot return an exact jet for a nonconstant increment.
     Reject that probe before proving the whole special function real;
     arguments constant under the assumptions still take the usual path. *)
  If[Kw === Infinity && small =!= {}, Return[$Failed, Module]];
  domain = specialFunctionRealDomain[e, u,
    <|"u" -> u, "Substitution" -> u, "LocalVariable" -> u|>, ass, limit];
  If[! AssociationQ[domain] || ! TrueQ[domain["RealFunctionVerified"]], Return[$Failed, Module]];
  normalized = If[zeroQ[center, ass], specialParameterizedFrobenius[e, position, z, ass], $Failed];
  result = Block[{$specialParameterizedForwardActive = True},
    If[ListQ[normalized] &&
       TrueQ[specialFunctionDomainEventuallyQ[argument > 0, u, ass, e]],
      factor = fwdPower[jet, normalized[[1]], u, ell, ass, Kw, limit];
      weight = If[jet[[1]] === {}, jet[[2]], jetValuation[jet[[1]]]];
      relativeCut = If[Kw === Infinity, Infinity, Kw - normalized[[1]] weight];
      body = normalized[[2]];
      unary = Apply[Function, {{z}, body}];
      regular = fwdAnalytic[unary, jet, body /. z -> argument,
        u, ell, ass, relativeCut, limit];
      pAdd[pConst[normalized[[3]], ell, ass],
        pScale[pMul[factor, regular, ell, ass, limit], normalized[[4]], ell, ass], ell, ass],
      body = ReplacePart[e, position -> z];
      unary = Apply[Function, {{z}, body}];
      fwdAnalytic[unary, jet, e, u, ell, ass, Kw, limit]]];
  If[! MatchQ[result, {_List, _, _}] ||
    ! AllTrue[result[[1]], PolynomialQ[#[[2]], ell] &&
      TrueQ[TimeConstrained[FullSimplify[Element[#[[2]], Reals],
        ass && Element[ell, Reals]], 1, False]] &], Return[$Failed, Module]];
  result];
(* END SOURCE: src/Kernel/ParameterizedSpecialFunctions.wl *)

(* BEGIN SOURCE: src/Kernel/DirichletSpecialFunctions.wl
   Source SHA256 (UTF-8/LF): 381e36cab5d980c050fb208236308b0118c8b97be9b2f457f297bfc203ea9a6c *)
(* Two convergent defining sums supply expansions unavailable from native
   Series. All parameters are fixed on the target approach. Zeta uses the
   exponential coordinate exp(-S); Lerch uses the reciprocal argument 1/a.
   https://dlmf.nist.gov/25.2.E1
   https://dlmf.nist.gov/25.14.E1 *)

dirichletSpecialBudget[e_, limit_] :=
  If[LeafCount[e] > limit, fail["ResourceLimit", "The Dirichlet special-function expansion exceeds MaxTerms expression leaves."]];

dirichletSpecialOptions[cut_, goal_, limit_] := (
  If[! IntegerQ[limit] || limit < 1, fail["InvalidOption", "MaxTerms must be a positive integer."]];
  If[goal =!= Automatic && (! IntegerQ[goal] || goal < 1),
    fail["InvalidTermGoal", "SeriesTermGoal must be a positive integer or Automatic."]];
  If[cut === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give a real exponent cutoff or a positive integer SeriesTermGoal."]],
    If[! exactRealQ[cut], fail["InvalidCutoff", "The cutoff must be an exact real number."]]]);

dirichletSpecialLargeArgumentQ[argument_, x_, coord_, ass_] := Module[{local, parameters},
  parameters = DeleteDuplicates[Cases[{argument},
    p_Symbol /; p =!= x && Context[p] =!= "System`", Infinity]];
  If[! AllTrue[parameters, TrueQ[inverseBranchTry[FullSimplify[Element[#, Reals], ass]]] &],
    Return[False, Module]];
  local = argument /. x -> coord["Substitution"];
  TrueQ[inverseBranchTry[inverseFunctionEventually[local > 0, coord["u"], ass]]] &&
    inverseBranchTry[Limit[local, coord["u"] -> 0, Direction -> "FromAbove", Assumptions -> ass]] === Infinity];

dirichletSpecialMake[f_, rows_, rho_, w_, domain_, x_, x0_, coord_, ass_, cut_, goal_, metadata_, limit_] := Module[
  {ell = Unique["dirichletLog$"], representation, result, actualCut},
  dirichletSpecialBudget[rows, limit];
  actualCut = If[cut === Automatic, rho, cut];
  representation = <|"Variable" -> x, "ScaleVariable" -> w, "LogVariable" -> ell,
    "Assumptions" -> ass, "Domain" -> domain, "Offset" -> 0, "Prefactor" -> 1,
    "Jet" -> {rows, rho, 0}, "Cutoff" -> actualCut,
    "RemainderDerivativeOrder" -> If[rho === Infinity, Infinity, 0]|>;
  result = seriesMake[representation, {"DirichletSpecialExpansion", {}}, Automatic];
  dirichletSpecialBudget[{result["Expression"], result["Remainder"]}, limit];
  GeneralizedSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "SeriesApproach" -> <|"Variable" -> x, "Point" -> x0, "Direction" -> coord["Direction"]|>,
    "Cutoff" -> actualCut, "RequestedCutoff" -> cut, "RequestedTermGoal" -> goal,
    "ReturnedTermCount" -> Length[rows], "Precision" -> {rho, 0},
    "SeriesRepresentation" -> Join[result["SeriesRepresentation"], <|"Cutoff" -> actualCut|>],
    "ParameterScope" -> "Parameters are fixed on the recorded real target approach; no uniformity as parameters vary is asserted."|>, metadata]]];

dirichletZetaForward[f_, argument_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {count, low, high, middle, first, w, rows, rho, domain, expression, bound},
  If[! MemberQ[{Infinity, -Infinity}, x0] || ! PolynomialQ[argument, x] ||
      Exponent[argument, x] =!= 1 || ! dirichletSpecialLargeArgumentQ[argument, x, coord, ass],
    Return[$Failed, Module]];
  dirichletSpecialOptions[cut, goal, limit];
  If[cut === Automatic,
    count = goal;
    If[count > limit, fail["ResourceLimit", "The Zeta Dirichlet term goal exceeds MaxTerms."]],
    (* Log[n]<cut is exclusive. Binary search avoids enumerating exp(cut)
       candidates, and the initial comparison rejects excessive requests. *)
    If[less[Log[limit + 1], cut], fail["ResourceLimit", "The Zeta exponential-coordinate cutoff exceeds MaxTerms."]];
    low = 0; high = limit + 1;
    While[high - low > 1,
      middle = Quotient[low + high, 2];
      If[less[Log[middle], cut], low = middle, high = middle]];
    count = low];
  first = count + 1; w = Exp[-argument]; rho = Log[first]; domain = ass && argument > 1;
  rows = Table[{Log[n], 1}, {n, 1, count}];
  expression = Total[Table[n^(-argument), {n, 1, count}]];
  (* For decreasing t^-S, sum_(n=m)^Infinity n^-S lies between
     m^-S and m^-S + Integrate[t^-S,{t,m,Infinity}], S>1. *)
  bound = first^(-argument) (1 + first/(argument - 1));
  dirichletSpecialMake[f, rows, rho, w, domain, x, x0, coord, ass, cut, goal, <|
    "Expression" -> expression, "RemainderScaleExpression" -> first^(-argument),
    "FrontierTerm" -> first^(-argument), "FirstOmittedInteger" -> first,
    "SpecialFunctionBackend" -> "ConvergentDirichletSeries", "SpecialFunctionFamily" -> "Zeta",
    "SourceArgument" -> argument, "ExpansionNature" -> "ConvergentDirichlet",
    "AbsoluteRemainderBound" -> bound, "RemainderLowerBound" -> first^(-argument),
    "RemainderBoundConditions" -> domain,
    "ForwardRemainderContract" -> <|"Type" -> "DirichletIntegralComparison",
      "ConvergentForwardSeries" -> True, "NumericCertificate" -> False,
      "Statement" -> "The positive omitted Dirichlet tail is bounded by its first term plus the integral of t^(-SourceArgument) from FirstOmittedInteger to Infinity."|>,
    "TermConvention" -> "The positive coordinate is w=Exp[-SourceArgument]. The n-th Dirichlet term is w^Log[n]; the exclusive cutoff is in this coordinate and SeriesTermGoal includes the constant n=1 term.",
    "AsymptoticReferences" -> {"https://dlmf.nist.gov/25.2.E1"}|>, limit]];

dirichletSpecialMoment[z_, 0] := 1/(1 - z);
dirichletSpecialMoment[z_, k_Integer?Positive] := If[z === 0, 0, PolyLog[-k, z]];

dirichletLerchCoefficient[z_, s_, k_, ass_, limit_] := Module[{coefficient},
  coefficient = inverseBranchTry[FullSimplify[(-1)^k Pochhammer[s, k] dirichletSpecialMoment[z, k]/Factorial[k], ass]];
  If[coefficient === $Failed, fail["ResourceLimit", "A Lerch moment exceeded the symbolic time budget."]];
  dirichletSpecialBudget[coefficient, limit]; coefficient];

(* Taylor's theorem for h(t)=(1+t)^(-s), t>=0, gives
   |h(t)-sum_(k<N) (-1)^k (s)_k t^k/k!|
       <= |(s)_N| t^N (1+t)^D/N!, D=max(0,ceil(-s-N)).
   For a>=1, t=n/a<=n. Summing absolute values against |z|^n
   yields the finite polylogarithmic moment constant below. This includes
   N=0, with M_0 containing the n=0 term, and every fixed real s. *)
dirichletLerchBoundConstant[z_, s_, n_, ass_, limit_] := Module[{d, constant},
  d = Max[0, Ceiling[-s - n]];
  If[n + d > limit, fail["ResourceLimit", "The Lerch remainder moment degree exceeds MaxTerms."]];
  constant = inverseBranchTry[FullSimplify[Abs[Pochhammer[s, n]]/Factorial[n] *
    Sum[Binomial[d, j] dirichletSpecialMoment[Abs[z], n + j], {j, 0, d}], ass]];
  If[constant === $Failed, fail["ResourceLimit", "The Lerch remainder bound exceeded the symbolic time budget."]];
  dirichletSpecialBudget[constant, limit]; constant];

dirichletLerchForward[f_, z_, s_, argument_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {degree, rows = {}, k = 0, coefficient, frontier = None, rho, w, domain, boundConstant,
    expression, exactSource, bound, conditions},
  If[! FreeQ[{z, s}, x] || ! exactRealQ[z] || ! exactRealQ[s] ||
      ! less[-1, z] || ! less[z, 1] || ! dirichletSpecialLargeArgumentQ[argument, x, coord, ass],
    Return[$Failed, Module]];
  dirichletSpecialOptions[cut, goal, limit];
  degree = Which[z === 0, 0, IntegerQ[s] && s <= 0, -s, True, Infinity];
  While[k <= degree,
    If[k > limit, fail["ResourceLimit", "The Lerch nonzero-moment search exceeds MaxTerms."]];
    coefficient = dirichletLerchCoefficient[z, s, k, ass, limit];
    If[! zeroQ[coefficient, ass],
      If[If[cut === Automatic, Length[rows] >= goal, ! less[s + k, cut]],
        frontier = {s + k, coefficient, k}; Break[]];
      AppendTo[rows, {s + k, coefficient}]; dirichletSpecialBudget[rows, limit]];
    k++];
  rho = If[frontier === None, Infinity, frontier[[1]]];
  w = 1/argument; domain = ass && argument > 0;
  expression = Total[(argument^(-#[[1]]) #[[2]]) & /@ rows];
  exactSource = degree =!= Infinity;
  If[frontier === None, boundConstant = 0; bound = 0; conditions = domain,
    boundConstant = dirichletLerchBoundConstant[z, s, frontier[[3]], ass, limit];
    bound = boundConstant argument^(-rho); conditions = domain && argument >= 1];
  dirichletSpecialMake[f, rows, rho, w, domain, x, x0, coord, ass, cut, goal, <|
    "Expression" -> expression,
    "RemainderScaleExpression" -> If[frontier === None, 0, argument^(-rho)],
    "FrontierTerm" -> If[frontier === None, 0, frontier[[2]] argument^(-rho)],
    "FirstOmittedMoment" -> If[frontier === None, None, frontier[[3]]],
    "SpecialFunctionBackend" -> "GeometricMomentExpansion", "SpecialFunctionFamily" -> "LerchPhi",
    "SourceArgument" -> argument, "LerchParameters" -> {z, s},
    "ExpansionNature" -> If[exactSource, "Finite", "Poincare"],
    "FiniteSourceExpansion" -> exactSource, "AbsoluteRemainderBound" -> bound,
    "RemainderBoundConstant" -> boundConstant, "RemainderBoundConditions" -> conditions,
    "ForwardRemainderContract" -> <|"Type" -> "TaylorRemainderSummedAgainstGeometricWeights",
      "ConvergentForwardSeries" -> exactSource, "NumericCertificate" -> False,
      "Statement" -> "For fixed real z and s with |z|<1 and positive a>=1, Taylor's theorem applied to (1+n/a)^(-s) bounds the omitted terms by RemainderBoundConstant a^(-RemainderPower). Negative integer s and z=0 give finite exact source expansions."|>,
    "TermConvention" -> "The positive coordinate is w=1/SourceArgument. Blocks have absolute exponents s+k with coefficients (-1)^k Pochhammer[s,k] M_k(z)/k!, where M_0(z)=1/(1-z) and M_k(z)=PolyLog[-k,z] for k>0. SeriesTermGoal counts nonzero blocks; cutoff is exclusive in w.",
    "AsymptoticReferences" -> {"https://dlmf.nist.gov/25.14.E1", "https://dlmf.nist.gov/25.12.E10"}|>, limit]];

dirichletSpecialForwardExpansion[f_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[{},
  If[! MatchQ[f, Zeta[_] | LerchPhi[_, _, _]], Return[$Failed, Module]];
  validateInput[f, limit]; dirichletSpecialBudget[f, limit];
  If[Head[f] === Zeta,
    dirichletZetaForward[f, First[f], x, x0, cut, ass, coord, goal, limit],
    dirichletLerchForward[f, f[[1]], f[[2]], f[[3]], x, x0, cut, ass, coord, goal, limit]]];
(* END SOURCE: src/Kernel/DirichletSpecialFunctions.wl *)

(* BEGIN SOURCE: src/Kernel/NativeSpecialFunctions.wl
   Source SHA256 (UTF-8/LF): 7292639d9b1c6a37482deee38d054ddd40c7a7b1d39474a3410ea2c96fefb012 *)
(* Import structured native asymptotic series without discarding their O terms.
   Native special-function expansions may contain several exact exponential
   carriers and oscillatory phases. Every tree operation transports an
   absolute error; a real projection is allowed only for a proved real source.
   https://reference.wolfram.com/language/ref/Series.html
   https://dlmf.nist.gov/2.1.iii *)

SetAttributes[specialNativeTry, HoldAllComplete];
specialNativeTry[e_] := Quiet[TimeConstrained[e, 4, $Failed]];

$specialNativeHeads = {AiryAi, AiryBi, AiryAiPrime, AiryBiPrime,
  BesselJ, BesselY, BesselI, BesselK, SphericalBesselJ, SphericalBesselY,
  HankelH1, HankelH2, StruveH, StruveL, AngerJ, WeberE,
  Erf, Erfc, Erfi, InverseErf, InverseErfc, DawsonF,
  ExpIntegralE, ExpIntegralEi, LogIntegral, SinIntegral, CosIntegral,
  SinhIntegral, CoshIntegral, FresnelC, FresnelS, Sinh, Cosh,
  PolyGamma, Zeta, HurwitzZeta, PolyLog, LerchPhi,
  GammaRegularized, InverseGammaRegularized, BetaRegularized,
  Hypergeometric0F1, Hypergeometric0F1Regularized,
  Hypergeometric1F1, Hypergeometric1F1Regularized, HypergeometricU,
  Hypergeometric2F1, Hypergeometric2F1Regularized, HypergeometricPFQ,
  HypergeometricPFQRegularized, MeijerG, WhittakerM, WhittakerW,
  ParabolicCylinderD, EllipticK, EllipticE, EllipticF, EllipticPi, JacobiSN, JacobiCN,
  JacobiDN, JacobiAmplitude, JacobiZeta, EllipticTheta,
  LegendreP, LegendreQ, GegenbauerC, JacobiP, LaguerreL,
  HermiteH, ChebyshevT, ChebyshevU, SpheroidalPS, SpheroidalQS};
$specialNativeCoreHeads = {Plus, Times, Power, Log, Exp, Abs, Sign,
  Sin, Cos, Tan, Cot, Sec, Csc, Tanh, Coth, Sech, Csch,
  ArcSin, ArcCos, ArcTan, ArcCot, ArcSec, ArcCsc, ArcSinh, ArcCosh,
  ArcTanh, ArcCoth, ArcSech, ArcCsch, Gamma, LogGamma, BarnesG,
  LogBarnesG, Factorial, Factorial2, Binomial, Beta, Pochhammer,
  Floor, Ceiling, Round, FractionalPart, IntegerPart, UnitStep,
  Min, Max, Re, Im, Conjugate, Arg};
specialNativeCandidateQ[f_, x_] := ! FreeQ[f, node_ /;
  ! AtomQ[node] && ! FreeQ[node, x] &&
    (MemberQ[$specialNativeHeads, Head[node]] ||
      specialNativeBuiltinHeadQ[Head[node]] ||
      MatchQ[node, Gamma[_, _] | Gamma[_, _, _] | Beta[_, _, _] | Beta[_, _, _, _]])];
specialNativeBuiltinHeadQ[h_Symbol] := Context[h] === "System`" &&
  ! MemberQ[$specialNativeCoreHeads, h] && MemberQ[Attributes[h], NumericFunction];
specialNativeBuiltinHeadQ[_] := False;

specialNativeBound[r_] := r /. rr_PowerLogRemainder :> remainderScale[rr];
specialNativeSmallQ[r_, u_, ass_] := Module[{bound},
  If[r === 0, Return[True, Module]];
  bound = Refine[specialNativeBound[r], ass && u > 0];
  (* These factors occur in nonnegative error sums. Their global bounds
     remove oscillations before the scalar limit test. *)
  bound = bound /. HoldPattern[Abs[(h : Sin | Cos)[phase_]]] /;
      TrueQ[Refine[Element[phase, Reals], ass && u > 0]] :> 1;
  specialNativeTry[Limit[bound, u -> 0, Direction -> "FromAbove", Assumptions -> ass]] === 0];
specialNativeReal[e_, u_, ass_] := Module[{value, simplified},
  value = specialNativeTry[Refine[ComplexExpand[Re[e],
    Select[DeleteDuplicates[Cases[e, _Symbol, {0, Infinity}]],
      # =!= u && ! NumericQ[#] && ! TrueQ[Refine[Element[#, Reals], ass]] &]], ass && u > 0]];
  If[value === $Failed, fail["ResourceLimit", "Real projection of the native expansion exceeded its time budget."]];
  value = Expand[value];
  (* Keep real oscillatory phases polynomial in their bounded modes.
     Global trigonometric simplification can combine different algebraic
     weights into a variable phase or a rational coefficient. *)
  If[! FreeQ[value, node : (Sin[_] | Cos[_]) /; ! FreeQ[node, u]], Return[value, Module]];
  simplified = specialNativeTry[FullSimplify[value, ass && u > 0]];
  If[simplified === $Failed, value, simplified]];
(* A structural absolute majorant avoids expensive cancellation inside an
   absolute value. In particular |sin(a+ib)| and |cos(a+ib)| are bounded by
   exp(|b|), which cancels opposite real carriers before the limit check. *)
specialNativeAbs[e_Plus, u_, ass_] := Total[specialNativeAbs[#, u, ass] & /@ List @@ e];
specialNativeAbs[e_Times, u_, ass_] := Times @@ (specialNativeAbs[#, u, ass] & /@ List @@ e);
specialNativeAbs[Power[E, phase_], u_, ass_] := Exp[Refine[Re[phase], ass && u > 0]];
specialNativeAbs[(Sin | Cos)[phase_], u_, ass_] := Exp[Abs[Refine[Im[phase], ass && u > 0]]];
specialNativeAbs[e_, u_, ass_] := Module[{value},
  value = specialNativeTry[FullSimplify[Abs[e], ass && u > 0]];
  If[value === $Failed, Abs[e], value]];

specialNativeMultiply[{a_, r_}, {b_, s_}, u_, ass_] :=
  {a b, If[s === 0, 0, specialNativeAbs[a, u, ass] s] +
    If[r === 0, 0, specialNativeAbs[b, u, ass] r] + r s};

specialNativeTree[e_, u_, ass_, limit_] := Module[
  {head = Head[e], result, argument, value, error, power, rows, coefficient, term},
  If[LeafCount[e] > limit, fail["ResourceLimit", "The native special-function expansion exceeds MaxTerms."]];
  If[FreeQ[e, _SeriesData],
    If[! FreeQ[e, _Series | _Derivative | Indeterminate | _DirectedInfinity],
      fail["UnresolvedNativeSeries", "The native expansion contains an unresolved function or nonfinite coefficient."]];
    Return[{e, 0}, Module]];
  Switch[head,
    SeriesData,
      If[e[[1]] =!= u || e[[2]] =!= 0 || ! IntegerQ[e[[6]]] || e[[6]] < 1,
        fail["UnsupportedNativeCoordinate", "Native series must use the recorded positive local variable at zero."]];
      rows = e[[3]]; result = {0, 0};
      Do[
        coefficient = specialNativeTree[rows[[k]], u, ass, limit];
        term = specialNativeMultiply[coefficient, {u^((e[[4]] + k - 1)/e[[6]]), 0}, u, ass];
        result += term,
        {k, Length[rows]}];
      (* SeriesData does not encode the logarithmic degree of its unknown
         tail. A half-lattice-step loss absorbs every fixed logarithmic
         polynomial. A sharper returned boundary comes from an explicitly
         computed omitted block, never a degree guessed from kept terms. *)
      result + {0, PowerLogRemainder[u, Sequence @@ nativeSeriesTailPrecision[e]]},
    Plus,
      Total[specialNativeTree[#, u, ass, limit] & /@ List @@ e],
    Times,
      Fold[specialNativeMultiply[#1, #2, u, ass] &, {1, 0},
        specialNativeTree[#, u, ass, limit] & /@ List @@ e],
    Power,
      If[e[[1]] === E,
        argument = specialNativeTree[e[[2]], u, ass, limit];
        If[! specialNativeSmallQ[argument[[2]], u, ass],
          fail["InsufficientNativePhasePrecision", "A native exponential phase must have vanishing absolute error."]];
        Return[{Exp[argument[[1]]], Exp[specialNativeReal[argument[[1]], u, ass]] argument[[2]]}, Module]];
      argument = specialNativeTree[e[[1]], u, ass, limit]; power = e[[2]];
      If[! FreeQ[power, _SeriesData] || ! exactRealQ[power],
        fail["UnsupportedNativePower", "A native series power requires a fixed exact real exponent."]];
      If[IntegerQ[power] && power >= 0,
        If[power > limit, fail["ResourceLimit", "The native polynomial power exceeds MaxTerms."]];
        Return[Fold[specialNativeMultiply[#1, argument, u, ass] &, {1, 0}, Range[power]], Module]];
      If[! TrueQ[specialNativeTry[FullSimplify[argument[[1]] > 0, ass && u > 0]]] ||
          ! specialNativeSmallQ[argument[[2]]/argument[[1]], u, ass],
        fail["UnprovedNativePowerBranch", "The native power needs a positive leading approximation and vanishing relative error."]];
      {argument[[1]]^power, argument[[1]]^(power - 1) argument[[2]]},
    Sin | Cos | Sinh | Cosh,
      argument = specialNativeTree[First[e], u, ass, limit];
      value = argument[[1]]; error = argument[[2]];
      If[MemberQ[{Sin, Cos}, head] && TrueQ[specialNativeTry[FullSimplify[Element[value, Reals], ass && u > 0]]],
        Return[{head[value], error}, Module]];
      If[! specialNativeSmallQ[error, u, ass],
        fail["InsufficientNativePhasePrecision", "A complex or hyperbolic phase requires vanishing absolute error."]];
      {head[value], Exp[Abs[If[MemberQ[{Sin, Cos}, head], Im[value], Re[value]]]] error},
    _, fail["UnsupportedNativeSeriesTree", "The native series contains an unsupported operation on a truncated argument.", <|"Head" -> head|>]]];

(* Split finite terms into real exponential carriers and algebraic weights.
   Oscillations remain coefficients with absolute bounds, never a nonzero
   leading coefficient from which division could infer a branch. *)
specialNativeTerm[term_, u_, ass_] := Module[{factors, carrier = 1, weight = 0, coefficient = 1},
  factors = If[Head[term] === Times, List @@ term, {term}];
  Do[Which[
    factor === u, weight += 1,
    MatchQ[factor, Power[u, _?exactRealQ]], weight += factor[[2]],
    MatchQ[factor, Power[E, _]] && ! FreeQ[factor, u], carrier *= factor,
    MatchQ[factor, Power[u, _]] && TrueQ[specialNativeTry[FullSimplify[Element[factor[[2]], Reals], ass]]], carrier *= factor,
    True, coefficient *= factor], {factor, factors}];
  {carrier, canon[weight], coefficient}];

specialNativeCoefficientDegree[c_, u_, ass_] := Module[{q, ell = Unique["nativeLog$"], oscillations, modes},
  oscillations = DeleteDuplicates[Cases[c, node : (Sin[_] | Cos[_]) /; ! FreeQ[node, u], {0, Infinity}]];
  If[! AllTrue[oscillations, TrueQ[specialNativeTry[FullSimplify[Element[First[#], Reals], ass && u > 0]]] &],
    fail["UnprovedNativeOscillation", "Oscillatory coefficient phases must be real."]];
  modes = Table[Unique["boundedMode$"], {Length[oscillations]}];
  q = c /. Thread[oscillations -> modes] /. Log[u] -> ell;
  If[! FreeQ[q, u] || ! PolynomialQ[q, Prepend[modes, ell]],
    fail["UnsupportedNativeCoefficient", "A native amplitude must have polynomial logarithmic coefficients and bounded real sine/cosine modes.", <|"Coefficient" -> c|>]];
  Max[0, Exponent[q, ell]]];

specialNativeSectors[expression_, u_, ass_] := Module[{expanded, terms, groups, result},
  expanded = Expand[expression];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  groups = GatherBy[specialNativeTerm[#, u, ass] & /@ terms, First];
  result = Function[group, Module[{rows, alpha, carrier = group[[1, 1]], oscillatory},
    rows = GatherBy[group, #[[2]] &];
    rows = {#[[1, 2]], specialNativeTry[FullSimplify[Total[#[[All, 3]]], ass && u > 0]]} & /@ rows;
    If[! FreeQ[rows, $Failed], fail["ResourceLimit", "Native amplitude simplification exceeded its time budget."]];
    rows = orderedWeightGroups[Select[rows, #[[2]] =!= 0 &]];
    rows = If[Length[#] === 1, First[#], {#[[1, 1]],
      specialNativeTry[FullSimplify[Total[#[[All, 2]]], ass && u > 0]]}] & /@ rows;
    If[! FreeQ[rows, $Failed], fail["ResourceLimit", "Native amplitude simplification exceeded its time budget."]];
    rows = Select[rows, #[[2]] =!= 0 &];
    If[rows === {}, Return[Nothing, Module]];
    oscillatory = ! FreeQ[rows, (Sin | Cos)[_]];
    alpha = If[carrier =!= 1 || oscillatory, rows[[1, 1]], 0];
    <|"Carrier" -> carrier u^alpha, "OriginalCarrier" -> carrier, "LeadingPower" -> alpha,
      "Rows" -> ({canon[#[[1]] - alpha], #[[2]], specialNativeCoefficientDegree[#[[2]], u, ass]} & /@ rows),
      "Oscillatory" -> oscillatory|>]] /@ groups;
  result];

specialNativeExactPart[source_, u_, ass_] := Module[{pieces, accepted = {}, sectors, phases},
  pieces = If[Head[source] === Plus, List @@ source, {source}];
  Do[
    If[specialNativeCandidateQ[piece, u], Continue[]];
    sectors = catch[specialNativeSectors[piece, u, ass]];
    If[! ListQ[sectors], Continue[]];
    phases = Cases[piece, Power[E, phase_] | (Sin | Cos)[phase_] :> phase, {0, Infinity}];
    If[AllTrue[Select[phases, ! FreeQ[#, u] &],
        MemberQ[{Infinity, -Infinity}, specialNativeTry[Limit[#, u -> 0,
          Direction -> "FromAbove", Assumptions -> ass]]] &], AppendTo[accepted, piece]],
    {piece, pieces}];
  Total[accepted]];

specialNativeTruncate[sectors_, u_, cut_, goal_, ass_] := Module[
  {expression = 0, remainder = 0, result = {}, rows, kept, omitted, frontier, degree, threshold},
  Do[
    rows = sector["Rows"]; threshold = cut;
    If[cut === Automatic, threshold = If[Length[rows] > goal, rows[[goal + 1, 1]], Infinity]];
    kept = Select[rows, less[#[[1]], threshold] &];
    If[IntegerQ[goal] && Length[kept] > goal, kept = Take[kept, goal]];
    omitted = Drop[rows, Length[kept]];
    expression += sector["Carrier"] Total[u^#[[1]] #[[2]] & /@ kept];
    frontier = If[omitted === {}, Missing["NativeFrontier"], First[omitted]];
    If[omitted =!= {},
      degree = Max[omitted[[All, 3]]];
      remainder += specialNativeAbs[sector["Carrier"], u, ass] PowerLogRemainder[u, First[omitted][[1]], degree]];
    AppendTo[result, Join[sector, <|"Rows" -> kept, "Cutoff" -> threshold, "Frontier" -> frontier|>]],
    {sector, sectors}];
  <|"Expression" -> expression, "Remainder" -> remainder, "Sectors" -> result|>];

specialNativeOrderedResult[truncated_, remainder_, u_, x_, coord_, ass_, domain_, limit_] := Module[
  {sectors = truncated["Sectors"], sector, ell = Unique["nativeLog$"], bound, envelope, precision,
    rows, representation},
  If[Length[sectors] =!= 1 || TrueQ[First[sectors]["Oscillatory"]], Return[$Failed, Module]];
  sector = First[sectors];
  rows = ({#[[1]], #[[2]] /. Log[u] -> ell} & /@ sector["Rows"]);
  If[! FreeQ[rows, u], Return[$Failed, Module]];
  If[remainder === 0, precision = {Infinity, 0},
    bound = specialNativeTry[FullSimplify[specialNativeBound[remainder]/Abs[sector["Carrier"]], ass && u > 0]];
    If[bound === $Failed, Return[$Failed, Module]];
    envelope = catch[exactJet[bound, u, ell, ass, limit]];
    If[! MatchQ[envelope, {_List, Infinity, _}] || envelope[[1]] === {}, Return[$Failed, Module]];
    precision = {envelope[[1, 1, 1]], polyDegree[envelope[[1, 1, 2]], ell]}];
  representation = <|"Variable" -> x, "ScaleVariable" -> coord["LocalVariable"],
    "LogVariable" -> ell, "Assumptions" -> ass, "Domain" -> domain,
    "Offset" -> 0, "Prefactor" -> (sector["Carrier"] /. u -> coord["LocalVariable"]),
    "Jet" -> {rows, precision[[1]], precision[[2]]}, "Cutoff" -> sector["Cutoff"],
    "RemainderDerivativeOrder" -> If[remainder === 0, Infinity, 0]|>;
  seriesMake[representation, {"NativeSpecialFunctionExpansion", {}}, Automatic]];

specialFunctionForwardExpansion[f_, x_, x0_, cut_, ass_, coord_, goal_, limit_] := Module[
  {domain, normalized, source, u = coord["u"], order, raw, data, expression, sectors,
    truncated, remainder, work = 0, enough, exact, result, restored, localDomain,
    exactPart, uncertainExpression, uncertainSectors, uncertainCarriers, ordinary},
  If[! specialNativeCandidateQ[f, x], Return[$Failed, Module]];
  validateInput[f, limit];
  If[goal =!= Automatic && (! IntegerQ[goal] || goal < 1),
    fail["InvalidTermGoal", "SeriesTermGoal must be a positive integer or Automatic."]];
  If[cut === Automatic,
    If[! IntegerQ[goal] || goal < 1, fail["InvalidCutoff", "Give an exponent cutoff or SeriesTermGoal -> n."]],
    If[! exactRealQ[cut], fail["InvalidCutoff", "The cutoff must be an exact real number."]]];
  domain = specialFunctionRealDomain[f, x, coord, ass, limit];
  If[! AssociationQ[domain], fail["UnprovedSpecialFunctionDomain", "The special-function expression must have a proved real branch on the requested approach."]];
  normalized = specialFunctionNormalize[f, x, coord, ass, limit];
  If[! MemberQ[{Infinity, -Infinity}, x0],
    ordinary = Quiet[TimeConstrained[catch[forwardCore[normalized["Expression"], x, x0, cut,
      Assumptions -> ass, Direction -> coord["Direction"], SeriesTermGoal -> goal, "MaxTerms" -> limit]], 30, $Failed]];
    If[MatchQ[ordinary, _GeneralizedSeries], Return[GeneralizedSeries[Join[ordinary[[1]],
      <|"Function" -> f, "TargetDomain" -> domain["Domain"] && normalized["Domain"],
        "RealDomainProof" -> domain, "NormalizedExpression" -> normalized["Expression"]|>]], Module]]];
  localDomain = ass && ((domain["Domain"] && normalized["Domain"]) /. x -> coord["Substitution"]);
  source = normalized["Expression"] /. x -> coord["Substitution"];
  exactPart = specialNativeExactPart[source, u, ass];
  order = If[cut === Automatic, Max[3, goal + 1], Max[3, Ceiling[cut] + 2]];
  While[True,
    If[++work > 8 || order + 1 > limit, fail["ResourceLimit", "Native special-function expansion exceeded its working-order budget."]];
    raw = Quiet[TimeConstrained[Series[source - exactPart, {u, 0, order}, Assumptions -> ass && u > 0,
      Analytic -> False], 30, $Failed]];
    If[raw === $Failed || ! FreeQ[raw, _Series], fail["UnsupportedSpecialFunctionExpansion", "Wolfram Series did not supply a structured expansion on this approach."]];
    raw = Refine[raw, localDomain && u > 0];
    data = specialNativeTree[raw, u, ass, limit];
    uncertainExpression = specialNativeReal[data[[1]], u, ass] /. {
      HoldPattern[Sinh[z_]] :> (Exp[z] - Exp[-z])/2,
      HoldPattern[Cosh[z_]] :> (Exp[z] + Exp[-z])/2};
    uncertainSectors = specialNativeSectors[uncertainExpression, u, ass];
    uncertainCarriers = Lookup[uncertainSectors, "OriginalCarrier", {}];
    expression = uncertainExpression + exactPart;
    sectors = If[exactPart === 0, uncertainSectors, specialNativeSectors[expression, u, ass]];
    exact = TrueQ[specialNativeTry[FullSimplify[source == expression, localDomain && u > 0]]];
    If[FreeQ[raw, _SeriesData] && ! exact,
      fail["UnresolvedNativeSeries", "A finite native result without a remainder is accepted only after exact equality with the source is established."]];
    enough = exact || (sectors =!= {} && uncertainSectors =!= {} && (cut =!= Automatic || AllTrue[sectors,
      Length[#["Rows"]] > goal || ! MemberQ[uncertainCarriers, #["OriginalCarrier"]] ||
      (#["OriginalCarrier"] === 1 && FreeQ[Total[#["Rows"][[All, 2]]], u] &&
        And @@ (# == 0 & /@ #["Rows"][[All, 1]])) &]));
    If[enough,
      truncated = specialNativeTruncate[sectors, u, cut, goal, ass];
      If[! exact, enough = truncated["Remainder"] =!= 0 &&
        specialNativeSmallQ[data[[2]]/specialNativeBound[truncated["Remainder"]], u, ass]]];
    If[enough, Break[]]; order = 2 order + 1];
  (* A nonexact exit has already proved the native error negligible beside
     this truncation's remainder. Reuse that accepted bound and its proof. *)
  remainder = truncated["Remainder"];
  restored = {u -> coord["LocalVariable"]};
  result = specialNativeOrderedResult[truncated, remainder, u, x, coord, ass,
    domain["Domain"] && normalized["Domain"], limit];
  If[result === $Failed, result = seriesEnvelopeMake[truncated["Expression"] /. restored, remainder /. restored,
    <|"Variable" -> x, "Assumptions" -> ass, "Domain" -> domain["Domain"] && normalized["Domain"],
      "Approach" -> <|"Variable" -> x, "Point" -> x0, "Direction" -> coord["Direction"]|>|>,
    <|"Operation" -> "NativeSpecialFunctionExpansion", "Source" -> f|>, limit]];
  GeneralizedSeries[Join[result[[1]], <|"Kind" -> "Forward", "Function" -> f,
    "Expression" -> Refine[result["Expression"], ass && domain["Domain"] && normalized["Domain"]],
    "Remainder" -> Refine[result["Remainder"], ass && domain["Domain"] && normalized["Domain"]],
    "RemainderScaleExpression" -> Refine[result["RemainderScaleExpression"], ass && domain["Domain"] && normalized["Domain"]],
    "ExpansionPoint" -> x0, "Direction" -> coord["Direction"],
    "NativeSectors" -> (truncated["Sectors"] /. restored), "NativeSeriesOrder" -> order,
    "NormalizedExpression" -> normalized["Expression"], "RequestedCutoff" -> cut,
    "RequestedTermGoal" -> goal, "ReturnedTermCount" -> Total[Length[#["Rows"]] & /@ truncated["Sectors"]],
    "ExpansionNature" -> "Poincare", "NativeSeriesBackend" -> "Wolfram Series with Analytic -> False",
    "ExactSourceEqualityVerified" -> exact, "RealDomainProof" -> domain,
    "TermConvention" -> "Each exact carrier has an amplitude in powers of the positive local coordinate with polynomial logarithms and bounded oscillations. Cutoffs and term goals apply separately to amplitude blocks; exact constant offsets are retained. Oscillatory and distinct exponential sectors retain separate absolute error bounds.",
    "AsymptoticReferences" -> Join[Lookup[domain, "References", {}], normalized["References"],
      {"https://reference.wolfram.com/language/ref/Series.html", "https://dlmf.nist.gov/2.1.iii"}]|>]]];
(* END SOURCE: src/Kernel/NativeSpecialFunctions.wl *)

(* BEGIN SOURCE: src/Kernel/NativeCompatibility.wl
   Source SHA256 (UTF-8/LF): b4d385be5f39b86e174f58a59d53133f63dd90651f9b34fcd5e14f5058e6a3e9 *)
(* Native delegation is a distinct result contract. Keep the complete native
   call held until it is released to the selected built-in. In particular,
   do not resolve native delayed options for a second metadata lookup. *)

Options[AsymptoticExpansion] = DeleteDuplicatesBy[Join[
  Options[AsymptoticExpansion], {"Backend" -> Automatic},
  Options[System`Series], Options[System`Asymptotic]], First];
Options[AsymptoticExpand] = Options[AsymptoticExpansion];
SetAttributes[AsymptoticExpand, HoldAllComplete];
AsymptoticExpand[args___] := AsymptoticExpansion[args];

nativeSeriesQ[GeneralizedSeries[a_Association]] := Lookup[a, "Kind", None] === "Native";
nativeSeriesQ[_] := False;
requireAnalyticSeries[s_] := If[nativeSeriesQ[s],
  fail["NativeSeriesContract", "This operation requires a package analytic remainder contract. Use NativeResult for native formal operations."]];
nativeSeriesValue[a_Association, value_] := catch[Module[{variable = Lookup[a, "Variable", None]},
  If[! MatchQ[variable, _Symbol], fail["NativeVariables",
    "Numerical application requires one identified expansion variable. Substitute into Normal[result] explicitly for other native specifications."]];
  a["Expression"] /. variable -> value]];

nativeHeldArguments[held_HoldComplete] := Cases[held, item_ :> HoldComplete[item], {1}];
nativeSequenceArguments[HoldComplete[Sequence[args___]]] :=
  Flatten[nativeSequenceArguments /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSequenceArguments[held_HoldComplete] := {held};
nativeTailArguments[request_HoldComplete] :=
  Flatten[nativeSequenceArguments /@ Rest[nativeHeldArguments[request]], 1];
nativeHeldJoin[items_List] := Fold[
  Function[{left, right}, Replace[{left, right},
    {HoldComplete[a___], HoldComplete[b___]} :> HoldComplete[a, b]]], HoldComplete[], items];

(* Only option containers are traversed. A rule inside the source or inside
   another option's value is data, not a selector for this wrapper. *)
nativeOptionTreeQ[HoldComplete[_Rule | _RuleDelayed]] := True;
nativeOptionTreeQ[HoldComplete[(List | Sequence)[args___]]] :=
  And @@ (nativeOptionTreeQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeOptionTreeQ[_] := False;
nativeSelectorValues[HoldComplete[(Rule | RuleDelayed)["Backend", value_]]] := {HoldComplete[value]};
nativeSelectorValues[HoldComplete[Sequence[args___]]] :=
  Flatten[nativeSelectorValues /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSelectorValues[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativeSelectorValues /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeSelectorValues[_] := {};
nativeStripSelector[HoldComplete[(Rule | RuleDelayed)["Backend", _]]] := HoldComplete[Sequence[]];
nativeStripSelector[HoldComplete[Sequence[args___]]] :=
  Replace[nativeHeldJoin[nativeStripSelector /@ nativeHeldArguments[HoldComplete[args]]],
    HoldComplete[items___] :> HoldComplete[Sequence[items]]];
nativeStripSelector[held : HoldComplete[List[args___]]] /; nativeOptionTreeQ[held] := Module[{items},
  items = DeleteCases[nativeStripSelector /@ nativeHeldArguments[HoldComplete[args]], HoldComplete[Sequence[]]];
  If[items === {} && nativeHeldArguments[HoldComplete[args]] =!= {}, Return[HoldComplete[Sequence[]], Module]];
  Replace[nativeHeldJoin[items], HoldComplete[kept___] :> HoldComplete[List[kept]]]];
nativeStripSelector[held_] := held;

(* Resolve computed trailing argument containers before selecting a backend,
   keeping the source held for that backend's evaluation context. Literal
   native requests bypass this preparation altogether. *)
nativeComputedArgumentQ[HoldComplete[_Rule | _RuleDelayed]] := False;
nativeComputedArgumentQ[HoldComplete[{x_Symbol, _, ___}]] /; OwnValues[x] === {} := False;
nativeComputedArgumentQ[HoldComplete[List[args___]]] :=
  Or @@ (nativeComputedArgumentQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeComputedArgumentQ[HoldComplete[Sequence[args___]]] :=
  Or @@ (nativeComputedArgumentQ /@ nativeHeldArguments[HoldComplete[args]]);
nativeComputedArgumentQ[_] := True;
SetAttributes[expansionHeldEntry, HoldAllComplete];
expansionHeldEntry[args___] := expansionDispatch[HoldComplete[args], False];
expansionPreparedEntry[original_HoldComplete, source_HoldComplete, args___] :=
  expansionDispatch[nativeHeldJoin[{source, HoldComplete[args]}], True, original];
expansionDispatch[request_HoldComplete, prepared_, original_: Automatic] := Module[
  {parts = nativeHeldArguments[request], values, backend, clean, sourceRequest},
  If[parts === {}, Return[catch[forwardEntry[]], Module]];
  sourceRequest = If[original === Automatic, request, original];
  values = Flatten[nativeSelectorValues /@ Rest[parts], 1];
  If[! TrueQ[prepared] && Or @@ (nativeComputedArgumentQ /@ Rest[parts]),
    Return[Replace[request, HoldComplete[f_, args___] :>
      expansionPreparedEntry[sourceRequest, HoldComplete[f], args]], Module]];
  backend = If[values === {}, Automatic, ReleaseHold[First[values]]];
  clean = nativeHeldJoin[Prepend[nativeStripSelector /@ Rest[parts], First[parts]]];
  Switch[backend,
    "Series" | "Asymptotic", nativeExpansion[clean, backend, sourceRequest],
    Automatic, automaticExpansion[clean, sourceRequest],
    "Package", packageExpansion[clean],
    _, Failure["InvalidBackend", <|"MessageTemplate" -> "Backend must be Automatic, Package, Series, or Asymptotic.", "Backend" -> backend|>]]];

nativeSpecificationVariable[HoldComplete[{x_Symbol, _, ___}]] := HoldComplete[x];
nativeSpecificationVariable[HoldComplete[(Rule | RuleDelayed)[x_Symbol, _]]] := HoldComplete[x];
nativeSpecificationVariable[_] := Missing["NotLiteralSpecification"];
nativeSpecificationQ[HoldComplete[{_Symbol, _, ___}]] := True;
nativeSpecificationQ[HoldComplete[(Rule | RuleDelayed)[key_Symbol, _]]] :=
  ! MemberQ[First /@ Options[AsymptoticExpansion], Unevaluated[key]];
nativeSpecificationQ[_] := False;
nativePackageOption[HoldComplete[(Rule | RuleDelayed)[key : ("MaxTerms" | "InverseFunctionBranches"), _]]] := {key};
nativePackageOption[held : HoldComplete[(List | Sequence)[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativePackageOption /@ nativeHeldArguments[HoldComplete[args]]];
nativePackageOption[_] := {};

nativeOptionKeys[HoldComplete[(Rule | RuleDelayed)[key_, _]]] := {HoldComplete[key]};
nativeOptionKeys[held : HoldComplete[(List | Sequence)[args___]]] /; nativeOptionTreeQ[held] :=
  Flatten[nativeOptionKeys /@ nativeHeldArguments[HoldComplete[args]], 1];
nativeOptionKeys[_] := {};
nativeRequestOptionKeys[request_HoldComplete] := DeleteDuplicates[Flatten[
  nativeOptionKeys /@ Select[nativeTailArguments[request], ! nativeSpecificationQ[#] &], 1]];

$packageExpansionOptionKeys = {HoldComplete[Assumptions], HoldComplete[Direction],
  HoldComplete[SeriesTermGoal], HoldComplete["MaxTerms"], HoldComplete["InverseFunctionBranches"]};
nativeExclusiveOptionKeys[request_HoldComplete] := Complement[
  nativeRequestOptionKeys[request], $packageExpansionOptionKeys];
packageExpansion[request_HoldComplete] := Replace[request,
  HoldComplete[f_, args___] :> catch[packageEvaluatedEntry[forwardHeldExpression[f], args]]];
packageEvaluatedEntry[args___] := packagePreparedExpansion[HoldComplete[args]];
packagePreparedExpansion[request_HoldComplete] := Module[{extra = nativeExclusiveOptionKeys[request]},
  If[extra =!= {}, Return[Failure["UnsupportedOption", <|
    "MessageTemplate" -> "The package analytic engine does not implement these native options. Select a compatible native backend or Automatic.",
    "Options" -> extra|>], Module]];
  Replace[request, HoldComplete[args___] :> catch[forwardEntry[args]]]];

(* Native-only options must be dispatched before an otherwise successful
   package calculation can silently ignore them. No backend may discard an
   explicit branch, direction, or resource contract to obtain a result. *)
automaticProtectedQ[request_HoldComplete, original_HoldComplete] :=
  ! FreeQ[First[nativeHeldArguments[original]], _InverseFunction | _Function | _ConditionalExpression | _GeneralizedSeries | _PowerLogRemainder] ||
  ! FreeQ[First[nativeHeldArguments[request]], _InverseFunction | _Function | _ConditionalExpression | _forwardCallable | _GeneralizedSeries | _PowerLogRemainder] ||
  Intersection[nativeRequestOptionKeys[request],
    {HoldComplete[Direction], HoldComplete["MaxTerms"], HoldComplete["InverseFunctionBranches"]}] =!= {};

automaticNativeBackend[request_HoldComplete] := Module[{keys, series, asymptotic, specifications},
  keys = nativeExclusiveOptionKeys[request];
  series = HoldComplete /@ (First /@ Options[System`Series]);
  asymptotic = HoldComplete /@ (First /@ Options[System`Asymptotic]);
  If[keys =!= {}, Return[Which[
    Complement[keys, series] === {}, "Series",
    Complement[keys, asymptotic] === {}, "Asymptotic",
    True, Failure["NativeOptionConflict", <|
      "MessageTemplate" -> "No native backend supports all the supplied option keys.", "Options" -> keys|>]], Module]];
  specifications = Select[nativeTailArguments[request], nativeSpecificationQ];
  If[MatchQ[specifications, {HoldComplete[{_Symbol, _, Infinity | DirectedInfinity[1]}]}],
    Return["Asymptotic", Module]];
  If[MatchQ[specifications, {HoldComplete[{_Symbol, _, _}]}] || Length[specifications] > 1,
    "Series", "Asymptotic"]];

automaticNativeBackends[request_HoldComplete] := Module[{preferred, keys, candidates},
  preferred = automaticNativeBackend[request];
  If[FailureQ[preferred], Return[preferred, Module]];
  keys = nativeRequestOptionKeys[request];
  candidates = Select[{"Series", "Asymptotic"}, Function[backend,
    Complement[keys, HoldComplete /@ (First /@ Options[
      If[backend === "Series", System`Series, System`Asymptotic]])] === {}]];
  DeleteDuplicates[Prepend[DeleteCases[candidates, preferred], preferred]]];

(* Two native attempts share effective common options. In particular, a
   delayed option is not another program to run when retrying the request.
   OptionValue preserves first-option precedence; unused duplicate delayed
   values are not evaluated. Explicit and native-exclusive paths bypass this. *)
automaticNativeOption[HoldComplete[(Rule | RuleDelayed)[key : (Assumptions | SeriesTermGoal), _]], values_] :=
  With[{value = Lookup[values, key]}, HoldComplete[key -> value]];
automaticNativeOption[HoldComplete[Sequence[args___]], values_] :=
  Replace[nativeHeldJoin[automaticNativeOption[#, values] & /@
      nativeHeldArguments[HoldComplete[args]]], HoldComplete[items___] :> HoldComplete[Sequence[items]]];
automaticNativeOption[held : HoldComplete[List[args___]], values_] /; nativeOptionTreeQ[held] :=
  Replace[nativeHeldJoin[automaticNativeOption[#, values] & /@
      nativeHeldArguments[HoldComplete[args]]], HoldComplete[items___] :> HoldComplete[List[items]]];
automaticNativeOption[held_, _] := held;

automaticNativeSearchRequest[request_HoldComplete] := Module[{keys, options, values = <||>, ambient, parts},
  keys = nativeRequestOptionKeys[request];
  If[Intersection[keys, {HoldComplete[Assumptions], HoldComplete[SeriesTermGoal]}] === {},
    Return[request, Module]];
  options = Flatten[ReleaseHold /@ Select[nativeTailArguments[request],
    nativeOptionTreeQ[#] && ! nativeSpecificationQ[#] &]];
  ambient = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions];
  Block[{$Assumptions = ambient},
    If[MemberQ[keys, HoldComplete[Assumptions]],
      AssociateTo[values, Assumptions -> optionAssumptions[AsymptoticExpansion, options]]];
    If[MemberQ[keys, HoldComplete[SeriesTermGoal]],
      AssociateTo[values, SeriesTermGoal -> OptionValue[AsymptoticExpansion, options, SeriesTermGoal]]]];
  parts = nativeHeldArguments[request];
  nativeHeldJoin[Prepend[automaticNativeOption[#, values] & /@ Rest[parts], First[parts]]]];

nativeEvaluationStatus[result_] := Which[
  ! FreeQ[result, $Aborted], "Aborted",
  ! FreeQ[result, $Failed | _Failure], "Failed",
  ! FreeQ[result, _System`Series | _System`Asymptotic], "Unresolved",
  True, "Computed"];

automaticNativeResult[request_HoldComplete, original_HoldComplete, reason_, failure_: None] := Module[
  {backends, prepared, result, selected = None, attempts = {}, backend, status},
  backends = automaticNativeBackends[request];
  If[FailureQ[backends], Return[backends, Module]];
  prepared = If[Length[backends] > 1, automaticNativeSearchRequest[request], request];
  Do[
    result = nativeExpansion[prepared, backend, original];
    If[selected === None, selected = result];
    status = If[MatchQ[result, _GeneralizedSeries], result["NativeEvaluationStatus"], "Failed"];
    AppendTo[attempts, <|"Backend" -> backend, "EvaluationStatus" -> status,
      "Request" -> If[MatchQ[result, _GeneralizedSeries], result["NativeRequest"], Missing["NotDelegated"]]|>];
    If[MemberQ[{"Computed", "Aborted"}, status], selected = result; Break[]],
    {backend, backends}];
  If[! MatchQ[selected, _GeneralizedSeries], Return[selected, Module]];
  GeneralizedSeries[Join[selected[[1]], <|"BackendSelection" -> Automatic,
    "BackendSelectionReason" -> reason, "OrderConvention" -> "Native",
    "PackageFailure" -> failure, "NativeAttempts" -> attempts|>]]];

(* Ordinary argument evaluation happens once at this entry, under the same
   neutral proof context as the established package entry. The resulting
   source and specifications, not their original programs, are reused after
   a representation failure. Literal explicit native calls never enter it. *)
automaticExpansion[request_HoldComplete, original_HoldComplete] := Module[{extra},
  If[automaticProtectedQ[request, original], Return[packageExpansion[request], Module]];
  extra = nativeExclusiveOptionKeys[request];
  If[extra =!= {}, Return[automaticNativeResult[request, original, "NativeOptions"], Module]];
  Replace[request, HoldComplete[f_, args___] :>
    catch[automaticEvaluatedEntry[original, forwardHeldExpression[f], args]]]];
automaticEvaluatedEntry[original_HoldComplete, args___] :=
  automaticPreparedExpansion[HoldComplete[args], original];

automaticNativeShapeQ[request_HoldComplete] := Module[{parts, specifications, center, order},
  parts = nativeHeldArguments[request];
  specifications = Select[Rest[parts], nativeSpecificationQ];
  If[specifications === {}, Return[False, Module]];
  If[Length[specifications] > 1, Return[True, Module]];
  If[MatchQ[First[parts], HoldComplete[_List]] || ! FreeQ[First[parts], _Inactive], Return[True, Module]];
  If[MatchQ[First[specifications], HoldComplete[_RuleDelayed]], Return[True, Module]];
  center = Replace[First[specifications], {
    HoldComplete[{_, point_, ___}] :> point,
    HoldComplete[(Rule | RuleDelayed)[_, point_]] :> point}];
  If[! MemberQ[{Infinity, -Infinity}, center] && ! exactRealQ[center], Return[True, Module]];
  order = Replace[First[specifications], {HoldComplete[{_, _, n_}] :> n, _ :> Automatic}];
  If[order =!= Automatic, Return[! exactRealQ[order], Module]];
  ! MemberQ[nativeRequestOptionKeys[request], HoldComplete[SeriesTermGoal]]];

(* These tags describe limitations of the real power-log representation.
   Domain, inverse branch, arithmetic budget and invalid-option failures are
   deliberately absent. A failed analytic proof is never reused as native
   analytic evidence. *)
$automaticNativeRepresentationFailures = {"InexactInput", "UnprovedRealCoefficient",
  "UnsupportedInput", "UnsupportedCoefficient", "SymbolicExponent", "ComplexExponent",
  "LogarithmicLeadingPower", "ExponentialScale", "UnsupportedNumber", "InfiniteSeries"};

automaticPreparedExpansion[request_HoldComplete, original_HoldComplete] := Module[
  {parts, specifications, options, keys, ass, dir, goal, limit, branches, packageRequest, replay, result},
  If[automaticProtectedQ[request, original], Return[packageExpansion[request], Module]];
  If[nativeExclusiveOptionKeys[request] =!= {},
    Return[automaticNativeResult[request, original, "NativeOptions"], Module]];
  If[automaticNativeShapeQ[request],
    Return[automaticNativeResult[request, original, "NativeSpecification"], Module]];
  parts = nativeHeldArguments[request];
  specifications = Select[Rest[parts], nativeSpecificationQ];
  options = Flatten[ReleaseHold /@ Select[Rest[parts], ! nativeSpecificationQ[#] &]];
  keys = nativeRequestOptionKeys[request];
  ass = optionAssumptions[AsymptoticExpansion, options];
  dir = OptionValue[AsymptoticExpansion, options, Direction];
  goal = OptionValue[AsymptoticExpansion, options, SeriesTermGoal];
  limit = OptionValue[AsymptoticExpansion, options, "MaxTerms"];
  branches = OptionValue[AsymptoticExpansion, options, "InverseFunctionBranches"];
  (* Native rule-form leading requests admit Automatic and nonpositive
     integer goals even though those are not package nonzero-block counts.
     Reuse the common values already consumed above, including delayed ones. *)
  If[MatchQ[specifications, {HoldComplete[_Rule]}] &&
      MemberQ[keys, HoldComplete[SeriesTermGoal]] &&
      (goal === Automatic || (IntegerQ[goal] && goal <= 0)),
    replay = nativeHeldJoin[Prepend[automaticNativeOption[#, <|
      Assumptions -> ass, SeriesTermGoal -> goal|>] & /@ Rest[parts], First[parts]]];
    Return[automaticNativeResult[replay, original, "NativeSpecification"], Module]];
  packageRequest = nativeHeldJoin[Join[Take[parts, 1], specifications,
    With[{a = ass, d = dir, g = goal, m = limit, b = branches},
      {HoldComplete[Assumptions -> a], HoldComplete[Direction -> d],
        HoldComplete[SeriesTermGoal -> g], HoldComplete["MaxTerms" -> m],
        HoldComplete["InverseFunctionBranches" -> b]}]]];
  result = Replace[packageRequest, HoldComplete[args___] :> catch[forwardEntry[args]]];
  If[! FailureQ[result] || ! MemberQ[$automaticNativeRepresentationFailures, result[[1]]], Return[result, Module]];
  (* Only common native options are replayed. Their delayed values have been
     consumed once above; omitted native defaults remain the native defaults. *)
  replay = nativeHeldJoin[Join[Take[parts, 1], specifications,
    With[{a = ass}, {HoldComplete[Assumptions -> a]}],
    If[MemberQ[keys, HoldComplete[SeriesTermGoal]], With[{g = goal}, {HoldComplete[SeriesTermGoal -> g]}], {}]]];
  automaticNativeResult[replay, original, "PackageRepresentation", result]];

nativeExpansion[request_HoldComplete, backend_, original_HoldComplete] := Module[
  {call, result, normal, parts, specifications, variables, variable, conflicts, ambient},
  parts = nativeTailArguments[request];
  conflicts = Flatten[nativePackageOption /@ parts];
  If[conflicts =!= {}, Return[Failure["NativeOptionConflict", <|
    "MessageTemplate" -> "Package resource budgets and inverse branch selectors require Backend -> Package; native delegation does not implement these options.",
    "Options" -> DeleteDuplicates[conflicts]|>], Module]];
  call = If[backend === "Series",
    Replace[request, HoldComplete[args___] :> HoldComplete[System`Series[args]]],
    Replace[request, HoldComplete[args___] :> HoldComplete[System`Asymptotic[args]]]];
  ambient = If[TrueQ[$assumptionScopeActive], $entryAssumptions, $Assumptions];
  result = Block[{$Assumptions = ambient}, ReleaseHold[call]];
  normal = Normal[result];
  specifications = Select[parts, nativeSpecificationQ];
  variables = DeleteDuplicates[Cases[nativeSpecificationVariable /@ specifications, _HoldComplete]];
  variable = If[Length[variables] === 1, ReleaseHold[First[variables]], Missing["MultipleOrUnresolvedVariables"]];
  GeneralizedSeries[<|"Kind" -> "Native", "Scale" -> "Native", "NativeBackend" -> backend,
    "NativeResult" -> result, "Expression" -> normal,
    "Remainder" -> Missing["NativeContract"], "Exact" -> Missing["NotEstablished"],
    "RemainderContract" -> If[backend === "Series", "NativeFormalOrder", "NativeAsymptotic"],
    "NativeEvaluationStatus" -> nativeEvaluationStatus[result],
    "NativeRequest" -> call, "OriginalArguments" -> original,
    "ExpansionSpecifications" -> specifications, "Variable" -> variable,
    "AmbientAssumptions" -> ambient, "Assumptions" -> Missing["NativeContract"],
    "NativeKernelVersion" -> $Version, "NativeSystemID" -> $SystemID|>]];
(* END SOURCE: src/Kernel/NativeCompatibility.wl *)

If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsCalculus.wl\n   Source SHA256 (UTF-8/LF): 5bfd1ceabc69951213036ebb83d9d2539763735aac5043dafc3de067f874d384 *)\n(* Loaded only by Mathics, after the ordinary analytic engines.\n   Mathics sends a symbolic Sum body to SymPy before substituting a finite\n   iterator. Derivative orders and Part indices must already be integers\n   when evaluated. Table binds those indices first and Total performs the\n   same exact finite sum; the official kernel retains its original code. *)\n\nDownValues[PerturbativeInverse] = {};",
"\nPerturbativeInverse[phi_, h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=\n  System`Module[{hy},\n    If[x === y || ! FreeQ[h, y],\n      Failure[\"InvalidVariables\", <|\"MessageTemplate\" -> \"Use distinct symbols; h must not contain y.\"|>],\n      hy = h /. x -> phi;\n      phi + Total[System`Table[(-1)^k/k! D[D[phi, y] hy^k, {y, k - 1}], {k, 1, n}]]]];",
"\nPerturbativeInverse[h_, {x_Symbol, y_Symbol}, n_Integer?NonNegative] :=\n  PerturbativeInverse[y, h, {x, y}, n];",
"\nPerturbativeInverse[___] := Failure[\"InvalidArguments\", <|\"MessageTemplate\" ->\n  \"Use PerturbativeInverse[phi, h, {x, y}, n] or PerturbativeInverse[h, {x, y}, n].\"|>];",
"\n\nlogarithmicEuler[e_, levels_] := -Total[System`Table[\n  D[e, levels[[j]]]/(Times @@ Take[levels, j - 1]), {j, Length[levels]}]];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsCoreFunctions.wl\n   Source SHA256 (UTF-8/LF): 9dd947a4cceed781642010f7f1deaef97281edd84b0660f3d83a84076568304d *)\n(* Loaded late in Private, only on Mathics. Mathics 10 passes the two\n   ProductLog arguments to mpmath in Wolfram order rather than mpmath order;\n   even N[ProductLog[0,E]] can therefore return -Infinity. The principal\n   branch has the exact one-argument spelling ProductLog[z]. Normalize at\n   each package construction site, before the builtin can see numeric data.\n   This neither changes System definitions nor asserts a numeric evaluator\n   for nonprincipal branches. Returned expressions keep the System head. *)\n\nClear[mathicsCoreProductLog];",
"\nmathicsCoreProductLog[0, argument_] := System`ProductLog[argument];",
"\nmathicsCoreProductLog[branch_, argument_] := System`ProductLog[branch, argument];",
"\nmathicsCoreProductLog[argument_] := System`ProductLog[argument];",
"\n\nScan[(DownValues[#] = DownValues[#] /.\n    System`ProductLog -> mathicsCoreProductLog) &,\n  {corePerturbationAutomaticInverse, exponentialCoreExactInverse,\n   lambertConstruct, specialThreshold}];",
"\n\n(* Preserve explicit user-selected core-check deadlines and the documented\n   five-second callable-evaluation guard. Only internal proof budgets receive\n   the interpreter-overhead allowance from MathicsTimeBudget.wl. *)\nScan[(DownValues[#] = DownValues[#] /.\n    AsymptoticAnalysis`Mathics`TimeConstrained -> System`TimeConstrained) &,\n  {corePerturbationChooseInverse, exponentialCoreExactInverse,\n   inverseFunctionApplicationData}];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsCertificate.wl\n   Source SHA256 (UTF-8/LF): 39d63b0414ff39d1fd89d546e5f06840fe603e36f41429417cc3f154279771b9 *)\n(* Loaded only by Mathics, after the certificate implementation.\n   Mathics 10 raises a Python IndexError when assigning to list[[-1]], even\n   for a nonempty one-element list. The certificate history is nonempty at\n   its update site. Its positive last index denotes exactly the same part.\n   Preserve the original interval algorithm, options, and failure paths. *)\n\nClearAll[mathicsCertificateSetLast];",
"\nSetAttributes[mathicsCertificateSetLast, HoldAll];",
"\n(* Keep the helper inert until the transformation has finished, so replacing\n   a held Set in a DownValue cannot execute that assignment during loading. *)\nDownValues[InverseCertificate] = DownValues[InverseCertificate] /.\n  HoldPattern[Set[Part[list_Symbol, -1], value_]] :>\n    mathicsCertificateSetLast[list, value];",
"\nmathicsCertificateSetLast[list_Symbol, value_] := (list[[Length[list]]] = value);"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsRefinement.wl\n   Source SHA256 (UTF-8/LF): 1f02dff6cad0e3c3d78d747daaac3fd950b82cb7a19f310c3bbf7dd3ca2b5551 *)\n(* Mathics-only late adapter. Association holds a mapped rule list without\n   evaluating it in Mathics 10. The refinement frontier must materialize its\n   rules before constructing the association. The finite-depth enumerator\n   needs the same evaluation order for its collected rule list. Keep these\n   rewrites local; the ordinary Wolfram definitions are never changed. *)\nClearAll[mathicsRefinementAssociation];",
"\nDownValues[refinementLagrangeSeed] = DownValues[refinementLagrangeSeed] /.\n  HoldPattern[Association[rules_Map]] :> mathicsRefinementAssociation[rules];",
"\nDownValues[depthRegion] = DownValues[depthRegion] /.\n  HoldPattern[Association[rules_Part]] :> mathicsRefinementAssociation[rules];",
"\nmathicsRefinementAssociation[rules_List] := Association @@ rules;"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsInverseBranches.wl\n   Source SHA256 (UTF-8/LF): 79ecef295c917a8a53c809b49e181f718811c9fe481693b440f3ca942d4ce022 *)\n(* Loaded late in Private, only on Mathics. Two bounded exact facts fill the\n   polynomial branch-inference path without emulating Reduce: a polynomial\n   with real constant coefficients is real on the whole real axis, and an\n   intersection of affine real half-lines is convex. The ordinary branch\n   validator still proves the source condition, limit, target side and local\n   derivative sign. Unsupported domains retain the conservative failure. *)\n\nmathicsPolynomialFunctionDomain[body_, x_Symbol, Reals] :=\n  If[PolynomialQ[body, x] && And @@ (exactRealQ /@ CoefficientList[body, x]),\n    True, System`FunctionDomain[body, x, Reals]];",
"\n\n(* Replace only this private consumer's unavailable FunctionDomain call.\n   No definition or attribute of a System symbol is changed. *)\nDownValues[inverseFunctionSelectBranchInternal] =\n  DownValues[inverseFunctionSelectBranchInternal] /.\n    System`FunctionDomain -> mathicsPolynomialFunctionDomain;",
"\n\nmathicsAffineRealExpressionQ[expression_, x_, ass_] :=\n  PolynomialQ[expression, x] && Exponent[expression, x] <= 1 &&\n    And @@ (TrueQ[FullSimplify[Element[#, Reals], ass]] & /@ CoefficientList[expression, x]);",
"\n\nmathicsConvexRealDomainQ[domain_, x_, ass_] := Module[{head = Head[domain], parts},\n  If[FreeQ[domain, x], Return[True, Module]];\n  If[head === And,\n    Return[And @@ (mathicsConvexRealDomainQ[#, x, ass] & /@ List @@ domain), Module]];\n  If[MemberQ[{Element, System`Element}, head],\n    Return[SameQ[domain[[1]], x] && SameQ[domain[[2]], Reals], Module]];\n  If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal}, head],\n    parts = List @@ domain;\n    If[head =!= Equal &&\n      ! And @@ (mathicsAffineRealExpressionQ[#, x, ass] & /@ parts), Return[False, Module]];\n    Return[And @@ (mathicsAffineRealExpressionQ[Subtract @@ #, x, ass] & /@\n      Partition[parts, 2, 1]), Module]];\n  If[head === Inequality,\n    parts = List @@ domain;\n    If[! And @@ (MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal}, #] & /@\n        parts[[2 ;; -1 ;; 2]]), Return[False, Module]];\n    If[! And @@ (mathicsAffineRealExpressionQ[#, x, ass] & /@ parts[[1 ;; -1 ;; 2]]),\n      Return[False, Module]];\n    Return[And @@ (mathicsAffineRealExpressionQ[Subtract @@ #, x, ass] & /@\n      Partition[parts[[1 ;; -1 ;; 2]], 2, 1]), Module]];\n  False];",
"\n\n(* Retain the existing general proof path as a fallback. Clear the dispatch\n   symbol before installing its wrapper: Mathics otherwise evaluates an old\n   definition while reading the left-hand side of a new definition. *)\nIf[DownValues[mathicsOriginalGlobalMonotonicity] === {},\n  DownValues[mathicsOriginalGlobalMonotonicity] =\n    DownValues[inverseBranchGlobalMonotonicity] /.\n      inverseBranchGlobalMonotonicity -> mathicsOriginalGlobalMonotonicity];",
"\nClear[inverseBranchGlobalMonotonicity];",
"\ninverseBranchGlobalMonotonicity[body_, x_, domain_, ass_] := Module[\n  {derivative = D[body, x], positive, negative},\n  If[! PolynomialQ[body, x] || ! mathicsConvexRealDomainQ[domain, x, ass],\n    Return[mathicsOriginalGlobalMonotonicity[body, x, domain, ass], Module]];\n  positive = inverseBranchTry[FullSimplify[derivative > 0,\n    ass && domain && Element[x, Reals]]];\n  If[TrueQ[positive],\n    Return[<|\"Type\" -> \"StrictDerivativeOnRealInterval\", \"Sign\" -> 1,\n      \"Domain\" -> domain, \"Derivative\" -> derivative|>, Module]];\n  negative = inverseBranchTry[FullSimplify[derivative < 0,\n    ass && domain && Element[x, Reals]]];\n  If[TrueQ[negative],\n    Return[<|\"Type\" -> \"StrictDerivativeOnRealInterval\", \"Sign\" -> -1,\n      \"Domain\" -> domain, \"Derivative\" -> derivative|>, Module]];\n  None];",
"\n\n(* For an affine expression on 0<u<r, every value is a strict convex\n   combination of the endpoint values. This proves the whole deleted\n   interval, including strict inequalities with one zero endpoint. *)\nmathicsAffineIntervalRelation[left_, head_, right_, u_, ass_, radius_] := Module[\n  {difference = Expand[left - right], endpoints, nonnegative, nonpositive,\n   positive, negative, zero},\n  If[! mathicsAffineRealExpressionQ[difference, u, ass], Return[None, Module]];\n  If[MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head] &&\n    ! (TrueQ[FullSimplify[Element[left, Reals], ass && Element[u, Reals]]] &&\n       TrueQ[FullSimplify[Element[right, Reals], ass && Element[u, Reals]]]),\n    Return[None, Module]];\n  endpoints = {difference /. u -> 0, difference /. u -> radius};\n  nonnegative = And @@ (TrueQ[FullSimplify[# >= 0, ass]] & /@ endpoints);\n  nonpositive = And @@ (TrueQ[FullSimplify[# <= 0, ass]] & /@ endpoints);\n  positive = nonnegative && Or @@ (provablyPositive[#, ass] & /@ endpoints);\n  negative = nonpositive && Or @@ (provablyNegative[#, ass] & /@ endpoints);\n  zero = And @@ (TrueQ[FullSimplify[# == 0, ass]] & /@ endpoints);\n  Switch[head,\n    Greater, Which[positive, True, nonpositive, False, True, None],\n    GreaterEqual, Which[nonnegative, True, negative, False, True, None],\n    Less, Which[negative, True, nonnegative, False, True, None],\n    LessEqual, Which[nonpositive, True, positive, False, True, None],\n    Equal, Which[zero, True, positive || negative, False, True, None],\n    Unequal, Which[positive || negative, True, zero, False, True, None],\n    _, None]];",
"\n\nmathicsAffineIntervalTruth[predicate_, u_, ass_, radius_] := Module[\n  {head = Head[predicate], parts, truths},\n  If[predicate === True || predicate === False, Return[predicate, Module]];\n  (* Unequal with more than two operands asserts every pair is unequal;\n     the consecutive-pair reduction used for ordered chains is insufficient. *)\n  If[head === Unequal && Length[predicate] =!= 2, Return[None, Module]];\n  If[head === And,\n    truths = mathicsAffineIntervalTruth[#, u, ass, radius] & /@ List @@ predicate,\n    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head],\n      truths = mathicsAffineIntervalRelation[#[[1]], head, #[[2]], u, ass, radius] & /@\n        Partition[List @@ predicate, 2, 1],\n      If[head === Inequality,\n        parts = List @@ predicate;\n        truths = Table[mathicsAffineIntervalRelation[parts[[j]], parts[[j + 1]],\n          parts[[j + 2]], u, ass, radius], {j, 1, Length[parts] - 2, 2}],\n        Return[None, Module]]]];\n  Which[MemberQ[truths, False], False, And @@ (TrueQ /@ truths), True, True, None]];",
"\n\nIf[DownValues[mathicsOriginalBranchEventualQ] === {},\n  DownValues[mathicsOriginalBranchEventualQ] = DownValues[inverseBranchEventualQ] /.\n    inverseBranchEventualQ -> mathicsOriginalBranchEventualQ];",
"\nClear[inverseBranchEventualQ];",
"\ninverseBranchEventualQ[predicate_, u_, ass_, radius_] := Module[{truth},\n  If[exactRealQ[radius] && less[0, radius],\n    truth = mathicsAffineIntervalTruth[predicate, u, ass, radius];\n    If[truth === True || truth === False, Return[truth, Module]]];\n  mathicsOriginalBranchEventualQ[predicate, u, ass, radius]];",
"\n\n(* Proving one explicit positive neighborhood suffices for eventual truth.\n   Failure at any trial radius says nothing about smaller neighborhoods. *)\nIf[DownValues[mathicsOriginalFunctionEventually] === {},\n  DownValues[mathicsOriginalFunctionEventually] = DownValues[inverseFunctionEventually] /.\n    inverseFunctionEventually -> mathicsOriginalFunctionEventually];",
"\nClear[inverseFunctionEventually];",
"\ninverseFunctionEventually[condition_, u_, ass_] := Module[{simple},\n  simple = FullSimplify[condition, ass && u > 0];\n  If[simple === True || simple === False, Return[simple, Module]];\n  Do[If[TrueQ[mathicsAffineIntervalTruth[simple, u, ass, 2^-j]],\n    Return[True, Module]], {j, 0, 6}];\n  mathicsOriginalFunctionEventually[condition, u, ass]];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsSpecialFunctions.wl\n   Source SHA256 (UTF-8/LF): 78ab28f9dcf8f87f2a22413ebc263788552333a91f485c2edc2e126a1030383b *)\n(* Mathics does not implement the large-positive-argument LogGamma Series\n   used by the Wolfram path. Use the classical finite Stirling model in the\n   existing jet algebra. This is a Poincare expansion with an explicit tail,\n   never an exact or convergent power series. DLMF 5.11.1 and 5.11(ii). *)\n\nmathicsGrowingPositiveJetQ[rows_List, ell_, ass_] := rows =!= {} &&\n  less[rows[[1, 1]], 0] && FreeQ[rows[[1, 2]], ell] &&\n  provablyPositive[rows[[1, 2]], ass];",
"\n\n(* Mathics can evaluate an existing general definition while installing a\n   more specific left-hand side. Temporarily retain the rules as held data. *)\n$mathicsOriginalFwdAnalytic = DownValues[fwdAnalytic];",
"\nDownValues[fwdAnalytic] = {};",
"\nfwdAnalytic[LogGamma, {rows_List, precision_, degree_}, e_, u_, ell_, ass_, cutoff_, limit_] /;\n    mathicsGrowingPositiveJetQ[rows, ell, ass] := Module[\n  {argument = First[e], rate = -rows[[1, 1]], count, model, result},\n  If[cutoff === Infinity,\n    fail[\"InfiniteSeries\", \"The Gamma logarithm requires a finite Poincare working order.\"]];\n  count = Max[0, Ceiling[(cutoff/rate + 1)/2] - 1];\n  If[count + 1 > limit,\n    fail[\"ResourceLimit\", \"The Stirling Bernoulli tail exceeds MaxTerms.\"]];\n  model = (argument - 1/2) Log[argument] - argument + Log[2 Pi]/2 +\n    Total[Table[BernoulliB[2 k]/(2 k (2 k - 1) argument^(2 k - 1)), {k, 1, count}]];\n  result = fwd[model, u, ell, ass, cutoff, limit];\n  pAdd[result, {{}, (2 count + 1) rate, 0}, ell, ass]];",
"\nDownValues[fwdAnalytic] = Join[DownValues[fwdAnalytic], $mathicsOriginalFwdAnalytic];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsInputAssumptions.wl\n   Source SHA256 (UTF-8/LF): c82eea58c4a6d0a89488cd65c3b60949426cda821222bdfd3415842b1da6363e *)\n(* Mathics' native Element rules can weaken a symbolic membership condition:\n   Element[Sin[a],Reals] becomes Element[a,Reals], although a=Pi/2+I is a\n   counterexample to that equivalence. The package's held public entries can\n   preserve an inline assumption before ordinary option evaluation reaches\n   those rules. Already evaluated caller values cannot be reconstructed.\n\n   The private catch boundary is held and is entered by the analytic paths\n   before option evaluation. Literal explicit native backend calls bypass\n   it. Keep the established assumption scope and exception behavior in the\n   original held delegate; change only membership heads inside syntactic\n   Assumptions rule values. Position and ReplacePart operate on held trees,\n   so immediate and delayed option programs retain their evaluation count. *)\n\nClearAll[mathicsProtectInputAssumptions];",
"\nmathicsProtectInputAssumptions[held_HoldComplete] := If[\n  FreeQ[held, System`Element], held, System`Module[\n  {options, heads, positions},\n  options = Position[held,\n    HoldPattern[Rule[Assumptions, _] | RuleDelayed[Assumptions, _]],\n    {0, Infinity}, Heads -> False];\n  If[options === {}, held,\n  heads = Position[held, System`Element, {0, Infinity}, Heads -> True];\n  positions = Select[heads, Function[position,\n    Or @@ (Function[option,\n      Length[position] >= Length[option] + 1 &&\n        Take[position, Length[option] + 1] === Append[option, 2]] /@ options)]];\n  ReplacePart[held, (# -> AsymptoticAnalysis`Mathics`Element) & /@ positions]]]];",
"\n\nIf[DownValues[mathicsOriginalInputCatch] === {},\n  SetAttributes[mathicsOriginalInputCatch, HoldAll];\n  DownValues[mathicsOriginalInputCatch] = DownValues[catch] /.\n    catch -> mathicsOriginalInputCatch];",
"\nClear[catch];",
"\nSetAttributes[catch, HoldAll];",
"\ncatch[body_] := Replace[mathicsProtectInputAssumptions[HoldComplete[body]],\n  HoldComplete[protected_] :> mathicsOriginalInputCatch[protected]];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsLists.wl\n   Source SHA256 (UTF-8/LF): 1a05f146c5d7a1d26aa8d6d8cedb7b2e87524c9236ab2001a1105e44e896f962 *)\n(* Mathics 10.0.1 Map[f, emptyList] can corrupt that list's cached element\n   properties. Reusing it in a nested numeric list then raises a Python\n   AssertionError. For example, without this package:\n     b = {}; f /@ b; {b, 2, 0}\n   Mapping at the default first level of an empty list has no applications\n   of f and returns an empty list. Bypass only that exact case. Other inputs,\n   explicit levels, Heads options, and invalid arguments retain native Map.\n\n   This late adapter changes references in package-private definitions only;\n   the interpreter and System`Map definitions are untouched. *)\n\nClearAll[mathicsMap, mathicsInstallMap];",
"\nmathicsMap[function_, items_List] :=\n  If[items === {}, {}, System`Map[function, items]];",
"\nmathicsMap[args___] := System`Map[args];",
"\n\nSetAttributes[mathicsInstallMap, HoldAllComplete];",
"\nmathicsInstallMap[symbol_Symbol] :=\n  If[HoldComplete[symbol] =!= HoldComplete[mathicsMap] &&\n      HoldComplete[symbol] =!= HoldComplete[mathicsInstallMap] &&\n      ! FreeQ[DownValues[symbol], System`Map],\n    DownValues[symbol] = DownValues[symbol] /. System`Map -> mathicsMap];",
"\n\n(* Mathics ToExpression evaluates its parsed expression before applying the\n   optional third argument. Put the holding installer in the parsed text so\n   even symbols with effectful OwnValues stay unevaluated during inspection.\n   Names supplies only existing, fully qualified package-private symbols. *)\nScan[ToExpression[\"AsymptoticAnalysis`Private`mathicsInstallMap[\" <> # <> \"]\"] &,\n  Names[\"AsymptoticAnalysis`Private`*\"]];"
}]];
If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {
"(* BEGIN SOURCE: src/Kernel/MathicsFormatting.wl\n   Source SHA256 (UTF-8/LF): c0fe6dc19f67df7c3cae5f2f4f972acb0392472423b4103af0b3ec422a95df2c *)\n(* Loaded after the analytic engines, in AsymptoticAnalysis`Private`.\n   Mathics' TagSetDelayed cannot discover the tag beneath the named outer\n   pattern used by the ordinary-arithmetic API.  Direct UpValues assignment\n   installs those same patterns without changing any System definition. *)\n\nIf[StringQ[$Version] && StringContainsQ[$Version, \"Mathics\"], Block[{$seriesArithmeticEnabled = False},\n  mathicsArithmeticRules = {\n    HoldPattern[expression : Plus[___, s_GeneralizedSeries, ___] /;\n      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>\n      seriesArithmeticAutomatic[HoldComplete[expression]],\n    HoldPattern[expression : Times[___, s_GeneralizedSeries, ___] /;\n      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>\n      seriesArithmeticAutomatic[HoldComplete[expression]],\n    HoldPattern[expression : Power[s_GeneralizedSeries, _] /;\n      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>\n      seriesArithmeticAutomatic[HoldComplete[expression]],\n    HoldPattern[expression : Power[_, s_GeneralizedSeries] /;\n      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>\n      seriesArithmeticAutomatic[HoldComplete[expression]]\n  };\n  mathicsArithmeticRules = Join[mathicsArithmeticRules,\n    Function[head, With[{h = head},\n      HoldPattern[expression : h[s_GeneralizedSeries] /;\n        TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>\n        seriesArithmeticAutomatic[HoldComplete[expression]]]] /@\n    {Log, Exp, Abs, Sin, Cos, Tan, Sinh, Cosh, Tanh, ArcSin, ArcCos, ArcTan}];\n  (* Reading Mathics UpValues can add HoldPattern wrappers.  Remove our own\n     previous arithmetic rules structurally instead of relying on SameQ\n     deduplication, so repeated Get does not accumulate duplicate rules. *)\n  mathicsPreviousRules = DeleteDuplicates[UpValues[GeneralizedSeries] //.\n    Verbatim[HoldPattern][Verbatim[HoldPattern][pattern_]] :> HoldPattern[pattern]];\n  UpValues[GeneralizedSeries] = Join[\n    Select[mathicsPreviousRules,\n      FreeQ[#, HoldPattern[seriesArithmeticAutomatic[_HoldComplete]]] &],\n    mathicsArithmeticRules];\n  (* An explicit head avoids Mathics treating Pattern as the formatting tag. *)\n  Format[PowerLogRemainder[w_, b_, k_], OutputForm] :=\n    With[{sc = remainderScale[PowerLogRemainder[w, b, k]]}, HoldForm[O[sc]]]\n]];"
}]];

End[];
EndPackage[];

(* Mathics EndPackage retains contexts inserted while the package loads. Keep
   the adapters private to already-parsed package definitions. *)
If[StringContainsQ[$Version, "Mathics"],
  $ContextPath = DeleteCases[$ContextPath, "AsymptoticAnalysis`Mathics`"]];
(* END SOURCE: src/Kernel/AsymptoticAnalysis.wl *)
