# Code review reports

Thirty-six review packages are grouped into four waves. Each wave index links
the reports, articles, evidence, proposed patches, and package-specific
reproduction instructions.

| Wave | Reports | Reviewed version | Date |
| --- | --- | --- | --- |
| [Wave 1](wave-1/README.md) | Nine independent review packages, numbered 1–9 | AsymptoticInverse 1.8.0; snapshots `07a9781` and `75de875` | September 9, 2026 |
| [Wave 2](wave-2/README.md) | Nine incremental review packages, numbered 10–18 | AsymptoticInverse 1.8.0; snapshot `921387e` | September 9, 2026 |
| [Wave 3](wave-3/README.md) | Nine incremental review packages, numbered 19–27 | AsymptoticAnalysis; snapshot `6687962` | September 9, 2026 |
| [Wave 4](wave-4/README.md) | Nine Mathics and engineering review packages, numbered 28–36 | AsymptoticAnalysis; snapshots `7d1bc83` and `513917b` | September 9, 2026 source snapshots |

The maintained [implementation status](../../docs/development/CODE_REVIEW_STATUS.md) consolidates the findings and links completed fixes to focused validation, while tracking pending work and design decisions.
The [wave-3 intake](../../docs/development/WAVE_3_INTAKE.md) maps its 44
attributed ledger entries and related proposals. Together with the earlier
123 entries, waves 1–3 have 167 identified report entries before consolidating
overlaps; this is not a count of distinct current defects or a total including
wave 4. The [wave-4 index](wave-4/README.md) links the later findings and their
novelty ledgers without treating independent or synthetic checks as current
package acceptance.

The wave indexes distinguish source and mathematical checks from native package observations, executed patch checks, and unrun regression specifications. Reviewers' independent test counts are not a combined acceptance run of this repository.

Reports describe their pinned source snapshots. Their inclusion does not establish that a finding still applies or that a proposed fix has been implemented and verified in the current checkout. Preserve each package's supplied evidence, licensing, and attribution notices when reorganizing this directory.

## Using the reviews

Start with the implementation register to see which findings share a cause
and which fixes have focused evidence. Follow the relevant wave index to the
original report, then check its reproduction against the current source.
Proposed patches and tests are review material until integrated and validated.

The [development instructions](../../docs/development/README.md) describe the
source and documentation workflow; the [validation record](../../validation/README.md)
links executable focused runners and their recorded scope. The current
instruction is to skip the full package suite.

These reviews concern the unified package. The nine earlier research and
implementation submissions have their own [reports index](../original-proposals/README.md)
and comparison. Return to the [repository README](../../README.md) for package
loading and the mathematical article and user guide.
