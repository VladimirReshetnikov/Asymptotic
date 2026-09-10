"""Small proposed fixes for Asymptotic's portable test launcher.

This module is an independent, tested implementation of the two corrections.
It does not import Mathics and does not modify an installed interpreter.
"""
from __future__ import annotations
import argparse
import math
import os
from pathlib import Path


def interpreter_path(value: str) -> str:
    """Make an existing executable path absolute without following its symlink.

    A bare command which is not a file relative to the caller's working
    directory remains a PATH lookup. The final symlink is significant for
    virtual environments and is deliberately NOT resolved.
    """
    if not isinstance(value, str) or not value:
        raise ValueError("an executable name or path is required")
    if Path(value).is_file():
        return os.path.abspath(value)
    return value


MAX_CASE_SECONDS = 86400.0  # Proposed documented limit: one day per test case.


def finite_positive_seconds(value: str | float) -> float:
    """argparse validator for 0 < timeout <= MAX_CASE_SECONDS.

    The finite upper bound avoids platform-specific C timeout overflows.
    This is a proposed CLI policy, not an existing repository requirement.
    """
    try:
        seconds = float(value)
    except (TypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError("timeout must be a finite positive number") from exc
    if not math.isfinite(seconds) or not (0 < seconds <= MAX_CASE_SECONDS):
        raise argparse.ArgumentTypeError("timeout must be finite and in (0, 86400] seconds")
    return seconds
