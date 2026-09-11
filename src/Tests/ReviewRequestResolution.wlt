(* W3-01: a configured "Backend" default is honored for omitted selectors,
   an explicit selector still comes first, the alias owns its own configured
   default, and internal replays never inherit a native default. W3-02:
   computed option keys resolve once, symbol spellings of string-named
   options are canonical, and an unknown symbol-keyed rule after a
   specification is refused instead of becoming a native specification. *)

VerificationTest[
 Module[{x, configured, explicit, alias, aliasConfigured, refined, s, restore},
  restore = Options[AsymptoticExpansion, "Backend"];
  SetOptions[AsymptoticExpansion, "Backend" -> "Series"];
  configured = AsymptoticExpansion[Exp[x], {x, 0, 3}];
  explicit = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
  alias = AsymptoticExpand[Exp[x], {x, 0, 3}];
  s = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Package"];
  refined = SeriesRefine[s, 5];
  SetOptions[AsymptoticExpansion, "Backend" -> Automatic];
  SetOptions[AsymptoticExpand, "Backend" -> "Asymptotic"];
  aliasConfigured = {AsymptoticExpand[1/(1 + x), {x, Infinity, 3}], AsymptoticExpand[Exp[x], {x, 0, 3}, "Backend" -> "Package"],
    AsymptoticExpansion[Exp[x], {x, 0, 3}]};
  SetOptions[AsymptoticExpand, "Backend" -> Automatic];
  SetOptions[AsymptoticExpansion, restore];
  {configured["Kind"], configured["NativeBackend"], explicit["Kind"], alias["Kind"], refined["Kind"], refined["RemainderPower"],
   aliasConfigured[[1]]["Kind"], aliasConfigured[[1]]["NativeBackend"], aliasConfigured[[2]]["Kind"], aliasConfigured[[3]]["Kind"],
   Options[AsymptoticExpansion, "Backend"], Options[AsymptoticExpand, "Backend"]}],
 {"Native", "Series", "Forward", "Native", "Forward", 5, "Native", "Asymptotic", "Forward", "Forward",
  {"Backend" -> Automatic}, {"Backend" -> Automatic}},
 TestID -> "configured-backend-defaults-are-honored-with-explicit-precedence-and-insulated-replay"]

VerificationTest[
 Module[{x, key = "Backend", limit = "MaxTerms", computedKey, container, symbolBackend, symbolLimit, literalLimit, delayed, evaluations = 0},
  computedKey = AsymptoticExpansion[Exp[x], {x, 0, 3}, key -> "Series"];
  container = AsymptoticExpansion[Exp[x], {x, 0, 3}, {key -> "Series"}];
  symbolBackend = AsymptoticExpansion[Exp[x], {x, 0, 3}, Backend -> "Package"];
  symbolLimit = AsymptoticExpansion[Exp[x], {x, 0, 3}, MaxTerms -> 7];
  literalLimit = AsymptoticExpansion[Exp[x], {x, 0, 3}, "MaxTerms" -> 7];
  delayed = AsymptoticExpansion[Exp[x], {x, 0, 3}, limit :> (evaluations++; 9)];
  {computedKey["Kind"], computedKey["NativeBackend"], container["Kind"], symbolBackend["Kind"],
   symbolLimit["Kind"], Normal[symbolLimit] === Normal[literalLimit], delayed["Kind"], Normal[delayed] === Normal[literalLimit], evaluations}],
 {"Native", "Series", "Native", "Forward", "Forward", True, "Forward", True, 1},
 TestID -> "computed-and-symbol-option-keys-resolve-to-one-option-identity"]

VerificationTest[
 Module[{x, afterList, afterRule, ruleForm, ruleGoal, stringUnknown, restore, configuredGoal},
  afterList = AsymptoticExpansion[Exp[x], {x, 0, 3}, Foo -> 1];
  afterRule = AsymptoticExpansion[Exp[x], x -> 0, Foo -> 2];
  ruleForm = AsymptoticExpansion[Exp[x], x -> 0, SeriesTermGoal -> 2];
  ruleGoal = AsymptoticExpansion[Sin[x], x -> 0];
  stringUnknown = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Foo" -> 1];
  restore = Options[AsymptoticExpansion, SeriesTermGoal];
  SetOptions[AsymptoticExpansion, SeriesTermGoal -> 2];
  configuredGoal = AsymptoticExpansion[Exp[x], x -> 0];
  SetOptions[AsymptoticExpansion, restore];
  {afterList[[1]], afterList[[2]]["Options"], afterRule[[1]], ruleForm["Kind"], Normal[ruleForm] === 1 + x,
   ruleGoal["Kind"], stringUnknown[[1]], configuredGoal["Kind"], Normal[configuredGoal] === 1 + x}],
 {"UnknownOption", {HoldComplete[Foo]}, "UnknownOption", "Forward", True, "Native", "NativeOptionConflict", "Forward", True},
 TestID -> "unknown-symbol-options-are-refused-and-configured-term-goals-route-rule-forms-to-the-package"]

