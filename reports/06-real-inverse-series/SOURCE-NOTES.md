# Sources consulted and scope

Prepared September 7, 2026.

The local source was the user-uploaded archive
`how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function.zip`,
whose Markdown copy contains the complete question. The public question was
also consulted:
https://mathematica.stackexchange.com/questions/236367/how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function

The supplied repository directory:
https://github.com/VladimirReshetnikov/ProveIt/tree/main/Analysis/FabiusFunction/docs/semi-formalized-research-frontiers/drafts/series-and-transseries

The group README was read. Its observed Git blob SHA was
`516aaa30e84cb0036a00f803cb6e8e3026febb8e`.

Relevant sections of `Combinatorial_Transseries_Inverses/Combinatorial_Transseries_Inverses.tex`
were read: phase-coordinate inversion, coefficient formulas, action collisions,
convergent inverse transseries, and inverse-error transport. Its observed blob SHA
was `05c56ce5ee60788a67f365110b62810550cba817`.

The canonical `Transseries_And_Inversion/transseries_and_inversion.tex` file
was listed but could not be retrieved through the available connector because
of its size. Its observed blob SHA was
`aec3c70d4793e286b462e7d8894dede7c754995e`.
The distribution does not claim a full reading or audit of that volume or of
the repository's Lean modules.

Classical/official sources include:

- DLMF 1.10(vii), https://dlmf.nist.gov/1.10#vii
- Gessel, Lagrange Inversion, https://arxiv.org/abs/1609.05988
- Surya and Warnke, Lagrange Inversion Formula by Induction,
  https://arxiv.org/abs/2305.17576
- DLMF gamma asymptotics, https://dlmf.nist.gov/5.11
- Edgar, Transseries for beginners, https://arxiv.org/abs/0801.4877
- https://reference.wolfram.com/language/ref/SeriesData.html
- https://reference.wolfram.com/language/ref/InverseSeries.html
- https://reference.wolfram.com/language/ref/TestReportObject.html

The general Lagrange identity is classical and also appears in the supplied
companion. The present work specializes it to an explicit positive-real
power-log input class, proves the finite-border remainder contract, and
provides the concrete implementation. No general-inversion priority claim is
made. A bibliography entry or source comparison is not a claim that all
mathematics in that source was reverified.
