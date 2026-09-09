(* Native StandardForm and Normal preview; never runs the full suite. *)
specialRenderRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{specialRenderRoot, "AsymptoticInverse", "Kernel", "AsymptoticInverse.wl"}]];
Clear[x];
bessel = AsymptoticExpansion[BesselI[0, x] BesselK[0, x], x -> Infinity, SeriesTermGoal -> 3];
gaussian = AsymptoticExpansion[Erfc[x], x -> Infinity, SeriesTermGoal -> 3];
oscillatory = AsymptoticExpansion[BesselJ[0, x], x -> Infinity, SeriesTermGoal -> 2];
zeta = AsymptoticExpansion[Zeta[x], x -> Infinity, SeriesTermGoal -> 3];
lerch = AsymptoticExpansion[LerchPhi[1/2, 2, x], x -> Infinity, SeriesTermGoal -> 3];
specialRenderRows = {
  {Style["Special-function expansions", Bold, 20], SpanFromLeft},
  {"BesselI[0,x] BesselK[0,x]", StandardForm[bessel]},
  {"Normal: ordinary expression", StandardForm[Normal[bessel]]},
  {"Erfc[x]", StandardForm[gaussian]},
  {"Normal: ordinary expression", StandardForm[Normal[gaussian]]},
  {"BesselJ[0,x]", StandardForm[oscillatory]},
  {"Zeta[x]", StandardForm[zeta]},
  {"LerchPhi[1/2,2,x]", StandardForm[lerch]}};
If[! FreeQ[specialRenderRows, _Failure], Print["A special-function preview failed."]; Exit[1]];
specialRenderImage = TimeConstrained[UsingFrontEnd[Rasterize[
  Framed[Style[Grid[specialRenderRows, Alignment -> Left, Spacings -> {3, 1.5},
    Background -> White], FontSize -> 16], FrameStyle -> None, FrameMargins -> 20],
  "Image", ImageResolution -> 120, ImageFormattingWidth -> 1300, Background -> White]], 120, $Aborted];
If[! ImageQ[specialRenderImage], Print["Native preview failed."]; Exit[1]];
specialRenderPath = FileNameJoin[{specialRenderRoot, "validation", "special-functions-preview.png"}];
Export[specialRenderPath, specialRenderImage];
Print["Native preview: ", specialRenderPath, "\nDimensions: ", ImageDimensions[specialRenderImage]];
Exit[0];
