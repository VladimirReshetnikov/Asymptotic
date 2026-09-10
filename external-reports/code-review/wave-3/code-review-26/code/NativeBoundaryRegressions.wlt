(* Load the package BEFORE reading this file. These are acceptance tests, not
   characterizations: affected tests are expected to fail on the audited baseline. *)
SetAttributes[auditWithOptions, HoldAll];
auditWithOptions[body_] := Module[
  {constructor = Options[AsymptoticExpansion], alias = Options[AsymptoticExpand], value},
  value = CheckAbort[body,
    Options[AsymptoticExpansion] = constructor;
    Options[AsymptoticExpand] = alias; Abort[]];
  Options[AsymptoticExpansion] = constructor;
  Options[AsymptoticExpand] = alias;
  value];

VerificationTest[Module[{x,s},
 s=AsymptoticExpansion[Exp[x],{x,0,3}];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2],True,
 TestID->"NB00-ordinary-exclusive-cutoff-control"]

VerificationTest[Module[{x,s},
 s=AsymptoticExpansion[Exp[x],{x,0,3},"Backend"->"Series"];
 s["Kind"]==="Native" && s["NativeResult"]===Series[Exp[x],{x,0,3}]],True,
 TestID->"NB01-explicit-native-control"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,"Backend"->"Series"];
 s=AsymptoticExpansion[Exp[x],{x,0,3}];
 s["Kind"]==="Native" && Normal[s]===1+x+x^2/2+x^3/6]],True,
 TestID->"NB02-configured-backend"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,"Backend"->"Series"];
 s=AsymptoticExpansion[Exp[x],{x,0,3},"Backend"->"Package"];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2]],True,
 TestID->"NB03-explicit-backend-wins"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,SeriesTermGoal->4];
 s=AsymptoticExpansion[Exp[x],x->0];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2+x^3/6]],True,
 TestID->"NB04-configured-term-goal"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,SeriesTermGoal->4];
 s=AsymptoticExpansion[Exp[x],x->0,SeriesTermGoal->2];
 s["Kind"]==="Forward" && Normal[s]===1+x]],True,
 TestID->"NB05-explicit-term-goal-wins"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpand,"Backend"->"Series"];
 s=AsymptoticExpand[Exp[x],{x,0,3}];
 s["Kind"]==="Native" && Normal[s]===1+x+x^2/2+x^3/6]],True,
 TestID->"NB06-alias-backend-default"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpand,SeriesTermGoal->4];
 s=AsymptoticExpand[Exp[x],x->0];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2+x^3/6]],True,
 TestID->"NB07-alias-term-goal-default"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,"Backend"->"Series"];
 SetOptions[AsymptoticExpand,"Backend"->"Package"];
 s=AsymptoticExpand[Exp[x],{x,0,3}];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2]],True,
 TestID->"NB08-alias-override-precedes-constructor-default"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,"Backend"->"Series"];
 SetOptions[AsymptoticExpansion,"Backend"->Automatic];
 s=AsymptoticExpansion[Exp[x],{x,0,3}];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2]],True,
 TestID->"NB09-reset-defaults"]

VerificationTest[Module[{x,a,s,t},
 s=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},"Assumptions"->a>0];
 t=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},Assumptions->a>0];
 s["Kind"]===t["Kind"] && Normal[s]===Normal[t] && Normal[s]===a+a*x],True,
 TestID->"NB10-string-assumptions-package-cutoff"]

VerificationTest[Module[{x,a,s,n},
 n=Series[Sqrt[a^2]Exp[x],{x,0,2},"Assumptions"->a>0];
 s=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},"Backend"->"Series","Assumptions"->a>0];
 s["NativeResult"]===n && Normal[s]===Normal[n]],True,
 TestID->"NB11-string-assumptions-explicit-native"]

VerificationTest[Module[{x,s,t},
 s=AsymptoticExpansion[Exp[x],{x,0,2},"Analytic"->False];
 t=AsymptoticExpansion[Exp[x],{x,0,2},Analytic->False];
 s["Kind"]==="Native" && s["NativeResult"]===t["NativeResult"]],True,
 TestID->"NB12-string-native-only-option"]

