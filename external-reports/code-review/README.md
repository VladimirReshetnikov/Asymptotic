# Code review reports

Thirty-five retained review packages are grouped into five waves. Each wave index
links the reports, articles, evidence, proposed patches, and package-specific
reproduction instructions.

| Wave | Retained reports | Reviewed version | Date |
| --- | --- | --- | --- |
| [Wave 1](wave-1/README.md) | Seven independent review packages: 1, 4–9 | AsymptoticInverse 1.8.0; snapshots `07a9781` and `75de875` | September 9, 2026 |
| [Wave 2](wave-2/README.md) | Five incremental review packages: 11, 15–18 | AsymptoticInverse 1.8.0; snapshot `921387e` | September 9, 2026 |
| [Wave 3](wave-3/README.md) | Eight incremental review packages: 19–25, 27 | AsymptoticAnalysis; snapshot `6687962` | September 9, 2026 |
| [Wave 4](wave-4/README.md) | Eight incremental review packages: 28–31, 33–36 | AsymptoticAnalysis; snapshots `7d1bc83` and `513917b` | September 9, 2026 |
| [Wave 5](wave-5/README.md) | Seven incremental review packages: 37–39, 42–45 | AsymptoticAnalysis; snapshots `8e85996` and `651f202` | September 10, 2026 |

The maintained [implementation status](../../docs/development/CODE_REVIEW_STATUS.md)
consolidates the findings and links completed fixes to focused validation, while
tracking pending work and design decisions.
The [wave-3 intake](../../docs/development/WAVE_3_INTAKE.md) maps its 44
attributed ledger entries; the [wave-4 intake](../../docs/development/WAVE_4_INTAKE.md)
maps 64 more entries, including numbered advisories and extension proposals,
to implementation obligations. Together with the earlier 123 entries, waves 1–4
supplied 231 attributed report entries before consolidating overlaps. Those
counts describe what arrived, not distinct current defects, completed changes,
or the reduced set of packages retained here. Wave 5 has no intake yet; its
entries are outside the 231 and outside every work item.

The wave indexes distinguish source and mathematical checks from native package
observations, executed patch checks, and unrun regression specifications.
Reviewers' independent test counts are not a combined acceptance run of this
repository.

Reports describe their pinned source snapshots. Their inclusion does not
establish that a finding still applies or that a proposed fix has been
implemented and verified in the current checkout. Preserve each package's
supplied evidence, licensing, and attribution notices when reorganizing this
directory.

## Using the reviews

Start with the implementation register to see which findings share a cause
and which fixes have focused evidence. Follow the relevant wave index to the
original report, then check its reproduction against the current source.
Proposed patches and tests are review material until integrated and validated.

The [development instructions](../../docs/development/README.md) describe the
source and documentation workflow; the [validation record](../../validation/README.md)
links executable focused runners and their recorded scope. The current
instruction is to skip the full package suite.

<a id="retired-review-packages"></a>
## Retired review packages

Ten packages were removed once every entry they carried was either implemented
and verified in the register, settled as a decision, or restated by a retained
package. Retirement removes a redundant copy of an obligation, never the
obligation itself: each open item below is still carried by the retained
reports named in its row, and the register keeps the consolidated statement of
the work. The removed directories remain in Git history at
`2396cb6` and earlier.

| Retired | Wave | Implemented or settled entries | Remaining entries, and where they are still carried |
| --- | --- | --- | --- |
| 2 | 1 | F01 → C04, F02 → C02, F03 → C03, F04 → C01 | F05 → C08 (reports 5, 6, 9, 18); F06 → P04 (5, 9); F07 → X01 (5, 7). Roadmap proposals X02, X03, X06 and X08 keep their other cited sources. |
| 3 | 1 | F01 → C02, F02 → C01, F03 → C03, F04 → C05 | F05 → P04 (5, 9). The X04 proposal now cites report 16's derivative-tail entries. |
| 10 | 2 | N01 → C05 | N02 → P06 (1, 4, 6, 8, 16). |
| 12 | 2 | N01 → C05, N02 → C07, N03 → C17 | N02's C13 component (reports 4, 7) and its B01 component (11, 13, 18). |
| 13 | 2 | A1 → C14, A2 → C07, A3 → C21 | A1's C12 component (report 6, the register's cited source); A2's B01 component (11, 18). |
| 14 | 2 | N01 → C15, N02 → C20, N03 → C21, N05 → C22 (truncation) | N04 → D01/D02 (1, 4, 6, 7, 16); C22's arithmetic transport stays open under the retained C22 record. |
| 26 | 3 | — | Every entry restates W3-01 (19, 20, 21, 23, 24, 25, 27), W3-02 (19, 20, 21, 24, 25, 27) or W3-04 (19, 20, 25). Its alias-default alternative is preserved in the wave-3 intake alongside report 20's. |
| 32 | 4 | T01 → W4-10 | M01 → W4-01 (28–30, 33, 34); M02/M03 → W4-03 (28, 35, 36); D-P06 → W4-07 (30, 33–36); D-V01 → W4-12 (28–30, 34, 35); L01 → W4-05 (28–31, 33–35); G01 → W4-08 (28, 30, 36). |
| 40 | 5 | — | ABS-01 duplicates 37 F01; ABS-02 duplicates 42 N01. |
| 41 | 5 | — | ABS-01 duplicates 37 F01. Its complex-modulus reference algorithm and the Hermitian pairing count are recorded in the [mathematical article](../../docs/article/sections/03-forward.tex) and the wave-5 index. |

Mathematical content that was unique to a retired package was merged into the
[mathematical article](../../docs/article/README.md) before removal, not
discarded; the wave-5 index names the merged results.

These reviews concern the unified package. The nine earlier research and
implementation submissions have their own [reports index](../original-proposals/README.md)
and comparison. Return to the [repository README](../../README.md) for package
loading and the mathematical article and user guide.
