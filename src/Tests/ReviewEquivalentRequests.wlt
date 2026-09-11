(* Differential behavior catalog (register B04, wave-3 report 20). Requests
   that differ only in spelling or in a controlled transformation must give
   the same expansion: alpha-renaming of the variable, the rule-form and
   list-form specifications, the string and symbol option spellings, the
   order of assumption clauses, a constant multiple of the source, and the
   sum of two sources against the sum of their expansions. The finite part
   and the remainder power are compared; the sources cover the elementary,
   special-function and inverse routes. *)
If[! MemberQ[$Packages, "AsymptoticAnalysis`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticAnalysis.wl"}]]];

equivalentRequestSignature[s_GeneralizedSeries] := {Expand[Normal[s]], s["RemainderPower"], s["Kind"]};
equivalentRequestSignature[other_] := {Head[other], other[[1]]};

equivalentRequestSources[x_] := {Exp[x] + x^2, Log[1 + x], 1/(1 - x)^2, Sqrt[1 + x] Cos[x], Gamma[1 + x], Erf[x] + x^3};

VerificationTest[
  Module[{x, y, renamed, direct},
    direct = equivalentRequestSignature[AsymptoticExpansion[#, {x, 0, 4}]] & /@ equivalentRequestSources[x];
    renamed = (equivalentRequestSignature[AsymptoticExpansion[#, {y, 0, 4}]] /. y -> x) & /@ equivalentRequestSources[y];
    renamed === direct],
  True, TestID -> "equivalent-requests-alpha-renaming-of-the-variable"]

VerificationTest[
  Module[{x, listForm, ruleForm},
    listForm = equivalentRequestSignature[AsymptoticExpansion[#, {x, 0}, SeriesTermGoal -> 3]] & /@ equivalentRequestSources[x];
    ruleForm = equivalentRequestSignature[AsymptoticExpansion[#, x -> 0, SeriesTermGoal -> 3]] & /@ equivalentRequestSources[x];
    listForm === ruleForm],
  True, TestID -> "equivalent-requests-rule-form-and-list-form-specifications"]

VerificationTest[
  Module[{x, stringSpelling, symbolSpelling, a},
    stringSpelling = equivalentRequestSignature[AsymptoticExpansion[#, {x, 0, 4}, "MaxTerms" -> 500, "Backend" -> "Package"]] & /@ equivalentRequestSources[x];
    symbolSpelling = equivalentRequestSignature[AsymptoticExpansion[#, {x, 0, 4}, MaxTerms -> 500, Backend -> "Package"]] & /@ equivalentRequestSources[x];
    stringSpelling === symbolSpelling],
  True, TestID -> "equivalent-requests-string-and-symbol-option-spellings"]

VerificationTest[
  Module[{x, a, first, second},
    first = equivalentRequestSignature[AsymptoticExpansion[Sqrt[a x + x^2], {x, 0, 3}, Assumptions -> a > 0 && Element[a, Reals]]];
    second = equivalentRequestSignature[AsymptoticExpansion[Sqrt[a x + x^2], {x, 0, 3}, Assumptions -> Element[a, Reals] && a > 0]];
    first === second && first[[3]] === "Forward"],
  True, TestID -> "equivalent-requests-assumption-clause-order"]

VerificationTest[
  Module[{x, scaled, direct},
    direct = equivalentRequestSignature[AsymptoticExpansion[#, {x, 0, 4}]] & /@ equivalentRequestSources[x];
    scaled = equivalentRequestSignature[AsymptoticExpansion[3 #, {x, 0, 4}]] & /@ equivalentRequestSources[x];
    scaled === ({Expand[3 #[[1]]], #[[2]], #[[3]]} & /@ direct)],
  True, TestID -> "equivalent-requests-constant-multiple-of-the-source"]

VerificationTest[
  Module[{x, sources, pairs, sums, added},
    sources = equivalentRequestSources[x];
    pairs = Partition[sources, 2];
    sums = equivalentRequestSignature[AsymptoticExpansion[#[[1]] + #[[2]], {x, 0, 4}]] & /@ pairs;
    added = equivalentRequestSignature[SeriesAdd[AsymptoticExpansion[#[[1]], {x, 0, 4}], AsymptoticExpansion[#[[2]], {x, 0, 4}]]] & /@ pairs;
    sums[[All, 1]] === added[[All, 1]] && sums[[All, 2]] === added[[All, 2]]],
  True, TestID -> "equivalent-requests-sum-of-sources-against-sum-of-expansions"]

VerificationTest[
  Module[{x, y, direct, renamed},
    direct = equivalentRequestSignature[AsymptoticInverse[x + x^2 + x^3, {x, 0}, {y, 5}]];
    renamed = equivalentRequestSignature[AsymptoticInverse[y + y^2 + y^3, {y, 0}, {x, 5}]] /. x -> y;
    direct === renamed],
  True, TestID -> "equivalent-requests-inverse-alpha-renaming-of-both-variables"]
