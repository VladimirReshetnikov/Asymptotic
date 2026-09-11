(* Conservative finite-real and sign consequences of explicit assumptions.
   This is not quantifier elimination or a replacement for Reduce. Unknown
   facts stay unknown; no numerical samples or PowerExpand identities are
   used. Loaded only by the Mathics bootstrap, before the analytic modules. *)

Begin["AsymptoticAnalysis`Mathics`"];
ClearAll[AsymptoticAnalysis`Mathics`Element,
  AsymptoticAnalysis`Mathics`mathicsAssumptionAtoms,
  AsymptoticAnalysis`Mathics`mathicsAssumptionFacts,
  AsymptoticAnalysis`Mathics`mathicsKnownSigns,
  AsymptoticAnalysis`Mathics`mathicsSignsWithinQ,
  AsymptoticAnalysis`Mathics`mathicsRealProof,
  AsymptoticAnalysis`Mathics`mathicsSignProof,
  AsymptoticAnalysis`Mathics`mathicsRealProofBody,
  AsymptoticAnalysis`Mathics`mathicsSignProofBody,
  AsymptoticAnalysis`Mathics`mathicsProofMemoized,
  AsymptoticAnalysis`Mathics`mathicsAssumptionWalk,
  AsymptoticAnalysis`Mathics`$mathicsProofMemo,
  AsymptoticAnalysis`Mathics`mathicsRelationProof,
  AsymptoticAnalysis`Mathics`mathicsAssumptionSimplify];
SetAttributes[Element, HoldAll];
(* Preserve the original symbolic realness question. Mathics' native Element
   can otherwise replace Element[Log[a],Reals] by Element[a,Reals], losing the
   positive-domain requirement before the assumptions are considered. *)
