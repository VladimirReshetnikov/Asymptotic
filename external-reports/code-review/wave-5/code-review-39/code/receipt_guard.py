"""Candidate additional receipt-consistency checks; not an authenticity proof."""
from __future__ import annotations
import ntpath
import posixpath
from receipt_excerpt import ENTRY, validate_shard


def lexical_path(value: str) -> str:
    """Normalize recorded path syntax without consulting the reviewer's filesystem.

    Windows drive and UNC paths are compared using Windows case normalization;
    POSIX paths remain case-sensitive. No filesystem/symlink identity is asserted.
    """
    if not isinstance(value, str) or not value:
        raise ValueError("Expected a nonempty recorded path")
    drive, _ = ntpath.splitdrive(value)
    if drive:
        return "windows:" + ntpath.normcase(ntpath.normpath(value))
    return "posix:" + posixpath.normpath(value.replace("\\", "/"))


def check_receipt_consistency(report: dict) -> None:
    if not isinstance(report, dict):
        raise ValueError("Expected a receipt object")
    recorded = report.get("TestedSourcesSHA256")
    if not isinstance(recorded, dict):
        raise ValueError("Expected TestedSourcesSHA256 to be an object")
    source = report.get("Source")
    selected = lexical_path(source)
    # Preserve the upstream filename guard; it is already implemented there.
    if source.replace("\\", "/").split("/")[-1] != ENTRY:
        raise ValueError("Unexpected package entry filename")
    matches = [path for path in recorded if lexical_path(path) == selected]
    if len(matches) != 1:
        raise ValueError("Selected Source must identify exactly one fingerprinted input path")
    # The current runner uses None before any observed mismatch. Even restoration
    # of the original content does not undo a recorded first mismatch.
    if report.get("FirstObservedSourceDriftSHA256") is not None:
        raise ValueError("A recorded first source mismatch contradicts source-stability claims")


def validate_shard_strict(report: dict, reference: dict):
    check_receipt_consistency(report)
    return validate_shard(report, reference)
