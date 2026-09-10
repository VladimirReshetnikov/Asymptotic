(* Focused outcome smoke: load the patched package first, then Get this file.
   No MUnit dependency. It deliberately does not claim coefficient/tail validation.
   Authored for Wolfram and Mathics; this complete file was not executed on Mathics
   during the audit. Seven corresponding patched outcomes were observed in Wolfram. *)
If[Length[Names["AsymptoticAnalysis`AsymptoticExponentialCoreInverse"]] == 0,
  Print["SETUP_FAILURE: Load AsymptoticAnalysis first."]; Abort[]];
Module[{x, y, z, b, cases, records, failed},
  cases = {
    {"target-dependent-shift", "Failure",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {y, 1}, "SourceShift" -> -Abs[y]]},
    {"core-inverse-may-use-target", "GeneralizedSeries",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {y, 1}, "CoreInverse" -> Log[y]]},
    {"automatic", "GeneralizedSeries",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {y, 1}]},
    {"fixed-negative-shift", "GeneralizedSeries",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {y, 1}, "SourceShift" -> -3]},
    {"fixed-parameter-shift", "GeneralizedSeries",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {y, 1}, "SourceShift" -> b, Assumptions -> Element[b, Reals]]},
    {"renamed-target-invalid", "Failure",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {z, 1}, "SourceShift" -> -Abs[z]]},
    {"unrelated-y-valid", "GeneralizedSeries",
      AsymptoticAnalysis`AsymptoticExponentialCoreInverse[Exp[x], 1,
        {x, Infinity}, {z, 1}, "SourceShift" -> -Abs[y]]}
  };
  records = ({#[[1]], #[[2]], Which[
    Head[#[[3]]] === Failure, "Failure",
    Head[#[[3]]] === AsymptoticAnalysis`GeneralizedSeries, "GeneralizedSeries",
    True, "UnexpectedHead"]} &) /@ cases;
  Scan[(Print[If[#[[2]] === #[[3]], "PASS: ", "FAIL: "], #[[1]],
    " expected=", #[[2]], " observed=", #[[3]]]) &, records];
  failed = Length[Select[records, #[[2]] =!= #[[3]] &]];
  Print["SOURCE_SHIFT_SMOKE kernel=", $Version, " cases=", Length[records], " failed=", failed];
  If[failed > 0, Abort[]];
];
