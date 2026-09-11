(* Focused W4-17 loading-lifecycle checks with the package-identity, native-compatibility, request-resolution and object suites that reload the package or depend on the caller's context. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "FocusedTests.wl"}]];
Exit[FocusedValidation`Run[DirectoryName[DirectoryName[$InputFileName]], $InputFileName, <|
 "Suites" -> {"ReviewLoadingLifecycle.wlt", "PackageIdentity.wlt", "NativeCompatibility.wlt", "NativeAutomatic.wlt",
   "GeneralizedSeries.wlt", "Formatting.wlt", "ReviewRequestResolution.wlt", "ReviewProofContext.wlt"},
 "Output" -> "loading-lifecycle-tests.json", "Timeout" -> 900,
 "Scope" -> "Eight selected files: the new loading-lifecycle probes (interrupted, missing and syntactically broken modules, a time-constrained load, stale-context recovery) and the package-identity, native, object, formatting, request-resolution and proof-context suites that reload the package or depend on the caller's context state; no full package suite."|>]];