VerificationTest[Module[{x,s},
 s=AsymptoticExpansion[Exp[x],x->0,"SeriesTermGoal"->4];
 s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2+x^3/6],True,
 TestID->"NB13-string-term-goal"]

VerificationTest[Module[{x,a,s,t},
 s=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},auditOptions`Assumptions->a>0];
 t=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},Assumptions->a>0];
 s["Kind"]===t["Kind"] && Normal[s]===Normal[t]],True,
 TestID->"NB14-context-equivalent-option-name"]

VerificationTest[Module[{s},
 s=AsymptoticExpansion[Exp[Method],Method->0,"Backend"->"Asymptotic"];
 s["Variable"]===Method && s["ExpansionSpecifications"]==={HoldComplete[Method->0]} && s[2]===1],True,
 TestID->"NB15-option-named-variable-explicit"]

VerificationTest[Module[{s},
 s=AsymptoticExpansion[Exp[Method],Method->0];
 s["Variable"]===Method && s["ExpansionSpecifications"]==={HoldComplete[Method->0]} && s[2]===1],True,
 TestID->"NB16-option-named-variable-automatic"]

VerificationTest[Module[{s},
 s=AsymptoticExpansion[Exp[Assumptions],Assumptions->0];
 s["Variable"]===Assumptions && s["ExpansionSpecifications"]==={HoldComplete[Assumptions->0]} && s[2]===1],True,
 TestID->"NB17-common-option-named-variable"]

VerificationTest[Module[{x,a,s,calls=0},
 s=AsymptoticExpansion[Sqrt[a^2]Exp[x],{x,0,2},"Assumptions":>(calls++;a>0)];
 calls===1 && s["Kind"]==="Forward" && Normal[s]===a+a*x],True,
 TestID->"NB18-delayed-string-assumption-consumed-once"]

VerificationTest[auditWithOptions[Module[{x,s,calls=0},
 SetOptions[AsymptoticExpansion,"Backend":>(calls++;"Series")];
 s=AsymptoticExpansion[Exp[x],{x,0,3}];
 calls===1 && s["Kind"]==="Native"]],True,
 TestID->"NB19-delayed-configured-selector"]

VerificationTest[auditWithOptions[Module[{x,s,calls=0},
 SetOptions[AsymptoticExpansion,SeriesTermGoal:>(calls++;4)];
 s=AsymptoticExpansion[Exp[x],x->0];
 calls===1 && s["Kind"]==="Forward" && Normal[s]===1+x+x^2/2+x^3/6]],True,
 TestID->"NB20-delayed-configured-goal"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,Analytic->False];
 s=AsymptoticExpansion[Exp[x],{x,0,2}];
 s["Kind"]==="Native" && s["NativeResult"]===Series[Exp[x],{x,0,2},Analytic->False]]],True,
 TestID->"NB21-configured-native-only-option"]

VerificationTest[auditWithOptions[Module[{x,s},
 SetOptions[AsymptoticExpansion,"MaxTerms"->3];
 s=AsymptoticExpansion[Exp[x],{x,0,2},"Backend"->"Series"];
 MatchQ[s,Failure["NativeOptionConflict",_Association]]]],True,
 TestID->"NB22-configured-package-budget-not-discarded"]

VerificationTest[Module[{s},
 s=AsymptoticExpansion[Exp[Method],Method->0,Method->Automatic];
 s["Variable"]===Method && s["ExpansionSpecifications"]==={HoldComplete[Method->0]} && s[2]===1],True,
 TestID->"NB23-same-symbol-in-two-positional-roles"]

VerificationTest[Module[{x,a,s,calls=0},
 s=AsymptoticExpansion[Sqrt[a^2]Exp[x],x->0,
 {{"Assumptions":>(calls++;a>0)},{"SeriesTermGoal"->4}}];
 calls===1 && s["Kind"]==="Forward" && Normal[s]===a+a*x+a*x^2/2+a*x^3/6],True,
 TestID->"NB24-nested-string-options"]
