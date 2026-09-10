(* Candidate helper library, NOT an installed package patch.
   Exact Python counterparts were tested; this WL translation has not been
   executed in either kernel. Load in a fresh kernel before acceptance tests.
   It does not modify System or AsymptoticAnalysis definitions. *)
BeginPackage["AsymptoticReviewSupport`"];
RationalGermCertificate::usage =
 "RationalGermCertificate[p,u,maxDegree] constructs an exact sign certificate for a nonzero rational polynomial on 0<u<r. It is not a global injectivity proof.";
CheckRationalGermCertificate::usage =
 "CheckRationalGermCertificate[c] independently checks the rational polynomial certificate fields and sufficient tail inequality.";
TerminatingPFQPolynomial::usage =
 "TerminatingPFQPolynomial[upper,lower,z,maxDegree] returns an exact terminating pFq polynomial. All parameters must be rational, and nonpositive integer lower parameters are refused.";
Begin["`Private`"];

rationalQ[x_] := MatchQ[x, _Integer | _Rational];
nonpositiveIntegerQ[x_] := IntegerQ[x] && x <= 0;
reviewFailure[tag_, message_] := System`Failure[tag, <|"MessageTemplate" -> message|>];

RationalGermCertificate[p_, u_Symbol, maxDegree_: 1000] := Module[
 {degree, coefficients, indices, m, leading, tail, radius},
 If[! IntegerQ[maxDegree] || maxDegree < 0,
  reviewFailure["Budget", "maxDegree must be a nonnegative integer."],
  If[! PolynomialQ[p, u] || TrueQ[p === 0],
   reviewFailure["Domain", "Use a nonzero rational polynomial."],
   degree = Exponent[p, u];
   If[! IntegerQ[degree] || degree > maxDegree,
    reviewFailure["Budget", "Polynomial degree exceeds the admitted bound."],
    coefficients = CoefficientList[p, u];
    If[! And @@ (rationalQ /@ coefficients),
     reviewFailure["Domain", "Only exact rational coefficients are admitted."],
     indices = Select[Range[Length[coefficients]], coefficients[[#]] =!= 0 &];
     m = First[indices] - 1; leading = coefficients[[m + 1]];
     tail = Total[Abs /@ Drop[coefficients, m + 1]];
     radius = If[tail === 0, 1, Min[1, Abs[leading]/(2 tail)]];
     <|"Coefficients" -> coefficients, "Valuation" -> m, "Leading" -> leading,
       "TailL1" -> tail, "Radius" -> radius, "Sign" -> Sign[leading],
       "Scope" -> "Strict sign on 0<u<Radius; no parameter or global branch theorem."|>
    ]
   ]
  ]
 ]
];
RationalGermCertificate[___] := reviewFailure["Arguments", "Use p, a fresh symbol u, and an optional integer budget."];

CheckRationalGermCertificate[c_Association] := Module[
 {a = c["Coefficients"], m = c["Valuation"], lead = c["Leading"],
  tail = c["TailL1"], r = c["Radius"], sign = c["Sign"], actualM, actualTail},
 If[! ListQ[a] || a === {} || ! And @@ (rationalQ /@ a) ||
    ! rationalQ[r] || ! TrueQ[0 < r <= 1] || ! IntegerQ[m] || Last[a] === 0,
  False,
  actualM = First[Select[Range[Length[a]], a[[#]] =!= 0 &]] - 1;
  actualTail = Total[Abs /@ Drop[a, actualM + 1]];
  TrueQ[m === actualM && lead === a[[actualM + 1]] && tail === actualTail &&
    sign === Sign[lead] && tail r <= Abs[lead]/2]
 ]
];
CheckRationalGermCertificate[_] := False;

TerminatingPFQPolynomial[upper_List, lower_List, z_Symbol, maxDegree_: 1000] := Module[
 {degrees, n, coefficients, k},
 If[! IntegerQ[maxDegree] || maxDegree < 0 ||
    ! And @@ (rationalQ /@ Join[upper, lower]),
  reviewFailure["Domain", "Use rational parameters and a nonnegative integer degree budget."],
  If[Or @@ (nonpositiveIntegerQ /@ lower),
   reviewFailure["ParameterPole", "No convention for nonpositive integer lower parameters is selected."],
   degrees = -Select[upper, nonpositiveIntegerQ];
   If[degrees === {},
    reviewFailure["Nonterminating", "No terminating upper parameter was proved."],
    n = Min[degrees];
    If[n > maxDegree,
     reviewFailure["Budget", "The terminating degree exceeds maxDegree."],
     coefficients = ConstantArray[0, n + 1]; coefficients[[1]] = 1;
     Do[coefficients[[k + 2]] = coefficients[[k + 1]]
        (Times @@ ((# + k) & /@ upper))/
        ((k + 1) (Times @@ ((# + k) & /@ lower))), {k, 0, n - 1}];
     Total[Table[coefficients[[k + 1]] z^k, {k, 0, n}]]
    ]
   ]
  ]
 ]
];
TerminatingPFQPolynomial[___] := reviewFailure["Arguments", "Use upper/lower parameter lists, a fresh variable, and an optional integer budget."];
End[];
EndPackage[];
