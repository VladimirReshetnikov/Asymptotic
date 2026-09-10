# Mathematical article

**[Real asymptotic expansions and inverse functions (PDF)](asymptotic-inverse.pdf)**
develops the mathematical theory of power–logarithmic expansions, real
inversion, convergence and asymptotic remainders, error transport, and the
extended scales used by the package. It contains mathematical examples
and algorithms, without package syntax or implementation history.

Package usage belongs to the separate
**[user guide](../../src/Documentation/UserGuide.html)**
([Markdown](../../src/Documentation/UserGuide.md)), organized in the
style of Wolfram documentation. It is this package's guide, not an official
Wolfram reference page.

## Sources and scope

| File or directory | Purpose |
| --- | --- |
| [asymptotic-inverse.tex](asymptotic-inverse.tex) | Main source: front matter, section order, shared notation, and bibliography. |
| [sections/](sections/) | Included mathematical sections; edit these sources to change the exposition. |
| [asymptotic-inverse.pdf](asymptotic-inverse.pdf) | Generated reader-facing article. |

Each theorem states its hypotheses. Formal jet identities, analytic remainder
bounds, convergence, parameter-uniform estimates, and numerical root
enclosures are separate claims. The introduction gives a reading map and
explains these distinctions before the detailed constructions.
Mathematical treatment of a class of expansions does not by itself establish
package support. Complete input coverage of built-in `Series` and `Asymptotic`
remains a development target tracked in the
[native compatibility plan](../development/NATIVE_COMPATIBILITY.md).
The user guide describes the implemented integration and its result contracts.

## Reading by topic

The PDF's linked table of contents follows the order set by the main TeX
source. Numeric source-file prefixes are stable identifiers; they do not
necessarily equal the section numbers in the PDF.

| Topic | Start with these sources |
| --- | --- |
| Basic scales and forward expansions | [Power–log blocks and jets](sections/02-scale.tex), then [closure and finite-order error propagation](sections/03-forward.tex). |
| Inverse coefficients and their justification | [Real branch selection](sections/04-branch.tex), [coefficient theorem](sections/06-coefficients.tex), [convergence](sections/07-convergence.tex), and [remainders](sections/08-remainders.tex). |
| Coordinates, composition, and refinement | [Coordinate transformations](sections/15-coordinates.tex), [complete weight layers](sections/25-refinement-state.tex), [transported precision](sections/17-calculus.tex), and [implicit inverse domains](sections/31-inverse-function-expressions.tex). |
| Logarithmic, flat, and oscillatory scales | [Logarithmic hierarchies](sections/20-logarithmic-scales.tex), [finite flat sectors](sections/21-flat-sectors.tex), and [Fourier coefficients](sections/22-fourier.tex). |
| Special functions and growing inverse cores | [Forward expansions and absolute envelopes](sections/35-special-function-expansions.tex), [normalization of Gamma and Barnes functions](sections/32-exponential-normalization.tex), [Gamma inversion](sections/33-gamma-inverse.tex), and [Barnes inversion](sections/34-barnes-inverse.tex). |
| Rigorous error at a fixed target | [Forward-error and residual transport](sections/09-transport.tex), then [interval root enclosures](sections/19-certificates.tex). |

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
python validation/inspect_pdf.py docs/article/asymptotic-inverse.pdf "$env:TEMP/asymptotic-article-review"
```

Inspect the contact sheets and any dense pages at full size. Geometry checks
alone do not establish readable layout. Commit the source and rebuilt PDF
together. Documentation-specific evidence is in
[validation/README.md](../../validation/README.md); each milestone's artifact
record identifies the PDF hash and the scope of its visual review. A review
of an earlier PDF does not establish that later source edits were built or
visually checked. Package tests are recorded separately.

The former software sections and engineering roadmap are preserved under
[docs/development/](../development/README.md); they are not included in this article.
The [documentation index](../README.md) also routes to review reports and
the separate vendored research library.
