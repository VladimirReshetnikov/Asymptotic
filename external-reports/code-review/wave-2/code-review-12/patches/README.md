# Focused candidate changes

The source transformation specification is `../code/patch_rules.json`.
Run `../code/apply_candidate_patch.py` against an independently obtained checkout
at commit `921387e5ba1239bfda96e63e64e89bf63d9c41e6` to emit patched copies,
a unified diff, and a hash manifest into a separate new directory. The tool
validates all anchors before writing and does not modify the checkout.

The three changes are certificate assumption isolation, a strict real-coefficient
admission guard in `pConst`, and machine-integer preflight for the optional
`SeriesData` view. Each underlying focused change had a successful native test,
with the exact scope recorded in `../evidence/native_observations.json`.
They were not tested together against the complete upstream suite. In particular,
the realness guard changes acceptance policy and can require additional explicit
parameter assumptions. It is not a complete codomain-evidence implementation.

After review and application to canonical kernel sources, regenerate the root
standalone package with the upstream `validation/build_standalone.py` and run
both modular and standalone regressions. Do not hand-edit only the standalone
artifact and assume the modular package has changed.
