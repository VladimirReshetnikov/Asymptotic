(* Independent Bernoulli-logarithm oracles. Multiplying Stirling's logarithm
   by x moves its 1/(12x) term into the exact prefactor and leaves
     -1/(360x^2) + 1/(1260x^4) - 1/(1680x^6) + ... .
   Coefficients below follow by formal exponential multiplication, without
   native Series or package operations supplying expected values. *)
If[! MemberQ[$Packages, "AsymptoticInverse`"],
  Get[FileNameJoin[{DirectoryName[DirectoryName[$TestFileName]], "Kernel", "AsymptoticInverse.wl"}]]];

gammaVaryingStirlingPrefactor[z_] := Sqrt[2 Pi] Exp[-z] z^(z - 1/2);
gammaVaryingEqual[s_, expr_, ass_: True] :=
  MatchQ[s, _GeneralizedSeries] && TrueQ[FullSimplify[Normal[s] == expr, ass]];

VerificationTest[Module[{x, s, pref},
  pref = Exp[1/12] gammaVaryingStirlingPrefactor[x]^x;
  s = AsymptoticExpansion[Gamma[x]^x, x -> Infinity, SeriesTermGoal -> 3];
  {gammaVaryingEqual[s, pref (1 - 1/(360 x^2) + 1447/(1814400 x^4)), x > 0],
    s["Terms"], s["RemainderPower"], s["RemainderLogDegree"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^6, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == -pref 1170727/(1959552000 x^6), x > 0]],
    s["Exact"]}],
  {True, {{0, 1}, {2, -1/360}, {4, 1447/1814400}}, 6, 0, True, True, False},
  TestID -> "gamma-varying-power-x-moves-constant-log-correction-into-prefactor"]

VerificationTest[Module[{x, s, pref},
  pref = Exp[-1/12] gammaVaryingStirlingPrefactor[x]^-x;
  s = AsymptoticExpansion[Gamma[x]^-x, x -> Infinity, SeriesTermGoal -> 3];
  {gammaVaryingEqual[s, pref (1 + 1/(360 x^2) - 1433/(1814400 x^4)), x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^6, x > 0]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref 1162087/(1959552000 x^6), x > 0]]}],
  {True, {{0, 1}, {2, 1/360}, {4, -1433/1814400}}, 6, True, True},
  TestID -> "gamma-varying-negative-power-x-tracks-decaying-prefactor"]

VerificationTest[Module[{x, r, s, pref},
  pref = gammaVaryingStirlingPrefactor[x]^r;
  s = AsymptoticExpansion[Gamma[x]^r, x -> Infinity,
    Assumptions -> Element[r, Reals], SeriesTermGoal -> 3];
  {gammaVaryingEqual[s, pref (1 + r/(12 x) + r^2/(288 x^2)),
      x > 0 && Element[r, Reals]],
    s["RemainderPower"], Length[s["Terms"]],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref (r^3/10368 - r/360)/x^3,
      x > 0 && Element[r, Reals]]],
    s["Assumptions"] === Element[r, Reals]}],
  {True, 3, 3, True, True},
  TestID -> "gamma-varying-real-parameter-power-retains-symbolic-coefficients-and-assumptions"]

VerificationTest[Module[{x, s, pref},
  (* The product logarithm has correction 1/(8x)-1/(320x^3)+11/(13440x^5).
     Multiplying by x/2 gives the exact constant 1/16 and even corrections. *)
  pref = Exp[1/16] (gammaVaryingStirlingPrefactor[x]
      gammaVaryingStirlingPrefactor[2 x])^(x/2);
  s = AsymptoticExpansion[(Gamma[x] Gamma[2 x])^(x/2),
    x -> Infinity, SeriesTermGoal -> 3];
  {gammaVaryingEqual[s, pref (1 - 1/(640 x^2) + 7061/(17203200 x^4)), x > 0],
    s["Terms"], s["RemainderPower"],
    TrueQ[FullSimplify[s["RemainderScaleExpression"] == pref/x^6, x > 0]]}],
  {True, {{0, 1}, {2, -1/640}, {4, 7061/17203200}}, 6, True},
  TestID -> "gamma-varying-positive-product-fractional-variable-power"]

VerificationTest[Module[{x, s, refined},
  s = AsymptoticExpansion[Gamma[x + 1]^x/Gamma[x]^x,
    x -> Infinity, SeriesTermGoal -> 5];
  refined = SeriesRefine[s, 8];
  {gammaVaryingEqual[s, x^x, x > 0], s["Remainder"], s["Exact"],
    gammaVaryingEqual[refined, x^x, x > 0], refined["Remainder"], refined["Exact"]}],
  {True, 0, True, True, 0, True},
  TestID -> "gamma-varying-exact-recurrence-cancellation-terminates-and-refines"]

