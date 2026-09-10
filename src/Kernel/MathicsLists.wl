(* Mathics 10.0.1 Map[f, emptyList] can corrupt that list's cached element
   properties. Reusing it in a nested numeric list then raises a Python
   AssertionError. For example, without this package:
     b = {}; f /@ b; {b, 2, 0}
   Mapping at the default first level of an empty list has no applications
   of f and returns an empty list. Bypass only that exact case. Other inputs,
   explicit levels, Heads options, and invalid arguments retain native Map.

   This late adapter changes references in package-owned public, private,
   and compatibility definitions. In particular, the public empty inverse
   multi-index and compatibility Lookup list forms need the same protection.
   The interpreter and System`Map definitions are untouched. *)

ClearAll[mathicsMap, mathicsInstallMap];
mathicsMap[function_, items_List] :=
  If[items === {}, {}, System`Map[function, items]];
mathicsMap[args___] := System`Map[args];

SetAttributes[mathicsInstallMap, HoldAllComplete];
mathicsInstallMap[symbol_Symbol] :=
  If[MemberQ[{"AsymptoticAnalysis`", "AsymptoticAnalysis`Private`",
      "AsymptoticAnalysis`Mathics`"}, Context[Unevaluated[symbol]]] &&
      HoldComplete[symbol] =!= HoldComplete[mathicsMap] &&
      HoldComplete[symbol] =!= HoldComplete[mathicsInstallMap] &&
      ! FreeQ[DownValues[symbol], System`Map],
    DownValues[symbol] = DownValues[symbol] /. System`Map -> mathicsMap];

(* Mathics ToExpression evaluates its parsed expression before applying the
   optional third argument. Put the holding installer in the parsed text so
   even symbols with effectful OwnValues stay unevaluated during inspection.
   Names supplies existing, fully qualified package symbols. The installer
   also checks the exact owning context before changing any definitions. *)
Scan[ToExpression["AsymptoticAnalysis`Private`mathicsInstallMap[" <> # <> "]"] &,
  DeleteDuplicates[Join[Names["AsymptoticAnalysis`*"],
    Names["AsymptoticAnalysis`Private`*"], Names["AsymptoticAnalysis`Mathics`*"]]]];
