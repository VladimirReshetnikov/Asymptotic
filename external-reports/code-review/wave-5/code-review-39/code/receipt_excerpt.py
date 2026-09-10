"""Source-transcribed functional excerpt of the pinned upstream receipt checker.

Source: VladimirReshetnikov/Asymptotic, commit
651f2029d0b2cd4da9e4dfdf1f4275a124d23b99,
validation/check_mathics_acceptance.py. The four functions below were copied
from the retrieved source; imports, constants and this header are scaffolding.
This does not include repository discovery, CLI or aggregate coverage checks.
All bundled test receipts are artificial, not package execution evidence.
"""
from collections import Counter
import re

SUITE = "validation/MathicsTests.wl"
RUNNER = "validation/run_mathics_tests.py"
REQUIREMENTS = "validation/requirements-mathics.txt"
ENTRY = "AsymptoticAnalysis.wl"
MODULAR_ENTRY = "src/Kernel/" + ENTRY
PREFIX = "ASYMPTOTIC_PORTABLE_"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def canonical_sources(raw: dict) -> dict[str, str]:
    require(isinstance(raw, dict), "TestedSourcesSHA256 must be an object")
    result = {}
    for name, digest in raw.items():
        require(isinstance(name, str) and isinstance(digest, str)
                and re.fullmatch(r"[0-9a-f]{64}", digest) is not None,
                f"Invalid source fingerprint: {name}")
        parts = name.replace("\\", "/").split("/")
        if len(parts) >= 2 and parts[-2] == "Kernel" and parts[-1].endswith(".wl"):
            canonical = "src/Kernel/" + parts[-1]
        elif len(parts) >= 2 and parts[-2] == "validation" and parts[-1] in {
                "MathicsTests.wl", "run_mathics_tests.py", "requirements-mathics.txt"}:
            canonical = "validation/" + parts[-1]
        elif parts[-1] == ENTRY:
            canonical = ENTRY
        else:
            raise ValueError(f"Unexpected fingerprinted input: {name}")
        require(canonical not in result, f"Duplicate canonical input: {canonical}")
        result[canonical] = digest
    return result


def protocol_fields(output: str, test_id: str) -> dict:
    require(isinstance(output, str), f"{test_id}: missing raw kernel output")
    lines = output.splitlines()

    def scalar(suffix: str) -> str:
        prefix = PREFIX + suffix + "\t"
        values = [line[len(prefix):] for line in lines if line.startswith(prefix)]
        require(len(values) == 1, f"{test_id}: missing or duplicate {suffix} protocol field")
        return values[0]

    def block(field: str) -> str:
        first, last = PREFIX + field.upper() + "_BEGIN", PREFIX + field.upper() + "_END"
        require(lines.count(first) == lines.count(last) == 1, f"{test_id}: incomplete {field} protocol block")
        start, end = lines.index(first), lines.index(last)
        require(start < end, f"{test_id}: reversed {field} protocol block")
        return "\n".join(lines[start + 1:end])

    require(scalar("RESULT") == test_id + "\tSuccess", f"{test_id}: raw result is not its successful record")
    limit = scalar("ITERATION_LIMIT")
    require(limit.isdigit(), f"{test_id}: invalid iteration limit")
    return {"Kernel": scalar("KERNEL"), "KernelIterationLimit": int(limit),
            "ActualOutput": block("Actual"), "ExpectedOutput": block("Expected")}


def validate_shard(report: dict, reference: dict) -> dict:
    require(report.get("Runtime") == "Mathics", "Receipt runtime is not Mathics")
    for key in ("RunComplete", "SourcesUnchangedDuringRun", "FreshKernelPerCase"):
        require(report.get(key) is True, f"Receipt requires {key}=true")
    results = report.get("Results")
    require(isinstance(results, list) and bool(results), "Receipt has no case results")
    for key in ("Selected", "Executed", "Succeeded", "Failed", "NotRun"):
        require(type(report.get(key)) is int, f"Invalid counter: {key}")
        expected = 0 if key in {"Failed", "NotRun"} else len(results)
        require(report[key] == expected, f"Incomplete or inconsistent counter: {key}")
    source = report.get("Source")
    require(isinstance(source, str), "Receipt has no source entry")
    parts = source.replace("\\", "/").split("/")
    require(parts[-1] == ENTRY, "Unexpected package entry filename")
    layout = "modular" if len(parts) >= 2 and parts[-2] == "Kernel" else "standalone"
    sources = canonical_sources(report.get("TestedSourcesSHA256"))
    requirements_checks = []
    if REQUIREMENTS in sources:
        requirements_checks.append(sources.pop(REQUIREMENTS))
    if "RequirementsSHA256" in report:
        requirements_checks.append(report["RequirementsSHA256"])
    require(all(value == reference["FilesSHA256"][REQUIREMENTS] for value in requirements_checks),
            "Recorded requirements hash differs from reference")
    require(sources == reference["ExpectedSources"][layout],
            f"{layout}: exact source set or hashes differ from reference")
    if "SourcesSHA256AfterRun" in report:
        require(canonical_sources(report["SourcesSHA256AfterRun"]) ==
                canonical_sources(report["TestedSourcesSHA256"]), "Contradictory after-run source fingerprints")
    require(report.get("TestSuiteSnapshotSHA256") == reference["FilesSHA256"][SUITE],
            "Suite snapshot hash differs from reference")
    require(report.get("MathicsIterationLimitConfiguredBySuite") == reference["IterationLimit"],
            "Configured iteration budget differs from reference")
    seen = []
    kernels = set()
    for row in results:
        require(isinstance(row, dict), "Case result must be an object")
        test_id = row.get("TestID")
        require(test_id in reference["Cases"], f"Unexpected test ID: {test_id}")
        require(row.get("Group") == reference["Cases"][test_id], f"{test_id}: incorrect group")
        require(row.get("Outcome") == "Success" and type(row.get("ExitCode")) is int
                and row["ExitCode"] == 0, f"{test_id}: unsuccessful outcome or exit status")
        parsed = protocol_fields(row.get("KernelOutput"), test_id)
        require(all(row.get(key) == value for key, value in parsed.items()),
                f"{test_id}: stored fields disagree with raw kernel protocol")
        require(parsed["Kernel"].startswith("Mathics3 " + reference["MathicsVersion"] + " "),
                f"{test_id}: unexpected kernel or Mathics version")
        require(parsed["KernelIterationLimit"] == reference["IterationLimit"],
                f"{test_id}: effective iteration budget differs from reference")
        require(parsed["ActualOutput"] == parsed["ExpectedOutput"],
                f"{test_id}: successful SameQ assertion has inconsistent printed values")
        seen.append(test_id)
        kernels.add(parsed["Kernel"])
    require(len(seen) == len(set(seen)), "Duplicate test ID within a shard")
    return {"Layout": layout, "Cases": seen, "Groups": dict(Counter(reference["Cases"][name] for name in seen)),
            "Kernels": sorted(kernels), "RequirementsHashStatus": "Verified" if requirements_checks else "NotRecorded",
            "SourcesSHA256": sources, "TestSuiteSnapshotSHA256": report["TestSuiteSnapshotSHA256"]}
