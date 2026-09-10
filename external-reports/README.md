# External research and code reviews

This directory preserves the independent proposals and later reviews that
informed AsymptoticAnalysis. The original proposals and code reviews are
different collections with separate numbering, source snapshots, and evidence.

| Collection | Contents | Start here |
| --- | --- | --- |
| Original proposals | Nine independent mathematical and Wolfram Language implementations, numbered 01–09. | [Proposal index](original-proposals/README.md) · [Analysis and comparison](original-proposals/COMPARISON.md) |
| Code reviews, wave 1 | Seven retained review packages, numbered 1 and 4–9, concerning the recorded `07a9781` or `75de875` snapshot. | [Wave 1 index](code-review/wave-1/README.md) |
| Code reviews, wave 2 | Five retained incremental review packages, numbered 11 and 15–18, concerning snapshot `921387e`. | [Wave 2 index](code-review/wave-2/README.md) |
| Code reviews, wave 3 | Eight retained incremental review packages, numbered 19–25 and 27, concerning snapshot `6687962`. | [Wave 3 index](code-review/wave-3/README.md) |
| Code reviews, wave 4 | Eight retained incremental review packages, numbered 28–31 and 33–36, concerning snapshots `7d1bc83` or `513917b`. | [Wave 4 index](code-review/wave-4/README.md) |
| Code reviews, wave 5 | Seven retained incremental review packages, numbered 37–39 and 42–45, concerning snapshots `8e85996` or `651f202`. | [Wave 5 index](code-review/wave-5/README.md) |
| Code reviews, wave 6 | Ten retained incremental review packages, numbered 46–55, concerning snapshot `8cee870`. | [Wave 6 index](code-review/wave-6/README.md) |

The forty-five retained code reviews are separate from the nine original
proposals. Ten further packages were retired once every entry they carried was
implemented, settled, or restated by a retained report. A tombstone page stands
where each removed directory was, and the
[retirement register](code-review/README.md#retired-review-packages) links them
and records what each package contributed and where its open entries are still
carried.
The [code review index](code-review/README.md) explains the reviewed revisions
and evidence categories. For current implementation decisions, use the
[maintained status register](../docs/development/CODE_REVIEW_STATUS.md), which
groups overlapping findings and links integrated fixes to focused validation.
A report finding or proposed patch is not automatically a current defect or
an implemented change.
The [wave-4 intake](../docs/development/WAVE_4_INTAKE.md) maps the latest
64 attributed entries and associated proposals to current work.

## Provenance and reproduction

Report payloads retain their supplied source, articles, PDFs, evidence,
licensing and attribution notices. Historical references to the package name
AsymptoticInverse and to the old repository layout describe those snapshots;
they are not rewritten to match the current package. Follow a report's own
README and pinned revision when reproducing it, and use a separate kernel
for historical package implementations.

The collections previously lived at repository-root `reports/` and
`code-review/`. They now live under `external-reports/original-proposals/` and
`external-reports/code-review/`. The indexes and current implementation links
follow these moves; supplied report contents and saved evidence remain
historical records.

Independent mathematical checks, static source inspection, native Wolfram
observations, tests of proposed patches, and current package acceptance are
separate evidence. The wave indexes state which kinds each report contains.
See the [validation record](../validation/README.md) for the maintained
package's actual runs and their source snapshots.

Current package use belongs in the [user guide](../src/Documentation/UserGuide.md).
Its separate [mathematical article](../docs/article/README.md) contains the
maintained definitions and proofs. The [vendored ProveIt library](../vendor/proveit/README.md)
is a separate revision-pinned collection of related research articles.
