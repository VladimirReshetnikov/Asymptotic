(* W3-13 / report 24 F01: bounded native characterization before or after
   changing the Fourier homogeneous-recurrence loop. This records outcomes;
   it does not turn expected failures into a package acceptance claim. *)
Module[{root, probeFile = $InputFileName, hashes, before, after, probeHash,
   probeStable, observe, observations, output, x, y, a, ell},
 root = DirectoryName[DirectoryName[probeFile]];
 hashes[] := Association[(StringReplace[FileNameTake[#, -3], "\\" -> "/"] ->
     FileHash[#, "SHA256", "HexString"]) & /@
   Sort[FileNames["*.wl", FileNameJoin[{root, "src", "Kernel"}]]]];
 before = hashes[]; probeHash = FileHash[probeFile, "SHA256", "HexString"];
 Get[FileNameJoin[{root, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
 observe[name_, held_HoldComplete] := Module[{result, seconds},
   {seconds, result} = AbsoluteTiming[TimeConstrained[ReleaseHold[held], 20, $Aborted]];
   Print[name, ": ", InputForm[result]];
   <|"Case" -> name, "Seconds" -> seconds,
     "Result" -> ToString[result, InputForm], "TimedOut" -> (result === $Aborted)|>];
 observations = Block[{$Assumptions = True}, {
   observe["helper-linear-budget-three", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, 1}}, 5, ell, True, 3, 1]]]],
   observe["helper-constant-needs-no-first-product", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, 0, {{0, 1}}, 5, ell, True, 1, 1]]]],
   observe["helper-zero-modes-need-no-product", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, Sqrt[2], {}, 5, ell, True, 1, 1]]]],
   observe["helper-quadratic-budget-five", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, 2, {{0, 1}}, 7, ell, True, 5, 1]]]],
   observe["helper-next-support-at-exclusive-cutoff", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{3, {{0, 1}}}}, -1, {{0, ell}}, 3, ell, True, 1, 1]]]],
   observe["helper-required-square-still-exceeds-budget", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, -1, {{0, 1}}, 5, ell, True, 3, 1]]]],
   observe["helper-assumptions-prove-next-coefficient-zero", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, a, {{0, 1}}, 5, ell, a == 1, 3, 1]]]],
   observe["helper-unproved-coefficient-still-needs-square", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, a, {{0, 1}}, 5, ell, Element[a, Reals], 3, 1]]]],
   observe["helper-nonzero-frequency-coefficients", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}}, 0, {{1, 1}}, 3, ell, True, 3, 1]]]],
   observe["helper-frequency-prevents-integer-power-termination", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{1, 1}}, 5, ell, True, 3, 1]]]],
   observe["helper-log-amplitude-prevents-integer-power-termination", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}, {2, {{0, 1}}}}, 1, {{0, ell}}, 5, ell, True, 3, 1]]]],
   observe["helper-infinite-nonterminating-series-is-budgeted", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{0, 1}}}}, -1, {{0, 1}}, Infinity, ell, True, 3, 1]]]],
   observe["helper-nonsmall-input-is-validated-before-termination", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{0, {{0, 1}}}}, 0, {{0, 1}}, 5, ell, True, 1, 1]]]],
   observe["helper-frequency-budget-remains-hard", HoldComplete[
     AsymptoticAnalysis`Private`catch[AsymptoticAnalysis`Private`fourierComposeBlock[
       {{1, {{-1, 1/2}, {1, 1/2}}}}, 1, {{0, 1}}, 2, ell, True, 20, 2]]]],
   observe["public-residual-explicit-budget-seven", HoldComplete[
     Module[{s = AsymptoticAnalysis`AsymptoticFourierInverse[
         x + x^2, {x, 0}, {y, 7}, "MaxTerms" -> 7]},
       If[FailureQ[s], s,
         AsymptoticAnalysis`FourierInverseResidual[s, Automatic, "MaxTerms" -> 7]]]]],
   observe["public-nonzero-frequency-residual-control", HoldComplete[
     Module[{s = AsymptoticAnalysis`AsymptoticFourierInverse[
         x + x^2 Sin[Log[x]], {x, 0}, {y, 4}]},
       If[FailureQ[s], s,
         <|"Expression" -> Normal[s], "RemainderPower" -> s["RemainderPower"],
           "Residual" -> AsymptoticAnalysis`FourierInverseResidual[s]|>]]]],
   observe["independent-retained-pair-counts", HoldComplete[
     <|"LinearWitnessUnneededSquare" -> Length[Select[Tuples[{1, 2}, 2], Total[#] < 5 &]],
       "PublicLinearUnneededSquare" -> Length[Select[Tuples[Range[5], 2], Total[#] < 6 &]],
       "PublicQuadraticRequiredSquare" -> Length[Select[Tuples[{Range[4], Range[5]}], Total[#] < 5 &]]|>]]
 }];
 after = hashes[]; probeStable = probeHash === FileHash[probeFile, "SHA256", "HexString"];
 output = Environment["ASYMPTOTIC_VALIDATION_OUTPUT"];
 If[! StringQ[output] || output === "", output = FileNameJoin[{root, "validation", "fourier-termination-baseline.json"}]];
 Export[output, <|"Kernel" -> $Version,
   "Scope" -> "Seventeen observations, each bounded to twenty seconds, of Fourier homogeneous termination, necessary resource failures, public residuals and exact pair counts; characterization, not a package acceptance suite. No full suite.",
   "SourceCount" -> Length[before], "SourceSHA256" -> before,
   "SourcesUnchangedDuringRun" -> (before === after),
   "ProbeSHA256" -> probeHash, "ProbeUnchangedDuringRun" -> probeStable,
   "Observations" -> observations|>, "RawJSON"];
 Print[output]; Exit[If[before === after && probeStable, 0, 1]]];
