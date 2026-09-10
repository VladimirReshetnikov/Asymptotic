"""Narrow candidate guards for the incremental review. Python >= 3.11.

These are tested building blocks, NOT an integrated Asymptotic patch.
No caller should infer full package acceptance from their tests.
"""
from __future__ import annotations
from contextlib import contextmanager
import json
import os
from pathlib import Path
import stat
import tempfile
from typing import Iterator, Mapping, Any

class EvidenceMismatch(ValueError):
    pass

# Required because legacy read_receipt currently drops the runner identity.
# Upstream ingestion must add TestRunnerSnapshotSHA256 before using this guard.
IDENTITY_FIELDS = (
    "PackageSourcesSHA256", "TestSuiteSnapshotSHA256",
    "TestRunnerSnapshotSHA256",
)

def require_same_test_contract(full: Mapping[str, Any], correction: Mapping[str, Any]) -> None:
    """Conservative identity check; different suites are supplemental evidence.

    This deliberately does not decide semantic equivalence of changed tests.
    Legacy missing fields require migration/review rather than silent acceptance.
    Recorded values must originate from validated receipt ingestion.
    """
    for field in IDENTITY_FIELDS:
        before, after = full.get(field), correction.get(field)
        if not before or not after:
            raise EvidenceMismatch(f"Missing reconciliation identity: {field}")
        if before != after:
            raise EvidenceMismatch(f"Changed reconciliation identity: {field}")


def atomic_publish_posix_mode(target: Path, data: bytes, *, new_file_mode: int = 0o600) -> None:
    """Replace a POSIX regular file, preserving its ordinary permission bits.

    Does not promise ACL/ownership preservation or a concurrent-writer CAS.
    Call only inside the application's existing publication checks/locking.
    Symlinks and nonregular existing targets are rejected. New files remain
    private by default; public 0644 creation must be explicitly requested.
    """
    if os.name != "posix":
        raise NotImplementedError("POSIX-mode prototype; Windows ACL policy is separate")
    if type(new_file_mode) is not int or new_file_mode < 0 or new_file_mode > 0o777:
        raise ValueError("new_file_mode must contain ordinary rwx permission bits only")
    target = Path(target)
    try:
        existing = target.lstat()
    except FileNotFoundError:
        mode = new_file_mode
    else:
        if not stat.S_ISREG(existing.st_mode):
            raise ValueError("Existing destination must be a regular, non-symlink file")
        if stat.S_IMODE(existing.st_mode) & 0o7000:
            raise ValueError("Special permission bits require an explicit publication policy")
        mode = stat.S_IMODE(existing.st_mode)
    fd, name = tempfile.mkstemp(prefix=".publish-", suffix=".tmp", dir=target.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fchmod(stream.fileno(), mode)
            os.fsync(stream.fileno())
        os.replace(temporary, target)
        # Complete durability of the renamed directory entry on POSIX.
        directory_fd = os.open(target.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        temporary.unlink(missing_ok=True)


def merge_pass_recorders(records: list[dict]) -> dict:
    """Union actual per-pass inputs; retain the full observations by pass.

    A repeated runtime path with different content is a distinct environment
    inconsistency, not an arbitrary winner. Call after EACH TeX pass, before
    its recorder is overwritten; this cannot reconstruct already lost data.
    """
    if len(records) != 3:
        raise EvidenceMismatch("Three per-pass recorder observations are required")
    local: set[str] = set()
    runtime: dict[str, str] = {}
    for number, record in enumerate(records, 1):
        if not {"vendored_inputs", "runtime_inputs"} <= set(record):
            raise EvidenceMismatch(f"Incomplete recorder for pass {number}")
        local.update(record["vendored_inputs"])
        for item in record["runtime_inputs"]:
            path, identity = item["path"], item["sha256"]
            if path in runtime and runtime[path] != identity:
                raise EvidenceMismatch(f"Runtime input changed between passes: {path}")
            runtime[path] = identity
    return {
        "passes": [{"pass": i, **record} for i, record in enumerate(records, 1)],
        "vendored_inputs": sorted(local),
        "runtime_inputs": [{"path": p, "sha256": runtime[p]} for p in sorted(runtime)],
    }


def _write_json_atomic(path: Path, value: dict) -> None:
    data = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    atomic_publish_posix_mode(path, data)

@contextmanager
def _ledger_lock(path: Path) -> Iterator[None]:
    """All writers must cooperate; keep the lock file, never unlink/recreate it."""
    if os.name != "posix":
        raise NotImplementedError("Prototype uses POSIX advisory flock")
    import fcntl
    lock_path = path.with_name(path.name + ".lock")
    with lock_path.open("a+b") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def commit_receipt(path: Path, pdf: str, receipt: dict, *, expected_previous: dict | None) -> dict:
    """Merge one receipt into a FRESH ledger under a cooperative writer lock.

    Compare-and-swap is per article, so different-article writers merge while
    same-article conflicting writers fail. This function alone does not make
    PDF bytes and a receipt one transaction: publish the PDF in the SAME lock
    or use immutable PDF objects plus an atomic article pointer at integration.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with _ledger_lock(path):
        value = json.loads(path.read_text()) if path.exists() else {
            "schema_version": 1, "regenerated_pdfs": {}}
        if type(value.get("schema_version")) is not int or value["schema_version"] != 1:
            raise EvidenceMismatch("Unsupported ledger version")
        current = value.get("regenerated_pdfs")
        if not isinstance(current, dict):
            raise EvidenceMismatch("Invalid ledger entries")
        if current.get(pdf) != expected_previous:
            raise EvidenceMismatch(f"Concurrent receipt change for {pdf}")
        current[pdf] = receipt
        failures = value.get("failed_builds", {})
        if not isinstance(failures, dict):
            raise EvidenceMismatch("Invalid failure ledger")
        failures.pop(pdf, None)
        _write_json_atomic(path, value)
        return value
