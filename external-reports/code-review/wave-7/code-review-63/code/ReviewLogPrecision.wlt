(* Desired-contract tests. Load the combined candidate before TestReport.
   The individual cases were probed natively, but this complete WLT file was
   not run through MUnit in this audit. Baseline failures are expected. *)
VerificationTest[
  Module[{d=2^-200,ctx,v},
    ctx=<|"SeriesOrder"->2,"Bits"->48,"ExponentMagnitudeLimit"->10000|>;
    v=AsymptoticAnalysis`Private`certLogPoint[1-d,ctx];
    v[[2]]<0 && (v[[2]]-v[[1]])/d<2^-44],
  True, TestID->"review-log-reciprocal-relative-width"]
VerificationTest[
  Module[{x,d=2^-200,ctx,v},
    ctx=<|"SeriesOrder"->2,"Bits"->48,"ExponentMagnitudeLimit"->10000|>;
    v=AsymptoticAnalysis`Private`certLogExpression[1+x,x,{d,d},ctx];
    v[[1]]>0 && (v[[2]]-v[[1]])/d<2^-44],
  True, TestID->"review-log-affine-relative-width"]
VerificationTest[
  Module[{x,y,d=2^-200,s,r},
    s=AsymptoticAnalysis`AsymptoticInverse[Log[x],{x,1},{y,3},Direction->"FromBelow"];
    r=AsymptoticAnalysis`InverseCertificate[s,Log[1-d],
      "Interval"->{1-2d,1-d/2},"Center"->1-d,
      "EnclosureOrder"->2,"MaxRefinements"->0];
    If[AssociationQ[r],TrueQ[r["Certified"] &&
      r["RootEnclosure"][[1]]<=1-d<=r["RootEnclosure"][[2]] &&
      r["CertifiedErrorBound"]<d/8],False]],
  True, TestID->"review-log-public-A"]
VerificationTest[
  Module[{x,y,d=2^-200,s,r},
    s=AsymptoticAnalysis`AsymptoticInverse[Log[1+x],{x,0},{y,3}];
    r=AsymptoticAnalysis`InverseCertificate[s,Log[1+d],
      "Interval"->{d/2,2d},"Center"->d,
      "EnclosureOrder"->2,"MaxRefinements"->0];
    If[AssociationQ[r],TrueQ[r["Certified"] &&
      r["RootEnclosure"][[1]]<=d<=r["RootEnclosure"][[2]] &&
      r["CertifiedErrorBound"]<d/8],False]],
  True, TestID->"review-log-public-B"]
VerificationTest[
  Module[{x,y,d=2^-200,s,r},
    s=AsymptoticAnalysis`AsymptoticInverse[Log[1+x],{x,0},{y,3},Direction->"FromBelow"];
    r=AsymptoticAnalysis`InverseCertificate[s,Log[1-d],
      "Interval"->{-2d,-d/2},"Center"->-d,
      "EnclosureOrder"->2,"MaxRefinements"->0];
    If[AssociationQ[r],TrueQ[r["Certified"] &&
      r["RootEnclosure"][[1]]<=-d<=r["RootEnclosure"][[2]] &&
      r["CertifiedErrorBound"]<d/8],False]],
  True, TestID->"review-log-public-C"]
VerificationTest[
  AsymptoticAnalysis`Private`certLogPoint[1,
    <|"SeriesOrder"->2,"Bits"->48,"ExponentMagnitudeLimit"->10000|>],
  {0,0}, TestID->"review-log-exact-one"]
VerificationTest[
  First[AsymptoticAnalysis`Private`catch[
    AsymptoticAnalysis`Private`certLogPoint[0,
      <|"SeriesOrder"->2,"Bits"->48,"ExponentMagnitudeLimit"->10000|>]]],
  "IntervalDomain", TestID->"review-log-domain-preserved"]
VerificationTest[
  Module[{x,d=2^-200},
    AsymptoticAnalysis`Private`certLogExpression[(1+x)/(1+d),x,{d,d},
      <|"SeriesOrder"->2,"Bits"->48,"ExponentMagnitudeLimit"->10000|>]],
  {0,0}, TestID->"review-log-centered-ratio-primitive"]
