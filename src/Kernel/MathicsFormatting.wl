(* Loaded after the analytic engines, in AsymptoticAnalysis`Private`.
   Mathics' TagSetDelayed cannot discover the tag beneath the named outer
   pattern used by the ordinary-arithmetic API.  Direct UpValues assignment
   installs those same patterns without changing any System definition. *)

If[StringQ[$Version] && StringContainsQ[$Version, "Mathics"], Block[{$seriesArithmeticEnabled = False},
  mathicsArithmeticRules = {
    HoldPattern[expression : Plus[___, s_GeneralizedSeries, ___] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>
      seriesArithmeticAutomatic[HoldComplete[expression]],
    HoldPattern[expression : Times[___, s_GeneralizedSeries, ___] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>
      seriesArithmeticAutomatic[HoldComplete[expression]],
    HoldPattern[expression : Power[s_GeneralizedSeries, _] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>
      seriesArithmeticAutomatic[HoldComplete[expression]],
    HoldPattern[expression : Power[_, s_GeneralizedSeries] /;
      TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>
      seriesArithmeticAutomatic[HoldComplete[expression]]
  };
  mathicsArithmeticRules = Join[mathicsArithmeticRules,
    Function[head, With[{h = head},
      HoldPattern[expression : h[s_GeneralizedSeries] /;
        TrueQ[$seriesArithmeticEnabled] && seriesArithmeticObjectQ[s]] :>
        seriesArithmeticAutomatic[HoldComplete[expression]]]] /@
    {Log, Exp, Abs, Sin, Cos, Tan, Sinh, Cosh, Tanh, ArcSin, ArcCos, ArcTan}];
  (* Reading Mathics UpValues can add HoldPattern wrappers.  Remove our own
     previous arithmetic rules structurally instead of relying on SameQ
     deduplication, so repeated Get does not accumulate duplicate rules. *)
  UpValues[GeneralizedSeries] = Join[
    Select[UpValues[GeneralizedSeries],
      FreeQ[#, HoldPattern[seriesArithmeticAutomatic[_HoldComplete]]] &],
    mathicsArithmeticRules];
  (* An explicit head avoids Mathics treating Pattern as the formatting tag. *)
  Format[PowerLogRemainder[w_, b_, k_], OutputForm] :=
    With[{sc = remainderScale[PowerLogRemainder[w, b, k]]}, HoldForm[O[sc]]]
]];
