(* Mathics' native Element rules can weaken a symbolic membership condition:
   Element[Sin[a],Reals] becomes Element[a,Reals], although a=Pi/2+I is a
   counterexample to that equivalence. The package's held public entries can
   preserve an inline assumption before ordinary option evaluation reaches
   those rules. Already evaluated caller values cannot be reconstructed.

   The private catch boundary is held and is entered by the analytic paths
   before option evaluation. Literal explicit native backend calls bypass
   it. Keep the established assumption scope and exception behavior in the
   original held delegate; change only membership heads inside the protected
   regions. Position and ReplacePart operate on held trees, so immediate and
   delayed option programs retain their evaluation count.

   Protected regions are the value of a syntactic Assumptions rule and the
   condition of an inline ConditionalExpression, whose live predicate the
   native rules would otherwise rewrite before the package reads it (wave-6
   report 49 N1). Inside a region only an applied two-argument membership
   head Element[_, _] is replaced: a bare Element symbol is caller data whose
   identity an option program may test, and anything below a held-data
   barrier (Hold, HoldComplete, HoldForm, Defer, HoldPattern, Verbatim,
   Unevaluated) is left as written (reports 51 N01 and 54 N02). *)

ClearAll[mathicsProtectInputAssumptions];
mathicsProtectInputAssumptions[held_HoldComplete] := If[
  FreeQ[held, System`Element], held, System`Module[
  {regions, heads, opaque, positions, below},
  regions = Join[
    (Append[#, 2] &) /@ Position[held,
      HoldPattern[Rule[Assumptions, _] | RuleDelayed[Assumptions, _]],
      {0, Infinity}, Heads -> False],
    (Append[#, 2] &) /@ Position[held,
      HoldPattern[ConditionalExpression[_, _]], {0, Infinity}, Heads -> False]];
  If[regions === {}, held,
  heads = (Append[#, 0] &) /@ Position[held,
    HoldPattern[System`Element[_, _]], {0, Infinity}, Heads -> False];
  opaque = Position[held,
    _HoldComplete | _Hold | _HoldForm | _Defer | _HoldPattern | _Verbatim | _Unevaluated,
    {1, Infinity}, Heads -> False];
  below[position_, prefix_] := Length[position] >= Length[prefix] &&
    Take[position, Length[prefix]] === prefix;
  positions = Select[heads, Function[position,
    (Or @@ (below[position, #] & /@ regions)) &&
      ! (Or @@ (below[position, #] & /@ opaque))]];
  ReplacePart[held, (# -> AsymptoticAnalysis`Mathics`Element) & /@ positions]]]];

If[DownValues[mathicsOriginalInputCatch] === {},
  SetAttributes[mathicsOriginalInputCatch, HoldAll];
  DownValues[mathicsOriginalInputCatch] = DownValues[catch] /.
    catch -> mathicsOriginalInputCatch];
Clear[catch];
SetAttributes[catch, HoldAll];
catch[body_] := Replace[mathicsProtectInputAssumptions[HoldComplete[body]],
  HoldComplete[protected_] :> mathicsOriginalInputCatch[protected]];
