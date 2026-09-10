(* Native front-end preview of the arithmetic API.
   Run: wolfram.exe -script validation/RenderSeriesArithmetic.wl *)
arithmeticRenderRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{arithmeticRenderRoot, "AsymptoticAnalysis", "Kernel", "AsymptoticAnalysis.wl"}]];
Clear[x, a, b, exact];
a = AsymptoticExpansion[Sin[x], {x, 0, 5}];
b = AsymptoticExpansion[Cos[x], {x, 0, 4}];
exact = AsymptoticExpansion[x, {x, 0, 2}];
arithmeticRenderRows = {
  {Style["Automatic series arithmetic", Bold, 20], SpanFromLeft},
  {"a = expansion of Sin[x]", StandardForm[a]},
  {"b = expansion of Cos[x]", StandardForm[b]},
  {"a + b", StandardForm[a + b]},
  {"a b", StandardForm[a b]},
  {"a/(1 + x)", StandardForm[a/(1 + x)]},
  {"Sqrt[b]", StandardForm[Sqrt[b]]},
  {"Sin[x] a", StandardForm[Sin[x] a]},
  {"Normal[a b]", StandardForm[Normal[a b]]},
  {"normalize (1+a)/(1-a), cutoff 4", StandardForm[SeriesNormalize[(1 + a)/(1 - a), "Cutoff" -> 4]]},
  {"normalize 1/(Exp[exact]-1-exact), cutoff 3",
    StandardForm[SeriesNormalize[1/(Exp[exact] - 1 - exact), "Cutoff" -> 3]]}};
If[! FreeQ[arithmeticRenderRows, _Failure], Print["An arithmetic preview expression failed."]; Exit[1]];
arithmeticRenderImage = TimeConstrained[UsingFrontEnd[Rasterize[
  Framed[Style[Grid[arithmeticRenderRows, Alignment -> Left, Spacings -> {3, 1.5},
    Dividers -> {None, {False, True, False}}, Background -> White], FontSize -> 16],
    FrameStyle -> None, FrameMargins -> 20],
  "Image", ImageResolution -> 120, ImageFormattingWidth -> 1300, Background -> White]], 120, $Aborted];
If[! ImageQ[arithmeticRenderImage], Print["Native preview failed: ", InputForm[arithmeticRenderImage]]; Exit[1]];
arithmeticRenderPath = FileNameJoin[{arithmeticRenderRoot, "validation", "series-arithmetic-preview.png"}];
Export[arithmeticRenderPath, arithmeticRenderImage];
Print["Native preview: ", arithmeticRenderPath, "\nDimensions: ", ImageDimensions[arithmeticRenderImage]];
Exit[0];
