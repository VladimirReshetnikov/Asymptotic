# Code review reports

Seventeen review packages are grouped into two waves. Each wave index links the reports, articles, evidence, proposed patches, and package-specific reproduction instructions.

| Wave | Reports | Reviewed version | Date |
| --- | --- | --- | --- |
| [Wave 1](wave-1/README.md) | Nine independent review packages, numbered 1–9 | AsymptoticInverse 1.8.0; snapshots `07a9781` and `75de875` | September 9, 2026 |
| [Wave 2](wave-2/README.md) | Eight incremental review packages, numbered 10–17 | AsymptoticInverse 1.8.0; snapshot `921387e` | September 9, 2026 |

The maintained [implementation status](../docs/development/CODE_REVIEW_STATUS.md) consolidates the findings and links completed fixes to focused validation, while tracking pending work and design decisions.

The wave indexes distinguish source and mathematical checks from native package observations, executed patch checks, and unrun regression specifications. Reviewers' independent test counts are not a combined acceptance run of this repository.

Reports describe their pinned source snapshots. Their inclusion does not establish that a finding still applies or that a proposed fix has been implemented and verified in the current checkout. Preserve each package's supplied evidence, licensing, and attribution notices when reorganizing this directory.
