"""Artificial fixtures in the PINNED receipt schema, never runtime evidence."""
import copy
from receipt_excerpt import SUITE, RUNNER, REQUIREMENTS, ENTRY, MODULAR_ENTRY, PREFIX


def fixture(layout="modular"):
    if layout not in {"modular", "standalone"}:
        raise ValueError("Unknown layout")
    sources = {
        MODULAR_ENTRY: "a" * 64,
        "src/Kernel/InverseCertificates.wl": "b" * 64,
        ENTRY: "c" * 64,
        SUITE: "d" * 64,
        RUNNER: "e" * 64,
        REQUIREMENTS: "f" * 64,
    }
    common = {name: sources[name] for name in (SUITE, RUNNER)}
    modular = {k: v for k, v in sources.items() if k.startswith("src/Kernel/")}
    expected = {"modular": dict(common, **modular),
                "standalone": dict(common, **{ENTRY: sources[ENTRY]})}
    reference = dict(Revision="SYNTHETIC-NOT-A-COMMIT", FilesSHA256=sources,
                     Cases={"case-a": "group-a"}, IterationLimit=250000,
                     MathicsVersion="10.0.1", ExpectedSources=expected)
    tested = {"/checkout/" + k: v for k, v in expected[layout].items()}
    source = "/checkout/" + (MODULAR_ENTRY if layout == "modular" else ENTRY)
    kernel = "Mathics3 10.0.1 on a SYNTHETIC test host"
    output = "\n".join([
        PREFIX + "RESULT\tcase-a\tSuccess",
        PREFIX + "KERNEL\t" + kernel,
        PREFIX + "ITERATION_LIMIT\t250000",
        PREFIX + "ACTUAL_BEGIN", "True", PREFIX + "ACTUAL_END",
        PREFIX + "EXPECTED_BEGIN", "True", PREFIX + "EXPECTED_END",
    ])
    row = dict(TestID="case-a", Group="group-a", Outcome="Success", ExitCode=0,
               KernelOutput=output, Kernel=kernel, KernelIterationLimit=250000,
               ActualOutput="True", ExpectedOutput="True")
    report = dict(Runtime="Mathics", RunComplete=True, SourcesUnchangedDuringRun=True,
                  FreshKernelPerCase=True, Selected=1, Executed=1, Succeeded=1,
                  Failed=0, NotRun=0, Source=source, TestedSourcesSHA256=tested,
                  SourcesSHA256AfterRun=copy.deepcopy(tested),
                  TestSuiteSnapshotSHA256=sources[SUITE],
                  MathicsIterationLimitConfiguredBySuite=250000,
                  FirstObservedSourceDriftSHA256=None, Results=[row])
    return report, reference
