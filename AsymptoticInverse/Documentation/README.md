# Package user guide

Read the **[rendered user guide](UserGuide.html)** or its
**[Markdown source](UserGuide.md)**. The guide is organized around Wolfram
Language usage forms, Details and Options, Examples, Applications,
Properties & Relations, Possible Issues, See Also, and Related Guides.
It documents this custom package and is not an official Wolfram reference page.

The separate **[mathematical article](../../article/asymptotic-inverse.pdf)**
contains definitions, theorems, and proofs.

## Rebuild

With Python and Pandoc on PATH, run from the repository root:

```powershell
python validation/build_user_guide.py
python validation/build_user_guide.py --check
```

The HTML embeds [UserGuide.css](UserGuide.css) and requires no external
assets or JavaScript. The builder checks unique anchors, local link
destinations, and reference coverage for every public symbol declared by
the package. Open the HTML in a browser and inspect both wide and narrow
layouts after changes. Commit Markdown, CSS, and generated HTML together.

Focused native documentation examples are checked separately by
`validation/CheckDocumentation.wl`; this is not the full package test suite.
See the [validation record](../../validation/README.md) for recorded results.