(* W3-03: a pure function is a callable-source contract only as the source
   itself; a Function consumed inside the source (an applied identity or the
   defining function of a Root object) no longer blocks the native fallback
   for a representation the package refuses. *)
VerificationTest[
 Module[{x, root, applied, plain, callable, callableReal},
  root = AsymptoticExpansion[Root[#^3 - # - 1 &, 1] x + Exp[I x], {x, 0, 3}];
  applied = AsymptoticExpansion[Function[t, t^2][x] + Exp[I x], {x, 0, 3}];
  plain = AsymptoticExpansion[Exp[I x], {x, 0, 3}];
  callable = AsymptoticExpansion[Function[t, Exp[I t]], {x, 0, 3}];
  callableReal = AsymptoticExpansion[Function[t, Exp[t]], {x, 0, 3}];
  {root["Kind"], Simplify[Normal[root] - Normal[Series[Root[#^3 - # - 1 &, 1] x + Exp[I x], {x, 0, 3}]]] === 0,
   applied["Kind"], Simplify[Normal[applied] - (1 + I x + x^2/2 - (I/6) x^3)] === 0, plain["Kind"],
   Head[callable], callable[[1]], callableReal["Kind"], Normal[callableReal] === 1 + x + x^2/2}],
 {"Native", True, "Native", True, "Native", Failure, "InexactInput", "Forward", True},
 TestID -> "consumed-functions-inside-a-source-do-not-block-the-native-fallback"]

(* W3-05: the native evaluation status describes the delegated call, not the
   user's data: a held native call in the source is data, a nonfinite value
   is a computed outcome labelled Nonfinite, and only a native call that still
   carries a specification is Unresolved. *)
VerificationTest[
 Module[{x, y, k, held, nonfinite, unresolved, computed, infiniteSum},
  held = AsymptoticExpansion[Hold[Series[y, {y, 0, 1}]] + Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  nonfinite = AsymptoticExpansion[Log[0] + x, {x, 0, 2}, "Backend" -> "Series"];
  unresolved = Quiet[AsymptoticExpansion[{Exp[x], Sin[x]}, x -> 0, SeriesTermGoal -> 0, "Backend" -> "Asymptotic"]];
  computed = AsymptoticExpansion[Exp[x], {x, 0, 3}, "Backend" -> "Series"];
  infiniteSum = AsymptoticExpansion[1/(1 - x), {x, 0, Infinity}, "Backend" -> "Asymptotic", GeneratedParameters -> (k[#] &)];
  {held["NativeEvaluationStatus"], ! FreeQ[held["NativeResult"], Hold[Series[y, {y, 0, 1}]]],
   nonfinite["NativeEvaluationStatus"], nonfinite["NativeResult"],
   unresolved["NativeEvaluationStatus"], computed["NativeEvaluationStatus"],
   infiniteSum["NativeEvaluationStatus"], ! FreeQ[infiniteSum["NativeResult"], Infinity]}],
 {"Computed", True, "Nonfinite", -Infinity, "Unresolved", "Computed", "Computed", True},
 TestID -> "native-evaluation-status-ignores-held-data-and-labels-nonfinite-values"]

(* W3-09: a source that is one top-level ConditionalExpression may be
   delegated natively with its condition added to the native assumptions and
   recorded as "SourceCondition"; the package path keeps its own conditioned
   contract, and a condition nested inside the source stays protected. *)
VerificationTest[
 Module[{x, a, automatic, package, explicit, parameter, nested},
  automatic = AsymptoticExpansion[ConditionalExpression[Exp[I x], x > 0], {x, 0, 3}];
  package = AsymptoticExpansion[ConditionalExpression[Log[1 + x], -1 < x < 1], {x, 0, 3}];
  explicit = AsymptoticExpansion[ConditionalExpression[Exp[I x], x > 0], {x, 0, 3}, "Backend" -> "Series"];
  parameter = AsymptoticExpansion[ConditionalExpression[Sqrt[a^2] Exp[I x], a > 0], {x, 0, 2}];
  nested = AsymptoticExpansion[Exp[I x] + ConditionalExpression[1, x > 0], {x, 0, 3}];
  {automatic["Kind"], automatic["SourceCondition"] === (x > 0), automatic["BackendSelectionReason"],
   Simplify[Normal[automatic] - (1 + I x - x^2/2 - (I/6) x^3)] === 0,
   package["Kind"], package["TargetDomain"] === (-1 < x < 1 && x > 0), KeyExistsQ[package[[1]], "SourceCondition"],
   explicit["Kind"], explicit["SourceCondition"] === (x > 0), Simplify[Normal[explicit] - (1 + I x - x^2/2 - (I/6) x^3)] === 0,
   parameter["Kind"], parameter["SourceCondition"] === (a > 0), Simplify[Normal[parameter] - a (1 + I x - x^2/2)] === 0,
   Head[nested], nested[[1]]}],
 {"Native", True, "PackageRepresentation", True, "Forward", True, False,
  "Native", True, True, "Native", True, True, Failure, "InexactInput"},
 TestID -> "a-top-level-conditioned-source-delegates-natively-with-its-condition-recorded"]
