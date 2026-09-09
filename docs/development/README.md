# Development and provenance

The maintained reader-facing documentation consists of the
[mathematical article](../../article/asymptotic-inverse.pdf) and the
[package user guide](../../AsymptoticInverse/Documentation/UserGuide.html).

This directory preserves engineering material that previously appeared in
or alongside the combined article:

- [Implementation plan (PDF)](implementation-plan.pdf) and
  [LaTeX source](implementation-plan.tex): the original engineering roadmap,
  moved without changing its contents.
- [Former article chapters](article-notes/): historical package, report,
  validation, and integration notes preserved verbatim from revision `2a3d75a`.

These documents describe their original milestones. Consult the current
guide for supported behavior and the [validation record](../../validation/README.md)
for the precise revision and scope of each test run. Historical validation
manifests retain their original artifact paths and hashes.

The [original report comparison](../../reports/COMPARISON.md) and
[Wolfram development notes](../../WOLFRAM-NOTES.md) remain separate sources
of engineering history.

## Standalone package

The canonical implementation is the modular package under
`AsymptoticInverse/Kernel/`. The repository-root `AsymptoticInverse.wl` is a
generated distribution for HTTP `Get` and single-file offline loading.
It preserves the original module order and top-level context transitions.
Each included source carries its path and SHA-256 hash, calculated after
normalizing line endings to LF.

For remote loading, retrieve the standalone source completely with
`URLDownload` and load the resulting temporary file with ordinary `Get`.
Cold direct HTTP loading of the large
distribution intermittently produced premature end-of-file errors in
Wolfram 15.0.1, including a local gzip fixture. Downloading before `Get`
avoids that reader path and preserves sequential context changes.
The downloaded-file form uses one HTTP fetch and accepts either the current `main`
URL or a commit-pinned standalone URL. A nested HTTP convenience loader was
withdrawn after abnormal kernel exits; its earlier evidence and the reason
for withdrawal are preserved in the [validation archive](../../validation/archive/README.md).

After editing kernel sources, rebuild and commit the standalone file with
the source changes:

```powershell
python validation/build_standalone.py
python validation/build_standalone.py --check
python -m unittest discover -s validation -p test_standalone.py -v
```

The builder validates all dependencies before replacing the output. Unknown
file loads, dependencies outside the kernel directory, repeated or cyclic
loads, and runtime file-location dependencies require explicit review.
Strings and nested comments are ignored when checking executable loads.
The `--check` command verifies byte-for-byte freshness without modifying the
artifact. A GitHub Actions workflow runs this check and the builder tests
when relevant files change.

For focused native acceptance checks, run:

```powershell
python validation/check_standalone_loading.py
```

This checks isolated local, plain HTTP, and gzip HTTP loading, both modular
entry points,
`Needs`, explicit reloads, and a missing HTTP file in separate Wolfram
kernels. It checks stream cleanup on initial load and reload. The HTTP fixture
contains only the standalone file and records
every request. It does not run the full package suite. See the
[validation record](../../validation/README.md) for published-URL checks.
