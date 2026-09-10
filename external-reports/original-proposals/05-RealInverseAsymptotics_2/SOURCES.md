# Sources and provenance

Prepared 7 September 2026.

## Motivating question

Vladimir Reshetnikov, “How to get an asymptotic of the real-valued branch of the
inverse function?”, Mathematica Stack Exchange question 236367, asked
11 December 2020 and edited 13 December 2020:
https://mathematica.stackexchange.com/questions/236367/how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function

The supplied archive
`how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function.zip`
was read directly. Its Markdown copy was checked against the live question.
Its examples are `x+x^2(1+Log[x])` and `x+x^Sqrt[2]`. No accepted iterative
answer is assumed. The incorrect bare `O(y^3)` estimate discussed in the
article appears in a comment, not in an alleged accepted answer.

## Supplied repository

https://github.com/VladimirReshetnikov/ProveIt/tree/main/Analysis/FabiusFunction/docs/semi-formalized-research-frontiers/drafts/series-and-transseries

Consulted the root overview, the consolidated volume's README, and selected
search excerpts describing formal support, inversion, and the distinction
between the near-identity operator form and the classical coefficient form of
Lagrange–Bürmann. The README blob inspected on 7 September 2026 has SHA
`de062c17cd19a309becb7cebcee773a3c3f771d0`.
Selected search results were tied to repository commit
`24ce8bd743eaab64a91ce90725ea00f498d319d2`.

Consolidated overview:
https://github.com/VladimirReshetnikov/ProveIt/blob/main/Analysis/FabiusFunction/docs/semi-formalized-research-frontiers/drafts/series-and-transseries/Transseries_And_Inversion/README.md

The very large canonical `transseries_and_inversion.tex` could not be retrieved
as usable decoded text through the available file endpoint. This report does
not claim to have read, reviewed, verified, or formally extended that entire
manuscript. Its finite-model theorem and proofs are developed self-containedly.
No statement here treats the repository's editorial completion as complete
machine formalization.

## Primary mathematical and implementation references

NIST Digital Library of Mathematical Functions, §1.10(vii), inverse functions
and Lagrange inversion:
https://dlmf.nist.gov/1.10#vii

Wolfram Research documentation:
https://reference.wolfram.com/language/ref/InverseFunction.html
https://reference.wolfram.com/language/ref/InverseSeries.html
https://reference.wolfram.com/language/ref/Series.html
https://reference.wolfram.com/language/ref/Element.html
https://reference.wolfram.com/language/ref/VerificationTest.html
https://reference.wolfram.com/language/ref/TestReport.html

These describe the relevant interfaces, not a claim that their contemporary
behavior reproduces every historical result displayed in the 2020 question.
The article labels the historical inverse-branch output accordingly.

## Execution provenance

The independent checks ran with the Python/SymPy/mpmath versions recorded in
`validation/results.json`. Native Wolfram execution was attempted through the
available connector, but its MCP endpoint returned HTTP 404. No local Wolfram
kernel was present. Consequently no native Wolfram test is reported as passed.

All code, exposition, and proofs in this deliverable were produced for this
request. Neither the question archive nor repository source files are included
in this distribution. Bibliographic references in the article give attribution.
