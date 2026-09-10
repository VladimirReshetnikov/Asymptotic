(* Native front-end preview; independent of the package regression suite.
   Run: wolfram.exe -script validation/RenderFormatting.wl *)
formattingRenderRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{formattingRenderRoot, "src", "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[x, y];
formattingRenderSeries = AsymptoticInverse[x + x^2, {x, 0}, {y, 5}];
formattingRenderExact = AsymptoticExpansion[1 + x, {x, 0, 2}];
formattingRenderPure = AsymptoticExpansion[x^3, {x, 0, 2}];
formattingRenderGamma = AsymptoticExpansion[LogGamma[x], x -> Infinity, SeriesTermGoal -> 5];
formattingRenderRows = {
  {Style["GeneralizedSeries: native notebook display", Bold, 20], SpanFromLeft},
  {"StandardForm[s]", StandardForm[formattingRenderSeries]},
  {"TraditionalForm[s]", TraditionalForm[formattingRenderSeries]},
  {"Normal[s]", StandardForm[Normal[formattingRenderSeries]]},
  {"exact series squared", StandardForm[formattingRenderExact^2]},
  {"twice an exact series", StandardForm[2 formattingRenderExact]},
  {"reciprocal of an exact series", StandardForm[1/formattingRenderExact]},
  {"pure remainder", StandardForm[formattingRenderPure]},
  {"Normal[pure remainder]", StandardForm[Normal[formattingRenderPure]]},
  {"logarithmic remainder at infinity", StandardForm[PowerLogRemainder[1/x, 4, 2]]},
  {"LogGamma expansion", StandardForm[formattingRenderGamma]}};
formattingRenderImage = TimeConstrained[UsingFrontEnd[Rasterize[
  Framed[Style[Grid[formattingRenderRows, Alignment -> Left, Spacings -> {3, 1.5},
    Dividers -> {None, {False, True, False}}, Background -> White], FontSize -> 16],
    FrameStyle -> None, FrameMargins -> 20],
  "Image", ImageResolution -> 120, ImageFormattingWidth -> 1100, Background -> White]], 120, $Aborted];
If[! ImageQ[formattingRenderImage], Print["Native preview failed: ", InputForm[formattingRenderImage]]; Exit[1]];
formattingRenderPath = FileNameJoin[{formattingRenderRoot, "validation", "formatting-preview.png"}];
Export[formattingRenderPath, formattingRenderImage];
Print["Native preview: ", formattingRenderPath, "\nDimensions: ", ImageDimensions[formattingRenderImage]];
Exit[0];
