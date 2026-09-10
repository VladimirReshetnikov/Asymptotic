(* Load an already selected local AsymptoticAnalysis distribution first.
   This file does not download, install, or patch it. All public heads are
   qualified to avoid parse-before-Get shadow symbols in a fresh kernel.
   These are observations, not a claim that either runtime's full suite passes. *)
Clear[Global`auditX, Global`auditA];
Global`auditSeed = AsymptoticAnalysis`AsymptoticExpansion[
  1/(1 - Global`auditA Global`auditX^3), {Global`auditX, 0, 1},
  Assumptions -> Global`auditA^2 == -1, "Backend" -> "Package"];
Global`auditAmplified = AsymptoticAnalysis`SeriesMultiply[
  AsymptoticAnalysis`SeriesAdd[Global`auditSeed, -1], Global`auditX^-4];
Global`auditTrig = {Sin[Global`auditAmplified], Cos[Global`auditAmplified]};
Global`auditMetadata = AsymptoticAnalysis`AsymptoticExpansion[
  Global`auditA Global`auditX, {Global`auditX, 0, 2},
  Assumptions -> Global`auditA > 0, "Backend" -> "Package"];
Global`auditCounts = Reap[Do[
  Sow[{k, Count[Global`auditMetadata["Assumptions"], Global`auditA > 0, {0, Infinity}],
    Count[Global`auditMetadata["TargetDomain"], Global`auditX > 0, {0, Infinity}],
    Normal[Global`auditMetadata] === 2^k Global`auditA Global`auditX}];
  If[k < 5, Global`auditMetadata = AsymptoticAnalysis`SeriesAdd[
    Global`auditMetadata, Global`auditMetadata]], {k, 0, 5}]][[2]];
Global`auditObservations = <|"KernelVersion" -> $Version,
  "N01Seed" -> Global`auditSeed,
  "N01Amplified" -> Global`auditAmplified,
  "N01Trig" -> Global`auditTrig,
  "N02Counts" -> Global`auditCounts|>;
Print[InputForm[Global`auditObservations]];
