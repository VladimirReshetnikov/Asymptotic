(* Reproducible comparison matrix; NO comparison outputs were obtained in
   this audit session. Every entry is timed separately and preserves failure
   or unevaluated output. Repeat in fresh kernels and record hardware.
   Set ASYMPTOTIC_AUDIT_ROOT as for RunAudit.wls. *)
auditRoot = Environment["ASYMPTOTIC_AUDIT_ROOT"];
If[! StringQ[auditRoot] || ! DirectoryQ[auditRoot],
 Print["Set ASYMPTOTIC_AUDIT_ROOT to a local repository checkout."]; Exit[2]];
Get[FileNameJoin[{auditRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
Clear[x, y];
SetAttributes[auditCase, HoldAllComplete];
auditCase[name_, expression_] := Module[{timed},
 timed = AbsoluteTiming[TimeConstrained[MemoryConstrained[expression, 512*1024^2,
     Failure["AuditMemoryLimit", <||>]], 60, Failure["AuditTimeLimit", <||>]]];
 <|"Name" -> name, "ElapsedSeconds" -> timed[[1]],
   "ResultHead" -> ToString[Head[timed[[2]]], InputForm],
   "Result" -> ToString[timed[[2]], InputForm]|>];
auditCases = {
 auditCase["native regular inverse", InverseSeries[Series[x+x^2, {x,0,4}], y]],
 auditCase["package regular inverse", AsymptoticInverse[x+x^2, {x,0}, {y,5}]],
 auditCase["native irrational implicit inverse", AsymptoticSolve[y == x+x^Sqrt[2], x -> 0,
    {y,0,3}, Reals, Direction -> "FromAbove", GenerateConditions -> True]],
 auditCase["package irrational inverse", AsymptoticInverse[x+x^Sqrt[2], {x,0}, y, SeriesTermGoal -> 3]],
 auditCase["native logarithmic implicit inverse", AsymptoticSolve[y == x+x^2 (1+Log[x]), x -> 0,
    {y,0,3}, Reals, Direction -> "FromAbove", GenerateConditions -> True]],
 auditCase["package logarithmic inverse", AsymptoticInverse[x+x^2 (1+Log[x]), {x,0}, {y,4}]],
 auditCase["native forward Gamma ratio", Asymptotic[Gamma[x+1/3]/Gamma[x+2/3],
    {x,Infinity,3}, GenerateConditions -> True]],
 auditCase["package forward Gamma ratio", AsymptoticExpansion[Gamma[x+1/3]/Gamma[x+2/3],
    {x,Infinity,3}]],
 auditCase["native real Gamma implicit inverse", AsymptoticSolve[Gamma[x] == y, x -> Infinity,
    {y,Infinity,3}, Reals, GenerateConditions -> True]],
 auditCase["package real Gamma inverse", AsymptoticInverse[Gamma[x], {x,Infinity}, y, SeriesTermGoal -> 3]],
 auditCase["native elliptic endpoint", Series[EllipticK[1-x^2], {x,0,3}]],
 auditCase["package elliptic endpoint", AsymptoticExpansion[EllipticK[1-x^2], {x,0,4}]]
};
Put[<|"WolframVersion" -> $Version, "SystemID" -> $SystemID, "Cases" -> auditCases,
 "Caution" -> "Order arguments are not equivalent across scale families. Compare requested semantic error targets, branch domains and full coefficients before comparing speed."|>,
 "builtin-comparison-results.wl"];
Print[InputForm[auditCases]];
