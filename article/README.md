# Mathematical article

**[Real asymptotic expansions and inverse functions (PDF)](asymptotic-inverse.pdf)**
develops the mathematical theory of power–logarithmic expansions, real
inversion, convergence and asymptotic remainders, error transport, and the
extended scales used by the package. It contains mathematical examples
and algorithms, without package syntax or implementation history.

Package usage belongs to the separate
**[user guide](../AsymptoticAnalysis/Documentation/UserGuide.html)**
([Markdown](../AsymptoticAnalysis/Documentation/UserGuide.md)), organized in the
style of Wolfram documentation. It is this package's guide, not an official
Wolfram reference page.

## Sources and scope

| File or directory | Purpose |
| --- | --- |
| [asymptotic-inverse.tex](asymptotic-inverse.tex) | Main source: front matter, chapter order, shared notation, and bibliography. |
| [sections/](sections/) | Included mathematical chapters; edit these sources to change the exposition. |
| [asymptotic-inverse.pdf](asymptotic-inverse.pdf) | Generated reader-facing article. |

Each theorem states its hypotheses. Formal jet identities, analytic remainder
bounds, convergence, and parameter-uniform estimates are separate claims.
Mathematical treatment of a class of expansions does not by itself establish
package support. In particular, complete compatibility with built-in `Series`
and `Asymptotic` is a
[pending implementation plan](../docs/development/NATIVE_COMPATIBILITY.md).

## Build and inspect

From this directory, run three serial LaTeX passes to resolve the table of
contents, equation references, and bibliography:

```powershell
pdflatex -no-shell-escape -interaction=nonstopmode -halt-on-error -file-line-error asymptotic-inverse.tex
pdflatex -no-shell-escape -interaction=nonstopmode -halt-on-error -file-line-error asymptotic-inverse.tex
pdflatex -no-shell-escape -interaction=nonstopmode -halt-on-error -file-line-error asymptotic-inverse.tex
```

From the repository root, render every page with Poppler and generate
contact sheets and geometry diagnostics (Python requires Pillow and pdfplumber):

```powershell
python validation/inspect_pdf.py article/asymptotic-inverse.pdf "$env:TEMP/asymptotic-article-review"
```

Inspect the contact sheets and any dense pages at full size. Geometry checks
alone do not establish readable layout. Commit the source and rebuilt PDF
together. Documentation-specific evidence is in
[validation/README.md](../validation/README.md); each milestone's artifact
record identifies the PDF hash and the scope of its visual review. A review
of an earlier PDF does not establish that later source edits were built or
visually checked. Package tests are recorded separately.

The former software chapters and engineering roadmap are preserved under
[docs/development/](../docs/development/README.md); they are not included in this article.
The [documentation index](../docs/README.md) also routes to review reports and
the separate vendored research library.
