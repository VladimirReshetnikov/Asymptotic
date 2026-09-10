(* Candidate algorithms for review commit 8cee870994f506b501bae3ea6bd4a3a7edb895c1.
   NOT executed in a Wolfram or Mathics kernel during this review.
   Load the original package first. Loading this file alone installs nothing.
   InstallIntegerPowerCandidate[] changes ONE package-private definition.
   RestoreIntegerPowerCandidate[] restores the captured definition.
   NonnegativeRationalPowerInterval is an independent candidate primitive;
   it is not automatically wired into the package's expression evaluator. *)

BeginPackage["AsymptoticAudit`"];
InstallIntegerPowerCandidate::usage = "InstallIntegerPowerCandidate[] installs the endpoint-range candidate for certIntegerPower.";
RestoreIntegerPowerCandidate::usage = "RestoreIntegerPowerCandidate[] restores the captured certIntegerPower definition.";
NonnegativeRationalPowerInterval::usage = "NonnegativeRationalPowerInterval[{lo,hi},p,ctx] encloses an exact rational power on its nonnegative real domain. ctx supplies Bits; fixed candidate limits are degree 128, exponent magnitude 100000 and work size 1000000 bits.";
Begin["`Private`"];

$rootFailureTag = "AsymptoticAuditRootFailure";
rootFailure[tag_, message_] := Throw[
  Failure[tag, <|"MessageTemplate" -> message|>], $rootFailureTag];

(* The original algorithm is retained for point endpoints and its existing
   dyadic rounding/resource policy. No large exact endpoint power is formed. *)
rangeIntegerPower[interval_, n_Integer, ctx_] := Module[
  {base = interval, degree = Abs[n], left, right},
  If[degree > 100000,
    originalIntegerPower[interval, n, ctx],
    If[n === 0, {1, 1},
      If[n < 0, base = AsymptoticAnalysis`Private`certReciprocal[base, ctx]];
      left = originalIntegerPower[{base[[1]], base[[1]]}, degree, ctx];
      right = originalIntegerPower[{base[[2]], base[[2]]}, degree, ctx];
      Which[
        OddQ[degree] || base[[1]] >= 0, {left[[1]], right[[2]]},
        base[[2]] <= 0, {right[[1]], left[[2]]},
        True, {0, Max[left[[2]], right[[2]]]}]]];

InstallIntegerPowerCandidate[] := If[TrueQ[$integerInstalled],
  "AlreadyInstalled",
  If[DownValues[AsymptoticAnalysis`Private`certIntegerPower] === {},
    Failure["PackageNotLoaded", <|"MessageTemplate" -> "Load AsymptoticAnalysis before installing the candidate."|>],
    DownValues[originalIntegerPower] =
      DownValues[AsymptoticAnalysis`Private`certIntegerPower] /.
        AsymptoticAnalysis`Private`certIntegerPower -> originalIntegerPower;
    DownValues[AsymptoticAnalysis`Private`certIntegerPower] = {};
    AsymptoticAnalysis`Private`certIntegerPower[a_, n_Integer, ctx_] :=
      AsymptoticAudit`Private`rangeIntegerPower[a, n, ctx];
    $integerInstalled = True;
    "Installed"]];

RestoreIntegerPowerCandidate[] := If[TrueQ[$integerInstalled],
  DownValues[AsymptoticAnalysis`Private`certIntegerPower] =
    DownValues[originalIntegerPower] /.
      originalIntegerPower -> AsymptoticAnalysis`Private`certIntegerPower;
  $integerInstalled = False;
  "Restored", "NotInstalled"];

(* Use integer Newton iteration. There are no Return[...,Module] constructs,
   symbolic finite Sum bodies, or floating-point root guesses in this file. *)
integerRootFloor[n_Integer, d_Integer] := Which[
  n < 2 || d === 1, n,
  d >= IntegerLength[n, 2], 1,
  True, Module[{x = 2^Ceiling[IntegerLength[n, 2]/d], y, done = False},
    While[! done,
      y = Quotient[(d - 1) x + Quotient[n, x^(d - 1)], d];
      If[y >= x, done = True, x = y]];
    x]];

floorLogTwo[q_] := Module[{e},
  e = IntegerLength[Numerator[q], 2] - IntegerLength[Denominator[q], 2];
  If[q < 2^e, e - 1, e]];

(* Cancellation before shifts is intentionally simple, exact, and bounded by
   the number of binary digits already present in the input integer. *)
scaledRatio[a0_, b0_, shift0_] := Module[{a = a0, b = b0, shift = shift0},
  If[shift >= 0,
    While[shift > 0 && EvenQ[a], a = Quotient[a, 2]; shift--];
    If[IntegerLength[b, 2] + shift > 1000000,
      rootFailure["RootWorkLimit", "Scaled denominator exceeds the candidate bit budget."]];
    b *= 2^shift,
    shift = -shift;
    While[shift > 0 && EvenQ[b], b = Quotient[b, 2]; shift--];
    If[IntegerLength[a, 2] + shift > 1000000,
      rootFailure["RootWorkLimit", "Scaled numerator exceeds the candidate bit budget."]];
    a *= 2^shift];
  {a, b}];

rootPoint[q_, degree_, bits_] := Module[
  {a = Numerator[q], b = Denominator[q], ra, rb, e, grid, scaled, m, lo},
  If[degree > 128, rootFailure["RootDegreeLimit", "Candidate root degree exceeds 128."]];
  If[Max[IntegerLength[a, 2], IntegerLength[b, 2]] > 1000000,
    rootFailure["RootWorkLimit", "Input rational exceeds the candidate bit budget."]];
  If[q === 0 || degree === 1, {q, q},
    ra = integerRootFloor[a, degree]; rb = integerRootFloor[b, degree];
    If[ra^degree === a && rb^degree === b, {ra/rb, ra/rb},
      e = Floor[floorLogTwo[q]/degree] - bits + 1;
      scaled = scaledRatio[a, b, degree e];
      m = integerRootFloor[Quotient[scaled[[1]], scaled[[2]]], degree];
      grid = 2^e; lo = m grid;
      {lo, If[m^degree scaled[[2]] === scaled[[1]], lo, (m + 1) grid]}]]];

NonnegativeRationalPowerInterval[interval_List, exponent_, ctx_Association] :=
  Catch[Module[{p, d, bits = ctx["Bits"], left, right},
    If[Length[interval] =!= 2 ||
        ! TrueQ[And @@ ((IntegerQ[#] || Head[#] === Rational) & /@ interval)] ||
        ! TrueQ[0 <= interval[[1]] <= interval[[2]]],
      rootFailure["RootDomain", "An ordered nonnegative exact rational interval is required."]];
    If[! (IntegerQ[exponent] || Head[exponent] === Rational),
      rootFailure["RootExponent", "An exact rational exponent is required."]];
    If[! IntegerQ[bits] || bits < 2,
      rootFailure["RootPrecision", "Bits must be an integer at least two."]];
    {p, d} = {Numerator[exponent], Denominator[exponent]};
    If[Abs[p] > 100000,
      rootFailure["RootExponentLimit", "Candidate exponent magnitude exceeds 100000."]];
    If[p < 0 && interval[[1]] === 0,
      rootFailure["RootDomain", "A negative power cannot include zero."]];
    left = rootPoint[interval[[1]], d, bits];
    right = rootPoint[interval[[2]], d, bits];
    (* This call uses the installed endpoint candidate, or the original safe
       power algorithm when the candidate has not been installed. *)
    AsymptoticAnalysis`Private`certIntegerPower[{left[[1]], right[[2]]}, p, ctx]
  ], $rootFailureTag];

End[];
EndPackage[];
