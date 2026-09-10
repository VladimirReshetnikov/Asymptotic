# Periodic peer-work reviews

The review-implementation workflow includes periodic read-only inspection of
the other worktrees and incoming `main` changes. A peer review is separate
from executing another agent's test harness or accepting its historical test
claims. Pending files remain owned by that worktree until coordinated changes
or a merge incorporate them.

## September 9, 2026 — Mathics compatibility checkpoint

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
