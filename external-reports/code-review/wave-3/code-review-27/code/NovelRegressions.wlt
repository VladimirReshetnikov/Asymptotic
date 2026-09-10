(* Desired-behavior specifications for the bounded candidate.
   Not a claim that this complete file has run. Load a pinned baseline or a
   staged candidate first. Baseline failures in N01--N03 are intentional.
   Independent SetOptions[AsymptoticExpand,...] ownership is NOT settled here. *)
If[!MemberQ[$Packages, "AsymptoticAnalysis`"],
  Print["Load AsymptoticAnalysis before this test file."]; Abort[]];

SetAttributes[auditWithSavedDefaults, HoldAll];
auditWithSavedDefaults[body_] := Module[{saved, aliasSaved},
  Internal`WithLocalSettings[
    saved = Options[AsymptoticAnalysis`AsymptoticExpansion];
    aliasSaved = Options[AsymptoticAnalysis`AsymptoticExpand],
    body,
    Options[AsymptoticAnalysis`AsymptoticExpansion] = saved;
    Options[AsymptoticAnalysis`AsymptoticExpand] = aliasSaved]];

auditNativeQ[s_] := MatchQ[s, _AsymptoticAnalysis`GeneralizedSeries] &&
  s["Kind"] === "Native";

VerificationTest[
  auditWithSavedDefaults[Module[{x, s},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
    auditNativeQ[s] && s["NativeResult"] === Series[Exp[x], {x, 0, 3}]]],
  True, TestID -> "N01-primary-Backend-default-is-effective"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> Automatic];
    s["Kind"] === "Forward" && Normal[s] === 1 + x + x^2/2]],
  True, TestID -> "N01-explicit-Automatic-overrides-configured-default"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Package"];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[I x], {x, 0, 3}];
    MatchQ[s, Failure["InexactInput", _Association]]]],
  True, TestID -> "N01-primary-Package-default-does-not-fall-back"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s, calls = 0},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion,
      "Backend" :> (calls++; "Series")];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
    auditNativeQ[s] && calls === 1]],
  True, TestID -> "N01-delayed-Backend-default-consumed-once"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s, calls = 0},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion,
      "Backend" :> (calls++; "Package")];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
    auditNativeQ[s] && calls === 0]],
  True, TestID -> "N01-explicit-selector-does-not-consume-delayed-default"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "Series"];
    s = AsymptoticAnalysis`AsymptoticExpand[Exp[x], {x, 0, 3}];
    auditNativeQ[s] && Normal[s] === 1 + x + x^2/2 + x^3/6]],
  True, TestID -> "N01-held-alias-inherits-primary-default-under-candidate-policy"]

VerificationTest[
  auditWithSavedDefaults[Module[{x, s},
    SetOptions[AsymptoticAnalysis`AsymptoticExpansion, "Backend" -> "NoSuchBackend"];
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}];
    MatchQ[s, Failure["InvalidBackend", _Association]]]],
  True, TestID -> "N01-invalid-default-gets-selector-diagnostic"]

VerificationTest[
  Module[{x, key = "Backend", s},
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> "Series"];
    auditNativeQ[s] && Normal[s] === 1 + x + x^2/2 + x^3/6],
  True, TestID -> "N02-option-key-alias-with-literal-specification"]

VerificationTest[
  Module[{x, key = "Backend", spec, a, b},
    spec = {x, 0, 3};
    a = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> "Series"];
    b = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], spec, key -> "Series"];
    auditNativeQ[a] && auditNativeQ[b] && a["NativeResult"] === b["NativeResult"]],
  True, TestID -> "N02-literal-versus-computed-specification-invariance"]

VerificationTest[
  Module[{x, key, keyCalls = 0, selectorCalls = 0, s},
    key := (keyCalls++; "Backend");
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3},
      {{key :> (selectorCalls++; "Series")}}];
    auditNativeQ[s] && {keyCalls, selectorCalls} === {1, 1}],
  True, TestID -> "N02-key-and-delayed-selector-are-consumed-once"]

VerificationTest[
  Module[{x, key = "Backend", first = 0, later = 0, s},
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[x], {x, 0, 3},
      {{key :> (first++; "Series")}, {"Backend" :> (later++; "Package")}}];
    auditNativeQ[s] && {first, later} === {1, 0}],
  True, TestID -> "N02-first-selector-wins-without-evaluating-later-selectors"]

VerificationTest[
  AsymptoticAnalysis`Private`nativeSelectorValues[
    HoldComplete[Method -> {"Backend" -> "Series"}]],
  {}, TestID -> "N02-rules-inside-an-option-value-are-not-selectors"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticAnalysis`AsymptoticExpansion[(# &)[Exp[I x]], {x, 0, 3}];
    auditNativeQ[s] && s["NativeResult"] === Series[Exp[I x], {x, 0, 3}]],
  True, TestID -> "N03-applied-identity-is-a-scalar-source-not-a-callable"]

VerificationTest[
  Module[{x, s, calls = 0},
    s = AsymptoticAnalysis`AsymptoticExpansion[
      (calls++; # &)[Exp[I x]], {x, 0, 3}];
    auditNativeQ[s] && calls === 1],
  True, TestID -> "N03-source-program-is-not-replayed-on-native-fallback"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticAnalysis`AsymptoticExpansion[Exp[#] &, {x, 0, 3}];
    s["Kind"] === "Forward" && Normal[s] === 1 + x + x^2/2],
  True, TestID -> "N03-genuine-unapplied-callable-keeps-package-path"]

VerificationTest[
  Module[{x, s},
    s = AsymptoticAnalysis`AsymptoticExpansion[(# &)[Exp[I x]], {x, 0, 3},
      "MaxTerms" -> 100];
    MatchQ[s, Failure["InexactInput", _Association]]],
  True, TestID -> "N03-explicit-resource-contract-still-protects-package-path"]

VerificationTest[
  Module[{x, requests},
    requests = {
      HoldComplete[InverseFunction[# + #^2 &][x], {x, 0, 3}],
      HoldComplete[ConditionalExpression[Exp[I x], x > 0], {x, 0, 3}],
      HoldComplete[Exp[I x], {x, 0, 3}, Direction -> "FromAbove"]};
    And @@ (AsymptoticAnalysis`Private`automaticProtectedQ[#, #] & /@ requests)],
  True, TestID -> "N03-inverse-conditional-and-direction-guards-are-retained"]
