# Documentation

The documentation starts with a purely mathematical article and a separate
package user guide organized in the style of Wolfram documentation. A result
properties reference describes the metadata used by each representation.
The guide documents this custom package; it is not an official Wolfram
reference page.

**The package must completely subsume Wolfram's `Series`, `Asymptotic`, and
`DiscreteAsymptotic`: every input successfully handled by any of them must
also be handled correctly and successfully by AsymptoticAnalysis.** Its
result representation may differ. Complete coverage is not yet established;
the current native backends cover `Series` and `Asymptotic`, while
`DiscreteAsymptotic` delegation remains to be implemented. The
[native compatibility plan](development/NATIVE_COMPATIBILITY.md) and
[backend guide](../src/Documentation/UserGuide.md#native-backend-expansions)
document the current behavior and known deviations from this requirement.

**Complete compatibility with Mathics3, in addition to the official Wolfram
kernel, is a project goal.** The package already has interpreter-specific
adapters and focused portable checks; complete Mathics coverage is not yet
established. The [compatibility guide](Mathics/COMPATIBILITY.md) distinguishes
the tested runtime and feature scope from remaining implementation and
validation work.

**All asymptotics developed in the vendored articles under `vendor/proveit/docs`
must also be computable by the package, including q-analogs, their inverses,
and combinatorial sequences.** The [vendored coverage matrix](development/VENDORED_ASYMPTOTICS.md)
maps the article families to existing building blocks and outstanding work;
it does not claim that those families are already implemented. The
[coverage register](development/COVERAGE_TARGETS.md) records all three goals
and the evidence needed to establish them.

| Read or do | Start here |
| --- | --- |
| Learn the theory, hypotheses, and proofs | [Mathematical article (PDF)](article/asymptotic-inverse.pdf) · [LaTeX source and build instructions](article/README.md) |
| Load and use the package | [User guide (HTML)](../src/Documentation/UserGuide.html) · [Markdown source](../src/Documentation/UserGuide.md) |
| Inspect result properties and missing metadata | [Result properties (HTML)](../src/Documentation/ResultReference.html) · [Markdown source](../src/Documentation/ResultReference.md) |
| Update existing code or follow new capabilities | [Recent development changes](CHANGES.md), including package renames, native routing, and Mathics milestones |
| Rebuild the guide or inspect its examples | [Guide build instructions](../src/Documentation/README.md) · [Examples](../src/Examples/README.md) |
| Understand implementation contracts and gotchas | [Development notes](development/README.md), including assumptions, native remainder semantics, and real coefficients · [Wolfram evaluation notes](WOLFRAM-NOTES.md) · [Mathics evaluation notes](MATHICS-NOTES.md) |
| Use the package in Mathics3 | [Compatibility and validation guide](Mathics/COMPATIBILITY.md) · [Exact assumptions](Mathics/ASSUMPTIONS.md) · [Callable branch proofs](Mathics/CALLABLES.md) |
| Track reported issues and proposed changes | [Implementation status](development/CODE_REVIEW_STATUS.md) · [Thirty-five retained code review packages in five waves](../external-reports/code-review/README.md) · [Wave-4 intake](development/WAVE_4_INTAKE.md) |
| Check what was actually validated | [Validation record](../validation/README.md), with focused test results and artifact-specific build and review evidence |
| Explore related asymptotic and inverse theory | [Vendored ProveIt article catalog](../vendor/proveit/README.md), with TeX/PDF sources, reading lists, and provenance |
| Track the three complete-coverage requirements | [Coverage register](development/COVERAGE_TARGETS.md) · [Vendored asymptotics matrix](development/VENDORED_ASYMPTOTICS.md) |
| Read submitted research and reviews | [External reports](../external-reports/README.md): nine original proposals and thirty-five retained code reviews |

The [native compatibility plan](development/NATIVE_COMPATIBILITY.md) records
the accepted requirement to completely subsume `Series`, `Asymptotic`, and
`DiscreteAsymptotic`, together with known deviations and interface repairs.
Explicit `Series`/`Asymptotic` delegation, the held alias, and
automatic routing for selected native forms and representation limitations
are implemented. The [226-test rename record](../validation/package-rename-tests.json)
checks selected cases at checkpoint `a6c90ce`, before the documentation and
report directories moved; it does not prove complete native coverage.
The [native result contracts](development/NATIVE_RESULT_CONTRACTS.md)
distinguish preserved formal output from analytic remainder proofs. The current
guide and implementation status distinguish supported behavior from pending
changes; mathematical existence results and successful examples alone do not
establish complete API coverage.

## Source and output maintenance

Edit the article's LaTeX sources and rebuild its PDF; edit the guide's Markdown
and CSS sources and regenerate its HTML. Their linked build instructions
describe the commands and visual checks. Keep changed sources with their
generated outputs. A test run, a successful document build, and a visual review
are separate evidence, each tied to the source or artifact it checked.
The [documentation maintenance guide](MAINTAINING.md) describes source
ownership, generated outputs, link checks, and the review workflow.

## Historical material

[Development](development/README.md) also preserves the original engineering
roadmap and [chapters from the former combined article](development/article-notes/README.md).
These retain their historical content and are not the maintained API reference.

Two retained Mathematica Stack Exchange questions document motivating examples:

- [Real-valued inverse branch](mathematica.stackexchange.com/how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function/how-to-get-an-asymptotic-of-the-real-valued-branch-of-the-inverse-function.md).
- [Irrational exponents](mathematica.stackexchange.com/asymptotic-expansion-for-a-function-containing-irrational-exponents/asymptotic-expansion-for-a-function-containing-irrational-exponents.md).

Their accompanying PDFs and source URL files are preserved beside the text.
Their original observations about Wolfram behavior are historical examples,
not current compatibility tests. The [question index](mathematica.stackexchange.com/README.md)
links their original online sources and local formats. The
[original reports index](../external-reports/original-proposals/README.md) introduces the nine independent
research and implementation submissions developed from these questions.

Return to the [repository README](../README.md) for a quick start and directory map.
