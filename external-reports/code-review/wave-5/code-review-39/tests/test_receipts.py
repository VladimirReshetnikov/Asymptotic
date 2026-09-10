from copy import deepcopy
import pytest
from receipt_excerpt import validate_shard
from receipt_guard import validate_shard_strict, lexical_path
from synthetic_receipts import fixture

@pytest.mark.parametrize("layout", ["modular", "standalone"])
def test_positive_controls(layout):
    report, ref = fixture(layout)
    original = validate_shard(report, ref)
    assert original["Layout"] == layout and original["Cases"] == ["case-a"]
    assert validate_shard_strict(report, ref) == original

@pytest.mark.parametrize("layout", ["modular", "standalone"])
def test_unfingerprinted_entry_is_accepted_by_original_but_not_guard(layout):
    report, ref = fixture(layout)
    report["Source"] = report["Source"].replace("/checkout/", "/NOT-FINGERPRINTED/")
    assert validate_shard(report, ref)["Layout"] == layout
    with pytest.raises(ValueError, match="exactly one"):
        validate_shard_strict(report, ref)

def test_nonentry_kernel_module_is_already_rejected():
    report, ref = fixture()
    report["Source"] = "/checkout/src/Kernel/InverseCertificates.wl"
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError, match="entry filename"):
            validator(report, ref)

@pytest.mark.parametrize("drift", [{}, {"/checkout/src/Kernel/AsymptoticAnalysis.wl": "f"*64}])
def test_recorded_drift_survives_endpoint_restoration(drift):
    report, ref = fixture()
    report["FirstObservedSourceDriftSHA256"] = drift
    assert validate_shard(report, ref)["Layout"] == "modular"
    with pytest.raises(ValueError, match="first source mismatch"):
        validate_shard_strict(report, ref)

@pytest.mark.parametrize("field", ["RunComplete", "FreshKernelPerCase", "SourcesUnchangedDuringRun"])
def test_existing_failure_controls_preserved(field):
    report, ref = fixture()
    report[field] = False
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError):
            validator(report, ref)

def test_bad_hash_rejected_by_both():
    report, ref = fixture()
    report["TestedSourcesSHA256"][report["Source"]] = "f"*64
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError, match="source set or hashes"):
            validator(report, ref)

def test_duplicate_case_rejected_by_both():
    report, ref = fixture()
    report["Results"].append(deepcopy(report["Results"][0]))
    for field in ["Selected", "Executed", "Succeeded"]:
        report[field] = 2
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError, match="Duplicate test ID"):
            validator(report, ref)

def test_no_case_rejected_by_both():
    report, ref = fixture()
    report["Results"] = []
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError, match="no case results"):
            validator(report, ref)

def test_bad_protocol_rejected_by_both():
    report, ref = fixture()
    report["Results"][0]["KernelOutput"] = ""
    for validator in [validate_shard, validate_shard_strict]:
        with pytest.raises(ValueError, match="RESULT protocol field"):
            validator(report, ref)

def test_windows_path_normalization_is_lexical():
    assert lexical_path(r"C:\work\Kernel\A.wl") == lexical_path("c:/work/Kernel/A.wl")
    assert lexical_path("/work/A.wl") != lexical_path("/work/a.wl")
