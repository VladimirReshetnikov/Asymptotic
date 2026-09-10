(* SOURCE EXCERPT ONLY, NOT A LOADABLE COPY OF THE PACKAGE.
   Upstream commit: 07a9781212beb2eeb9ff16aa625b50ac27974078
   Core blob: ea9eaf4a11130e922ac4fb3faae37fd8e8d29643
   Selected definitions from AsymptoticInverse/Kernel/AsymptoticInverse.wl.
   See UPSTREAM-LICENSE.txt. Used to unit-test the patch transformation. *)
makeSeriesData[terms_, x_, x0_, coord_, remData_, logw_] := Module[{exps, den, nmin, nmax, coeffs, ptx, dirSign},
  If[coord["Direction"] === "FromBelow" && ! coord["Infinite"], Return[Missing["NotAvailable"], Module]];
  If[x0 === -Infinity, Return[Missing["NotAvailable"], Module]];
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = If[exps === {}, remData[[1]] den, Min[exps] den]; nmax = remData[[1]] den;
  coeffs = Table[0, {nmax - nmin}];
  Do[coeffs[[t[[1]] den - nmin + 1]] = t[[2]], {t, terms}];
  SeriesData[x, x0, coeffs, nmin, nmax, den]];

makeInverseSeriesData[terms_, y_, y0_, a_, coord_, remData_, r_, x0_] := Module[{exps, den, nmin, nmax, coeffs},
  If[r =!= 1 || coord["Sign"] =!= 1 || coord["Infinite"] || x0 =!= 0, Return[Missing["NotAvailable"], Module]];
  If[y0 === Infinity || y0 === -Infinity, Return[Missing["NotAvailable"], Module]];
  exps = terms[[All, 1]];
  If[! (And @@ (IntegerQ[#] || Head[#] === Rational & /@ exps)), Return[Missing["IrrationalExponents"], Module]];
  If[remData === None, Return[Missing["Exact"], Module]];
  If[! (IntegerQ[remData[[1]]] || Head[remData[[1]]] === Rational), Return[Missing["IrrationalExponents"], Module]];
  den = LCM @@ (Denominator /@ Append[exps, remData[[1]]]);
  nmin = Min[exps] den; nmax = remData[[1]] den;
  coeffs = Table[0, {nmax - nmin}];
  Do[coeffs[[t[[1]] den - nmin + 1]] = a^(-t[[1]]) t[[2]], {t, terms}];
  SeriesData[y, y0, coeffs, nmin, nmax, den]];

