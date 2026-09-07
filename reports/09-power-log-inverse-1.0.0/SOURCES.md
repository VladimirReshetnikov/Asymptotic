# Sources and provenance

Prepared September 7, 2026. The report's proofs are self-contained. The
coefficient identity is a specialization of classical Lagrange–Bürmann
inversion; no priority claim for a new general inversion theorem is made.

## The problem

Vladimir Reshetnikov, “How to get an asymptotic of the real-valued branch of the
inverse function?”, Mathematica Stack Exchange, question 236367 (December 2020):
https://mathematica.stackexchange.com/questions/236367/how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function

The user-supplied archive contained Markdown, HTML, and PDF copies. Its Markdown
was read in full, and the public page was also inspected. The two models used
here are `x + x^2 (1 + Log[x])` and `x + x^Sqrt[2]`. The archived irrational-power
coefficients are reproduced, not corrected. The informal remainder after the
first two logarithmic blocks requires the logarithmic factor stated in the
report. Historical Mathematica outputs were not rerun on a current kernel.

## Repository context

The directory listing and README were consulted using the GitHub connector:
https://github.com/VladimirReshetnikov/ProveIt/tree/main/Analysis/FabiusFunction/docs/semi-formalized-research-frontiers/drafts/series-and-transseries

Selected parts of the companion draft, *Combinatorial coefficient algebras for
transseries inverses*, were read, including its introduction, numerical and
remainder discussions, synthesis, collected coefficient formulas, and the
Wolfram recipe appendix:
https://github.com/VladimirReshetnikov/ProveIt/blob/main/Analysis/FabiusFunction/docs/semi-formalized-research-frontiers/drafts/series-and-transseries/Combinatorial_Transseries_Inverses/Combinatorial_Transseries_Inverses.tex

The large main source `Transseries_And_Inversion/transseries_and_inversion.tex`
was identified (reported size 1,241,489 bytes; blob SHA
`aec3c70d4793e286b462e7d8894dede7c754995e`), but the available content/blob
endpoints did not return its text successfully. It was not read in full, and
no result from an inaccessible section is used as a premise.

## Primary mathematical reference

NIST Digital Library of Mathematical Functions, §1.10, especially the residue,
Rouché, inverse-function, and Lagrange-inversion statements:
https://dlmf.nist.gov/1.10

## Wolfram Language documentation

The following official reference pages were consulted for the meaning of the
built-in operations and the native test-report interface, not as evidence of
execution of this package:

- https://reference.wolfram.com/language/ref/InverseSeries.html
- https://reference.wolfram.com/language/ref/SeriesData.html
- https://reference.wolfram.com/language/ref/AsymptoticSolve.html
- https://reference.wolfram.com/language/ref/TestReport.html
- https://reference.wolfram.com/language/ref/TestReportObject.html
- https://reference.wolfram.com/language/ref/VerificationTest.html

Both attempted calls to the connected Wolfram context/evaluator service
returned HTTP 404. No native kernel was available locally. The actual
executed verification is the independent Python program and the lexical
source audit described in `Verification/STATUS.md`.

## Reuse

External source files are not redistributed in this archive. The report
contains newly written exposition and proofs, with references. The software
is MIT-licensed; the new article is CC BY 4.0. See the respective license files.