Element[e_, Reals] /; NumericQ[e] &&
    MemberQ[{True, False}, System`Element[e, Reals]] := System`Element[e, Reals];
Element[e_, domain_] /; domain =!= Reals := System`Element[e, domain];

mathicsAssumptionAtoms[a_] := If[MemberQ[{And, List}, Head[a]],
  Flatten[mathicsAssumptionAtoms /@ List @@ a, 1], {a}];

mathicsAssumptionFacts[ass_] := Module[{real = {}, constraints = {}, add, relation, atoms},
  add[value_, signs_List] := Module[{v = value, s = signs},
    If[Head[v] === Times && Length[v] === 2 && First[v] === -1,
      v = -v; s = -s];
    AppendTo[constraints, {v, Sort[s]}]];
  relation[left_, head_, right_] := Module[{delta, signs},
    If[! FreeQ[{left, right}, _DirectedInfinity | Indeterminate], Return[Null, Module]];
    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual}, head],
      real = Join[real, {left, right}]];
    delta = left - right;
    signs = Switch[head, Less, {-1}, LessEqual, {-1, 0}, Greater, {1},
      GreaterEqual, {0, 1}, Equal, {0}, _, {-1, 0, 1}];
    If[head =!= Unequal, add[delta, signs]];
    (* A finite numeric endpoint also supplies useful weaker sign bounds. *)
    If[NumericQ[right] && TrueQ[System`Element[right, Reals]],
      Which[MemberQ[{Greater, GreaterEqual}, head] && TrueQ[right > 0], add[left, {1}],
        head === Greater && right === 0, add[left, {1}],
        head === GreaterEqual && right === 0, add[left, {0, 1}],
        MemberQ[{Less, LessEqual}, head] && TrueQ[right < 0], add[left, {-1}],
        head === Less && right === 0, add[left, {-1}],
        head === LessEqual && right === 0, add[left, {-1, 0}]]];
    If[NumericQ[left] && ! NumericQ[right],
      relation[right, Switch[head, Less, Greater, LessEqual, GreaterEqual,
        Greater, Less, GreaterEqual, LessEqual, _, head], left]]];
  atoms = mathicsAssumptionAtoms[ass];
  Do[Which[
    MemberQ[{Element, System`Element}, Head[atom]] && Length[atom] === 2 &&
      MemberQ[{Reals, Rationals, Integers}, atom[[2]]],
      real = Join[real, If[Head[atom[[1]]] === Alternatives || ListQ[atom[[1]]],
        List @@ atom[[1]], {atom[[1]]}]],
    MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, Head[atom]],
      Scan[relation[#[[1]], Head[atom], #[[2]]] &, Partition[List @@ atom, 2, 1]],
    Head[atom] === Inequality,
      Scan[relation[#[[1]], #[[2]], #[[3]]] &, Partition[List @@ atom, 3, 2]]],
    {atom, atoms}];
  {DeleteDuplicates[real], constraints}];

mathicsKnownSigns[e_, facts_] := Module[{sets, reciprocal, signs},
  sets = Last /@ Select[facts[[2]], SameQ[First[#], e] &];
  If[sets =!= {}, Return[Fold[Intersection, First[sets], Rest[sets]], Module]];
  (* Canonical evaluation distributes 1/(a b) into a^-1 b^-1. A proved
     nonzero real product still proves its reciprocal real with the same
     sign, without requiring either individual factor to be real. *)
  If[MemberQ[{Times, Power}, Head[e]],
    reciprocal = 1/e;
    sets = Last /@ Select[facts[[2]], SameQ[First[#], reciprocal] &];
    If[sets =!= {},
      signs = Fold[Intersection, First[sets], Rest[sets]];
      If[signs =!= {} && ! MemberQ[signs, 0], Return[signs, Module]]]];
  None];
mathicsSignsWithinQ[signs_, permitted_List] := ListQ[signs] && signs =!= {} &&
  Complement[signs, permitted] === {};

(* Request-local reuse of proof results. The mutually recursive provers reach
   the same subquery along several branches (a sum's sign proof asks for the
   realness and the sign of each term, a power asks for both of its base),
   so the work grows exponentially with nesting. A memo is scoped to one
   entry call, keyed by the query and its fact table: a proved answer at any
   depth is a proof, and an unresolved answer at depth d stays unresolved at
   every depth up to d. Nothing is kept across requests (wave-6 report 47 N01
   inside P08's bounded request-local lane). *)
$mathicsProofMemo = None;
mathicsProofMemoized[kind_, e_, facts_, depth_Integer, body_] := Module[{key, cached, result},
  If[$mathicsProofMemo === None, Return[body[e, facts, depth], Module]];
  key = {kind, e, facts};
  cached = $mathicsProofMemo[key];
  If[MatchQ[cached, {_Integer, _}] && (cached[[2]] =!= None || cached[[1]] >= depth),
    Return[cached[[2]], Module]];
  result = body[e, facts, depth];
  $mathicsProofMemo[key] = {depth, result};
  result];
mathicsRealProof[e_, facts_, depth_Integer] :=
  mathicsProofMemoized["Real", e, facts, depth, mathicsRealProofBody];
mathicsSignProof[e_, facts_, depth_Integer] :=
  mathicsProofMemoized["Sign", e, facts, depth, mathicsSignProofBody];

mathicsRealProofBody[e_, facts_, depth_Integer] := Module[{head = Head[e], arguments, signs, base, exponent},
  If[depth <= 0, Return[None, Module]];
  If[e === System`Glaisher, Return[True, Module]];
  If[Or @@ (SameQ[#, e] & /@ facts[[1]]), Return[True, Module]];
  signs = mathicsKnownSigns[e, facts];
  If[ListQ[signs] && signs =!= {}, Return[True, Module]];
  If[NumericQ[e],
    signs = System`Element[e, Reals];
    If[signs === True || signs === False, Return[signs, Module]]];
  If[MemberQ[{Plus, Times, Alternatives}, head],
    arguments = mathicsRealProof[#, facts, depth - 1] & /@ List @@ e;
    Return[If[And @@ (TrueQ /@ arguments), True, None], Module]];
  If[head === Power,
    base = e[[1]]; exponent = e[[2]];
    If[! TrueQ[mathicsRealProof[exponent, facts, depth - 1]], Return[None, Module]];
    signs = mathicsSignProof[base, facts, depth - 1];
    If[mathicsSignsWithinQ[signs, {1}], Return[True, Module]];
    If[IntegerQ[exponent] && TrueQ[mathicsRealProof[base, facts, depth - 1]] &&
      (exponent >= 0 || mathicsSignsWithinQ[signs, {-1, 1}]), Return[True, Module]];
    If[TrueQ[exponent > 0] && mathicsSignsWithinQ[signs, {0, 1}], Return[True, Module]];
    Return[None, Module]];
  If[Length[e] === 1 && MemberQ[{Sin, Cos, Sinh, Cosh, Tanh, ArcTan, Abs}, head],
    Return[If[TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]], True, None], Module]];
  If[Length[e] === 1 && MemberQ[{Log, Gamma, LogGamma, System`BarnesG, System`LogBarnesG}, head],
    signs = mathicsSignProof[e[[1]], facts, depth - 1];
    If[mathicsSignsWithinQ[signs, {1}], Return[True, Module]];
    If[head === Log && mathicsSignsWithinQ[signs, {-1, 0}], Return[False, Module]]];
  None];

mathicsSignProofBody[e_, facts_, depth_Integer] := Module[
  {known, head = Head[e], sets, base, exponent, signs, result},
  If[depth <= 0, Return[None, Module]];
  If[e === System`Glaisher, Return[{1}, Module]];
  known = mathicsKnownSigns[e, facts];
  If[known =!= None, Return[known, Module]];
  If[NumericQ[e] && TrueQ[System`Element[e, Reals]],
    Return[Which[TrueQ[e > 0], {1}, TrueQ[e < 0], {-1}, TrueQ[e == 0], {0}, True, None], Module]];
  If[head === Plus || head === Times,
    sets = mathicsSignProof[#, facts, depth - 1] & /@ List @@ e;
    If[! And @@ (ListQ[#] && # =!= {} & /@ sets), Return[None, Module]];
    If[head === Times,
      result = {1}; Do[result = DeleteDuplicates[Flatten[Outer[Times, result, s]]], {s, sets}];
      Return[Sort[result], Module]];
    If[And @@ (mathicsSignsWithinQ[#, {0, 1}] & /@ sets),
      Return[If[MemberQ[sets, {1}], {1}, {0, 1}], Module]];
    If[And @@ (mathicsSignsWithinQ[#, {-1, 0}] & /@ sets),
      Return[If[MemberQ[sets, {-1}], {-1}, {-1, 0}], Module]];
    Return[{-1, 0, 1}, Module]];
  If[head === Power,
    base = e[[1]]; exponent = e[[2]]; signs = mathicsSignProof[base, facts, depth - 1];
    If[mathicsSignsWithinQ[signs, {1}] && TrueQ[mathicsRealProof[exponent, facts, depth - 1]],
      Return[{1}, Module]];
    If[IntegerQ[exponent] && ListQ[signs] && signs =!= {} &&
      (exponent >= 0 || ! MemberQ[signs, 0]),
      Return[Sort[DeleteDuplicates[Sign[#^exponent] & /@ signs]], Module]];
    If[TrueQ[exponent > 0] && mathicsSignsWithinQ[signs, {0, 1}] &&
      TrueQ[mathicsRealProof[exponent, facts, depth - 1]], Return[signs, Module]]];
  If[Length[e] === 1 && head === Abs && TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]],
    signs = mathicsSignProof[e[[1]], facts, depth - 1];
    Return[If[mathicsSignsWithinQ[signs, {-1, 1}], {1}, {0, 1}], Module]];
  If[Length[e] === 1 && head === Cosh && TrueQ[mathicsRealProof[e[[1]], facts, depth - 1]],
    Return[{1}, Module]];
  If[Length[e] === 1 && MemberQ[{Gamma, System`BarnesG}, head] &&
    mathicsSignsWithinQ[mathicsSignProof[e[[1]], facts, depth - 1], {1}], Return[{1}, Module]];
  If[TrueQ[mathicsRealProof[e, facts, depth - 1]], {-1, 0, 1}, None]];

mathicsRelationProof[left_, head_, right_, facts_] := Module[{signs, accepted},
  If[! MemberQ[{Equal, Unequal}, head] &&
    ! (TrueQ[mathicsRealProof[left, facts, 24]] && TrueQ[mathicsRealProof[right, facts, 24]]),
    Return[None, Module]];
  signs = mathicsSignProof[left - right, facts, 24];
  accepted = Switch[head, Less, {-1}, LessEqual, {-1, 0}, Greater, {1},
    GreaterEqual, {0, 1}, Equal, {0}, Unequal, {-1, 1}, _, {}];
  Which[mathicsSignsWithinQ[signs, accepted], True,
    ListQ[signs] && signs =!= {} && Intersection[signs, accepted] === {}, False, True, None]];

(* One memo per entry call; nested entries with other assumptions are
   separated by the fact table inside the key. The memo is installed before
   any work: an earlier version computed the fact table and then re-entered
   the whole walker under the memo block, so every outer call paid for its
   fact table twice, which cost about half again the running time of every
   Mathics request that proves assumptions (the wave-7 operations receipts
   and the CI deadline exposed it). *)
mathicsAssumptionSimplify[expression_, assumptions_] := Module[{memo},
  If[$mathicsProofMemo === None,
    Block[{$mathicsProofMemo = memo}, mathicsAssumptionWalk[expression, assumptions]],
    mathicsAssumptionWalk[expression, assumptions]]];

mathicsAssumptionWalk[expression_, assumptions_] := Module[{facts, walk},
  (* Direct Taylor-admission calls also reach this walker. Do not let its
     Factor/Together path convert retained ProductLog[k,z] through Mathics'
     incorrect SymPy argument order. Leave the proof unresolved. *)
  If[! FreeQ[{expression, assumptions}, HoldPattern[System`ProductLog[_, _]]],
    Return[expression, Module]];
  facts = mathicsAssumptionFacts[assumptions];
  walk[e_] := Module[{head = Head[e], value, proof, signs, base, results},
    If[AtomQ[e], Return[e, Module]];
    If[MemberQ[{Element, System`Element}, head] && Length[e] === 2 && e[[2]] === Reals,
      proof = mathicsRealProof[e[[1]], facts, 24];
      Return[If[proof === True || proof === False, proof, e], Module]];
    If[! MemberQ[{And, Or, Not}, head] && Head[head] === Symbol &&
      Intersection[Attributes[head], {HoldAll, HoldAllComplete, HoldFirst, HoldRest}] =!= {}, Return[e, Module]];
    value = Map[walk, e]; head = Head[value];
    If[MemberQ[{Less, LessEqual, Greater, GreaterEqual, Equal, Unequal}, head],
      results = mathicsRelationProof[#[[1]], head, #[[2]], facts] & /@
        If[head === Unequal, Subsets[List @@ value, {2}], Partition[List @@ value, 2, 1]];
      If[And @@ (TrueQ /@ results), Return[True, Module]];
      If[MemberQ[results, False], Return[False, Module]]];
    If[MatchQ[value, Power[_, Rational[1, 2]]],
      base = value[[1]];
      If[! MatchQ[base, Power[_, 2]] && LeafCount[base] <= 200 &&
          NumericQ[Denominator[Together[base]]],
        proof = System`Factor[base];
        If[Expand[proof - base] === 0, base = proof]];
      If[MatchQ[base, Power[_, 2]],
        base = base[[1]]; signs = mathicsSignProof[base, facts, 24];
        Which[mathicsSignsWithinQ[signs, {0, 1}], Return[base, Module],
          mathicsSignsWithinQ[signs, {-1, 0}], Return[-base, Module],
          TrueQ[mathicsRealProof[base, facts, 24]], Return[Abs[base], Module]]]];
    If[head === Abs && Length[value] === 1,
      base = value[[1]]; signs = mathicsSignProof[base, facts, 24];
      If[mathicsSignsWithinQ[signs, {0, 1}], Return[base, Module]];
      If[mathicsSignsWithinQ[signs, {-1, 0}], Return[-base, Module]]];
    value];
  walk[expression]];

End[];
