# Vendored research articles

This directory contains external research material used as mathematical
background for the package. The collection currently consists of
[selected ProveIt articles](proveit/README.md) on asymptotic expansions,
transseries, q-analogs, combinatorial sequences, and their inverses.

The [collection index](proveit/README.md) provides topic reading lists and
links to paired TeX and PDF files. Its
[manifest](proveit/manifest.json) identifies the exact upstream Git revision,
file hashes, and dependency closure; its
[selection record](proveit/selection.json) explains inclusions and exclusions.
Provenance refers to the online
[VladimirReshetnikov/ProveIt repository](https://github.com/VladimirReshetnikov/ProveIt).

Preserve upstream relative paths, licenses, attribution, and source/PDF
pairs. Corrections and stale-PDF rebuilds should be committed upstream before
refreshing the pinned copy and its evidence. The collection README describes
the refresh and validation tools. Building a PDF or verifying copied bytes
does not independently verify the article's mathematical claims.

The package's own [mathematical article](../docs/article/README.md) and
[user guide](../src/Documentation/README.md) remain the entry
points for its theory and supported behavior.
