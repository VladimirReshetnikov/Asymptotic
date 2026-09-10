# Maintaining the documentation

Start with the [coverage targets](development/COVERAGE_TARGETS.md), the
[implementation register](development/CODE_REVIEW_STATUS.md), the
[recent changes](CHANGES.md), and the Git log. A package capability, a mathematical theorem, a passing example,
and a project goal are different claims. Keep their scope explicit when
updating any format.

## Edit the source and its generated output together

| Change | Maintained source | Output or related documentation |
| --- | --- | --- |
| Public syntax, options, result properties, or examples | [UserGuide.md](../src/Documentation/UserGuide.md) | Regenerate [UserGuide.html](../src/Documentation/UserGuide.html); update the relevant [executable examples](../src/Examples/README.md). |
| Result-family metadata, missing values, or accessor behavior | [ResultReference.md](../src/Documentation/ResultReference.md) | Regenerate [ResultReference.html](../src/Documentation/ResultReference.html) with the same builder and keep guide summaries consistent. |
| Guide typography or responsive layout | [UserGuide.css](../src/Documentation/UserGuide.css) | Regenerate HTML and inspect desktop and narrow layouts. |
| Mathematical hypotheses, statements, proofs, or notation | [Article master](article/asymptotic-inverse.tex) and its included sections | Rebuild and visually inspect [the PDF](article/asymptotic-inverse.pdf). Keep software syntax in the user guide. |
| Runtime or coverage status | [Coverage register](development/COVERAGE_TARGETS.md), [native deviations](development/NATIVE_COMPATIBILITY.md), and [Mathics status](Mathics/COMPATIBILITY.md) | Keep the root README, documentation index, and guide introductions consistent with the detailed records. |
| Test or build evidence | [Validation record](../validation/README.md) and a new artifact receipt | Name the exact source revision or hashes, selected checks, interpreter, outcomes, and limitations. Preserve prior records. |
| Imported research or review intake | [Report indexes](../external-reports/README.md) and [vendor catalog](../vendor/proveit/README.md) | Preserve supplied source/PDF bodies and notices; describe current implementation separately. |

## Check links, generated HTML, and mathematical references

The guide builder requires Python and Pandoc on `PATH`. It builds both the
user guide and result properties reference, with shared styling and HTML links
between them. Each generated page contains the stylesheet and needs no external
assets or JavaScript. Pandoc's
HTML template can change between versions; the current artifact was generated
with **Pandoc 3.9.0.2**. If a different version changes the output, review that
diff together with the source instead of bypassing the freshness check.

Run from the repository root:

```powershell
python validation/build_user_guide.py
python validation/check_documentation.py
python -m unittest discover -s validation -p test_documentation_links.py -v
python -m unittest discover -s validation -p test_documentation_text.py -v
git diff --check
```

The documentation checker verifies HTML freshness, unique guide anchors and
coverage of all public usage symbols, mathematical labels/citations, and
preservation of six historical engineering files. It automatically discovers
maintained Markdown under `src/`, `docs/`, and `validation/`, along with the
research/review catalogs and review-wave indexes. It checks local files,
images, and Markdown/HTML section fragments using Pandoc's GFM parser.
Imported report bodies, vendored source libraries, and saved question texts
retain their original references; their maintained indexes are checked.
External web availability, mathematical correctness, and runtime behavior are
outside this static check.

Save maintained text as UTF-8. The checker also scans maintained Markdown,
article TeX, and generated HTML/CSS for invalid UTF-8, replacement characters,
misdecoded punctuation, and unexpected control characters. Diagnostics name
the file and line; repair the editable source and regenerate affected outputs.
Use explicit UTF-8 encoding in scripts (`encoding="utf-8"` in Python or
`-Encoding utf8` with PowerShell `Set-Content`) rather than relying on a
terminal's legacy code page. Imported report bodies and historical evidence
remain unchanged by this check.

For the mathematical PDF, follow the
[three-pass build and rendering procedure](article/README.md#build-and-inspect).
Check the final log for unresolved references and overflowing boxes, then
inspect every rendered page in contact sheets and changed or dense pages at
full size. A successful LaTeX process does not establish readable layout.
Likewise, open the guide in a browser after changing its content or CSS;
check navigation, tables, long code examples, and narrow-screen wrapping.

## Keep implementation and evidence synchronized

For a behavior change, select the relevant
[focused Wolfram checks](../validation/README.md#choose-a-focused-check) and
[portable Mathics/Wolfram checks](Mathics/COMPATIBILITY.md#validation-and-remaining-work).
Write new output files instead of replacing historical receipts. Record
modular and standalone loading separately, and compare unchanged source
snapshots. A Wolfram preservation check does not establish Mathics acceptance.

When kernel sources change, also regenerate the standalone distribution with
`python validation/build_standalone.py` and verify it with `--check`.
Source inspection, executable example validation, document generation,
visual inspection, and publication should each be reported only when done.

When other worktrees are active, review their committed changes and incoming
`origin/main` updates. Resolve source conflicts first; regenerate HTML or the
standalone package from the merged sources, and rebuild a conflicted PDF
from resolved LaTeX. Keep the final validation tied to those merged artifacts.
Add a concise entry to [recent changes](CHANGES.md) for user-visible capabilities
or migration requirements. Link the actual implementation commit separately
from any later acceptance receipt; describe what a test checked instead of
implying that an old pass establishes current or complete coverage.
