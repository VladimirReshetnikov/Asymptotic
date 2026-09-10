# Periodic peer-work reviews

The review-implementation workflow includes periodic read-only inspection of
the other worktrees and incoming `main` changes. A peer review is separate
from executing another agent's test harness or accepting its historical test
claims. Pending files remain owned by that worktree until coordinated changes
or a merge incorporate them.

## September 9, 2026 — Mathics compatibility checkpoint

The later immutable review of
[`7d1bc832895cc90a9b2a978b7b7684acab908bd2`](https://github.com/VladimirReshetnikov/Asymptotic/commit/7d1bc832895cc90a9b2a978b7b7684acab908bd2)
against `a55df16` found no merge blocker in the Mathics empty-list adapter,
guarded native loading, capture-script isolation, portable test additions,
or operations CI shard. The adapter replaces private references to the
two-argument default-level `Map` case; it leaves `System` definitions unchanged.
The standalone continues to defer parsing its adapter source on native Wolfram.

The previous P2 capture-script finding is repaired in that immutable revision:
the exact captured script bytes are copied once, the frozen path is executed,
the snapshot is checked before each launch and at completion, and original
tool drift invalidates the report. Three mocked tests exercise unchanged,
original-mutated, and snapshot-mutated runs. The portable source contains 90
cases, including 12 new operation cases and one empty-map primitive. These
are source-review observations; root's subsequent validation is recorded
separately. The unchanged portable runner and builder were not new peer fixes.

Untracked `MathicsInputAssumptions.wl` and three Mathics receipts visible in
the peer worktree were outside this immutable review. Historical native
preservation counts remain attached to their recorded source hashes.

The same incoming revision's article changes were independently reviewed
against the underlying mathematical chapters. The first-order versus
second-order Taylor distinction, nonnegative-exponent quotient algebra,
small-uniformizer wording, possible omitted-weight qualifier, and refined
forward-error transport formula agree with the stated theorems. New reading
references resolve. No mathematical blocker was found; this source review
does not replace rebuilding or inspecting the merged PDF.

The actual merged guide build exposed two missing coverage-index targets in
`7d1bc83`. The subsequent upstream revision `699a9739` supplies both indexes,
the maintenance guide and raw-HTML link/image checks. Root merged it, retained
both validation histories, and reran all five documentation-link regressions
plus the complete maintained-document checker. The final native and TeX
source hashes are unchanged by that documentation-only merge. No peer
uncommitted files were copied to fill the missing targets.

Reviewed the 17 committed files between `350c70f` and
[`5d4ff7c569f747245741d940a5a774d51917912f`](https://github.com/VladimirReshetnikov/Asymptotic/commit/5d4ff7c569f747245741d940a5a774d51917912f),
plus the relevant uncommitted documentation and native-definition comparison
tools in the `codex/mathics-compatibility` worktree. No merge blocker was found
in the committed changes. No peer files were modified during review.

The committed review covered the added guarded Mathics loads, native parse
isolation of adapter strings, the `/;` and `;;` standalone-splitting repair,
current `ProductLog` rewrite sites, proof-time budgets versus explicit caller
budgets, realness and Taylor-arity guards, CI and runner reporting. The guarded
code does not claim nonprincipal numerical `ProductLog` support. Historical
preservation receipts remain tied to their recorded source revisions.

**Finding at review time — P2: freeze the native-definition capture script.** The
uncommitted `validation/check_mathics_definitions.py` records tool hashes at
line 111, but line 135 executes the live `CheckMathicsDefinitions.wl` path for
each capture. Package inputs are snapshotted and checked; the capture script
is not. An edit during the multi-kernel run can therefore leave a passing
receipt whose recorded script hash differs from the code executed. Copy the
capture script into the temporary directory and execute that frozen copy, or
invalidate the comparison on tool-hash drift. The reviewed script hashes were:

- `check_mathics_definitions.py`: `ea9f7bfa554fe8add87bdf5c8a3abf4cb15e943def09d18846d9859a4949d2ac`.
- `CheckMathicsDefinitions.wl`: `84dccd5f40e5abfe23a96220784c188d46e24fb21e6d2232ab519f67dda6c4c4`.

This finding concerns pending work outside `5d4ff7c`; it is not a defect in the
merged package's mathematical output. A later review should recheck the live
tool rather than assuming this uncommitted snapshot is still current.

**Resolution in the Mathics worktree:** the comparison runner now copies
the exact hashed capture bytes before launching any kernel, executes only
that frozen script, checks its hash before each launch and at completion,
and rejects changes to the original tools as well. Three focused offline
regressions check the unchanged case, an edit to the original during the
first kernel, and corruption of the snapshot during the first kernel. The
last case prevents the second kernel from starting. These tests pass; they
verify harness isolation rather than package mathematical behavior.

Root's separate post-merge acceptance is recorded in the
[validation index](../../validation/README.md). Focused native tests,
standalone-builder tests and portable-runner tests do not establish complete
Mathics runtime acceptance. The full package suite was skipped.

## September 9, 2026 — documentation and observable follow-ups

The documentation checkpoint `db8ea41`, merged through `a4e1a3e`, temporarily
linked to two uncommitted coverage registers. Running the documentation
checker reproduced those missing destinations. The completed `513917b` and
`699a973` updates supply the registers and regenerated guide. After merging
them, the checker passes across 45 maintained Markdown pages, 1,603 local
links and 209 local fragments, including the Mathics assumption notes.
The broader link checker uses the same GFM parser as the guide builder;
source review confirmed that imported report bodies remain outside its
maintained-page scope. Its artifact-specific checks are separate from kernel
acceptance.

The uncommitted observable repair in the `codex/fix-inverse-asymptotic-expansion`
worktree was also inspected read-only. Its new helpers validate the returned
Taylor chart and exclusive endpoint before indexing coefficients, retain the
selected one-sided constant, and require two-sided/point agreement when the
input does not prove an approach side. These address concrete information-loss
cases. This inspection is not acceptance of that worktree's pending files;
a later merge still requires an updated native control and relevant Mathics
observable regressions. No files in either peer worktree were edited.