VerificationTest[Module[{x, s, refined, pref},
  pref = Exp[1/12] gammaVaryingStirlingPrefactor[x]^x;
  s = AsymptoticExpansion[ConditionalExpression[Gamma[x]^x, x > 2],
    x -> Infinity, SeriesTermGoal -> 2];
  refined = SeriesRefine[s, 6];
  {gammaVaryingEqual[refined, pref (1 - 1/(360 x^2) + 1447/(1814400 x^4)), x > 2],
    TrueQ[(s["TargetDomain"] /. x -> 1) === False],
    TrueQ[(refined["TargetDomain"] /. x -> 1) === False],
    TrueQ[refined["TargetDomain"] /. x -> 3], refined["RemainderPower"]}],
  {True, True, True, True, 6},
  TestID -> "gamma-varying-source-refinement-preserves-conditional-domain"]

VerificationTest[Module[{x, s, expectedLogPrefactor},
  (* After its exact 1/36 constant, the combined logarithm starts
     -1/(12x)-1/(9720x^2)+1/(360x^3), giving c_2=131/38880. *)
  expectedLogPrefactor = 1/36
    + x ((3 x - 1/2) Log[3 x] - 3 x + Log[2 Pi]/2)
    - ((x - 1/2) Log[x] - x + Log[2 Pi]/2);
  s = AsymptoticExpansion[Gamma[3 x]^x/Gamma[x], x -> Infinity, SeriesTermGoal -> 3];
  {TrueQ[FullSimplify[Log[s["Prefactor"]] - expectedLogPrefactor, x > 0] === 0],
    s["Terms"], s["RemainderPower"], s["Exact"]}],
  {True, {{0, 1}, {1, -1/12}, {2, 131/38880}}, 3, False},
  TestID -> "gamma-varying-mixed-powered-ratio-has-independent-correction-coefficients"]

VerificationTest[Module[{x, s, pref, next},
  (* Multiplying (x(Log[x]-1)-Log[x]/2+Log[2Pi]/2+1/(12x)+...)
     by Sqrt[x](1-1/(2x)-1/(8x^2)+...) gives this nonvanishing
     logarithmic part and first vanishing coefficient. The constant
     5/24 in that coefficient is 1/12+1/8. *)
  pref = Exp[x^(3/2) (Log[x] - 1)
    + Sqrt[x] (-Log[x] + (1 + Log[2 Pi])/2)];
  next = (Log[x]/8 + 5/24 - Log[2 Pi]/4)/Sqrt[x];
  s = AsymptoticExpansion[Gamma[x]^Sqrt[x - 1],
    x -> Infinity, SeriesTermGoal -> 1];
  {gammaVaryingEqual[s, pref, x > 1], s["Terms"],
    s["RemainderPower"], s["RemainderLogDegree"],
    TrueQ[FullSimplify[s["FrontierTerm"] == pref next, x > 1]], s["Exact"]}],
  {True, {{0, 1}}, 1/2, 1, True, False},
  TestID -> "gamma-varying-shifted-root-exponent-has-eventually-real-domain"]

VerificationTest[Module[{x, r},
  Quiet[FailureQ[AsymptoticExpansion[Gamma[x]^r,
    x -> Infinity, SeriesTermGoal -> 3]]]],
  True,
  TestID -> "gamma-varying-symbolic-power-needs-explicit-real-parameter-assumption"]

VerificationTest[Module[{x, s, refined},
  (* The exact Gamma recurrence first gives x(x-1). Its logarithmic source
     still contains an infinite Log[1-1/x] correction, so exact termination
     must use the retained identity rather than finite coefficient zeros. *)
  s = AsymptoticExpansion[(x - 1) Gamma[x + 1]/Gamma[x],
    x -> Infinity, SeriesTermGoal -> 5];
  refined = SeriesRefine[s, 7];
  {gammaVaryingEqual[s, x (x - 1), x > 1],
    s["Remainder"], s["Exact"],
    gammaVaryingEqual[refined, x (x - 1), x > 1],
    refined["Remainder"], refined["Exact"]}],
  {True, 0, True, True, 0, True},
  TestID -> "gamma-varying-exact-recurrence-polynomial-factor-terminates-and-refines"]
