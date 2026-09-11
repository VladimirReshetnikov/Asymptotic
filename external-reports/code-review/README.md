# Code review reports

Fifty-two retained review packages are grouped into seven waves. Each wave index
links the reports, articles, evidence, proposed patches, and package-specific
reproduction instructions.

| Wave | Retained reports | Reviewed version | Date |
| --- | --- | --- | --- |
| [Wave 1](wave-1/README.md) | Seven independent review packages: 1, 4–9 | AsymptoticInverse 1.8.0; snapshots `07a9781` and `75de875` | September 9, 2026 |
| [Wave 2](wave-2/README.md) | Five incremental review packages: 11, 15–18 | AsymptoticInverse 1.8.0; snapshot `921387e` | September 9, 2026 |
| [Wave 3](wave-3/README.md) | Eight incremental review packages: 19–25, 27 | AsymptoticAnalysis; snapshot `6687962` | September 9, 2026 |
| [Wave 4](wave-4/README.md) | Eight incremental review packages: 28–31, 33–36 | AsymptoticAnalysis; snapshots `7d1bc83` and `513917b` | September 9, 2026 |
| [Wave 5](wave-5/README.md) | Seven incremental review packages: 37–39, 42–45 | AsymptoticAnalysis; snapshots `8e85996` and `651f202` | September 10, 2026 |
| [Wave 6](wave-6/README.md) | Ten incremental review packages: 46–55 | AsymptoticAnalysis; snapshot `8cee870` | September 10, 2026 |
| [Wave 7](wave-7/README.md) | Nine incremental review packages: 56–64 | AsymptoticAnalysis; snapshots `efa1aee` and `8f28084` | September 10, 2026 |

The maintained [implementation status](../../docs/development/CODE_REVIEW_STATUS.md)
consolidates the findings and links completed fixes to focused validation, while
tracking pending work and design decisions.
The [wave-3 intake](../../docs/development/WAVE_3_INTAKE.md) maps its 44
attributed ledger entries; the [wave-4 intake](../../docs/development/WAVE_4_INTAKE.md)
maps 64 more entries, including numbered advisories and extension proposals,
to implementation obligations. Together with the earlier 123 entries, waves 1–4
supplied 231 attributed report entries before consolidating overlaps. Those
counts describe what arrived, not distinct current defects, completed changes,
or the reduced set of packages retained here. Waves 5, 6 and 7 have no intake;
their entries are outside the 231 and outside every work item, and each wave
index carries an implementation-status table mapping its entries to the
register. No wave-6 or wave-7 package was retired: five wave-6 defects are
reported two or three times, but every copy carries a witness, a proof or a
different proposed repair that the others lack, so its
[index](wave-6/README.md) records those obligations once instead.

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
the work.

A tombstone page stands where each removed directory was — `wave-N/code-review-NN.md`,
linked from the first column below. It records the package's title, pinned
snapshot, supplied evidence, licensing, the disposition of every entry it
carried, and the commands that read the original files. The directories
themselves remain unedited in Git history at `2396cb6` and earlier.

