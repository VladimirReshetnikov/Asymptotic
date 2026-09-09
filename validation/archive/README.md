# Historical loading experiment

`github-convenience-loading-tests.json` preserves the initial successful run
of a small `Load.wl` HTTP entry that fetched the standalone package with
`URLRead` while the outer remote `Get` was evaluating it. That implementation
and its original harness are available at commit `62e7ec5`; the report was
committed in `795b8ad`.

Two subsequent fresh-kernel attempts each completed all seven acceptance
checks, then exited with status `3221225477` (`0xC0000005`). The runner
correctly rejected both attempts despite their successful test reports.
The precise native failure mechanism was not established. The convenience
entry was removed and is not a supported installation command.

The supported form downloads the complete standalone file before calling `Get`:

```wolfram
Get[URLDownload[url]]
```

Current acceptance records are in the parent directory. The archived
successful record documents the earlier experiment, not current reliability.
