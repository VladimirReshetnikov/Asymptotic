# Mathematical article

**[Real asymptotic expansions and inverse functions (PDF)](asymptotic-inverse.pdf)**
develops the mathematical theory of power–logarithmic expansions, real
inversion, convergence and asymptotic remainders, error transport, and the
extended scales used by the package. It contains mathematical examples
and algorithms, without package syntax or implementation history.

Package usage belongs to the separate
**[user guide](../AsymptoticInverse/Documentation/UserGuide.html)**
([Markdown](../AsymptoticInverse/Documentation/UserGuide.md)).

## Build and inspect

From this directory, run three serial LaTeX passes to resolve the table of
contents, equation references, and bibliography:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-inverse.tex
```

From the repository root, render every page with Poppler and generate
contact sheets and geometry diagnostics (Python requires Pillow and pdfplumber):

```powershell
python validation/inspect_pdf.py article/asymptotic-inverse.pdf "$env:TEMP/asymptotic-article-review"
```

Inspect the contact sheets and any dense pages at full size. Geometry checks
alone do not establish readable layout. Commit the source and rebuilt PDF
together. Documentation-specific evidence is in
[validation/README.md](../validation/README.md).

The former software chapters and engineering roadmap are preserved under
[docs/development/](../docs/development/); they are not included in this article.
