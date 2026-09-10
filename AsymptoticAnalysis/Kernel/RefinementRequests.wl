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