| Retired | Wave | Implemented or settled entries | Remaining entries, and where they are still carried |
| --- | --- | --- | --- |
| [2](wave-1/code-review-2.md) | 1 | F01 → C04, F02 → C02, F03 → C03, F04 → C01 | F05 → C08 (reports 5, 6, 9, 18); F06 → P04 (5, 9); F07 → X01 (5, 7). Roadmap proposals X02, X03, X06 and X08 keep their other cited sources. |
| [3](wave-1/code-review-3.md) | 1 | F01 → C02, F02 → C01, F03 → C03, F04 → C05 | F05 → P04 (5, 9). The X04 proposal now cites report 16's derivative-tail entries. |
| [10](wave-2/code-review-10.md) | 2 | N01 → C05 | N02 → P06 (1, 4, 6, 8, 16). |
| [12](wave-2/code-review-12.md) | 2 | N01 → C05, N02 → C07, N03 → C17 | N02's C13 component (reports 4, 7) and its B01 component (11, 18). |
| [13](wave-2/code-review-13.md) | 2 | A1 → C14, A2 → C07, A3 → C21 | A1's C12 component (report 6, the register's cited source); A2's B01 component (11, 18). |
| [14](wave-2/code-review-14.md) | 2 | N01 → C15, N02 → C20, N03 → C21, N05 → C22 (truncation) | N04 → D01 (reports 1, 4, 6, 7, 16) and D02 (1, 4, 6, 7); C22's arithmetic transport, once carried only by the retained C22 record, is now implemented as well. |
| [26](wave-3/code-review-26.md) | 3 | — | Every entry restates W3-01 (19, 20, 21, 23, 24, 25, 27), W3-02 (19, 20, 21, 24, 25, 27) or W3-04 (19, 20, 25). Its alias-default alternative is preserved in the wave-3 intake alongside report 20's. |
| [32](wave-4/code-review-32.md) | 4 | T01 → W4-10 | M01 → W4-01 (28–30, 33, 34); M02/M03 → W4-03 (28, 35, 36); D-P06 → W4-07 (30, 33–36); D-V01 → W4-12 (28–30, 34, 35); L01 → W4-05 (28–31, 33–35); G01 → W4-08 (28, 30, 36). |
| [40](wave-5/code-review-40.md) | 5 | — | ABS-01's algebraic finding duplicates 37 F01; its logarithmic witness was its own and is now a case in the [modulus characterization](../../validation/wave5-modulus-witness.json). ABS-02 duplicates 42 N01, which uses a different source family; 40's `AsymptoticFourierInverse` entry point is recorded in its tombstone. |
| [41](wave-5/code-review-41.md) | 5 | — | ABS-01 duplicates 37 F01, but its second witness does not: `Abs[1+a z]^2 + Abs[1-a z]^2` returns a real coefficient of the wrong sign, and it is now a case in the [modulus characterization](../../validation/wave5-modulus-witness.json). Its complex-modulus reference algorithm and Hermitian pairing count are recorded in the [mathematical article](../../docs/article/sections/03-forward.tex). |

The crosswalks were walked item by item, and **C22 was the single exception**
that the rule had to state carefully. C22 was at first *focused verified for
truncation* only, with the register recording that supported arithmetic on such
results still dropped the bound fields. Report 14's N05 — the entry that was
implemented — was C22's only report source, so that arithmetic half was carried
by the C22 register record and its own acceptance evidence rather than by any
retained report; it has since been implemented and the register row records
both halves. Every other open or partial item keeps at least one retained report.

Thirty items now rest on a single retained report and twenty-seven already did.
C12 (report 6), C15 (report 11) and C21 (report 17) became single-sourced
through these removals, as did the X04 proposal, which now cites report 16.
Three closed items — C14, C17 and C20 — were reported only by a retired
package; each is focused verified with its own acceptance record, and the
register keeps the original attribution.

The mathematics unique to retired reports 40 and 41 — the norm-square modulus
construction, the logarithmic scale boundary, the Hermitian pairing count and
the cusp counterexample — was merged into the
[mathematical article](../../docs/article/README.md) before removal, and the
wave-5 index names those results. The wave-1 to wave-4 packages were retired
because every entry they carried is restated elsewhere; their articles were not
separately audited for unique mathematics, and each tombstone records what its
package supplied and which of its witnesses survive only in Git history.

Retained packages cite each other by commit-pinned URL. Those citations record
what a reviewer actually compared against and still resolve on GitHub, so they
were left untouched even where they name a retired package. Nothing in a
supplied package was edited: retirement removes whole directories, and every
retained directory keeps its original files, evidence and notices.

These reviews concern the unified package. The nine earlier research and
implementation submissions have their own [reports index](../original-proposals/README.md)
and comparison. Return to the [repository README](../../README.md) for package
loading and the mathematical article and user guide.
