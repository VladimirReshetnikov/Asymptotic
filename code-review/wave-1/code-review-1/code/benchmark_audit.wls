(* Prospective benchmark, NOT EXECUTED during this audit.
   Start a fresh kernel for EACH case. ASYMPTOTIC_AUDIT_ROOT is required.
   ASYMPTOTIC_AUDIT_CASE selects a case; ASYMPTOTIC_AUDIT_OUTPUT selects JSON.
   Warm-up plus three timed runs. Output terms, branches and errors must be
   compared before interpreting timing ratios. No equality is inferred here. *)
root = Environment["ASYMPTOTIC_AUDIT_ROOT"];
If[! StringQ[root] || root === "", Print["Set ASYMPTOTIC_AUDIT_ROOT."]; Exit[2]];
root = ExpandFileName[root];
If[Check[Get[FileNameJoin[{root, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]], $Failed] === $Failed, Exit[2]];
Clear[x, y];
cases = <|
 "NativeQuadratic" -> HoldComplete[InverseSeries[x + x^2 + O[x]^8, y]],
 "PackageQuadratic" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^2, {x, 0}, {y, 8}]],
 "NativeIrrational" -> HoldComplete[AsymptoticSolve[x + x^Sqrt[2] == y, x -> 0, y -> 0, Reals,
    Assumptions -> y > 0, SeriesTermGoal -> 5, GenerateConditions -> True]],
 "PackageIrrationalLagrange" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y,
    SeriesTermGoal -> 5, Method -> "Lagrange"]],
 "PackageIrrationalNewton" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^Sqrt[2], {x, 0}, y,
    SeriesTermGoal -> 5, Method -> "Newton"]],
 "PackageLogarithmic" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[x + x^2 (1 + Log[x]), {x, 0}, {y, 7}]],
 "NativeGamma" -> HoldComplete[Asymptotic[Gamma[x], x -> Infinity, SeriesTermGoal -> 5]],
 "PackageGamma" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[Gamma[x], {x, Infinity}, SeriesTermGoal -> 5]],
 "PackageGammaInverse" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[Gamma[x], {x, Infinity}, y, SeriesTermGoal -> 5]],
 "PackageBarnesInverse" -> HoldComplete[AsymptoticInverse`AsymptoticInverse[BarnesG[x], {x, Infinity}, y, SeriesTermGoal -> 5]],
 "PackageBessel" -> HoldComplete[AsymptoticInverse`AsymptoticExpansion[BesselJ[0, x], {x, Infinity}, SeriesTermGoal -> 5]]
|>;
name = Environment["ASYMPTOTIC_AUDIT_CASE"];
If[! KeyExistsQ[cases, name], Print["Select ASYMPTOTIC_AUDIT_CASE from ", Keys[cases]]; Exit[2]];
held = cases[name];
run[] := Module[{seconds, value},
 {seconds, value} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 60, $Aborted]];
 <|"Seconds" -> seconds, "ByteCount" -> ByteCount[value],
   "LeafCount" -> LeafCount[value], "Output" -> ToString[value, InputForm],
   "Aborted" -> (value === $Aborted), "Failure" -> FailureQ[value]|>];
warm = run[]; measured = Table[run[], {3}];
output = Environment["ASYMPTOTIC_AUDIT_OUTPUT"];
If[! StringQ[output] || output === "", output = FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "evidence", "benchmark_" <> name <> ".json"}]];
Export[output, <|"Kernel" -> $Version, "SystemID" -> $SystemID, "Case" -> name,
 "Input" -> ToString[held, InputForm], "Warmup" -> warm, "Samples" -> measured,
 "MedianSeconds" -> Median[Lookup[measured, "Seconds"]],
 "SourceSHA256" -> Association[(# -> IntegerString[FileHash[#, "SHA256"], 16, 64]) & /@
    Sort[FileNames["*.wl", FileNameJoin[{root, "AsymptoticInverse", "Kernel"}]]]],
 "Caution" -> "Related calls are not necessarily equivalent requests. Check complete blocks, branch, retained carriers and error contracts before reporting a speedup."|>, "RawJSON"];
Print[output];
